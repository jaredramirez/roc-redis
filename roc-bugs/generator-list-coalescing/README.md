# Heap corruption while replacing a list's last string

Observed September 8 on arm64 macOS, Roc `nightly-2026-09-07-14d9829`.
Both dev and speed compile `repro.roc` successfully, then the executable aborts
(shell status 134 / SIGABRT). The full catalog application additionally reported
`malloc: Heap corruption detected, free list is damaged` during the native Nix
check. The reduced executable aborts without reliably printing that diagnostic.

```console
roc build --opt=dev --no-cache roc-bugs/generator-list-coalescing/repro.roc --output=/tmp/roc-coalesce-repro
timeout 10 /tmp/roc-coalesce-repro
roc build --opt=dev --no-cache roc-bugs/generator-list-coalescing/control.roc --output=/tmp/roc-coalesce-control
timeout 10 /tmp/roc-coalesce-control
```

Use unused output paths. Repeat with `--opt=speed` for the second confirmed
backend. The control prints `passed` and exits zero on both tested backends.
Size and other operating systems have not been qualified for this frozen repro.

The application merges adjacent generated list expressions. The failing shape
reads `$segments.last()`, derives string slices, and replaces the final list
entry with `$segments.drop_last(1).append(...)`. The control retains the pending
string separately from completed segments. It produces the same expected
expression on every iteration. This isolates a code-shape-sensitive compiler
memory-management failure; it does not establish the underlying ARC/root cause.

Found during behavior-preserving generator cleanup, not Redis protocol parsing.
The production generator uses the passing pending-segment shape. Keep the repro
independent; do not replace the failing implementation with the workaround.
The suite formats both fixtures; the known-bug verifier executes the control.
