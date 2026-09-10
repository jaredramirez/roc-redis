## Deterministic runtime matrix for Execute's transport-error and completed-prefix
## contracts. The byte-stream model is deliberately literal and independent of
## production encoding helpers.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "../package/main.roc",
}

import pf.OsStr
import pf.Stdout
import redis.Batch
import redis.Command
import redis.Config
import redis.Positive
import redis.Execute
import redis.NoReply
import redis.Request
import redis.Resp

Fault : [EmptyRead, EndOfFile, Malformed, OversizedRead, PartialThenEnd, ReadError]

default_config = Config.build(Config.default)

one_command_config = Config.default |> Config.with_max_commands(1) |> Config.build

request_limit : U64
request_limit = ping_wire(1).len() - 1

Ok(request_bytes) = Positive.from_u64(request_limit)

short_request_config = Config.default |> Config.with_max_request_bytes(request_bytes) |> Config.build

main! : List(OsStr) => Try({}, [TransportPropertiesFailed(Str), Exit(I32), ..])
main! = |args| {
	# The argument-derived start keeps this an executed runtime matrix rather than
	# relying on expectation evaluation. The public CLI intentionally takes no args.
	if args.len() != 1 {
		return Err(TransportPropertiesFailed("usage: transport-properties"))
	}

	var $cases = 0.U64
	var $completed_prefix = 0.U64
	while $completed_prefix <= 16 {
		for fault in [ReadError, EndOfFile, EmptyRead, OversizedRead, Malformed, PartialThenEnd] {
			{} = widen_for_main(require_case!(fault_prefix_case!($completed_prefix, fault), "${fault_label(fault)} after ${$completed_prefix.to_str()} completed replies"))?
			$cases = $cases + 1
		}
		{} = widen_for_main(require_case!(response_limit_case!($completed_prefix), "response limit after ${$completed_prefix.to_str()} completed replies"))?
		$cases = $cases + 1
		{} = widen_for_main(require_case!(semantic_failure_case!($completed_prefix), "Batch.each semantic failure at index ${$completed_prefix.to_str()}"))?
		$cases = $cases + 1
		$completed_prefix = $completed_prefix + 1
	}

	for (label, result) in [
		("command limit rejects before write", command_limit_rejection!({})),
		("request byte limit rejects before write", request_limit_rejection!({})),
		("empty no-reply plan does not write", empty_no_reply!({})),
		("no-reply validates literal wire", successful_no_reply!({})),
		("no-reply preserves write failure", failed_no_reply!({})),
		("no-reply command limit rejects before write", rejected_no_reply!({})),
	] {
		{} = widen_for_main(require_case!(result, label))?
		$cases = $cases + 1
	}

	if $cases != 142 {
		return Err(TransportPropertiesFailed("internal case-count mismatch: expected 142, ran ${$cases.to_str()}"))
	}
	write_result = Stdout.line!("Transport property matrix passed: ${$cases.to_str()} deterministic runtime cases.")
		.map_err(|error| TransportPropertiesFailed("write success message: ${Str.inspect(error)}"))
	{} = widen_for_main(write_result)?
	Ok({})
}

require_case! : Bool, Str => Try({}, [TransportPropertiesFailed(Str)])
require_case! = |passed, label|
	if passed Ok({}) else Err(TransportPropertiesFailed("failed: ${label}"))

fault_prefix_case! : U64, Fault => Bool
fault_prefix_case! = |completed, fault| {
	expected = completed + 1
	prefix = integer_wire(completed)
	budget = prefix.len() + if fault == PartialThenEnd 2 else 1
	config = match fault_config(expected, budget) {
		Ok(value) => value
		Err(_) => return Bool.False
	}
	requests = List.repeat(integer_request({}), expected)
	expected_write = ping_wire(expected)
	transport : Execute.Transport(_, _)
	transport = {
		write_all!: |bytes| if bytes == expected_write Ok({}) else Err(WrongWire),
		read!: |max_bytes| fault_read(prefix, budget, fault, max_bytes),
	}
	result = Execute.batch!(config, Batch.each(requests), transport)
	match (fault, result) {
		(ReadError, Err(ExchangeFailed(ReadFailed(InjectedReadFailure)))) => Bool.True
		(EndOfFile, Err(ExchangeFailed(ConnectionClosed({ expected: actual_expected, received })))) => actual_expected == expected and received == completed
		(EmptyRead, Err(ExchangeFailed(EmptyData))) => Bool.True
		(OversizedRead, Err(ExchangeFailed(ReadLimitExceeded({ actual, limit })))) => actual == 2 and limit == 1
		(Malformed, Err(ExchangeFailed(ProtocolFailure({ completed: actual_completed, error: UnknownType({ at, byte }) })))) => actual_completed == completed and at == 0 and byte == '?'
		(PartialThenEnd, Err(ExchangeFailed(ProtocolFailure({ completed: actual_completed, error: UnexpectedEnd({ at, context: LineEnd }) })))) => actual_completed == completed and at == 1
		_ => Bool.False
	}
}

