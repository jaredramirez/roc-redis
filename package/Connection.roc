import Batch
import Config
import Execute
import Request

## Validated Config bound to one platform transport for repeated exchanges.
## This is not a socket owner or pool lease: aliases still share the transport.
## Give each exchange exclusive access and discard after ExchangeFailed.
##
## `Client.attach` is the usual way to build one; `open` is the direct route
## when no session policy (auth/db) is involved.
Connection(read_err, write_err) := {
	config : Config.Config,
	transport : Execute.Transport(read_err, write_err),
}.{
	open : Config.Config, Execute.Transport(read_err, write_err) -> Connection(read_err, write_err)
	open = |config, transport| Connection.{ config, transport }

	request! : Connection(read_err, write_err), Request.Request(value, decode_err) => Try(value, Execute.Error(read_err, write_err, decode_err))
	request! = |connection, request|
		Execute.request!(connection.config, request, connection.transport)

	batch! : Connection(read_err, write_err), Batch.Batch(value, decode_err) => Try(value, [RequestRejected(Execute.ValidationError), ExchangeFailed(Execute.ExchangeError(read_err, write_err)), BatchDecodeFailure(decode_err), ReplyCountMismatch({ expected : U64, actual : U64 })])
	batch! = |connection, batch|
		Execute.batch!(connection.config, batch, connection.transport)
}
