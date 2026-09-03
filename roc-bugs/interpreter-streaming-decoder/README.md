# Backend corruption in streaming decoder state

Compiler: `nightly-2026-09-04-c125b82`

Nightly-upgrade verification on `nightly-2026-09-07-14d9829`: the frozen dev
control still passes 3/3, but the interpreter now fails **all three** expectations
(0 passed, 3 failed, 0 compiler errors), including the record-shaped cases.
The checker tracks that new failure shape. The commands/results below describe
the original September 4 findings; the fixture's package-header pin follows the
current compiler so version warnings do not contaminate regression checks.

September 7 follow-up: `nightly-2026-09-07-14d9829` still fails the original
speed repro (1/3 pass). An isolated state-detachment refactor makes all three
expectations pass and also passes the package's 919 expectations under speed
and size on both nightlies. The workaround was subsequently promoted into the
production decoder, whose tuned package passed 925 expectations on dev/speed/size.
See [perf.md](../../perf.md#compiler-workaround-and-support-boundary) for the
workaround and verification scope. The frozen failing source remains unchanged;
dev remains the default and optimized execution remains experimental.

This standalone pure package does not import the production package or a
platform. It preserves the smallest decoder state shape found to trigger two
related backend failures; further reductions stopped reproducing them.

Run from the repository root:

```console
roc test --opt=dev roc-bugs/interpreter-streaming-decoder/main.roc --no-cache
# All (3) tests passed

roc test --opt=interpreter roc-bugs/interpreter-streaming-decoder/main.roc --no-cache
# 2 passed, 1 failed, 0 compiler errors

roc test --opt=speed roc-bugs/interpreter-streaming-decoder/main.roc --no-cache
# fails with corrupted values, or aborts with an allocator panic

roc test --opt=size roc-bugs/interpreter-streaming-decoder/main.roc --no-cache
# fails with corrupted values, or aborts with an allocator panic
```

The first two expectations differ only in the recursive byte loop's argument
shape:

- `consume_positional` carries decoder, chunk, index, and completed values as
  four arguments. Non-dev backends retain `BulkString([1])` after reading the
  byte `120` (`x`).
- `consume_chunk` carries those fields in one explicitly annotated
  `ChunkState` record and returns the correct `BulkString([120])` in this case.

The third expectation exercises only the record-shaped loop. It decodes a
nested value at every possible two-chunk boundary. It passes with `dev` and
`interpreter`, but fails with `speed` and `size`. Optimized runs are themselves
nondeterministic: they may report corrupted expectation values or abort with a
runtime allocator double-free/untracked-free panic. Successful reductions show
the optimized code overwriting an earlier `PONG` bulk payload with bytes from a
later value. This is distinct from the positional-recursion failure because it
remains after applying that workaround. The required known-bug verifier does
not execute these unstable optimized backends; the commands above are manual
diagnostics.

`package/Decoder.roc` uses the record-shaped loop and now also detaches the old
tagged state before helper dispatch. The latter avoids the observed optimized
failure in the tested production paths. It does not fix this frozen repro or
establish general optimizer correctness; `speed` and `size` remain experimental.

Remove the production workaround only after the positional test passes on all
backends. Expand backend support only after this repro and the full package and
integration suites pass under that backend.
