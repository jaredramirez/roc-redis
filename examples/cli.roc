## Read-only PING against Redis on 127.0.0.1:6379.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "../package/main.roc",
}

import pf.Tcp
import pf.Stdout
import pf.OsStr exposing [OsStr]
import redis.Commands
import redis.Config
import redis.Client
import redis.Transport

config = Config.default |> Config.build

client = Client.new(config)

main! : List(OsStr) => Try({}, [ExampleFailed(Str), Exit(I32), ..])
main! = |_args| {
	stream = Tcp.connect!("127.0.0.1", 6379, 2_000)
		? |error| ExampleFailed("connect: ${Str.inspect(error)}")

	transport = Transport.from_bytes_io({
		read_bytes!: |max_bytes| stream.read_up_to!(max_bytes, 2_000),
		write_all!: |bytes| stream.write!(bytes, 2_000),
	})

	connection = client.connect!(transport)
		? |_| ExampleFailed("Redis handshake failed")

	pong = connection.request!(Commands.Session.ping())
		? |_| ExampleFailed("Redis PING failed")

	text = pong.to_utf8() ? |_| ExampleFailed("PING returned non-UTF-8 bytes")
	Stdout.line!(text) ? |error| ExampleFailed("stdout: ${Str.inspect(error)}")
	Ok({})
}
