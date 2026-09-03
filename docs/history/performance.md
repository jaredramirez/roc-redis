# Historical performance investigations

These measurements describe earlier source snapshots, not the current package.
See [current performance guidance](../../perf.md) first.

## September 8: independent decode isolation and memory probes

These are new server-free diagnostics, not additional Python/Go live results.
The decoder runner alternates two runtime-seeded fixtures, validates every
result, and performs no command-encoding workload before timing. It includes
fixture lookup, chunk slicing, decoder initialization/feed/finish, collection,
and exact result comparison; it is not a measurement of just one parser call.

Three speed-built variants used identical conservative limits and the existing
state-detachment correctness workaround. Only Decoder differed:

| Variant | 32-byte bulk, ns/iteration, invocation medians | 100 simple 32-byte replies, µs/iteration |
| --- | ---: | ---: |
| Current tuned | 222.016 / 221.796 | 9.315 |
| Simple/error span path removed | 199.775 / 199.425 | 38.491 |
| Bulk branch moved before span path | 219.784 / 221.554 | 10.156 |

Lower is better. Bulk runs were ordered tuned, removed, moved, moved, removed,
tuned; each invocation has ten samples of 500,000 iterations and 100 warmups
per sample. No project compilation or other project benchmark ran concurrently.
The five-case broader sweep has ten samples per case/variant but only one
invocation, so treat its smaller differences as exploratory. Whole 64 KiB bulk
was approximately 17.1 µs for all three variants. The removed path costs roughly
4.1× on the simple-reply case, so it is not an acceptable blanket rollback.

Removing the span branch reproduces the tiny-bulk improvement without running
the encoder first. Moving it first does not recover that improvement. This
isolates the effect to decoder source/code generation, but does **not** establish
an instruction-cache, branch-prediction, ARC, or LLVM root cause. No branch-order
change was promoted from this experiment. Absolute timings cannot be pooled
with the earlier codec harness, which has a different timed body.

Raw evidence: [60 bulk samples](../../benchmarks/results/2026-09-08-decode-bulk-isolation.jsonl)
and [150 sweep samples](../../benchmarks/results/2026-09-08-decode-sweep.jsonl).
Each record includes its snapshot NAR hash, compiler, variant, seed, chunk size,
batch width, iterations, and validation. The three snapshots consisted of
`package/` plus `benchmarks/decode.roc` and `benchmarks/stages.roc`.
Historical experiment patches are
[remove span](../../benchmarks/baselines/decode-without_span.patch) and
[move bulk first](../../benchmarks/baselines/decode-bulk_first.patch); they target the
pre-memory-hardening source, recoverable in local JJ snapshot `150d88ca`.
Apply them only to a disposable historical copy, not the current working tree.

### Memory interpretation

`scripts/profile-memory.roc` is the Roc orchestrator; `benchmarks/memory.roc`
is the separately compiled subject. Every child has a deadline and reports a
validated result. The runner normalizes macOS maximum-RSS bytes and Linux GNU
time KiB to bytes. Do not subtract the idle process and label the result heap
usage: runtime startup, fixtures, decoded trees, and allocator high-water all
contribute, and RSS does not count total allocation traffic.

The initial smoke campaign ran twelve cases in fresh processes, three samples
each, independently for dev and speed. Median peak RSS in MiB:

| Case | Dev | Speed |
| --- | ---: | ---: |
| Idle | 2.016 | 1.672 |
| 64 KiB bulk, whole | 2.469 | 1.953 |
| 64 KiB bulk, 31-byte chunks | 2.906 | 2.391 |
| 1,024-element array | 2.641 | 2.078 |
| Flat batch, 256 elements | 2.188 | 1.703 |
| Synthetic deep batch, 256 layers | 3.500 | 2.625 |
| 100 repeated exchanges, 32-byte bulk | 2.313 | 1.703 |

Evidence: [dev, 36 records](../../benchmarks/results/2026-09-08-memory-dev-smoke.jsonl),
[speed, 36 records](../../benchmarks/results/2026-09-08-memory-speed-smoke.jsonl).
These are pre-memory-hardening baselines, not a completed full-size campaign.
The dev records identify the immutable Nix source; the locally built speed
subject records both the package NAR hash and memory-probe SHA-256.

