# Fixed: inferred `List(U8)` helper changed runtime behavior

Originally reproduced with: `nightly-2026-09-03-62fcb65`

Verified fixed with: `nightly-2026-09-04-c125b82`

Run from the repository root:

```console
roc check roc-bugs/inferred-u8-helper/main.roc --no-cache
roc test roc-bugs/inferred-u8-helper/main.roc --no-cache
```

On the original nightly, `roc check` reported no errors but `roc test`
reported one pass and one failure. The unannotated `is_pair(bytes, 0)`
evaluated to `False` for the explicitly typed `List(U8)` value `[13, 10]`.
The otherwise-identical `is_pair_typed`, whose only difference was the
`List(U8), U64 -> Bool` annotation, evaluated to `True`.

Annotating either the caller (`is_pair`) or the helper as
`get_or_zero : List(U8), U64 -> U8` works around the problem. This was reduced
from a RESP CRLF scanner: without one of those annotations it skipped the CR
byte and recursed to end-of-input.

Both expectations pass on the pinned 2026-09-04 nightly. The repro remains in
`roc-bugs/` as a regression test, and `scripts/check-known-bug.roc` requires it
to stay fixed. Production code retains its useful explicit byte annotations.
