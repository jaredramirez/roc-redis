## Server-free, one-case-per-process probes for allocation and retained-memory
## investigation. This program validates behavior but does not measure memory;
## run the compiled binary under an OS memory tool.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "../package/main.roc",
}

import pf.Env
import pf.OsStr
import pf.Stdout
import redis.Batch
import redis.Bytes
import redis.Command
import redis.Commands
import redis.Config
import redis.Decoder
import redis.Positive
import redis.Execute
import redis.NonEmpty
import redis.Reply
import redis.Request
import redis.Resp

Chunk : [ChunkBytes(U64), Whole]

Probe : [
	AdvertisedHeader(U64),
	ArrayProbe({ count : U64, chunk : Chunk }),
	BatchProbe({ count : U64, shape : [Deep, Flat] }),
	BulkProbe({ chunk : Chunk, size : U64 }),
	ErrorProbe({ count : U64, mode : [Compact, Held], size : U64 }),
	IdleProbe,
	LineProbe({ chunk : Chunk, kind : [ErrorLine, SimpleLine], size : U64 }),
	MgetProbe(U64),
	RepeatedExchange({ count : U64, size : U64 }),
]

Measurement : {
	schema : Str,
	case_name : Str,
	size : U64,
	chunk_size : U64,
	count : U64,
	checksum : U64,
	validated : Bool,
}

DeepBatchModel : {
	commands : List(Command.Command),
	decoder : List(Resp.Resp) -> Try(U64, [DeepFailure]),
}

Record : {
	schema : Str,
	case_name : Str,
	size : U64,
	chunk_size : U64,
	count : U64,
	checksum : U64,
	validated : Bool,
	compiler : Str,
	build_mode : Str,
	source : Str,
}

max_bulk_size : U64
max_bulk_size = 8 * 1024 * 1024

max_line_size : U64
max_line_size = 65_536

max_array_count : U64
max_array_count = 65_536

max_batch_count : U64
max_batch_count = 4096

max_repeat_count : U64
max_repeat_count = 100_000

max_repeat_bytes : U64
max_repeat_bytes = 512 * 1024 * 1024

max_held_bytes : U64
max_held_bytes = 128 * 1024 * 1024

usage : Str
usage = "usage: memory <idle|bulk SIZE CHUNK|line simple|error SIZE CHUNK|array COUNT CHUNK|mget COUNT|batch flat|deep COUNT|repeat COUNT SIZE|error held|compact SIZE COUNT|advertised-header SIZE>; CHUNK is whole or a positive byte count; recommended bulk sizes are 65536, 1048576, and 8388608 and chunks are whole, 16384, 31, and 1"

main! = |raw_args| {
	build_mode = Env.var_str!(OsStr.from_str("ROC_REDIS_BUILD_MODE")) ? |_| ProbeFailed("set ROC_REDIS_BUILD_MODE to the compiled backend")
	source = Env.var_str!(OsStr.from_str("ROC_REDIS_NIX_SOURCE_ID")) ? |_| ProbeFailed("set ROC_REDIS_NIX_SOURCE_ID to the source identity")
	args = os_args_to_str(raw_args.drop_first(1)) ? |message| ProbeFailed(message)
	probe = parse_probe(args) ? |message| ProbeFailed("${message}; ${usage}")
	measurement = run_probe!(probe) ? |ProbeFailed(message)| ProbeFailed(message)
	record : Record
	record = {
		schema: measurement.schema,
		case_name: measurement.case_name,
		size: measurement.size,
		chunk_size: measurement.chunk_size,
		count: measurement.count,
		checksum: measurement.checksum,
		validated: measurement.validated,
		compiler: "nightly-2026-09-07-14d9829",
		build_mode,
		source,
	}
	Stdout.line!(Json.to_str(record))?
	Ok({})
}

os_args_to_str : List(OsStr) -> Try(List(Str), Str)
os_args_to_str = |args| {
	var $values = List.with_capacity(args.len())
	for arg in args {
		value = OsStr.to_str_try(arg) ? |_| "command-line argument is not valid UTF-8"
		$values = $values.append(value)
	}
	Ok($values)
}

