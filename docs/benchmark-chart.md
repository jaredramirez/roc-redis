# Benchmark chart provenance

The README now shows a markdown table that the benchmark controller prints
directly (`just benchmark` / `just benchmark-all`; rows are experiments, columns
are clients). The archived figures below come from the
[September 7 tuned campaign](../benchmarks/results/2026-09-07-tuning-final-speed-quiet.jsonl)
and cover only the original four workloads; the three realistic workloads
(`mset_mget`, `hash_roundtrip`, `set_get_pipeline`) need a fresh campaign.

Throughput is 5,000 operations divided by median elapsed time across 30 validated
samples per client/workload. Labels truncate to whole operations/second, matching
the historical report; bars use unrounded values. Each panel has its own
zero-based scale.

| Client | PING/s | SET+GET/s | INCR/s | Pipelined PING/s |
| --- | ---: | ---: | ---: | ---: |
| Roc · speed | 14,694 | 7,252 | 14,657 | 972,006 |
| Python | 12,488 | 5,958 | 12,425 | 357,869 |
| Go | 13,619 | 6,765 | 13,680 | 1,010,951 |
| Rust | 14,593 | 7,283 | 14,530 | 1,148,545 |
| C | 14,506 | 7,313 | 14,528 | 1,147,183 |

Redis 8.10.1; aarch64-darwin; persistent loopback TCP; RESP2; 32-byte binary
values; 500 warmup operations; 5,000 measured operations/sample. Three samples
in each of ten position-balanced orders give 600 records. SET+GET is two
commands but one operation; pipelines hold 100 PINGs. Compilation, setup,
warmup, and cleanup are outside the timed regions.

Roc uses the September 7 nightly, experimental speed backend, and basic-cli
0.22.2. Comparators are redis-py 8.1.0 (pure Python parser), go-redis 9.22.0,
redis-rs 1.6.0, and hiredis 1.4.1. Roc uses a UTC wall-clock timer; others use
monotonic timers. These are descriptive medians, not confidence intervals.

This source predates subsequent decoder changes, readability edits, and the CLI
upgrade. Do not interpret close results as significant differences or this
campaign as a current-checkout measurement or general language ranking.

[Full historical report](history/performance.md#live-redis-all-five-clients) ·
[Workloads and reproduction](../benchmarks/README.md) ·
[Newer memory/decoder measurements](../perf.md)

To refresh the README, run `just benchmark` (or `just benchmark-all`) on an
isolated host and paste the controller's printed table; it computes throughput
with the same median-of-samples policy. Retain the raw JSONL (`--jsonl`) and
source provenance; never pool different campaigns or relabel historical results
as current.
