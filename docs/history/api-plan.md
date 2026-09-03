# Redis API redesign plan

Status: all approved implementation and verification tasks complete September 7,
2026. Deferred extensions and validation limits are recorded below.

This records the API walkthrough decisions through September 7, 2026. Accepted
directions below preserve the original decision register. The completion report
records the implemented choices; deferred extensions remain out of scope.

## September 8 approved hardening follow-up

- Reuse `roc-fuzz` for typed generation, coverage-guided execution, replay, and
  minimization. Four bounded targets cover semantic RESP round trips, an
  independent one-shot grammar, structured malformed frames, and command
  encoding/budgets. No project-local random engine was added.
- Add the independent 142-case transport failure-prefix runtime matrix and
  qualify selected dev/speed/size subjects through the same live adapters and
  downstream bundle consumer. Native Linux/macOS CI jobs are configured;
  local arm64 macOS execution is distinct from pending remote CI evidence.
- Give raw Decoder initialization the same conservative limits as Config;
  retain the larger explicit Redis-compatible profile. Preserve rich semantic
  errors and document compacting them before long-lived storage.
- Add Roc-only process memory orchestration and a seeded decode-only runner.
  Preserve raw evidence, exact source identities, controlled decoder variants,
  limitations, and resulting memory findings in `perf.md`.

The original deferred boundaries—pooling, RESP3, routing, streaming adapters,
and automatic retry—remain unchanged. Optimized backends remain experimental.

Follow-up completed: bulk buffering now uses a bounded flat prefix and
geometrically balanced received pieces. All 933 package expects pass across
dev/speed/size, as do live qualification, 400,000 generated cases, and the full
42-case memory suite on dev and speed. A generous fragmented-bulk regression
deadline is part of Nix checks. The small fragmented-reply timing tradeoff is
explicit in `perf.md`. The earlier deep-batch memory inference was invalidated:
the synthetic probe captured whole plans unlike production `Batch.map2`.
The probe and documentation are corrected; no Batch API change was justified.

## Purpose and constraints

Build a production-quality, platform-agnostic Redis package for current Roc.
Protocol encoding, parsing, command construction, and semantic reply decoding
remain pure. Effects enter only through a small byte-stream transport contract.

- Keep platform dependencies out of `package/`.
- Prefer Roc conventions, nominal types where they clarify invariants, static
  dispatch, and compile-time evaluation of constant inputs.
- Keep the initial public surface small while exposing the regular Redis command
  catalog through typed APIs.
- Preserve binary data exactly; text conversion is explicit.
- Use the pinned compiler's dev backend initially. Revisit other backends after
  correctness; record newly discovered compiler bugs in `roc-bugs/` with a minimal
  repro, compiler version, expected/actual behavior, and control where useful.
- Keep development reproducible through Nix. Project orchestration stays in Roc
  on basic-cli. Python remains appropriate as a benchmark subject, not a legacy
  project scripting dependency.

## Decision register

### 1. Module organization

Explore modest namespacing to reduce the current flat collection of modules.
`Commands.Connection` is a candidate for the Redis connection-command family;
it must not imply ownership of sockets. Verify supported package/module syntax
before selecting the layout. Avoid extra wrapper modules solely for appearance.

The agreed execution names are `redis.Execute.request!`, `redis.Execute.batch!`,
and `redis.Execute.no_reply!`.

### 2. Bytes, literals, and naming

- Replace numeric ASCII constants with character literals such as `'P'` wherever
  a byte is intended, including encoders, command generation, and tests.
- Prefer snake_case command names, for example `get_set`; review compound names
  consistently rather than mechanically splitting every Redis token.
- Explore a nominal, opaque `Bytes` type with `from_quote` for string literals
  and explicit construction from arbitrary bytes.
- Explore non-empty byte/collection types for required arguments. Prove their
  literal and constant-validation ergonomics on the pinned compiler before
  committing the public API.
- Keep raw byte access available for transport and custom protocol work.

### 3. Protocol values and reply decoding

- Preserve null bulk strings (`$-1`) and null arrays (`*-1`) as distinct protocol
  values. A semantic decoder may intentionally map both to one application value.