Correction: this original deep probe captured whole intermediate `Batch` values,
including their command lists. Production `Batch.map2` extracts the decoder
functions instead. These original deep-case measurements are **not evidence of
production map2 retention**. The corrected probe below models the extracted
closures; neither synthetic model is an actual dynamic `Batch.map2` chain,
whose heterogeneous error type grows with each composition.


### Larger cases: outstanding release risks

The [11 bounded observations](../../benchmarks/results/2026-09-08-memory-bounded.jsonl)
use the production decoder, the same probe source, macOS maximum RSS, and a
30-second deadline per process. They are single samples, not stable statistical
estimates. No allocation-count or CPU-time claim is derived from them.

| Case | Dev peak MiB | Speed peak MiB |
| --- | ---: | ---: |
| 8 MiB bulk, whole | 26.41 | 25.91 |
| 8 MiB bulk, 16 KiB chunks | 221.64 | 232.16 |
| 100 repeated exchanges, 32-byte payload | — | 1.91 |
| 10,000 repeated exchanges, 32-byte payload | — | 1.70 |
| Sixteen retained 1 MiB unexpected replies | — | 17.95 |
| Same errors compacted immediately | — | 4.94 |
| MGET decoder, 65,536 results | — | 42.83 |
| Flat batch, 4,096 commands | — | 2.08 |
| Synthetic left-deep batch, 4,096 layers | — | 217.44 |

Three conclusions are actionable:

1. **Large fragmented bulks are not production-qualified for memory scaling.**
   Repeated concatenation of the accumulated payload is a candidate source of
   copying, but RSS alone cannot prove list uniqueness, total copied bytes, or
   whether compiler lifetime analysis is responsible. Whole-frame behavior does
   not predict fragmented behavior. The full 42-case campaign was not completed.
2. **Do not capture whole intermediate plans in custom decoder closures.** The
   original deep probe did this; production `Batch.map2` does not. Its 217 MiB
   result is a probe artifact and does not justify changing the production API.
3. **Compact long-lived errors deliberately.** Keeping full unexpected replies
   retains their payloads. Map to a small application-owned summary before
   retaining errors. The two repeat counts did not show growing RSS in these
   samples, but this is not a leak proof or a long-running/concurrent-server test.

Two isolated decoder-state-detachment attempts were rejected. The first passed
929 expectations on all three backends and all four 10,000-case fuzz campaigns,
but neither made the 8 MiB/31-byte case complete within 30 seconds in dev or
speed. Neither ownership-detachment change was promoted. An initially duplicated
binary hash in the investigation notes was a transcription error, subsequently
corrected; these rejected candidates are not used as quantitative evidence for
the later balanced-buffer change.

Next focused experiments are caller-side mutable-state lifetime isolation,
then received-span accumulation with a single final materialization if needed;
retain precise offsets, all limits, and no proportional allocation from a bare
advertised-length header. The independent batch review subsequently invalidated
the original deep-retention inference. These findings are not reasons to
silently relax tests, resource limits, or the existing compiler workaround.

## September 7: original tuning reference

Consolidated September 8, 2026; measurements below were taken September 7.
This is the project's durable performance reference. See
[benchmark workload contracts](../../benchmarks/README.md) for harness details and
[raw dataset index](../../benchmarks/results/README.md) for retained evidence.

## Findings to carry forward

- Sequential loopback round trips hide much of the client cost. Measure pipelines
  and server-free stages as well as live workloads; a large CPU-only gain need
  not produce an equally large end-to-end gain.
- Measure before allocating, reserve known capacity, and write directly into the
  destination buffer. Decimal-to-string-to-bytes temporaries were expensive on
  speed; replacing them helped dev much less. Do not assume backend-independent
  gains from a source-level optimization.
- Consume received byte spans instead of rebuilding parser state for every byte.
  Keep delimiter handling and error offsets on a checked path; preserve arbitrary
  chunk boundaries, binary safety, distinct nulls, limits, and completed replies.
  Never reserve an untrusted advertised payload length before receiving bytes.
- Prefer local mutable loops and indexed traversal where measurements support
  them. Indexing batch responses improved speed semantic decoding, but barely
  changed dev. Keep each element's Try and indexed error reporting intact.
- Inspect adapter calls before changing the transport. This trace showed one
  write and one read per batch, not extra application round trips. It does not
  prove one kernel syscall, nor predict fragmentation on other networks.
