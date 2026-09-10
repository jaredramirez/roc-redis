import Decoder
import Positive

## Validated resource policy. Build once and reuse across executions.
##
## The scalar limits are compile-time-validated positive integers, so a literal
## like `Config.with_read_size(0)` fails to compile and `Config.build` is total:
##
## ```roc
## config =
##     Config.default
##     |> Config.with_read_size(32_768)
##     |> Config.build
## ```
##
## For a value obtained at runtime, validate it through `Positive.from_u64`
## first. Decoder limits are supplied as `Decoder.Limits`; `default` and
## `redis_compatible` provide sound values and the decoder tolerates any others.
Config :: {
	limits : Decoder.Limits,
	max_commands : Positive.Positive,
	max_request_bytes : Positive.Positive,
	max_response_bytes : Positive.Positive,
	read_size : Positive.Positive,
}.{
	is_eq : _

	## Unvalidated candidates. Setters never fail; every scalar limit is already
	## a validated Positive, so build has nothing left to reject.
	Builder :: {
		limits : Decoder.Limits,
		max_commands : Positive.Positive,
		max_request_bytes : Positive.Positive,
		max_response_bytes : Positive.Positive,
		read_size : Positive.Positive,
	}

	## Bounded starting policy for ordinary workloads. All byte limits are bytes;
	## decoder limits apply per reply and response bytes apply per exchange.
	default : Builder
	default = Builder.{
		limits: Decoder.default_limits,
		max_commands: 4096,
		max_request_bytes: 16_777_216,
		max_response_bytes: 16_777_216,
		read_size: 16_384,
	}

	## Larger finite decoder policy for Redis-sized values. This does not promise
	## compatibility with every server configuration or platform read limit.
	redis_compatible : Builder
	redis_compatible = Builder.{
		limits: Decoder.redis_compatible_limits,
		max_commands: 65_536,
		max_request_bytes: 536_936_448,
		max_response_bytes: 536_936_448,
		read_size: 16_384,
	}

	with_read_size : Builder, Positive.Positive -> Builder
	with_read_size = |builder, read_size| { ..builder, read_size }

	with_max_commands : Builder, Positive.Positive -> Builder
	with_max_commands = |builder, max_commands| { ..builder, max_commands }

	with_max_request_bytes : Builder, Positive.Positive -> Builder
	with_max_request_bytes = |builder, max_request_bytes| { ..builder, max_request_bytes }

	with_max_response_bytes : Builder, Positive.Positive -> Builder
	with_max_response_bytes = |builder, max_response_bytes| { ..builder, max_response_bytes }

	with_decoder_limits : Builder, Decoder.Limits -> Builder
	with_decoder_limits = |builder, limits| { ..builder, limits }

	## Finalize a policy. Total: every scalar already carries its non-zero
	## invariant and decoder limits are trusted, so there is nothing to reject.
	build : Builder -> Config
	build = |builder| Config.{
		limits: builder.limits,
		max_commands: builder.max_commands,
		max_request_bytes: builder.max_request_bytes,
		max_response_bytes: builder.max_response_bytes,
		read_size: builder.read_size,
	}

	decoder_limits : Config -> Decoder.Limits
	decoder_limits = |config| config.limits

	command_limit : Config -> U64
	command_limit = |config| config.max_commands.to_u64()

	request_byte_limit : Config -> U64
	request_byte_limit = |config| config.max_request_bytes.to_u64()

	response_byte_limit : Config -> U64
	response_byte_limit = |config| config.max_response_bytes.to_u64()

	read_size : Config -> U64
	read_size = |config| config.read_size.to_u64()
}

production_config = Config.default |> Config.with_read_size(32_768) |> Config.with_max_request_bytes(67_108_864) |> Config.build

expect production_config.read_size() == 32_768 and production_config.request_byte_limit() == 67_108_864

expect Config.build(Config.default).decoder_limits() == Decoder.default_limits
expect Config.build(Config.redis_compatible).decoder_limits() == Decoder.redis_compatible_limits
expect Config.build(Config.default).command_limit() == 4096
expect Config.build(Config.redis_compatible).command_limit() == 65_536