- Pair requests with custom pure decoders: several protocol values may compose
  into one semantic result.
- Allow application-defined decoder errors rather than fixing all requests to
  the library's reply-error type.
- Provide a composable UTF-8/string decoder, initially `Reply.utf8`; defer extra
  convenience combinations until real use demonstrates their value.
- Preserve Redis server errors as raw bytes, with a non-lossy classifier.
  Distinguish server errors, semantic reply-decoding failures, malformed protocol,
  transport failures, and local validation/limit failures.

### 4. Typed commands and execution families

- Regular command constructors produce typed requests pairing wire commands with
  semantic decoders. Provide exhaustive typed option handling and selectively
  narrower helpers where useful.
- Keep raw command construction and custom decoding as explicit escape hatches.
  Generated raw catalog details should not dictate the ergonomic public API.
- Separate sender families by actual response behavior. A no-reply operation
  cannot produce `ReplyDecodeFailure`.
- Explicitly classify request/reply, batch, no-reply, streaming, connection-closing,
  and protocol/mode-changing commands before defining which are executable in the
  initial API. Catalog coverage does not imply every command fits `request!`.
- Scope streaming, subscription, and expected-disconnection execution separately;
  do not force them into ordinary request/reply behavior.
- Avoid the term `Fence`; the discussed reply-mode diagnostic name is
  `ReplyModeNotConfirmed`. Final naming and confirmation semantics need review
  alongside the no-reply family.

### 5. Batches

- Encode a batch into one outbound buffer and submit it through one write-all
  effect. This is one logical network round trip, not a guarantee about TCP
  packet count or an atomic Redis transaction.
- Preserve an individual `Try` for each element in the per-element batch API.
  Consume the expected replies even when a semantic element fails, provided the
  protocol and transport remain usable.
- Support composition into one semantic value. The discussed shapes are
  `Batch.each` for per-element results, a stricter `Batch.all`, and explicit
  composition/custom decoding for heterogeneous results. Verify concrete Roc
  signatures before publishing them.
- Keep transport/protocol failures outside the list of ordinary element results;
  define what completed-prefix information is retained on those failures.

### 6. Configuration

Use an opaque validated `Config` and a separate builder. Setters are pure and
infallible; one final build validates all invariants and returns `Try`.

Intended usage:

```roc
Ok(production_config) =
    Config.default
    |> Config.with_read_size(32_768)
    |> Config.with_max_request_bytes(64 * 1024 * 1024)
    |> Config.build
```

Here `Config.default` seeds the builder. There is one `Ok` destructure around the
whole configuration expression, rather than one per setter. Recommend placing
this destructure directly at module scope. Tests assert on that value instead of
repeating the destructure inside `expect` on the pinned compiler. Constant inputs
should allow compile-time validation; runtime inputs still require handling the
build result. This is an API goal, not a claim about the compiler's internal
number of evaluation passes.

- Use Roc's defaultable nominal fields where appropriate internally.
- Do not expose a `from_settings` route that bypasses validation.
- Pass configuration into execution; do not return unchanged configuration or
  client records with each result.
- Provide conservative defaults and an explicit Redis-compatible profile; avoid
  an unbounded profile. Final numeric budgets require measurements and review.
- Cover decoder bounds, read size, outbound request bytes, cumulative response
  bytes, and batch command count, with precise budget scope and overflow checks.

### 7. Transport and platform boundary

Keep the structural effect record limited to `read!` and `write_all!`.

- A read returns non-empty data up to the requested size, or explicit EOF.
  Timeouts are errors, not EOF.
- Write-all succeeds only after accepting every byte; failure may follow partial
  transmission and cannot establish that Redis did not execute a command.
- The caller supplies exclusive connection use for the entire exchange, including
  all writes and reads. Per-socket-operation locking is insufficient.
- Connection creation, closing, TLS, deadlines, retries, and pooling belong to the
  platform/application. Preserve concrete transport error types.
- Keep parsing state local to ordinary execution. No public client/session value
  or bound sender is needed initially.
- Use inline transport records in the basic-cli and basic-webserver examples.
  basic-cli reuses a stream sequentially; basic-webserver opens one per HTTP
  request. Defer pooling and document the example's connection strategy.
