import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 Hash command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
Hashes := {}.{

	## Construct `HDEL`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hdel/).
	## Parameters (in order): `key`, `first_field`, `other_fields`.
	hdel : List(U8), List(U8), List(List(U8)) -> Command.Command
	hdel = |key, first_field, other_fields| {
		catalog_fields = [first_field].concat(other_fields)
		Command.from_nonempty_bytes("HDEL", [key].concat(catalog_fields))
	}

	## Construct `HEXISTS`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hexists/).
	## Parameters (in order): `key`, `field`.
	hexists : List(U8), List(U8) -> Command.Command
	hexists = |key, field| {
		Command.from_nonempty_bytes("HEXISTS", [key, field])
	}

	## Construct `HEXPIRE`.
	## Available since Redis 7.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hexpire/).
	## Parameters (in order): `key`, `seconds`, `options_before_fields`, `first_field`, `other_fields`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	hexpire : List(U8), List(U8), List(List(U8)), List(U8), List(List(U8)) -> Command.Command
	hexpire = |key, seconds, options_before_fields, first_field, other_fields| {
		catalog_fields = [first_field].concat(other_fields)
		Command.from_nonempty_bytes("HEXPIRE", [key, seconds].concat(options_before_fields).concat([['F', 'I', 'E', 'L', 'D', 'S'], catalog_fields.len().to_str().to_utf8()].concat(catalog_fields)))
	}

	## Construct `HEXPIREAT`.
	## Available since Redis 7.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hexpireat/).
	## Parameters (in order): `key`, `unix_time_seconds`, `options_before_fields`, `first_field`, `other_fields`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	hexpireat : List(U8), List(U8), List(List(U8)), List(U8), List(List(U8)) -> Command.Command
	hexpireat = |key, unix_time_seconds, options_before_fields, first_field, other_fields| {
		catalog_fields = [first_field].concat(other_fields)
		Command.from_nonempty_bytes("HEXPIREAT", [key, unix_time_seconds].concat(options_before_fields).concat([['F', 'I', 'E', 'L', 'D', 'S'], catalog_fields.len().to_str().to_utf8()].concat(catalog_fields)))
	}

	## Construct `HEXPIRETIME`.
	## Available since Redis 7.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hexpiretime/).
	## Parameters (in order): `key`, `first_field`, `other_fields`.
	hexpiretime : List(U8), List(U8), List(List(U8)) -> Command.Command
	hexpiretime = |key, first_field, other_fields| {
		catalog_fields = [first_field].concat(other_fields)
		Command.from_nonempty_bytes("HEXPIRETIME", [key].concat([['F', 'I', 'E', 'L', 'D', 'S'], catalog_fields.len().to_str().to_utf8()].concat(catalog_fields)))
	}

	## Construct `HGET`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hget/).
	## Parameters (in order): `key`, `field`.
	hget : List(U8), List(U8) -> Command.Command
	hget = |key, field| {
		Command.from_nonempty_bytes("HGET", [key, field])
	}

	## Construct `HGETALL`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hgetall/).
	## Parameters (in order): `key`.
	hgetall : List(U8) -> Command.Command
	hgetall = |key| {
		Command.from_nonempty_bytes("HGETALL", [key])
	}

	## Construct `HGETDEL`.
	## Available since Redis 8.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hgetdel/).
	## Parameters (in order): `key`, `first_field`, `other_fields`.
	hgetdel : List(U8), List(U8), List(List(U8)) -> Command.Command
	hgetdel = |key, first_field, other_fields| {
		catalog_fields = [first_field].concat(other_fields)
		Command.from_nonempty_bytes("HGETDEL", [key].concat([['F', 'I', 'E', 'L', 'D', 'S'], catalog_fields.len().to_str().to_utf8()].concat(catalog_fields)))
	}

	## Construct `HGETEX`.
	## Available since Redis 8.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hgetex/).
	## Parameters (in order): `key`, `options_before_fields`, `first_field`, `other_fields`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	hgetex : List(U8), List(List(U8)), List(U8), List(List(U8)) -> Command.Command
	hgetex = |key, options_before_fields, first_field, other_fields| {
		catalog_fields = [first_field].concat(other_fields)
		Command.from_nonempty_bytes("HGETEX", [key].concat(options_before_fields).concat([['F', 'I', 'E', 'L', 'D', 'S'], catalog_fields.len().to_str().to_utf8()].concat(catalog_fields)))
	}

	## Construct `HIMPORT DISCARD`.
	## Available since Redis 8.10.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/himport-discard/).
	## Parameters (in order): `fieldset_name`.
	himport_discard : List(U8) -> Command.Command
	himport_discard = |fieldset_name| {
		Command.from_nonempty_bytes("HIMPORT", [['D', 'I', 'S', 'C', 'A', 'R', 'D']].concat([fieldset_name]))
	}

	## Construct `HIMPORT DISCARDALL`.
	## Available since Redis 8.10.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/himport-discardall/).
	himport_discardall : () -> Command.Command
	himport_discardall = || {
		Command.from_nonempty_bytes("HIMPORT", [['D', 'I', 'S', 'C', 'A', 'R', 'D', 'A', 'L', 'L']])
	}

	## Construct `HIMPORT PREPARE`.
	## Available since Redis 8.10.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/himport-prepare/).
	## Parameters (in order): `fieldset_name`, `first_field`, `other_fields`.
	himport_prepare : List(U8), List(U8), List(List(U8)) -> Command.Command
	himport_prepare = |fieldset_name, first_field, other_fields| {
		catalog_fields = [first_field].concat(other_fields)
		Command.from_nonempty_bytes("HIMPORT", [['P', 'R', 'E', 'P', 'A', 'R', 'E']].concat([fieldset_name].concat(catalog_fields)))
	}

	## Construct `HIMPORT SET`.
	## Available since Redis 8.10.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/himport-set/).
	## Parameters (in order): `key`, `fieldset_name`, `first_value`, `other_values`.
	himport_set : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	himport_set = |key, fieldset_name, first_value, other_values| {
		catalog_values = [first_value].concat(other_values)
		Command.from_nonempty_bytes("HIMPORT", [['S', 'E', 'T']].concat([key, fieldset_name].concat(catalog_values)))
	}

	## Construct `HINCRBY`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hincrby/).
	## Parameters (in order): `key`, `field`, `increment`.
	hincrby : List(U8), List(U8), List(U8) -> Command.Command
	hincrby = |key, field, increment| {
		Command.from_nonempty_bytes("HINCRBY", [key, field, increment])
	}

	## Construct `HINCRBYFLOAT`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hincrbyfloat/).
	## Parameters (in order): `key`, `field`, `increment`.
	hincrbyfloat : List(U8), List(U8), List(U8) -> Command.Command
	hincrbyfloat = |key, field, increment| {
		Command.from_nonempty_bytes("HINCRBYFLOAT", [key, field, increment])
	}

	## Construct `HKEYS`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hkeys/).
	## Parameters (in order): `key`.
	hkeys : List(U8) -> Command.Command
	hkeys = |key| {
		Command.from_nonempty_bytes("HKEYS", [key])
	}

	## Construct `HLEN`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hlen/).
	## Parameters (in order): `key`.
	hlen : List(U8) -> Command.Command
	hlen = |key| {
		Command.from_nonempty_bytes("HLEN", [key])
	}

	## Construct `HMGET`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hmget/).
	## Parameters (in order): `key`, `first_field`, `other_fields`.
	hmget : List(U8), List(U8), List(List(U8)) -> Command.Command
	hmget = |key, first_field, other_fields| {
		catalog_fields = [first_field].concat(other_fields)
		Command.from_nonempty_bytes("HMGET", [key].concat(catalog_fields))
	}

	## Construct `HMSET`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hmset/).
	## Parameters (in order): `key`, `first_entry`, `other_entries`.
	## Deprecated by Redis; retained for catalog completeness.
	hmset : List(U8), { field : List(U8), value : List(U8) }, List({ field : List(U8), value : List(U8) }) -> Command.Command
	hmset = |key, first_entry, other_entries| {
		catalog_entries = [first_entry].concat(other_entries)
		Command.from_nonempty_bytes("HMSET", [key].concat(catalog_entries.join_map(|item| [item.field, item.value])))
	}

	## Construct `HPERSIST`.
	## Available since Redis 7.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hpersist/).
	## Parameters (in order): `key`, `first_field`, `other_fields`.
	hpersist : List(U8), List(U8), List(List(U8)) -> Command.Command
	hpersist = |key, first_field, other_fields| {
		catalog_fields = [first_field].concat(other_fields)
		Command.from_nonempty_bytes("HPERSIST", [key].concat([['F', 'I', 'E', 'L', 'D', 'S'], catalog_fields.len().to_str().to_utf8()].concat(catalog_fields)))
	}

	## Construct `HPEXPIRE`.
	## Available since Redis 7.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hpexpire/).
	## Parameters (in order): `key`, `milliseconds`, `options_before_fields`, `first_field`, `other_fields`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	hpexpire : List(U8), List(U8), List(List(U8)), List(U8), List(List(U8)) -> Command.Command
	hpexpire = |key, milliseconds, options_before_fields, first_field, other_fields| {
		catalog_fields = [first_field].concat(other_fields)
		Command.from_nonempty_bytes("HPEXPIRE", [key, milliseconds].concat(options_before_fields).concat([['F', 'I', 'E', 'L', 'D', 'S'], catalog_fields.len().to_str().to_utf8()].concat(catalog_fields)))
	}

	## Construct `HPEXPIREAT`.
	## Available since Redis 7.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hpexpireat/).
	## Parameters (in order): `key`, `unix_time_milliseconds`, `options_before_fields`, `first_field`, `other_fields`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	hpexpireat : List(U8), List(U8), List(List(U8)), List(U8), List(List(U8)) -> Command.Command
	hpexpireat = |key, unix_time_milliseconds, options_before_fields, first_field, other_fields| {
		catalog_fields = [first_field].concat(other_fields)
		Command.from_nonempty_bytes("HPEXPIREAT", [key, unix_time_milliseconds].concat(options_before_fields).concat([['F', 'I', 'E', 'L', 'D', 'S'], catalog_fields.len().to_str().to_utf8()].concat(catalog_fields)))
	}

	## Construct `HPEXPIRETIME`.
	## Available since Redis 7.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hpexpiretime/).
	## Parameters (in order): `key`, `first_field`, `other_fields`.
	hpexpiretime : List(U8), List(U8), List(List(U8)) -> Command.Command
	hpexpiretime = |key, first_field, other_fields| {
		catalog_fields = [first_field].concat(other_fields)
		Command.from_nonempty_bytes("HPEXPIRETIME", [key].concat([['F', 'I', 'E', 'L', 'D', 'S'], catalog_fields.len().to_str().to_utf8()].concat(catalog_fields)))
	}

	## Construct `HPTTL`.
	## Available since Redis 7.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hpttl/).
	## Parameters (in order): `key`, `first_field`, `other_fields`.
	hpttl : List(U8), List(U8), List(List(U8)) -> Command.Command
	hpttl = |key, first_field, other_fields| {
		catalog_fields = [first_field].concat(other_fields)
		Command.from_nonempty_bytes("HPTTL", [key].concat([['F', 'I', 'E', 'L', 'D', 'S'], catalog_fields.len().to_str().to_utf8()].concat(catalog_fields)))
	}

	## Construct `HRANDFIELD`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hrandfield/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	hrandfield : List(U8), List(List(U8)) -> Command.Command
	hrandfield = |key, options| {
		Command.from_nonempty_bytes("HRANDFIELD", [key].concat(options))
	}

	## Construct `HSCAN`.
	## Available since Redis 2.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hscan/).
	## Parameters (in order): `key`, `cursor`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	hscan : List(U8), List(U8), List(List(U8)) -> Command.Command
	hscan = |key, cursor, options| {
		Command.from_nonempty_bytes("HSCAN", [key, cursor].concat(options))
	}

	## Construct `HSET`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hset/).
	## Parameters (in order): `key`, `first_entry`, `other_entries`.
	hset : List(U8), { field : List(U8), value : List(U8) }, List({ field : List(U8), value : List(U8) }) -> Command.Command
	hset = |key, first_entry, other_entries| {
		catalog_entries = [first_entry].concat(other_entries)
		Command.from_nonempty_bytes("HSET", [key].concat(catalog_entries.join_map(|item| [item.field, item.value])))
	}

	## Construct `HSETEX`.
	## Available since Redis 8.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hsetex/).
	## Parameters (in order): `key`, `options_before_fields`, `first_entry`, `other_entries`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	hsetex : List(U8), List(List(U8)), { field : List(U8), value : List(U8) }, List({ field : List(U8), value : List(U8) }) -> Command.Command
	hsetex = |key, options_before_fields, first_entry, other_entries| {
		catalog_entries = [first_entry].concat(other_entries)
		Command.from_nonempty_bytes("HSETEX", [key].concat(options_before_fields).concat([['F', 'I', 'E', 'L', 'D', 'S'], catalog_entries.len().to_str().to_utf8()].concat(catalog_entries.join_map(|item| [item.field, item.value]))))
	}

	## Construct `HSETNX`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hsetnx/).
	## Parameters (in order): `key`, `field`, `value`.
	hsetnx : List(U8), List(U8), List(U8) -> Command.Command
	hsetnx = |key, field, value| {
		Command.from_nonempty_bytes("HSETNX", [key, field, value])
	}

	## Construct `HSTRLEN`.
	## Available since Redis 3.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hstrlen/).
	## Parameters (in order): `key`, `field`.
	hstrlen : List(U8), List(U8) -> Command.Command
	hstrlen = |key, field| {
		Command.from_nonempty_bytes("HSTRLEN", [key, field])
	}

	## Construct `HTTL`.
	## Available since Redis 7.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/httl/).
	## Parameters (in order): `key`, `first_field`, `other_fields`.
	httl : List(U8), List(U8), List(List(U8)) -> Command.Command
	httl = |key, first_field, other_fields| {
		catalog_fields = [first_field].concat(other_fields)
		Command.from_nonempty_bytes("HTTL", [key].concat([['F', 'I', 'E', 'L', 'D', 'S'], catalog_fields.len().to_str().to_utf8()].concat(catalog_fields)))
	}

	## Construct `HVALS`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hvals/).
	## Parameters (in order): `key`.
	hvals : List(U8) -> Command.Command
	hvals = |key| {
		Command.from_nonempty_bytes("HVALS", [key])
	}
}

