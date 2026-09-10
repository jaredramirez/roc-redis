import Batch
import Bytes
import Command
import Config
import Decoder
import NoReply
import Request
import Resp

## Platform-independent execution. The caller owns the connection and gives one
## call exclusive access for its whole exchange. There are no implicit retries.
Execute :: [].{

	Read : [Data(List(U8)), End]
	Transport(read_err, write_err) : {
		read! : U64 => Try(Read, read_err),
		write_all! : List(U8) => Try({}, write_err),
	}

	ValidationError : [
		CommandLimitExceeded({ actual : U64, limit : U64 }),
		RequestByteLimitExceeded({ limit : U64 }),
	]

	## Every failure here occurs after a write was attempted. Discard the stream;
	## execution may already have occurred. Completed counts describe parsed wire
	## replies, not proof that any remaining command was or was not executed.
	ExchangeError(read_err, write_err) : [
		WriteFailed(write_err),
		ReadFailed(read_err),
		ConnectionClosed({ expected : U64, received : U64 }),
		ProtocolFailure({ completed : U64, error : Decoder.DecodeError }),
		EmptyData,
		ReadLimitExceeded({ actual : U64, limit : U64 }),
		ResponseByteLimitExceeded({ limit : U64 }),
		UnexpectedData({ buffered : U64, expected : U64, received : U64 }),
	]

	Error(read_err, write_err, decode_err) : [
		RequestRejected(ValidationError),
		ExchangeFailed(ExchangeError(read_err, write_err)),
		ServerError(Bytes.Bytes),
		ReplyDecodeFailure(decode_err),
	]

	## Rejection leaves the stream untouched. Server/semantic errors follow a
	## complete reply and leave framing aligned. They do not undo command effects.
	request! : Config.Config, Request.Request(value, decode_err), Transport(read_err, write_err) => Try(value, Error(read_err, write_err, decode_err))
	request! = |config, request, transport| {
		responses = exchange!(config, [request.command()], transport) ? |failure| match failure {
			RequestRejected(details) => RequestRejected(details)
			ExchangeFailed(details) => ExchangeFailed(details)
		}
		match responses {
			[response] => request.decode(response).map_err(
				|failure| match failure {
					ServerError(bytes) => ServerError(bytes)
					ReplyDecodeFailure(error) => ReplyDecodeFailure(error)
				},
			)
			_ => Err(ExchangeFailed(UnexpectedData({ buffered: 0, expected: 1, received: responses.len() })))
		}
	}

	batch! : Config.Config, Batch.Batch(value, decode_err), Transport(read_err, write_err) => Try(value, [RequestRejected(ValidationError), ExchangeFailed(ExchangeError(read_err, write_err)), BatchDecodeFailure(decode_err), ReplyCountMismatch({ expected : U64, actual : U64 })])
	batch! = |config, batch, transport| {
		responses = exchange!(config, batch.commands(), transport) ? |failure| match failure {
			RequestRejected(details) => RequestRejected(details)
			ExchangeFailed(details) => ExchangeFailed(details)
		}
		value = batch.decode(responses) ? |failure| match failure {
			BatchDecodeFailure(error) => BatchDecodeFailure(error)
			ReplyCountMismatch(details) => ReplyCountMismatch(details)
		}
		Ok(value)
	}

	## Write-only execution on explicitly suppressed replies. There is no reader
	## capability and no reply-decoder error in this function's type.
	no_reply! : Config.Config, NoReply.NoReply, { write_all! : List(U8) => Try({}, write_err) } => Try({}, [RequestRejected(ValidationError), WriteFailed(write_err)])
	no_reply! = |config, plan, transport| {
		commands = plan.commands()
		encoded = prepare(config, commands).map_err(|error| RequestRejected(error))?
		if commands.is_empty() {
			Ok({})
		} else {
			{ write_all! } = transport
			write_all!(encoded).map_err(|error| WriteFailed(error))
		}
	}

	## Whether the connection is safe to reuse after a failure, or must be
	## discarded. Only a transport failure (ExchangeFailed) corrupts framing;
	## a validation rejection never wrote anything, and server/decoder errors
	## follow a complete, framed reply. See the ExchangeError/Error invariants
	## above. Pooling adapters map this onto their reuse/discard decision.
	Disposition : [Reuse, Discard]

	disposition : Error(read_err, write_err, decode_err) -> Disposition
	disposition = |error| match error {
		ExchangeFailed(_) => Discard
		RequestRejected(_) => Reuse
		ServerError(_) => Reuse
		ReplyDecodeFailure(_) => Reuse
	}

	## Same rule for batch! outcomes: discard only on a transport failure. The
	## complete wire batch is drained before any decoder runs, so decode and
	## count failures leave framing aligned.
	batch_disposition : [RequestRejected(ValidationError), ExchangeFailed(ExchangeError(read_err, write_err)), BatchDecodeFailure(decode_err), ReplyCountMismatch({ expected : U64, actual : U64 })] -> Disposition
	batch_disposition = |error| match error {
		ExchangeFailed(_) => Discard
		RequestRejected(_) => Reuse
		BatchDecodeFailure(_) => Reuse
		ReplyCountMismatch(_) => Reuse
	}
}