- Test all affected workloads. The simple/error fast path improved pipelines but
  coincided with a repeatable 6% bulk-decoding slowdown. Preserve this tradeoff
  in future comparisons instead of optimizing only the best-looking workload.
- Timing does not measure allocations or retained capacity. The September 8
  probes below add process peak RSS, not isolated heap or allocation counts.

## Compiler workaround and support boundary

In `Decoder.step_byte`, save the tagged state, clear the decoder's state to
`AwaitType`, then pass the saved payload to its helper alongside the cleared
record. The helpers already receive their old state explicitly; this avoids
passing it twice without changing protocol semantics or copying payload bytes.
This code shape avoids an observed optimized-backend miscompilation, not a proven
compiler root cause. Keep the [frozen failing decoder repro](../../roc-bugs/interpreter-streaming-decoder/README.md)
independent of the production workaround.

Both September 4 and September 7 nightlies failed the original speed repro
(1/3 expectations passed); refactoring made all three pass. The tuned package
subsequently passed 925 expectations under dev/speed/size on September 7,
plus speed runtime/live/bundle checks. This is bounded evidence, not proof that
optimized compilation is generally safe. Dev remains the default; rerun the
full correctness gates before expanding support or removing the workaround.

Explicit local record annotations also avoid the
[effectful-record JSON inference hang](../../roc-bugs/effectful-record-json-inference/README.md)
found while building the trace. Preserve minimal repros and passing controls
for compiler issues instead of weakening protocol checks to get a benchmark.

## Same-nightly tuning snapshot

All comparisons here use Roc `nightly-2026-09-07-14d9829` on arm64 macOS
26.5.1. Both Roc variants use experimental `--opt=speed` and include the
state-detachment workaround. This isolates the subsequent encoder, simple/error
decoder, and batch traversal changes from the compiler/backend upgrade.
The supported default remains dev.

## What changed

- Bounded encoding writes decimal headers directly into its exactly reserved
  output buffer, retaining the complete pre-allocation request-size check.
- Simple/error decoding consumes received spans; delimiters, errors, and resource
  limits retain scalar semantics. No untrusted advertised-size reservation.
- Batch semantic decoding indexes responses rather than repeatedly taking tails.
  Per-element Try values and indexed errors remain unchanged.
- Added server-free stage diagnostics and an untimed platform-adapter trace.
  No connection pool, transport API change, or protocol-validation shortcut.

The [baseline patch](../../benchmarks/baselines/pre-tuning.patch) retains the
workaround-only comparison; reproduction steps are below. Frozen compiler
repros remain untouched.

## Live Redis: all five clients

Higher operations/second is better. SET+GET counts one operation containing two
Redis commands. Redis 8.10.1, loopback TCP, one persistent connection, RESP2,
32-byte binary values, 5,000 operations/sample, 500 warmup operations, batches
of 100 PINGs. Three samples in each of ten position-balanced client orders
give 30 samples per client/workload and 600 validated records per campaign.

| Tuned campaign | PING/s | SET+GET/s | INCR/s | Pipelined PING/s |
| --- | ---: | ---: | ---: | ---: |
| Roc / roc-redis (speed) | 14,694 | 7,252 | 14,657 | 972,006 |
| Python / redis-py | 12,488 | 5,958 | 12,425 | 357,869 |
| Go / go-redis | 13,619 | 6,765 | 13,680 | 1,010,951 |
| Rust / redis-rs | 14,593 | 7,283 | 14,530 | 1,148,545 |
| C / hiredis | 14,506 | 7,313 | 14,528 | 1,147,183 |

| Roc workload | Baseline ops/s | Tuned ops/s | Throughput change |
| --- | ---: | ---: | ---: |
| ping_sequential | 14,865 | 14,694 | -1.2% |
| set_get_sequential | 7,420 | 7,252 | -2.3% |
| incr_sequential | 14,959 | 14,657 | -2.0% |
| ping_pipeline | 892,697 | 972,006 | 8.9% |

The pipeline gain is 8.9%; tuned Roc is 3.9% below Go and about 15.4% below
Rust/hiredis in this campaign, while delivering 2.72× redis-py's throughput.
Sequential rates fell slightly for every client between campaigns. This is
consistent with host drift; it does not establish either a sequential
improvement or a code-induced regression. We do not normalize the results to
other clients or remove samples.

