# roc-redis client benchmarks

The [performance reference](../perf.md) consolidates measurements, lessons,
tradeoffs, and the future tuning workflow. The [dataset index](results/README.md)
lists retained raw evidence; this guide defines the benchmark contracts.

## Pipeline diagnostics

`just benchmark-stages 2000` (or `nix run .#benchmark-stages -- 2000`)
emits 30 validated `roc-redis-stages/v1` records: five samples of bounded wire
encoding, whole-frame decoding, 31-byte fragmented decoding, semantic decoding,
plan construction plus decoding, and a mocked transport exchange. Each sample
warms up with 100 iterations. Even iteration counts use batches of 100 commands;
odd counts use 101. Two runtime-sized fixtures alternate to discourage constant
evaluation. Plans and fixtures are prepared outside timing except in the
explicit plan-construction stage. Exact output validation remains inside timing.

These are diagnostic microbenchmarks, not additive profiler measurements:
stages overlap, run in a fixed order, and include validation and harness costs.
Roc uses UTC wall-clock timing. Every record identifies the compiler, build
variant, and immutable Nix source. Default builds use dev; an isolated flake copy
with `benchmarkBuildMode = "speed"` selects experimental speed for the live,
codec, and stage subjects without optimizing the orchestration controllers.

`just transport-profile` (or `nix run .#transport-profile`) starts an isolated
Redis and traces adapter reads/writes while validating ten iterations of each
live workload. SET/GET uses the same 32-byte binary payload as the live benchmark;
the diagnostic's uniquely owned key has a 60-second backup TTL and is deleted
on success. The supervised Redis is torn down on failure too.
This trace is **untimed**: JSON logging can affect scheduling and fragmentation.
It counts platform-adapter calls and byte lengths, not kernel syscalls or memory
allocations. Transport traces and stage smoke runs are included in Nix checks.

## Server-free codec supplement

`just benchmark-codec 10000` (or `nix run .#benchmark-codec -- 10000`)
compares Roc's dev-backend encoder/decoder with hiredis's public codec APIs.
It emits 40 `roc-redis-codec/v1` JSONL records: ten samples, two implementations,
and two workloads. Subject order alternates; each occupies each position five times.
There is no Redis process or socket. This is a Roc/hiredis diagnostic, not a
five-language codec ranking; no private client internals are benchmarked.

Each sample warms up with 1,000 operations. Matching runtime-seeded fixtures
cycle through 256 binary 32-byte payloads. Encoding constructs a RESP SET command;
decoding consumes a complete bulk-string frame with a fresh decoder per operation.
Fixture setup is outside timing; allocation, decoder initialization, and exact
byte validation are inside. Roc includes its bounded encoding checks. hiredis
uses `redisFormatCommandArgv` and `redisReaderGetReply`. Different safety checks,
representations, and allocators remain part of the comparison. Both are built
before timing; Roc uses UTC and hiredis a monotonic clock. Source IDs and runtime
versions are retained in every record. No allocation counts are inferred from
elapsed time.

## Live Redis comparison

These programs compare client-side request/response overhead for `roc-redis`,
Python's `redis-py`, Go's `go-redis`, Rust's `redis-rs`, and C's `hiredis`. They implement the same workload
contract and emit one JSON object per measured sample on standard output
(JSON Lines). Diagnostics go to standard error and a validation failure exits
non-zero.

The programs deliberately time only workload execution. Compile/build time,
process startup, connection setup, lease acquisition, warmup, and cleanup are
outside every timed interval. The supported Roc subject currently uses the dev
backend. These results are suitable for repeatable toolchain characterization
and regression work, but are not optimized Roc production-performance claims.

## One-command comparison

From the repository root, Nix builds the pinned subjects, starts one isolated
non-persistent Redis server, runs and validates all samples, then tears
everything down:

```sh
nix run .#benchmark
nix run .#benchmark -- --all-order-rotations \
  --iterations 20000 --samples 7 \
  --jsonl results.jsonl
```

The default is 10,000 measured operations, 1,000 warmup operations, and five
samples per workload and client. `--jsonl` retains every validated raw sample;
the terminal summary reports medians. `just benchmark` forwards additional
arguments to the same Nix app, while `just benchmark-smoke` is a functional
check rather than a performance run.

The Roc controller can run one selected order with `--order-rotation 0..9`, or
all ten balanced orders in one campaign with `--all-order-rotations`:

```sh
nix run .#benchmark -- --all-order-rotations --jsonl results.jsonl
# Equivalent convenience recipe:
just benchmark-all --jsonl results.jsonl
```

Orders 0–4 rotate `Roc/Python/Go/Rust/C` to the left by 0–4 positions. Orders
5–9 rotate `Roc/C/Rust/Go/Python` by 0–4 positions. Every subject appears twice
in each ordinal position. This is positional balance, not all 120 permutations
or complete pairwise carryover balance. Repeat campaigns when drawing
statistical conclusions; ordering does not eliminate thermal drift.

All 50 subject runs share one isolated Redis process, started and stopped once
by the controller. Rotation and position are included in each random run prefix,
so every subject run owns a distinct key set. With the defaults, the combined
summary median for each client/workload contains 50 samples (ten rotations by
five samples), and the retained JSONL contains 1,000 validated records.

## Shared command line

All five subjects accept:

