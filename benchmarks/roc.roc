## Validated roc-redis subject for the cross-client benchmark.
##
## Compile this program before collecting measurements. Its internal timer
## excludes compilation, process startup, connection setup, warmup, and cleanup.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "../package/main.roc",
}

import pf.OsStr
import pf.Random
import pf.Stdout
import pf.Tcp
import pf.Utc
import redis.Batch
import redis.Config as RedisConfig
import redis.Execute
import redis.Reply
import redis.Request
import redis.Command
import redis.Keyspace as RawKeyspace
import redis.Resp
import redis.Strings as RawStrings

Config : {
	host : Str,
	port : U16,
	iterations : U64,
	warmup : U64,
	samples : U64,
	pipeline_batch : U64,
	timeout_ms : U64,
	key_prefix : Str,
	redis_version : Str,
	nix_source_id : Str,
	build_mode : Str,
	nix_system : Str,
	os : Str,
	arch : Str,
	order_rotation : U64,
	subject_position : U64,
}

client_version : Str
client_version = "0.1.0-dev"

max_iterations : U64
max_iterations = 1_000_000_000

max_samples : U64
max_samples = 1_000

max_pipeline_batch : U64
max_pipeline_batch = 65_536

max_timeout_ms : U64
max_timeout_ms = 300_000

key_ttl_ms : List(U8)
key_ttl_ms = Str.to_utf8("86400001")

binary_payload : List(U8)
binary_payload = [
	0,
	13,
	10,
	255,
	128,
	82,
	111,
	99,
	45,
	82,
	101,
	100,
	105,
	115,
	0,
	1,
	2,
	3,
	10,
	13,
	127,
	128,
	254,
	255,
	65,
	66,
	67,
	120,
	121,
	122,
	0,
	255,
]

usage : Str
usage = "usage: roc-benchmark [--host HOST] [--port PORT] [--iterations N] [--warmup N] [--samples N] [--pipeline-batch N] [--timeout-ms N] [--key-prefix PREFIX] [--nix-source-id ID] [--build-mode MODE] [--nix-system SYSTEM] [--os OS] [--arch ARCH] [--order-rotation 0..9] [--subject-position 0..5]"

default_config : Config
default_config = {
	host: "127.0.0.1",
	port: 6_379,
	iterations: 10_000,
	warmup: 1_000,
	samples: 5,
	pipeline_batch: 100,
	timeout_ms: 5_000,
	key_prefix: "",
	redis_version: "",
	nix_source_id: "unmanaged",
	build_mode: "unmanaged",
	nix_system: "unmanaged",
	os: "unmanaged",
	arch: "unmanaged",
	order_rotation: 0,
	subject_position: 0,
}

main! : List(OsStr) => Try({}, [BenchmarkFailed(Str), Exit(I32), ..])
main! = |raw_args| {
	args = os_args_to_str(raw_args.drop_first(1)).map_err(|message| BenchmarkFailed(message))?
	if args.contains("--help") or args.contains("-h") {
		Stdout.line!(usage) ? |error| BenchmarkFailed("write help: ${Str.inspect(error)}")
	} else {
		parsed = parse_options(args, default_config) ? |message| BenchmarkFailed("${message}; ${usage}")
		config = widen_for_main(ensure_key_prefix!(parsed))?
		widen_for_main(run_with_cleanup!(config))?
	}
	Ok({})
}

widen_for_main : Try(value, [BenchmarkFailed(Str)]) -> Try(value, [BenchmarkFailed(Str), Exit(I32), ..])
widen_for_main = |result|
	match result {
		Ok(value) => Ok(value)
		Err(BenchmarkFailed(message)) => Err(BenchmarkFailed(message))
	}

os_args_to_str : List(OsStr) -> Try(List(Str), Str)
os_args_to_str = |args|
	match args {
		[] => Ok([])
		[first, .. as rest] => {
			text = OsStr.to_str_try(first) ? |_| "command-line argument is not valid UTF-8"
			remaining = os_args_to_str(rest)?
			Ok(remaining.prepend(text))
		}
	}