expect Execute.disposition(ExchangeFailed(EmptyData)) == Discard
expect Execute.disposition(RequestRejected(RequestByteLimitExceeded({ limit: 16 }))) == Reuse
expect Execute.disposition(ServerError(Bytes.from_str("WRONGTYPE"))) == Reuse
expect Execute.disposition(ReplyDecodeFailure(NotInteger)) == Reuse
expect Execute.batch_disposition(ExchangeFailed(WriteFailed(Timeout))) == Discard
expect Execute.batch_disposition(ReplyCountMismatch({ expected: 2, actual: 1 })) == Reuse

prepare : Config.Config, List(Command.Command) -> Try(List(U8), Execute.ValidationError)
prepare = |config, commands|
	if commands.len() > config.command_limit() {
		Err(CommandLimitExceeded({ actual: commands.len(), limit: config.command_limit() }))
	} else {
		Command.encode_bounded(commands, config.request_byte_limit()).map_err(
			|error| match error {
				RequestByteLimitExceeded(details) => RequestByteLimitExceeded(details)
			},
		)
	}

exchange! : Config.Config, List(Command.Command), Execute.Transport(read_err, write_err) => Try(List(Resp.Resp), [RequestRejected(Execute.ValidationError), ExchangeFailed(Execute.ExchangeError(read_err, write_err))])
exchange! = |config, commands, transport| {
	encoded = prepare(config, commands).map_err(|error| RequestRejected(error))?
	if commands.is_empty() {
		return Ok([])
	}
	{ write_all!, .. } = transport
	{} = write_all!(encoded) ? |error| ExchangeFailed(WriteFailed(error))
	read_responses!(Decoder.with_limits(config.decoder_limits()), commands.len(), List.with_capacity(commands.len()), config, config.response_byte_limit(), transport)
		.map_err(|error| ExchangeFailed(error))
}

read_responses! : Decoder.Decoder, U64, List(Resp.Resp), Config.Config, U64, Execute.Transport(read_err, write_err) => Try(List(Resp.Resp), Execute.ExchangeError(read_err, write_err))
read_responses! = |decoder, expected, previous, config, remaining, transport| {
	var $decoder = decoder
	var $responses = previous
	var $remaining = remaining
	{ read!, .. } = transport
	while $responses.len() < expected {
		if $remaining == 0 {
			return Err(ResponseByteLimitExceeded({ limit: config.response_byte_limit() }))
		}
		max_bytes = if $remaining < config.read_size() {
			$remaining
		} else {
			config.read_size()
		}
		match read!(max_bytes) {
			Err(error) => return Err(ReadFailed(error))
			Ok(End) => return match Decoder.finish($decoder) {
				Ok({}) => Err(ConnectionClosed({ expected, received: $responses.len() }))
				Err(error) => Err(ProtocolFailure({ completed: $responses.len(), error }))
			}
			Ok(Data([])) => return Err(EmptyData)
			Ok(Data(chunk)) if chunk.len() > max_bytes => return Err(ReadLimitExceeded({ actual: chunk.len(), limit: max_bytes }))
			Ok(Data(chunk)) => {
				$remaining = $remaining - chunk.len()
				match Decoder.feed($decoder, chunk) {
					Failed({ completed, error }) => return Err(ProtocolFailure({ completed: $responses.len() + completed.len(), error }))
					Progress({ decoder: next_decoder, values }) => {
						$responses = $responses.concat(values)
						received = $responses.len()
						buffered = Decoder.buffered_len(next_decoder)
						if received > expected or (received == expected and buffered > 0) {
							return Err(UnexpectedData({ buffered, expected, received }))
						}
						$decoder = next_decoder
					}
				}
			}
		}
	}
	Ok($responses)
}
