import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 Hyperloglog command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
HyperLogLog := {}.{

	## Construct `PFADD`.
	## Available since Redis 2.8.9.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/pfadd/).
	## Parameters (in order): `key`, `elements`.
	pfadd : List(U8), List(List(U8)) -> Command.Command
	pfadd = |key, elements| {
		Command.from_nonempty_bytes("PFADD", [key].concat(elements))
	}

	## Construct `PFCOUNT`.
	## Available since Redis 2.8.9.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/pfcount/).
	## Parameters (in order): `first_key`, `other_keys`.
	pfcount : List(U8), List(List(U8)) -> Command.Command
	pfcount = |first_key, other_keys| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("PFCOUNT", catalog_keys)
	}

	## Construct `PFMERGE`.
	## Available since Redis 2.8.9.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/pfmerge/).
	## Parameters (in order): `destkey`, `sourcekeys`.
	pfmerge : List(U8), List(List(U8)) -> Command.Command
	pfmerge = |destkey, sourcekeys| {
		Command.from_nonempty_bytes("PFMERGE", [destkey].concat(sourcekeys))
	}
}

expect Command.encode(HyperLogLog.pfadd([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'P', 'F', 'A', 'D', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(HyperLogLog.pfadd([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '5', '\r', '\n', 'P', 'F', 'A', 'D', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(HyperLogLog.pfcount([0, 1, 255], [[0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'P', 'F', 'C', 'O', 'U', 'N', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(HyperLogLog.pfcount([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'P', 'F', 'C', 'O', 'U', 'N', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(HyperLogLog.pfmerge([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'P', 'F', 'M', 'E', 'R', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(HyperLogLog.pfmerge([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'P', 'F', 'M', 'E', 'R', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']