```text
--host HOST              Redis host (default: 127.0.0.1)
--port PORT              Redis port (default: 6379)
--iterations N           measured operations per sample (default: 10000)
--warmup N               unmeasured operations before each sample (default: 1000)
--samples N              samples per workload (default: 5)
--pipeline-batch N       commands per pipeline write (default: 100)
--timeout-ms N           connect/read/write timeout (default: 5000)
--key-prefix PREFIX      exclusive safe-ASCII Redis key prefix
--nix-source-id ID       content-derived source ID (default: unmanaged)
--build-mode MODE        build mode (default: unmanaged)
--nix-system SYSTEM      Nix system (default: unmanaged)
--os OS                  operating system (default: unmanaged)
--arch ARCH              architecture (default: unmanaged)
--order-rotation N       balanced order ID, 0 through 9 (default: 0)
--subject-position N     one-based controller position (default: 0)
```

`iterations`, `samples`, `pipeline-batch`, and `timeout-ms` must be positive;
`warmup` may be zero. The numeric limits and key/host validation are identical
across subjects; `pipeline-batch` is capped at 65,536 commands, matching the
roc-redis client pipeline limit. If `--key-prefix` is omitted, each subject generates a
process-unique prefix. A supplied prefix must be exclusive to one benchmark
process at a time. An NX lease enforces that rule.
The Nix controller supplies and validates managed provenance and one-based
positions. Direct subject invocations deliberately report `unmanaged` metadata
and position zero unless the caller supplies truthful values.

Rust uses redis-rs 1.6.0 with default features disabled, a locked dependency tree,
one synchronous connection, and explicit non-transactional pipelines. Its Nix
build uses the release profile with thin LTO. C uses the flake's hiredis package,
`-O3`, binary-safe argv/length commands, and explicit append/drain pipelines.
Both use monotonic timers and verify direct/pipelined connection identity before
timing. `runtime_version` records their pinned compiler version. `build_mode`
continues to identify the campaign's Roc backend, not the native optimization
level. There are no automatic retry loops in either added subject.

The pinned hiredis 1.4.1 package has headers reporting 1.4.0. Nix supplies its
actual package version at C compilation so `client_version` identifies the
hash-pinned dependency; unmanaged builds fall back to header version macros.

Example invocations (compile or install dependencies before collecting data):

```sh
roc build --opt=dev --output=benchmarks/roc-benchmark benchmarks/roc.roc
./benchmarks/roc-benchmark --iterations 20000 --key-prefix roc-redis-bench:run-1

python3 -m venv .venv
.venv/bin/pip install -r benchmarks/python/requirements.txt
.venv/bin/python benchmarks/python/benchmark.py --iterations 20000 \
  --key-prefix roc-redis-bench:run-1

(cd benchmarks/go && go build -o ../go-benchmark .)
./benchmarks/go-benchmark --iterations 20000 \
  --key-prefix roc-redis-bench:run-1
```

For unbiased comparisons, build each subject first, run them against the same
isolated Redis process, alternate subject order across repetitions, pin CPU and
power policy where possible, and retain every JSONL sample rather than only a
best result.

## Workload contract

Each subject uses one persistent workload TCP connection and RESP2. Workloads
run in this fixed order, with samples numbered from one:

| Workload | One operation | Measured commands | Measured round trips |
| --- | --- | ---: | ---: |
| `ping_sequential` | Send and validate one `PING` | `iterations` | `iterations` |
| `set_get_sequential` | `SET key payload PX 86400001`, then `GET` and byte-compare | `2 * iterations` | `2 * iterations` |
| `incr_sequential` | `INCR key` and validate the exact counter | `iterations` | `iterations` |
| `ping_pipeline` | Send and validate `iterations` PINGs in bounded pipelines | `iterations` | `ceil(iterations / pipeline-batch)` |

The 32-byte binary payload, written here as hexadecimal, is identical in every
subject:

```text
000d0aff80526f632d5265646973000102030a0d7f80feff41424378797a00ff
```

Warmup performs the same operation count and validation as measurement. The
INCR key is reset to zero between warmup and measurement. Setup/reset commands,
the lease command, and final `DEL` are not included in reported command counts.
All mutable keys have a 24-hour TTL as a crash-safety backstop and are deleted
explicitly through a fresh connection on normal or error exit. The controller
limits each subject to 30 minutes, so its lease cannot expire during a valid
run. A standalone subject has no token-guarded cleanup: it must finish within
24 hours and its supplied prefix must remain exclusive for the entire run, or
another owner could acquire the expired lease before the original cleanup.
The extra millisecond on the TTL makes every client encode `PX`; go-redis would
otherwise select `EX` for a whole-second duration.
Automatic command retries are disabled in the Python and Go clients, matching
roc-redis's fail-fast behavior and preventing hidden extra commands. Both use a
one-connection pool; before timing, each performs a live `CLIENT ID` check that
proves its ordinary and pipeline paths borrowed the same already-open TCP
connection, including when `--warmup 0` is selected.

## JSONL schema

Every successful line has `schema: "roc-redis-benchmark/v2"`. It identifies the
runtime, exact client version, actual Redis server version, content-derived Nix
source ID, `build_mode`, Nix system, OS, architecture, order permutation, and
subject position; records the workload/configuration; and reports exact
`operation_count`, `command_count`, `round_trip_count`, and integer
`elapsed_ns`. Derived rates are intentionally omitted so downstream analysis
can apply one numerical policy to all subjects. `validated` is always `true`;
invalid responses abort instead of producing a timing.

Python is pinned to `redis==8.1.0` and Go to
`github.com/redis/go-redis/v9 v9.22.0`. The Go subject reads its go-redis module
version from embedded Go build information; the controller compares every
reported client version with the corresponding Nix pin. The Roc subject uses
the repository package at `0.1.0-dev` and basic-cli 0.22.2. Python and Go use
monotonic clocks. basic-cli currently exposes UTC nanoseconds rather than a
monotonic clock, so Roc records `timer: "utc_wall_clock"`; discard a Roc sample
if the host clock is adjusted during its timed interval.
