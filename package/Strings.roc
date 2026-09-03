import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 String command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
Strings := {}.{

	## Construct `APPEND`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/append/).
	## Parameters (in order): `key`, `value`.
	append : List(U8), List(U8) -> Command.Command
	append = |key, value| {
		Command.from_nonempty_bytes("APPEND", [key, value])
	}

	## Construct `DECR`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/decr/).
	## Parameters (in order): `key`.
	decr : List(U8) -> Command.Command
	decr = |key| {
		Command.from_nonempty_bytes("DECR", [key])
	}

	## Construct `DECRBY`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/decrby/).
	## Parameters (in order): `key`, `decrement`.
	decrby : List(U8), List(U8) -> Command.Command
	decrby = |key, decrement| {
		Command.from_nonempty_bytes("DECRBY", [key, decrement])
	}

	## Construct `DELEX`.
	## Available since Redis 8.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/delex/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	delex : List(U8), List(List(U8)) -> Command.Command
	delex = |key, options| {
		Command.from_nonempty_bytes("DELEX", [key].concat(options))
	}

	## Construct `DIGEST`.
	## Available since Redis 8.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/digest/).
	## Parameters (in order): `key`.
	digest : List(U8) -> Command.Command
	digest = |key| {
		Command.from_nonempty_bytes("DIGEST", [key])
	}

	## Construct `GET`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/get/).
	## Parameters (in order): `key`.
	get : List(U8) -> Command.Command
	get = |key| {
		Command.from_nonempty_bytes("GET", [key])
	}

	## Construct `GETDEL`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/getdel/).
	## Parameters (in order): `key`.
	getdel : List(U8) -> Command.Command
	getdel = |key| {
		Command.from_nonempty_bytes("GETDEL", [key])
	}

	## Construct `GETEX`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/getex/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	getex : List(U8), List(List(U8)) -> Command.Command
	getex = |key, options| {
		Command.from_nonempty_bytes("GETEX", [key].concat(options))
	}

	## Construct `GETRANGE`.
	## Available since Redis 2.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/getrange/).
	## Parameters (in order): `key`, `start`, `end`.
	getrange : List(U8), List(U8), List(U8) -> Command.Command
	getrange = |key, start, end| {
		Command.from_nonempty_bytes("GETRANGE", [key, start, end])
	}

	## Construct `GETSET`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/getset/).
	## Parameters (in order): `key`, `value`.
	## Deprecated by Redis; retained for catalog completeness.
	getset : List(U8), List(U8) -> Command.Command
	getset = |key, value| {
		Command.from_nonempty_bytes("GETSET", [key, value])
	}

	## Construct `INCR`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/incr/).
	## Parameters (in order): `key`.
	incr : List(U8) -> Command.Command
	incr = |key| {
		Command.from_nonempty_bytes("INCR", [key])
	}

	## Construct `INCRBY`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/incrby/).
	## Parameters (in order): `key`, `increment`.
	incrby : List(U8), List(U8) -> Command.Command
	incrby = |key, increment| {
		Command.from_nonempty_bytes("INCRBY", [key, increment])
	}

	## Construct `INCRBYFLOAT`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/incrbyfloat/).
	## Parameters (in order): `key`, `increment`.
	incrbyfloat : List(U8), List(U8) -> Command.Command
	incrbyfloat = |key, increment| {
		Command.from_nonempty_bytes("INCRBYFLOAT", [key, increment])
	}

	## Construct `INCREX`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/increx/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	increx : List(U8), List(List(U8)) -> Command.Command
	increx = |key, options| {
		Command.from_nonempty_bytes("INCREX", [key].concat(options))
	}

	## Construct `LCS`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/lcs/).
	## Parameters (in order): `key1`, `key2`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	lcs : List(U8), List(U8), List(List(U8)) -> Command.Command
	lcs = |key1, key2, options| {
		Command.from_nonempty_bytes("LCS", [key1, key2].concat(options))
	}

	## Construct `MGET`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/mget/).
	## Parameters (in order): `first_key`, `other_keys`.
	mget : List(U8), List(List(U8)) -> Command.Command
	mget = |first_key, other_keys| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("MGET", catalog_keys)
	}

	## Construct `MSET`.
	## Available since Redis 1.0.1.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/mset/).
	## Parameters (in order): `first_entry`, `other_entries`.
	mset : { key : List(U8), value : List(U8) }, List({ key : List(U8), value : List(U8) }) -> Command.Command
	mset = |first_entry, other_entries| {
		catalog_entries = [first_entry].concat(other_entries)
		Command.from_nonempty_bytes("MSET", catalog_entries.join_map(|item| [item.key, item.value]))
	}

	## Construct `MSETEX`.
	## Available since Redis 8.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/msetex/).
	## Parameters (in order): `first_entry`, `other_entries`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	msetex : { key : List(U8), value : List(U8) }, List({ key : List(U8), value : List(U8) }), List(List(U8)) -> Command.Command
	msetex = |first_entry, other_entries, options| {
		catalog_entries = [first_entry].concat(other_entries)
		Command.from_nonempty_bytes("MSETEX", [catalog_entries.len().to_str().to_utf8()].concat(catalog_entries.join_map(|item| [item.key, item.value])).concat(options))
	}

	## Construct `MSETNX`.
	## Available since Redis 1.0.1.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/msetnx/).
	## Parameters (in order): `first_entry`, `other_entries`.
	msetnx : { key : List(U8), value : List(U8) }, List({ key : List(U8), value : List(U8) }) -> Command.Command
	msetnx = |first_entry, other_entries| {
		catalog_entries = [first_entry].concat(other_entries)
		Command.from_nonempty_bytes("MSETNX", catalog_entries.join_map(|item| [item.key, item.value]))
	}

	## Construct `PSETEX`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/psetex/).
	## Parameters (in order): `key`, `milliseconds`, `value`.
	## Deprecated by Redis; retained for catalog completeness.
	psetex : List(U8), List(U8), List(U8) -> Command.Command
	psetex = |key, milliseconds, value| {
		Command.from_nonempty_bytes("PSETEX", [key, milliseconds, value])
	}

	## Construct `SET`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/set/).
	## Parameters (in order): `key`, `value`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	set : List(U8), List(U8), List(List(U8)) -> Command.Command
	set = |key, value, options| {
		Command.from_nonempty_bytes("SET", [key, value].concat(options))
	}

	## Construct `SETEX`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/setex/).
	## Parameters (in order): `key`, `seconds`, `value`.
	## Deprecated by Redis; retained for catalog completeness.
	setex : List(U8), List(U8), List(U8) -> Command.Command
	setex = |key, seconds, value| {
		Command.from_nonempty_bytes("SETEX", [key, seconds, value])
	}

	## Construct `SETNX`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/setnx/).
	## Parameters (in order): `key`, `value`.
	## Deprecated by Redis; retained for catalog completeness.
	setnx : List(U8), List(U8) -> Command.Command
	setnx = |key, value| {
		Command.from_nonempty_bytes("SETNX", [key, value])
	}

	## Construct `SETRANGE`.
	## Available since Redis 2.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/setrange/).
	## Parameters (in order): `key`, `offset`, `value`.
	setrange : List(U8), List(U8), List(U8) -> Command.Command
	setrange = |key, offset, value| {
		Command.from_nonempty_bytes("SETRANGE", [key, offset, value])
	}

	## Construct `STRLEN`.
	## Available since Redis 2.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/strlen/).
	## Parameters (in order): `key`.
	strlen : List(U8) -> Command.Command
	strlen = |key| {
		Command.from_nonempty_bytes("STRLEN", [key])
	}

	## Construct `SUBSTR`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/substr/).
	## Parameters (in order): `key`, `start`, `end`.
	## Deprecated by Redis; retained for catalog completeness.
	substr : List(U8), List(U8), List(U8) -> Command.Command
	substr = |key, start, end| {
		Command.from_nonempty_bytes("SUBSTR", [key, start, end])
	}
}