parse_probe : List(Str) -> Try(Probe, Str)
parse_probe = |args|
	match args {
		["idle"] => Ok(IdleProbe)
		["bulk", size, chunk] => {
			parsed_size = parse_bounded("bulk size", size, 1, max_bulk_size)?
			Ok(BulkProbe({ size: parsed_size, chunk: parse_chunk(chunk)? }))
		}
		["line", kind, size, chunk] => {
			line_kind = match kind {
				"simple" => Ok(SimpleLine)
				"error" => Ok(ErrorLine)
				_ => Err("line kind must be simple or error")
			}?
			parsed_size = parse_bounded("line size", size, 1, max_line_size)?
			Ok(LineProbe({ kind: line_kind, size: parsed_size, chunk: parse_chunk(chunk)? }))
		}
		["array", count, chunk] => {
			parsed_count = parse_bounded("array count", count, 1, max_array_count)?
			Ok(ArrayProbe({ count: parsed_count, chunk: parse_chunk(chunk)? }))
		}
		["mget", count] => Ok(MgetProbe(parse_bounded("MGET count", count, 1, max_array_count)?))
		["batch", shape, count] => {
			batch_shape = match shape {
				"flat" => Ok(Flat)
				"deep" => Ok(Deep)
				_ => Err("batch shape must be flat or deep")
			}?
			Ok(BatchProbe({ shape: batch_shape, count: parse_bounded("batch count", count, 1, max_batch_count)? }))
		}
		["repeat", count, size] => {
			parsed_count = parse_bounded("repeat count", count, 1, max_repeat_count)?
			parsed_size = parse_bounded("repeat bulk size", size, 1, max_bulk_size)?
			{} = require_product("repeat work", parsed_count, parsed_size, max_repeat_bytes)?
			Ok(RepeatedExchange({ count: parsed_count, size: parsed_size }))
		}
		["error", mode, size, count] => {
			error_mode = match mode {
				"held" => Ok(Held)
				"compact" => Ok(Compact)
				_ => Err("error mode must be held or compact")
			}?
			parsed_size = parse_bounded("error payload size", size, 1, max_bulk_size)?
			parsed_count = parse_bounded("error count", count, 1, max_repeat_count)?
			{} = require_product("held-error work", parsed_count, parsed_size, max_held_bytes)?
			Ok(ErrorProbe({ mode: error_mode, size: parsed_size, count: parsed_count }))
		}
		["advertised-header", size] => Ok(AdvertisedHeader(parse_u64("advertised size", size)?))
		_ => Err(usage)
	}

parse_chunk : Str -> Try(Chunk, Str)
parse_chunk = |text|
	if text == "whole" {
		Ok(Whole)
	} else {
		Ok(ChunkBytes(parse_bounded("chunk size", text, 1, max_bulk_size + 32)?))
	}

parse_bounded : Str, Str, U64, U64 -> Try(U64, Str)
parse_bounded = |name, text, minimum, maximum| {
	value = parse_u64(name, text)?
	if value < minimum or value > maximum {
		Err("${name} must be ${minimum.to_str()}..${maximum.to_str()}")
	} else {
		Ok(value)
	}
}

parse_u64 : Str, Str -> Try(U64, Str)
parse_u64 = |name, text| {
	if text.is_empty() or !text.to_utf8().all(|byte| byte >= '0' and byte <= '9') {
		return Err("${name} must be an unsigned decimal integer")
	}
	U64.from_str(text).map_err(|_| "${name} overflows U64")
}

require_product : Str, U64, U64, U64 -> Try({}, Str)
require_product = |name, left, right, limit|
	if left > limit / right {
		Err("${name} must not exceed ${limit.to_str()} bytes")
	} else {
		Ok({})
	}

run_probe! : Probe => Try(Measurement, [ProbeFailed(Str)])
run_probe! = |probe|
	match probe {
		IdleProbe => Ok(record("idle", 0, 0, 0, 0))
		BulkProbe(settings) => run_bulk(settings)
		LineProbe(settings) => run_line(settings)
		ArrayProbe(settings) => run_array(settings)
		MgetProbe(count) => run_mget(count)
		BatchProbe(settings) => run_batch(settings)
		RepeatedExchange(settings) => run_repeated_exchange!(settings)
		ErrorProbe(settings) => run_errors(settings)
		AdvertisedHeader(size) => run_advertised_header(size)
	}

run_bulk : { chunk : Chunk, size : U64 } -> Try(Measurement, [ProbeFailed(Str)])
run_bulk = |{ size, chunk }| {
	payload = make_payload(size, 17)
	wire = "$${size.to_str()}\r\n".to_utf8().concat(payload).append('\r').append('\n')
	chunk_size = resolved_chunk(chunk, wire.len())
	values = decode_fragmented(wire, chunk_size)?
	match values {
		[Resp.BulkString(decoded)] if decoded == payload => Ok(record("bulk", size, chunk_size, 1, checksum(decoded)))
		_ => Err(ProbeFailed("bulk decoder returned the wrong value"))
	}
}

