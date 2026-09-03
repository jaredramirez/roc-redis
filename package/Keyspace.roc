import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 Generic command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
Keyspace := {}.{

	## Construct `COPY`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/copy/).
	## Parameters (in order): `source`, `destination`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	copy : List(U8), List(U8), List(List(U8)) -> Command.Command
	copy = |source, destination, options| {
		Command.from_nonempty_bytes("COPY", [source, destination].concat(options))
	}

	## Construct `DEL`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/del/).
	## Parameters (in order): `first_key`, `other_keys`.
	del : List(U8), List(List(U8)) -> Command.Command
	del = |first_key, other_keys| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("DEL", catalog_keys)
	}

	## Construct `DUMP`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/dump/).
	## Parameters (in order): `key`.
	dump : List(U8) -> Command.Command
	dump = |key| {
		Command.from_nonempty_bytes("DUMP", [key])
	}

	## Construct `EXISTS`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/exists/).
	## Parameters (in order): `first_key`, `other_keys`.
	exists : List(U8), List(List(U8)) -> Command.Command
	exists = |first_key, other_keys| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("EXISTS", catalog_keys)
	}

	## Construct `EXPIRE`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/expire/).
	## Parameters (in order): `key`, `seconds`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	expire : List(U8), List(U8), List(List(U8)) -> Command.Command
	expire = |key, seconds, options| {
		Command.from_nonempty_bytes("EXPIRE", [key, seconds].concat(options))
	}

	## Construct `EXPIREAT`.
	## Available since Redis 1.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/expireat/).
	## Parameters (in order): `key`, `unix_time_seconds`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	expireat : List(U8), List(U8), List(List(U8)) -> Command.Command
	expireat = |key, unix_time_seconds, options| {
		Command.from_nonempty_bytes("EXPIREAT", [key, unix_time_seconds].concat(options))
	}

	## Construct `EXPIRETIME`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/expiretime/).
	## Parameters (in order): `key`.
	expiretime : List(U8) -> Command.Command
	expiretime = |key| {
		Command.from_nonempty_bytes("EXPIRETIME", [key])
	}

	## Construct `KEYS`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/keys/).
	## Parameters (in order): `pattern`.
	keys : List(U8) -> Command.Command
	keys = |pattern| {
		Command.from_nonempty_bytes("KEYS", [pattern])
	}

	## Construct `MIGRATE`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/migrate/).
	## Parameters (in order): `host`, `port`, `key_selector`, `destination_db`, `timeout`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	migrate : List(U8), List(U8), List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	migrate = |host, port, key_selector, destination_db, timeout, options| {
		Command.from_nonempty_bytes("MIGRATE", [host, port, key_selector, destination_db, timeout].concat(options))
	}

	## Construct `MOVE`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/move/).
	## Parameters (in order): `key`, `db`.
	move : List(U8), List(U8) -> Command.Command
	move = |key, db| {
		Command.from_nonempty_bytes("MOVE", [key, db])
	}

	## Construct `OBJECT ENCODING`.
	## Available since Redis 2.2.3.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/object-encoding/).
	## Parameters (in order): `key`.
	object_encoding : List(U8) -> Command.Command
	object_encoding = |key| {
		Command.from_nonempty_bytes("OBJECT", [['E', 'N', 'C', 'O', 'D', 'I', 'N', 'G']].concat([key]))
	}

	## Construct `OBJECT FREQ`.
	## Available since Redis 4.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/object-freq/).
	## Parameters (in order): `key`.
	object_freq : List(U8) -> Command.Command
	object_freq = |key| {
		Command.from_nonempty_bytes("OBJECT", [['F', 'R', 'E', 'Q']].concat([key]))
	}

	## Construct `OBJECT IDLETIME`.
	## Available since Redis 2.2.3.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/object-idletime/).
	## Parameters (in order): `key`.
	object_idletime : List(U8) -> Command.Command
	object_idletime = |key| {
		Command.from_nonempty_bytes("OBJECT", [['I', 'D', 'L', 'E', 'T', 'I', 'M', 'E']].concat([key]))
	}

	## Construct `OBJECT REFCOUNT`.
	## Available since Redis 2.2.3.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/object-refcount/).
	## Parameters (in order): `key`.
	object_refcount : List(U8) -> Command.Command
	object_refcount = |key| {
		Command.from_nonempty_bytes("OBJECT", [['R', 'E', 'F', 'C', 'O', 'U', 'N', 'T']].concat([key]))
	}

	## Construct `PERSIST`.
	## Available since Redis 2.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/persist/).
	## Parameters (in order): `key`.
	persist : List(U8) -> Command.Command
	persist = |key| {
		Command.from_nonempty_bytes("PERSIST", [key])
	}

	## Construct `PEXPIRE`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/pexpire/).
	## Parameters (in order): `key`, `milliseconds`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	pexpire : List(U8), List(U8), List(List(U8)) -> Command.Command
	pexpire = |key, milliseconds, options| {
		Command.from_nonempty_bytes("PEXPIRE", [key, milliseconds].concat(options))
	}

	## Construct `PEXPIREAT`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/pexpireat/).
	## Parameters (in order): `key`, `unix_time_milliseconds`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	pexpireat : List(U8), List(U8), List(List(U8)) -> Command.Command
	pexpireat = |key, unix_time_milliseconds, options| {
		Command.from_nonempty_bytes("PEXPIREAT", [key, unix_time_milliseconds].concat(options))
	}

	## Construct `PEXPIRETIME`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/pexpiretime/).
	## Parameters (in order): `key`.
	pexpiretime : List(U8) -> Command.Command
	pexpiretime = |key| {
		Command.from_nonempty_bytes("PEXPIRETIME", [key])
	}

	## Construct `PTTL`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/pttl/).
	## Parameters (in order): `key`.
	pttl : List(U8) -> Command.Command
	pttl = |key| {
		Command.from_nonempty_bytes("PTTL", [key])
	}

	## Construct `RANDOMKEY`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/randomkey/).
	randomkey : {} -> Command.Command
	randomkey = |_| {
		Command.from_nonempty_bytes("RANDOMKEY", [])
	}

	## Construct `RENAME`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/rename/).
	## Parameters (in order): `key`, `newkey`.
	rename : List(U8), List(U8) -> Command.Command
	rename = |key, newkey| {
		Command.from_nonempty_bytes("RENAME", [key, newkey])
	}

	## Construct `RENAMENX`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/renamenx/).
	## Parameters (in order): `key`, `newkey`.
	renamenx : List(U8), List(U8) -> Command.Command
	renamenx = |key, newkey| {
		Command.from_nonempty_bytes("RENAMENX", [key, newkey])
	}

	## Construct `RESTORE`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/restore/).
	## Parameters (in order): `key`, `ttl_2`, `serialized_value`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	restore : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	restore = |key, ttl_2, serialized_value, options| {
		Command.from_nonempty_bytes("RESTORE", [key, ttl_2, serialized_value].concat(options))
	}

	## Construct `SCAN`.
	## Available since Redis 2.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/scan/).
	## Parameters (in order): `cursor`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	scan : List(U8), List(List(U8)) -> Command.Command
	scan = |cursor, options| {
		Command.from_nonempty_bytes("SCAN", [cursor].concat(options))
	}

	## Construct `SORT`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/sort/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	sort : List(U8), List(List(U8)) -> Command.Command
	sort = |key, options| {
		Command.from_nonempty_bytes("SORT", [key].concat(options))
	}

	## Construct `SORT_RO`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/sort_ro/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	sort_ro : List(U8), List(List(U8)) -> Command.Command
	sort_ro = |key, options| {
		Command.from_nonempty_bytes("SORT_RO", [key].concat(options))
	}

	## Construct `TOUCH`.
	## Available since Redis 3.2.1.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/touch/).
	## Parameters (in order): `first_key`, `other_keys`.
	touch : List(U8), List(List(U8)) -> Command.Command
	touch = |first_key, other_keys| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("TOUCH", catalog_keys)
	}

	## Construct `TTL`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/ttl/).
	## Parameters (in order): `key`.
	ttl : List(U8) -> Command.Command
	ttl = |key| {
		Command.from_nonempty_bytes("TTL", [key])
	}

	## Construct `TYPE`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/type/).
	## Parameters (in order): `key`.
	type_ : List(U8) -> Command.Command
	type_ = |key| {
		Command.from_nonempty_bytes("TYPE", [key])
	}

	## Construct `UNLINK`.
	## Available since Redis 4.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/unlink/).
	## Parameters (in order): `first_key`, `other_keys`.
	unlink : List(U8), List(List(U8)) -> Command.Command
	unlink = |first_key, other_keys| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("UNLINK", catalog_keys)
	}

	## Construct `WAIT`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/wait/).
	## Parameters (in order): `numreplicas`, `timeout`.
	wait : List(U8), List(U8) -> Command.Command
	wait = |numreplicas, timeout| {
		Command.from_nonempty_bytes("WAIT", [numreplicas, timeout])
	}

	## Construct `WAITAOF`.
	## Available since Redis 7.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/waitaof/).
	## Parameters (in order): `numlocal`, `numreplicas`, `timeout`.
	waitaof : List(U8), List(U8), List(U8) -> Command.Command
	waitaof = |numlocal, numreplicas, timeout| {
		Command.from_nonempty_bytes("WAITAOF", [numlocal, numreplicas, timeout])
	}
}

