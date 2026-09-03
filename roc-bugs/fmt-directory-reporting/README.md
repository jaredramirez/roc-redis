# `roc fmt --check DIRECTORY` corrupts the failing-file list

Compiler: `nightly-2026-09-04-c125b82`

Run from the repository root:

```console
roc --opt=dev roc-bugs/fmt-directory-reporting/repro.roc
```

The temporary directory contains two valid but unformatted files named
`Alpha.roc` and `Beta.roc`, so the diagnostic should list those two names.
Instead, this nightly reports `Alpha.ro` and `Alpha.roc`; with a larger set of
unformatted files, the repeated names can also contain embedded NUL bytes.

Formatting or checking each file explicitly reports the correct path. This was
found while verifying the generated Redis command modules, so the project uses
an explicit file list for its formatter check as a temporary workaround.

The Roc reproducer uses basic-cli only for temporary-file and child-process
effects. `scripts/check-known-bug.roc` runs it with a hard timeout and asserts
the exact required fragments, including that `Beta.roc` remains absent from the
corrupted diagnostic.
