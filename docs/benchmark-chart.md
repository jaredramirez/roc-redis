# Benchmark chart provenance

The README table is printed directly by the benchmark controller
(`just benchmark-all`; rows are experiments, columns are clients). The current
figures come from a position-balanced campaign taken on this checkout on
2026-09-10 (`../benchmarks/results/2026-09-10-seven-workload-speed-quiet.jsonl`),
covering all seven workloads.

Throughput is 10,000 operations divided by median elapsed time across 50
validated samples per client/workload (five samples in each of ten
position-balanced subject orders). Labels truncate to whole operations/second.
Each `SET+GET`, `MSET/MGET`, hash roundtrip, and pipelined pair counts as one
operation.

| Experiment | roc-redis | redis-py | go-redis | redis-rs | hiredis |
| --- | ---: | ---: | ---: | ---: | ---: |
| `ping_sequential` | 15,024 | 12,537 | 13,896 | 14,981 | 14,960 |
| `set_get_sequential` | 7,458 | 6,091 | 6,950 | 7,400 | 7,392 |
| `incr_sequential` | 14,874 | 12,548 | 13,892 | 14,814 | 14,787 |
| `ping_pipeline` | 957,579 | 352,223 | 1,075,811 | 1,225,787 | 1,218,100 |
| `mset_mget_sequential` | 7,242 | 5,751 | 6,910 | 7,406 | 7,462 |
| `hash_roundtrip_sequential` | 7,291 | 5,987 | 6,937 | 7,385 | 7,375 |
| `set_get_pipeline` | 459,252 | 117,322 | 456,467 | 468,426 | 577,383 |

Redis 8.10.1; aarch64-darwin; persistent loopback TCP; RESP2; 32-byte binary
values; 1,000 warmup operations; 10,000 measured operations/sample. Five samples
in each of ten position-balanced orders give 1,750 records per campaign. SET+GET
is two commands but one operation; pipelines hold up to 100 operations.
Compilation, setup, warmup, and cleanup are outside the timed regions.

Roc uses the pinned `nightly-2026-09-07-14d9829`, the experimental speed backend,
and basic-cli 0.23.0-rc1. Comparators are redis-py 8.1.0 (pure Python parser),
go-redis 9.22.0, redis-rs 1.6.0, and hiredis 1.4.1. Roc uses a UTC wall-clock
timer; others use monotonic timers. These are descriptive medians, not
confidence intervals.

The community-preview default is the dev backend, not speed. A dev-backend
cross-check with identical parameters
(`../benchmarks/results/2026-09-10-seven-workload-quiet.jsonl`) stays within a
few percent on the sequential rows (`ping_sequential` 14,651 vs 15,024) and runs
about 2.5–3× lower on the pipelined rows (`ping_pipeline` 395,890 vs 957,579;
`set_get_pipeline` 152,413 vs 459,252). Sequential workloads are network
round-trip bound, so the backend barely moves them; pipelines expose client-side
CPU.

Do not interpret close results as significant differences, this campaign as a
general language ranking, or these medians as confidence intervals. Numbers were
taken on one quiet host.

[Historical September 7 report](history/performance.md#live-redis-all-five-clients) ·
[Workloads and reproduction](../benchmarks/README.md) ·
[Memory/decoder measurements](../perf.md)

To refresh the README, run `just benchmark-all` on an isolated host and paste the
controller's printed table; it computes throughput with the same
median-of-samples policy. The live subjects build Roc on dev by default; select
the experimental speed backend with an isolated flake copy setting
`benchmarkBuildMode = "speed"` (see [benchmarks/README.md](../benchmarks/README.md)).
Retain the raw JSONL (`--jsonl`) and source provenance; never pool different
campaigns or relabel historical results as current.
