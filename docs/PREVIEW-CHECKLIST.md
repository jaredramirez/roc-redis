# Community preview checklist

This is a publishing checklist, not evidence that a release exists.

- [x] Show exact nightly, dev default, experimental optimized backends, and RESP2 scope.
- [x] Add contribution instructions and distinguish generated code/compiler repros.
- [x] Confirm Apache 2.0; include and verify repository/package license and notice in bundles.
- [x] Finish third-party provenance/attribution notes (`THIRD_PARTY.md`).
- [x] Record four independent Sol API reviews and focused community questions.
- [x] Confirm repository destination and publication authority.
- [x] Publish source and run configured remote Linux/macOS CI on the exact revision.
- [x] Publish a fixed, content-addressed preview bundle only after its checks pass.
- [x] Put its real content-addressed URL in a complete installation example.
- [x] Test that exact public URL from a fresh downstream directory/cache.

Do not substitute a local bundle test for verification of the public URL, or
describe configured CI as passing before actual remote runs finish. A preview
release should link the exact source revision and identify the pinned compiler.

## Publication and fresh-consumer procedure

1. Confirm license, repository, and authority to publish the current source.
   Include the license/notice in the actual bundle, not just the repository.
2. Push the reviewed source revision and observe its real CI runs. Record both
   the SHA and run URLs; fix failures before creating the preview release.
3. Build with the pinned compiler using `just bundle`, inspect the archive,
   and publish it as an immutable prerelease asset tied to that source revision.
4. Replace the local dependency in the complete [installation example](INSTALL.md)
   with the exact HTTPS asset URL, including its content-addressed filename.
5. In a new downstream directory, use an empty XDG_CACHE_HOME and ROC_CACHE_DIR
   and invoke the raw pinned compiler (not the project's cache-seeding wrapper).
   Check, test, build, and run the example against that public URL. No checkout
   path may remain as the Redis dependency. Record the URL, compiler, SHA, and
   results. A platform download in this test is expected.
6. Only then mark installation/remote-CI items complete and post the community
   message drafted in [COMMUNITY-FEEDBACK.md](COMMUNITY-FEEDBACK.md).

The repository is public at `https://github.com/jaredramirez/roc-redis`.
The maintainer approved preparing and publishing `0.1.0-rc1` on September 9.
Publication checks are recorded below. Do not replace the RC asset in place;
publish another version if package contents change.

## 0.1.0-rc1 publication (September 9)

- [Release](https://github.com/jaredramirez/roc-redis/releases/tag/0.1.0-rc1),
  source `ff103969a696fa4385cb6379a107b08d1322ffe5`.
- All 16 jobs in the [exact-revision Linux/macOS CI run](https://github.com/jaredramirez/roc-redis/actions/runs/34412246159)
  passed before publication, including the Linux pooling integration.
- Published archive: `D8HziVQtZBUBer5ASdLDqwsFwXwZ2pV5XNQ9C21urvTZ.tar.zst`.
  SHA-256: `20a48faec89feed173d5ca5206b1318131a2b75b6301ad48588baf4e71b7633c`.
  LICENSE and NOTICE were compared with the repository copies; checksums are
  attached to the release.
- On Apple Silicon macOS, the README app was copied to a fresh temporary
  directory and checked/built with the raw pinned compiler, fresh
  `XDG_CACHE_HOME` and `ROC_CACHE_DIR`, and the actual public release URL.
  No repository cache-seeding wrapper or local Redis-package dependency was used.
- The exact app checked and built with zero errors/warnings. A runtime copy
  changed only the TCP port from 6379 to 46379 because 6379 was occupied by an
  existing SSH forward. The ownership-aware Roc harness started disposable
  Redis on 46379, executed the read/modify/write app successfully, and cleaned up.
- The no-server application in `INSTALL.md` also ran successfully against the
  public release and printed the GET command's parts.
- API documentation generation passed locally. GitHub Pages is not yet configured.

## Local preparation checks (September 8)

- Full native `nix flake check path:. --print-build-logs` passed after these additions.
- The composition example and its imports passed 62 expectations on dev, speed,
  and size; the dev executable printed the expected success and compact error.
- The complete local installation snippet built and ran in a separate temporary
  directory against the checkout dependency. This was not a public-URL test.
- Current documentation file links and source whitespace checks passed.
- No public repository, release, or remote CI run was created during preparation.
