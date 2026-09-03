# `roc bundle` reports an unqualified `AccessDenied` from a read-only working directory

Observed on arm64 macOS with `nightly-2026-09-07-14d9829`. The package input and
requested output directory can both be writable, but invoking `roc bundle` while
the process working directory is read-only exits 1 with this diagnostic:

```text
── ✗ unreported error ──────────────────────────────────────────────────────────

The compiler stopped with the error AccessDenied but did not say why.
```

This is recorded as a compiler/tooling limitation with a poor diagnostic. A
writable working directory may be an intentional requirement; if so, the
compiler should identify the path and operation that require write access.

From the repository root, the following shell fragment creates the reduced
setup. It deliberately changes permissions only inside a new temporary tree:

```sh
scratch="$(mktemp -d)"
mkdir "$scratch/source" "$scratch/output" "$scratch/read-only-cwd"
cp roc-bugs/bundle-readonly-working-directory/main.roc "$scratch/source/main.roc"
chmod a-w "$scratch/read-only-cwd"

(
  cd "$scratch/read-only-cwd"
  roc bundle "$scratch/source/main.roc" --output-dir "$scratch/output"
)

chmod u+w "$scratch/read-only-cwd"
rm -rf "$scratch"
```

Expected: either the archive is written to the requested writable output
directory, or the compiler reports which additional path must be writable.
Actual: the unqualified `AccessDenied` above.

The production bundle-consumer harness hit this when the Nix app ran from an
immutable store snapshot. `scripts/test-bundle.roc` works around it by copying
the package into its private temporary tree and entering that writable tree for
the bundle command, restoring the repository working directory afterward.

This failure is not part of the automated known-bug sentinel because that would
require creating a deliberately read-only directory on every CI host. The
passing bundle-consumer qualification exercises the workaround instead.
