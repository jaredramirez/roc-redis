# API and operational guide

## Bound execution (recommended)

Create a client from validated config once, then bind each connected stream:

```roc
import redis.Client
import redis.Transport

client = Client.{ config }

transport = Transport.from_bytes_io({
    read_bytes!: |max_bytes| stream.read_up_to!(max_bytes, 2_000),
    write_all!: |bytes| stream.write!(bytes, 2_000),
})
connection = client.connect!(transport)?
pong = connection.request!(Commands.Session.ping())?
results = connection.batch!(batch)?
```

`Client` holds the validated config plus optional session policy (the `auth` and
`select_db` fields). `connect!` runs the AUTH/SELECT handshake and returns a `Connection`;
for pooling, `client.attach` binds a reused socket with no I/O and `client.handshake!`
initializes a fresh one. `Transport.from_bytes_io` folds the raw-reader adapter (an
empty read means end of stream); `Transport.new` takes an explicit `Data`/`End` reader.

`Connection` is a transparent nominal record. It delegates to the same execution
logic as the unbound `Execute.request!` and `Execute.batch!` forms documented
below; result types, limits, and failure guarantees are unchanged. Request and
batch plans remain pure and reusable, including custom decoders. No per-command
methods or hidden retries are added.

This value does not acquire or close a socket, enforce exclusive access, or
invalidate aliases after a failure. The application must still discard the stream
after `ExchangeFailed`; `Execute.disposition` classifies which errors require that,
and a failed `handshake!` always does. `Execute.no_reply!` remains separate and
requires only a write capability, not a full reply-reading connection.

A binary-safe, platform-agnostic Redis client package for Roc.

**Community preview.** Targets `nightly-2026-09-07-14d9829` and RESP2. Dev is
the default backend; speed and size remain experimental despite passing the
recorded qualification checks. Dev is much slower for pipelined workloads, where
speed is roughly 2.1-2.6x faster; sequential workloads land within about 4%
because they wait on the network rather than the client. The API is open to feedback before a stable
release. No RESP3, automatic retries, cluster routing, or connection pool is included.

The active CLI examples/tools use basic-cli `0.23.0-rc1`; webserver examples use
basic-webserver `0.16.0`. The core package depends on neither platform.
See [platform qualification](../docs/PLATFORM-UPGRADE.md) for pins and checks.

Implementation decisions and validation limits are recorded in
[API-PLAN.md](../API-PLAN.md) and [QUALITY-REVIEW.md](../QUALITY-REVIEW.md).

The package owns protocol and request/reply logic only. It accepts byte-stream
effects from the application, so sockets, TLS, timeouts, observability, and
connection pooling remain platform policy. The included basic-cli and
basic-webserver programs are integration adapters, not package dependencies.

This preview deliberately targets RESP2. It supports command and
pipeline encoding, all RESP2 reply types, incremental decoding across arbitrary
read boundaries, bounded parsing of untrusted replies, sequential requests,
and ordered pipelines.

## API

See [installation status and a complete local consumer](../docs/INSTALL.md).

See the [module map](../docs/modules.md) for raw versus typed commands, and the
[minimal examples](../examples/README.md) for complete platform connectors.
The [composition example](../examples/composition.roc) demonstrates custom decoders
and actual nested batch errors without needing a Redis service.

Use `Commands.<Family>` for typed commands and `Execute` for platform-independent
execution. All 18 families are covered. The raw generated modules remain an
explicit low-level escape hatch.

```roc
import redis.Commands
import redis.Config
import redis.Execute

# Recommended: construct validated settings once, at module scope.
config = Config.{ read_size: 32_768 }

request = Commands.Strings.set("key", "value", {
    condition: IfMissing,
    expiration: Milliseconds(60_000),
})
result = Execute.request!(config, request, transport)?
```

Scalar limits are compile-time-validated positives, so there is no build step and
a literal like `Config.{ read_size: 0 }` fails to compile; for a limit read at
runtime, validate it with `Positive.from_u64` before passing it. Option records
infer their nominal type from the call and fill omitted fields with defaults.
On the pinned compiler, an empty default option record must have an explicit
type: import its module directly and use e.g. `Strings.SetOptions.{}`, or pass
an inferred record with at least one named field. Explicit nominal constructors
through nested aliases hit a recorded compiler limitation.

The core types are:

