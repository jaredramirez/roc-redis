import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 Set command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
Sets := {}.{

	## Construct `SADD`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/sadd/).
	## Parameters (in order): `key`, `first_member`, `other_members`.
	sadd : List(U8), List(U8), List(List(U8)) -> Command.Command
	sadd = |key, first_member, other_members| {
		catalog_members = [first_member].concat(other_members)
		Command.from_nonempty_bytes("SADD", [key].concat(catalog_members))
	}

	## Construct `SCARD`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/scard/).
	## Parameters (in order): `key`.
	scard : List(U8) -> Command.Command
	scard = |key| {
		Command.from_nonempty_bytes("SCARD", [key])
	}

	## Construct `SDIFF`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/sdiff/).
	## Parameters (in order): `first_key`, `other_keys`.
	sdiff : List(U8), List(List(U8)) -> Command.Command
	sdiff = |first_key, other_keys| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("SDIFF", catalog_keys)
	}

	## Construct `SDIFFCARD`.
	## Available since Redis 8.10.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/sdiffcard/).
	## Parameters (in order): `first_key`, `other_keys`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	sdiffcard : List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	sdiffcard = |first_key, other_keys, options| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("SDIFFCARD", [catalog_keys.len().to_str().to_utf8()].concat(catalog_keys).concat(options))
	}

	## Construct `SDIFFSTORE`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/sdiffstore/).
	## Parameters (in order): `destination`, `first_key`, `other_keys`.
	sdiffstore : List(U8), List(U8), List(List(U8)) -> Command.Command
	sdiffstore = |destination, first_key, other_keys| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("SDIFFSTORE", [destination].concat(catalog_keys))
	}

	## Construct `SINTER`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/sinter/).
	## Parameters (in order): `first_key`, `other_keys`.
	sinter : List(U8), List(List(U8)) -> Command.Command
	sinter = |first_key, other_keys| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("SINTER", catalog_keys)
	}

	## Construct `SINTERCARD`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/sintercard/).
	## Parameters (in order): `first_key`, `other_keys`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	sintercard : List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	sintercard = |first_key, other_keys, options| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("SINTERCARD", [catalog_keys.len().to_str().to_utf8()].concat(catalog_keys).concat(options))
	}

	## Construct `SINTERSTORE`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/sinterstore/).
	## Parameters (in order): `destination`, `first_key`, `other_keys`.
	sinterstore : List(U8), List(U8), List(List(U8)) -> Command.Command
	sinterstore = |destination, first_key, other_keys| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("SINTERSTORE", [destination].concat(catalog_keys))
	}

	## Construct `SISMEMBER`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/sismember/).
	## Parameters (in order): `key`, `member`.
	sismember : List(U8), List(U8) -> Command.Command
	sismember = |key, member| {
		Command.from_nonempty_bytes("SISMEMBER", [key, member])
	}

	## Construct `SMEMBERS`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/smembers/).
	## Parameters (in order): `key`.
	smembers : List(U8) -> Command.Command
	smembers = |key| {
		Command.from_nonempty_bytes("SMEMBERS", [key])
	}

	## Construct `SMISMEMBER`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/smismember/).
	## Parameters (in order): `key`, `first_member`, `other_members`.
	smismember : List(U8), List(U8), List(List(U8)) -> Command.Command
	smismember = |key, first_member, other_members| {
		catalog_members = [first_member].concat(other_members)
		Command.from_nonempty_bytes("SMISMEMBER", [key].concat(catalog_members))
	}

	## Construct `SMOVE`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/smove/).
	## Parameters (in order): `source`, `destination`, `member`.
	smove : List(U8), List(U8), List(U8) -> Command.Command
	smove = |source, destination, member| {
		Command.from_nonempty_bytes("SMOVE", [source, destination, member])
	}

	## Construct `SPOP`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/spop/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	spop : List(U8), List(List(U8)) -> Command.Command
	spop = |key, options| {
		Command.from_nonempty_bytes("SPOP", [key].concat(options))
	}

	## Construct `SRANDMEMBER`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/srandmember/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	srandmember : List(U8), List(List(U8)) -> Command.Command
	srandmember = |key, options| {
		Command.from_nonempty_bytes("SRANDMEMBER", [key].concat(options))
	}

	## Construct `SREM`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/srem/).
	## Parameters (in order): `key`, `first_member`, `other_members`.
	srem : List(U8), List(U8), List(List(U8)) -> Command.Command
	srem = |key, first_member, other_members| {
		catalog_members = [first_member].concat(other_members)
		Command.from_nonempty_bytes("SREM", [key].concat(catalog_members))
	}

	## Construct `SSCAN`.
	## Available since Redis 2.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/sscan/).
	## Parameters (in order): `key`, `cursor`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	sscan : List(U8), List(U8), List(List(U8)) -> Command.Command
	sscan = |key, cursor, options| {
		Command.from_nonempty_bytes("SSCAN", [key, cursor].concat(options))
	}

	## Construct `SUNION`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/sunion/).
	## Parameters (in order): `first_key`, `other_keys`.
	sunion : List(U8), List(List(U8)) -> Command.Command
	sunion = |first_key, other_keys| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("SUNION", catalog_keys)
	}

	## Construct `SUNIONCARD`.
	## Available since Redis 8.10.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/sunioncard/).
	## Parameters (in order): `first_key`, `other_keys`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	sunioncard : List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	sunioncard = |first_key, other_keys, options| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("SUNIONCARD", [catalog_keys.len().to_str().to_utf8()].concat(catalog_keys).concat(options))
	}

	## Construct `SUNIONSTORE`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/sunionstore/).
	## Parameters (in order): `destination`, `first_key`, `other_keys`.
	sunionstore : List(U8), List(U8), List(List(U8)) -> Command.Command
	sunionstore = |destination, first_key, other_keys| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("SUNIONSTORE", [destination].concat(catalog_keys))
	}
}

