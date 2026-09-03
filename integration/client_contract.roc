## Deterministic, no-network contract tests for Execute's effect orchestration.
##
## Run with:
##
##     roc integration/client_contract.roc
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "../package/main.roc",
}

import pf.OsStr
import redis.Batch
import redis.Bytes
import redis.Command
import redis.Config
import redis.Decoder
import redis.Execute
import redis.NoReply
import redis.Reply
import redis.Request
import redis.Resp

main! : List(OsStr) => Try({}, [ContractFailed(Str), Exit(I32), ..])
main! = |args| {
	test_decoder_matrix!(args.len())?
	test_long_fragmented_exchange!(args.len())?
	test_execute!({})?
	test_execute_failures!({})?
	test_migrated_regressions!({})?
	Ok({})
}

## Runtime seed keeps the larger fragmentation matrix out of compile-time
## expectation evaluation. Validate all bytes and every two-part split.
test_decoder_matrix! : U64 => Try({}, [ContractFailed(Str), ..])
test_decoder_matrix! = |seed| {
	var $payload = List.with_capacity(256)
	var $number = 0.U64
	while $number < 256 {
		$payload = $payload.append(($number + seed % 256).to_u8_wrap())
		$number = $number + 1
	}
	wire = "$256\r\n".to_utf8().concat($payload).concat(['\r', '\n'])
	expected = [Resp.BulkString($payload)]
	var $split = 0.U64
	while $split <= wire.len() {
		match Decoder.feed(Decoder.init({}), wire.take_first($split)) {
			Failed(_) => {
				return fail("first decoder fragment failed")
			}
			Progress({ decoder, values }) => {
				match Decoder.feed(decoder, wire.drop_first($split)) {
					Failed(_) => {
						return fail("second decoder fragment failed")
					}
					Progress({ decoder: final_decoder, values: following }) => {
						if values.concat(following) != expected or Decoder.finish(final_decoder).is_err() {
							return fail("fragmentation changed the binary bulk payload")
						}
					}
				}
			}
		}
		$split = $split + 1
	}
	var $decoder = Decoder.init({})
	var $values = []
	var $index = 0.U64
	while $index < wire.len() {
		match Decoder.feed($decoder, wire.sublist({ start: $index, len: 1 })) {
			Failed(_) => {
				return fail("single-byte decoder fragment failed")
			}
			Progress({ decoder, values }) => {
				$decoder = decoder
				$values = $values.concat(values)
			}
		}
		$index = $index + 1
	}
	if $values != expected or Decoder.finish($decoder).is_err() {
		return fail("single-byte fragmentation changed payload")
	}
	Ok({})
}

Ok(execution_config) = Config.default |> Config.build

## A large number of reads must not grow the execution call stack. Bounds
## encode the cursor, avoiding hidden mutable state in the fake transport.
test_long_fragmented_exchange! : U64 => Try({}, [ContractFailed(Str), ..])
test_long_fragmented_exchange! = |seed| {
	var $payload = List.with_capacity(25_000)
	var $index = 0.U64
	while $index < 25_000 {
		$payload = $payload.append(($index + seed).to_u8_wrap())
		$index = $index + 1
	}
	wire = "$25000\r\n".to_utf8().concat($payload).concat(['\r', '\n'])
	policy = Config.default |> Config.with_read_size(wire.len()) |> Config.with_max_response_bytes(wire.len()) |> Config.build ? |error| ContractFailed(Str.inspect(error))
	transport : Execute.Transport(_, _)
	transport = {
		write_all!: |_| Ok({}),
		read!: |limit| if limit > 0 and limit <= wire.len() {
			Ok(Data(wire.sublist({ start: wire.len() - limit, len: 1 })))
		} else {
			Err(InvalidReadLimit)
		},
	}
	actual = Execute.request!(policy, Request.new(Command.echo($payload), Reply.bulk), transport) ? |error| ContractFailed(Str.inspect(error))
	if actual == $payload {
		Ok({})
	} else {
		fail("large single-byte exchange changed payload")
	}
}

Ok(tiny_execution_config) = Config.default |> Config.with_max_request_bytes(13) |> Config.build

Ok(short_read_config) = Config.default |> Config.with_read_size(3) |> Config.build

Ok(response_budget_config) = Config.default |> Config.with_max_response_bytes(6) |> Config.build

Ok(single_command_config) = Config.default |> Config.with_max_commands(1) |> Config.build