Raw data: [baseline, 600 records](../../benchmarks/results/2026-09-07-tuning-baseline-speed-quiet.jsonl),
[tuned, 600 records](../../benchmarks/results/2026-09-07-tuning-final-speed-quiet.jsonl).

Other runtimes match the earlier campaign: CPython 3.14.7/redis-py 8.1.0 pure
Python parser; Go 1.26.7/go-redis 9.22.0; Rust 1.97.1/redis-rs 1.6.0 release/LTO;
Clang 21.1.8/hiredis 1.4.1 `-O3`. Roc uses basic-cli 0.22.2.
The shared `build_mode: "speed"` is the Roc mode, not a setting for other clients.

## Server-free stage timings

Median microseconds per 100-command batch; **lower is better**. Five samples of
2,000 batch iterations, with 100 warmup iterations before each sample. Identical
applications and fixtures in both variants; exact result validation is timed.

| Stage | Baseline μs | Tuned μs | Time reduction |
| --- | ---: | ---: | ---: |
| encode_pipeline | 10.883 | 3.552 | 67.4% |
| decode_pipeline | 11.780 | 8.119 | 31.1% |
| decode_fragmented | 14.959 | 10.846 | 27.5% |
| semantic_decode | 2.010 | 1.439 | 28.4% |
| plan_and_decode | 3.374 | 3.193 | 5.3% |
| exchange_mock | 25.107 | 13.338 | 46.9% |

These overlapping stages are not an additive profile. The mocked exchange
includes encoding, RESP decoding, semantic decoding, fake transport callbacks,
and validation, but no sockets/server. Its 46.9% time reduction is not a promise
of that end-to-end gain: real transport/server costs remain.

Raw data: [baseline stages](../../benchmarks/results/2026-09-07-tuning-baseline-stages-speed-quiet.jsonl),
[tuned stages](../../benchmarks/results/2026-09-07-tuning-final-stages-speed-quiet.jsonl).
All 60 records validated; first-sample slowdowns are retained, not discarded.

### Default dev backend: stage cross-check

The same immutable sources and stage application were separately compiled with
`roc build --opt=dev`, using the same nightly. These direct builds override the
snapshots' benchmark-mode setting; records correctly identify `variant: "dev"`.
Both binaries were built before timing, and the final Nix checks had finished.
The iteration/warmup/sample contract is identical to the speed stage run.

| Stage | Baseline dev μs | Tuned dev μs | Time reduction |
| --- | ---: | ---: | ---: |
| encode_pipeline | 45.105 | 43.822 | 2.8% |
| decode_pipeline | 146.486 | 90.421 | 38.3% |
| decode_fragmented | 153.383 | 98.293 | 35.9% |
| semantic_decode | 18.365 | 18.235 | 0.7% |
| plan_and_decode | 23.108 | 23.129 | -0.1% |
| exchange_mock | 207.184 | 148.100 | 28.5% |

Raw data: [baseline dev stages](../../benchmarks/results/2026-09-07-tuning-baseline-stages-dev-quiet.jsonl),
[tuned dev stages](../../benchmarks/results/2026-09-07-tuning-final-stages-dev-quiet.jsonl).
All 60 records validated. These are not new dev live-Redis measurements and
must not be substituted into the optimized five-client matrix.

## Codec gains and tradeoff

The initial 10,000-operation codec samples suggested a bulk-decoding slowdown.
We repeated with 100,000 operations/sample in tuned/baseline/baseline/tuned
invocation order. Each invocation includes ten samples/workload/implementation,
1,000 warmup operations, and alternating Roc/hiredis subject order. The table
pools both invocations per variant (20 samples per cell).

| Public codec | Baseline ops/s | Tuned ops/s | Throughput change |
| --- | ---: | ---: | ---: |
| roc / encode_set | 3,463,923 | 9,036,280 | 160.9% |
| roc / decode_bulk | 5,651,154 | 5,311,097 | -6.0% |
| hiredis / encode_set | 6,585,012 | 6,873,088 | 4.4% |
| hiredis / decode_bulk | 4,942,665 | 4,989,770 | 1.0% |

