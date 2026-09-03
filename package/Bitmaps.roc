import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 Bitmap command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
Bitmaps := {}.{

	## Construct `BITCOUNT`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/bitcount/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	bitcount : List(U8), List(List(U8)) -> Command.Command
	bitcount = |key, options| {
		Command.from_nonempty_bytes("BITCOUNT", [key].concat(options))
	}

	## Construct `BITFIELD`.
	## Available since Redis 3.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/bitfield/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	bitfield : List(U8), List(List(U8)) -> Command.Command
	bitfield = |key, options| {
		Command.from_nonempty_bytes("BITFIELD", [key].concat(options))
	}

	## Construct `BITFIELD_RO`.
	## Available since Redis 6.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/bitfield_ro/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	bitfield_ro : List(U8), List(List(U8)) -> Command.Command
	bitfield_ro = |key, options| {
		Command.from_nonempty_bytes("BITFIELD_RO", [key].concat(options))
	}

	## Construct `BITOP`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/bitop/).
	## Parameters (in order): `operation`, `destkey`, `first_key`, `other_keys`.
	bitop : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	bitop = |operation, destkey, first_key, other_keys| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("BITOP", [operation, destkey].concat(catalog_keys))
	}

	## Construct `BITPOS`.
	## Available since Redis 2.8.7.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/bitpos/).
	## Parameters (in order): `key`, `bit`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	bitpos : List(U8), List(U8), List(List(U8)) -> Command.Command
	bitpos = |key, bit, options| {
		Command.from_nonempty_bytes("BITPOS", [key, bit].concat(options))
	}

	## Construct `GETBIT`.
	## Available since Redis 2.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/getbit/).
	## Parameters (in order): `key`, `offset`.
	getbit : List(U8), List(U8) -> Command.Command
	getbit = |key, offset| {
		Command.from_nonempty_bytes("GETBIT", [key, offset])
	}

	## Construct `SETBIT`.
	## Available since Redis 2.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/setbit/).
	## Parameters (in order): `key`, `offset`, `value`.
	setbit : List(U8), List(U8), List(U8) -> Command.Command
	setbit = |key, offset, value| {
		Command.from_nonempty_bytes("SETBIT", [key, offset, value])
	}
}

expect Command.encode(Bitmaps.bitcount([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '8', '\r', '\n', 'B', 'I', 'T', 'C', 'O', 'U', 'N', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Bitmaps.bitcount([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '8', '\r', '\n', 'B', 'I', 'T', 'C', 'O', 'U', 'N', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Bitmaps.bitfield([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '8', '\r', '\n', 'B', 'I', 'T', 'F', 'I', 'E', 'L', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Bitmaps.bitfield([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '8', '\r', '\n', 'B', 'I', 'T', 'F', 'I', 'E', 'L', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Bitmaps.bitfield_ro([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '1', '1', '\r', '\n', 'B', 'I', 'T', 'F', 'I', 'E', 'L', 'D', '_', 'R', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Bitmaps.bitfield_ro([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '1', '1', '\r', '\n', 'B', 'I', 'T', 'F', 'I', 'E', 'L', 'D', '_', 'R', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Bitmaps.bitop(['A', 'N', 'D'], [0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '5', '\r', '\n', '$', '5', '\r', '\n', 'B', 'I', 'T', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', 'A', 'N', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Bitmaps.bitop(['A', 'N', 'D'], [0, 1, 255], [0, 2, 255], [])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'B', 'I', 'T', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', 'A', 'N', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Bitmaps.bitpos([0, 1, 255], ['2'], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'B', 'I', 'T', 'P', 'O', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Bitmaps.bitpos([0, 1, 255], ['2'], [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'B', 'I', 'T', 'P', 'O', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Bitmaps.getbit([0, 1, 255], ['2'])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'G', 'E', 'T', 'B', 'I', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Bitmaps.setbit([0, 1, 255], ['2'], ['3'])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'S', 'E', 'T', 'B', 'I', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n']
