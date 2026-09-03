# roc-fuzz compatibility and targets

These targets use the published `roc-fuzz` runner rather than a project-local
random-number generator or property-test driver.

- Release: `0.4.0-rc1`
- Source commit: `1fa2b5f09d77f1e91a2df3b0a11adf8454dd2831`
- Package URL: `https://github.com/lukewilliamboswell/roc-fuzz/releases/download/0.4.0-rc1/9k2cfuAWoBfcRBRiVbriXFf1dHktoRBbieifYN7NmTHc.tar.zst`
- Package SHA-256: `e045382e6dcb9e04c29b14c6e63949fcb879917f328ab5c7120c5351653ba9b0`
- License: MIT (`roc-fuzz` also bundles separately documented third-party code)

The release platform declares Roc `nightly-2026-09-05-b195f5b`. It builds and
runs with this project's `nightly-2026-09-07-14d9829`, with the compiler's
expected version-mismatch warning. Compatibility was checked with `roc build
--fuzz` and a bounded runner smoke test on Apple Silicon macOS. This is not
evidence for either published Linux target or another Roc nightly.

The targets deliberately separate four properties:

- `resp_round_trip.roc` generates bounded semantic RESP2 trees, serializes them
  with the test-only serializer, and checks one-shot, arbitrary, and single-byte
  decoder fragmentation.
- `resp_differential.roc` compares arbitrary bytes with the independent one-shot
  grammar in `RespOracle.roc`, and requires exact production results to remain
  invariant under arbitrary fragmentation. An incomplete reference frame may
  also hit a configured decoder limit, while reference-invalid input must fail.
- `command_encoding.roc` compares raw commands, pipelines, measured lengths, and
  exact/short budgets with an independent command serializer.
- `resp_mutations.roc` mutates structured frames and exercises truncated frames,
  integer/length overflow, malformed delimiters, null spelling, and completed
  reply prefixes before malformed or incomplete input.

The flake pins and caches the upstream platform. On Apple Silicon macOS or
x86-64 Linux, run a bounded campaign with a separate working directory per
target (the runner defaults to `.roc-fuzz/corpus` in its working directory):

```sh
nix run .#fuzz-resp_round_trip -- run --runs=100000 --seed=20260907 --max-input-size=512
```

`nix flake check` runs 10,000 cases per target with isolated fresh corpora on
those two systems. Other architectures still run the deterministic expectations
and transport matrix, but have no published roc-fuzz platform in this pin.
The separate CI matrix schedules 100,000 cases per target on native Linux and
macOS runners; configuring it is not evidence that remote jobs have passed.
It uses the upstream runner's `ci` mode and preserves reports/corpora/replay
artifacts for 14 days, with a 256 MiB process limit and five-second input timeout.
The upstream platform's two-day compiler-pin mismatch is an explicitly accepted
build warning; successful executable creation and runtime checks are required.

Equivalent direct build with the project compiler cache initialized:

```sh
roc build --fuzz integration/fuzz/resp_round_trip.roc
./integration/fuzz/resp_round_trip run --runs=10000 --seed=20260907 --max-input-size=512
```

`roc-fuzz` provides persistent corpora plus `show`, `replay`, and `minimize` for
saved failures. Keep generated corpora and artifacts outside the source tree in
CI unless a minimized input is intentionally reviewed and committed as a
regression fixture.

The reference parser shares RESP value types and configured limits, but not
production parsing, framing, or encoding routines. This is an independent
bounded oracle, not a complete Redis server implementation. Incomplete input
may be rejected early by a production resource limit. Generated trees have
bounded depth, widths, and payload sizes; bounded campaigns cannot prove the
absence of parser or compiler defects.

Other existing projects considered were
[roc-spec](https://github.com/niclas-ahden/roc-spec) (test organization and
assertions) and [RocPBT](https://github.com/JRI98/RocPBT) (property-testing
experiments). [roc-fuzz](https://github.com/lukewilliamboswell/roc-fuzz) supplies
the typed generators, coverage-guided engine, corpus management, replay, and
minimization needed here; the Redis-specific properties remain project code.

The final September 8 balanced-buffer package passed four 100,000-case campaigns
with seed 20260908 and a 1,024-byte generator-input cap. The compact
[qualification record](qualification/2026-09-08.jsonl) retains upstream runner
outcomes, compiler/package provenance, executable hashes, and counters. Large
payload buffering is additionally covered by threshold/order expectations and
the separately executed memory matrix; these fuzz generators intentionally use
small bounded payloads.
