# Platform examples

For the README's read/modify/write flow, run
`roc --opt=dev examples/read_modify_write.roc` against the disposable Redis below.
It changes `example:greeting`, appends `!` (starting from `Hello` if missing),
and resets its TTL to 60 seconds. Repeated runs print `Hello!`, `Hello!!`, etc.
GET followed by SET is not atomic; do not use this pattern for concurrent updates.

For a no-server demonstration of custom decoding, heterogeneous batches, and
per-element failures, run `roc --opt=dev examples/composition.roc`. Its pure
expectations and compiled application are included in the portable suite.

The read-only CLI and webserver examples show the entire connection boundary without test
assertions, random keys, or process supervision. The full isolated proofs remain
in `integration/` and run with `just integration`.

From the repository root, enter `nix develop`. In a separate shell, start a
foreground disposable Redis (stop with Ctrl-C):

```console
redis-server --bind 127.0.0.1 --port 6379 --save "" --appendonly no
```

Then run either example:

```console
roc --opt=dev examples/cli.roc
roc --opt=dev examples/webserver.roc
```

The CLI prints `PONG`. While the webserver is running,
`curl http://127.0.0.1:8000/` returns `PONG`. If either port is already occupied, stop
and choose matching unused ports in the example and launch command; do not stop
an unrelated service. Both examples only issue PING and do not modify Redis.

Each execution exclusively owns its connection. There are no implicit retries.
The webserver example opens one connection per HTTP request and is a connector
demonstration, not a pooling or HTTP deployment recommendation. Platform-specific
timeouts remain the platform's responsibility. See [the API guide](../docs/usage.md) for failure
categories and when a connection must be discarded.

## Minimal pooled platform

[The Zig pooling demo](pooling/README.md) shows platform-owned checkout,
reuse/discard, and stale-lease protection. Run `nix run path:.#pooling-demo`.
It is intentionally single-threaded and loopback-only, not a production pool.
