## Decode-only diagnostic. No encoding workload runs before a timed sample.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "../package/main.roc",
}

import pf.Env
import pf.OsStr
import pf.Stdout
import pf.Utc
import redis.Decoder
import redis.Resp

Fixture : { wire : List(U8), values : List(Resp.Resp) }

Options : { kind : Str, size : U64, chunk : U64, width : U64, iterations : U64, seed : U64 }

Record : { schema : Str, compiler : Str, variant : Str, source : Str, kind : Str, payload_bytes : U64, chunk_bytes : U64, batch_width : U64, wire_bytes : U64, iterations : U64, seed : U64, sample : U64, warmup : U64, elapsed_ns : U128, validated : Bool }

main! = |args| {
	var $texts = []
	for arg in args.drop_first(1) {
		text = OsStr.to_str_try(arg) ? |_| DecodeBenchFailed("invalid UTF-8 argument")
		$texts = $texts.append(text)
	}
	options = parse_options($texts) ? |message| DecodeBenchFailed(message)
	variant = Env.var_str!(OsStr.from_str("ROC_REDIS_BUILD_MODE")) ? |_| DecodeBenchFailed("missing build mode")
	source = Env.var_str!(OsStr.from_str("ROC_REDIS_NIX_SOURCE_ID")) ? |_| DecodeBenchFailed("missing source identity")
	fixtures = [fixture(options, options.seed.to_u8_wrap()), fixture(options, 255 - options.seed.to_u8_wrap())]
	first = fixtures.get(0) ? |_| DecodeBenchFailed("missing fixture")
	chunk = if options.chunk == 0 first.wire.len() else options.chunk
	steps = first.wire.len() / chunk + (if first.wire.len() % chunk == 0 0 else 1)
	if first.wire.len() > 8 * 1024 * 1024 or steps > 4_000_000 / (options.iterations + 100) or first.wire.len() > 512_000_000 / (options.iterations + 100) {
		return Err(DecodeBenchFailed("case exceeds work budget; reduce size, width, iterations, or fragmentation"))
	}
	for sample in [1.U64, 2, 3, 4, 5, 6, 7, 8, 9, 10] {
		run(fixtures, chunk, 100) ? |message| DecodeBenchFailed(message)
		start = Utc.now!()
		run(fixtures, chunk, options.iterations) ? |message| DecodeBenchFailed(message)
		end = Utc.now!()
		if end <= start {
			return Err(DecodeBenchFailed("nonpositive clock interval"))
		}
		record : Record
		record = { schema: "roc-redis-decode/v1", compiler: "nightly-2026-09-07-14d9829", variant, source, kind: options.kind, payload_bytes: options.size, chunk_bytes: chunk, batch_width: options.width, wire_bytes: first.wire.len(), iterations: options.iterations, seed: options.seed, sample, warmup: 100, elapsed_ns: end - start, validated: True }
		Stdout.line!(Json.to_str(record))?
	}
	Ok({})
}

parse_options : List(Str) -> Try(Options, Str)
parse_options = |args| match args {
	[kind, size, chunk, width, iterations, seed] => {
		if !["bulk", "simple", "error", "integer", "array", "mixed", "null"].contains(kind) {
			return Err("unknown reply kind")
		}
		s = number(size, 0, 65_536)?
		c = number(chunk, 0, 8 * 1024 * 1024)?
		w = number(width, 1, 1000)?
		i = number(iterations, 1, 1_000_000)?
		r = number(seed, 0, 18_446_744_073_709_551_615)?
		# Bound construction too, before allocating the fixtures.
		if (s + 128) > (8 * 1024 * 1024) / w {
			return Err("fixture exceeds 8 MiB budget")
		}
		Ok({ kind, size: s, chunk: c, width: w, iterations: i, seed: r })
	}
	_ => Err("usage: decode KIND SIZE CHUNK WIDTH ITERATIONS SEED; CHUNK=0 means whole frame")
}

number : Str, U64, U64 -> Try(U64, Str)
number = |text, low, high| {
	if text.is_empty() or !text.to_utf8().all(|byte| byte >= '0' and byte <= '9') {
		return Err("expected decimal integer")
	}
	value = U64.from_str(text) ? |_| "integer overflow"
	if value < low or value > high Err("integer outside bounds") else Ok(value)
}

fixture : Options, U8 -> Fixture
fixture = |options, seed| {
	var $payload = List.with_capacity(options.size)
	var $index = 0.U64
	while $index < options.size {
		$payload = $payload.append(($index + seed.to_u64()).to_u8_wrap())
		$index = $index + 1
	}
	payload = $payload
	line = payload.map(|byte| if byte == '\r' or byte == '\n' 'x' else byte)
	integer = 10 + seed.to_u64() % 90
	bulk = "$${payload.len().to_str()}\r\n".to_utf8().concat(payload).concat(['\r', '\n'])
	(single_wire, value) = match options.kind {
		"bulk" => (bulk, Resp.BulkString(payload))
		"simple" => (['+'].concat(line).concat(['\r', '\n']), Resp.SimpleString(line))
		"error" => (['-'].concat(line).concat(['\r', '\n']), Resp.ErrorReply(line))
		"integer" => (":${integer.to_str()}\r\n".to_utf8(), Resp.Integer(integer.to_i64_wrap()))
		"null" => ("$-1\r\n".to_utf8(), Resp.NullBulkString)
		"array" => ("*2\r\n".to_utf8().concat(bulk).concat("*-1\r\n".to_utf8()), Resp.Array([Resp.BulkString(payload), Resp.NullArray]))
		_ => ("*4\r\n+OK\r\n:42\r\n".to_utf8().concat(bulk).concat("-ERR test\r\n".to_utf8()), Resp.Array([Resp.simple_utf8("OK"), Resp.Integer(42), Resp.BulkString(payload), Resp.ErrorReply("ERR test".to_utf8())]))
	}
	var $wire = List.with_capacity(single_wire.len() * options.width)
	for _index in List.repeat({}, options.width) {
		$wire = $wire.concat(single_wire)
	}
	{ wire: $wire, values: List.repeat(value, options.width) }
}

run : List(Fixture), U64, U64 -> Try({}, Str)
run = |fixtures, chunk, iterations| {
	var $iteration = 0.U64
	while $iteration < iterations {
		f = fixtures.get($iteration % 2) ? |_| "fixture index"
		var $decoder = Decoder.init({})
		var $values = List.with_capacity(f.values.len())
		var $offset = 0.U64
		while $offset < f.wire.len() {
			bytes = f.wire.sublist({ start: $offset, len: chunk })
			match Decoder.feed($decoder, bytes) {
				Progress({ decoder, values }) => {
					$decoder = decoder
					$values = $values.concat(values)
				}
				Failed(_) => return Err("decoder rejected fixture")
			}
			$offset = $offset + bytes.len()
		}
		if Decoder.finish($decoder).is_err() or $values != f.values {
			return Err("decoded values differ")
		}
		$iteration = $iteration + 1
	}
	Ok({})
}

expect number("0", 0, 1) == Ok(0)
expect ["", "-1", "+1", "1_0", "18446744073709551616"].all(|text| number(text, 0, 100).is_err())
expect parse_options(["bulk", "65536", "0", "1000", "1", "0"]).is_err()
expect {
	var $okay = True
	for kind in ["bulk", "simple", "error", "integer", "array", "mixed", "null"] {
		options = parse_options([kind, "32", "1", "3", "4", "255"])?
		f = fixture(options, 255)
		$okay = $okay and run([f, fixture(options, 0)], 1, 4).is_ok()
	}
	$okay
}