SET encoding improves about 2.6×, but bulk-only decoding is roughly 6% slower.
That repeatable tradeoff is retained and disclosed: this pass primarily improves
outbound encoding and simple/error-heavy pipelines, not every RESP workload.
Bulk payload copying itself is unchanged; these timings do not identify whether
dispatch, generated code layout, or another compiler effect causes the slowdown.
There is no allocation-count evidence or general language-performance claim.

Raw longer runs: [1 tuned](../../benchmarks/results/2026-09-07-tuning-codec-long-1-final.jsonl),
[2 baseline](../../benchmarks/results/2026-09-07-tuning-codec-long-2-baseline.jsonl),
[3 baseline](../../benchmarks/results/2026-09-07-tuning-codec-long-3-baseline.jsonl),
[4 tuned](../../benchmarks/results/2026-09-07-tuning-codec-long-4-final.jsonl).
All 160 longer-run codec records validated. The 80 validated shorter-run
records were exploratory and have been removed; the retained longer runs are
the evidence for this table.

## Transport trace

The [106-event trace](../../benchmarks/results/2026-09-07-tuning-transport.jsonl) validated all workloads
against an isolated Redis. Every 100-PING batch used one 1,400-byte write and one
700-byte read in this run (ten batches). PING/INCR each used ten writes/reads;
SET+GET used twenty each. Setup/reset/deletion account for six other events.
Read requests allowed up to 16,384 bytes. No extra application round trips were
observed, so this pass does not change the connector.

This is a dev-built, untimed adapter-call trace, not a kernel syscall profile;
logging may alter scheduling and read fragmentation. Different networks can
split replies into multiple reads. It uses an independently owned temporary key
and a shorter diagnostic TTL, not the benchmark key or benchmark timings.

## Provenance, verification, and limits

- Baseline source: `hfhbbhs1yya6dk7dyxjl7nypn18z0l8d-roc-redis-source`.
- Tuned source: `zjcbylkvsqaiqw30ikzy24cz1jw55vaz-roc-redis-source`.
- Sources were captured before this results documentation; subsequent package
  changes only clarify the workaround comment.
- All subjects were prebuilt. No agent-driven builds/tests ran during the live,
  stage, or codec measurements. Live campaigns ran baseline then tuned, not
  interleaved. CPU affinity, host background activity, and power policy were
  uncontrolled; this is one host, not a confidence interval or performance ceiling.
- Roc clocks are UTC wall clocks; other clients use monotonic clocks. No
  independent clock-adjustment monitor was used.
- At the measured revision, 925 package expectations passed under dev, speed,
  and size. Speed passed the
  runtime transport contract, live basic-cli and basic-webserver integrations,
  and 13 bundled-consumer expectations. Full native Nix checks passed; the flake
  evaluated for all four target systems. Other targets were not executed here.
- Binary/malformed line split/limit differential tests and decimal-boundary
  tests guard the new paths. The new effectful-record JSON inference hang has
  a minimal repro plus annotated control under `roc-bugs/`.
- Optimized backends remain experimental. These checks do not prove freedom
  from compiler miscompilations, nor measure peak memory or allocations.

## Earlier backend comparison: keep it separate

The earlier quiet campaigns used **September 4** nightly `c125b82`, despite
September 7 filenames. Their workload, client pins, and host matched the live
contract above, but the dev and speed campaigns were separate runs and changed
both decoder code shape and backend. Do not attribute the entire gain to the
optimizer or relabel those samples as September 7 compiler results.

| Roc measurement | Earlier dev | Earlier speed + workaround |
| --- | ---: | ---: |
| Pipelined PING/s | 356,849 | 842,957 |
| SET encodes/s | 757,776 | 3,260,515 |
| Bulk decodes/s | 552,761 | 4,145,077 |

The pipeline increase was 2.36×; this helped locate client-side overhead but
was not an upper bound. Complete other-client samples remain in the raw data.

- Dev: [600 live samples](../../benchmarks/results/2026-09-07-five-clients-dev-quiet.jsonl)
  and [40 codec samples](../../benchmarks/results/2026-09-07-codec-dev-quiet.jsonl);
  source `qnzqb9gvxgvm3fqhvqqw8s9jlywz1sh9-roc-redis-source`.
