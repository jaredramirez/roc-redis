# `roc test` evaluates an `expect` after its dependency has a type error

## September 8 observation on nightly-2026-09-07-14d9829

While adding the conservative-decoder regression test, an invalid nested record
pattern in `package/Decoder.roc` caused `roc test --opt=dev --no-cache
package/main.roc` to exit 139 (SIGSEGV); `roc check package/main.roc` correctly
reported a type mismatch. The same test through `package/Config.roc` also exited
139. To recreate the invalid program, in the new `$8388609` header expectation
remove `actual: 8_388_609` from the `BulkLengthLimitExceeded` record pattern
(do this only in a disposable source copy). The union payload requires `actual`,
`at`, and `limit`; restoring the field makes all 929 package tests pass.

A standalone equivalent record-pattern reduction reports the type error without
SIGSEGV, so the package-sized crash is not yet minimized. This is an invalid-input
diagnostic failure, not evidence that the valid decoder fails at runtime. The
frozen small repro below remains useful for the related diagnostic-recovery bug.

Compiler: `nightly-2026-09-04-c125b82`

Run from the repository root:

```console
roc test --no-cache roc-bugs/type-error-expect-diagnostic-recovery/repro.roc
roc test --no-cache roc-bugs/type-error-expect-diagnostic-recovery/control.roc
```

The repro deliberately gives `bad` a `U64` annotation and an empty-record
value, then references `bad` from an `expect`.

Expected: `roc test` exits nonzero after reporting the type mismatch. It should
not evaluate an expectation whose dependency failed to type-check, and any
summary should count the compiler error accurately.

Actual: the compiler first reports the useful type mismatch, but then continues
into compile-time expectation evaluation and emits:

```text
Roc application crashed with this message:

    runtime error

── ✗ fail

expect bad == 1

Ran 1 tests ...:
    0 passed
    1 failed
    0 compiler errors
```

The command exits with status 1, but `0 compiler errors` contradicts the type
error immediately above it, and the generic runtime crash is a secondary
failure caused by continuing after that error. The control exits successfully
with one passing test.

This is a diagnostic-recovery problem limited to invalid programs; the reduced
case does not depend on opaque types, defaulted record fields, packages, or a
platform. It was reduced from an invalid opaque-config constructor while
checking the package API.
