# Independent API reviews for community feedback

Four separate `gpt-5.6-sol` reviewers inspected the repository read-only on
September 8, 2026, one per question. These are independent model reviews, not
feedback from Roc maintainers or a substitute for real application use. None
identified a core correctness blocker in its bounded review.

## 1. Effect injection and platform boundaries

**Assessment:** the small structural `{ read!, write_all! }` capability record,
platform-owned connections, and pure Request/Batch plans are coherent. The
write-only sender's narrower capability/error type is a particular strength.
See `package/Execute.roc`, `package/Request.roc`, and the two connector examples.

**Friction:** adapters must translate empty reads into End and annotate the
transport record; repeated calls carry config and transport explicitly. Precise
error categories can make common application handling verbose.

**Resolved:** `Transport.from_bytes_io` folds the empty-is-End adapter, and
`Client` binds config once, so callers hold a client and call `client.connect!`
or `client.attach` instead of threading config and transport per call — this
answers the bound-sender question below. `Execute.disposition` maps the error
families onto a Reuse/Discard decision.

Questions to ask:

- Does passing config and transport per call fit your platform, or would you
  naturally create an application-local bound sender?
- Does the Data/End contract map cleanly onto your platform's byte-stream API?
- Are the failure families enough to decide when to discard a connection,
  without additional classifiers?

## 2. Typed commands, custom decoders, and batch errors

**Assessment:** Request's application-owned decoder error and map operation
compose well. Typed mode/result unions and per-element Batch.each outcomes make
semantics explicit. Full draining before semantic decoding is important.
See `package/Request.roc`, `package/Batch.roc`, and `package/Reply.roc`.

**Friction:** custom structured decoders require manual loops because higher-level
helpers are internal. Three or more heterogeneous requests create a nested
LeftFailure/RightFailure tree. Top-level Redis errors and errors nested in a
structured reply can have different wrappers; count checks exist at more than
one layer for direct decoder use as well as ordinary execution.

Questions to ask:

- Is nested Batch.map2 pleasant for three or more different result types?
- Should list/count/scan decoder combinators be public, or is direct Resp
  matching preferable while keeping the API small?
- Is preserved error provenance worth the nesting, and where would you map
  errors into application-owned summaries?

Before sharing, this reviewer wanted an executable composition/error example.
[examples/composition.roc](../examples/composition.roc) now demonstrates that
boundary without a live server. No new combinator API was added.

## 3. Configuration and literal-backed types

**Assessment:** a pure Builder and non-failing setters feed one final build.
Scalar limits are now compile-time-validated positives, so build is total and the
module-level binding needs no Ok destructure; an invalid literal such as
`Config.with_read_size(0)` fails to compile. Bytes, NonEmptyBytes, NonEmpty, and
Positive separate useful invariants without forcing text decoding.
See their corresponding `package/` modules.

**Friction:** setters use `with_max_*` while getters use `*_limit`; literal hooks
have diagnostic errors different from runtime constructors; NonEmpty examples
sometimes need explicit element types to communicate intended inference.

Questions to ask:

- Is one `Config.default |> with_* |> build` chain intuitive for both constant
  and runtime settings?
- Are literal-hook diagnostics versus runtime constructor errors unsurprising?
- What explicit form is clearest when constructing a `NonEmpty(Bytes)` value?

The current nightly is September 7. Some frozen bug reports were originally
recorded on September 4; do not turn their historical observations into general
claims about Roc. API naming changes remain deferred until real feedback.

## 4. Raw versus typed module discovery

**Assessment:** curated examples and the module map lead with the typed route.
Types distinguish raw Command construction from Request construction clearly.

**Friction:** raw families and Commands have equal top-level export prominence.
The physical `Commands/` directory can suggest different import syntax than
the ordinary namespace-value API. A raw constructor alone doesn't explain the
Request.new bridge to execution.

Questions to ask:

- Without reading implementation code, did you find `import redis.Commands`
  followed by `Commands.Strings.get` as the recommended path?
- When autocomplete offered both Commands and Strings, which did you choose?
- Was it clear when and how to wrap a raw Command in Request.new?

The [module map](modules.md) now explains the import/namespace mechanics and
raw-to-Request bridge. A public Raw namespace or module rename remains a future
design question, not a pre-feedback migration.

## Suggested community post (draft, not posted)

I've been building a platform-agnostic Redis package for Roc and would love API
feedback before stabilizing it. Commands, RESP2 decoding, and semantic reply
decoders are pure; applications supply a small read/write capability record and
keep ownership of connections, timeouts, TLS, and pooling. There are working
basic-cli and basic-webserver examples.

The preview targets `nightly-2026-09-07-14d9829`. Dev is the default; optimized
backends are experimental. It has typed command families, custom decoders,
ordered batches, bounded parsing, and no automatic retries. It does not implement
RESP3, cluster routing, or subscription lifecycle management.

I'm especially interested in whether the effect boundary feels natural, whether
heterogeneous batches/errors are pleasant to compose, whether the config/literal
types feel idiomatic, and whether the raw/typed namespace is easy to discover.
A small example of the code you'd prefer to write would be very helpful.

Before posting, add the repository, verified preview installation URL, and exact
remote CI revision. Link benchmarks only as supporting experimental evidence,
not as the headline or as a claim about unmeasured current source.
