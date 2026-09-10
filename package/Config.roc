import Decoder
import Positive

## Validated resource policy. Construct with defaults and override only what you
## need; every field is valid by construction, so there is no separate build step:
##
## ```roc
## config = Config.{ read_size: 32_768 }
## ```
##
## Scalar limits are compile-time-validated positives, so `Config.{ read_size: 0 }`
## fails to compile; validate a runtime limit through `Positive.from_u64` first.
## Decoder limits default to sound values, and the decoder tolerates any others.
Config := {
	limits : Decoder.Limits ?? Decoder.default_limits,
	max_commands : Positive.Positive ?? 4096,
	max_request_bytes : Positive.Positive ?? 16_777_216,
	max_response_bytes : Positive.Positive ?? 16_777_216,
	read_size : Positive.Positive ?? 16_384,
}.{
	is_eq : _

	## All defaults: a bounded starting policy for ordinary workloads. All byte
	## limits are bytes; decoder limits apply per reply and response bytes apply
	## per exchange.
	default : Config
	default = Config.{}

	## Larger finite decoder policy for Redis-sized values. This does not promise
	## compatibility with every server configuration or platform read limit.
	redis_compatible : Config
	redis_compatible = Config.{
		limits: Decoder.redis_compatible_limits,
		max_commands: 65_536,
		max_request_bytes: 536_936_448,
		max_response_bytes: 536_936_448,
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

expect Config.default.read_size() == 16_384
expect Config.default.command_limit() == 4096
expect Config.{ read_size: 32_768 }.read_size() == 32_768
expect Config.{ read_size: 32_768 }.command_limit() == 4096
expect Config.redis_compatible.command_limit() == 65_536
expect Config.default.decoder_limits() == Decoder.default_limits
expect Config.redis_compatible.decoder_limits() == Decoder.redis_compatible_limits
