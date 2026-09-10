## End-to-end verification against Redis using basic-cli as one platform
## adapter. The package itself has no dependency on basic-cli.
##
## Prefer `just integration`, which starts an isolated Redis. To use an
## existing server instead:
##
##     roc integration/basic_cli.roc -- 127.0.0.1 6379
##
## The test writes only a random, NX-protected key with a 60-second TTL.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "../package/main.roc",
}

import pf.OsStr
import pf.Random
import pf.Tcp
import redis.Batch
import redis.Bytes
import redis.Command
import redis.Commands as TypedCommands
import redis.Client
import redis.Config
import redis.Execute
import redis.NonEmpty
import redis.Reply
import redis.Request
import redis.Transport
import TypedCases

io_idle_timeout_ms : U64
io_idle_timeout_ms = 2_000

test_value : List(U8)
test_value = [0, 13, 10, 255, 128, 65]

config = Config.default

client = Client.{ config }

main! : List(OsStr) => Try({}, [IntegrationFailed(Str), Exit(I32), ..])
main! = |args| {
	target = parse_target(args) ? |message| IntegrationFailed(message)
	seed = Random.seed_u64!() ? |error| IntegrationFailed("random test key: ${Str.inspect(error)}")
	test_key = Str.to_utf8("roc-redis:integration:${seed.to_str()}")

	stream = Tcp.connect!(target.host, target.port, io_idle_timeout_ms) ? |error| IntegrationFailed("connect: ${Str.inspect(error)}")

	transport : Execute.Transport(_, _)
	transport = Transport.from_bytes_io({
		read_bytes!: |max_bytes| stream.read_up_to!(max_bytes, io_idle_timeout_ms),
		write_all!: |bytes| stream.write!(bytes, io_idle_timeout_ms),
	})
	connection = client.connect!(transport) ? |error| client_failure("handshake", error)

	ping_result = connection.request!(Request.new(Command.ping({}), Reply.simple)) ? |error| client_failure("PING", error)
	if ping_result != "PONG".to_utf8() {
		return Err(IntegrationFailed("PING did not return PONG"))
	}

	# NX prevents overwriting a coincidentally existing key. PX cleans up after
	# an interrupted test which cannot reach the explicit DEL below. Validate
	# NX immediately so a random collision is never read or deleted.
	set_request = TypedCommands.Strings.set(Bytes.from_list(test_key), Bytes.from_list(test_value), { condition: IfMissing, expiration: Milliseconds(60_000) })
	set_result = connection.request!(set_request) ? |error| client_failure("SET", error)
	if set_result != Applied {
		return Err(IntegrationFailed("SET did not acquire the random test key; leaving it untouched"))
	}

	get_result = connection.request!(TypedCommands.Strings.get(Bytes.from_list(test_key))) ? |error| client_failure("GET", error)

	echo_command = Command.echo(test_value)
	pipeline_result = connection.batch!(Batch.each([Request.new(Command.ping({}), Reply.simple), Request.new(echo_command, Reply.bulk)])) ? |error| client_failure("pipeline", error)

	TypedCases.run!(Bytes.from_list(test_key), config, transport) ? |message| IntegrationFailed(message)
	del_result = connection.request!(TypedCommands.Keyspace.del(NonEmpty.new(Bytes.from_list(test_key), []))) ? |error| client_failure("DEL", error)

	# Validate after DEL so ordinary assertion failures do not leave state behind.
	if get_result != Present(Bytes.from_list(test_value)) {
		return Err(IntegrationFailed("GET payload differs"))
	}
	if pipeline_result != [Ok("PONG".to_utf8()), Ok(test_value)] {
		return Err(IntegrationFailed("pipeline results differ"))
	}
	if del_result < 0 or del_result > 1 {
		return Err(IntegrationFailed("DEL did not delete the test key"))
	}

	Ok({})
}

parse_target : List(OsStr) -> Try({ host : Str, port : U16 }, Str)
parse_target = |args|
	match args.drop_first(1) {
		[] => Ok({ host: "127.0.0.1", port: 6379 })
		[host_arg, port_arg] => {
			host = OsStr.to_str_try(host_arg) ? |_| "host is not valid UTF-8"
			port_text = OsStr.to_str_try(port_arg) ? |_| "port is not valid UTF-8"
			port = parse_port(port_text)?
			Ok({ host, port })
		}
		_ => Err("usage: basic_cli [host port]")
	}

parse_port : Str -> Try(U16, Str)
parse_port = |text| {
	bytes = text.to_utf8()
	invalid = "port must be a decimal integer from 1 through 65535"
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

client_failure = |operation, error|
	IntegrationFailed("${operation}: ${Str.inspect(error)}")

expect parse_target([OsStr.from_str("app")]) == Ok({ host: "127.0.0.1", port: 6379 })

expect parse_target([OsStr.from_str("app"), OsStr.from_str("redis"), OsStr.from_str("6380")]) == Ok({ host: "redis", port: 6380 })

expect {
	match parse_target([OsStr.from_str("app"), OsStr.from_str("redis"), OsStr.from_str("nope")]) {
		Err(_) => True
		Ok(_) => False
	}
}

expect parse_port("1") == Ok(1)

expect parse_port("65535") == Ok(65535)

expect ["", "0", "+1", "0x10", "1_0", "65536", "18446744073709551617"].all(|text| parse_port(text).is_err())
