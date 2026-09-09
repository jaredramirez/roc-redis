## HTTP :8000 -> one Redis PING on 127.0.0.1:6379 per request.
## Connections are request-local; this example deliberately does not add pooling.
app [Context, program] {
	pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.16.0/42jC1JT3auhHSmv2Ah8mW5F2MXiAakq1UQQ4NQceQjXw.tar.zst",
	http: "https://github.com/roc-lang/http/releases/download/2.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst",
	redis: "../package/main.roc",
}

import pf.Server
import pf.Tcp
import http.Response
import redis.Commands
import redis.Config
import redis.Execute

Context : {}

program = { init!, respond!, shutdown! }

Ok(config) = Config.default |> Config.build

init! = || Ok({ config: Server.default_config.with_listen({ host: "127.0.0.1", port: 8000 }), context: {} })

respond! : Server.Request, Context => Try(Server.Outcome, [ServerErr(Str), ..])
respond! = |_request, _context| {
	stream = Tcp.connect!("127.0.0.1", 6379)
		? |error| ServerErr(Tcp.connect_err_to_str(error))
	connection : Execute.Connection(_, _)
	connection = {
		config: config,
		read!: |max_bytes| stream.read_up_to!(max_bytes)
			.map_ok(|bytes| if bytes.is_empty() End else Data(bytes)),
		write_all!: |bytes| stream.write!(bytes),
	}
	pong = connection.request!(Commands.Connection.ping())
		? |_| ServerErr("Redis PING failed")
	Ok(Server.respond(Response.from_status(200).with_body(pong.to_list())))
}

shutdown! : Server.ShutdownReason, Context => Try({}, [Exit(I64), ..])
shutdown! = |_reason, _context| Ok({})
