# Rejected string literal also reports “invalid numeric literal”

Compiler: nightly-2026-09-04-c125b82, arm64 macOS.

```console
roc check roc-bugs/invalid-string-literal-diagnostic/Literal.roc
roc test --opt=dev roc-bugs/invalid-string-literal-diagnostic/Accepted.roc
```

The repro's `from_quote` deliberately returns `BadQuotedBytes`. Compilation
correctly fails and includes the supplied string-specific error, but also emits
a “compile time crash” claiming “invalid numeric literal”. There is no numeric
literal in the failing definition. Expected: a string-literal rejection without
the unrelated numeric-literal crash message. The accepting control passes.

Found while adding compile-rejection tests for empty Redis command names. This
is a diagnostic issue, not an acceptance of an invalid command or a runtime bug.
