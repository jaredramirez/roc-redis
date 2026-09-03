# API and implementation review

Reviewed against Roc nightly-2026-09-04-c125b82 and Redis 8.10.1.
This is a scoped review, not a claim that every server/version/platform combination
has been exhaustively tested.

## Invariants and memory

- Command is opaque. Every constructor establishes a nonempty name; read-only
  `to_parts` supports command introspection without permitting invalid construction.
- Constant configuration is built once at module scope. Runtime values retain
  ordinary error handling. Compile-rejection fixtures cover zero positive literals,
  empty names, invalid configuration, and opaque-constructor bypass attempts.
- Outbound size is checked before allocation using subtraction from the remaining
  budget, avoiding aggregate U64 overflow. Encoding reserves the exact measured
  size and appends into one buffer; it does not build one encoded buffer per command.
- The executor reserves the known, validated reply count. Its read loop does not
  grow the stack with fragmentation. A runtime 25,000-byte binary payload is read
  one byte at a time, in addition to every two-part split of all 256 byte values.
- Untrusted bulk/array headers do not trigger advertised-size allocation. Decoder
  buffers grow with received data, subject to frame, bulk, array, depth, line,
  value-count, and exchange byte limits. Span copies avoid byte-by-byte bulk work.
- `concat(sublist(...))` is retained instead of `append_sublist`: the latter hits
  the frozen compiler allocation repro. No zero-copy or allocation-free claim is made.
- Semantic list decoders reserve capacity from already parsed bounded arrays.
  Batch.each preserves each Try; Batch.all can stop semantic decoding only after
  all wire replies have been consumed. Deeply nested user composition can still
  cost more allocations than a flat batch; no optimizer assumptions are required.

## API and error paths

- Transport rejection happens before effects. All exchange failures require
  stream disposal and leave execution outcome uncertain; no retry is implicit.
- Server errors retain exact bytes and are separate from custom decoder failures.
  Semantic errors preserve framing, not transactional success or connection mode.
- All 405 included catalog commands have accounted-for namespaced APIs. The
  generated typed manifest distinguishes typed/custom-decoder requests from
  encoding-only lifecycle and streaming commands. Catalog coverage is not a
  claim that every option combination was executed against a server.
- Decimal scores, coordinates, and numeric text preserve bytes. Redis validates
  numeric syntax and state-dependent constraints. Required variadics and their
  count prefixes cannot disagree. Introspection schemas remain caller-owned.
- Reverse sorted-set helpers accept logical min/max consistently and reverse
  wire order internally. Live tests caught the previous inconsistency.
- Live Redis and pinned source confirmed that ARSCAN and ARGREP WITHVALUES both
  use nested index/value pairs; their online return-information text incorrectly
  says flat. Regression tests cover the actual protocol.
- Stream pending tombstones, bulk/array nulls, claim delivery metadata, transaction
  cancellation, and element failures remain distinct. Hash expiration values
  use a neutral `Value` tag for both relative TTLs and absolute timestamps.
- CLI live tests replace their already-owned random key inside MULTI/EXEC with
  TTL installation in the same transaction. Optional newer commands are detected
  before testing so the older CI Redis is still supported. Cluster topology
  mutations and dangerous server administration are construction/decoder-tested,
  not executed against an external cluster.
- basic-webserver remains a thin fresh-connection adapter. Pooling, routing,
  RESP3, streaming feeds, TLS implementation, and retries remain explicit non-goals.

## Extra-reply research and retained policy

The reviewed clients have connection-owned readers and lifecycle machinery; their
behavior is not interchangeable with this library's two-effect boundary.