parse_options : List(Str), Config -> Try(Config, Str)
parse_options = |args, config|
	match args {
		[] => validate_config(config)
		["--host", value, .. as rest] => parse_options(rest, { ..config, host: value })
		["--port", value, .. as rest] => {
			port = parse_port(value)?
			parse_options(rest, { ..config, port })
		}
		["--iterations", value, .. as rest] => {
			iterations = parse_bounded("iterations", value, 1, max_iterations)?
			parse_options(rest, { ..config, iterations })
		}
		["--warmup", value, .. as rest] => {
			warmup = parse_bounded("warmup", value, 0, max_iterations)?
			parse_options(rest, { ..config, warmup })
		}
		["--samples", value, .. as rest] => {
			samples = parse_bounded("samples", value, 1, max_samples)?
			parse_options(rest, { ..config, samples })
		}
		["--pipeline-batch", value, .. as rest] => {
			pipeline_batch = parse_bounded("pipeline-batch", value, 1, max_pipeline_batch)?
			parse_options(rest, { ..config, pipeline_batch })
		}
		["--timeout-ms", value, .. as rest] => {
			timeout_ms = parse_bounded("timeout-ms", value, 1, max_timeout_ms)?
			parse_options(rest, { ..config, timeout_ms })
		}
		["--key-prefix", value, .. as rest] => parse_options(rest, { ..config, key_prefix: value })
		["--nix-source-id", value, .. as rest] => parse_options(rest, { ..config, nix_source_id: value })
		["--build-mode", value, .. as rest] => parse_options(rest, { ..config, build_mode: value })
		["--nix-system", value, .. as rest] => parse_options(rest, { ..config, nix_system: value })
		["--os", value, .. as rest] => parse_options(rest, { ..config, os: value })
		["--arch", value, .. as rest] => parse_options(rest, { ..config, arch: value })
		["--order-rotation", value, .. as rest] => {
			order_rotation = parse_bounded("order-rotation", value, 0, 9)?
			parse_options(rest, { ..config, order_rotation })
		}
		["--subject-position", value, .. as rest] => {
			subject_position = parse_bounded("subject-position", value, 0, 5)?
			parse_options(rest, { ..config, subject_position })
		}
		[option, ..] => Err("unknown or incomplete option ${Str.inspect(option)}")
	}

parse_port : Str -> Try(U16, Str)
parse_port = |text| {
	{} = require_decimal("port", text)?
	value = U16.from_str(text) ? |_| "port must be from 1 through 65535"
	if value == 0 {
		Err("port must be from 1 through 65535")
	} else {
		Ok(value)
	}
}

parse_bounded : Str, Str, U64, U64 -> Try(U64, Str)
parse_bounded = |name, text, minimum, maximum| {
	{} = require_decimal(name, text)?
	value = U64.from_str(text) ? |_| "${name} must be from ${minimum.to_str()} through ${maximum.to_str()}"
	if value < minimum or value > maximum {
		Err("${name} must be from ${minimum.to_str()} through ${maximum.to_str()}")
	} else {
		Ok(value)
	}
}

require_decimal : Str, Str -> Try({}, Str)
require_decimal = |name, text| {
	bytes = text.to_utf8()
	if bytes.is_empty() or !(bytes.all(|byte| byte >= 48 and byte <= 57)) {
		Err("${name} must be a decimal integer")
	} else {
		Ok({})
	}
}

validate_config : Config -> Try(Config, Str)
validate_config = |config|
	if !(is_safe_host(config.host)) {
		Err("host must contain 1 through 253 printable non-space ASCII characters")
	} else if config.key_prefix != "" and !(is_safe_prefix(config.key_prefix)) {
		Err("key-prefix must contain 1 through 128 ASCII letters, digits, '.', '_', ':', or '-'")
	} else if !([config.nix_source_id, config.build_mode, config.nix_system, config.os, config.arch].all(is_safe_metadata)) {
		Err("benchmark metadata must contain 1 through 128 safe ASCII characters")
	} else {
		Ok(config)
	}