expect Command.encode(Hashes.hdel([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'H', 'D', 'E', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Hashes.hdel([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'H', 'D', 'E', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Hashes.hexists([0, 1, 255], [0, 2, 255])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'H', 'E', 'X', 'I', 'S', 'T', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Hashes.hexpire([0, 1, 255], ['2'], [[0, 3, 255], [0, 4, 255]], [0, 5, 255], [[0, 6, 255]])) == ['*', '9', '\r', '\n', '$', '7', '\r', '\n', 'H', 'E', 'X', 'P', 'I', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n']

expect Command.encode(Hashes.hexpire([0, 1, 255], ['2'], [], [0, 5, 255], [])) == ['*', '6', '\r', '\n', '$', '7', '\r', '\n', 'H', 'E', 'X', 'P', 'I', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Hashes.hexpireat([0, 1, 255], ['2'], [[0, 3, 255], [0, 4, 255]], [0, 5, 255], [[0, 6, 255]])) == ['*', '9', '\r', '\n', '$', '9', '\r', '\n', 'H', 'E', 'X', 'P', 'I', 'R', 'E', 'A', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n']

expect Command.encode(Hashes.hexpireat([0, 1, 255], ['2'], [], [0, 5, 255], [])) == ['*', '6', '\r', '\n', '$', '9', '\r', '\n', 'H', 'E', 'X', 'P', 'I', 'R', 'E', 'A', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Hashes.hexpiretime([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '6', '\r', '\n', '$', '1', '1', '\r', '\n', 'H', 'E', 'X', 'P', 'I', 'R', 'E', 'T', 'I', 'M', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Hashes.hexpiretime([0, 1, 255], [0, 2, 255], [])) == ['*', '5', '\r', '\n', '$', '1', '1', '\r', '\n', 'H', 'E', 'X', 'P', 'I', 'R', 'E', 'T', 'I', 'M', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Hashes.hget([0, 1, 255], [0, 2, 255])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'H', 'G', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Hashes.hgetall([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'H', 'G', 'E', 'T', 'A', 'L', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Hashes.hgetdel([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '6', '\r', '\n', '$', '7', '\r', '\n', 'H', 'G', 'E', 'T', 'D', 'E', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Hashes.hgetdel([0, 1, 255], [0, 2, 255], [])) == ['*', '5', '\r', '\n', '$', '7', '\r', '\n', 'H', 'G', 'E', 'T', 'D', 'E', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Hashes.hgetex([0, 1, 255], [[0, 2, 255], [0, 3, 255]], [0, 4, 255], [[0, 5, 255]])) == ['*', '8', '\r', '\n', '$', '6', '\r', '\n', 'H', 'G', 'E', 'T', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Hashes.hgetex([0, 1, 255], [], [0, 4, 255], [])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'H', 'G', 'E', 'T', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Hashes.himport_discard([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'H', 'I', 'M', 'P', 'O', 'R', 'T', '\r', '\n', '$', '7', '\r', '\n', 'D', 'I', 'S', 'C', 'A', 'R', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Hashes.himport_discardall()) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'H', 'I', 'M', 'P', 'O', 'R', 'T', '\r', '\n', '$', '1', '0', '\r', '\n', 'D', 'I', 'S', 'C', 'A', 'R', 'D', 'A', 'L', 'L', '\r', '\n']

expect Command.encode(Hashes.himport_prepare([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '5', '\r', '\n', '$', '7', '\r', '\n', 'H', 'I', 'M', 'P', 'O', 'R', 'T', '\r', '\n', '$', '7', '\r', '\n', 'P', 'R', 'E', 'P', 'A', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Hashes.himport_prepare([0, 1, 255], [0, 2, 255], [])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'H', 'I', 'M', 'P', 'O', 'R', 'T', '\r', '\n', '$', '7', '\r', '\n', 'P', 'R', 'E', 'P', 'A', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Hashes.himport_set([0, 1, 255], [0, 2, 255], [0, 3, 255], [[0, 4, 255]])) == ['*', '6', '\r', '\n', '$', '7', '\r', '\n', 'H', 'I', 'M', 'P', 'O', 'R', 'T', '\r', '\n', '$', '3', '\r', '\n', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Hashes.himport_set([0, 1, 255], [0, 2, 255], [0, 3, 255], [])) == ['*', '5', '\r', '\n', '$', '7', '\r', '\n', 'H', 'I', 'M', 'P', 'O', 'R', 'T', '\r', '\n', '$', '3', '\r', '\n', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Hashes.hincrby([0, 1, 255], [0, 2, 255], ['3'])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'H', 'I', 'N', 'C', 'R', 'B', 'Y', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n']

expect Command.encode(Hashes.hincrbyfloat([0, 1, 255], [0, 2, 255], ['3', '.', '5'])) == ['*', '4', '\r', '\n', '$', '1', '2', '\r', '\n', 'H', 'I', 'N', 'C', 'R', 'B', 'Y', 'F', 'L', 'O', 'A', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n']

expect Command.encode(Hashes.hkeys([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '5', '\r', '\n', 'H', 'K', 'E', 'Y', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Hashes.hlen([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'H', 'L', 'E', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Hashes.hmget([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'H', 'M', 'G', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Hashes.hmget([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'H', 'M', 'G', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Hashes.hmset([0, 1, 255], { field: [0, 2, 255], value: [0, 3, 255] }, [{ field: [0, 4, 255], value: [0, 5, 255] }])) == ['*', '6', '\r', '\n', '$', '5', '\r', '\n', 'H', 'M', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Hashes.hmset([0, 1, 255], { field: [0, 2, 255], value: [0, 3, 255] }, [])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'H', 'M', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Hashes.hpersist([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '6', '\r', '\n', '$', '8', '\r', '\n', 'H', 'P', 'E', 'R', 'S', 'I', 'S', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Hashes.hpersist([0, 1, 255], [0, 2, 255], [])) == ['*', '5', '\r', '\n', '$', '8', '\r', '\n', 'H', 'P', 'E', 'R', 'S', 'I', 'S', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Hashes.hpexpire([0, 1, 255], ['2'], [[0, 3, 255], [0, 4, 255]], [0, 5, 255], [[0, 6, 255]])) == ['*', '9', '\r', '\n', '$', '8', '\r', '\n', 'H', 'P', 'E', 'X', 'P', 'I', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n']

expect Command.encode(Hashes.hpexpire([0, 1, 255], ['2'], [], [0, 5, 255], [])) == ['*', '6', '\r', '\n', '$', '8', '\r', '\n', 'H', 'P', 'E', 'X', 'P', 'I', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Hashes.hpexpireat([0, 1, 255], ['2'], [[0, 3, 255], [0, 4, 255]], [0, 5, 255], [[0, 6, 255]])) == ['*', '9', '\r', '\n', '$', '1', '0', '\r', '\n', 'H', 'P', 'E', 'X', 'P', 'I', 'R', 'E', 'A', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n']

expect Command.encode(Hashes.hpexpireat([0, 1, 255], ['2'], [], [0, 5, 255], [])) == ['*', '6', '\r', '\n', '$', '1', '0', '\r', '\n', 'H', 'P', 'E', 'X', 'P', 'I', 'R', 'E', 'A', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Hashes.hpexpiretime([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '6', '\r', '\n', '$', '1', '2', '\r', '\n', 'H', 'P', 'E', 'X', 'P', 'I', 'R', 'E', 'T', 'I', 'M', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Hashes.hpexpiretime([0, 1, 255], [0, 2, 255], [])) == ['*', '5', '\r', '\n', '$', '1', '2', '\r', '\n', 'H', 'P', 'E', 'X', 'P', 'I', 'R', 'E', 'T', 'I', 'M', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Hashes.hpttl([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '6', '\r', '\n', '$', '5', '\r', '\n', 'H', 'P', 'T', 'T', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Hashes.hpttl([0, 1, 255], [0, 2, 255], [])) == ['*', '5', '\r', '\n', '$', '5', '\r', '\n', 'H', 'P', 'T', 'T', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Hashes.hrandfield([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '1', '0', '\r', '\n', 'H', 'R', 'A', 'N', 'D', 'F', 'I', 'E', 'L', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Hashes.hrandfield([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '1', '0', '\r', '\n', 'H', 'R', 'A', 'N', 'D', 'F', 'I', 'E', 'L', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Hashes.hscan([0, 1, 255], ['2'], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '5', '\r', '\n', 'H', 'S', 'C', 'A', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Hashes.hscan([0, 1, 255], ['2'], [])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'H', 'S', 'C', 'A', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Hashes.hset([0, 1, 255], { field: [0, 2, 255], value: [0, 3, 255] }, [{ field: [0, 4, 255], value: [0, 5, 255] }])) == ['*', '6', '\r', '\n', '$', '4', '\r', '\n', 'H', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Hashes.hset([0, 1, 255], { field: [0, 2, 255], value: [0, 3, 255] }, [])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'H', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Hashes.hsetex([0, 1, 255], [[0, 2, 255], [0, 3, 255]], { field: [0, 4, 255], value: [0, 5, 255] }, [{ field: [0, 6, 255], value: [0, 7, 255] }])) == ['*', '1', '0', '\r', '\n', '$', '6', '\r', '\n', 'H', 'S', 'E', 'T', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 7, 255, '\r', '\n']

expect Command.encode(Hashes.hsetex([0, 1, 255], [], { field: [0, 4, 255], value: [0, 5, 255] }, [])) == ['*', '6', '\r', '\n', '$', '6', '\r', '\n', 'H', 'S', 'E', 'T', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Hashes.hsetnx([0, 1, 255], [0, 2, 255], [0, 3, 255])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'H', 'S', 'E', 'T', 'N', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Hashes.hstrlen([0, 1, 255], [0, 2, 255])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'H', 'S', 'T', 'R', 'L', 'E', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Hashes.httl([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '6', '\r', '\n', '$', '4', '\r', '\n', 'H', 'T', 'T', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Hashes.httl([0, 1, 255], [0, 2, 255], [])) == ['*', '5', '\r', '\n', '$', '4', '\r', '\n', 'H', 'T', 'T', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'F', 'I', 'E', 'L', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Hashes.hvals([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '5', '\r', '\n', 'H', 'V', 'A', 'L', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']
