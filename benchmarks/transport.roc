## Untimed adapter-call trace. Use only through the isolated integration harness.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "../package/main.roc",
}
import pf.OsStr
import pf.Random
import pf.Stdout
import pf.Tcp
import redis.Batch
import redis.Bytes
import redis.Command
import redis.Config
import redis.Execute
import redis.Reply
import redis.Request
import redis.Resp

config = Config.default |> Config.build

Event : { schema : Str, workload : Str, call : Str, bytes : U64, requested : U64 }

payload : List(U8)
payload = [0, 13, 10, 255, 128, 82, 111, 99, 45, 82, 101, 100, 105, 115, 0, 1, 2, 3, 10, 13, 127, 128, 254, 255, 65, 66, 67, 120, 121, 122, 0, 255]

main! : List(OsStr) => Try({}, [TraceFailed(Str), Exit(I32), ..])
main! = |args| {
	port = match args.drop_first(1) {
		[host, port_arg] => {
			if OsStr.to_str_try(host) != Ok("127.0.0.1") {
				return Err(TraceFailed("only loopback is allowed"))
			}
			text = OsStr.to_str_try(port_arg) ? |_| TraceFailed("invalid port")
			U16.from_str(text) ? |_| TraceFailed("invalid port")
		}
		_ => return Err(TraceFailed("usage: transport 127.0.0.1 port"))
	}
	seed = Random.seed_u64!() ? |_| TraceFailed("random key failed")
	key = Bytes.from_str("roc-redis:transport:${seed.to_str()}")
	stream = Tcp.connect!("127.0.0.1", port, 2000) ? |error| TraceFailed(Str.inspect(error))
	setup = traced(stream, "setup")
	owned = Execute.request!(config, Request.new(Command.new("SET", [key, "0", "NX", "PX", "60000"]), Reply.raw), setup) ? |error| TraceFailed(Str.inspect(error))
	if owned != Resp.simple_utf8("OK") {
		return Err(TraceFailed("key was not acquired"))
	}
	for workload in ["ping_sequential", "set_get_sequential", "incr_sequential", "ping_pipeline"] {
		if workload == "incr_sequential" {
			reset = Execute.request!(config, Request.new(Command.new("SET", [key, "0", "PX", "60000"]), Reply.raw), setup) ? |error| TraceFailed(Str.inspect(error))
			if reset != Resp.simple_utf8("OK") {
				return Err(TraceFailed("counter reset failed"))
			}
		}
		transport = traced(stream, workload)
		var $iteration = 0.U64
		while $iteration < 10 {
			if workload == "ping_pipeline" {
				plan = Batch.all(List.repeat(Request.new(Command.ping({}), Reply.raw), 100))
				values = Execute.batch!(config, plan, transport) ? |error| TraceFailed(Str.inspect(error))
				if values != List.repeat(Resp.simple_utf8("PONG"), 100) {
					return Err(TraceFailed("invalid pipeline"))
				}
			} else if workload == "set_get_sequential" {
				set = Execute.request!(config, Request.new(Command.new("SET", [key, Bytes.from_list(payload), "PX", "60000"]), Reply.raw), transport) ? |error| TraceFailed(Str.inspect(error))
				get = Execute.request!(config, Request.new(Command.new("GET", [key]), Reply.raw), transport) ? |error| TraceFailed(Str.inspect(error))
				if set != Resp.simple_utf8("OK") or get != Resp.BulkString(payload) {
					return Err(TraceFailed("invalid SET/GET"))
				}
			} else {
				command = if workload == "incr_sequential" {
					Command.new("INCR", [key])
				} else {
					Command.ping({})
				}
				value = Execute.request!(config, Request.new(command, Reply.raw), transport) ? |error| TraceFailed(Str.inspect(error))
				expected = if workload == "incr_sequential" {
					Resp.Integer(($iteration + 1).to_i64_wrap())
				} else {
					Resp.simple_utf8("PONG")
				}
				if value != expected {
					return Err(TraceFailed("invalid sequential reply"))
				}
			}
			$iteration = $iteration + 1
		}
	}
	deleted = Execute.request!(config, Request.new(Command.new("DEL", [key]), Reply.raw), setup) ? |error| TraceFailed(Str.inspect(error))
	if deleted != Resp.Integer(1) {
		return Err(TraceFailed("cleanup failed"))
	}
	Ok({})
}

traced : Tcp.Stream, Str -> Execute.Transport([TraceFailed(Str)], [TraceFailed(Str)])
traced = |stream, workload| {
	read!: |limit| {
		bytes = stream.read_up_to!(limit, 2000) ? |error| TraceFailed(Str.inspect(error))
		event : Event
		event = { schema: "roc-redis-transport/v1", workload, call: "read", bytes: bytes.len(), requested: limit }
		Stdout.line!(Json.to_str(event)) ? |_| TraceFailed("trace output failed")
		Ok(if bytes.is_empty() End else Data(bytes))
	},
	write_all!: |bytes| {
		stream.write!(bytes, 2000) ? |error| TraceFailed(Str.inspect(error))
		event : Event
		event = { schema: "roc-redis-transport/v1", workload, call: "write", bytes: bytes.len(), requested: bytes.len() }
		Stdout.line!(Json.to_str(event)) ? |_| TraceFailed("trace output failed")
		Ok({})
	},
}