is_safe_host : Str -> Bool
is_safe_host = |value| {
	bytes = value.to_utf8()
	bytes.len() >= 1 and bytes.len() <= 253 and bytes.all(|byte| byte >= 33 and byte <= 126)
}

is_safe_prefix : Str -> Bool
is_safe_prefix = |value| {
	bytes = value.to_utf8()
	bytes.len() >= 1 and bytes.len() <= 128 and bytes.all(is_safe_prefix_byte)
}

is_safe_prefix_byte : U8 -> Bool
is_safe_prefix_byte = |byte|
	(byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) or (byte >= 48 and byte <= 57) or byte == 46 or byte == 95 or byte == 58 or byte == 45

is_safe_metadata : Str -> Bool
is_safe_metadata = |value| {
	bytes = value.to_utf8()
	bytes.len() >= 1 and bytes.len() <= 128 and bytes.all(|byte| is_safe_prefix_byte(byte) or byte == 43)
}

ensure_key_prefix! : Config => Try(Config, [BenchmarkFailed(Str)])
ensure_key_prefix! = |config|
	if config.key_prefix == "" {
		seed = Random.seed_u64!() ? |error| BenchmarkFailed("generate key prefix: ${Str.inspect(error)}")
		Ok({ ..config, key_prefix: "roc-redis-bench:roc:${seed.to_str()}" })
	} else {
		Ok(config)
	}

execution_config = RedisConfig.default |> RedisConfig.with_max_commands(65_536) |> RedisConfig.build

raw_request! : Command.Command, Execute.Transport(read_err, write_err) => Try(Resp.Resp, [BenchmarkFailed(Str)])
raw_request! = |command, transport|
	Execute.request!(execution_config, Request.new(command, Reply.raw), transport)
		.map_err(|error| BenchmarkFailed(Str.inspect(error)))

run_with_cleanup! : Config => Try({}, [BenchmarkFailed(Str)])
run_with_cleanup! = |config| {
	marker_key = "${config.key_prefix}:lease".to_utf8()
	set_key = "${config.key_prefix}:set-get".to_utf8()
	incr_key = "${config.key_prefix}:incr".to_utf8()
	stream = Tcp.connect!(config.host, config.port, config.timeout_ms)
		? |error| BenchmarkFailed("connect: ${Str.inspect(error)}")
	transport : Execute.Transport(_, _)
	transport = {
		read!: |max_bytes|
			stream.read_up_to!(max_bytes, config.timeout_ms)
				.map_ok(|bytes| if bytes.is_empty() End else Data(bytes)),
		write_all!: |bytes| stream.write!(bytes, config.timeout_ms),
	}
	info_command = Command.from_utf8("INFO", ["server"])
		? |_| BenchmarkFailed("construct INFO server command")
	info_result = raw_request!(info_command, transport)
		? |error| BenchmarkFailed("read Redis version: ${Str.inspect(error)}")
	redis_version = redis_version_from_response(info_result)?
	runtime_config = { ..config, redis_version }

	lease_result = raw_request!(
		RawStrings.set(marker_key, Str.to_utf8("benchmark-lease"), [Str.to_utf8("PX"), key_ttl_ms, Str.to_utf8("NX")]),
		transport,
	) ? |error| BenchmarkFailed("acquire key-prefix lease: ${Str.inspect(error)}")
	match lease_result {
		Resp.NullBulkString => Err(BenchmarkFailed("key-prefix lease already exists; supply an exclusive --key-prefix"))
		Resp.SimpleString([79, 75]) => {
			benchmark_result = run_benchmarks!(runtime_config, transport, set_key, incr_key)
			cleanup_result = cleanup_keys!(runtime_config, marker_key, set_key, incr_key)
			combine_run_and_cleanup(benchmark_result, cleanup_result)
		}
		response => Err(BenchmarkFailed("lease SET returned ${describe_response(response)}, expected OK or null"))
	}
}