run_line : { chunk : Chunk, kind : [ErrorLine, SimpleLine], size : U64 } -> Try(Measurement, [ProbeFailed(Str)])
run_line = |{ kind, size, chunk }| {
	payload = make_line_payload(size)
	prefix = match kind {
		SimpleLine => '+'
		ErrorLine => '-'
	}
	wire = [prefix].concat(payload).append('\r').append('\n')
	chunk_size = resolved_chunk(chunk, wire.len())
	values = decode_fragmented(wire, chunk_size)?
	valid = match (kind, values) {
		(SimpleLine, [Resp.SimpleString(decoded)]) => decoded == payload
		(ErrorLine, [Resp.ErrorReply(decoded)]) => decoded == payload
		_ => False
	}
	if valid {
		Ok(record(if kind == SimpleLine "line-simple" else "line-error", size, chunk_size, 1, checksum(payload)))
	} else {
		Err(ProbeFailed("line decoder returned the wrong value"))
	}
}

run_array : { chunk : Chunk, count : U64 } -> Try(Measurement, [ProbeFailed(Str)])
run_array = |{ count, chunk }| {
	header = "*${count.to_str()}\r\n".to_utf8()
	var $wire = List.with_capacity(header.len() + count * 4)
	$wire = $wire.concat(header)
	var $index = 0.U64
	while $index < count {
		$wire = $wire.append('+').append('x').append('\r').append('\n')
		$index = $index + 1
	}
	chunk_size = resolved_chunk(chunk, $wire.len())
	values = decode_fragmented($wire, chunk_size)?
	match values {
		[Resp.Array(items)] if items.len() == count and items.all(|item| item == Resp.SimpleString(['x'])) => Ok(record("array", $wire.len(), chunk_size, count, count))
		_ => Err(ProbeFailed("array decoder returned the wrong value"))
	}
}

run_mget : U64 -> Try(Measurement, [ProbeFailed(Str)])
run_mget = |count| {
	key = Bytes.from_str("k")
	request = Commands.Strings.mget(NonEmpty.new(key, List.repeat(key, count - 1)))
	var $responses = List.with_capacity(count)
	var $index = 0.U64
	while $index < count {
		response = if $index % 2 == 0 {
			Resp.BulkString([($index % 256).to_u8_wrap()])
		} else {
			Resp.NullBulkString
		}
		$responses = $responses.append(response)
		$index = $index + 1
	}
	decoded = request.decode(Resp.Array($responses)) ? |_| ProbeFailed("MGET semantic decoding failed")
	if decoded.len() != count {
		return Err(ProbeFailed("MGET semantic decoding returned the wrong count"))
	}
	var $present = 0.U64
	for value in decoded {
		match value {
			Present(bytes) => {
				if bytes.len() != 1 {
					return Err(ProbeFailed("MGET returned a malformed present value"))
				}
				$present = $present + 1
			}
			Absent => {}
		}
	}
	Ok(record("mget", count, 0, count, $present))
}

run_batch : { count : U64, shape : [Deep, Flat] } -> Try(Measurement, [ProbeFailed(Str)])
run_batch = |{ count, shape }| {
	responses = List.repeat(Resp.Integer(1), count)
	if shape == Flat {
		request = Request.new(Command.ping({}), Reply.integer)
		plan = Batch.all(List.repeat(request, count))
		decoded = plan.decode(responses) ? |_| ProbeFailed("flat batch decoding failed")
		if decoded.len() == count and decoded.all(|value| value == 1) {
			Ok(record("batch-flat", count, 0, count, decoded.len()))
		} else {
			Err(ProbeFailed("flat batch returned the wrong values"))
		}
	} else {
		plan = make_deep_batch(count)
		decoded = plan.decode(responses) ? |_| ProbeFailed("deep batch decoding failed")
		if decoded == count {
			Ok(record("batch-deep-extracted-model", count, 0, count, decoded))
		} else {
			Err(ProbeFailed("deep batch returned the wrong value"))
		}
	}
}

## Model left-deep Batch.map2 composition while keeping a stable error type.
## Extracting each child decoder before closing over it mirrors Batch.map2 and
## avoids retaining the child record and every intermediate command list. Wrap
## the completed model with Batch.new once at the public boundary.
make_deep_batch : U64 -> Batch.Batch(U64, [DeepFailure])
make_deep_batch = |count| {
	model = make_deep_batch_model(count)
	decoder = model.decoder
	Batch.new(model.commands, decoder)
}