fault_read : List(U8), U64, Fault, U64 -> Try(Execute.Read, [InjectedReadFailure])
fault_read = |prefix, budget, fault, max_bytes| {
	if max_bytes > budget {
		return Err(InjectedReadFailure)
	}
	offset = budget - max_bytes
	if offset < prefix.len() {
		Ok(Data([byte_at(prefix, offset)]))
	} else {
		match fault {
			ReadError => Err(InjectedReadFailure)
			EndOfFile => Ok(End)
			EmptyRead => Ok(Data([]))
			OversizedRead => Ok(Data(['?', '?']))
			Malformed => Ok(Data(['?']))
			PartialThenEnd => if offset == prefix.len() Ok(Data([':'])) else Ok(End)
		}
	}
}

response_limit_case! : U64 => Bool
response_limit_case! = |completed| {
	expected = completed + 1
	prefix = integer_wire(completed)
	budget = if prefix.is_empty() 1 else prefix.len()
	config = match fault_config(expected, budget) {
		Ok(value) => value
		Err(_) => return Bool.False
	}
	transport : Execute.Transport(_, _)
	transport = {
		write_all!: |bytes| if bytes == ping_wire(expected) Ok({}) else Err(WrongWire),
		read!: |max_bytes| {
			offset = budget - max_bytes
			if completed == 0 {
				Ok(Data([':']))
			} else {
				Ok(Data([byte_at(prefix, offset)]))
			}
		},
	}
	match Execute.batch!(config, Batch.each(List.repeat(integer_request({}), expected)), transport) {
		Err(ExchangeFailed(ResponseByteLimitExceeded({ limit }))) => limit == budget
		_ => Bool.False
	}
}

semantic_failure_case! : U64 => Bool
semantic_failure_case! = |failure_index| {
	count = failure_index + 1
	wire = semantic_wire(failure_index)
	budget = wire.len()
	config = match fault_config(count, budget) {
		Ok(value) => value
		Err(_) => return Bool.False
	}
	transport : Execute.Transport(_, _)
	transport = {
		write_all!: |bytes| if bytes == ping_wire(count) Ok({}) else Err(WrongWire),
		read!: |_| Ok(Data(wire)),
	}
	match Execute.batch!(config, Batch.each(List.repeat(integer_request({}), count)), transport) {
		Ok(results) => semantic_results_match(results, failure_index, 0)
		_ => Bool.False
	}
}

semantic_results_match : List(Try(I64, Request.Error([NotInteger]))), U64, U64 -> Bool
semantic_results_match = |results, failure_index, index|
	match results {
		[] => index == failure_index + 1
		[result, .. as rest] => {
			expected = if index == failure_index {
				result == Err(ReplyDecodeFailure(NotInteger))
			} else {
				result == Ok(1)
			}
			expected and semantic_results_match(rest, failure_index, index + 1)
		}
	}

integer_request : {} -> Request.Request(I64, [NotInteger])
integer_request = |_| Request.new(
	Command.ping({}),
	|response| match response {
		Resp.Integer(value) => Ok(value)
		_ => Err(NotInteger)
	},
)

fault_config : U64, U64 -> Try(Config.Config, [Zero])
fault_config = |commands, budget| {
	command_limit = Positive.from_u64(commands)?
	budget_limit = Positive.from_u64(budget)?
	Ok(
		Config.default
			|> Config.with_max_commands(command_limit)
			|> Config.with_read_size(budget_limit)
			|> Config.with_max_response_bytes(budget_limit)
			|> Config.build,
	)
}