expect Command.encode(Keyspace.copy([0, 1, 255], [0, 2, 255], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '4', '\r', '\n', 'C', 'O', 'P', 'Y', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Keyspace.copy([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'C', 'O', 'P', 'Y', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Keyspace.del([0, 1, 255], [[0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '3', '\r', '\n', 'D', 'E', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Keyspace.del([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '3', '\r', '\n', 'D', 'E', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.dump([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'D', 'U', 'M', 'P', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.exists([0, 1, 255], [[0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'E', 'X', 'I', 'S', 'T', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Keyspace.exists([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'E', 'X', 'I', 'S', 'T', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.expire([0, 1, 255], ['2'], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'E', 'X', 'P', 'I', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Keyspace.expire([0, 1, 255], ['2'], [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'E', 'X', 'P', 'I', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Keyspace.expireat([0, 1, 255], ['2'], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '8', '\r', '\n', 'E', 'X', 'P', 'I', 'R', 'E', 'A', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Keyspace.expireat([0, 1, 255], ['2'], [])) == ['*', '3', '\r', '\n', '$', '8', '\r', '\n', 'E', 'X', 'P', 'I', 'R', 'E', 'A', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Keyspace.expiretime([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '1', '0', '\r', '\n', 'E', 'X', 'P', 'I', 'R', 'E', 'T', 'I', 'M', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.keys([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'K', 'E', 'Y', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.migrate([0, 1, 255], ['2'], [0, 3, 255], ['4'], ['5'], [[0, 6, 255], [0, 7, 255]])) == ['*', '8', '\r', '\n', '$', '7', '\r', '\n', 'M', 'I', 'G', 'R', 'A', 'T', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '1', '\r', '\n', '4', '\r', '\n', '$', '1', '\r', '\n', '5', '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 7, 255, '\r', '\n']

expect Command.encode(Keyspace.migrate([0, 1, 255], ['2'], [0, 3, 255], ['4'], ['5'], [])) == ['*', '6', '\r', '\n', '$', '7', '\r', '\n', 'M', 'I', 'G', 'R', 'A', 'T', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '1', '\r', '\n', '4', '\r', '\n', '$', '1', '\r', '\n', '5', '\r', '\n']

expect Command.encode(Keyspace.move([0, 1, 255], ['2'])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'M', 'O', 'V', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Keyspace.object_encoding([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'O', 'B', 'J', 'E', 'C', 'T', '\r', '\n', '$', '8', '\r', '\n', 'E', 'N', 'C', 'O', 'D', 'I', 'N', 'G', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.object_freq([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'O', 'B', 'J', 'E', 'C', 'T', '\r', '\n', '$', '4', '\r', '\n', 'F', 'R', 'E', 'Q', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.object_idletime([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'O', 'B', 'J', 'E', 'C', 'T', '\r', '\n', '$', '8', '\r', '\n', 'I', 'D', 'L', 'E', 'T', 'I', 'M', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.object_refcount([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'O', 'B', 'J', 'E', 'C', 'T', '\r', '\n', '$', '8', '\r', '\n', 'R', 'E', 'F', 'C', 'O', 'U', 'N', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.persist([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'P', 'E', 'R', 'S', 'I', 'S', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.pexpire([0, 1, 255], ['2'], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '7', '\r', '\n', 'P', 'E', 'X', 'P', 'I', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Keyspace.pexpire([0, 1, 255], ['2'], [])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'P', 'E', 'X', 'P', 'I', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Keyspace.pexpireat([0, 1, 255], ['2'], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '9', '\r', '\n', 'P', 'E', 'X', 'P', 'I', 'R', 'E', 'A', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Keyspace.pexpireat([0, 1, 255], ['2'], [])) == ['*', '3', '\r', '\n', '$', '9', '\r', '\n', 'P', 'E', 'X', 'P', 'I', 'R', 'E', 'A', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Keyspace.pexpiretime([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '1', '1', '\r', '\n', 'P', 'E', 'X', 'P', 'I', 'R', 'E', 'T', 'I', 'M', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.pttl([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'P', 'T', 'T', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.randomkey({})) == ['*', '1', '\r', '\n', '$', '9', '\r', '\n', 'R', 'A', 'N', 'D', 'O', 'M', 'K', 'E', 'Y', '\r', '\n']

expect Command.encode(Keyspace.rename([0, 1, 255], [0, 2, 255])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'R', 'E', 'N', 'A', 'M', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Keyspace.renamenx([0, 1, 255], [0, 2, 255])) == ['*', '3', '\r', '\n', '$', '8', '\r', '\n', 'R', 'E', 'N', 'A', 'M', 'E', 'N', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Keyspace.restore([0, 1, 255], ['2'], [0, 3, 255], [[0, 4, 255], [0, 5, 255]])) == ['*', '6', '\r', '\n', '$', '7', '\r', '\n', 'R', 'E', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Keyspace.restore([0, 1, 255], ['2'], [0, 3, 255], [])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'R', 'E', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Keyspace.scan(['1'], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'S', 'C', 'A', 'N', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Keyspace.scan(['1'], [])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'S', 'C', 'A', 'N', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n']

expect Command.encode(Keyspace.sort([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'S', 'O', 'R', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Keyspace.sort([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'S', 'O', 'R', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.sort_ro([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'S', 'O', 'R', 'T', '_', 'R', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Keyspace.sort_ro([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'S', 'O', 'R', 'T', '_', 'R', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.touch([0, 1, 255], [[0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'T', 'O', 'U', 'C', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Keyspace.touch([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '5', '\r', '\n', 'T', 'O', 'U', 'C', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.ttl([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '3', '\r', '\n', 'T', 'T', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.type_([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'T', 'Y', 'P', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.unlink([0, 1, 255], [[0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'U', 'N', 'L', 'I', 'N', 'K', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Keyspace.unlink([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'U', 'N', 'L', 'I', 'N', 'K', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Keyspace.wait(['1'], ['2'])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'W', 'A', 'I', 'T', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Keyspace.waitaof(['1'], ['2'], ['3'])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'W', 'A', 'I', 'T', 'A', 'O', 'F', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n']
