# Missing bundle output directory produces an unreported error

Observed with `nightly-2026-09-07-14d9829` on Apple Silicon macOS while
preparing roc-redis's first RC. No package-source changes were required.

From the repository root, with the pinned compiler available:

```sh
repro_dir=$(mktemp -d)
roc bundle package/main.roc package/LICENSE package/NOTICE --output-dir "$repro_dir/absent"
```

Actual: nonzero exit and `unreported error`; the compiler reports
`FileNotFound` without identifying the missing output directory.

Expected: create the destination or explain that the destination does not
exist. Workaround: create the output directory first (`just bundle` already
does this). This is a diagnostic issue, not a Redis codec or execution defect.
