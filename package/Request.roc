import Bytes
import Command
import Resp

## One command and its semantic decoder. The decoder's error type belongs to
## the caller. Redis errors are intercepted before invoking that decoder.
Request(value, decode_err) :: {
	command : Command.Command,
	decoder : Resp.Resp -> Try(value, decode_err),
}.{
	Error(error) : [ServerError(Bytes.Bytes), ReplyDecodeFailure(error)]

	new : Command.Command, (Resp.Resp -> Try(value, error)) -> Request(value, error)
	new = |command, decode| Request.{ command, decoder: decode }

	command : Request(value, error) -> Command.Command
	command = |request| request.command

	decode : Request(value, error), Resp.Resp -> Try(value, Error(error))
	decode = |request, response|
		match response {
			Resp.ErrorReply(bytes) => Err(ServerError(Bytes.from_list(bytes)))
			_ => {
				decoder = request.decoder
				decoder(response).map_err(|error| ReplyDecodeFailure(error))
			}
		}

	map : Request(a, error), (a -> b) -> Request(b, error)
	map = |request, transform| {
		decoder = request.decoder
		Request.{ command: request.command, decoder: |response| decoder(response).map_ok(transform) }
	}
}

expect {
	request = Request.new(Command.ping(), |_reply| Err(ApplicationError))
	request.decode(Resp.simple_utf8("PONG")) == Err(ReplyDecodeFailure(ApplicationError))
}

expect {
	request = Request.new(Command.ping(), |_reply| Ok(42))
	request.decode(Resp.error_utf8("ERR bad")) == Err(ServerError(Bytes.from_str("ERR bad")))
}

expect {
	request = Request.new(Command.ping(), |_reply| Ok(42)).map(|value| value + 1)
	request.decode(Resp.simple_utf8("PONG")) == Ok(43)
}
