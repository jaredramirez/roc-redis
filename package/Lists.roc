import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 List command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
Lists := {}.{

	## Construct `BLMOVE`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/blmove/).
	## Parameters (in order): `source`, `destination`, `wherefrom`, `whereto`, `timeout`.
	blmove : List(U8), List(U8), List(U8), List(U8), List(U8) -> Command.Command
	blmove = |source, destination, wherefrom, whereto, timeout| {
		Command.from_nonempty_bytes("BLMOVE", [source, destination, wherefrom, whereto, timeout])
	}

	## Construct `BLMOVEM`.
	## Available since Redis 8.10.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/blmovem/).
	## Parameters (in order): `source`, `destination`, `wherefrom`, `whereto`, `timeout`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	blmovem : List(U8), List(U8), List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	blmovem = |source, destination, wherefrom, whereto, timeout, options| {
		Command.from_nonempty_bytes("BLMOVEM", [source, destination, wherefrom, whereto, timeout].concat(options))
	}

	## Construct `BLMPOP`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/blmpop/).
	## Parameters (in order): `timeout`, `first_key`, `other_keys`, `where_`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	blmpop : List(U8), List(U8), List(List(U8)), List(U8), List(List(U8)) -> Command.Command
	blmpop = |timeout, first_key, other_keys, where_, options| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("BLMPOP", [timeout].concat([catalog_keys.len().to_str().to_utf8()].concat(catalog_keys)).concat([where_]).concat(options))
	}

	## Construct `BLPOP`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/blpop/).
	## Parameters (in order): `first_key`, `other_keys`, `timeout`.
	blpop : List(U8), List(List(U8)), List(U8) -> Command.Command
	blpop = |first_key, other_keys, timeout| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("BLPOP", catalog_keys.concat([timeout]))
	}

	## Construct `BRPOP`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/brpop/).
	## Parameters (in order): `first_key`, `other_keys`, `timeout`.
	brpop : List(U8), List(List(U8)), List(U8) -> Command.Command
	brpop = |first_key, other_keys, timeout| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("BRPOP", catalog_keys.concat([timeout]))
	}

	## Construct `BRPOPLPUSH`.
	## Available since Redis 2.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/brpoplpush/).
	## Parameters (in order): `source`, `destination`, `timeout`.
	## Deprecated by Redis; retained for catalog completeness.
	brpoplpush : List(U8), List(U8), List(U8) -> Command.Command
	brpoplpush = |source, destination, timeout| {
		Command.from_nonempty_bytes("BRPOPLPUSH", [source, destination, timeout])
	}

	## Construct `LINDEX`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/lindex/).
	## Parameters (in order): `key`, `index`.
	lindex : List(U8), List(U8) -> Command.Command
	lindex = |key, index| {
		Command.from_nonempty_bytes("LINDEX", [key, index])
	}

	## Construct `LINSERT`.
	## Available since Redis 2.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/linsert/).
	## Parameters (in order): `key`, `where_`, `pivot`, `element`.
	linsert : List(U8), List(U8), List(U8), List(U8) -> Command.Command
	linsert = |key, where_, pivot, element| {
		Command.from_nonempty_bytes("LINSERT", [key, where_, pivot, element])
	}

	## Construct `LLEN`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/llen/).
	## Parameters (in order): `key`.
	llen : List(U8) -> Command.Command
	llen = |key| {
		Command.from_nonempty_bytes("LLEN", [key])
	}

	## Construct `LMOVE`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/lmove/).
	## Parameters (in order): `source`, `destination`, `wherefrom`, `whereto`.
	lmove : List(U8), List(U8), List(U8), List(U8) -> Command.Command
	lmove = |source, destination, wherefrom, whereto| {
		Command.from_nonempty_bytes("LMOVE", [source, destination, wherefrom, whereto])
	}

	## Construct `LMOVEM`.
	## Available since Redis 8.10.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/lmovem/).
	## Parameters (in order): `source`, `destination`, `wherefrom`, `whereto`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	lmovem : List(U8), List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	lmovem = |source, destination, wherefrom, whereto, options| {
		Command.from_nonempty_bytes("LMOVEM", [source, destination, wherefrom, whereto].concat(options))
	}

	## Construct `LMPOP`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/lmpop/).
	## Parameters (in order): `first_key`, `other_keys`, `where_`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	lmpop : List(U8), List(List(U8)), List(U8), List(List(U8)) -> Command.Command
	lmpop = |first_key, other_keys, where_, options| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("LMPOP", [catalog_keys.len().to_str().to_utf8()].concat(catalog_keys).concat([where_]).concat(options))
	}

	## Construct `LPOP`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/lpop/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	lpop : List(U8), List(List(U8)) -> Command.Command
	lpop = |key, options| {
		Command.from_nonempty_bytes("LPOP", [key].concat(options))
	}

	## Construct `LPOS`.
	## Available since Redis 6.0.6.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/lpos/).
	## Parameters (in order): `key`, `element`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	lpos : List(U8), List(U8), List(List(U8)) -> Command.Command
	lpos = |key, element, options| {
		Command.from_nonempty_bytes("LPOS", [key, element].concat(options))
	}

	## Construct `LPUSH`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/lpush/).
	## Parameters (in order): `key`, `first_element`, `other_elements`.
	lpush : List(U8), List(U8), List(List(U8)) -> Command.Command
	lpush = |key, first_element, other_elements| {
		catalog_elements = [first_element].concat(other_elements)
		Command.from_nonempty_bytes("LPUSH", [key].concat(catalog_elements))
	}

	## Construct `LPUSHX`.
	## Available since Redis 2.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/lpushx/).
	## Parameters (in order): `key`, `first_element`, `other_elements`.
	lpushx : List(U8), List(U8), List(List(U8)) -> Command.Command
	lpushx = |key, first_element, other_elements| {
		catalog_elements = [first_element].concat(other_elements)
		Command.from_nonempty_bytes("LPUSHX", [key].concat(catalog_elements))
	}

	## Construct `LRANGE`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/lrange/).
	## Parameters (in order): `key`, `start`, `stop`.
	lrange : List(U8), List(U8), List(U8) -> Command.Command
	lrange = |key, start, stop| {
		Command.from_nonempty_bytes("LRANGE", [key, start, stop])
	}

	## Construct `LREM`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/lrem/).
	## Parameters (in order): `key`, `count`, `element`.
	lrem : List(U8), List(U8), List(U8) -> Command.Command
	lrem = |key, count, element| {
		Command.from_nonempty_bytes("LREM", [key, count, element])
	}

	## Construct `LSET`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/lset/).
	## Parameters (in order): `key`, `index`, `element`.
	lset : List(U8), List(U8), List(U8) -> Command.Command
	lset = |key, index, element| {
		Command.from_nonempty_bytes("LSET", [key, index, element])
	}

	## Construct `LTRIM`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/ltrim/).
	## Parameters (in order): `key`, `start`, `stop`.
	ltrim : List(U8), List(U8), List(U8) -> Command.Command
	ltrim = |key, start, stop| {
		Command.from_nonempty_bytes("LTRIM", [key, start, stop])
	}

	## Construct `RPOP`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/rpop/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	rpop : List(U8), List(List(U8)) -> Command.Command
	rpop = |key, options| {
		Command.from_nonempty_bytes("RPOP", [key].concat(options))
	}

	## Construct `RPOPLPUSH`.
	## Available since Redis 1.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/rpoplpush/).
	## Parameters (in order): `source`, `destination`.
	## Deprecated by Redis; retained for catalog completeness.
	rpoplpush : List(U8), List(U8) -> Command.Command
	rpoplpush = |source, destination| {
		Command.from_nonempty_bytes("RPOPLPUSH", [source, destination])
	}

	## Construct `RPUSH`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/rpush/).
	## Parameters (in order): `key`, `first_element`, `other_elements`.
	rpush : List(U8), List(U8), List(List(U8)) -> Command.Command
	rpush = |key, first_element, other_elements| {
		catalog_elements = [first_element].concat(other_elements)
		Command.from_nonempty_bytes("RPUSH", [key].concat(catalog_elements))
	}

	## Construct `RPUSHX`.
	## Available since Redis 2.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/rpushx/).
	## Parameters (in order): `key`, `first_element`, `other_elements`.
	rpushx : List(U8), List(U8), List(List(U8)) -> Command.Command
	rpushx = |key, first_element, other_elements| {
		catalog_elements = [first_element].concat(other_elements)
		Command.from_nonempty_bytes("RPUSHX", [key].concat(catalog_elements))
	}
}

