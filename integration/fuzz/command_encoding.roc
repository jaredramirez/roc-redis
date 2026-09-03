app [target] {
	fuzz: platform "https://github.com/lukewilliamboswell/roc-fuzz/releases/download/0.4.0-rc1/9k2cfuAWoBfcRBRiVbriXFf1dHktoRBbieifYN7NmTHc.tar.zst",
	roc: "nightly-2026-09-07-14d9829",
	redis: "../../package/main.roc",
}

import fuzz.Fuzz
import redis.Command
import redis.Resp
import RespOracle

raw_command_generator = Fuzz.map(
	{
		name: Fuzz.list(Fuzz.u8, 16),
		arguments: Fuzz.list(Fuzz.list(Fuzz.u8, 32), 6),
	}.Fuzz,
	|raw| { ..raw, name: if raw.name.is_empty() [0] else raw.name },
)

input_generator = Fuzz.list(raw_command_generator, 8)

test = |input| {
	var $commands = List.with_capacity(input.len())
	var $expected_wire = []
	var $expected_values = []
	for raw in input {
		command = match Command.from_bytes(raw.name, raw.arguments) {
			Ok(value) => value
			Err(_) => crash "generator produced an empty command name"
		}
		parts = [raw.name].concat(raw.arguments)
		expected = encode_parts(parts)
		if Command.to_parts(command) != parts or Command.encode(command) != expected {
			crash "command encoding differs from the independent serializer"
		}
		$commands = $commands.append(command)
		$expected_wire = $expected_wire.concat(expected)
		$expected_values = $expected_values.append(Resp.Array(parts.map(|part| Resp.BulkString(part))))
	}

	if Command.encode_pipeline($commands) != $expected_wire {
		crash "pipeline encoding differs from independently concatenated commands"
	}

	match Command.pipeline_size($commands, $expected_wire.len()) {
		Ok(size) if size == $expected_wire.len() => {}
		_ => crash "pipeline_size differs from the independent wire length"
	}

	match Command.encode_bounded($commands, $expected_wire.len()) {
		Ok(actual) if actual == $expected_wire => {}
		_ => crash "exact outbound budget rejected or changed a command pipeline"
	}

	if !$expected_wire.is_empty() {
		short = $expected_wire.len() - 1
		if Command.encode_bounded($commands, short) != Err(RequestByteLimitExceeded({ limit: short })) {
			crash "one-byte-short outbound budget accepted a command pipeline"
		}
	}

	if RespOracle.reference($expected_wire) != Complete($expected_values) {
		crash "independent command serializer did not produce the expected RESP arrays"
	}

	Fuzz.keep
}

target = Fuzz.target_with({
	name: "command-encoding",
	generator: input_generator,
	test,
	show: |input| Str.inspect(input),
})

encode_parts = |parts|
	"*${parts.len().to_str()}\r\n".to_utf8().concat(parts.join_map(encode_bulk))

encode_bulk = |bytes|
	"$${bytes.len().to_str()}\r\n".to_utf8().concat(bytes).concat(['\r', '\n'])
