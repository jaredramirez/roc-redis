import /Bytes
import /Command
import /Commands/Decode
import /NonEmpty
import /Reply
import /Request
import /Resp

Keyspace :: [].{
	ExpireCondition : [Always, IfPersistent, IfExpiring, IfLater, IfEarlier, IfExpiringLater, IfExpiringEarlier]
	ExpirationValue : [MissingKey, Persistent, Value(U64)]
	CopyOptions := { database : Reply.Optional(U64) ?? Absent, replace : Bool ?? False }
	ScanOptions := { pattern : Reply.Optional(Bytes.Bytes) ?? Absent, count : Reply.Optional(U64) ?? Absent, kind : Reply.Optional(Bytes.Bytes) ?? Absent }
	RestoreOptions := { replace : Bool ?? False, absolute_ttl : Bool ?? False, eviction : [Default, IdleSeconds(U64), Frequency(U8)] ?? Default }
	SortOptions := { by : Reply.Optional(Bytes.Bytes) ?? Absent, limit : Reply.Optional({ offset : I64, count : I64 }) ?? Absent, get : List(Bytes.Bytes) ?? [], order : [Ascending, Descending] ?? Ascending, alpha : Bool ?? False }
	SortMode : [Values, Store(Bytes.Bytes)]
	SortResult : [Values(List(Reply.Optional(Bytes.Bytes))), Stored(I64)]
	MigrateKeys : [One(Bytes.Bytes), Many(NonEmpty.NonEmpty(Bytes.Bytes))]
	MigrateOptions := { copy : Bool ?? False, replace : Bool ?? False, authentication : [None, Password(Bytes.Bytes), User({ username : Bytes.Bytes, password : Bytes.Bytes })] ?? None }
	MigrateResult : [Migrated, NoKeys]
	del : NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	del = |keys| Request.new(Command.new("DEL", keys.to_list()), Reply.integer)

	exists : NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	exists = |keys| Request.new(Command.new("EXISTS", keys.to_list()), Reply.integer)

	unlink : NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	unlink = |keys| Request.new(Command.new("UNLINK", keys.to_list()), Reply.integer)

	touch : NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	touch = |keys| Request.new(Command.new("TOUCH", keys.to_list()), Reply.integer)

	dump : Bytes.Bytes -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	dump = |key| Request.new(Command.new("DUMP", [key]), Decode.optional_bytes)

	keys : Bytes.Bytes -> Request.Request(List(Bytes.Bytes), Reply.Error)
	keys = |pattern| Request.new(Command.new("KEYS", [pattern]), Decode.bytes_list)

	move : Bytes.Bytes, U64 -> Request.Request(Bool, Reply.Error)
	move = |key, database| Request.new(Command.new("MOVE", [key, decimal(database)]), Reply.integer_boolean)

	persist : Bytes.Bytes -> Request.Request(Bool, Reply.Error)
	persist = |key| Request.new(Command.new("PERSIST", [key]), Reply.integer_boolean)

	random_key : () -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	random_key = || Request.new(Command.new("RANDOMKEY", []), Decode.optional_bytes)

	rename : Bytes.Bytes, Bytes.Bytes -> Request.Request({}, Reply.Error)
	rename = |key, replacement| Request.new(Command.new("RENAME", [key, replacement]), Reply.okay)

	rename_nx : Bytes.Bytes, Bytes.Bytes -> Request.Request(Bool, Reply.Error)
	rename_nx = |key, replacement| Request.new(Command.new("RENAMENX", [key, replacement]), Reply.integer_boolean)

	wait : U64, U64 -> Request.Request(I64, Reply.Error)
	wait = |replicas, timeout_ms| Request.new(Command.new("WAIT", [decimal(replicas), decimal(timeout_ms)]), Reply.integer)

	expire : Bytes.Bytes, I64, ExpireCondition -> Request.Request(Bool, Reply.Error)
	expire = |key, time, condition| Request.new(Command.new("EXPIRE", [key, signed(time)].concat(condition_args(condition))), Reply.integer_boolean)

	expire_at : Bytes.Bytes, I64, ExpireCondition -> Request.Request(Bool, Reply.Error)
	expire_at = |key, time, condition| Request.new(Command.new("EXPIREAT", [key, signed(time)].concat(condition_args(condition))), Reply.integer_boolean)

	pexpire : Bytes.Bytes, I64, ExpireCondition -> Request.Request(Bool, Reply.Error)
	pexpire = |key, time, condition| Request.new(Command.new("PEXPIRE", [key, signed(time)].concat(condition_args(condition))), Reply.integer_boolean)

	pexpire_at : Bytes.Bytes, I64, ExpireCondition -> Request.Request(Bool, Reply.Error)
	pexpire_at = |key, time, condition| Request.new(Command.new("PEXPIREAT", [key, signed(time)].concat(condition_args(condition))), Reply.integer_boolean)

	## Value is in the command's units: TTL/PTTL durations, or EXPIRETIME/
	## PEXPIRETIME absolute Unix timestamps. The two negative sentinels are
	## represented separately, never exposed as an unsigned wraparound.
	ttl : Bytes.Bytes -> Request.Request(ExpirationValue, Reply.Error)
	ttl = |key| Request.new(Command.new("TTL", [key]), expiration_value)

	pttl : Bytes.Bytes -> Request.Request(ExpirationValue, Reply.Error)
	pttl = |key| Request.new(Command.new("PTTL", [key]), expiration_value)

	expire_time : Bytes.Bytes -> Request.Request(ExpirationValue, Reply.Error)
	expire_time = |key| Request.new(Command.new("EXPIRETIME", [key]), expiration_value)

	pexpire_time : Bytes.Bytes -> Request.Request(ExpirationValue, Reply.Error)
	pexpire_time = |key| Request.new(Command.new("PEXPIRETIME", [key]), expiration_value)

	object_encoding : Bytes.Bytes -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	object_encoding = |key| Request.new(Command.new("OBJECT", ["ENCODING", key]), Decode.optional_bytes)

	object_freq : Bytes.Bytes -> Request.Request(Reply.Optional(I64), Reply.Error)
	object_freq = |key| Request.new(Command.new("OBJECT", ["FREQ", key]), optional_integer)

	object_idle_time : Bytes.Bytes -> Request.Request(Reply.Optional(I64), Reply.Error)
	object_idle_time = |key| Request.new(Command.new("OBJECT", ["IDLETIME", key]), optional_integer)

	object_ref_count : Bytes.Bytes -> Request.Request(Reply.Optional(I64), Reply.Error)
	object_ref_count = |key| Request.new(Command.new("OBJECT", ["REFCOUNT", key]), optional_integer)

	key_type : Bytes.Bytes -> Request.Request(Bytes.Bytes, Reply.Error)
	key_type = |key| Request.new(Command.new("TYPE", [key]), |reply| Reply.simple(reply).map_ok(Bytes.from_list))

	copy : Bytes.Bytes, Bytes.Bytes, CopyOptions -> Request.Request(Bool, Reply.Error)
	copy = |source, destination, options| {
		database = match options.database {
			Absent => []
			Present(value) => [Bytes.from_str("DB"), decimal(value)]
		}
		replace = if options.replace {
			[Bytes.from_str("REPLACE")]
		} else {
			[]
		}
		Request.new(Command.new("COPY", [source, destination].concat(database).concat(replace)), Reply.integer_boolean)
	}

	restore : Bytes.Bytes, U64, Bytes.Bytes, RestoreOptions -> Request.Request({}, Reply.Error)
	restore = |key, ttl_ms, payload, options| {
		replace = if options.replace {
			[Bytes.from_str("REPLACE")]
		} else {
			[]
		}
		absolute = if options.absolute_ttl {
			[Bytes.from_str("ABSTTL")]
		} else {
			[]
		}
		eviction = match options.eviction {
			Default => []
			IdleSeconds(value) => [Bytes.from_str("IDLETIME"), decimal(value)]
			Frequency(value) => [Bytes.from_str("FREQ"), Bytes.from_str(value.to_str())]
		}
		Request.new(Command.new("RESTORE", [key, decimal(ttl_ms), payload].concat(replace).concat(absolute).concat(eviction)), Reply.okay)
	}

	scan : Bytes.Bytes, ScanOptions -> Request.Request({ cursor : Bytes.Bytes, values : List(Bytes.Bytes) }, Reply.Error)
	scan = |cursor, options| {
		pattern = match options.pattern {
			Absent => []
			Present(value) => [Bytes.from_str("MATCH"), value]
		}
		count = match options.count {
			Absent => []
			Present(value) => [Bytes.from_str("COUNT"), decimal(value)]
		}
		kind = match options.kind {
			Absent => []
			Present(value) => [Bytes.from_str("TYPE"), value]
		}
		Request.new(Command.new("SCAN", [cursor].concat(pattern).concat(count).concat(kind)), |reply| Decode.scan(reply, Decode.bytes_list))
	}

	sort : Bytes.Bytes, SortOptions, SortMode -> Request.Request(SortResult, Reply.Error)
	sort = |key, options, mode| {
		store = match mode {
			Values => []
			Store(destination) => [Bytes.from_str("STORE"), destination]
		}
		Request.new(
			Command.new("SORT", [key].concat(sort_args(options)).concat(store)),
			|reply| match mode {
				Values => Decode.list(reply, Decode.optional_bytes).map_ok(|values| Values(values))
				Store(_) => Reply.integer(reply).map_ok(|count| Stored(count))
			},
		)
	}

	sort_ro : Bytes.Bytes, SortOptions -> Request.Request(List(Reply.Optional(Bytes.Bytes)), Reply.Error)
	sort_ro = |key, options| Request.new(Command.new("SORT_RO", [key].concat(sort_args(options))), |reply| Decode.list(reply, Decode.optional_bytes))

	## Redis's migration I/O errors may leave copies at both source and target.
	## Never infer that a server error makes retrying a migration safe.
	migrate : Bytes.Bytes, U16, MigrateKeys, U64, U64, MigrateOptions -> Request.Request(MigrateResult, Reply.Error)
	migrate = |host, port, selected_keys, database, timeout_ms, options| {
		selection = match selected_keys {
			One(key) => { key, tail: [] }
			Many(values) => { key: Bytes.from_str(""), tail: [Bytes.from_str("KEYS")].concat(values.to_list()) }
		}
		copy_args = if options.copy {
			[Bytes.from_str("COPY")]
		} else {
			[]
		}
		replace = if options.replace {
			[Bytes.from_str("REPLACE")]
		} else {
			[]
		}
		authentication = match options.authentication {
			None => []
			Password(password) => [Bytes.from_str("AUTH"), password]
			User(credentials) => [Bytes.from_str("AUTH2"), credentials.username, credentials.password]
		}
		Request.new(
			Command.new("MIGRATE", [host, Bytes.from_str(port.to_str()), selection.key, decimal(database), decimal(timeout_ms)].concat(copy_args).concat(replace).concat(authentication).concat(selection.tail)),
			|reply| match reply {
				SimpleString(['O', 'K']) => Ok(Migrated)
				SimpleString(['N', 'O', 'K', 'E', 'Y']) => Ok(NoKeys)
				_ => Err(UnexpectedReply({ actual: reply, expected: SimpleReply }))
			},
		)
	}

	wait_aof : Bool, U64, U64 -> Request.Request({ local : I64, replicas : I64 }, Reply.Error)
	wait_aof = |local, replicas, timeout_ms| Request.new(
		Command.new(
			"WAITAOF",
			[
				if local {
					Bytes.from_str("1")
				} else {
					Bytes.from_str("0")
				},
				decimal(replicas),
				decimal(timeout_ms),
			],
		),
		|reply| match reply {
			Array([local_reply, replica_reply]) => Ok({ local: Reply.integer(local_reply)?, replicas: Reply.integer(replica_reply)? })
			_ => Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
		},
	)
}