expect Command.encode(Lists.blmove([0, 1, 255], [0, 2, 255], ['L', 'E', 'F', 'T'], ['L', 'E', 'F', 'T'], ['3', '.', '5'])) == ['*', '6', '\r', '\n', '$', '6', '\r', '\n', 'B', 'L', 'M', 'O', 'V', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '4', '\r', '\n', 'L', 'E', 'F', 'T', '\r', '\n', '$', '4', '\r', '\n', 'L', 'E', 'F', 'T', '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n']

expect Command.encode(Lists.blmovem([0, 1, 255], [0, 2, 255], ['L', 'E', 'F', 'T'], ['L', 'E', 'F', 'T'], ['3', '.', '5'], [[0, 4, 255], [0, 5, 255]])) == ['*', '8', '\r', '\n', '$', '7', '\r', '\n', 'B', 'L', 'M', 'O', 'V', 'E', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '4', '\r', '\n', 'L', 'E', 'F', 'T', '\r', '\n', '$', '4', '\r', '\n', 'L', 'E', 'F', 'T', '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Lists.blmovem([0, 1, 255], [0, 2, 255], ['L', 'E', 'F', 'T'], ['L', 'E', 'F', 'T'], ['3', '.', '5'], [])) == ['*', '6', '\r', '\n', '$', '7', '\r', '\n', 'B', 'L', 'M', 'O', 'V', 'E', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '4', '\r', '\n', 'L', 'E', 'F', 'T', '\r', '\n', '$', '4', '\r', '\n', 'L', 'E', 'F', 'T', '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n']

expect Command.encode(Lists.blmpop(['1', '.', '5'], [0, 2, 255], [[0, 3, 255]], ['L', 'E', 'F', 'T'], [[0, 4, 255], [0, 5, 255]])) == ['*', '8', '\r', '\n', '$', '6', '\r', '\n', 'B', 'L', 'M', 'P', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', '1', '.', '5', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '4', '\r', '\n', 'L', 'E', 'F', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Lists.blmpop(['1', '.', '5'], [0, 2, 255], [], ['L', 'E', 'F', 'T'], [])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'B', 'L', 'M', 'P', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', '1', '.', '5', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '4', '\r', '\n', 'L', 'E', 'F', 'T', '\r', '\n']

expect Command.encode(Lists.blpop([0, 1, 255], [[0, 2, 255]], ['3', '.', '5'])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'B', 'L', 'P', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n']

expect Command.encode(Lists.blpop([0, 1, 255], [], ['3', '.', '5'])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'B', 'L', 'P', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n']

expect Command.encode(Lists.brpop([0, 1, 255], [[0, 2, 255]], ['3', '.', '5'])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'B', 'R', 'P', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n']

expect Command.encode(Lists.brpop([0, 1, 255], [], ['3', '.', '5'])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'B', 'R', 'P', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n']

expect Command.encode(Lists.brpoplpush([0, 1, 255], [0, 2, 255], ['3', '.', '5'])) == ['*', '4', '\r', '\n', '$', '1', '0', '\r', '\n', 'B', 'R', 'P', 'O', 'P', 'L', 'P', 'U', 'S', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n']

expect Command.encode(Lists.lindex([0, 1, 255], ['2'])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'L', 'I', 'N', 'D', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Lists.linsert([0, 1, 255], ['B', 'E', 'F', 'O', 'R', 'E'], [0, 2, 255], [0, 3, 255])) == ['*', '5', '\r', '\n', '$', '7', '\r', '\n', 'L', 'I', 'N', 'S', 'E', 'R', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'B', 'E', 'F', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Lists.llen([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'L', 'L', 'E', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Lists.lmove([0, 1, 255], [0, 2, 255], ['L', 'E', 'F', 'T'], ['L', 'E', 'F', 'T'])) == ['*', '5', '\r', '\n', '$', '5', '\r', '\n', 'L', 'M', 'O', 'V', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '4', '\r', '\n', 'L', 'E', 'F', 'T', '\r', '\n', '$', '4', '\r', '\n', 'L', 'E', 'F', 'T', '\r', '\n']

expect Command.encode(Lists.lmovem([0, 1, 255], [0, 2, 255], ['L', 'E', 'F', 'T'], ['L', 'E', 'F', 'T'], [[0, 3, 255], [0, 4, 255]])) == ['*', '7', '\r', '\n', '$', '6', '\r', '\n', 'L', 'M', 'O', 'V', 'E', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '4', '\r', '\n', 'L', 'E', 'F', 'T', '\r', '\n', '$', '4', '\r', '\n', 'L', 'E', 'F', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Lists.lmovem([0, 1, 255], [0, 2, 255], ['L', 'E', 'F', 'T'], ['L', 'E', 'F', 'T'], [])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'L', 'M', 'O', 'V', 'E', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '4', '\r', '\n', 'L', 'E', 'F', 'T', '\r', '\n', '$', '4', '\r', '\n', 'L', 'E', 'F', 'T', '\r', '\n']

expect Command.encode(Lists.lmpop([0, 1, 255], [[0, 2, 255]], ['L', 'E', 'F', 'T'], [[0, 3, 255], [0, 4, 255]])) == ['*', '7', '\r', '\n', '$', '5', '\r', '\n', 'L', 'M', 'P', 'O', 'P', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '4', '\r', '\n', 'L', 'E', 'F', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Lists.lmpop([0, 1, 255], [], ['L', 'E', 'F', 'T'], [])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'L', 'M', 'P', 'O', 'P', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '4', '\r', '\n', 'L', 'E', 'F', 'T', '\r', '\n']

expect Command.encode(Lists.lpop([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'L', 'P', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Lists.lpop([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'L', 'P', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Lists.lpos([0, 1, 255], [0, 2, 255], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '4', '\r', '\n', 'L', 'P', 'O', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Lists.lpos([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'L', 'P', 'O', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Lists.lpush([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'L', 'P', 'U', 'S', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Lists.lpush([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'L', 'P', 'U', 'S', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Lists.lpushx([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'L', 'P', 'U', 'S', 'H', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Lists.lpushx([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'L', 'P', 'U', 'S', 'H', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Lists.lrange([0, 1, 255], ['2'], ['3'])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'L', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n']

expect Command.encode(Lists.lrem([0, 1, 255], ['2'], [0, 3, 255])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'L', 'R', 'E', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Lists.lset([0, 1, 255], ['2'], [0, 3, 255])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'L', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Lists.ltrim([0, 1, 255], ['2'], ['3'])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'L', 'T', 'R', 'I', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n']

expect Command.encode(Lists.rpop([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'R', 'P', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Lists.rpop([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'R', 'P', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Lists.rpoplpush([0, 1, 255], [0, 2, 255])) == ['*', '3', '\r', '\n', '$', '9', '\r', '\n', 'R', 'P', 'O', 'P', 'L', 'P', 'U', 'S', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Lists.rpush([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'R', 'P', 'U', 'S', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Lists.rpush([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'R', 'P', 'U', 'S', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Lists.rpushx([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'R', 'P', 'U', 'S', 'H', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Lists.rpushx([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'R', 'P', 'U', 'S', 'H', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']