expect Command.encode(Sets.sadd([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'S', 'A', 'D', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Sets.sadd([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'S', 'A', 'D', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Sets.scard([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '5', '\r', '\n', 'S', 'C', 'A', 'R', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Sets.sdiff([0, 1, 255], [[0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'S', 'D', 'I', 'F', 'F', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Sets.sdiff([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '5', '\r', '\n', 'S', 'D', 'I', 'F', 'F', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Sets.sdiffcard([0, 1, 255], [[0, 2, 255]], [[0, 3, 255], [0, 4, 255]])) == ['*', '6', '\r', '\n', '$', '9', '\r', '\n', 'S', 'D', 'I', 'F', 'F', 'C', 'A', 'R', 'D', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Sets.sdiffcard([0, 1, 255], [], [])) == ['*', '3', '\r', '\n', '$', '9', '\r', '\n', 'S', 'D', 'I', 'F', 'F', 'C', 'A', 'R', 'D', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Sets.sdiffstore([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '1', '0', '\r', '\n', 'S', 'D', 'I', 'F', 'F', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Sets.sdiffstore([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '1', '0', '\r', '\n', 'S', 'D', 'I', 'F', 'F', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Sets.sinter([0, 1, 255], [[0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'S', 'I', 'N', 'T', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Sets.sinter([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'S', 'I', 'N', 'T', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Sets.sintercard([0, 1, 255], [[0, 2, 255]], [[0, 3, 255], [0, 4, 255]])) == ['*', '6', '\r', '\n', '$', '1', '0', '\r', '\n', 'S', 'I', 'N', 'T', 'E', 'R', 'C', 'A', 'R', 'D', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Sets.sintercard([0, 1, 255], [], [])) == ['*', '3', '\r', '\n', '$', '1', '0', '\r', '\n', 'S', 'I', 'N', 'T', 'E', 'R', 'C', 'A', 'R', 'D', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Sets.sinterstore([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '1', '1', '\r', '\n', 'S', 'I', 'N', 'T', 'E', 'R', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Sets.sinterstore([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '1', '1', '\r', '\n', 'S', 'I', 'N', 'T', 'E', 'R', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Sets.sismember([0, 1, 255], [0, 2, 255])) == ['*', '3', '\r', '\n', '$', '9', '\r', '\n', 'S', 'I', 'S', 'M', 'E', 'M', 'B', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Sets.smembers([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '8', '\r', '\n', 'S', 'M', 'E', 'M', 'B', 'E', 'R', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Sets.smismember([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '1', '0', '\r', '\n', 'S', 'M', 'I', 'S', 'M', 'E', 'M', 'B', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Sets.smismember([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '1', '0', '\r', '\n', 'S', 'M', 'I', 'S', 'M', 'E', 'M', 'B', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Sets.smove([0, 1, 255], [0, 2, 255], [0, 3, 255])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'S', 'M', 'O', 'V', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Sets.spop([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'S', 'P', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Sets.spop([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'S', 'P', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Sets.srandmember([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '1', '1', '\r', '\n', 'S', 'R', 'A', 'N', 'D', 'M', 'E', 'M', 'B', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Sets.srandmember([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '1', '1', '\r', '\n', 'S', 'R', 'A', 'N', 'D', 'M', 'E', 'M', 'B', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Sets.srem([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'S', 'R', 'E', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Sets.srem([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'S', 'R', 'E', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Sets.sscan([0, 1, 255], ['2'], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '5', '\r', '\n', 'S', 'S', 'C', 'A', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Sets.sscan([0, 1, 255], ['2'], [])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'S', 'S', 'C', 'A', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Sets.sunion([0, 1, 255], [[0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'S', 'U', 'N', 'I', 'O', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Sets.sunion([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'S', 'U', 'N', 'I', 'O', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Sets.sunioncard([0, 1, 255], [[0, 2, 255]], [[0, 3, 255], [0, 4, 255]])) == ['*', '6', '\r', '\n', '$', '1', '0', '\r', '\n', 'S', 'U', 'N', 'I', 'O', 'N', 'C', 'A', 'R', 'D', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Sets.sunioncard([0, 1, 255], [], [])) == ['*', '3', '\r', '\n', '$', '1', '0', '\r', '\n', 'S', 'U', 'N', 'I', 'O', 'N', 'C', 'A', 'R', 'D', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Sets.sunionstore([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '1', '1', '\r', '\n', 'S', 'U', 'N', 'I', 'O', 'N', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Sets.sunionstore([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '1', '1', '\r', '\n', 'S', 'U', 'N', 'I', 'O', 'N', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']
