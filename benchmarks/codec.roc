## Server-free codec comparison against hiredis public APIs. Build before timing.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "../package/main.roc",
}

import pf.Cmd
import pf.Env
import pf.OsStr
import pf.Stdout
import pf.Utc
import redis.Bytes
import redis.Command
import redis.Decoder
import redis.Resp

Fixture : { command : Command.Command, encoded : List(U8), response : List(U8), payload : List(U8) }

Record : { schema : Str, implementation : Str, runtime : Str, timer : Str, source : Str, workload : Str, sample : U64, position : U64, iterations : U64, warmup : U64, elapsed_ns : U128, validated : Bool }

main! = |args| {
	iterations = match args.drop_first(1) {
		[] => Ok(10_000)
		[arg] => match OsStr.to_str_try(arg) {
			Ok(text) => parse_iterations(text)
			Err(_) => Err("invalid UTF-8 argument")
		}
		_ => Err("usage: benchmark-codec [iterations]")
	} ? |message| CodecFailed(message)
	native = Env.var_str!(OsStr.from_str("ROC_REDIS_CODEC_C")) ? |error| CodecFailed(Str.inspect(error))
	source = Env.var_str!(OsStr.from_str("ROC_REDIS_NIX_SOURCE_ID")) ? |error| CodecFailed(Str.inspect(error))
	build_mode = Env.var_str!(OsStr.from_str("ROC_REDIS_BUILD_MODE")) ? |error| CodecFailed(Str.inspect(error))
	seed = Utc.now!().to_u8_wrap()
	fixtures = make_fixtures(seed)
	var $sample = 1.U64
	while $sample <= 10 {
		for position in [1.U64, 2] {
			if ($sample % 2 == 1 and position == 1) or ($sample % 2 == 0 and position == 2) {
				for workload in ["encode_set", "decode_bulk"] {
					run(workload, 1_000, fixtures) ? |CodecFailed(message)| CodecFailed(message)
					start = Utc.now!()
					run(workload, iterations, fixtures) ? |CodecFailed(message)| CodecFailed(message)
					end = Utc.now!()
					if end <= start {
						return Err(CodecFailed("nonpositive UTC elapsed time"))
					}
					record : Record
					record = { schema: "roc-redis-codec/v1", implementation: "roc", runtime: "nightly-2026-09-07-14d9829/${build_mode}", timer: "utc_wall_clock", source, workload, sample: $sample, position, iterations, warmup: 1_000, elapsed_ns: end - start, validated: True }
					Stdout.line!(Json.to_str(record))?
				}
			} else {
				output = Cmd.new_str("timeout").args_str(["--kill-after=2s", "120s", native, iterations.to_str(), $sample.to_str(), position.to_str(), source, seed.to_str()]).exec_output!() ? |error| CodecFailed(Str.inspect(error))
				lines = output.stdout_utf8.trim().split_on("\n")
				if lines.len() != 2 {
					return Err(CodecFailed("native codec subject did not return two records"))
				}
				var $index = 0.U64
				for line in lines {
					record : Record
					record = Json.parse(line) ? |error| CodecFailed(Str.inspect(error))
					expected_workload = if $index == 0 {
						"encode_set"
					} else {
						"decode_bulk"
					}
					if record.schema != "roc-redis-codec/v1" or record.implementation != "hiredis" or record.timer != "monotonic" or record.source != source or record.workload != expected_workload or record.sample != $sample or record.position != position or record.iterations != iterations or record.warmup != 1_000 or record.elapsed_ns == 0 or !record.validated {
						return Err(CodecFailed("invalid native codec record"))
					}
					Stdout.line!(line)?
					$index = $index + 1
				}
			}
		}
		$sample = $sample + 1
	}
	Ok({})
}

parse_iterations : Str -> Try(U64, Str)
parse_iterations = |text| {
	if text.is_empty() or !text.to_utf8().all(|byte| byte >= '0' and byte <= '9') {
		return Err("iterations must be decimal")
	}
	value = U64.from_str(text).map_err(|_| "iterations overflow")?
	if value == 0 or value > 1_000_000 {
		Err("iterations must be 1..1000000")
	} else {
		Ok(value)
	}
}

make_fixtures : U8 -> List(Fixture)
make_fixtures = |seed| {
	base = [0, 13, 10, 255, 128, 82, 111, 99, 45, 82, 101, 100, 105, 115, 0, 1, 2, 3, 10, 13, 127, 128, 254, 255, 65, 66, 67, 120, 121, 122, 0]
	var $fixtures = List.with_capacity(256)
	var $index = 0.U64
	while $index < 256 {
		payload = base.append(($index + seed.to_u64()).to_u8_wrap())
		$fixtures = $fixtures.append({ command: Command.new("SET", ["key", Bytes.from_list(payload)]), encoded: "*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$32\r\n".to_utf8().concat(payload).concat(['\r', '\n']), response: "$32\r\n".to_utf8().concat(payload).concat(['\r', '\n']), payload })
		$index = $index + 1
	}
	$fixtures
}

run : Str, U64, List(Fixture) -> Try({}, [CodecFailed(Str)])
run = |workload, iterations, fixtures| {
	var $index = 0.U64
	while $index < iterations {
		fixture = fixtures.get($index % 256) ? |_| CodecFailed("missing fixture")
		if workload == "encode_set" {
			encoded = Command.encode_bounded([fixture.command], 1024) ? |_| CodecFailed("encoding rejected fixture")
			if encoded != fixture.encoded {
				return Err(CodecFailed("encoded bytes differ"))
			}
		} else {
			match Decoder.feed(Decoder.init({}), fixture.response) {
				Progress({ decoder, values: [Resp.BulkString(payload)] }) if payload == fixture.payload and Decoder.finish(decoder).is_ok() => {}
				_ => return Err(CodecFailed("decoded fixture differs"))
			}
		}
		$index = $index + 1
	}
	Ok({})
}

expect parse_iterations("0").is_err()
expect parse_iterations("10000") == Ok(10000)
expect parse_iterations("+1").is_err()
expect run("encode_set", 256, make_fixtures(0)) == Ok({})
expect run("decode_bulk", 256, make_fixtures(0)) == Ok({})