redis_version_from_response : Resp.Resp -> Try(Str, [BenchmarkFailed(Str)])
redis_version_from_response = |response|
	match response {
		Resp.BulkString(bytes) => {
			info = Str.from_utf8(bytes)
				? |_| BenchmarkFailed("INFO server returned non-UTF-8 bytes")
			line = info.split_on("\n").find_first(|candidate| candidate.trim().starts_with("redis_version:"))
				? |_| BenchmarkFailed("INFO server omitted redis_version")
			version = line.trim().drop_prefix("redis_version:").trim()
			if is_safe_version(version) {
				Ok(version)
			} else {
				Err(BenchmarkFailed("INFO server returned an invalid redis_version ${Str.inspect(version)}"))
			}
		}
		other => Err(BenchmarkFailed("INFO server returned ${describe_response(other)}, expected a bulk string"))
	}

is_safe_version : Str -> Bool
is_safe_version = |version| {
	bytes = version.to_utf8()
	bytes.len() >= 1 and bytes.len() <= 128 and bytes.all(|byte|
		(byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) or byte == 43 or byte == 45 or byte == 46 or byte == 95)
}

combine_run_and_cleanup : Try({}, [BenchmarkFailed(Str)]), Try({}, [BenchmarkFailed(Str)]) -> Try({}, [BenchmarkFailed(Str)])
combine_run_and_cleanup = |benchmark_result, cleanup_result|
	match (benchmark_result, cleanup_result) {
		(Ok(_), Ok({})) => Ok({})
		(Err(error), Ok({})) => Err(error)
		(Ok(_), Err(BenchmarkFailed(cleanup_message))) => Err(BenchmarkFailed("benchmark succeeded but cleanup failed: ${cleanup_message}"))
		(Err(BenchmarkFailed(run_message)), Err(BenchmarkFailed(cleanup_message))) => Err(BenchmarkFailed("benchmark failed: ${run_message}; cleanup also failed: ${cleanup_message}"))
	}

cleanup_keys! : Config, List(U8), List(U8), List(U8) => Try({}, [BenchmarkFailed(Str)])
cleanup_keys! = |config, marker_key, set_key, incr_key| {
	stream = Tcp.connect!(config.host, config.port, config.timeout_ms)
		? |error| BenchmarkFailed("connect cleanup transport: ${Str.inspect(error)}")
	transport : Execute.Transport(_, _)
	transport = {
		read!: |max_bytes|
			stream.read_up_to!(max_bytes, config.timeout_ms)
				.map_ok(|bytes| if bytes.is_empty() End else Data(bytes)),
		write_all!: |bytes| stream.write!(bytes, config.timeout_ms),
	}
	result = raw_request!(RawKeyspace.del(marker_key, [set_key, incr_key]), transport)
		? |error| BenchmarkFailed("delete benchmark keys: ${Str.inspect(error)}")
	match result {
		Resp.Integer(number) if number >= 0 and number <= 3 => Ok({})
		response => Err(BenchmarkFailed("cleanup DEL returned ${describe_response(response)}, expected an integer from 0 through 3"))
	}
}

run_benchmarks! : Config, Execute.Transport(read_err, write_err), List(U8), List(U8) => Try({}, [BenchmarkFailed(Str)])
run_benchmarks! = |config, transport, set_key, incr_key| {
	{} = run_ping!(1, transport)?
	{} = benchmark_ping_samples!(config, 1, transport)?
	{} = benchmark_set_get_samples!(config, 1, transport, set_key)?
	{} = benchmark_incr_samples!(config, 1, transport, incr_key)?
	benchmark_pipeline_samples!(config, 1, transport)
}