- Split errors so callers can distinguish connection reusability from command
  outcome certainty. Returning a semantic error must not imply execution failed.

### 8. Memory and resource behavior

Audit command construction, encoding, incremental parsing, and batch collection.
Use local mutable variables, loops, and known-capacity list reservation where they
improve measured allocation behavior without weakening correctness.

Reject oversized outbound work before transport effects. Check sizes without
overflow before allocation. Avoid repeated concatenation, reparsing, or retention
of large backing buffers for small slices where practical. Track peak retained
memory as well as throughput. Apply limits consistently across fragmented input
and multiple replies; document whether each limit is per value or per exchange.

### 9. Unexpected replies and connection state

Retain the open research item: compare established clients' behavior for extra
top-level replies, unread data, push messages, and connection reuse. Separate RESP2
request/reply behavior from future protocol modes. Specify what the library can
detect in already-read bytes and what it cannot know about unread socket data.

Do not silently discard extra bytes or weaken connection disposition merely to
match another client's behavior. Review the result with the user before changing
the current strict response-count policy.

### 10. Additional benchmark candidates

Keep Python/redis-py and Go/go-redis as the existing baseline. Rust/redis-rs and
C/hiredis are approved as the next benchmark subjects. Node.js remains a later
candidate. Rust and C are now implemented and their ten-order smoke campaign
passes; performance measurements remain separate from that smoke check:

