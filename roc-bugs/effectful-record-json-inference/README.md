# JSON derivation stalls inside a returned effectful record

Compiler: `nightly-2026-09-07-14d9829`, arm64 macOS.

`make` returns a record containing an effectful callback. Its signature determines
the callback argument's U64 type, but JSON derivation on an inferred record using
that argument stalls. An explicit local record annotation resolves the problem.

```sh
timeout 5 roc check --no-cache roc-bugs/effectful-record-json-inference/repro.roc
roc check --no-cache roc-bugs/effectful-record-json-inference/control.roc
```

Observed: repro exits 124 (timeout); control finishes with zero errors/warnings.
The original transport trace also timed out at 20 seconds and an earlier unbounded
attempt was interrupted. Expected: both equivalent, well-typed programs finish.
The control adds only `event : Event` before the record expression. The identical
annotation is used by `benchmarks/transport.roc`; no transport behavior changes.
