# Broken documentation link is reported twice

Roc compiler: `nightly-2026-09-04-c125b82`

This package deliberately contains one invalid documentation reference,
`[Resp.Resp]`. The target module and its `Resp` nominal type both exist, but
the generated documentation exposes the type at `#Resp`, not `#Resp.Resp`.

Run from the repository root:

```sh
output=/tmp/roc-docs-broken-link-repro
rm -rf "$output"
roc docs --no-cache --output="$output" \
  roc-bugs/docs-broken-link-double-report/main.roc
rm -rf "$output"
```

Expected: `roc docs` exits nonzero and reports the invalid reference once.

Actual: after the useful diagnostic, Roc emits a second diagnostic claiming
that the first error was not reported:

```text
Error: 1 doc reference(s) point at non-existent anchors:
  .../Reply.roc:5: [Resp.Resp] -> #Resp.Resp
── ✗ unreported error ──────────────────────────────────────────────────────────

The compiler stopped with the error BrokenDocLinks but did not say why.

This is a bug in the compiler: whatever failed should have explained itself.
```

The first diagnostic demonstrates that `BrokenDocLinks` *was* explained. The
compiler should preserve that useful diagnostic and omit only the contradictory
"unreported error" footer.

This was found while generating documentation for `roc-redis`. The production
documentation uses the valid code-form reference `` `Resp.Resp` ``, so package
documentation still builds. `scripts/check-known-bug.roc` runs this repro with
a randomized output path, requires exit status 1 and both parts of the known
failure shape, and recursively removes the partially generated documentation
whether the assertion passes or fails.