benchmark_ping_samples! : Config, U64, Execute.Transport(read_err, write_err) => Try({}, [BenchmarkFailed(Str)])
benchmark_ping_samples! = |config, sample, transport|
	if sample > config.samples {
		Ok({})
	} else {
		{} = run_ping!(config.warmup, transport)?
		start = Utc.now!()
		{} = run_ping!(config.iterations, transport)?
		end = Utc.now!()
		elapsed = elapsed_nanos(start, end)?
		{} = emit_result!(config, "ping_sequential", sample, config.iterations, config.iterations, config.iterations, elapsed)?
		benchmark_ping_samples!(config, sample + 1, transport)
	}

benchmark_set_get_samples! : Config, U64, Execute.Transport(read_err, write_err), List(U8) => Try({}, [BenchmarkFailed(Str)])
benchmark_set_get_samples! = |config, sample, transport, key|
	if sample > config.samples {
		Ok({})
	} else {
		{} = run_set_get!(config.warmup, transport, key)?
		start = Utc.now!()
		{} = run_set_get!(config.iterations, transport, key)?
		end = Utc.now!()
		elapsed = elapsed_nanos(start, end)?
		{} = emit_result!(config, "set_get_sequential", sample, config.iterations, config.iterations * 2, config.iterations * 2, elapsed)?
		benchmark_set_get_samples!(config, sample + 1, transport, key)
	}

benchmark_incr_samples! : Config, U64, Execute.Transport(read_err, write_err), List(U8) => Try({}, [BenchmarkFailed(Str)])
benchmark_incr_samples! = |config, sample, transport, key|
	if sample > config.samples {
		Ok({})
	} else {
		{} = prepare_counter!(transport, key)?
		{} = run_incr!(config.warmup, 1, transport, key)?
		{} = prepare_counter!(transport, key)?
		start = Utc.now!()
		{} = run_incr!(config.iterations, 1, transport, key)?
		end = Utc.now!()
		elapsed = elapsed_nanos(start, end)?
		{} = emit_result!(config, "incr_sequential", sample, config.iterations, config.iterations, config.iterations, elapsed)?
		benchmark_incr_samples!(config, sample + 1, transport, key)
	}

benchmark_pipeline_samples! : Config, U64, Execute.Transport(read_err, write_err) => Try({}, [BenchmarkFailed(Str)])
benchmark_pipeline_samples! = |config, sample, transport|
	if sample > config.samples {
		Ok({})
	} else {
		{} = run_ping_pipeline!(config.warmup, config.pipeline_batch, transport)?
		start = Utc.now!()
		{} = run_ping_pipeline!(config.iterations, config.pipeline_batch, transport)?
		end = Utc.now!()
		elapsed = elapsed_nanos(start, end)?
		round_trips = ceiling_divide(config.iterations, config.pipeline_batch)
		{} = emit_result!(config, "ping_pipeline", sample, config.iterations, config.iterations, round_trips, elapsed)?
		benchmark_pipeline_samples!(config, sample + 1, transport)
	}

run_ping! : U64, Execute.Transport(read_err, write_err) => Try({}, [BenchmarkFailed(Str)])
run_ping! = |remaining, transport|
	if remaining == 0 {
		Ok({})
	} else {
		result = raw_request!(Command.ping({}), transport)
			? |error| BenchmarkFailed("PING: ${Str.inspect(error)}")
		{} = require_response("PING", result, Resp.simple_utf8("PONG"))?
		run_ping!(remaining - 1, transport)
	}

