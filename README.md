# roc-redis

A binary-safe, platform-agnostic Redis client for Roc. Pure command construction
and RESP2 decoding. Your platform supplies the byte-stream effects.

[API documentation (development / main)](https://jaredramirez.github.io/roc-redis/)

- Typed APIs for **405 commands across 18 families**, plus raw constructors.
- Custom reply decoders, ordered pipelines, and distinct RESP2 null types.
- Bounded incremental parsing and explicit transport, server, and decoder errors.
- Examples for basic-cli and basic-webserver; the core depends on neither.

**Dev backend is much slower for pipeline operations.** Speed runs 2.1–2.6x
faster on pipelined workloads, while sequential workloads are comparable with
other languages. See [Benchmarks](#benchmarks). The API is open to feedback.

## Get started

Spin up a redis server like so (you clone this branch and run `nix develop` to
get redis + roc in a dev shell):

```sh
redis-server --bind 127.0.0.1 --port 6379 --save "" --appendonly no
```

Then put this in a roc file and run `roc --opt=dev main.roc`:

```roc
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "https://github.com/jaredramirez/roc-redis/releases/download/0.1.0-rc4/8BsZJKf5j58G6rxgggefDWqmgfdDkYmJbNUSTb8NvRfC.tar.zst",
}

import pf.Tcp
import pf.Stdout
import pf.OsStr exposing [OsStr]
import redis.Bytes
import redis.Client
import redis.Commands
import redis.Config
import redis.ByteIo

# Create a redis client. Client contains many fields with default values, but
# since we are not overriding any of those values, we just leave it empty.
client = Client.{}

main! : List(OsStr) => Try({}, [ExampleFailed(Str), Exit(I32), ..])
main! = |_args| {
    # Create a TCP stream
	stream = Tcp.connect!("127.0.0.1", 6379, 2_000)
		? |error| ExampleFailed("connect: ${Str.inspect(error)}")

    # Create a ByteIo that reads and writes over the stream
	byte_io = ByteIo.from_empty_eof({
		read_bytes!: |max_bytes| stream.read_up_to!(max_bytes, 2_000),
		write_all!: |bytes| stream.write!(bytes, 2_000),
	})

    # Create a re-usable connection that knows how to do IO via the transport
	connection = client.connect!(byte_io)
		? |_| ExampleFailed("Redis handshake failed")

    # Read a value
	stored = connection.request!(Commands.Strings.get("example:greeting"))
		? |error| ExampleFailed("GET: ${Str.inspect(error)}")
	greeting = match stored {
		Present(bytes) => bytes.to_utf8() ? |_| ExampleFailed("greeting is not UTF-8")
		Absent => "Hello"
	}

    # Update a value
	updated = Bytes.from_str("${greeting}!")
	_ = connection.request!(
		Commands.Strings.set("example:greeting", updated, { expiration: Seconds(60) }),
	) ? |error| ExampleFailed("SET: ${Str.inspect(error)}")
	Stdout.line!("${greeting}!") ? |error| ExampleFailed("stdout: ${Str.inspect(error)}")

	Ok({})
}
```

[Installation details](docs/INSTALL.md) ·
[Checkout-local example](examples/read_modify_write.roc) ·
[Custom decoders and batches](examples/composition.roc)

## Bring your own transport

Your application owns the socket, TLS, deadlines, and exclusive access. This
package needs only two effects, `read!` and `write_all!`. `ByteIo.from_empty_eof`
wraps a raw byte reader and writer into a transport that's used to create a connection.

`Client.{ config }` holds your configuration and session policy (set `auth`
and `select_db`). `client.connect!(byte_io)` runs the AUTH/SELECT handshake
and returns a ready `Connection`. For pooling, `client.attach` binds a reused
socket without a handshake and `client.handshake!` initializes a fresh one.
See the [minimal Zig pooling example](examples/pooling/README.md) to see how
platform-owned pooling could work.

`connection.request!` handles one request. `connection.batch!` pipelines
requests in one exchange, with `Batch.each` preserving each result. Batching
is *not* a transaction. Discard the connection after `ExchangeFailed`. Use
`Execute.disposition` to classify which errors require that. Reply suppression
has a separate, explicitly unsafe `Execute.no_reply!` API. The connection
does not enforce ownership or invalidate aliases after failure. Unbound
`Execute.request!` and `Execute.batch!` remain available for adapters.

[Full API, transport contract, and failure guarantees →](docs/usage.md)

## Benchmarks

Operations per second by workload and client (**higher is better**). Each
`SET+GET`, `MSET/MGET`, hash roundtrip, and pipelined pair counts as one
operation. Pipelines hold up to 100 operations.

| Experiment | roc-redis | redis-py | go-redis | redis-rs | hiredis |
| --- | ---: | ---: | ---: | ---: | ---: |
| `ping_sequential` | 14,836 | 12,475 | 13,839 | 14,766 | 14,728 |
| `set_get_sequential` | 7,362 | 6,079 | 6,909 | 7,293 | 7,309 |
| `incr_sequential` | 14,683 | 12,578 | 13,831 | 14,568 | 14,598 |
| `ping_pipeline` | 982,800 | 358,179 | 1,050,813 | 1,207,349 | 1,226,768 |
| `mset_mget_sequential` | 7,097 | 5,758 | 6,817 | 7,303 | 7,374 |
| `hash_roundtrip_sequential` | 7,180 | 5,963 | 6,887 | 7,283 | 7,296 |
| `set_get_pipeline` | 447,828 | 119,411 | 439,952 | 467,049 | 475,692 |

All seven rows come from a local aarch64-darwin 48gb machine. They should not be taken
as absolute truth, more testing cross machine is needed.

**If you pipeline, the backend matters more than anything else here.** These
rows use the speed backend. On the dev default, single-command sequential
workloads are fast!

| Workload | dev | speed | speed is |
| --- | ---: | ---: | --- |
| `ping_pipeline` | 460,394 | 982,800 | **2.1× faster** |
| `set_get_pipeline` | 174,442 | 447,828 | **2.6× faster** |

Pipelining amortizes the network away, which leaves client-side CPU in charge,
and that is exactly what the optimizing backend improves. Develop on dev & build
with the speed backend if you are using pipelines. We hope to improve pipeline
numbers generally over time.

Regenerate all seven with `just benchmark-all` (the controller prints this exact
table).

[Chart provenance and exact values](docs/benchmark-chart.md) ·
[Workloads and reproduction](benchmarks/README.md) ·
[Performance learnings](perf.md)

```console
nix run .#benchmark
```

## Explore and contribute

- [Module map](docs/modules.md) and [complete command coverage](metadata/typed-command-api.tsv)
- [Validation status](QUALITY-REVIEW.md), [platform pins](docs/PLATFORM-UPGRADE.md), and [compiler repros](roc-bugs/)
- [API feedback questions](docs/COMMUNITY-FEEDBACK.md) and [contributing](CONTRIBUTING.md)

Licensed under [Apache 2.0](LICENSE). See [NOTICE](NOTICE) and
[third-party provenance](THIRD_PARTY.md).
