# roc-redis

A binary-safe, platform-agnostic Redis client for Roc. Pure command construction
and RESP2 decoding; your platform supplies the byte-stream effects.

**Community preview:** targets `nightly-2026-09-07-14d9829`. Use the dev backend
by default; speed and size remain experimental. The API is open to feedback.

- Typed APIs for **405 commands across 18 families**, plus raw constructors.
- Custom reply decoders, ordered pipelines, and distinct RESP2 null types.
- Bounded incremental parsing and explicit transport, server, and decoder errors.
- Examples for basic-cli and basic-webserver; the core depends on neither.

## Get started

See [installation and a complete local consumer](docs/INSTALL.md).
From this checkout:

```console
nix develop
just test
just integration
```

Integration tests start isolated, disposable Redis instances. Test orchestration
is written in Roc. [More development commands →](docs/development.md)

## Read, modify, write

Read a UTF-8 greeting, append an exclamation mark, and save it for 60 seconds:

```roc
import redis.Bytes
import redis.Commands
import redis.Config
import redis.Execute

# Validate constant settings once, at module scope.
Ok(config) = Config.default |> Config.build

# Inside your effectful function, with an exclusively owned transport:
stored = Execute.request!(config, Commands.Strings.get("example:greeting"), transport)?
greeting = match stored {
    Present(bytes) => bytes.to_utf8()?
    Absent => "Hello"
}
updated = Bytes.from_str("${greeting}!")

_ = Execute.request!(
    config,
    Commands.Strings.set("example:greeting", updated, { expiration: Seconds(60) }),
    transport,
)?
```

Missing keys start with `"Hello"`; invalid UTF-8 and request failures propagate
through `?`. The SET resets the key's TTL to 60 seconds.

**This is not atomic:** another writer can change the value between GET and SET.
Use a server-side command such as APPEND for atomic appends, or a transaction/script
for coordinated updates. Run this example only against disposable data.

[Complete runnable example](examples/read_modify_write.roc) ·
[Connection setup](examples/README.md) ·
[Custom decoders and batches](examples/composition.roc)

## Bring your own transport

Supply two effects to `Execute`:

```roc
transport : Execute.Transport(_, _)
transport = {
    read!: |max_bytes| stream.read_up_to!(max_bytes, 2_000)
        .map_ok(|bytes| if bytes.is_empty() End else Data(bytes)),
    write_all!: |bytes| stream.write!(bytes, 2_000),
}
```

Your application owns the connection, TLS, deadlines, and exclusive access.
`read!` returns at most the requested bytes; `write_all!` must accept the whole
buffer. Discard the connection after `ExchangeFailed`; execution may be ambiguous.

`Execute.request!` handles one request. `Execute.batch!` pipelines requests in
one exchange, with `Batch.each` preserving each result. Batching is not a transaction.
Reply suppression has a separate, explicitly unsafe `Execute.no_reply!` API.

No RESP3, automatic retries, cluster routing, or connection pool is included.
[Full API, transport contract, and failure guarantees →](docs/usage.md)

## Benchmarks

![Four workload charts comparing Roc, Python, Go, Rust, and C throughput. Higher is better; each panel has its own zero-based scale.](docs/assets/benchmarks.svg)

Historical September 7 campaign: Redis 8.10.1 over loopback on Apple Silicon
macOS, 5,000 operations/sample, 30 samples per client/workload across ten balanced
orders. **Higher operations/second is better.** SET+GET counts as one operation;
pipelines contain 100 PINGs.

Roc used the experimental speed backend and basic-cli 0.22.2. These results
predate subsequent decoder changes and the platform upgrade; they are not a
measurement of the current checkout or a general language ranking.
Roc used a wall-clock timer; other clients used monotonic timers.

[Exact values and chart provenance](docs/benchmark-chart.md) ·
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
