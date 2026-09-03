# Nested module alias accepts functions but rejects a nominal constructor

Compiler: `nightly-2026-09-04-c125b82`, native arm64 macOS.

Commands from the repository root:

```sh
roc check roc-bugs/nested-alias-type-constructor/repro.roc
roc test --opt=dev roc-bugs/nested-alias-type-constructor/control.roc
```

The repro check exits 1: `The type Inner.Options is not exposed by the module
nested.Outer.` The control passes one expectation. Both call the same
`Outer.Inner.new`; only the explicit nominal record constructor differs.

Expected, if nested public type aliases support transitive type access: the
exported `Options` constructor should be reachable alongside `new`. This might
instead be an intentional current namespace limitation; no claim is made about
the compiler's intended feature scope.

Context: `redis.Commands.Strings.set` is callable from a downstream application,
but `redis.Commands.Strings.SetOptions.{...}` is rejected. Passing a record with
inferred nominal type works, including omitted defaultable fields. The CLI and
bundled consumer exercise that workaround. Internal module tests alone did not
catch the package-boundary restriction.