- `Bytes`: opaque binary data, with quoted UTF-8 literals and `from_list` for
  arbitrary bytes. `NonEmptyBytes` validates command-name literals.
- `NonEmpty`: required operands; `NonEmpty.new(first, rest)` establishes
  cardinality once. `Positive` validates positive numeric literals and runtime values.
- `Command`: pure construction and bounded encoding into one byte buffer.
- `Resp` and `Decoder`: all RESP2 values and bounded incremental parsing.
  `NullBulkString` and `NullArray` remain distinct.
- `Reply`: reusable strict decoders, UTF-8 validation, and Redis error classification.
- `Request`: one command with an application-selected pure semantic decoder.
- `Batch`: composition of requests into one exchange.
- `Config` and `Execute`: validated resource policy and injected byte-stream effects.
- `NoReply`: explicitly unchecked plans for externally established reply suppression.

`package/` has no platform imports. See [API-PLAN.md](../API-PLAN.md) for design
decisions and [metadata/typed-command-api.tsv](../metadata/typed-command-api.tsv)
for the complete command-to-API and sender classification.

## Development

The [development map](../docs/development.md) explains test entry points, Nix files,
and process supervision. Current conclusions live in [QUALITY-REVIEW.md](../QUALITY-REVIEW.md)
and [perf.md](../perf.md); dated investigations are archived separately.

The repository pins the exact Roc nightly in both `.roc-version` and the Nix
flake. Enter the reproducible shell with:

```console
nix develop
```

To run the live checks without entering the shell first:

```console
nix run .#redis-integration
nix run .#webserver-integration
nix run .#catalog-live
```

The same flake can run the cross-client benchmark against a disposable Redis:

```console
nix run .#benchmark
nix run .#benchmark -- --iterations 20000 --samples 7 --jsonl results.jsonl
```

These commands supply the pinned Roc toolchain, Redis, and test utilities from
the flake. The Roc applications separately pin their content-addressed
basic-cli/basic-webserver platform bundles. Each command starts isolated,
non-persistent processes with identity-guarded normal and parent-death cleanup.
Project test orchestration is itself written in Roc on basic-cli; Nix and Just
are thin entry points which supply tools and invoke those Roc programs.

The development shell's `roc` command seeds the pinned basic-cli,
basic-webserver, and roc-http archives into an ignored `.roc-cache/` inside the
checkout. It preserves your real home directory, works from any directory
inside the repository, and does not need network access or a pre-existing user
cache. Compiler-driven Just recipes run through that wrapper; live Just recipes
use the dependency-complete Nix apps, so they also work outside `nix develop`
without relying on host Redis or GNU utilities.

If you use direnv, `direnv allow` enters the same shell. Useful commands are:

```console
just test          # pure expectations plus deterministic effect-contract tests
just integration   # isolated Redis through basic-cli and basic-webserver
just webserver-integration # only the basic-webserver platform proof
just catalog-live  # compare APIs with Redis 8.10.1 when available
just benchmark     # compare Roc with redis-py and go-redis (10,000 ops/sample)
just benchmark-smoke # validate the benchmark pipeline with tiny workloads
just all           # every portable static, compiler-repro, and live adapter check
just bundle-test   # test the bundled package as a downstream dependency
just docs          # generate API documentation
just bundle        # create a package archive in dist/
just nix-check     # hermetic flake checks
just roc-bug       # verify the pinned nightly's documented compiler bugs
```

The basic-cli integration starts its own non-persistent Redis on an unused high
port. The application also uses a random `SET ... NX PX 60000` key and deletes
it after verification, so it does not overwrite existing data. Set
`ROC_REDIS_TEST_PORT` to require a particular port.

Roc's built-in test primitive is `expect`; this repository builds a broader
testing story around it. `just test` runs module-local expectations for pure
protocol logic and every generated command, adapter-local expectations, a
deterministic executable for the injected transport contract, and a downstream
consumer of the actual package archive. The archive is served from loopback by
a minimal Roc/basic-webserver fixture with one host-native exact-file route;
Python is used only as a benchmark subject. `just integration` then starts
isolated services and exercises both basic-cli and basic-webserver over real
sockets.

