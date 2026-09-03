# `append_sublist` allocation failure in a streaming decoder

Compiler: `nightly-2026-09-04-c125b82`, native arm64 macOS, dev backend.

The frozen `Decoder.roc` appends bulk payload spans using
`bulk.content.append_sublist(chunk, { start: index, len: count })`. Feeding a
256-byte payload one byte at a time aborts with an allocation failure. The same
decoder using `bulk.content.concat(chunk.sublist(...))` passes. Both operations
should append the same bounded span.

```console
roc test --opt=dev --no-cache roc-bugs/decoder-expect-allocation/repro.roc
roc test --opt=dev --no-cache roc-bugs/decoder-expect-allocation/control.roc
```

Verified: the repro exits 134 with:

```text
panic: RuntimeHostEnv: out of memory during roc_alloc
```

The control imports the working package decoder and checks the same payload and
fragmentation cases. The bug also reproduced in the compiled dev-backend
`integration/client_contract.roc` runtime matrix before the package switched to
`concat(sublist(...))`; that executable exited 1 with `roc_alloc: out of memory`.
The corrected executable passes both every two-part split and single-byte reads.

This is not yet a minimal compiler repro: simple list loops, sliced source lists,
and smaller nominal/tagged accumulator reductions did not fail. A snapshot of
the parser without its tests is retained here so the failing case is independent
of future package decoder edits. Further reduction is needed to identify the
precise ownership/lowering cause. Do not infer that all uses of `append_sublist`
are affected.
