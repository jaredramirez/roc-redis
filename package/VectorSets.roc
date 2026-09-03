import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 Vector Set command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
VectorSets := {}.{

	## Construct `VADD`.
	## Available since Redis 8.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/vadd/).
	## Parameters (in order): `key`, `options_before_input`, `input`, `element`, `options`.
	## `input` is `Fp32(blob)` or `Values({ first, rest })`; the non-empty VALUES count is derived automatically.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	vadd : List(U8), List(List(U8)), [Fp32(List(U8)), Values({ first : List(U8), rest : List(List(U8)) })], List(U8), List(List(U8)) -> Command.Command
	vadd = |key, options_before_input, input, element, options| {
		encoded_input = match input {
			Fp32(blob) => [['F', 'P', '3', '2'], blob]
			Values({ first, rest }) => {
				values = [first].concat(rest)
				[['V', 'A', 'L', 'U', 'E', 'S'], values.len().to_str().to_utf8()].concat(values)
			}
		}
		Command.from_nonempty_bytes("VADD", [key].concat(options_before_input).concat(encoded_input).concat([element]).concat(options))
	}

	## Construct `VCARD`.
	## Available since Redis 8.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/vcard/).
	## Parameters (in order): `key`.
	vcard : List(U8) -> Command.Command
	vcard = |key| {
		Command.from_nonempty_bytes("VCARD", [key])
	}

	## Construct `VDIM`.
	## Available since Redis 8.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/vdim/).
	## Parameters (in order): `key`.
	vdim : List(U8) -> Command.Command
	vdim = |key| {
		Command.from_nonempty_bytes("VDIM", [key])
	}

	## Construct `VEMB`.
	## Available since Redis 8.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/vemb/).
	## Parameters (in order): `key`, `element`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	vemb : List(U8), List(U8), List(List(U8)) -> Command.Command
	vemb = |key, element, options| {
		Command.from_nonempty_bytes("VEMB", [key, element].concat(options))
	}

	## Construct `VGETATTR`.
	## Available since Redis 8.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/vgetattr/).
	## Parameters (in order): `key`, `element`.
	vgetattr : List(U8), List(U8) -> Command.Command
	vgetattr = |key, element| {
		Command.from_nonempty_bytes("VGETATTR", [key, element])
	}

	## Construct `VINFO`.
	## Available since Redis 8.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/vinfo/).
	## Parameters (in order): `key`.
	vinfo : List(U8) -> Command.Command
	vinfo = |key| {
		Command.from_nonempty_bytes("VINFO", [key])
	}

	## Construct `VISMEMBER`.
	## Available since Redis 8.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/vismember/).
	## Parameters (in order): `key`, `element`.
	vismember : List(U8), List(U8) -> Command.Command
	vismember = |key, element| {
		Command.from_nonempty_bytes("VISMEMBER", [key, element])
	}

	## Construct `VLINKS`.
	## Available since Redis 8.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/vlinks/).
	## Parameters (in order): `key`, `element`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	vlinks : List(U8), List(U8), List(List(U8)) -> Command.Command
	vlinks = |key, element, options| {
		Command.from_nonempty_bytes("VLINKS", [key, element].concat(options))
	}

	## Construct `VRANDMEMBER`.
	## Available since Redis 8.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/vrandmember/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	vrandmember : List(U8), List(List(U8)) -> Command.Command
	vrandmember = |key, options| {
		Command.from_nonempty_bytes("VRANDMEMBER", [key].concat(options))
	}

	## Construct `VRANGE`.
	## Available since Redis 8.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/vrange/).
	## Parameters (in order): `key`, `start`, `end`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	vrange : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	vrange = |key, start, end, options| {
		Command.from_nonempty_bytes("VRANGE", [key, start, end].concat(options))
	}

	## Construct `VREM`.
	## Available since Redis 8.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/vrem/).
	## Parameters (in order): `key`, `element`.
	vrem : List(U8), List(U8) -> Command.Command
	vrem = |key, element| {
		Command.from_nonempty_bytes("VREM", [key, element])
	}

	## Construct `VSETATTR`.
	## Available since Redis 8.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/vsetattr/).
	## Parameters (in order): `key`, `element`, `json`.
	vsetattr : List(U8), List(U8), List(U8) -> Command.Command
	vsetattr = |key, element, json| {
		Command.from_nonempty_bytes("VSETATTR", [key, element, json])
	}

	## Construct `VSIM`.
	## Available since Redis 8.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/vsim/).
	## Parameters (in order): `key`, `query`, `options`.
	## `query` is `Element(element)`, `Fp32(blob)`, or `Values({ first, rest })`; the non-empty VALUES count is derived automatically.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	vsim : List(U8), [Element(List(U8)), Fp32(List(U8)), Values({ first : List(U8), rest : List(List(U8)) })], List(List(U8)) -> Command.Command
	vsim = |key, query, options| {
		encoded_query = match query {
			Element(element) => [['E', 'L', 'E'], element]
			Fp32(blob) => [['F', 'P', '3', '2'], blob]
			Values({ first, rest }) => {
				values = [first].concat(rest)
				[['V', 'A', 'L', 'U', 'E', 'S'], values.len().to_str().to_utf8()].concat(values)
			}
		}
		Command.from_nonempty_bytes("VSIM", [key].concat(encoded_query).concat(options))
	}
}