run_set_get! : U64, Execute.Transport(read_err, write_err), List(U8) => Try({}, [BenchmarkFailed(Str)])
run_set_get! = |remaining, transport, key|
	if remaining == 0 {
		Ok({})
	} else {
		set_result = raw_request!(
			RawStrings.set(key, binary_payload, [Str.to_utf8("PX"), key_ttl_ms]),
			transport,
		) ? |error| BenchmarkFailed("SET: ${Str.inspect(error)}")
		{} = require_response("SET", set_result, Resp.simple_utf8("OK"))?
		get_result = raw_request!(RawStrings.get(key), transport)
			? |error| BenchmarkFailed("GET: ${Str.inspect(error)}")
		{} = require_response("GET", get_result, Resp.BulkString(binary_payload))?
		run_set_get!(remaining - 1, transport, key)
	}

prepare_counter! : Execute.Transport(read_err, write_err), List(U8) => Try({}, [BenchmarkFailed(Str)])
prepare_counter! = |transport, key| {
	result = raw_request!(
		RawStrings.set(key, Str.to_utf8("0"), [Str.to_utf8("PX"), key_ttl_ms]),
		transport,
	) ? |error| BenchmarkFailed("counter SET: ${Str.inspect(error)}")
	require_response("counter SET", result, Resp.simple_utf8("OK"))
}

run_incr! : U64, I64, Execute.Transport(read_err, write_err), List(U8) => Try({}, [BenchmarkFailed(Str)])
run_incr! = |remaining, expected, transport, key|
	if remaining == 0 {
		Ok({})
	} else {
		result = raw_request!(RawStrings.incr(key), transport)
			? |error| BenchmarkFailed("INCR: ${Str.inspect(error)}")
		{} = require_response("INCR", result, Resp.Integer(expected))?
		run_incr!(remaining - 1, expected + 1, transport, key)
	}

run_ping_pipeline! : U64, U64, Execute.Transport(read_err, write_err) => Try({}, [BenchmarkFailed(Str)])
run_ping_pipeline! = |remaining, batch_size, transport|
	if remaining == 0 {
		Ok({})
	} else {
		current_batch = if remaining < batch_size remaining else batch_size
		commands = List.repeat(Command.ping({}), current_batch)
		result = Execute.batch!(execution_config, Batch.all(commands.map(|command| Request.new(command, Reply.raw))), transport)
			? |error| BenchmarkFailed("PING pipeline: ${Str.inspect(error)}")
		if result.len() == current_batch and result.all(|response| response == Resp.simple_utf8("PONG")) {
			run_ping_pipeline!(remaining - current_batch, batch_size, transport)
		} else {
			Err(BenchmarkFailed("PING pipeline returned ${result.len().to_str()} replies with an invalid value; expected ${current_batch.to_str()} PONG replies"))
		}
	}

require_response : Str, Resp.Resp, Resp.Resp -> Try({}, [BenchmarkFailed(Str)])
require_response = |operation, actual, expected|
	if actual == expected {
		Ok({})
	} else {
		Err(BenchmarkFailed("${operation} returned ${describe_response(actual)}, expected ${describe_response(expected)}"))
	}

describe_response : Resp.Resp -> Str
describe_response = |response|
	match response {
		Resp.Array(values) => "array(${values.len().to_str()})"
		Resp.BulkString(bytes) => "bulk(${Str.inspect(bytes)})"
		Resp.ErrorReply(bytes) => "error(${Str.inspect(bytes)})"
		Resp.Integer(number) => "integer(${number.to_str()})"
		Resp.NullBulkString => "null bulk string"
		Resp.NullArray => "null array"
		Resp.SimpleString(bytes) => "simple(${Str.inspect(bytes)})"
	}

elapsed_nanos : U128, U128 -> Try(U128, [BenchmarkFailed(Str)])
elapsed_nanos = |start, end|
	if end >= start {
		Ok(end - start)
	} else {
		Err(BenchmarkFailed("UTC clock moved backwards during a measured sample"))
	}

ceiling_divide : U64, U64 -> U64
ceiling_divide = |dividend, divisor| (dividend + divisor - 1) // divisor

