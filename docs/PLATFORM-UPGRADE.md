# Platform qualification — September 8, 2026

The package remains platform-independent. This change updates the CLI platform
used by examples, integration applications, scripts, and benchmark subjects;
it does not alter Redis protocol or typed-command APIs.

| Dependency | Before | Active pin |
| --- | --- | --- |
| Roc compiler | nightly-2026-09-07-14d9829 | unchanged |
| basic-cli | 0.22.2 | 0.23.0-rc1 |
| basic-webserver | 0.16.0 | unchanged; newest published release |
| roc-http | 2.0.0 | unchanged |

Upstream releases were checked including prereleases, not just GitHub's
latest-stable endpoint. The CLI candidate was published September 8. The
webserver's most recent release is August 11; its older 0.14.0-rc1 is not an
upgrade from 0.16.0.

- [basic-cli 0.23.0-rc1](https://github.com/roc-lang/basic-cli/releases/tag/0.23.0-rc1)
- [basic-webserver releases](https://github.com/roc-lang/basic-webserver/releases)

The CLI archive is
`3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst`;
its published and Nix-verified SHA-256 is
`def8c052d7027604b50d67f209a9d33b3a831e172811d3e31ea1f3a873223018`.
Nix pins the equivalent SRI hash. Frozen compiler repros keep 0.22.2, and the
project cache deliberately seeds both platform archives for offline checks.
Historical benchmark results/patches and their recorded versions are unchanged.

## Scope and safeguards

The candidate adds native process/resource APIs, but the existing qualified
watchdog bridges are retained. Adopting those APIs would require a separate
lifecycle refactor with the same ownership and parent-death guarantees.
No new platform incompatibility or compiler defect was found in this upgrade.

Apache 2.0 was approved and applied to the project. Root and package LICENSE/
NOTICE copies must match. `just bundle` and the downstream harness explicitly
include both files, because a main.roc-only bundle does not include unreferenced
non-Roc files. Native checks extract and compare the actual archive contents.

## Verification

The initial updated-platform native Nix suite and dev/speed/size backend
qualification passed: 933 package expectations per backend, compiled client
contracts, 142 deterministic transport cases per backend, both live platform
integrations, and downstream bundle consumption. Native checks also cover
catalog verification, examples, known compiler regressions, benchmark smoke,
four bounded 10,000-case fuzz campaigns, and the large-fragment memory regression.

The final native `nix flake check path:. --print-build-logs` passed, including
byte-for-byte verification of the bundled LICENSE and NOTICE.
`nix flake check path:. --all-systems --no-build` also passed.
The final `nix run path:.#backend-check -- dev speed size` passed all three
backends again, including both live adapters and license-bearing downstream
bundle consumption.

This is local arm64 macOS execution; all-system evaluation is not native Linux
execution. No remote CI run or new comparative performance campaign is claimed.