1. **Rust / [redis-rs](https://github.com/redis-rs/redis-rs).** A useful native-code
   comparison with a higher-level client. Start with its synchronous connection
   and explicit pipeline API to match the current Roc execution model.
2. **C / [hiredis](https://github.com/redis/hiredis).** A minimal client comparison
   that helps assess overhead from richer client APIs. Treat it as a reference,
   not an assumed performance ceiling; use binary-safe command APIs.
3. **JavaScript / [node-redis](https://github.com/redis/node-redis).** Adds a common
   event-loop runtime. Account explicitly for automatic pipelining within one
   event-loop tick. Match the number of outstanding commands and batch boundaries
   rather than comparing concurrent JavaScript with sequential Roc.

Rust and C offer the most immediate diagnostic value for this package. Consider
Node.js afterward. C# / [StackExchange.Redis](https://github.com/StackExchange/StackExchange.Redis/blob/main/docs/PipelinesMultiplexers.md)
is a useful later managed-runtime comparison when testing concurrent workloads;
its multiplexing behavior must be reported and controlled in the comparison.

These are client-and-runtime comparisons, not isolated language rankings. Pin
dependencies/toolchains through the reproducible benchmark setup, use optimized
builds for native subjects, and report Roc's dev backend explicitly. Match RESP
version, payloads, connection count, outstanding work, and pipeline size; exclude
transactions, automatic retries, and client-side caching from the baseline.
Record Python's parser implementation and optional native accelerators. Warm up
JIT runtimes before sampling and keep correctness checks equivalent.

Network round trips can hide client costs. Supplement live Redis measurements
with encode/decode benchmarks over matching in-memory fixtures where a client
exposes suitable APIs, clearly separated from end-to-end results. Measure
allocation/retained-memory behavior where tooling permits. Revisit the current
all-order-rotations benchmark strategy before expanding the subject set:
factorially many permutations become impractical; use a balanced, recorded order.

## Implementation sequence

### Completion report

- All six implementation phases below are implemented. `Commands.<Family>`
  covers all 405 included catalog commands across 18 families, with a generated
  typed API/sender manifest. Raw constructors remain explicit escape hatches;
  legacy `Client`/`Operation` have been removed and their regression coverage migrated.
- Opaque byte/name/command invariants, nominal positive and nonempty operands,
  one module-level configuration destructure, custom decoders, typed batches,
  and the three Execute sender families are in place. Null kinds stay distinct.
- Namespaced option constructors hit a recorded compiler limitation; inferred
  nonempty record literals or direct-module nominal constructors are documented.
  Invalid constant literals/configuration and opaque bypass attempts have
  compile-rejection fixtures. Newly found compiler issues have repros and controls.
- Both platform examples and the bundled consumer use the new API. CLI coverage
  includes ordinary typed command families and detects newer optional commands.
  Server administration/cluster mutations are not exercised destructively.
- [The quality review](../../QUALITY-REVIEW.md) records the post-compilation invariant,
  error-path, memory, and cross-client extra-reply review. Bounded encoding reserves
  one buffer; decoding does not reserve untrusted advertised sizes; execution uses
  a loop tested with 25,000 one-byte payload reads. Strict extra-current-read
  rejection remains the deliberate policy.
- Full native `nix flake check path:. --print-build-logs` passes: 925 package
  expectations, deterministic transport contracts, 13 bundled-consumer expectations,
  both live integrations, catalog verification, compiler-bug checks, native subject
  tests, and live/codec benchmark smoke checks. All four systems evaluate with
  `--all-systems --no-build`; only arm64 macOS was executed here.
- Roc orchestrates the five-client benchmark (Python, Go, Rust, C, and Roc), with
  ten position-balanced orders. A server-free Roc/hiredis codec supplement uses
  matching binary fixtures. The final quiet campaigns retained 600 live and
  40 codec samples; [results and limitations](../../perf.md) are
  retained in the repository. Only benchmark Python sources remain.
- Optimized Roc backends, pooling, routing, RESP3, streaming adapters, retries,
  and additional language subjects remain the explicitly deferred follow-ups,
  not incomplete requirements of this implementation. Exact allocation profiling
  is not claimed; the local C sanitizer attempt was inconclusive.

### Ordered work

1. **Resolve API experiments.** Check namespacing, literal construction,
   non-empty types, config folding, and typed batch composition on the pinned
   compiler. Produce small compiled examples and record any compiler defects.
   Review the unresolved sender scope and reply-handling choices.
2. **Implement pure foundations.** Introduce byte types, distinct null values,
   config builders, and composable reply decoders. Establish encoding and parsing
   invariants before changing effects.
3. **Implement requests, batches, and execution.** Introduce the approved sender
   families and error contracts; remove unchanged-client return plumbing. Preserve
   the thin transport boundary and specify connection disposition on every path.
4. **Migrate the command catalog.** Update the Roc generator and command metadata
   handling together. Add typed option/reply APIs, consistent names and literals,
   and explicit treatment of special-mode commands. Verify catalog coverage and
   downstream usability, not just generated file counts.
5. **Migrate examples and documentation.** Update both platform integrations,
   package exports, bundled consumer, and usage examples. Keep pooling deferred.
   Audit for obsolete project Python scripts while retaining Python benchmarks.
6. **Review production quality and performance.** Complete an independent pass
   over invariants, error paths, resource limits, API clarity, and memory behavior.
   Run comparable Redis benchmarks against Python and Go and record limitations.

These phases may be split into reviewable changes. They are not authorization to
implement every speculative option before the plan is reviewed.

## Verification and completion criteria

- Pure tests cover exact wire bytes, arbitrary binary payloads, both null kinds,
  nested values, fragmentation at every boundary in representative frames,
  malformed lengths/terminators, truncation, overflow, and configured limits.
- Compile checks demonstrate valid constant configuration/literals and reject
  invalid constants; runtime counterparts verify ordinary error handling.
- Deterministic transport tests exercise short reads, EOF, read/write failures,
  malformed and excess replies, pre-write rejection, batch element errors, and
  connection disposition. No-reply tests verify its distinct effect/error shape.
- Both live platform tests run against isolated Redis through Nix. The webserver
  proof covers HTTP handler to Redis and back with exact response verification.
- The generated catalog remains reproducible and accounted for, and the bundled
  package works as a downstream dependency with no platform imports in its core.
- Benchmark thousands of sequential PING, binary SET/GET, INCR, and pipelined
  operations against redis-py and go-redis. Keep setup outside timing, validate
  results, retain versions/raw samples, and distinguish dev-backend measurements
  from future optimized-backend performance.
- Update README/API docs to match the shipped surface. Record unresolved platform
  or compiler limitations honestly. Complete the production-quality review after
  compilation and functional tests succeed.
