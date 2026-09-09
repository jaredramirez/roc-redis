import Batch
import Config
import Execute
import Request

## Configuration and byte-stream effects bound once for repeated exchanges.
## This is not a socket owner or pool lease: aliases still share the stream.
## Give each exchange exclusive access and discard after ExchangeFailed.
Connection(read_err, write_err) := {
	config : Config.Config,
	read! : U64 => Try(Execute.Read, read_err),
	write_all! : List(U8) => Try({}, write_err),
}.{
	request! : Connection(read_err, write_err), Request.Request(value, decode_err) => Try(value, Execute.Error(read_err, write_err, decode_err))
	request! = |connection, request|
		Execute.request!(connection.config, request, { read!: connection.read!, write_all!: connection.write_all! })

	batch! : Connection(read_err, write_err), Batch.Batch(value, decode_err) => Try(value, [RequestRejected(Execute.ValidationError), ExchangeFailed(Execute.ExchangeError(read_err, write_err)), BatchDecodeFailure(decode_err), ReplyCountMismatch({ expected : U64, actual : U64 })])
	batch! = |connection, batch|
		Execute.batch!(connection.config, batch, { read!: connection.read!, write_all!: connection.write_all! })
}
