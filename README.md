# roc-redis

A binary-safe, platform-agnostic Redis client for Roc. Pure command construction
and RESP2 decoding; your platform supplies the byte-stream effects.

[API documentation (development / main)](https://jaredramirez.github.io/roc-redis/)

**Community preview:** targets `nightly-2026-09-07-14d9829`. Use the dev backend
by default; speed and size remain experimental. The API is open to feedback.

- Typed APIs for **405 commands across 18 families**, plus raw constructors.
- Custom reply decoders, ordered pipelines, and distinct RESP2 null types.
- Bounded incremental parsing and explicit transport, server, and decoder errors.
- Examples for basic-cli and basic-webserver; the core depends on neither.

## Get started

The example below targets **0.1.0-rc1** and the pinned Roc nightly above.
Save it as `main.roc`. With Roc and Redis available (the checkout's
`nix develop` supplies both), start disposable Redis in a separate terminal:

```sh
redis-server --bind 127.0.0.1 --port 6379 --save "" --appendonly no
```

Then run `roc --opt=dev main.roc`. Each run appends `!` to a UTF-8 greeting
and saves it for 60 seconds:

```roc
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "https://github.com/jaredramirez/roc-redis/releases/download/0.1.0-rc1/D8HziVQtZBUBer5ASdLDqwsFwXwZ2pV5XNQ9C21urvTZ.tar.zst",
}

import pf.Tcp
import pf.Stdout
import pf.OsStr exposing [OsStr]
import redis.Bytes
import redis.Client
import redis.Commands
import redis.Config
import redis.Transport

client = Client.{}

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
	stored = connection.request!(Commands.Strings.get("example:greeting"))
		? |error| ExampleFailed("GET: ${Str.inspect(error)}")
	greeting = match stored {
		Present(bytes) => bytes.to_utf8() ? |_| ExampleFailed("greeting is not UTF-8")
		Absent => "Hello"
	}
	updated = Bytes.from_str("${greeting}!")
	_ = connection.request!(
		Commands.Strings.set("example:greeting", updated, { expiration: Seconds(60) }),
	) ? |error| ExampleFailed("SET: ${Str.inspect(error)}")
	Stdout.line!("${greeting}!") ? |error| ExampleFailed("stdout: ${Str.inspect(error)}")
	Ok({})
}
```

Missing keys start with `"Hello"`; invalid UTF-8 and request failures are reported.
**This is not atomic:** another writer can change the value between GET and SET.
Use APPEND or a transaction/script for coordinated updates. Run this example
only against disposable data; stop Redis with Ctrl-C when finished.

[Installation details](docs/INSTALL.md) ·
[Checkout-local example](examples/read_modify_write.roc) ·
[Custom decoders and batches](examples/composition.roc)

## Bring your own transport

Your application owns the socket, TLS, deadlines, and exclusive access; the
package needs only two effects, `read!` and `write_all!`. `Transport.from_bytes_io`
wraps a raw byte reader and writer into a transport (an empty read means end of
stream). `Client.{ config }` holds your configuration and session policy
(set `auth` and `select_db`); `client.connect!(transport)` runs the AUTH/SELECT
handshake and returns a ready `Connection`. For pooling, `client.attach` binds a
reused socket without a handshake and `client.handshake!` initializes a freshly
dialed one.

`connection.request!` handles one request. `connection.batch!` pipelines requests in
one exchange, with `Batch.each` preserving each result. Batching is not a transaction.
Discard the connection after `ExchangeFailed`; `Execute.disposition` classifies which
errors require that. Reply suppression has a separate, explicitly unsafe
`Execute.no_reply!` API. The connection does not enforce ownership or invalidate
aliases after failure. Unbound `Execute.request!` and `Execute.batch!` remain
available for adapters.

The core includes no RESP3, automatic retries, cluster routing, or connection pool.
The [minimal Zig pooling example](examples/pooling/README.md) demonstrates
platform-owned pooling; it is not a production concurrent pool.
[Full API, transport contract, and failure guarantees →](docs/usage.md)

## Benchmarks

Operations per second by workload and client (**higher is better**). Each
`SET+GET`, `MSET/MGET`, hash roundtrip, and pipelined pair counts as one
operation; pipelines hold up to 100 operations.

| Experiment | roc-redis | redis-py | go-redis | redis-rs | hiredis |
| --- | ---: | ---: | ---: | ---: | ---: |
| `ping_sequential` | 14,694 | 12,488 | 13,619 | 14,593 | 14,506 |
| `set_get_sequential` | 7,252 | 5,958 | 6,765 | 7,283 | 7,313 |
| `incr_sequential` | 14,657 | 12,425 | 13,680 | 14,530 | 14,528 |
| `ping_pipeline` | 972,006 | 357,869 | 1,010,951 | 1,148,545 | 1,147,183 |
| `mset_mget_sequential` | — | — | — | — | — |
| `hash_roundtrip_sequential` | — | — | — | — | — |
| `set_get_pipeline` | — | — | — | — | — |

The first four rows are the archived September 7 campaign (Redis 8.10.1 over
loopback on Apple Silicon; Roc on the experimental speed backend, basic-cli
0.22.2). They predate the current checkout and are not a language ranking. The
three realistic workloads are pending a fresh run. Regenerate all seven on an
isolated host with `just benchmark` (or `just benchmark-all`) — the controller
prints this exact table.

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
