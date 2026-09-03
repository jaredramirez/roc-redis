import Decoder

## Validated resource policy. Build once and reuse across executions.
##
## Prefer one module-level destructure for constant application configuration:
##
## ```roc
## Ok(config) =
##     Config.default
##     |> Config.with_read_size(32_768)
##     |> Config.build
## ```
##
## The compiler checks the constant result before runtime. For values obtained
## at runtime, handle Config.build with `?` or `match` instead. Keep constant
## declarations outside `expect` blocks on the pinned compiler.
Config :: {
	limits : Decoder.Limits,
	max_commands : U64,
	max_request_bytes : U64,
	max_response_bytes : U64,
	read_size : U64,
}.{
	is_eq : _

	## Unvalidated candidates. Setters never fail; build validates the whole value.
	Builder :: {
		limits : Decoder.Limits,
		max_commands : U64,
		max_request_bytes : U64,
		max_response_bytes : U64,
		read_size : U64,
	}

	Field : [ArrayLength, BulkLength, Commands, Depth, FrameLength, LineLength, ReadSize, RequestBytes, ResponseBytes, Values]
	Error : [ZeroLimit(Field)]

	## Bounded starting policy for ordinary workloads. All byte limits are bytes;
	## decoder limits apply per reply and response bytes apply per exchange.
	default : Builder
	default = Builder.{
		limits: Decoder.default_limits,
		max_commands: 4096,
		max_request_bytes: 16 * 1024 * 1024,
		max_response_bytes: 16 * 1024 * 1024,
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

	with_read_size : Builder, U64 -> Builder
	with_read_size = |builder, read_size| { ..builder, read_size }

	with_max_commands : Builder, U64 -> Builder
	with_max_commands = |builder, max_commands| { ..builder, max_commands }

	with_max_request_bytes : Builder, U64 -> Builder
	with_max_request_bytes = |builder, max_request_bytes| { ..builder, max_request_bytes }

	with_max_response_bytes : Builder, U64 -> Builder
	with_max_response_bytes = |builder, max_response_bytes| { ..builder, max_response_bytes }

	with_decoder_limits : Builder, Decoder.Limits -> Builder
	with_decoder_limits = |builder, limits| { ..builder, limits }

	build : Builder -> Try(Config, Error)
	build = |builder| {
		fields = [
			(ReadSize, builder.read_size),
			(Commands, builder.max_commands),
			(RequestBytes, builder.max_request_bytes),
			(ResponseBytes, builder.max_response_bytes),
			(ArrayLength, builder.limits.max_array_length),
			(BulkLength, builder.limits.max_bulk_length),
			(Depth, builder.limits.max_depth),
			(FrameLength, builder.limits.max_frame_length),
			(LineLength, builder.limits.max_line_length),
			(Values, builder.limits.max_values),
		]
		for (field, value) in fields {
			if value == 0 {
				return Err(ZeroLimit(field))
			}
		}
		Ok(
			Config.{
				limits: builder.limits,
				max_commands: builder.max_commands,
				max_request_bytes: builder.max_request_bytes,
				max_response_bytes: builder.max_response_bytes,
				read_size: builder.read_size,
			},
		)
	}

	decoder_limits : Config -> Decoder.Limits
	decoder_limits = |config| config.limits

	command_limit : Config -> U64
	command_limit = |config| config.max_commands

	request_byte_limit : Config -> U64
	request_byte_limit = |config| config.max_request_bytes

	response_byte_limit : Config -> U64
	response_byte_limit = |config| config.max_response_bytes

	read_size : Config -> U64
	read_size = |config| config.read_size
}

Ok(production_config) = Config.default |> Config.with_read_size(32_768) |> Config.with_max_request_bytes(64 * 1024 * 1024) |> Config.build

expect production_config.read_size() == 32_768 and production_config.request_byte_limit() == 64 * 1024 * 1024

expect Config.build(Config.redis_compatible).is_ok()

expect Config.build(Config.default).map_ok(Config.decoder_limits) == Ok(Decoder.default_limits)
expect Config.build(Config.redis_compatible).map_ok(Config.decoder_limits) == Ok(Decoder.redis_compatible_limits)

expect Config.default |> Config.with_read_size(0) |> Config.build == Err(ZeroLimit(ReadSize))

expect Config.default |> Config.with_max_commands(0) |> Config.build == Err(ZeroLimit(Commands))

expect Config.default |> Config.with_max_request_bytes(0) |> Config.build == Err(ZeroLimit(RequestBytes))

expect Config.default |> Config.with_max_response_bytes(0) |> Config.build == Err(ZeroLimit(ResponseBytes))

## Intermediate candidate values may be invalid; only the final value matters.
Ok(repaired_config) = Config.default |> Config.with_read_size(0) |> Config.with_read_size(1) |> Config.build

expect repaired_config.read_size() == 1
