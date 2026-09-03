# Performance learnings and measurement guide

## Current result: balanced bulk buffering and corrected batch probe

The September 8 follow-up replaces repeated whole-prefix concatenation for
incomplete bulk payloads. A received prefix up to 4 KiB stays flat; beyond that,
pieces are stored newest-first and merged until each older piece is at least
twice the size of its newer neighbor. The piece list therefore grows
logarithmically, even when in-place list reuse is unavailable. A payload received
in one span still takes a direct path; finalization materializes received pieces
in wire order. No storage is reserved from an advertised length alone.

This bounds the small-prefix copying cost and removes the unbounded quadratic
prefix-copy pattern. It is not a zero-copy or hard-heap guarantee: received
slices, runtime lifetimes, and final materialization still contribute to RSS.
The pure byte-stream API, limits, null distinction, completed-prefix handling,
and error offsets are unchanged.

### Final memory measurements

The full 42-case suite now completes on both dev and speed, including 8 MiB
payloads delivered one byte at a time. These are one fresh-process observation
per case/backend, not medians or allocation counts. Peak process RSS in MiB:

| 8 MiB bulk input | Previous dev | Final dev | Previous speed | Final speed |
| --- | ---: | ---: | ---: | ---: |
| Whole payload | 26.41 | 18.47 | 25.91 | 17.73 |
| 16 KiB chunks | 221.64 | 44.41 | 232.16 | 42.53 |
| 31-byte chunks | Not completed in initial investigation | 60.19 | Not completed in initial investigation | 61.77 |
| Single-byte chunks | Not measured | 51.88 | Not measured | 51.94 |

The rejected state-detachment attempts timed out at 30 seconds for 8 MiB/31-byte
input. The balanced implementation completes that case, and a 30-second native
Nix regression check now protects it. That generous deadline is not a benchmark
or a latency promise. Measurements include fixtures and runtime startup; do not
subtract idle RSS and call the difference heap usage.

Final evidence: [dev, 42 cases](benchmarks/results/2026-09-08-balanced-prefix-memory-dev-full.jsonl)
and [speed, 42 cases](benchmarks/results/2026-09-08-balanced-prefix-memory-speed-full.jsonl).
They identify package NAR hash
`sha256-hjjL4Gl84G3KyYmBLI753RO8OB5jWR2LVwtFbPT38lM=` and probe SHA-256
`aa55b4bd7091a65f8cbaf349dd567624a2128d408c36cf48cc9107ce4945c5b6`.
Compiler remains `nightly-2026-09-07-14d9829`; dev remains the default.

### Performance tradeoff, not a universal speedup

A quiet, speed-built before/new/new/before sequence used ten samples per
invocation. Median time per iteration for each of the two invocations:

| Decode-only workload | Before | Final |
| --- | --- | --- |
| Whole 32-byte bulk | 212.262 / 212.165 ns | 192.847 / 195.549 ns |
| 100 simple 32-byte replies | 9.110 / 8.897 µs | 8.893 / 9.092 µs |
| 4 KiB bulk in 31-byte chunks | 11.243 / 11.224 µs | 12.564 / 12.419 µs |

Small whole bulk improved; simple-reply differences are within the observed
run variation. The deliberately fragmented 4 KiB case remains approximately
11% slower. The initial fully balanced candidate was worse here at roughly
16.3–16.6 µs; the bounded flat prefix reduces that cost without restoring the
large-payload scaling failure. Preserve this remaining tradeoff in future
comparisons.

[Final 120 timing samples](benchmarks/results/2026-09-08-balanced-prefix-decode-abba.jsonl)
and [initial balance, 120 samples](benchmarks/results/2026-09-08-balanced-decode-abba.jsonl)
retain source, seed, chunk size, iteration count, and validation. Initial
unrefined source is recoverable from JJ snapshot `6d165dd0`. These are not new
Python/Go live comparisons; the older cross-language tables remain historical.

### Correction: the original deep-batch finding was a probe artifact

The original model captured entire intermediate Batch values, including command
lists. Production `Batch.map2` extracts child decoder functions first. A matched
speed comparison at 4,096 layers measured 228,294,656 bytes for the incorrect
whole-record-capture model, versus 4,374,528 bytes for the corrected extracted-
decoder model; flat controls were approximately 2.1 MiB.

The corrected probe explicitly reports `batch-deep-extracted-model`, with tests
for success, wrong count, and wrong values. It is still a synthetic model with
a stable error type, not an actual dynamically growing `Batch.map2` chain.
[Four matched observations](benchmarks/results/2026-09-08-batch-capture-correction.jsonl)
preserve provenance. **The earlier 217 MiB result is not evidence of a production
Batch retention defect.** No production Batch representation or API change was
made. Custom closures should likewise avoid retaining whole plans unnecessarily.

### Qualification

The final package passes 933 expectations on dev/speed/size, 142 runtime
transport cases per backend, both live platform adapters and bundled downstream
consumption on all three backends, and complete native Nix checks. Four
[recorded fuzz campaigns](integration/fuzz/qualification/2026-09-08.jsonl) passed
100,000 cases each. Buffer-invariant expectations and the runtime large-payload
matrix supplement the fuzz targets' bounded small payloads.

## Reading and reproducing the evidence

The measurements above predate the behavior-preserving readability pass. They
are not fresh results for the reformatted/generated source. No new speed claim
is made by that pass.

- [Historical investigations and five-language comparison](docs/history/performance.md)
- [Benchmark workload contracts](benchmarks/README.md)
- [Raw evidence index](benchmarks/results/README.md)

Historical sections retain their original conclusions and corrections. In
particular, an old section titled “outstanding release risks” does not describe
the current balanced bulk buffer. Exact reproduction commands and baseline
patch instructions remain with the historical measurements.