## Failure categories must preserve the original platform and protocol errors.
test_execute_failures! : {} => Try({}, [ContractFailed(Str), ..])
test_execute_failures! = |_| {
	request = Request.new(Command.ping({}), Reply.simple)
	read_failure : Execute.Transport(_, _)
	read_failure = { write_all!: |_| Ok({}), read!: |_| Err(TimedOut) }
	match Execute.request!(execution_config, request, read_failure) {
		Err(ExchangeFailed(ReadFailed(TimedOut))) => {}
		_ => {
			return fail("Execute lost the concrete read error")
		}
	}
	eof : Execute.Transport(_, _)
	eof = { write_all!: |_| Ok({}), read!: |_| Ok(End) }
	match Execute.request!(execution_config, request, eof) {
		Err(ExchangeFailed(ConnectionClosed({ expected: 1, received: 0 }))) => {}
		_ => {
			return fail("Execute did not distinguish clean EOF from read failure")
		}
	}
	empty : Execute.Transport(_, _)
	empty = { write_all!: |_| Ok({}), read!: |_| Ok(Data([])) }
	match Execute.request!(execution_config, request, empty) {
		Err(ExchangeFailed(EmptyData)) => {}
		_ => {
			return fail("Execute accepted an empty data read")
		}
	}
	oversized : Execute.Transport(_, _)
	oversized = { write_all!: |_| Ok({}), read!: |_| Ok(Data("+PONG\r\n".to_utf8())) }
	match Execute.request!(short_read_config, request, oversized) {
		Err(ExchangeFailed(ReadLimitExceeded({ actual: 7, limit: 3 }))) => {}
		_ => {
			return fail("Execute accepted bytes exceeding the requested read size")
		}
	}
	budget : Execute.Transport(_, _)
	budget = {
		write_all!: |_| Ok({}),
		read!: |max_bytes| if max_bytes == 6 {
			Ok(Data("+PONG\r".to_utf8()))
		} else {
			Err(ReadPastBudget)
		},
	}
	match Execute.request!(response_budget_config, request, budget) {
		Err(ExchangeFailed(ResponseByteLimitExceeded({ limit: 6 }))) => {}
		_ => {
			return fail("Execute read past its cumulative response budget")
		}
	}
	untouched : Execute.Transport(_, _)
	untouched = { write_all!: |_| Err(WriteMustNotRun), read!: |_| Err(ReadMustNotRun) }
	match Execute.batch!(single_command_config, Batch.each([request, request]), untouched) {
		Err(RequestRejected(CommandLimitExceeded({ actual: 2, limit: 1 }))) => {}
		_ => {
			return fail("Execute failed to enforce command count before effects")
		}
	}
	for suffix in ["+EXTRA\r\n", "+"] {
		extra : Execute.Transport(_, _)
		extra = { write_all!: |_| Ok({}), read!: |_| Ok(Data("+PONG\r\n${suffix}".to_utf8())) }
		match Execute.request!(execution_config, request, extra) {
			Err(ExchangeFailed(UnexpectedData(_))) => {}
			_ => {
				return fail("Execute accepted an extra complete or partial response")
			}
		}
	}
	malformed : Execute.Transport(_, _)
	malformed = { write_all!: |_| Ok({}), read!: |_| Ok(Data("+PONG\r\n?".to_utf8())) }
	match Execute.batch!(execution_config, Batch.each([request, request]), malformed) {
		Err(ExchangeFailed(ProtocolFailure({ completed: 1, .. }))) => {}
		_ => {
			return fail("Execute lost the completed prefix on malformed protocol")
		}
	}
	wrong_shape : Execute.Transport(_, _)
	wrong_shape = { write_all!: |_| Ok({}), read!: |_| Ok(Data(":1\r\n".to_utf8())) }
	match Execute.request!(execution_config, request, wrong_shape) {
		Err(ReplyDecodeFailure(UnexpectedReply(_))) => {}
		_ => {
			return fail("Execute conflated semantic decoding with protocol failure")
		}
	}
	match Execute.no_reply!(tiny_execution_config, NoReply.unsafe_assume_suppressed([Command.ping({})]), { write_all!: |_| Err(WriteMustNotRun) }) {
		Err(RequestRejected(RequestByteLimitExceeded({ limit: 13 }))) => {}
		_ => {
			return fail("Execute.no_reply! wrote an oversized request")
		}
	}
	Ok({})
}

