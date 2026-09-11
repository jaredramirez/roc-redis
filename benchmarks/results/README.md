# Retained performance evidence

See [perf.md](../../perf.md) for the consolidated findings, tables, provenance,
tradeoffs, and reproduction workflow. These files are raw evidence, not separate
performance reports. Do not pool campaigns across compilers, variants, or workloads.

| Campaign | Compiler / variant | Retained data |
| --- | --- | --- |
| Earlier quiet dev | September 4 / dev | [Live, 600](2026-09-07-five-clients-dev-quiet.jsonl), [codec, 40](2026-09-07-codec-dev-quiet.jsonl) |
| Earlier workaround | September 4 / speed | [Live, 600](2026-09-07-five-clients-speed-workaround-quiet.jsonl), [codec, 40](2026-09-07-codec-speed-workaround-quiet.jsonl) |
| Same-nightly baseline | September 7 / speed | [Live, 600](2026-09-07-tuning-baseline-speed-quiet.jsonl), [stages, 30](2026-09-07-tuning-baseline-stages-speed-quiet.jsonl) |
| Same-nightly tuned | September 7 / speed | [Live, 600](2026-09-07-tuning-final-speed-quiet.jsonl), [stages, 30](2026-09-07-tuning-final-stages-speed-quiet.jsonl) |
| Longer codec repeat | September 7 / speed; invocation order below | [1 tuned, 40](2026-09-07-tuning-codec-long-1-final.jsonl), [2 baseline, 40](2026-09-07-tuning-codec-long-2-baseline.jsonl), [3 baseline, 40](2026-09-07-tuning-codec-long-3-baseline.jsonl), [4 tuned, 40](2026-09-07-tuning-codec-long-4-final.jsonl) |
| Dev stage cross-check | September 7 / dev | [Baseline, 30](2026-09-07-tuning-baseline-stages-dev-quiet.jsonl), [tuned, 30](2026-09-07-tuning-final-stages-dev-quiet.jsonl) |
| Untimed adapter trace | September 7 / dev | [106 events](2026-09-07-tuning-transport.jsonl) |
| Decode isolation | September 7 / three speed variants, measured September 8 | [Bulk, 60](2026-09-08-decode-bulk-isolation.jsonl), [broader sweep, 150](2026-09-08-decode-sweep.jsonl) |
| Initial memory smoke | September 7 / pre-memory-hardening, measured September 8 | [Dev, 36](2026-09-08-memory-dev-smoke.jsonl), [speed, 36](2026-09-08-memory-speed-smoke.jsonl) |
| Larger bounded memory probes | September 7 / production decoder, measured September 8 | [11 single-case RSS observations](2026-09-08-memory-bounded.jsonl) |
| Balanced-buffer refinement | September 7 / speed, before/new/new/before per case | [Initial balance, 120](2026-09-08-balanced-decode-abba.jsonl), [final bounded-prefix balance, 120](2026-09-08-balanced-prefix-decode-abba.jsonl) |
| Final full memory suite | September 7 / bounded-prefix balance and corrected batch model | [Dev, 42](2026-09-08-balanced-prefix-memory-dev-full.jsonl), [speed, 42](2026-09-08-balanced-prefix-memory-speed-full.jsonl) |
| Batch capture correction | September 7 / matched speed probe comparison | [4 single-case RSS observations](2026-09-08-batch-capture-correction.jsonl) |
| Seven-workload, before decoder work | September 10 / speed | [Live, 1750](2026-09-10-seven-workload-speed-quiet.jsonl) |
| Seven-workload, before decoder work | September 10 / dev | [Live, 1750](2026-09-10-seven-workload-quiet.jsonl) |
| Seven-workload README source | September 11 / speed | [Live, 1750](2026-09-11-seven-workload-speed-quiet.jsonl) |
| Seven-workload dev cross-check | September 11 / dev | [Live, 1750](2026-09-11-seven-workload-quiet.jsonl) |

Counts are JSONL records/events. The September 7 filenames identify measurement
dates, not necessarily compiler dates. Every timed record includes variant and
source provenance. The transport trace is untimed and is not a syscall count.

The original September 8 `batch-deep` smoke/bounded rows captured entire
intermediate batches, unlike production `Batch.map2`. They are retained as
historical probe observations, not evidence of production batch retention.
See the correction in `perf.md` before using any deep-batch numbers.

Full-memory files for the initial unrefined buffer were superseded by final
source runs; the earlier working-copy snapshot `6d165dd0` preserves them.
The historical smoke files also restore the exact `U64.highest` advertised-size
metadata from the original Roc output: an intermediate analysis serialization
had rounded that integer. RSS measurements were unaffected. JSONL is retained
as emitted; do not round-trip U64 fields through a floating-point JSON parser.

## Cleanup and recovery

The consolidation removed the compilation-confounded preliminary live run,
two superseded short codec runs, duplicate narrative reports, and obsolete
optimized-backend patches. No retained table depends on those removed raw runs.
The useful historical comparison patch moved to
[benchmarks/baselines/pre-tuning.patch](../baselines/pre-tuning.patch).

Pre-cleanup tracked files are recoverable from Jujutsu commit
`4d8d8eaa0953acb4fb2a992581f49589f591e0a8` (subject to normal repository retention),
for example with `jj file show -r <commit> <old-path>`.
Compiler repros and executable benchmark/diagnostic sources were preserved.
