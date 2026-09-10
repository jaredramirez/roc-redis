import Command
import Bytes
import Request
import Resp

## An ordered wire batch with a pure semantic decoder. The transport drains all
## expected replies before this decoder runs, so element errors cannot strand
## later replies on the connection.
Batch(value, decode_err) :: {
	commands : List(Command.Command),
	decoder : List(Resp.Resp) -> Try(value, decode_err),
}.{
	CountError : [ReplyCountMismatch({ expected : U64, actual : U64 })]

	## Explicit custom composition. Execute supplies exactly one reply per command.
	new : List(Command.Command), (List(Resp.Resp) -> Try(value, error)) -> Batch(value, error)
	new = |commands, decode| Batch.{ commands, decoder: decode }

	commands : Batch(value, error) -> List(Command.Command)
	commands = |batch| batch.commands

	## Lift one request into a batch plan for heterogeneous composition.
	one : Request.Request(value, error) -> Batch(value, [ServerError(Bytes.Bytes), ReplyDecodeFailure(error), ReplyCountMismatch({ expected : U64, actual : U64 })])
	one = |request| Batch.{
		commands: [request.command()],
		decoder: |responses| match responses {
			[response] => request.decode(response).map_err(
				|failure| match failure {
					ServerError(bytes) => ServerError(bytes)
					ReplyDecodeFailure(error) => ReplyDecodeFailure(error)
				},
			)
			_ => Err(ReplyCountMismatch({ expected: 1, actual: responses.len() }))
		},
	}

	## Compose independently typed plans into one exchange and semantic value.
	## Their error types stay distinct. The complete wire batch is drained before
	## either semantic decoder runs; this does not provide transaction atomicity.
	map2 : Batch(a, left_err), Batch(b, right_err), (a, b -> value) -> Batch(value, [LeftFailure(left_err), RightFailure(right_err)])
	map2 = |left, right, combine| {
		left_decoder = left.decoder
		right_decoder = right.decoder
		left_count = left.commands.len()
		Batch.{
			commands: left.commands.concat(right.commands),
			decoder: |responses| {
				a = left_decoder(responses.take_first(left_count)).map_err(|error| LeftFailure(error))?
				b = right_decoder(responses.drop_first(left_count)).map_err(|error| RightFailure(error))?
				Ok(combine(a, b))
			},
		}
	}

	decode : Batch(value, error), List(Resp.Resp) -> Try(value, [BatchDecodeFailure(error), ReplyCountMismatch({ expected : U64, actual : U64 })])
	decode = |batch, responses|
		if responses.len() != batch.commands.len() {
			Err(ReplyCountMismatch({ expected: batch.commands.len(), actual: responses.len() }))
		} else {
			decoder = batch.decoder
			decoder(responses).map_err(|error| BatchDecodeFailure(error))
		}

	## Preserve every element's success, server error, or custom decoder failure.
	each : List(Request.Request(value, error)) -> Batch(List(Try(value, Request.Error(error))), CountError)
	each = |requests| Batch.{
		commands: requests.map(Request.command),
		decoder: |responses| decode_each(requests, responses),
	}

	## Return the first semantic failure after the full batch has been drained.
	all : List(Request.Request(value, error)) -> Batch(List(value), [ElementFailed({ index : U64, error : Request.Error(error) }), ReplyCountMismatch({ expected : U64, actual : U64 })])
	all = |requests| Batch.{
		commands: requests.map(Request.command),
		decoder: |responses| {
			if requests.len() != responses.len() {
				return Err(ReplyCountMismatch({ expected: requests.len(), actual: responses.len() }))
			}
			var $values = List.with_capacity(requests.len())
			var $index = 0
			for request in requests {
				match responses.get($index) {
					Ok(response) => {
						value = request.decode(response).map_err(|error| ElementFailed({ index: $index, error }))?
						$values = $values.append(value)
					}
					Err(_) => {
						return Err(ReplyCountMismatch({ expected: requests.len(), actual: responses.len() }))
					}
				}
				$index = $index + 1
			}
			Ok($values)
		},
	}

	map : Batch(a, error), (a -> b) -> Batch(b, error)
	map = |batch, transform| {
		decoder = batch.decoder
		Batch.{ commands: batch.commands, decoder: |responses| decoder(responses).map_ok(transform) }
	}
}

decode_each : List(Request.Request(value, error)), List(Resp.Resp) -> Try(List(Try(value, Request.Error(error))), Batch.CountError)
decode_each = |requests, responses| {
	if requests.len() != responses.len() {
		return Err(ReplyCountMismatch({ expected: requests.len(), actual: responses.len() }))
	}
	var $values = List.with_capacity(requests.len())
	var $index = 0.U64
	for request in requests {
		match responses.get($index) {
			Ok(response) => {
				$values = $values.append(request.decode(response))
			}
			Err(_) => {
				return Err(ReplyCountMismatch({ expected: requests.len(), actual: responses.len() }))
			}
		}
		$index = $index + 1
	}
	Ok($values)
}

expect {
	request = Request.new(
		Command.ping(),
		|response| match response {
			Resp.Integer(value) => Ok(value)
			_ => Err(NotInteger)
		},
	)
	batch = Batch.each([request, request, request])
	batch.decode([Resp.Integer(1), Resp.simple_utf8("wrong"), Resp.Integer(3)]) == Ok([Ok(1), Err(ReplyDecodeFailure(NotInteger)), Ok(3)])
}

expect {
	request = Request.new(Command.ping(), |_response| Ok(1))
	Batch.each([request]).decode([]).is_err()
}

expect {
	left = Batch.one(
		Request.new(
			Command.ping(),
			|response| match response {
				Resp.Integer(number) => Ok(number)
				_ => Err(NotInteger)
			},
		),
	)
	right = Batch.one(
		Request.new(
			Command.ping(),
			|response| match response {
				Resp.BulkString(bytes) => Ok(bytes)
				_ => Err(NotBulk)
			},
		),
	)
	combined = Batch.map2(left, right, |number, bytes| { number, bytes })
	combined.decode([Resp.Integer(7), Resp.BulkString([0, 255])]) == Ok({ number: 7, bytes: [0, 255] })
}