- Speed/workaround: [600 live samples](../../benchmarks/results/2026-09-07-five-clients-speed-workaround-quiet.jsonl)
  and [40 codec samples](../../benchmarks/results/2026-09-07-codec-speed-workaround-quiet.jsonl);
  source `ir1nbdvxfg4ixamlc0mf2xgw3xvkz9kh-roc-redis-source`.
- Codec samples used 10,000 operations and 1,000 warmup operations, ten samples
  per implementation/workload with alternating subject order.
- An earlier live run overlapped compilation and is **not valid baseline evidence**.
  Its preliminary output was removed during consolidation; it is not pooled
  into any table here. Obsolete experiment patches were also removed because
  their changes are now incorporated or superseded.

## Repeatable workflow for future tuning

1. Record the exact compiler pin, platform versions, client versions, build mode,
   architecture, workload, and source identity. Never compare two different
   nightlies while claiming to isolate a source change.
2. Establish correctness before timing: package expectations, binary/malformed
   split/limit tests, runtime transport contract, basic-cli and basic-webserver
   live tests, bundle consumer, and compiler-bug controls. For optimizer work,
   repeat package tests under speed/size and build **and execute** the live
   subjects with the selected backend; compiling the controller is not enough.
3. Make baseline and candidate source copies; keep harnesses, fixtures, safety
   checks, and other-language subjects identical. For the recorded September 7
   baseline only, apply [pre-tuning.patch](../../benchmarks/baselines/pre-tuning.patch)
   with `patch -p1` **inside the baseline copy**. It reverses three tuned modules
   and their new tests but preserves state detachment. It is historical, not a
   production patch; after code changes, check that it still applies and means
   what you intend. Use versioned baselines for subsequent tuning.
4. For optimized experiments, set `benchmarkBuildMode = "speed"` in both copied
   flakes. This selects speed for live/codec/stage subjects; controllers remain
   dev. The main flake defaults to dev. Do not weaken checks or alter workloads.
5. Prebuild every subject before measuring. For the current dev defaults:

   ```sh
   nix build path:.#benchmark path:.#benchmark-codec path:.#benchmark-stages --no-link
   nix run path:.#benchmark -- --iterations 5000 --warmup 500 --samples 3 \
     --pipeline-batch 100 --all-order-rotations \
     --jsonl benchmarks/results/NEW-UNIQUE-RUN.jsonl
   nix run path:.#benchmark-stages -- 2000
   nix run path:.#benchmark-codec -- 100000
   nix run path:.#transport-profile
   ```

   Use the matching copied flake for experimental runs. On macOS, absolute
   `path:/private/tmp/...` works where symlinked `path:/tmp/...` does not.
   Do not edit sources between prebuild and timing: that may trigger a rebuild.
   Prefer invoking the already-built wrappers when running a quiet campaign.
6. Run one timed job at a time, without concurrent builds/tests. Retain every
   validated sample and the run order. Balance client positions within live
   campaigns; alternate baseline/candidate invocation order for repeated codec
   runs to reduce drift. Use longer samples to investigate small changes, not
   selective removal of slow samples.
7. Report operations divided by median elapsed time (SET+GET is two commands but
   one operation). Distinguish ops/s from commands/s and μs/batch. Higher rates
   are better; lower times are better. These are descriptive medians, not
   confidence intervals. Inspect variance and shared host drift before ranking
   close results.
8. Keep the validated raw evidence, a versioned baseline, methodology, wins,
   regressions, and compiler repros. Consolidate conclusions here. Remove
   throwaway patches, duplicate reports, and superseded preliminary outputs.

The [benchmark guide](../../benchmarks/README.md) documents all CLI options, fixture
contracts, bounds, and timer caveats. Project orchestration stays Roc/basic-cli;
Python is a comparison subject, not the scripting language for the workflow.

## Next investigations, not established conclusions

- Isolate the bulk-only slowdown with controlled dispatch/code-layout variants;
  repeat both pipeline and bulk workloads before retaining a change.
- Measure allocations and peak/retained memory across large payloads, fragmented
  replies, and deeply composed batches before changing buffer ownership.
- Add workload diversity (mixed replies, larger binary values, error-heavy
  batches, varied batch sizes) before generalizing from PING or 32-byte values.
- Recheck on newer nightlies and other hosts/platforms with the same contracts.
  The existing five-client matrix characterizes these implementations, not an
  intrinsic ranking of languages or a forecast of production network behavior.