- redis-py 6.4.0 checks readability when checking a connection out of its pool;
  unexpected data causes disconnect/reconnect and another readiness check.
  [Source: ConnectionPool.get_connection](https://github.com/redis/redis-py/blob/v6.4.0/redis/connection.py).
- go-redis 9.12.1 reads each pipeline command's reply and retains command-local
  Redis errors; a non-Redis read error stops decoding and marks the remainder.
  [Source: pipelineReadCmds](https://github.com/redis/go-redis/blob/v9.12.1/redis.go).
- redis-rs 1.6.0 reads the requested count, accounts separately for push messages,
  and retains its first read error while draining the response loop.
  [Source: req_packed_commands](https://github.com/redis-rs/redis-rs/blob/redis-1.6.0/redis/src/connection.rs).

Decision: retain strict rejection of extra complete/partial replies in the current
read. Do not add socket peeking, background reads, or a buffered connection owner
without a separate API review. This cannot detect unsolicited bytes arriving
after the final read; the exclusive ordinary RESP2 precondition remains essential.

## Validation and limitations

The package/automation suite, deterministic transport contracts, downstream bundle,
and both isolated platform integrations pass on arm64 macOS with the dev backend.
All-system flake evaluation passes; this is not execution on all four systems.
Rust passes strict Clippy; the C subject passes its normal unit tests and static
analysis. The attempted AddressSanitizer run stalls on this Nix/macOS toolchain,
so it is inconclusive, not a passing sanitizer result.

Only benchmark Python sources remain; project orchestration is Roc/basic-cli.
The full native flake check also covers all 925 package expectations, both live
platform integrations, the 13-expectation bundled consumer, generated catalog,
compile-rejection contracts, and live/codec benchmark smoke tests. Server-free
codec measurements compare Roc and hiredis public APIs only; the live campaign
includes all five clients. Allocation counts and retained-memory profiles were
not measured, and timing results do not establish those properties.
Compiler limitations have repros and context under `roc-bugs/`. Optimized Roc
backends remain unsupported pending the recorded miscompilation fixes.

## September 7 nightly upgrade

The project pin, all four release hashes, package headers, and active benchmark
metadata now use `nightly-2026-09-07-14d9829`. Historical benchmark data still
identifies the compiler actually used (September 4); it was not relabeled.

The upgrade exposed a cached duplicate-package-alias abort, reduced under
`roc-bugs/cached-package-alias-duplicate/`. The two affected webserver expectation
commands use `--no-cache`; their checks, live builds, and application behavior
are unchanged. The reduced cache problem also exists on September 4.
The frozen interpreter decoder repro now fails all three cases rather than one;
the verifier records that observed change while retaining the passing dev control.
The later tuning pass promoted the state-detachment workaround into the decoder;
the frozen failing repro remains unchanged.

The complete native flake check passes on this pin: 925 package expectations,
transport contracts, both isolated live platforms, 13 downstream expectations,
catalog verification, compiler-bug checks, docs/bundle generation, and both
benchmark smoke checks. Re-enter `nix develop` to replace an already-open shell's
older compiler wrapper.
Benchmark results are observations of this pinned dev toolchain, not promises
about optimized Roc or production network conditions.

## Pipeline tuning review

Consolidated results, tradeoffs, and reproduction guidance live in [perf.md](../../perf.md).

Bounded encoding still measures the complete request before reserving its exact
wire size or writing bytes. Decimal headers now append digits directly into that
buffer; regression tests cover zero, decimal boundaries, U64 maximum, existing
buffer contents, binary payloads, and exact/one-byte-short request budgets.

Simple/error line decoding copies received spans while retaining the scalar path
for delimiters and errors. A scalar oracle compares full state and failure output
at every two-chunk split across valid, malformed, nested, binary, and unfinished
frames with multiple line/frame budgets. It preserves error offsets and limits;
it does not preallocate untrusted advertised lengths. Batch decoding now indexes
replies instead of repeatedly creating tail slices, retaining indexed failures
and each element's Try result.

All 925 package expectations pass on dev, speed, and size on arm64 macOS. Speed
also passes the runtime transport contract, both isolated live integrations, and
the 13-expectation bundled consumer. Full native Nix checks and four-system flake
evaluation pass. Optimized execution is still experimental, not the default.
The new effectful-record JSON inference hang has a minimal repro and annotated
control under `roc-bugs/effectful-record-json-inference/`; the bug verifier checks
both. Explicit local record types avoid that hang in the transport diagnostic.

Stage timings and adapter traces supplement end-to-end benchmarks; they do not
measure allocation counts, peak retained memory, or kernel syscall counts.

## September 8 hardening review

The raw decoder now defaults to the same conservative limits as Config, with
an explicit larger Redis-compatible profile. Four new expectations bring the
package to 929. Rich semantic errors remain intact; documentation now warns
that retaining them can retain the complete unexpected reply.

Four independent generated targets reuse the pinned roc-fuzz platform. The
hermetic smoke gate passes 10,000 generated inputs per target. The reference
grammar is separate from production parsing and checks completed prefixes;
structured mutations exercise cases unlikely to arise from uniform random
bytes. Runtime transport qualification adds 142 enumerated cases, including
failures after each prefix of 0..16 completed replies.

Full local dev/speed/size qualification passes package expectations, executed
client and transport contracts, both isolated live integrations, and downstream
bundle consumption. Controllers remain dev-built. Native Linux/macOS CI
qualification and generated-test jobs are configured, not remotely verified.
The newly discovered read-only-working-directory bundle failure has a verified
reduced repro and passing control under `roc-bugs/`; the runner bundles from
its own writable temporary copy and restores the working directory.

Roc-only decode and process-memory diagnostics now retain validated raw
measurements. The initial smoke matrix covers twelve cases on dev and speed,
three process samples each. RSS includes runtime and fixtures and is not an
allocation count. Larger fragmented bulk probes exposed substantial allocation
high-water and poor scaling; passing functional gates does not resolve that
production risk. See `perf.md` for the controlled experiments and outstanding
memory limitation, rather than interpreting this review as unrestricted
production-performance certification.

### Completed memory follow-up

The final decoder uses a bounded 4 KiB flat prefix followed by geometrically
balanced received pieces. This removes repeated whole-prefix growth for large
fragmented bulks without changing the public API, limits, or errors. Four new
buffer-invariant expectations bring the package to 933; all pass on dev, speed,
and size. Independent review verified order, logarithmic piece count, reachable
integer safety, the threshold transition, and single-piece finalization.

The final source also passes 400,000 generated cases, all-backend live/bundle
qualification, and native Nix checks. The full 42-case memory suite completes
on both dev and speed, including 8 MiB single-byte fragments. A 30-second
large-fragmented-bulk regression check is now included in Nix. The residual
approximately 11% slowdown for a 4 KiB/31-byte-fragment decode-only workload is
documented alongside improvements; this is not claimed as a universal speedup.

The original deep-batch retention inference was wrong: the synthetic probe
captured whole intermediate plans, unlike production `Batch.map2`. The probe
now extracts decoder functions, validates wrong count/value behavior, and labels
its output as a model. Matched evidence shows roughly 4 MiB rather than 217 MiB
for the corrected speed model at 4,096 layers. No production Batch change was
needed. Historical measurements are preserved with explicit correction notices.
