import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 Stream command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
Streams := {}.{

	## Construct `XACK`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xack/).
	## Parameters (in order): `key`, `group`, `first_id`, `other_ids`.
	xack : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	xack = |key, group, first_id, other_ids| {
		catalog_ids = [first_id].concat(other_ids)
		Command.from_nonempty_bytes("XACK", [key, group].concat(catalog_ids))
	}

	## Construct `XACKDEL`.
	## Available since Redis 8.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xackdel/).
	## Parameters (in order): `key`, `group`, `options_before_ids`, `first_id`, `other_ids`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	xackdel : List(U8), List(U8), List(List(U8)), List(U8), List(List(U8)) -> Command.Command
	xackdel = |key, group, options_before_ids, first_id, other_ids| {
		catalog_ids = [first_id].concat(other_ids)
		Command.from_nonempty_bytes("XACKDEL", [key, group].concat(options_before_ids).concat([['I', 'D', 'S'], catalog_ids.len().to_str().to_utf8()].concat(catalog_ids)))
	}

	## Construct `XADD`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xadd/).
	## Parameters (in order): `key`, `options_before_id_selector`, `id_selector`, `first_entry`, `other_entries`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	xadd : List(U8), List(List(U8)), List(U8), { field : List(U8), value : List(U8) }, List({ field : List(U8), value : List(U8) }) -> Command.Command
	xadd = |key, options_before_id_selector, id_selector, first_entry, other_entries| {
		catalog_entries = [first_entry].concat(other_entries)
		Command.from_nonempty_bytes("XADD", [key].concat(options_before_id_selector).concat([id_selector]).concat(catalog_entries.join_map(|item| [item.field, item.value])))
	}

	## Construct `XAUTOCLAIM`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xautoclaim/).
	## Parameters (in order): `key`, `group`, `consumer`, `min_idle_time`, `start`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	xautoclaim : List(U8), List(U8), List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	xautoclaim = |key, group, consumer, min_idle_time, start, options| {
		Command.from_nonempty_bytes("XAUTOCLAIM", [key, group, consumer, min_idle_time, start].concat(options))
	}

	## Construct `XCFGSET`.
	## Available since Redis 8.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xcfgset/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	xcfgset : List(U8), List(List(U8)) -> Command.Command
	xcfgset = |key, options| {
		Command.from_nonempty_bytes("XCFGSET", [key].concat(options))
	}

	## Construct `XCLAIM`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xclaim/).
	## Parameters (in order): `key`, `group`, `consumer`, `min_idle_time`, `first_id`, `other_ids`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	xclaim : List(U8), List(U8), List(U8), List(U8), List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	xclaim = |key, group, consumer, min_idle_time, first_id, other_ids, options| {
		catalog_ids = [first_id].concat(other_ids)
		Command.from_nonempty_bytes("XCLAIM", [key, group, consumer, min_idle_time].concat(catalog_ids).concat(options))
	}

	## Construct `XDEL`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xdel/).
	## Parameters (in order): `key`, `first_id`, `other_ids`.
	xdel : List(U8), List(U8), List(List(U8)) -> Command.Command
	xdel = |key, first_id, other_ids| {
		catalog_ids = [first_id].concat(other_ids)
		Command.from_nonempty_bytes("XDEL", [key].concat(catalog_ids))
	}

	## Construct `XDELEX`.
	## Available since Redis 8.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xdelex/).
	## Parameters (in order): `key`, `options_before_ids`, `first_id`, `other_ids`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	xdelex : List(U8), List(List(U8)), List(U8), List(List(U8)) -> Command.Command
	xdelex = |key, options_before_ids, first_id, other_ids| {
		catalog_ids = [first_id].concat(other_ids)
		Command.from_nonempty_bytes("XDELEX", [key].concat(options_before_ids).concat([['I', 'D', 'S'], catalog_ids.len().to_str().to_utf8()].concat(catalog_ids)))
	}

	## Construct `XGROUP CREATE`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xgroup-create/).
	## Parameters (in order): `key`, `group`, `id_selector`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	xgroup_create : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	xgroup_create = |key, group, id_selector, options| {
		Command.from_nonempty_bytes("XGROUP", [['C', 'R', 'E', 'A', 'T', 'E']].concat([key, group, id_selector].concat(options)))
	}

	## Construct `XGROUP CREATECONSUMER`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xgroup-createconsumer/).
	## Parameters (in order): `key`, `group`, `consumer`.
	xgroup_createconsumer : List(U8), List(U8), List(U8) -> Command.Command
	xgroup_createconsumer = |key, group, consumer| {
		Command.from_nonempty_bytes("XGROUP", [['C', 'R', 'E', 'A', 'T', 'E', 'C', 'O', 'N', 'S', 'U', 'M', 'E', 'R']].concat([key, group, consumer]))
	}

	## Construct `XGROUP DELCONSUMER`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xgroup-delconsumer/).
	## Parameters (in order): `key`, `group`, `consumer`.
	xgroup_delconsumer : List(U8), List(U8), List(U8) -> Command.Command
	xgroup_delconsumer = |key, group, consumer| {
		Command.from_nonempty_bytes("XGROUP", [['D', 'E', 'L', 'C', 'O', 'N', 'S', 'U', 'M', 'E', 'R']].concat([key, group, consumer]))
	}

	## Construct `XGROUP DESTROY`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xgroup-destroy/).
	## Parameters (in order): `key`, `group`.
	xgroup_destroy : List(U8), List(U8) -> Command.Command
	xgroup_destroy = |key, group| {
		Command.from_nonempty_bytes("XGROUP", [['D', 'E', 'S', 'T', 'R', 'O', 'Y']].concat([key, group]))
	}

	## Construct `XGROUP SETID`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xgroup-setid/).
	## Parameters (in order): `key`, `group`, `id_selector`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	xgroup_setid : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	xgroup_setid = |key, group, id_selector, options| {
		Command.from_nonempty_bytes("XGROUP", [['S', 'E', 'T', 'I', 'D']].concat([key, group, id_selector].concat(options)))
	}

	## Construct `XINFO CONSUMERS`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xinfo-consumers/).
	## Parameters (in order): `key`, `group`.
	xinfo_consumers : List(U8), List(U8) -> Command.Command
	xinfo_consumers = |key, group| {
		Command.from_nonempty_bytes("XINFO", [['C', 'O', 'N', 'S', 'U', 'M', 'E', 'R', 'S']].concat([key, group]))
	}

	## Construct `XINFO GROUPS`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xinfo-groups/).
	## Parameters (in order): `key`.
	xinfo_groups : List(U8) -> Command.Command
	xinfo_groups = |key| {
		Command.from_nonempty_bytes("XINFO", [['G', 'R', 'O', 'U', 'P', 'S']].concat([key]))
	}

	## Construct `XINFO STREAM`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xinfo-stream/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	xinfo_stream : List(U8), List(List(U8)) -> Command.Command
	xinfo_stream = |key, options| {
		Command.from_nonempty_bytes("XINFO", [['S', 'T', 'R', 'E', 'A', 'M']].concat([key].concat(options)))
	}

	## Construct `XLEN`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xlen/).
	## Parameters (in order): `key`.
	xlen : List(U8) -> Command.Command
	xlen = |key| {
		Command.from_nonempty_bytes("XLEN", [key])
	}

	## Construct `XNACK`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xnack/).
	## Parameters (in order): `key`, `group`, `mode`, `first_id`, `other_ids`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	xnack : List(U8), List(U8), List(U8), List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	xnack = |key, group, mode, first_id, other_ids, options| {
		catalog_ids = [first_id].concat(other_ids)
		Command.from_nonempty_bytes("XNACK", [key, group, mode].concat([['I', 'D', 'S'], catalog_ids.len().to_str().to_utf8()].concat(catalog_ids)).concat(options))
	}

	## Construct `XPENDING`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xpending/).
	## Parameters (in order): `key`, `group`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	xpending : List(U8), List(U8), List(List(U8)) -> Command.Command
	xpending = |key, group, options| {
		Command.from_nonempty_bytes("XPENDING", [key, group].concat(options))
	}

	## Construct `XRANGE`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xrange/).
	## Parameters (in order): `key`, `start`, `end`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	xrange : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	xrange = |key, start, end, options| {
		Command.from_nonempty_bytes("XRANGE", [key, start, end].concat(options))
	}

	## Construct `XREAD`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xread/).
	## Parameters (in order): `options_before_streams`, `first_stream`, `other_streams`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	xread : List(List(U8)), { key : List(U8), id : List(U8) }, List({ key : List(U8), id : List(U8) }) -> Command.Command
	xread = |options_before_streams, first_stream, other_streams| {
		catalog_streams = [first_stream].concat(other_streams)
		Command.from_nonempty_bytes("XREAD", options_before_streams.concat([['S', 'T', 'R', 'E', 'A', 'M', 'S']].concat(catalog_streams.map(|item| item.key)).concat(catalog_streams.map(|item| item.id))))
	}

	## Construct `XREADGROUP`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xreadgroup/).
	## Parameters (in order): `group`, `consumer`, `options_before_streams`, `first_stream`, `other_streams`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	xreadgroup : List(U8), List(U8), List(List(U8)), { key : List(U8), id : List(U8) }, List({ key : List(U8), id : List(U8) }) -> Command.Command
	xreadgroup = |group, consumer, options_before_streams, first_stream, other_streams| {
		catalog_streams = [first_stream].concat(other_streams)
		Command.from_nonempty_bytes("XREADGROUP", [['G', 'R', 'O', 'U', 'P']].concat([group, consumer]).concat(options_before_streams).concat([['S', 'T', 'R', 'E', 'A', 'M', 'S']].concat(catalog_streams.map(|item| item.key)).concat(catalog_streams.map(|item| item.id))))
	}

	## Construct `XREVRANGE`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xrevrange/).
	## Parameters (in order): `key`, `end`, `start`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	xrevrange : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	xrevrange = |key, end, start, options| {
		Command.from_nonempty_bytes("XREVRANGE", [key, end, start].concat(options))
	}

	## Construct `XTRIM`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/xtrim/).
	## Parameters (in order): `key`, `strategy`, `options_before_threshold`, `threshold`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	xtrim : List(U8), List(U8), List(List(U8)), List(U8), List(List(U8)) -> Command.Command
	xtrim = |key, strategy, options_before_threshold, threshold, options| {
		Command.from_nonempty_bytes("XTRIM", [key].concat([strategy].concat(options_before_threshold).concat([threshold]).concat(options)))
	}
}