test_execute! : {} => Try({}, [ContractFailed(Str), ..])
test_execute! = |_| {
	request = Request.new(Command.ping({}), Reply.simple)
	transport : Execute.Transport(_, _)
	transport = {
		write_all!: |bytes| if bytes == Command.encode(Command.ping({})) {
			Ok({})
		} else {
			Err(WrongBytes)
		},
		read!: |_| Ok(Data("+PONG\r\n".to_utf8())),
	}
	match Execute.request!(execution_config, request, transport) {
		Ok(bytes) if bytes == "PONG".to_utf8() => {}
		_ => {
			return fail("Execute.request! did not return the decoded value")
		}
	}
	untouched : Execute.Transport(_, _)
	untouched = { write_all!: |_| Err(WriteMustNotRun), read!: |_| Err(ReadMustNotRun) }
	match Execute.request!(tiny_execution_config, request, untouched) {
		Err(RequestRejected(RequestByteLimitExceeded({ limit: 13 }))) => {}
		_ => {
			return fail("Execute.request! failed to reject oversized output before effects")
		}
	}
	match Execute.request!(execution_config, request, untouched) {
		Err(ExchangeFailed(WriteFailed(WriteMustNotRun))) => {}
		_ => {
			return fail("Execute.request! did not classify a failed write")
		}
	}
	server_error : Execute.Transport(_, _)
	server_error = { write_all!: |_| Ok({}), read!: |_| Ok(Data("-ERR bad\r\n".to_utf8())) }
	match Execute.request!(execution_config, request, server_error) {
		Err(ServerError(bytes)) if bytes == Bytes.from_str("ERR bad") => {}
		_ => {
			return fail("Execute.request! did not preserve Redis error bytes")
		}
	}
	integer_request = Request.new(
		Command.ping({}),
		|response| match response {
			Resp.Integer(number) => Ok(number)
			_ => Err(NotInteger)
		},
	)
	batch_transport : Execute.Transport(_, _)
	batch_transport = {
		write_all!: |bytes| if bytes == Command.encode_pipeline([Command.ping({}), Command.ping({}), Command.ping({})]) {
			Ok({})
		} else {
			Err(WrongBatchBytes)
		},
		read!: |_| Ok(Data(":1\r\n+wrong\r\n:3\r\n".to_utf8())),
	}
	match Execute.batch!(execution_config, Batch.each([integer_request, integer_request, integer_request]), batch_transport) {
		Ok([Ok(1), Err(ReplyDecodeFailure(NotInteger)), Ok(3)]) => {}
		_ => {
			return fail("Execute.batch! lost an element result after a semantic failure")
		}
	}
	match Execute.batch!(execution_config, Batch.each([]), untouched) {
		Ok([]) => {}
		_ => {
			return fail("empty Execute.batch! performed effects")
		}
	}
	match Execute.no_reply!(
		execution_config,
		NoReply.unsafe_assume_suppressed([Command.ping({})]),
		{
			write_all!: |bytes| if bytes == Command.encode(Command.ping({})) {
				Ok({})
			} else {
				Err(WrongBytes)
			},
		},
	) {
		Ok({}) => {}
		_ => {
			return fail("Execute.no_reply! failed with only a write capability")
		}
	}
	Ok({})
}

Ok(split_config) = Config.default |> Config.with_max_response_bytes(7) |> Config.with_read_size(4) |> Config.build

Ok(bulk_limit_config) = Config.default |> Config.with_decoder_limits({ ..Decoder.default_limits, max_bulk_length: 1 }) |> Config.build

Ok(batch_budget_config) = Config.default |> Config.with_max_response_bytes(9) |> Config.build

Ok(reuse_config) = Config.default |> Config.with_max_response_bytes(17) |> Config.with_read_size(31) |> Config.build

