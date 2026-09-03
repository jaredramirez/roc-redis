## Non-atomic read/modify/write of example:greeting on a disposable local Redis.
## Each run appends "!" and resets the TTL to 60 seconds.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "../package/main.roc",
}

import pf.Tcp
import pf.Stdout
import pf.OsStr exposing [OsStr]
import redis.Bytes
import redis.Commands
import redis.Config
import redis.Execute

Ok(config) = Config.default |> Config.build

main! : List(OsStr) => Try({}, [ExampleFailed(Str), Exit(I32), ..])
main! = |_args| {
	stream = Tcp.connect!("127.0.0.1", 6379, 2_000)
		? |error| ExampleFailed("connect: ${Str.inspect(error)}")
	transport : Execute.Transport(_, _)
	transport = {
		read!: |max_bytes| stream.read_up_to!(max_bytes, 2_000)
			.map_ok(|bytes| if bytes.is_empty() End else Data(bytes)),
		write_all!: |bytes| stream.write!(bytes, 2_000),
	}
	stored = Execute.request!(config, Commands.Strings.get("example:greeting"), transport)
		? |error| ExampleFailed("GET: ${Str.inspect(error)}")
	greeting = match stored {
		Present(bytes) => bytes.to_utf8() ? |_| ExampleFailed("greeting is not UTF-8")
		Absent => "Hello"
	}
	updated = Bytes.from_str("${greeting}!")
	_ = Execute.request!(
		config,
		Commands.Strings.set("example:greeting", updated, { expiration: Seconds(60) }),
		transport,
	) ? |error| ExampleFailed("SET: ${Str.inspect(error)}")
	Stdout.line!("${greeting}!") ? |error| ExampleFailed("stdout: ${Str.inspect(error)}")
	Ok({})
}
