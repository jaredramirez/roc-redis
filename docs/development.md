# Development map

Enter `nix develop` from the repository root. The repository pins September 7;
an already-open shell can retain an older compiler, so check `roc version`
after changing the flake. During untracked work use `nix develop path:.` or
`nix run path:.#...` so new source files are included.

| Task | Command | Owner |
| --- | --- | --- |
| Formatting, type checks, catalog snapshot | `just check` | `scripts/test.roc check` |
| Expectations, compiled runtime contracts, bundle proof | `just test` | `scripts/test.roc test`, then bundle harness |
| Isolated CLI and webserver proofs | `just integration` | Platform harnesses |
| All portable checks plus known bugs and integrations | `just all` | Just composes existing entry points |
| Dev/speed/size execution qualification | `just backend-check dev speed size` | Dev controller, explicitly selected subjects |
| Hermetic checks | `nix flake check path:.` | Nix checks |
| Generated properties | `just fuzz resp_round_trip run --runs=10000` | Upstream roc-fuzz platform |
| Full memory probes | `just memory-profile full 1` | Separate process per case |

`just all` does not imply all fuzz campaigns, backend combinations, or benchmarks.
Those are deliberately explicit. Timed benchmarks should run without concurrent
builds or other benchmarks. See [perf.md](../perf.md) for evidence and caveats.

## Setup structure

- `flake.nix`: inputs, public apps, development shells, output wiring.
- `nix/toolchain.nix`: immutable compiler/platform pins, caches, source filtering,
  and benchmark dependency versions.
- `nix/packages.nix`: subjects and controllers; build mode is an explicit
  parameter, defaulting to dev. Benchmark subjects opt into benchmarkBuildMode.
- `nix/checks.nix`: hermetic verification and platform-specific exceptions.
- `scripts/TestSuite.roc`: one portable check/expect/runtime inventory.
- `scripts/HarnessText.roc`: pure text parsing shared by harnesses.

Adding a portable test means updating the inventory once, not copying commands
into Nix, Just, and CI. Imported helpers have their expectations evaluated with
their application. Frozen failing fixtures are formatted, not added as passing
tests. Fuzz targets retain their separate platform and checks.

Use `just bundle` for redistribution. It explicitly includes `package/LICENSE`
and `package/NOTICE`; bundling only `package/main.roc` omits those non-Roc files.
Native checks compare their archive contents with the repository originals.

## Process supervision

The harnesses remain Roc applications. The qualified fixed shell bridges for
background launch and parent-death supervision are retained during the upgrade
to basic-cli 0.23.0-rc1; adopting its new native process/resource APIs is separate
work. Their fragments are joined with spaces; splitting fragments for readability
does not change the emitted shell bytes. Dynamic values travel through arguments
or environment variables, not interpolated shell source.

The lifecycle is: allocate an owned directory, start supervision, launch the
service, attest readiness/identity, exercise it, then stop it and remove only
owned state. A failed or ambiguous ownership check must preserve supervision
and report failure rather than signal an unrelated PID or delete live state.
Startup interruption, mismatched PID, and parent-death tests stay in place.

Named BundleLaunch/WebLaunchContext records describe settings, not proof of
ownership. HarnessText only parses text; successful PID parsing never authorizes
a signal. Service-specific identity and cleanup decisions remain local.
