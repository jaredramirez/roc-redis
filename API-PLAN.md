# API design and implementation status

The reviewed API is implemented, extended with a `Client` connection factory, a
first-class `Transport`, an infallible refinement-typed `Config`, and the
`Connect`→`Session` command-family rename that freed `connect` for
`Client.connect!`. Adding a public client/session value deliberately reverses the
original decision to ship none initially.

## Current design

- Raw command families construct Command values; Commands families construct
  typed Request values or explicitly encoding-only plans.
- Request combines one command and a custom semantic decoder.
- Batch combines commands into one exchange, retaining per-element Try values
  when requested. No transaction atomicity is implied.
- Execute.request!, Execute.batch!, and Execute.no_reply! expose only their
  relevant capabilities and error families. Execute.disposition classifies a
  failed exchange as Reuse or Discard (discard only on a transport failure).
- Config uses a pure builder and one final build. Scalar limits are
  compile-time-validated positives, so build is total; validate a runtime limit
  with Positive.from_u64 before applying it.
- Client holds config plus session policy (auth, database) and mints
  connections: attach (pure bind), handshake! (AUTH/SELECT), and connect! (both).
  Connection is { config, transport }; Transport.new / Transport.from_bytes_io
  build the two-effect byte transport.
- Bytes and NonEmptyBytes accept literals; binary payloads need no UTF-8
  validation. Reply.utf8 is explicit when text is wanted.
- Platforms own the socket, TLS, deadlines, and pooling; the package needs only
  read! and write_all!. Litmus: a feature may be a built-in battery only if it
  needs nothing beyond those two effects plus pure logic. Handshake and
  disposition qualify; timeouts, dialing, and TLS stay platform-side. Pooling,
  retries, and connection-state protocols are not silently added to the ordinary
  request boundary.

See the [module map](docs/modules.md), [README](README.md), and
[current quality notes](QUALITY-REVIEW.md).

## Decisions and history

The [full accepted review and implementation sequence](docs/history/api-plan.md)
retains every original decision, completion report, and benchmark candidate.
The [simplification checklist](SIMPLIFICATION-PLAN.md) tracks the current pass.
