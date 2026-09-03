# Qualified tag patterns fail with an absolute module import

Compiler: `nightly-2026-09-04-c125b82`.

```console
roc check roc-bugs/absolute-import-pattern/main.roc
roc test --opt=dev roc-bugs/absolute-import-pattern/control.roc
```

`Nested/Case.roc` imports `/Types`. Its `Types.Types` annotation and the
`Types.Okay` constructor expression resolve, but the qualified match patterns
`Types.Okay` and `Types.Missing` each report that `Types` is undeclared.
Expected: the qualified patterns resolve to the same imported nominal type.
The failing check exits 1 with two errors.

The control retains the absolute import and annotation but uses type-inferred
`Okay`/`Missing` patterns. This is the form used in the typed command modules.
The issue was found while introducing `Commands.Strings` with root-relative
imports of the pure protocol modules.
