# Cached package aliases duplicate a compiled source module

Observed on arm64 macOS with `nightly-2026-09-07-14d9829` while upgrading the
project nightly. A dependency has two URL spellings with the same content hash:
the app imports HTTP through its 2.0.0 release URL, while basic-webserver imports
the identical archive through its 1.0.0 release URL.

A subsequent comparison also reproduces the reduced cached case on September 4,
with `typed_cir invariant violated: duplicate module name` instead. This is an
existing cache/alias problem exposed during the upgrade, not evidence that the
September 7 release introduced it.

The reduced pure package here imports Method under both URLs. With a fresh
compiler cache, `roc check` succeeds and the subsequent cached `roc test`
aborts (exit 134):

```text
panic: compiled module plan contains duplicate source module
https://github.com/roc-lang/http/releases/download/2.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst.Method
```

Reproduce with the **unwrapped compiler executable** and a fresh ROC_CACHE_DIR
(the project's shell wrapper overrides that variable):

```sh
ROC_CACHE_DIR=/absolute/path/to/fresh-cache roc check roc-bugs/cached-package-alias-duplicate/main.roc
ROC_CACHE_DIR=/absolute/path/to/fresh-cache roc test --opt=dev roc-bugs/cached-package-alias-duplicate/main.roc
roc test --opt=dev --no-cache roc-bugs/cached-package-alias-duplicate/main.roc
```

Expected: the content-addressed module is loaded once and the test passes.
Actual: check passes, cached test aborts, and `--no-cache` passes its single test.
The unreduced case is `integration/bundle_server.roc`: check followed by a cached
test aborts naming the 1.0.0 URL; `--no-cache` passes all seven expectations.

The workaround is restricted to the two affected integration test invocations
in Justfile/flake.nix; CI already uses uncached tests. No protocol or application
behavior changes. The known-bug checker verifies the uncached control; the
cache-sensitive aborting sequence above is a manual diagnostic.
