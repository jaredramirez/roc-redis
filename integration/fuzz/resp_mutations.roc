app [target] {
	fuzz: platform "https://github.com/lukewilliamboswell/roc-fuzz/releases/download/0.4.0-rc1/9k2cfuAWoBfcRBRiVbriXFf1dHktoRBbieifYN7NmTHc.tar.zst",
	roc: "nightly-2026-09-07-14d9829",
	redis: "../../package/main.roc",
}

import fuzz.Fuzz
import RespOracle

input_generator = {
	kind: Fuzz.u8_in(0, 15),
	payload: Fuzz.list(Fuzz.u8, 64),
	position: Fuzz.u8,
	replacement: Fuzz.u8,
	chunks: Fuzz.list(Fuzz.u8, 32),
}.Fuzz

test = |input| {
	wire = mutated_wire(input)
	reference = RespOracle.reference(wire)
	whole = RespOracle.observe(wire)
	fragmented = RespOracle.observe_chunks(wire, input.chunks)
	single = RespOracle.observe_single_bytes(wire)

	if fragmented != whole or single != whole {
		crash "structured RESP2 mutation changed its exact failure under chunking"
	} else if !RespOracle.agrees(reference, whole) {
		crash "structured RESP2 mutation differs from the independent reference grammar"
	} else {
		Fuzz.keep
	}
}

target = Fuzz.target_with({
	name: "resp2-mutations",
	generator: input_generator,
	test,
	show: |input| Str.inspect({ input, wire: mutated_wire(input) }),
})

mutated_wire = |input| {
	clean = input.payload.map(|byte| if byte == '\r' or byte == '\n' 0 else byte)
	bulk = "$${input.payload.len().to_str()}\r\n".to_utf8().concat(input.payload).concat(['\r', '\n'])
	position = input.position.to_u64() % (bulk.len() + 1)
	match input.kind {
		0 => bulk.take_first(position)
		1 => replace_at(bulk, input.position.to_u64() % bulk.len(), input.replacement)
		2 => ['+'].concat(clean).concat(['\n'])
		3 => ['+'].concat(clean).concat(['\r', 'X'])
		4 => ":1_0\r\n".to_utf8()
		5 => ":9223372036854775808\r\n".to_utf8()
		6 => "$-01\r\n".to_utf8()
		7 => "*-01\r\n".to_utf8()
		8 => "$18446744073709551616\r\n".to_utf8()
		9 => "$2\r\nokX".to_utf8()
		10 => "$0\r\n\rX".to_utf8()
		11 => "*2\r\n+OK\r\n?".to_utf8()
		12 => "+FIRST\r\n$3\r\nab".to_utf8()
		13 => "+FIRST\r\n$2\r\nokX".to_utf8()
		14 => "*2\r\n$-1\r\n*-1\r\n".to_utf8()
		_ => "+FIRST\r\n".to_utf8().concat(bulk)
	}
}

replace_at = |bytes, index, replacement|
	bytes.take_first(index).append(replacement).concat(bytes.drop_first(index + 1))
