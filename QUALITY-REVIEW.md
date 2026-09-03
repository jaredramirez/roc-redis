# Current quality and safety notes

The package remains platform-independent RESP2 code. The supported default is
dev; speed and size have bounded qualification with retained compiler
workarounds, not a general guarantee of compiler correctness.

## Invariants to preserve

- Validate complete outbound size before writing. No implicit retries.
- Discard the stream after an exchange failure; server/semantic failures after
  a fully drained exchange preserve framing but do not undo command effects.
- Keep null bulk strings and null arrays distinct.
- Batch.each preserves each element's Try; batch composition is not atomic.
- Resource limits are per reply or exchange, not a hard process heap limit.
- Do not reserve storage from an untrusted advertised payload length alone.
- Compact retained diagnostic errors deliberately; replies may contain large
  payloads. Custom closures should capture needed decoder functions, not plans.
- Keep process-identity, parent-death, timeout, and cleanup checks in harnesses.

## Verification entry points

The portable inventory lives in [TestSuite.roc](scripts/TestSuite.roc), used by
Just, Nix, and CI. It distinguishes formatting/type checks, expectations, and
compiled runtime subjects. Live platform proofs, bundle consumption, fuzzing,
and backend qualification remain separate explicit checks.

See [development commands](docs/development.md), [current performance evidence](perf.md),
and [compiler repros](roc-bugs/). The last pre-simplification qualification was
933 package expectations on dev/speed/size, 142 runtime transport cases per
backend, and four 100,000-case fuzz campaigns. These are bounded observations,
not proof of exhaustive correctness.

The [simplification pass](SIMPLIFICATION-PLAN.md) subsequently passed native Nix
checks and all three backend qualifications with those package/transport counts
unchanged. It also records the generator compiler repro and verified workaround.

## Historical review

The [dated review archive](docs/history/quality-review.md) retains the original
API review, research sources, compiler upgrades, and the correction to the
synthetic deep-batch probe. Its earlier unsupported-backend and memory-risk
statements apply to those snapshots, not later qualified work.