`nix run .#benchmark` builds pinned Roc, redis-py, go-redis, redis-rs, and hiredis subjects, runs
sequential PING, binary SET+GET, INCR, and pipelined PING workloads against the
same isolated server, validates every reply and reported command count, and
prints median operations/second. Warmup, connection setup, compilation, and
cleanup are outside the timed regions. Raw schema-v2 samples include exact
client and Redis versions, content-derived Nix source provenance, target
system, and execution order, and can be retained with `--jsonl`. Use
`--all-order-rotations` (or `just benchmark-all`) for one Roc-orchestrated
campaign containing ten position-balanced subject orders. The published table uses the
experimental speed backend and retains a dev cross-check beside it, so these
numbers characterize the current toolchain and must not be presented as a
language ranking. See
[benchmarks/README.md](../benchmarks/README.md) for the exact workload and timer
caveats, and [perf.md](../perf.md) for results, tradeoffs, and future tuning guidance.

For Roc nightly `nightly-2026-09-07-14d9829`, integration scripts and normal
benchmark apps select `--opt=dev` by default. The tuned decoder
includes a state-detachment workaround: all 933 package expectations now pass
under both `--opt=speed` and `--opt=size`, and speed also passes the runtime
contract, both live platform integrations, and bundled consumer. Optimized
backends remain experimental; the original failing compiler repros are retained
under `roc-bugs/`. No protocol validation or resource limits were relaxed.
Reevaluate this boundary when upgrading the Roc pin.

## Redis command API

The catalog accounts for 449 Redis OSS 8.10.1 names: 405 public operational
commands and 44 explicitly excluded internal, HELP-only, or container entries.
The exact server metadata is retained in
[metadata/redis-8.10.1-command-catalog.json](../metadata/redis-8.10.1-command-catalog.json).
`just catalog-live` compares it with an isolated pinned server.

Every included command has both a generated raw constructor and a namespaced
API. The generator checks typed API coverage and reproduces
[metadata/typed-command-api.tsv](../metadata/typed-command-api.tsv). Ordinary commands
return `Request`; mode-sensitive commands use exhaustive option/result unions.
Version-extensible administration replies and application-defined Lua/function
results accept a custom decoder. Encoding-only entries require dedicated
connection-state handling; they are not ordinary requests.

```roc
get = Commands.Strings.get("key")
value = Execute.request!(config, get, transport)?
match value {
    Present(bytes) => use_bytes(bytes)
    Absent => handle_missing({})
}
```

Required variadic arguments use `NonEmpty`, and count prefixes are derived from
the supplied values. Numeric scores, coordinates, and decimal results remain
exact bytes rather than being rounded through client floating-point conversion.
Redis validates numeric syntax, server capabilities, and stateful constraints.
A server older than the command or selected option can return a server error.

For custom semantics, use `Request.new(command, decoder)`. The decoder may
compose a whole RESP value into one application value and use its own error type.
`Reply.utf8(bytes)` validates text explicitly. Raw Redis errors are intercepted
before invoking the request decoder.

`Reply.UnexpectedReply` deliberately retains the complete actual reply for
diagnostics. Before queueing or storing errors long-term, map them to a compact
application-owned tag/metadata record. Rendering the entire reply with
`Str.inspect` and then truncating the text still constructs that full rendering.

Raw `Decoder.init` now uses the same conservative per-reply defaults as
`Config.default` (8 MiB bulk, 16 MiB frame). Opt into larger values explicitly
with `Decoder.with_limits(Decoder.redis_compatible_limits)`. Direct decoder
callers must additionally bound input chunks and total retained replies/bytes;
per-reply limits are not an exchange or heap-memory limit. `Execute` supplies
read-size and exchange-byte budgets. Those budgets apply at execution, not to
the application's earlier command/batch construction or concurrent exchanges.

## Supplying a transport

`Execute.Transport` specifies semantics, not a networking implementation.
`Transport.from_bytes_io` builds one from a raw byte reader and writer, folding
the empty-is-`End` adapter that every integration otherwise repeats:

```roc
transport = Transport.from_bytes_io({
    read_bytes!: |max_bytes| stream.read_up_to!(max_bytes, idle_timeout_ms),
    write_all!: |bytes| stream.write!(bytes, idle_timeout_ms),
})
```

`Transport.new` takes a reader that already yields `Data`/`End` when the platform
distinguishes a definitive EOF from a short read itself.

`Data` contains 1 through `max_bytes` bytes. `End` means definitive EOF; a
timeout is an error. `write_all!` succeeds only after accepting the entire buffer.
The application owns sockets, TLS, close/discard behavior, cancellation, deadlines,
and exclusive access for the entire exchange. The basic-cli example uses per-I/O
idle timeouts; a deadline-aware adapter can capture a total deadline instead.
The basic-webserver example opens a fresh connection per HTTP request; pooling
remains deliberately out of scope.