expect Command.encode(Strings.append([0, 1, 255], [0, 2, 255])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'A', 'P', 'P', 'E', 'N', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Strings.decr([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'D', 'E', 'C', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Strings.decrby([0, 1, 255], ['2'])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'D', 'E', 'C', 'R', 'B', 'Y', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Strings.delex([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'D', 'E', 'L', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Strings.delex([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '5', '\r', '\n', 'D', 'E', 'L', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Strings.digest([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'D', 'I', 'G', 'E', 'S', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Strings.get([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '3', '\r', '\n', 'G', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Strings.getdel([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'G', 'E', 'T', 'D', 'E', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Strings.getex([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'G', 'E', 'T', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Strings.getex([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '5', '\r', '\n', 'G', 'E', 'T', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Strings.getrange([0, 1, 255], ['2'], ['3'])) == ['*', '4', '\r', '\n', '$', '8', '\r', '\n', 'G', 'E', 'T', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n']

expect Command.encode(Strings.getset([0, 1, 255], [0, 2, 255])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'G', 'E', 'T', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Strings.incr([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'I', 'N', 'C', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Strings.incrby([0, 1, 255], ['2'])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'I', 'N', 'C', 'R', 'B', 'Y', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Strings.incrbyfloat([0, 1, 255], ['2', '.', '5'])) == ['*', '3', '\r', '\n', '$', '1', '1', '\r', '\n', 'I', 'N', 'C', 'R', 'B', 'Y', 'F', 'L', 'O', 'A', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '2', '.', '5', '\r', '\n']

expect Command.encode(Strings.increx([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'I', 'N', 'C', 'R', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Strings.increx([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'I', 'N', 'C', 'R', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Strings.lcs([0, 1, 255], [0, 2, 255], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '3', '\r', '\n', 'L', 'C', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Strings.lcs([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '3', '\r', '\n', 'L', 'C', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Strings.mget([0, 1, 255], [[0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'M', 'G', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Strings.mget([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'M', 'G', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Strings.mset({ key: [0, 1, 255], value: [0, 2, 255] }, [{ key: [0, 3, 255], value: [0, 4, 255] }])) == ['*', '5', '\r', '\n', '$', '4', '\r', '\n', 'M', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Strings.mset({ key: [0, 1, 255], value: [0, 2, 255] }, [])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'M', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Strings.msetex({ key: [0, 1, 255], value: [0, 2, 255] }, [{ key: [0, 3, 255], value: [0, 4, 255] }], [[0, 5, 255], [0, 6, 255]])) == ['*', '8', '\r', '\n', '$', '6', '\r', '\n', 'M', 'S', 'E', 'T', 'E', 'X', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n']

expect Command.encode(Strings.msetex({ key: [0, 1, 255], value: [0, 2, 255] }, [], [])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'M', 'S', 'E', 'T', 'E', 'X', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Strings.msetnx({ key: [0, 1, 255], value: [0, 2, 255] }, [{ key: [0, 3, 255], value: [0, 4, 255] }])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'M', 'S', 'E', 'T', 'N', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Strings.msetnx({ key: [0, 1, 255], value: [0, 2, 255] }, [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'M', 'S', 'E', 'T', 'N', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Strings.psetex([0, 1, 255], ['2'], [0, 3, 255])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'P', 'S', 'E', 'T', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Strings.set([0, 1, 255], [0, 2, 255], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '3', '\r', '\n', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Strings.set([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '3', '\r', '\n', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Strings.setex([0, 1, 255], ['2'], [0, 3, 255])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'S', 'E', 'T', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Strings.setnx([0, 1, 255], [0, 2, 255])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'S', 'E', 'T', 'N', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Strings.setrange([0, 1, 255], ['2'], [0, 3, 255])) == ['*', '4', '\r', '\n', '$', '8', '\r', '\n', 'S', 'E', 'T', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Strings.strlen([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'S', 'T', 'R', 'L', 'E', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Strings.substr([0, 1, 255], ['2'], ['3'])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'S', 'U', 'B', 'S', 'T', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n']
