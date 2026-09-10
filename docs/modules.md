# Module map

Start with `Commands`, `Config`, and `Client`. Generated raw families cover
catalogued commands without semantic decoders. Use `Command.new` for custom or
extension commands; both can support specialized connection-state protocols.
Both layers remain public. `Commands.Session` contains typed connection-management
commands (AUTH, PING, SELECT, CLIENT …); `Session` is their raw counterpart.
Neither owns a transport.

| API path (not import syntax) | Produces or handles | Source |
| --- | --- | --- |
| `redis.Commands.Strings.get` | Typed `Request` with semantic reply decoding | `package/Commands/Strings.roc` |
| `redis.Strings.get` | Raw `Command`, without a reply decoder | `package/Strings.roc` (generated) |
| `redis.Command` | Binary command construction and encoding | `package/Command.roc` |
| `redis.Request`, `redis.Batch`, `redis.NoReply` | Plans for one reply, a batch, or suppressed replies | Corresponding package modules |
| `redis.Execute` | Validated exchange using supplied effectful functions; `Execute.disposition` classifies reuse/discard | `package/Execute.roc` |
| `redis.Transport` | Constructors (`new`, `from_bytes_io`) for the two-effect byte transport | `package/Transport.roc` |
| `redis.Connection` | A bound `{ config, transport }` with `request!` and `batch!`; `Connection.open` builds one | `package/Connection.roc` |
| `redis.Client` | Config plus session policy; mints connections via `attach`, `handshake!`, and `connect!` | `package/Client.roc` |
| `redis.Config` | Pure settings builder; `build` is total (scalar limits are validated positives) | `package/Config.roc` |
| `redis.Decoder`, `redis.Resp` | Incremental RESP2 framing and wire values | Corresponding package modules |
| `redis.Reply` | Pure semantic decoders and explicit UTF-8 validation | `package/Reply.roc` |
| `redis.Bytes`, `redis.NonEmptyBytes`, `redis.NonEmpty`, `redis.Positive` | Small invariant-bearing values | Corresponding package modules |

When raw families appear in examples or applications, alias them explicitly:

```roc
import redis.Strings as RawStrings
import redis.Commands
import redis.Request
import redis.Reply

raw = RawStrings.get("key".to_utf8())
typed = Commands.Strings.get("key")
custom = Request.new(raw, Reply.bulk_or_null)
```

Import `redis.Commands`, then access `Commands.Strings.get`. `Commands.Strings`
is a family exposed through the namespace value, not a separate import needed
for ordinary calls. `connection.request!` takes a `Request`, not a raw `Command`;
`Request.new(raw, decoder)` is the explicit bridge when you want custom semantics.

`package/Commands/Decode.roc` contains shared internal reply shapes, not another
public API. The generated families are checked against the pinned catalog;
edit `scripts/command-catalog.roc`, never their generated output directly.

For the smallest complete applications, see [examples](../examples/README.md).