```roc
results = Execute.batch!(
    config,
    Batch.each([
        Commands.Session.ping(),
        Commands.Session.echo("hello"),
    ]),
    transport,
)?
# results preserves one Try per element, even after a semantic/server error.
```

A batch uses one `write_all!` call and reads all expected replies: one pipelined
exchange, potentially multiple transport reads, not one round trip per command.
`Batch.all` returns the first semantic failure after consuming the whole exchange.
`Batch.map2` composes heterogeneous requests into one semantic value. Batching
does not provide transaction atomicity. For MULTI/EXEC, use
`Commands.Transactions.queued` and `exec_batch`, holding the same connection
exclusively for the entire transaction.

## Failure and scope guarantees

- `RequestRejected`: no transport effects occurred.
- `ExchangeFailed`: discard the stream. A partial write, timeout, protocol
  failure, or excess reply does not establish whether Redis executed a command.
- `ServerError` / `ReplyDecodeFailure`: the expected reply was fully consumed;
  framing is aligned, but command side effects and connection mode still matter.
- Batch element errors stay in each element with `Batch.each`; `Batch.all`
  or composed decoders can instead return a semantic batch failure.

There are no implicit retries or redirection handling. Extra complete or partial
replies in the current read are rejected. Extra bytes arriving in a later read
cannot be detected without additional I/O; callers must use an ordinary,
exclusive one-command/one-reply RESP2 connection.

Subscription changes, MONITOR, tracking invalidations, HELLO/protocol switching,
reply suppression, QUIT, and SHUTDOWN need dedicated lifecycle handling.
Their encoding APIs do not promise ordinary execution. `Execute.no_reply!`
accepts only `NoReply.unsafe_assume_suppressed(...)` and a write capability.
It cannot prove server state or acknowledge execution; it has no reply-decoder
error. Do not use it for a command that replies before closing.

RESP3, streaming subscriptions, cluster routing, pooling, TLS implementation,
and automatic retry are not implemented by this package.

## Additional qualification and diagnostics

`just backend-check dev speed size` builds and executes the package, transport
contracts, both live platform integrations, and the bundled consumer with each
selected backend. The orchestration itself stays dev-built. CI defines native
Linux/macOS jobs for all three backends; optimized execution remains experimental.

Generated properties reuse [roc-fuzz](https://github.com/lukewilliamboswell/roc-fuzz).
See [targets, compatibility, and replay instructions](../integration/fuzz/README.md).
The flake runs bounded generated checks on the two architectures supported by
that platform release, in addition to ordinary `expect` and runtime contracts.

`just memory-profile smoke 1` measures each bounded memory case in a separate
process; `full 3` repeats the complete matrix three times. Output is validated
JSONL with source/backend identity and host maximum RSS in bytes, not allocation
counts or isolated heap usage. `just benchmark-decode bulk 32 0 1 100000 42`
runs a seeded decode-only diagnostic. See [perf.md](../perf.md) before interpreting
either diagnostic as application performance.

Incomplete bulk replies keep a bounded small prefix flat, then balance received
pieces geometrically to avoid repeatedly copying the entire growing payload.
Protocol limits still bound accepted bytes, not process RSS. Start diagnostics
with the smoke suite; the full suite includes large and single-byte-fragmented
cases. See `perf.md` for measured costs and the remaining small-fragment tradeoff.
Functional test success is not a production heap guarantee.

## Roc nightly issues

Minimal reproductions for compiler defects discovered while developing the
package live under `roc-bugs/`, each with the exact nightly and reproduction
commands. They are intentionally separate from package tests.

## Feedback and contributions

Licensed under [Apache 2.0](../LICENSE). See [NOTICE](../NOTICE) and
[third-party provenance](../THIRD_PARTY.md). The package includes its own copies of
the license and notice for downstream redistribution.

See [CONTRIBUTING.md](../CONTRIBUTING.md) for the smallest checks and generated-file
ownership. The [four focused API reviews and community questions](../docs/COMMUNITY-FEEDBACK.md)
identify the feedback we want before stabilizing the API. Upstream provenance
is recorded in [THIRD_PARTY.md](../THIRD_PARTY.md).
