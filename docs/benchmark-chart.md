# Benchmark chart provenance

The README table is printed directly by the benchmark controller
(`just benchmark-all`; rows are experiments, columns are clients). The current
figures come from a position-balanced campaign taken on this checkout on
2026-09-11 (`../benchmarks/results/2026-09-11-seven-workload-speed-quiet.jsonl`),
covering all seven workloads.

Throughput is 10,000 operations divided by median elapsed time across 50
validated samples per client/workload (five samples in each of ten
position-balanced subject orders). Labels truncate to whole operations/second.
Each `SET+GET`, `MSET/MGET`, hash roundtrip, and pipelined pair counts as one
operation.

| Experiment | roc-redis | redis-py | go-redis | redis-rs | hiredis |
| --- | ---: | ---: | ---: | ---: | ---: |
| `ping_sequential` | 14,836 | 12,475 | 13,839 | 14,766 | 14,728 |
| `set_get_sequential` | 7,362 | 6,079 | 6,909 | 7,293 | 7,309 |
| `incr_sequential` | 14,683 | 12,578 | 13,831 | 14,568 | 14,598 |
| `ping_pipeline` | 982,800 | 358,179 | 1,050,813 | 1,207,349 | 1,226,768 |
| `mset_mget_sequential` | 7,097 | 5,758 | 6,817 | 7,303 | 7,374 |
| `hash_roundtrip_sequential` | 7,180 | 5,963 | 6,887 | 7,283 | 7,296 |
| `set_get_pipeline` | 447,828 | 119,411 | 439,952 | 467,049 | 475,692 |

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
(`../benchmarks/results/2026-09-11-seven-workload-quiet.jsonl`) stays within
about 4% on the single-command sequential rows (`ping_sequential` 14,260 vs
14,836), widens to roughly 10% on the two-command sequential rows
(`mset_mget_sequential` 6,356 vs 7,097), and falls far behind on the pipelined
rows (`ping_pipeline` 460,394 vs 982,800, 2.1×; `set_get_pipeline` 174,442 vs
447,828, 2.6×). Sequential workloads are network round-trip bound, so the
backend barely moves them; pipelines amortize the network away and expose
client-side CPU.

The decoder work on 2026-09-11 (folding numeric headers in one pass, and
extending the line fast path to every line kind with a single-step CRLF finish)
raised dev pipelined throughput by about 15% — `ping_pipeline` 395,890 ->
460,394 and `set_get_pipeline` 152,413 -> 174,442 against the 2026-09-10
campaign — while leaving the speed figures unchanged within noise. That is the
expected shape: those changes remove per-byte record rebuilds that the
optimizing backend already eliminated, so they close part of the dev gap and add
nothing on speed.

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
