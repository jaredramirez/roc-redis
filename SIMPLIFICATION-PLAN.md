# Behavior-preserving simplification

Public APIs, wire semantics, cleanup ownership safeguards, compiler workarounds,
and historical benchmark evidence are retained throughout this pass.

- [x] One Roc check/expect/runtime inventory used by Just, Nix, and CI.
- [x] Explicit subject build modes; small purpose-specific Nix files.
- [x] Named harness contexts, shared pure helpers, readable watchdog bridges.
- [x] Minimal runnable CLI and webserver examples, checked and built with the suite.
- [x] Clear raw/typed module map and consistent raw aliases.
- [x] Simplify fixed argument segments in the generator; verify wire output.
- [x] Current documentation separated from historical reports; explain buffer order.
- [x] Formatting, catalog, runtime/integration, backend, and native Nix verification.

Baseline working-copy snapshot: `1377b6ea`. No public module moves or new
runtime abstractions are planned. Performance-sensitive parser code is unchanged.

## Implementation notes

The root flake is now 215 lines (previously 1,112). The public outputs and pins
are preserved. Scripts use HarnessText only for pure helpers; it does not grant
process ownership. Watchdog source fragments were split without changing their
joined bytes. Named settings replace the bundle launch argument list and the
webserver cleanup context; service-specific safety decisions remain local.

The conservative generator rewrite merges only adjacent bare-name list
expressions. An initial last()/drop_last() implementation exposed compiler heap
corruption on both dev and speed. The independent repro and passing control are
in `roc-bugs/generator-list-coalescing/`; production keeps the pending segment
separate. No Redis validation was removed to work around it.

All historical measurements and accepted API decisions remain linked from the
current documents. No new cross-language performance claim is made in this pass.

## Verification (September 8)

- `nix flake check path:. --all-systems --no-build`: all configured systems evaluate.
- `nix flake check path:. --print-build-logs`: native arm64 macOS checks pass,
  including the shared suite, compiled examples, catalog/live checks, bundle
  consumer, both platform proofs, 40,000 fuzz-smoke cases, and the fragmented
  memory regression check.
- `nix run path:.#backend-check -- dev speed size`: all three pass 933 package
  expectations, compiled client/142-case transport contracts, both live platform
  proofs, and downstream bundle consumption.
- Frozen new compiler repro aborts on dev and speed; its control passes both.
- Current/archive Markdown file links resolve; source whitespace checks pass
  (historical unified-diff patch fixtures excluded from whitespace lint).

No remote CI execution or fresh comparative performance campaign is claimed.
Final follow-up edits after these checks only record results and clarify the
buffer's worked example; parser implementation and public API signatures remain
unchanged from the baseline.