## Coverage migrated from Client/Operation before removing those APIs.
test_migrated_regressions! : {} => Try({}, [ContractFailed(Str), ..])
test_migrated_regressions! = |_| {
	request = Request.new(Command.ping({}), Reply.simple)
	for ended in [False, True] {
		transport : Execute.Transport(_, _)
		transport = {
			write_all!: |_| Ok({}),
			read!: |limit| match limit {
				4 => Ok(Data("+PON".to_utf8()))
				3 => if ended {
					Ok(End)
				} else {
					Ok(Data("G\r\n".to_utf8()))
				}
				_ => Err(UnexpectedReadLimit(limit))
			},
		}
		result = Execute.request!(split_config, request, transport)
		match (ended, result) {
			(False, Ok(bytes)) if bytes == "PONG".to_utf8() => {}
			(True, Err(ExchangeFailed(ProtocolFailure({ completed: 0, error: UnexpectedEnd({ at: 4, .. }) })))) => {}
			_ => return fail("split read lost its decoder state or EOF position")
		}
	}
	bulk_transport : Execute.Transport(_, _)
	bulk_transport = { write_all!: |_| Ok({}), read!: |_| Ok(Data("$2\r\nhi\r\n".to_utf8())) }
	match Execute.request!(bulk_limit_config, request, bulk_transport) {
		Err(ExchangeFailed(ProtocolFailure({ completed: 0, error: BulkLengthLimitExceeded({ actual: 2, limit: 1, .. }) }))) => {}
		_ => return fail("configured decoder bulk bound was not enforced through Execute")
	}
	budget_transport : Execute.Transport(_, _)
	budget_transport = {
		write_all!: |_| Ok({}),
		read!: |limit| if limit == 9 {
			Ok(Data("+OK\r\n+OK\r".to_utf8()))
		} else {
			Err(UnexpectedReadLimit(limit))
		},
	}
	match Execute.batch!(batch_budget_config, Batch.each([request, request]), budget_transport) {
		Err(ExchangeFailed(ResponseByteLimitExceeded({ limit: 9 }))) => {}
		_ => return fail("response budget reset between batch elements")
	}
	binary = [0, '\r', '\n', 255]
	commands = [Command.ping({}), Command.echo(binary)]
	binary_transport : Execute.Transport(_, _)
	binary_transport = {
		write_all!: |bytes| if bytes == Command.encode_pipeline(commands) {
			Ok({})
		} else {
			Err(WrongBytes)
		},
		read!: |_| Ok(Data("+PONG\r\n$4\r\n".to_utf8().concat(binary).concat(['\r', '\n']))),
	}
	raw_batch = Batch.each(commands.map(|command| Request.new(command, |reply| Ok(reply))))
	match Execute.batch!(execution_config, raw_batch, binary_transport) {
		Ok([Ok(Resp.SimpleString(pong)), Ok(Resp.BulkString(value))]) if pong == "PONG".to_utf8() and value == binary => {}
		_ => return fail("batch lost wire ordering or arbitrary binary values")
	}
	for response in ["-ERR rejected\r\n", ":1\r\n"] {
		transport : Execute.Transport(_, _)
		transport = {
			write_all!: |_| Ok({}),
			read!: |limit| if limit == 17 {
				Ok(Data(response.to_utf8()))
			} else {
				Err(UnexpectedReadLimit(limit))
			},
		}
		okay = Request.new(Command.ping({}), Reply.okay)
		failure = Execute.request!(reuse_config, okay, transport)
		match failure {
			Err(ServerError(bytes)) if bytes == Bytes.from_str("ERR rejected") => {}
			Err(ReplyDecodeFailure(UnexpectedReply({ actual: Resp.Integer(1), expected: OkayReply }))) => {}
			_ => return fail("server and semantic failures were conflated with transport failure")
		}
		following : Execute.Transport(_, _)
		following = {
			write_all!: |_| Ok({}),
			read!: |limit| if limit == 17 {
				Ok(Data("+OK\r\n".to_utf8()))
			} else {
				Err(UnexpectedReadLimit(limit))
			},
		}
		match Execute.request!(reuse_config, okay, following) {
			Ok({}) => {}
			_ => return fail("configuration was not reusable after an aligned reply failure")
		}
	}
	match Execute.no_reply!(execution_config, NoReply.unsafe_assume_suppressed([]), { write_all!: |_| Err(MustNotWrite) }) {
		Ok({}) => {}
		_ => return fail("empty no-reply plan performed effects")
	}
	match Execute.no_reply!(execution_config, NoReply.unsafe_assume_suppressed([Command.ping({})]), { write_all!: |_| Err(FailedWrite) }) {
		Err(WriteFailed(FailedWrite)) => {}
		_ => return fail("no-reply execution lost the platform write error")
	}
	Ok({})
}

fail : Str -> Try({}, [ContractFailed(Str), ..])
fail = |message| Err(ContractFailed(message))
