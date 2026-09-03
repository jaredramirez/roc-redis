# Constant-result destructuring differs inside `expect`

Compiler: `nightly-2026-09-04-c125b82`.

Discovered while implementing the single-build configuration API. A constant
call returning `Try` allows an `Ok`-only destructure in a top-level definition,
but the same expression inside `expect` reports a non-exhaustive destructure.
This is a compiler limitation/inconsistency to investigate; it is not established
whether compile-time branch narrowing inside expectations is intended to be
supported. The library uses the supported top-level form.

Run from the repository root:

```console
roc test --opt=dev --no-cache roc-bugs/constant-destructure-in-expect/repro.roc
roc test --opt=dev --no-cache roc-bugs/constant-destructure-in-expect/control.roc
```

Expected for consistent constant narrowing: both forms establish that `positive(1)`
cannot return `Err` and pass. Verified actual: the repro reports a non-exhaustive
destructure, also reports `All (1) tests passed`, and exits 1. The control reports
one passing test and exits 0.
