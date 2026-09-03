# Contributing

This project is licensed under Apache 2.0; see [LICENSE](LICENSE) and
[NOTICE](NOTICE). Contributions intentionally submitted for inclusion are
covered by the license's contribution terms unless explicitly stated otherwise.

Thanks for trying the preview. API feedback and small real applications on
different Roc platforms are especially useful. See [the module map](docs/modules.md)
and [minimal connectors](examples/README.md) before the larger test harnesses.

## Smallest useful checks

Enter `nix develop` and confirm `roc version` matches `.roc-version`. An older
shell may retain the previous compiler. For new untracked files, use
`nix develop path:.` so Nix includes them.

```console
roc check package/main.roc
roc test --opt=dev package/main.roc
```

Before proposing a change, run `just check` and `just test`. Changes to execution
or adapters also need `just integration`; compiler-sensitive changes need
`just backend-check dev speed size`. Fuzzing and benchmarks are separate:
see [development commands](docs/development.md) and [performance guidance](perf.md).
Do not collect performance data while builds or other benchmarks are running.

## Where to edit

- `package/Commands/`: handwritten typed commands and semantic decoders.
- Top-level command families such as `package/Strings.roc`: generated. Edit
  `scripts/command-catalog.roc`, then run
  `roc --opt=dev scripts/command-catalog.roc -- generate` and `just check`.
- `metadata/redis-8.10.1-command-catalog.json`: normalized server contract;
  do not add copied Redis documentation prose. `just catalog-live` verifies it
  against the exact pinned Redis server.
- `scripts/TestSuite.roc`: the portable test inventory used by Just, Nix, and CI.

Keep changes focused. Preserve binary data, null distinctions, per-element batch
errors, resource limits, and exclusive connection ownership. Don't remove
compiler workarounds merely because another expression looks equivalent.

## Reporting problems

Include the exact Roc version, OS/architecture, backend, smallest reproducer,
expected behavior, and actual output. For Redis behavior, include server version
and the command/reply shape. Use invented credentials and payloads, not real
connection strings, secrets, or customer data.

- Library issue: add an expectation or runtime case that demonstrates the error.
- Compiler issue: put an independent repro and context under `roc-bugs/`, with
  a passing control when possible. Keep it separate from the production fix.
  Link an upstream report if one exists; don't assume every test failure is a
  compiler defect.
- API feedback: show the application code you wanted to write and what felt
  awkward. A small before/after example is more useful than a broad rewrite.

Please do not open a public issue containing an exploitable vulnerability or
secrets. Arrange a private report with the maintainer first; a formal private
reporting channel must be established before broad production adoption.