emit_result! : Config, Str, U64, U64, U64, U64, U128 => Try({}, [BenchmarkFailed(Str)])
emit_result! = |config, workload, sample, operation_count, command_count, round_trip_count, elapsed_ns| {
	json = "{\"schema\":\"roc-redis-benchmark/v2\",\"implementation\":\"roc\",\"client\":\"roc-redis\",\"client_version\":\"${client_version}\",\"runtime_version\":\"nightly-2026-09-07-14d9829\",\"redis_version\":\"${config.redis_version}\",\"nix_source_id\":\"${config.nix_source_id}\",\"build_mode\":\"${config.build_mode}\",\"nix_system\":\"${config.nix_system}\",\"os\":\"${config.os}\",\"arch\":\"${config.arch}\",\"order_rotation\":${config.order_rotation.to_str()},\"subject_position\":${config.subject_position.to_str()},\"timer\":\"utc_wall_clock\",\"workload\":\"${workload}\",\"sample\":${sample.to_str()},\"samples\":${config.samples.to_str()},\"iterations\":${config.iterations.to_str()},\"warmup\":${config.warmup.to_str()},\"pipeline_batch\":${config.pipeline_batch.to_str()},\"operation_count\":${operation_count.to_str()},\"command_count\":${command_count.to_str()},\"round_trip_count\":${round_trip_count.to_str()},\"elapsed_ns\":${elapsed_ns.to_str()},\"validated\":true}"
	Stdout.line!(json).map_err(|error| BenchmarkFailed("write benchmark result: ${Str.inspect(error)}"))
}

expect parse_port("1") == Ok(1)

expect parse_port("65535") == Ok(65_535)

expect ["", "0", "+1", "-1", "1_0", "65536"].all(|text| parse_port(text).is_err())

expect parse_bounded("samples", "5", 1, max_samples) == Ok(5)

expect ["", "+1", "-1", "1_000", "1001"].all(|text| parse_bounded("samples", text, 1, max_samples).is_err())

expect is_safe_host("127.0.0.1") and is_safe_host("::1") and !(is_safe_host("bad host"))

expect is_safe_prefix("roc-redis-bench:test_1") and !(is_safe_prefix("bad/prefix")) and !(is_safe_prefix(""))

expect redis_version_from_response(Resp.BulkString(Str.to_utf8("# Server\r\nredis_version:8.10.1\r\n"))) == Ok("8.10.1")

expect redis_version_from_response(Resp.BulkString(Str.to_utf8("redis_version:bad version\r\n"))).is_err()

expect binary_payload.len() == 32

expect ceiling_divide(10_000, 100) == 100

expect ceiling_divide(10_001, 100) == 101

expect {
	parsed = parse_options(["--iterations", "20", "--warmup", "0", "--samples", "2", "--pipeline-batch", "7", "--timeout-ms", "20", "--port", "6380", "--host", "localhost", "--key-prefix", "roc-redis-bench:test"], default_config)?
	parsed == {
		host: "localhost",
		port: 6_380,
		iterations: 20,
		warmup: 0,
		samples: 2,
		pipeline_batch: 7,
		timeout_ms: 20,
		key_prefix: "roc-redis-bench:test",
		redis_version: "",
		nix_source_id: "unmanaged",
		build_mode: "unmanaged",
		nix_system: "unmanaged",
		os: "unmanaged",
		arch: "unmanaged",
		order_rotation: 0,
		subject_position: 0,
	}
}

expect parse_options(["--nix-source-id", "abc-source", "--build-mode", "dev", "--nix-system", "aarch64-darwin", "--os", "darwin", "--arch", "aarch64", "--order-rotation", "5", "--subject-position", "3"], default_config) == Ok({ ..default_config, nix_source_id: "abc-source", build_mode: "dev", nix_system: "aarch64-darwin", os: "darwin", arch: "aarch64", order_rotation: 5, subject_position: 3 })

expect [["--nix-source-id", "bad/source"], ["--order-rotation", "10"], ["--subject-position", "6"]].all(|args| parse_options(args, default_config).is_err())
