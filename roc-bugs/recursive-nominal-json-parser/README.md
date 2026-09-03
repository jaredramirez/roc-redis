# Recursive nominal JSON parser derivation hangs

Roc compiler: `nightly-2026-09-04-c125b82`

`repro/main.roc` exports a fixture that asks the compiler to derive
`parser_for` for a one-field recursive nominal record and then uses that method
through `Json.parse`. The recursion is behind `List`, so every concrete runtime
value is finite.

Run both checks with hard bounds from the repository root:

```sh
timeout --signal=TERM --kill-after=5s 10s \
  roc check roc-bugs/recursive-nominal-json-parser/control/main.roc --no-cache

timeout --signal=TERM --kill-after=5s 10s \
  roc check roc-bugs/recursive-nominal-json-parser/repro/main.roc --no-cache
```

Expected: both checks terminate successfully. Recursive nominal types are
supported, and derived codecs must terminate on recursive types.

Actual: the compiler checks the non-recursive control in milliseconds, but
does not finish the recursive repro within 10 seconds; GNU `timeout` exits with
status 124. The control has the same nominal record and `List` field shape,
replacing only `List(Node)` with `List(Str)`. This isolates recursion as the
trigger.

The fixtures intentionally live in separate module directories. Roc loads a
sibling `main.roc` when checking another file in its directory, which would
cause the hanging repro to contaminate the control invocation.

This was found while implementing the Redis command-catalog tool. Redis
`COMMAND DOCS` describes command arguments recursively through nested
`arguments` arrays. The production tool currently parses a deliberately
bounded set of structural JSON shapes and converts them to its recursive
domain type after parsing, avoiding recursive parser derivation while keeping
the rest of the catalog logic strongly typed.
