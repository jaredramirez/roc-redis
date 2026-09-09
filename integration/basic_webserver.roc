## End-to-end verification using basic-webserver as a second platform adapter.
##
## The handler opens a fresh Redis connection for each HTTP request, pipelines
## PING with an ECHO of the request target, validates both Redis responses, and
## returns the echoed target as the HTTP body. No Redis state is mutated.
##
## Prefer `roc scripts/test-basic-webserver.roc`, which starts isolated Redis
## and HTTP processes and supplies the two required port environment variables.
app [Context, program] {
	pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.16.0/42jC1JT3auhHSmv2Ah8mW5F2MXiAakq1UQQ4NQceQjXw.tar.zst",
	http: "https://github.com/roc-lang/http/releases/download/2.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst",
	redis: "../package/main.roc",
}

import pf.Env
import pf.OsStr
import pf.Server
import pf.Tcp
import http.Response
import redis.Batch
import redis.Bytes
import redis.Commands
import redis.Config
import redis.Connection

Context : {
	redis_host : Str,
	redis_port : U16,
}

program = { init!, respond!, shutdown! }

Ok(redis_config) = Config.default |> Config.build

init! : () => Try(
	{ config : Server.Config, context : Context },
	[ConfigError(Str), Exit(I64), ..],
)
init! = || {
	redis_port = read_port!("ROC_REDIS_TEST_PORT")?
	web_port = read_port!("ROC_REDIS_WEBSERVER_PORT")?

	Ok({
		config: Server.default_config.with_listen({ host: "127.0.0.1", port: web_port }),
		context: { redis_host: "127.0.0.1", redis_port },
	})
}

respond! : Server.Request, Context => Try(Server.Outcome, [ServerErr(Str), ..])
respond! = |request, context| {
	target = request_target_to_str(request.target())
		? |message| ServerErr(message)
	target_bytes = target.to_utf8()
	echo = Commands.Connect.echo(Bytes.from_list(target_bytes))

	stream = Tcp.connect!(context.redis_host, context.redis_port)
		? |error| ServerErr("connect to Redis: ${Tcp.connect_err_to_str(error)}")

	connection : Connection(_, _)
	connection = {
		config: redis_config,
		read!: |max_bytes|
			stream.read_up_to!(max_bytes)
				.map_ok(|bytes| if bytes.is_empty() End else Data(bytes)),
		write_all!: |bytes| stream.write!(bytes),
	}

	result = connection.batch!(Batch.all([Commands.Connect.ping(), echo]))
		? |error| ServerErr("Redis pipeline: ${Str.inspect(error)}")

	expected = [Bytes.from_str("PONG"), Bytes.from_list(target_bytes)]
	if result == expected {
		Ok(
			Server.respond(
				Response.from_status(200)
					.with_headers([{ name: "Content-Type", value: "text/plain; charset=utf-8" }])
					.with_body(target_bytes),
			),
		)
	} else {
		Err(ServerErr("unexpected Redis responses: ${Str.inspect(result)}"))
	}
}

## Preserve the exact percent-encoded origin/absolute-form resource target that
## basic-webserver validated. Authority-form and asterisk-form targets are not
## resource identifiers, so this proof rejects them instead of conflating them
## with an ordinary path.
request_target_to_str : Server.Target -> Try(Str, Str)
request_target_to_str = |target|
	match target {
		Resource({ raw_path, raw_query }) => Ok(resource_target_to_str(raw_path, raw_query))
		Authority(_) => Err("Redis echo endpoint does not accept authority-form request targets")
		Asterisk => Err("Redis echo endpoint does not accept the asterisk-form request target")
	}

resource_target_to_str : Str, [Absent, Present(Str)] -> Str
resource_target_to_str = |raw_path, raw_query|
	match raw_query {
		Absent => raw_path
		Present(raw_query_text) => "${raw_path}?${raw_query_text}"
	}

shutdown! : Server.ShutdownReason, Context => Try({}, [Exit(I64), ..])
shutdown! = |_reason, _context| Ok({})

read_port! : Str => Try(U16, [ConfigError(Str), ..])
read_port! = |name| {
	text = Env.var_str!(OsStr.from_str(name))
		? |error| ConfigError("${name}: ${Str.inspect(error)}")
	parse_port(text)
		.map_err(|message| ConfigError("${name} ${message}"))
}

parse_port : Str -> Try(U16, Str)
parse_port = |text| {
	bytes = text.to_utf8()
	invalid = "must be a decimal integer from 1 through 65535"
	if bytes.is_empty() or bytes.len() > 5 {
		Err(invalid)
	} else if bytes.all(|byte| byte >= 48 and byte <= 57) {
		port = U16.from_str(text) ? |_| invalid
		if port == 0 {
			Err(invalid)
		} else {
			Ok(port)
		}
	} else {
		Err(invalid)
	}
}

expect parse_port("1") == Ok(1)

expect parse_port("65535") == Ok(65535)

expect ["", "0", "+1", "0x10", "1_0", "65536", "18446744073709551617"].all(|text| parse_port(text).is_err())

expect resource_target_to_str("/binary%00path", Absent) == "/binary%00path"

expect resource_target_to_str("/search", Present("q=roc%20redis")) == "/search?q=roc%20redis"

expect resource_target_to_str("/empty-query", Present("")) == "/empty-query?"
