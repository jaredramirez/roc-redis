app [target] {
	fuzz: platform "https://github.com/lukewilliamboswell/roc-fuzz/releases/download/0.4.0-rc1/9k2cfuAWoBfcRBRiVbriXFf1dHktoRBbieifYN7NmTHc.tar.zst",
	roc: "nightly-2026-09-07-14d9829",
	redis: "../../package/main.roc",
}

import fuzz.Fuzz
import redis.Resp
import RespOracle

input_generator = Fuzz.map2(
	Fuzz.list(Fuzz.u8, 96),
	Fuzz.list(Fuzz.u8, 32),
	|recipe, chunks| {
		generated = value_from(recipe, 0, 0)
		{ value: generated.value, chunks }
	},
)

test = |input| {
	wire = RespOracle.encode(input.value)
	expected = Decoded([input.value])
	whole = RespOracle.observe(wire)
	fragmented = RespOracle.observe_chunks(wire, input.chunks)
	single = RespOracle.observe_single_bytes(wire)
	reference = RespOracle.reference(wire)

	if whole != expected {
		crash "generated RESP2 value did not round trip"
	} else if fragmented != whole {
		crash "generated RESP2 value changed under arbitrary chunking"
	} else if single != whole {
		crash "generated RESP2 value changed under single-byte chunking"
	} else if reference != Complete([input.value]) {
		crash "reference parser rejected its own serialized RESP2 value"
	} else {
		Fuzz.keep
	}
}

target = Fuzz.target_with({
	name: "resp2-round-trip",
	generator: input_generator,
	test,
	show: |input| Str.inspect(input),
})

value_from = |recipe, index, depth| {
	selector = byte_at(recipe, index) % 7
	if selector == 0 and depth < 5 {
		count = (byte_at(recipe, index + 1) % 4).to_u64()
		array_from(recipe, index + 2, depth + 1, count, [])
	} else if selector == 1 {
		generated = bytes_from(recipe, index + 1, True)
		{ value: Resp.BulkString(generated.bytes), next: generated.next }
	} else if selector == 2 {
		generated = bytes_from(recipe, index + 1, False)
		{ value: Resp.SimpleString(generated.bytes), next: generated.next }
	} else if selector == 3 {
		generated = bytes_from(recipe, index + 1, False)
		{ value: Resp.ErrorReply(generated.bytes), next: generated.next }
	} else if selector == 4 {
		{ value: Resp.Integer(integer_from(byte_at(recipe, index + 1))), next: index + 2 }
	} else if selector == 5 {
		{ value: Resp.NullBulkString, next: index + 1 }
	} else {
		{ value: Resp.NullArray, next: index + 1 }
	}
}

array_from = |recipe, index, depth, remaining, values|
	if remaining == 0 {
		{ value: Resp.Array(values), next: index }
	} else {
		generated = value_from(recipe, index, depth)
		array_from(recipe, generated.next, depth, remaining - 1, values.append(generated.value))
	}

bytes_from = |recipe, index, binary| {
	length = (byte_at(recipe, index) % 13).to_u64()
	var $bytes = List.with_capacity(length)
	var $offset = 0.U64
	while $offset < length {
		byte = byte_at(recipe, index + 1 + $offset)
		clean = if binary or (byte != '\r' and byte != '\n') byte else 0
		$bytes = $bytes.append(clean)
		$offset = $offset + 1
	}
	{ bytes: $bytes, next: index + 1 + length }
}

byte_at = |bytes, index| bytes.get(index) ?? 0

integer_from = |selector| match selector % 9 {
	0 => 0
	1 => 1
	2 => -1
	3 => 127
	4 => -128
	5 => 2147483647
	6 => -2147483648
	7 => I64.highest
	_ => I64.lowest
}
