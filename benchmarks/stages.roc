## Diagnostic timings for pipeline stages; not an additive CPU profile.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "../package/main.roc",
}

import pf.OsStr
import pf.Env
import pf.Stdout
import pf.Utc
import redis.Batch
import redis.Command
import redis.Config
import redis.Decoder
import redis.Execute
import redis.NonEmptyBytes
import redis.Reply
import redis.Request
import redis.Resp

Fixture : { commands : List(Command.Command), wire : List(U8), responses : List(Resp.Resp), encoded : List(U8) }

Record : { schema : Str, variant : Str, source : Str, compiler : Str, stage : Str, sample : U64, iterations : U64, commands_per_iteration : U64, elapsed_ns : U128, validated : Bool }

config = Config.default

main! = |args| {
	variant = Env.var_str!(OsStr.from_str("ROC_REDIS_STAGE_VARIANT")) ? |_| StageFailed("set ROC_REDIS_STAGE_VARIANT to the compiled variant")
	source = Env.var_str!(OsStr.from_str("ROC_REDIS_NIX_SOURCE_ID")) ? |_| StageFailed("set ROC_REDIS_NIX_SOURCE_ID to the source identity")
	iterations = match args.drop_first(1) {
		[value] => {
			text = OsStr.to_str_try(value) ? |_| StageFailed("invalid argument")
			U64.from_str(text) ? |_| StageFailed("invalid iteration count")
		}
		_ => return Err(StageFailed("usage: stages iterations"))
	}
	if iterations == 0 or iterations > 100_000 {
		return Err(StageFailed("iterations must be 1..100000"))
	}
	# Runtime-sized fixtures and alternating content prevent constant evaluation.
	count = 100 + iterations % 2
	fixtures = [fixture("PING", "PONG", count), fixture("pInG", "pOnG", count)]
	plans = fixtures.map(|f| Batch.all(f.commands.map(|command| Request.new(command, Reply.raw))))
	for sample in [1.U64, 2, 3, 4, 5] {
		for stage in ["encode_pipeline", "decode_pipeline", "decode_fragmented", "semantic_decode", "plan_and_decode", "exchange_mock"] {
			run!(stage, 100, fixtures, plans) ? |StageFailed(message)| StageFailed(message)
			start = Utc.now!()
			run!(stage, iterations, fixtures, plans) ? |StageFailed(message)| StageFailed(message)
			end = Utc.now!()
			if end <= start {
				return Err(StageFailed("nonpositive timing"))
			}
			elapsed = end - start
			record : Record
			record = { schema: "roc-redis-stages/v1", variant, source, compiler: "nightly-2026-09-07-14d9829", stage, sample, iterations, commands_per_iteration: count, elapsed_ns: elapsed, validated: True }
			Stdout.line!(Json.to_str(record))?
		}
	}
	Ok({})
}

fixture : NonEmptyBytes.NonEmptyBytes, Str, U64 -> Fixture
fixture = |name, payload, count| {
	commands = List.repeat(Command.from_nonempty_bytes(name, []), count)
	{ commands, encoded: Command.encode_pipeline(commands), wire: Str.join_with(List.repeat("+${payload}\r\n", count), "").to_utf8(), responses: List.repeat(Resp.simple_utf8(payload), count) }
}

run! : Str, U64, List(Fixture), List(Batch.Batch(List(Resp.Resp), plan_error)) => Try({}, [StageFailed(Str)])
run! = |stage, iterations, fixtures, plans| {
	var $index = 0.U64
	while $index < iterations {
		f = fixtures.get($index % 2) ? |_| StageFailed("missing fixture")
		plan = plans.get($index % 2) ? |_| StageFailed("missing plan")
		match stage {
			"encode_pipeline" => {
				encoded = Command.encode_bounded(f.commands, 1_000_000) ? |_| StageFailed("encoding failed")
				if encoded != f.encoded {
					return Err(StageFailed("wrong encoding"))
				}
			}
			"decode_pipeline" => match Decoder.feed(Decoder.init(), f.wire) {
				Progress({ decoder, values }) if values == f.responses and Decoder.finish(decoder).is_ok() => {}
				_ => return Err(StageFailed("wrong decoding"))
			}
			"decode_fragmented" => {
				var $decoder = Decoder.init()
				var $values = []
				var $offset = 0.U64
				while $offset < f.wire.len() {
					match Decoder.feed($decoder, f.wire.sublist({ start: $offset, len: 31 })) {
						Progress({ decoder, values }) => {
							$decoder = decoder
							$values = $values.concat(values)
						}
						_ => return Err(StageFailed("fragmented decoding failed"))
					}
					$offset = $offset + 31
				}
				if $values != f.responses or Decoder.finish($decoder).is_err() {
					return Err(StageFailed("wrong fragmented decoding"))
				}
			}
			"semantic_decode" => {
				values = plan.decode(f.responses) ? |_| StageFailed("semantic decode failed")
				if values != f.responses {
					return Err(StageFailed("wrong semantic values"))
				}
			}
			"plan_and_decode" => {
				built = Batch.all(f.commands.map(|command| Request.new(command, Reply.raw)))
				values = built.decode(f.responses) ? |_| StageFailed("constructed decode failed")
				if values != f.responses {
					return Err(StageFailed("wrong constructed values"))
				}
			}
			"exchange_mock" => {
				transport = {
					read!: |_| Ok(Data(f.wire)),
					write_all!: |bytes| if bytes == f.encoded {
						Ok({})
					} else {
						Err(WrongWrite)
					},
				}
				values = Execute.batch!(config, plan, transport) ? |_| StageFailed("mock exchange failed")
				if values != f.responses {
					return Err(StageFailed("wrong exchange values"))
				}
			}
			_ => return Err(StageFailed("unknown stage"))
		}
		$index = $index + 1
	}
	Ok({})
}