command_limit_rejection! : {} => Bool
command_limit_rejection! = |_| {
	transport : Execute.Transport(_, _)
	transport = { write_all!: |_| Err(WriteMustNotRun), read!: |_| Err(ReadMustNotRun) }
	match Execute.batch!(one_command_config, Batch.each(List.repeat(integer_request({}), 2)), transport) {
		Err(RequestRejected(CommandLimitExceeded({ actual, limit }))) => actual == 2 and limit == 1
		_ => Bool.False
	}
}

request_limit_rejection! : {} => Bool
request_limit_rejection! = |_| {
	transport : Execute.Transport(_, _)
	transport = { write_all!: |_| Err(WriteMustNotRun), read!: |_| Err(ReadMustNotRun) }
	match Execute.batch!(short_request_config, Batch.each([integer_request({})]), transport) {
		Err(RequestRejected(RequestByteLimitExceeded({ limit: actual }))) => actual == request_limit
		_ => Bool.False
	}
}

empty_no_reply! : {} => Bool
empty_no_reply! = |_| Execute.no_reply!(default_config, NoReply.unsafe_assume_suppressed([]), { write_all!: |_| Err(MustNotWrite) }) == Ok({})

successful_no_reply! : {} => Bool
successful_no_reply! = |_| Execute.no_reply!(default_config, NoReply.unsafe_assume_suppressed([Command.ping({})]), { write_all!: |bytes| if bytes == ping_wire(1) Ok({}) else Err(WrongWire) }) == Ok({})

failed_no_reply! : {} => Bool
failed_no_reply! = |_| Execute.no_reply!(default_config, NoReply.unsafe_assume_suppressed([Command.ping({})]), { write_all!: |_| Err(InjectedWriteFailure) }) == Err(WriteFailed(InjectedWriteFailure))

rejected_no_reply! : {} => Bool
rejected_no_reply! = |_| {
	match Execute.no_reply!(one_command_config, NoReply.unsafe_assume_suppressed(List.repeat(Command.ping({}), 2)), { write_all!: |_| Err(WriteMustNotRun) }) {
		Err(RequestRejected(CommandLimitExceeded({ actual, limit }))) => actual == 2 and limit == 1
		_ => Bool.False
	}
}

integer_wire : U64 -> List(U8)
integer_wire = |count|
	Str.join_with(List.repeat(":1\r\n", count), "").to_utf8()

ping_wire : U64 -> List(U8)
ping_wire = |count|
	Str.join_with(List.repeat("*1\r\n$4\r\nPING\r\n", count), "").to_utf8()

semantic_wire : U64 -> List(U8)
semantic_wire = |failure_index| {
	var $frames = []
	var $index = 0.U64
	while $index <= failure_index {
		$frames = $frames.append(if $index == failure_index "+wrong\r\n" else ":1\r\n")
		$index = $index + 1
	}
	Str.join_with($frames, "").to_utf8()
}

byte_at : List(U8), U64 -> U8
byte_at = |bytes, index|
	match bytes.get(index) {
		Ok(byte) => byte
		Err(_) => 0
	}

fault_label : Fault -> Str
fault_label = |fault|
	match fault {
		ReadError => "read failure"
		EndOfFile => "EOF"
		EmptyRead => "empty read"
		OversizedRead => "oversized read"
		Malformed => "malformed byte"
		PartialThenEnd => "partial frame then EOF"
	}

widen_for_main : Try(a, [TransportPropertiesFailed(Str)]) -> Try(a, [TransportPropertiesFailed(Str), Exit(I32), ..])
widen_for_main = |result|
	match result {
		Ok(value) => Ok(value)
		Err(TransportPropertiesFailed(message)) => Err(TransportPropertiesFailed(message))
	}

expect integer_wire(2) == ":1\r\n:1\r\n".to_utf8()

expect ping_wire(2) == "*1\r\n$4\r\nPING\r\n*1\r\n$4\r\nPING\r\n".to_utf8()

expect semantic_wire(2) == ":1\r\n:1\r\n+wrong\r\n".to_utf8()

expect fault_label(PartialThenEnd) == "partial frame then EOF"

expect fault_read(integer_wire(1), 5, Malformed, 5) == Ok(Data([':']))

expect fault_read(integer_wire(1), 5, Malformed, 1) == Ok(Data(['?']))

expect fault_read(integer_wire(1), 6, PartialThenEnd, 2) == Ok(Data([':']))

expect fault_read(integer_wire(1), 6, PartialThenEnd, 1) == Ok(End)