expect Command.encode(Streams.xack([0, 1, 255], [0, 2, 255], [0, 3, 255], [[0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '4', '\r', '\n', 'X', 'A', 'C', 'K', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Streams.xack([0, 1, 255], [0, 2, 255], [0, 3, 255], [])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'X', 'A', 'C', 'K', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Streams.xackdel([0, 1, 255], [0, 2, 255], [[0, 3, 255], [0, 4, 255]], [0, 5, 255], [[0, 6, 255]])) == ['*', '9', '\r', '\n', '$', '7', '\r', '\n', 'X', 'A', 'C', 'K', 'D', 'E', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 'I', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n']

expect Command.encode(Streams.xackdel([0, 1, 255], [0, 2, 255], [], [0, 5, 255], [])) == ['*', '6', '\r', '\n', '$', '7', '\r', '\n', 'X', 'A', 'C', 'K', 'D', 'E', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 'I', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Streams.xadd([0, 1, 255], [[0, 2, 255], [0, 3, 255]], ['*'], { field: [0, 4, 255], value: [0, 5, 255] }, [{ field: [0, 6, 255], value: [0, 7, 255] }])) == ['*', '9', '\r', '\n', '$', '4', '\r', '\n', 'X', 'A', 'D', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '1', '\r', '\n', '*', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 7, 255, '\r', '\n']

expect Command.encode(Streams.xadd([0, 1, 255], [], ['*'], { field: [0, 4, 255], value: [0, 5, 255] }, [])) == ['*', '5', '\r', '\n', '$', '4', '\r', '\n', 'X', 'A', 'D', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '*', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Streams.xautoclaim([0, 1, 255], [0, 2, 255], [0, 3, 255], [0, 4, 255], [0, 5, 255], [[0, 6, 255], [0, 7, 255]])) == ['*', '8', '\r', '\n', '$', '1', '0', '\r', '\n', 'X', 'A', 'U', 'T', 'O', 'C', 'L', 'A', 'I', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 7, 255, '\r', '\n']

expect Command.encode(Streams.xautoclaim([0, 1, 255], [0, 2, 255], [0, 3, 255], [0, 4, 255], [0, 5, 255], [])) == ['*', '6', '\r', '\n', '$', '1', '0', '\r', '\n', 'X', 'A', 'U', 'T', 'O', 'C', 'L', 'A', 'I', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Streams.xcfgset([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'X', 'C', 'F', 'G', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Streams.xcfgset([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'X', 'C', 'F', 'G', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Streams.xclaim([0, 1, 255], [0, 2, 255], [0, 3, 255], [0, 4, 255], [0, 5, 255], [[0, 6, 255]], [[0, 7, 255], [0, 8, 255]])) == ['*', '9', '\r', '\n', '$', '6', '\r', '\n', 'X', 'C', 'L', 'A', 'I', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 7, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 8, 255, '\r', '\n']

expect Command.encode(Streams.xclaim([0, 1, 255], [0, 2, 255], [0, 3, 255], [0, 4, 255], [0, 5, 255], [], [])) == ['*', '6', '\r', '\n', '$', '6', '\r', '\n', 'X', 'C', 'L', 'A', 'I', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Streams.xdel([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'X', 'D', 'E', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Streams.xdel([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'X', 'D', 'E', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Streams.xdelex([0, 1, 255], [[0, 2, 255], [0, 3, 255]], [0, 4, 255], [[0, 5, 255]])) == ['*', '8', '\r', '\n', '$', '6', '\r', '\n', 'X', 'D', 'E', 'L', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 'I', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Streams.xdelex([0, 1, 255], [], [0, 4, 255], [])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'X', 'D', 'E', 'L', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 'I', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Streams.xgroup_create([0, 1, 255], [0, 2, 255], [0, 3, 255], [[0, 4, 255], [0, 5, 255]])) == ['*', '7', '\r', '\n', '$', '6', '\r', '\n', 'X', 'G', 'R', 'O', 'U', 'P', '\r', '\n', '$', '6', '\r', '\n', 'C', 'R', 'E', 'A', 'T', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Streams.xgroup_create([0, 1, 255], [0, 2, 255], [0, 3, 255], [])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'X', 'G', 'R', 'O', 'U', 'P', '\r', '\n', '$', '6', '\r', '\n', 'C', 'R', 'E', 'A', 'T', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Streams.xgroup_createconsumer([0, 1, 255], [0, 2, 255], [0, 3, 255])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'X', 'G', 'R', 'O', 'U', 'P', '\r', '\n', '$', '1', '4', '\r', '\n', 'C', 'R', 'E', 'A', 'T', 'E', 'C', 'O', 'N', 'S', 'U', 'M', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Streams.xgroup_delconsumer([0, 1, 255], [0, 2, 255], [0, 3, 255])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'X', 'G', 'R', 'O', 'U', 'P', '\r', '\n', '$', '1', '1', '\r', '\n', 'D', 'E', 'L', 'C', 'O', 'N', 'S', 'U', 'M', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Streams.xgroup_destroy([0, 1, 255], [0, 2, 255])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'X', 'G', 'R', 'O', 'U', 'P', '\r', '\n', '$', '7', '\r', '\n', 'D', 'E', 'S', 'T', 'R', 'O', 'Y', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Streams.xgroup_setid([0, 1, 255], [0, 2, 255], [0, 3, 255], [[0, 4, 255], [0, 5, 255]])) == ['*', '7', '\r', '\n', '$', '6', '\r', '\n', 'X', 'G', 'R', 'O', 'U', 'P', '\r', '\n', '$', '5', '\r', '\n', 'S', 'E', 'T', 'I', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Streams.xgroup_setid([0, 1, 255], [0, 2, 255], [0, 3, 255], [])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'X', 'G', 'R', 'O', 'U', 'P', '\r', '\n', '$', '5', '\r', '\n', 'S', 'E', 'T', 'I', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Streams.xinfo_consumers([0, 1, 255], [0, 2, 255])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'X', 'I', 'N', 'F', 'O', '\r', '\n', '$', '9', '\r', '\n', 'C', 'O', 'N', 'S', 'U', 'M', 'E', 'R', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Streams.xinfo_groups([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'X', 'I', 'N', 'F', 'O', '\r', '\n', '$', '6', '\r', '\n', 'G', 'R', 'O', 'U', 'P', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Streams.xinfo_stream([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '5', '\r', '\n', '$', '5', '\r', '\n', 'X', 'I', 'N', 'F', 'O', '\r', '\n', '$', '6', '\r', '\n', 'S', 'T', 'R', 'E', 'A', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Streams.xinfo_stream([0, 1, 255], [])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'X', 'I', 'N', 'F', 'O', '\r', '\n', '$', '6', '\r', '\n', 'S', 'T', 'R', 'E', 'A', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Streams.xlen([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'X', 'L', 'E', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Streams.xnack([0, 1, 255], [0, 2, 255], ['S', 'I', 'L', 'E', 'N', 'T'], [0, 3, 255], [[0, 4, 255]], [[0, 5, 255], [0, 6, 255]])) == ['*', '1', '0', '\r', '\n', '$', '5', '\r', '\n', 'X', 'N', 'A', 'C', 'K', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '6', '\r', '\n', 'S', 'I', 'L', 'E', 'N', 'T', '\r', '\n', '$', '3', '\r', '\n', 'I', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n']

expect Command.encode(Streams.xnack([0, 1, 255], [0, 2, 255], ['S', 'I', 'L', 'E', 'N', 'T'], [0, 3, 255], [], [])) == ['*', '7', '\r', '\n', '$', '5', '\r', '\n', 'X', 'N', 'A', 'C', 'K', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '6', '\r', '\n', 'S', 'I', 'L', 'E', 'N', 'T', '\r', '\n', '$', '3', '\r', '\n', 'I', 'D', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Streams.xpending([0, 1, 255], [0, 2, 255], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '8', '\r', '\n', 'X', 'P', 'E', 'N', 'D', 'I', 'N', 'G', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Streams.xpending([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '8', '\r', '\n', 'X', 'P', 'E', 'N', 'D', 'I', 'N', 'G', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Streams.xrange([0, 1, 255], [0, 2, 255], [0, 3, 255], [[0, 4, 255], [0, 5, 255]])) == ['*', '6', '\r', '\n', '$', '6', '\r', '\n', 'X', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Streams.xrange([0, 1, 255], [0, 2, 255], [0, 3, 255], [])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'X', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Streams.xread([[0, 1, 255], [0, 2, 255]], { key: [0, 3, 255], id: [0, 4, 255] }, [{ key: [0, 5, 255], id: [0, 6, 255] }])) == ['*', '8', '\r', '\n', '$', '5', '\r', '\n', 'X', 'R', 'E', 'A', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '7', '\r', '\n', 'S', 'T', 'R', 'E', 'A', 'M', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n']

expect Command.encode(Streams.xread([], { key: [0, 3, 255], id: [0, 4, 255] }, [])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'X', 'R', 'E', 'A', 'D', '\r', '\n', '$', '7', '\r', '\n', 'S', 'T', 'R', 'E', 'A', 'M', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Streams.xreadgroup([0, 1, 255], [0, 2, 255], [[0, 3, 255], [0, 4, 255]], { key: [0, 5, 255], id: [0, 6, 255] }, [{ key: [0, 7, 255], id: [0, 8, 255] }])) == ['*', '1', '1', '\r', '\n', '$', '1', '0', '\r', '\n', 'X', 'R', 'E', 'A', 'D', 'G', 'R', 'O', 'U', 'P', '\r', '\n', '$', '5', '\r', '\n', 'G', 'R', 'O', 'U', 'P', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '7', '\r', '\n', 'S', 'T', 'R', 'E', 'A', 'M', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 7, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 8, 255, '\r', '\n']

expect Command.encode(Streams.xreadgroup([0, 1, 255], [0, 2, 255], [], { key: [0, 5, 255], id: [0, 6, 255] }, [])) == ['*', '7', '\r', '\n', '$', '1', '0', '\r', '\n', 'X', 'R', 'E', 'A', 'D', 'G', 'R', 'O', 'U', 'P', '\r', '\n', '$', '5', '\r', '\n', 'G', 'R', 'O', 'U', 'P', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '7', '\r', '\n', 'S', 'T', 'R', 'E', 'A', 'M', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n']

expect Command.encode(Streams.xrevrange([0, 1, 255], [0, 2, 255], [0, 3, 255], [[0, 4, 255], [0, 5, 255]])) == ['*', '6', '\r', '\n', '$', '9', '\r', '\n', 'X', 'R', 'E', 'V', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Streams.xrevrange([0, 1, 255], [0, 2, 255], [0, 3, 255], [])) == ['*', '4', '\r', '\n', '$', '9', '\r', '\n', 'X', 'R', 'E', 'V', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Streams.xtrim([0, 1, 255], ['M', 'A', 'X', 'L', 'E', 'N'], [[0, 2, 255], [0, 3, 255]], [0, 4, 255], [[0, 5, 255], [0, 6, 255]])) == ['*', '8', '\r', '\n', '$', '5', '\r', '\n', 'X', 'T', 'R', 'I', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'M', 'A', 'X', 'L', 'E', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n']

expect Command.encode(Streams.xtrim([0, 1, 255], ['M', 'A', 'X', 'L', 'E', 'N'], [], [0, 4, 255], [])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'X', 'T', 'R', 'I', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '6', '\r', '\n', 'M', 'A', 'X', 'L', 'E', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']