expect Command.encode(VectorSets.vadd([0, 1, 255], [[0, 2, 255], [0, 3, 255]], Fp32([0, 4, 255]), [0, 5, 255], [[0, 6, 255], [0, 7, 255]])) == ['*', '9', '\r', '\n', '$', '4', '\r', '\n', 'V', 'A', 'D', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '4', '\r', '\n', 'F', 'P', '3', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 7, 255, '\r', '\n']

expect Command.encode(VectorSets.vadd([0, 1, 255], [], Fp32([0, 4, 255]), [0, 5, 255], [])) == ['*', '5', '\r', '\n', '$', '4', '\r', '\n', 'V', 'A', 'D', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '4', '\r', '\n', 'F', 'P', '3', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(VectorSets.vadd([0, 240, 255], [], Values({ first: ['1', '.', '2', '5'], rest: [['-', '2', '.', '5']] }), [0, 241, 255], [])) == ['*', '7', '\r', '\n', '$', '4', '\r', '\n', 'V', 'A', 'D', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 240, 255, '\r', '\n', '$', '6', '\r', '\n', 'V', 'A', 'L', 'U', 'E', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '4', '\r', '\n', '1', '.', '2', '5', '\r', '\n', '$', '4', '\r', '\n', '-', '2', '.', '5', '\r', '\n', '$', '3', '\r', '\n', 0, 241, 255, '\r', '\n']

expect Command.encode(VectorSets.vcard([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '5', '\r', '\n', 'V', 'C', 'A', 'R', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(VectorSets.vdim([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'V', 'D', 'I', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(VectorSets.vemb([0, 1, 255], [0, 2, 255], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '4', '\r', '\n', 'V', 'E', 'M', 'B', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(VectorSets.vemb([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'V', 'E', 'M', 'B', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(VectorSets.vgetattr([0, 1, 255], [0, 2, 255])) == ['*', '3', '\r', '\n', '$', '8', '\r', '\n', 'V', 'G', 'E', 'T', 'A', 'T', 'T', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(VectorSets.vinfo([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '5', '\r', '\n', 'V', 'I', 'N', 'F', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(VectorSets.vismember([0, 1, 255], [0, 2, 255])) == ['*', '3', '\r', '\n', '$', '9', '\r', '\n', 'V', 'I', 'S', 'M', 'E', 'M', 'B', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(VectorSets.vlinks([0, 1, 255], [0, 2, 255], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'V', 'L', 'I', 'N', 'K', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(VectorSets.vlinks([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'V', 'L', 'I', 'N', 'K', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(VectorSets.vrandmember([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '1', '1', '\r', '\n', 'V', 'R', 'A', 'N', 'D', 'M', 'E', 'M', 'B', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(VectorSets.vrandmember([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '1', '1', '\r', '\n', 'V', 'R', 'A', 'N', 'D', 'M', 'E', 'M', 'B', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(VectorSets.vrange([0, 1, 255], [0, 2, 255], [0, 3, 255], [[0, 4, 255], [0, 5, 255]])) == ['*', '6', '\r', '\n', '$', '6', '\r', '\n', 'V', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(VectorSets.vrange([0, 1, 255], [0, 2, 255], [0, 3, 255], [])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'V', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(VectorSets.vrem([0, 1, 255], [0, 2, 255])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'V', 'R', 'E', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(VectorSets.vsetattr([0, 1, 255], [0, 2, 255], [0, 3, 255])) == ['*', '4', '\r', '\n', '$', '8', '\r', '\n', 'V', 'S', 'E', 'T', 'A', 'T', 'T', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(VectorSets.vsim([0, 1, 255], Element([0, 2, 255]), [[0, 3, 255], [0, 4, 255]])) == ['*', '6', '\r', '\n', '$', '4', '\r', '\n', 'V', 'S', 'I', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 'E', 'L', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(VectorSets.vsim([0, 1, 255], Element([0, 2, 255]), [])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'V', 'S', 'I', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 'E', 'L', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(VectorSets.vsim([0, 240, 255], Fp32([0, 1, 2, 3, 255]), [])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'V', 'S', 'I', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 240, 255, '\r', '\n', '$', '4', '\r', '\n', 'F', 'P', '3', '2', '\r', '\n', '$', '5', '\r', '\n', 0, 1, 2, 3, 255, '\r', '\n']

expect Command.encode(VectorSets.vsim([0, 240, 255], Values({ first: ['1', '.', '2', '5'], rest: [['-', '2', '.', '5']] }), [])) == ['*', '6', '\r', '\n', '$', '4', '\r', '\n', 'V', 'S', 'I', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 240, 255, '\r', '\n', '$', '6', '\r', '\n', 'V', 'A', 'L', 'U', 'E', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '4', '\r', '\n', '1', '.', '2', '5', '\r', '\n', '$', '4', '\r', '\n', '-', '2', '.', '5', '\r', '\n']