decimal : U64 -> Bytes.Bytes
decimal = |value| Bytes.from_str(value.to_str())

signed : I64 -> Bytes.Bytes
signed = |value| Bytes.from_str(value.to_str())

condition_args : Keyspace.ExpireCondition -> List(Bytes.Bytes)
condition_args = |condition| match condition {
	Always => []
	IfPersistent => ["NX"]
	IfExpiring => ["XX"]
	IfLater => ["GT"]
	IfEarlier => ["LT"]
	IfExpiringLater => ["XX", "GT"]
	IfExpiringEarlier => ["XX", "LT"]
}

expiration_value : Resp.Resp -> Try(Keyspace.ExpirationValue, Reply.Error)
expiration_value = |reply| match reply {
	Integer(-2) => Ok(MissingKey)
	Integer(-1) => Ok(Persistent)
	Integer(value) if value >= 0 => Ok(Value(value.to_u64_wrap()))
	_ => Err(UnexpectedReply({ actual: reply, expected: IntegerReply }))
}

optional_integer : Resp.Resp -> Try(Reply.Optional(I64), Reply.Error)
optional_integer = |reply| match reply {
	NullBulkString => Ok(Absent)
	_ => Reply.integer(reply).map_ok(|value| Present(value))
}

sort_args : Keyspace.SortOptions -> List(Bytes.Bytes)
sort_args = |options| {
	by = match options.by {
		Absent => []
		Present(value) => [Bytes.from_str("BY"), value]
	}
	limit = match options.limit {
		Absent => []
		Present(value) => [Bytes.from_str("LIMIT"), signed(value.offset), signed(value.count)]
	}
	get = options.get.join_map(|pattern| [Bytes.from_str("GET"), pattern])
	order = match options.order {
		Ascending => Bytes.from_str("ASC")
		Descending => Bytes.from_str("DESC")
	}
	alpha = if options.alpha {
		[Bytes.from_str("ALPHA")]
	} else {
		[]
	}
	by.concat(limit).concat(get).append(order).concat(alpha)
}

expect Keyspace.ttl("key").decode(Resp.Integer(-2)) == Ok(MissingKey)
expect Keyspace.ttl("key").decode(Resp.Integer(-3)).is_err()
expect Keyspace.expire("key", -1, IfExpiringLater).command() == Command.new("EXPIRE", ["key", "-1", "XX", "GT"])
expect Keyspace.sort("key", Keyspace.SortOptions.{ get: ["missing:*"] }, Values).decode(Resp.Array([Resp.NullBulkString])) == Ok(Values([Absent]))
expect Keyspace.sort("key", Keyspace.SortOptions.{}, Store("out")).decode(Resp.Integer(2)) == Ok(Stored(2))
expect Keyspace.wait_aof(True, 2, 100).decode(Resp.Array([Resp.Integer(1), Resp.Integer(2)])) == Ok({ local: 1, replicas: 2 })
expect Keyspace.copy("a", "b", Keyspace.CopyOptions.{ database: Present(2), replace: True }).command() == Command.new("COPY", ["a", "b", "DB", "2", "REPLACE"])
