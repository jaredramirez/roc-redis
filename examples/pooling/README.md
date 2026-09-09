# Platform-owned TCP pooling

Run against a disposable, automatically managed Redis instance:

```sh
nix run path:.#pooling-demo
```

Nix generates ABI glue from the pinned Roc compiler's source, builds the Zig
host, runs its unit tests, and builds the Roc application. The existing Roc
integration harness owns Redis startup, timeouts, and cleanup.
The `pooling-integration` flake check runs the same proof in CI. The initial
local end-to-end validation is on Apple Silicon macOS; Linux host code has
been cross-compiled, but Linux execution still needs CI validation.

The boundary stays small:

```roc
pool.with_connection!(2_000, |stream| {
    client = connection(stream)
    pong = client.request!(Commands.Connect.ping())?
    Ok(Reuse(pong))
})
```

`connection` binds the stream's read/write effects to the Redis configuration;
the Redis package knows nothing about pooling. See [main.roc](main.roc).

The callback returns `Reuse(value)` or `Discard(value)`. An error always
discards the socket. Reuse is a protocol-level decision: return it only after
consuming all replies and leaving Redis session state suitable for the next
borrower. Socket errors, timeouts, and EOF poison a lease, so even a subsequent
`Reuse` cannot return that socket to the pool. Escaped stream aliases carry an
expired lease ID and cannot access a later borrower's connection.

The executable checks reuse using Redis's `CLIENT ID`, explicit discard,
callback-error cleanup, stale-alias rejection, bounded capacity exhaustion, and
discard after an actual read timeout even when the callback asks for reuse.

## Deliberately limited platform

This is a small boundary demonstration, **not a production concurrent pool**.
It supports one pool per process, 1–16 connections, IPv4 loopback only, and
1–5,000 ms checkout/connect and per-I/O timeouts. Reads are limited to 1 MiB
and writes to 16 MiB per call. Host calls are serialized: nested checkout at
capacity times out; it does not schedule another task. There is no TLS, DNS,
authentication setup, health-check/retry policy, asynchronous cancellation, or
session reset. A process crash relies on OS socket cleanup.

The portable library is unchanged. A real server platform would supply its own
scheduler and concurrent pool behind the same callback/read/write boundary.