make_deep_batch_model : U64 -> DeepBatchModel
make_deep_batch_model = |count| {
	leaf : DeepBatchModel
	leaf = {
		commands: [Command.ping({})],
		decoder: |responses| if responses == [Resp.Integer(1)] Ok(1) else Err(DeepFailure),
	}
	if count <= 1 {
		leaf
	} else {
		left = make_deep_batch_model(count - 1)
		left_decoder = left.decoder
		right_decoder = leaf.decoder
		left_count = count - 1
		{
			commands: left.commands.concat(leaf.commands),
			decoder: |responses| {
				left_value = left_decoder(responses.take_first(left_count))?
				right_value = right_decoder(responses.drop_first(left_count))?
				Ok(left_value + right_value)
			},
		}
	}
}

run_repeated_exchange! : { count : U64, size : U64 } => Try(Measurement, [ProbeFailed(Str)])
run_repeated_exchange! = |{ count, size }| {
	payload = make_payload(size, 29)
	wire = "$${size.to_str()}\r\n".to_utf8().concat(payload).append('\r').append('\n')
	read_budget = Positive.from_u64(wire.len()) ? |_| ProbeFailed("repeated-exchange wire must be non-empty")
	config = Config.{ read_size: read_budget, max_response_bytes: read_budget }
	request = Request.new(Command.ping({}), Reply.bulk)
	expected_write = Command.encode(Command.ping({}))
	var $checksum = 0.U64
	var $iteration = 0.U64
	while $iteration < count {
		transport = {
			read!: |max_bytes| if wire.len() <= max_bytes {
				Ok(Data(wire))
			} else {
				Err(ReadTooSmall)
			},
			write_all!: |bytes| if bytes == expected_write {
				Ok({})
			} else {
				Err(WrongWrite)
			},
		}
		decoded = Execute.request!(config, request, transport) ? |_| ProbeFailed("repeated exchange failed")
		if decoded != payload {
			return Err(ProbeFailed("repeated exchange returned the wrong payload"))
		}
		$checksum = $checksum + decoded.len()
		$iteration = $iteration + 1
	}
	Ok(record("repeat-exchange", size, wire.len(), count, $checksum))
}

run_errors : { count : U64, mode : [Compact, Held], size : U64 } -> Try(Measurement, [ProbeFailed(Str)])
run_errors = |{ count, mode, size }| {
	if mode == Held {
		var $held = List.with_capacity(count)
		var $index = 0.U64
		while $index < count {
			payload = make_payload(size, $index.to_u8_wrap())
			match Reply.integer(Resp.BulkString(payload)) {
				Err(error) => {
					$held = $held.append(error)
				}
				Ok(_) => return Err(ProbeFailed("held-error fixture unexpectedly decoded"))
			}
			$index = $index + 1
		}
		retained_bytes = error_payload_bytes($held)?
		Ok(record("error-held", size, 0, count, retained_bytes))
	} else {
		var $checksum = 0.U64
		var $index = 0.U64
		while $index < count {
			payload = make_payload(size, $index.to_u8_wrap())
			match Reply.integer(Resp.BulkString(payload)) {
				Err(UnexpectedReply({ actual: Resp.BulkString(bytes), expected: IntegerReply })) => {
					$checksum = $checksum + bytes.len()
				}
				Err(_) => return Err(ProbeFailed("compact-error fixture returned a different error"))
				Ok(_) => return Err(ProbeFailed("compact-error fixture unexpectedly decoded"))
			}
			$index = $index + 1
		}
		Ok(record("error-compact", size, 0, count, $checksum))
	}
}

error_payload_bytes : List(Reply.Error) -> Try(U64, [ProbeFailed(Str)])
error_payload_bytes = |errors| {
	var $total = 0.U64
	for error in errors {
		match error {
			UnexpectedReply({ actual: Resp.BulkString(bytes), expected: IntegerReply }) => {
				$total = $total + bytes.len()
			}
			_ => return Err(ProbeFailed("held-error fixture retained a different error"))
		}
	}
	Ok($total)
}

run_advertised_header : U64 -> Try(Measurement, [ProbeFailed(Str)])
run_advertised_header = |size| {
	wire = "$${size.to_str()}\r\n".to_utf8()
	result = Decoder.feed(Decoder.init({}), wire)
	if size <= Decoder.default_limits.max_bulk_length {
		match result {
			Progress({ decoder, values: [] }) if Decoder.buffered_len(decoder) == wire.len() => Ok(record("advertised-header-accepted", size, wire.len(), 1, Decoder.buffered_len(decoder)))
			_ => Err(ProbeFailed("accepted advertised header produced the wrong decoder state"))
		}
	} else {
		match result {
			Failed({ completed: [], error: BulkLengthLimitExceeded({ actual, limit, .. }) }) if actual == size and limit == Decoder.default_limits.max_bulk_length => Ok(record("advertised-header-rejected", size, wire.len(), 1, wire.len()))
			_ => Err(ProbeFailed("oversized advertised header produced the wrong failure"))
		}
	}
}

decode_fragmented : List(U8), U64 -> Try(List(Resp.Resp), [ProbeFailed(Str)])
decode_fragmented = |wire, chunk_size| {
	var $decoder = Decoder.init({})
	var $values = []
	var $offset = 0.U64
	while $offset < wire.len() {
		amount = (wire.len() - $offset).min(chunk_size)
		match Decoder.feed($decoder, wire.sublist({ start: $offset, len: amount })) {
			Progress({ decoder, values }) => {
				$decoder = decoder
				$values = $values.concat(values)
			}
			Failed(_) => return Err(ProbeFailed("fragmented decoder failed"))
		}
		$offset = $offset + amount
	}
	Decoder.finish($decoder).map_err(|_| ProbeFailed("fragmented decoder did not finish between frames"))?
	Ok($values)
}

resolved_chunk : Chunk, U64 -> U64
resolved_chunk = |chunk, wire_length|
	match chunk {
		Whole => wire_length
		ChunkBytes(size) => size.min(wire_length)
	}

make_payload : U64, U8 -> List(U8)
make_payload = |size, seed| {
	var $bytes = List.with_capacity(size)
	var $index = 0.U64
	while $index < size {
		$bytes = $bytes.append((($index * 31 + seed.to_u64()) % 256).to_u8_wrap())
		$index = $index + 1
	}
	$bytes
}

make_line_payload : U64 -> List(U8)
make_line_payload = |size| {
	var $bytes = List.with_capacity(size)
	var $index = 0.U64
	while $index < size {
		$bytes = $bytes.append(('a' + ($index % 26).to_u8_wrap()))
		$index = $index + 1
	}
	$bytes
}

checksum : List(U8) -> U64
checksum = |bytes| {
	var $total = 0.U64
	for byte in bytes {
		$total = $total + byte.to_u64()
	}
	$total
}

record : Str, U64, U64, U64, U64 -> Measurement
record = |case_name, size, chunk_size, count, checksum_value| {
	schema: "roc-redis-memory/v1",
	case_name,
	size,
	chunk_size,
	count,
	checksum: checksum_value,
	validated: True,
}

expect parse_probe(["bulk", "65536", "whole"]) == Ok(BulkProbe({ size: 65_536, chunk: Whole }))
expect parse_probe(["idle"]) == Ok(IdleProbe)
expect parse_probe(["repeat", "10", "32"]) == Ok(RepeatedExchange({ count: 10, size: 32 }))
expect parse_probe(["repeat", "100000", "8388608"]).is_err()
expect parse_probe(["error", "held", "8388608", "17"]).is_err()
expect parse_probe(["advertised-header", "18446744073709551615"]) == Ok(AdvertisedHeader(18_446_744_073_709_551_615))
expect run_bulk({ size: 32, chunk: ChunkBytes(1) }).is_ok()
expect run_line({ kind: ErrorLine, size: 32, chunk: ChunkBytes(3) }).is_ok()
expect run_array({ count: 8, chunk: ChunkBytes(5) }).is_ok()
expect run_mget(8).is_ok()
expect run_batch({ shape: Flat, count: 8 }).is_ok()
expect run_batch({ shape: Deep, count: 8 }).is_ok()
expect {
	batch = make_deep_batch(3)
	valid = batch.decode([Resp.Integer(1), Resp.Integer(1), Resp.Integer(1)])
	wrong_count = batch.decode([Resp.Integer(1), Resp.Integer(1)])
	wrong_value = batch.decode([Resp.Integer(1), Resp.Integer(2), Resp.Integer(1)])
	valid == Ok(3)
		and wrong_count == Err(ReplyCountMismatch({ expected: 3, actual: 2 }))
			and wrong_value == Err(BatchDecodeFailure(DeepFailure))
}
expect run_errors({ mode: Held, size: 32, count: 3 }).is_ok()
expect run_errors({ mode: Compact, size: 32, count: 3 }).is_ok()
expect run_advertised_header(8 * 1024 * 1024).is_ok()
