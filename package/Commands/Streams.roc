import /Bytes
import /Command
import /Commands/Decode
import /NonEmpty
import /Positive
import /Reply
import /Request
import /Resp

## Stream IDs remain binary-safe Redis syntax. Fields are ordered pairs,
## preserving duplicates. Blocking timeouts are distinct from transport timeouts.
Streams :: [].{
	Field : { field : Bytes.Bytes, value : Bytes.Bytes }
	Entry : { id : Bytes.Bytes, fields : Reply.Optional(List(Field)), claimed : Reply.Optional({ idle_ms : I64, deliveries : I64 }) }
	Stream : { key : Bytes.Bytes, entries : List(Entry) }
	ReferencePolicy : [Keep, Delete, Acknowledged]
	DeleteResult : [Missing, Deleted, Referenced]
	TrimStrategy : [Length(U64), MinimumId(Bytes.Bytes)]
	Trim : [Exact(TrimStrategy), Approximate(TrimStrategy, Reply.Optional(U64))]
	AddOptions := { no_create : Bool ?? False, references : ReferencePolicy ?? Keep, idempotency : [None, Automatic(Bytes.Bytes), Explicit({ producer : Bytes.Bytes, id : Bytes.Bytes })] ?? None, trim : Reply.Optional(Trim) ?? Absent }
	ReadOptions := { count : Reply.Optional(Positive.Positive) ?? Absent, max_count : Reply.Optional(Positive.Positive) ?? Absent, max_bytes : Reply.Optional(Positive.Positive) ?? Absent, block_ms : Reply.Optional(U64) ?? Absent }
	GroupReadOptions := { read : ReadOptions ?? ReadOptions.{}, claim_idle_ms : Reply.Optional(U64) ?? Absent, no_ack : Bool ?? False }
	Source : { key : Bytes.Bytes, id : Bytes.Bytes }
	ClaimMode : [Entries, Ids]
	ClaimResult : [Entries(List(Entry)), Ids(List(Bytes.Bytes))]
	ClaimOptions := { time : [Default, Idle(U64), UnixMilliseconds(U64)] ?? Default, retry_count : Reply.Optional(U64) ?? Absent, force : Bool ?? False, last_id : Reply.Optional(Bytes.Bytes) ?? Absent }
	GroupOptions := { create_stream : Bool ?? False, entries_read : Reply.Optional(I64) ?? Absent }
	PendingMode : [Summary, Entries({ start : Bytes.Bytes, end : Bytes.Bytes, count : Positive.Positive, idle_ms : Reply.Optional(U64), consumer : Reply.Optional(Bytes.Bytes) })]
	Pending : { id : Bytes.Bytes, consumer : Bytes.Bytes, idle_ms : I64, deliveries : I64 }
	PendingResult : [Summary({ count : I64, first : Reply.Optional(Bytes.Bytes), last : Reply.Optional(Bytes.Bytes), consumers : Reply.Optional(List({ consumer : Bytes.Bytes, count : U64 })) }), Entries(List(Pending))]

	xadd : Bytes.Bytes, Bytes.Bytes, NonEmpty.NonEmpty(Field), AddOptions -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	xadd = |key, id, fields, options| {
		var $args = [key]
		if options.no_create {
			$args = $args.append("NOMKSTREAM")
		}
		$args = $args.concat(
			if options.references == Keep {
				[]
			} else {
				[policy_arg(options.references)]
			},
		)
		$args = $args.concat(
			match options.idempotency {
				None => []
				Automatic(producer) => ["IDMPAUTO", producer]
				Explicit(value) => ["IDMP", value.producer, value.id]
			},
		)
		$args = $args.concat(
			match options.trim {
				Absent => []
				Present(trim) => trim_args(trim)
			},
		).append(id)
		for field in fields.to_list() {
			$args = $args.concat([field.field, field.value])
		}
		Request.new(Command.new("XADD", $args), Decode.optional_bytes)
	}

	xtrim : Bytes.Bytes, Trim, ReferencePolicy -> Request.Request(I64, Reply.Error)
	xtrim = |key, trim, policy| Request.new(
		Command.new(
			"XTRIM",
			[key].concat(trim_args(trim)).concat(
				if policy == Keep {
					[]
				} else {
					[policy_arg(policy)]
				},
			),
		),
		Reply.integer,
	)

	xread : NonEmpty.NonEmpty(Source), ReadOptions -> Request.Request(Reply.Optional(List(Stream)), Reply.Error)
	xread = |sources, options| Request.new(Command.new("XREAD", read_args(options).concat(source_args(sources))), |reply| read_reply(reply, False, False))

	xread_group : Bytes.Bytes, Bytes.Bytes, NonEmpty.NonEmpty(Source), GroupReadOptions -> Request.Request(Reply.Optional(List(Stream)), Reply.Error)
	xread_group = |group, consumer, sources, options| {
		args = ["GROUP", group, consumer].concat(read_args(options.read)).concat(number_option("CLAIM", options.claim_idle_ms)).concat(
			if options.no_ack {
				["NOACK"]
			} else {
				[]
			},
		).concat(source_args(sources))
		allow_claimed = match options.claim_idle_ms {
			Absent => False
			Present(_) => True
		}
		Request.new(Command.new("XREADGROUP", args), |reply| read_reply(reply, True, allow_claimed))
	}

	xclaim : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes, U64, NonEmpty.NonEmpty(Bytes.Bytes), ClaimMode, ClaimOptions -> Request.Request(ClaimResult, Reply.Error)
	xclaim = |key, group, consumer, idle_ms, ids, mode, options| {
		args = [key, group, consumer, decimal(idle_ms)].concat(ids.to_list())
			.concat(
				match options.time {
					Default => []
					Idle(value) => ["IDLE", decimal(value)]
					UnixMilliseconds(value) => ["TIME", decimal(value)]
				},
			)
			.concat(number_option("RETRYCOUNT", options.retry_count)).concat(
			if options.force {
				["FORCE"]
			} else {
				[]
			},
		)
			.concat(mode_args(mode)).concat(bytes_option("LASTID", options.last_id))
		Request.new(Command.new("XCLAIM", args), |reply| claim_reply(reply, mode))
	}

	## Redis 7+ returns removed IDs as the third element. Redis 6.2 omitted it;
	## both documented forms are supported without merging null kinds.
	xauto_claim : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes, U64, Bytes.Bytes, Reply.Optional(Positive.Positive), ClaimMode -> Request.Request({ next : Bytes.Bytes, claimed : ClaimResult, deleted : List(Bytes.Bytes) }, Reply.Error)
	xauto_claim = |key, group, consumer, idle_ms, start, count, mode| Request.new(
		Command.new("XAUTOCLAIM", [key, group, consumer, decimal(idle_ms), start].concat(positive_option("COUNT", count)).concat(mode_args(mode))),
		|reply| match reply {
			Array([next, claimed]) => Ok({ next: Decode.bytes(next)?, claimed: claim_reply(claimed, mode)?, deleted: [] })
			Array([next, claimed, deleted]) => Ok({ next: Decode.bytes(next)?, claimed: claim_reply(claimed, mode)?, deleted: Decode.bytes_list(deleted)? })
			_ => Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
		},
	)

	xpending : Bytes.Bytes, Bytes.Bytes, PendingMode -> Request.Request(PendingResult, Reply.Error)
	xpending = |key, group, mode| {
		args = [key, group].concat(
			match mode {
				Summary => []
				Entries(options) => number_option("IDLE", options.idle_ms).concat([options.start, options.end, decimal(options.count.to_u64())]).concat(
					match options.consumer {
						Absent => []
						Present(consumer) => [consumer]
					},
				)
			},
		)
		Request.new(
			Command.new("XPENDING", args),
			|reply| match mode {
				Summary => pending_summary(reply).map_ok(|value| Summary(value))
				Entries(_) => Decode.list(reply, pending_entry).map_ok(|values| Entries(values))
			},
		)
	}

	xgroup_create : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes, GroupOptions -> Request.Request({}, Reply.Error)
	xgroup_create = |key, group, id, options| Request.new(
		Command.new(
			"XGROUP",
			["CREATE", key, group, id].concat(
				if options.create_stream {
					["MKSTREAM"]
				} else {
					[]
				},
			).concat(signed_option("ENTRIESREAD", options.entries_read)),
		),
		Reply.okay,
	)

	xgroup_set_id : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes, Reply.Optional(I64) -> Request.Request({}, Reply.Error)
	xgroup_set_id = |key, group, id, entries_read| Request.new(Command.new("XGROUP", ["SETID", key, group, id].concat(signed_option("ENTRIESREAD", entries_read))), Reply.okay)

	xnack : Bytes.Bytes, Bytes.Bytes, [Silent, Fail, Fatal], NonEmpty.NonEmpty(Bytes.Bytes), { retry_count : Reply.Optional(U64), force : Bool } -> Request.Request(I64, Reply.Error)
	xnack = |key, group, mode, ids, options| Request.new(
		Command.new(
			"XNACK",
			[
				key,
				group,
				match mode {
					Silent => "SILENT"
					Fail => "FAIL"
					Fatal => "FATAL"
				},
			].concat(ids_args(ids)).concat(number_option("RETRYCOUNT", options.retry_count)).concat(
				if options.force {
					["FORCE"]
				} else {
					[]
				},
			),
		),
		Reply.integer,
	)

	xcfg_set : Bytes.Bytes, { duration_seconds : Reply.Optional(U64), max_size : Reply.Optional(U64) } -> Request.Request({}, Reply.Error)
	xcfg_set = |key, settings| Request.new(Command.new("XCFGSET", [key].concat(number_option("IDMP-DURATION", settings.duration_seconds)).concat(number_option("IDMP-MAXSIZE", settings.max_size))), Reply.okay)

	## XINFO schemas are version-extensible, including FULL's nested group state.
	xinfo_stream : Bytes.Bytes, [Summary, Full(Reply.Optional(U64))], (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	xinfo_stream = |key, mode, decode| Request.new(
		Command.new(
			"XINFO",
			["STREAM", key].concat(
				match mode {
					Summary => []
					Full(count) => ["FULL"].concat(number_option("COUNT", count))
				},
			),
		),
		decode,
	)

	xack : Bytes.Bytes, Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	xack = |key, group, ids| Request.new(Command.new("XACK", [key, group].concat(ids.to_list())), Reply.integer)

	xdel : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	xdel = |key, ids| Request.new(Command.new("XDEL", [key].concat(ids.to_list())), Reply.integer)

	xlen : Bytes.Bytes -> Request.Request(I64, Reply.Error)
	xlen = |key| Request.new(Command.new("XLEN", [key]), Reply.integer)

	xgroup_create_consumer : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes -> Request.Request(Bool, Reply.Error)
	xgroup_create_consumer = |key, group, consumer| Request.new(Command.new("XGROUP", ["CREATECONSUMER", key, group, consumer]), Reply.integer_boolean)

	xgroup_del_consumer : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes -> Request.Request(I64, Reply.Error)
	xgroup_del_consumer = |key, group, consumer| Request.new(Command.new("XGROUP", ["DELCONSUMER", key, group, consumer]), Reply.integer)

	xgroup_destroy : Bytes.Bytes, Bytes.Bytes -> Request.Request(Bool, Reply.Error)
	xgroup_destroy = |key, group| Request.new(Command.new("XGROUP", ["DESTROY", key, group]), Reply.integer_boolean)

	xack_del : Bytes.Bytes, Bytes.Bytes, ReferencePolicy, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(DeleteResult), Reply.Error)
	xack_del = |key, group, policy, ids| Request.new(Command.new("XACKDEL", [key, group, policy_arg(policy)].concat(ids_args(ids))), |reply| Decode.counted(reply, ids.len(), delete_reply))

	xdel_ex : Bytes.Bytes, ReferencePolicy, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(DeleteResult), Reply.Error)
	xdel_ex = |key, policy, ids| Request.new(Command.new("XDELEX", [key, policy_arg(policy)].concat(ids_args(ids))), |reply| Decode.counted(reply, ids.len(), delete_reply))

	xrange : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes, Reply.Optional(Positive.Positive) -> Request.Request(List(Entry), Reply.Error)
	xrange = |key, start, end, count| Request.new(Command.new("XRANGE", [key, start, end].concat(positive_option("COUNT", count))), |reply| Decode.list(reply, |entry| entry_reply(entry, False, False)))

	xrev_range : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes, Reply.Optional(Positive.Positive) -> Request.Request(List(Entry), Reply.Error)
	xrev_range = |key, start, end, count| Request.new(Command.new("XREVRANGE", [key, end, start].concat(positive_option("COUNT", count))), |reply| Decode.list(reply, |entry| entry_reply(entry, False, False)))

	xinfo_consumers : Bytes.Bytes, Bytes.Bytes, (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	xinfo_consumers = |key, group, decode| Request.new(Command.new("XINFO", ["CONSUMERS", key, group]), decode)

	xinfo_groups : Bytes.Bytes, (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	xinfo_groups = |key, decode| Request.new(Command.new("XINFO", ["GROUPS", key]), decode)
}

decimal : U64 -> Bytes.Bytes
decimal = |value| Bytes.from_str(value.to_str())

number_option : Bytes.Bytes, Reply.Optional(U64) -> List(Bytes.Bytes)
number_option = |name, value| match value {
	Absent => []
	Present(number) => [name, decimal(number)]
}

positive_option : Bytes.Bytes, Reply.Optional(Positive.Positive) -> List(Bytes.Bytes)
positive_option = |name, value| match value {
	Absent => []
	Present(number) => [name, decimal(number.to_u64())]
}

signed_option : Bytes.Bytes, Reply.Optional(I64) -> List(Bytes.Bytes)
signed_option = |name, value| match value {
	Absent => []
	Present(number) => [name, Bytes.from_str(number.to_str())]
}

bytes_option : Bytes.Bytes, Reply.Optional(Bytes.Bytes) -> List(Bytes.Bytes)
bytes_option = |name, value| match value {
	Absent => []
	Present(data) => [name, data]
}

policy_arg : Streams.ReferencePolicy -> Bytes.Bytes
policy_arg = |policy| match policy {
	Keep => "KEEPREF"
	Delete => "DELREF"
	Acknowledged => "ACKED"
}

trim_args : Streams.Trim -> List(Bytes.Bytes)
trim_args = |trim| {
	(strategy, operator, limit) = match trim {
		Exact(selected) => (selected, Bytes.from_str("="), Absent)
		Approximate(selected, maximum) => (selected, Bytes.from_str("~"), maximum)
	}
	match strategy {
		Length(count) => ["MAXLEN", operator, decimal(count)].concat(number_option("LIMIT", limit))
		MinimumId(id) => ["MINID", operator, id].concat(number_option("LIMIT", limit))
	}
}

ids_args : NonEmpty.NonEmpty(Bytes.Bytes) -> List(Bytes.Bytes)
ids_args = |ids| ["IDS", decimal(ids.len())].concat(ids.to_list())

read_args : Streams.ReadOptions -> List(Bytes.Bytes)
read_args = |options| positive_option("COUNT", options.count).concat(positive_option("MAXCOUNT", options.max_count)).concat(positive_option("MAXSIZE", options.max_bytes)).concat(number_option("BLOCK", options.block_ms))

source_args : NonEmpty.NonEmpty(Streams.Source) -> List(Bytes.Bytes)
source_args = |sources| {
	values = sources.to_list()
	["STREAMS"].concat(values.map(|source| source.key)).concat(values.map(|source| source.id))
}

mode_args : Streams.ClaimMode -> List(Bytes.Bytes)
mode_args = |mode| match mode {
	Entries => []
	Ids => ["JUSTID"]
}

claim_reply : Resp.Resp, Streams.ClaimMode -> Try(Streams.ClaimResult, Reply.Error)
claim_reply = |reply, mode| match mode {
	Entries => Decode.list(reply, |entry| entry_reply(entry, False, False)).map_ok(|values| Entries(values))
	Ids => Decode.bytes_list(reply).map_ok(|values| Ids(values))
}

delete_reply : Resp.Resp -> Try(Streams.DeleteResult, Reply.Error)
delete_reply = |reply| match reply {
	Integer(-1) => Ok(Missing)
	Integer(1) => Ok(Deleted)
	Integer(2) => Ok(Referenced)
	_ => Err(UnexpectedReply({ actual: reply, expected: IntegerReply }))
}

fields_reply : Resp.Resp, Bool -> Try(Reply.Optional(List(Streams.Field)), Reply.Error)
fields_reply = |reply, allow_deleted| {
	if allow_deleted and reply == Resp.NullArray {
		return Ok(Absent)
	}
	items = Reply.array(reply)?
	if items.len() % 2 != 0 {
		return Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
	}
	var $fields = List.with_capacity(items.len() / 2)
	var $remaining = items
	while !$remaining.is_empty() {
		match $remaining {
			[field, value, .. as rest] => {
				$fields = $fields.append({ field: Decode.bytes(field)?, value: Decode.bytes(value)? })
				$remaining = rest
			}
			_ => return Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
		}
	}
	Ok(Present($fields))
}

entry_reply : Resp.Resp, Bool, Bool -> Try(Streams.Entry, Reply.Error)
entry_reply = |reply, allow_deleted, allow_claimed| match reply {
	Array([id, fields]) => Ok({ id: Decode.bytes(id)?, fields: fields_reply(fields, allow_deleted)?, claimed: Absent })
	Array([id, fields, idle, deliveries]) if allow_claimed => Ok({ id: Decode.bytes(id)?, fields: fields_reply(fields, False)?, claimed: Present({ idle_ms: Reply.integer(idle)?, deliveries: Reply.integer(deliveries)? }) })
	_ => Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
}

read_reply : Resp.Resp, Bool, Bool -> Try(Reply.Optional(List(Streams.Stream)), Reply.Error)
read_reply = |reply, allow_deleted, allow_claimed| match reply {
	NullArray => Ok(Absent)
	_ => Decode.list(
		reply,
		|stream| match stream {
			Array([key, entries]) => Ok({ key: Decode.bytes(key)?, entries: Decode.list(entries, |entry| entry_reply(entry, allow_deleted, allow_claimed))? })
			_ => Err(UnexpectedReply({ actual: stream, expected: ArrayReply }))
		},
	).map_ok(|streams| Present(streams))
}

pending_entry : Resp.Resp -> Try(Streams.Pending, Reply.Error)
pending_entry = |reply| match reply {
	Array([id, consumer, idle, deliveries]) => Ok({ id: Decode.bytes(id)?, consumer: Decode.bytes(consumer)?, idle_ms: Reply.integer(idle)?, deliveries: Reply.integer(deliveries)? })
	_ => Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
}

consumer_count : Resp.Resp -> Try({ consumer : Bytes.Bytes, count : U64 }, Reply.Error)
consumer_count = |reply| match reply {
	Array([consumer, count]) => {
		data = Reply.bulk(count)?
		string = Str.from_utf8(data).map_err(|_| UnexpectedReply({ actual: count, expected: BulkReply }))?
		number = U64.from_str(string).map_err(|_| UnexpectedReply({ actual: count, expected: BulkReply }))?
		Ok({ consumer: Decode.bytes(consumer)?, count: number })
	}
	_ => Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
}

pending_summary : Resp.Resp -> Try({ count : I64, first : Reply.Optional(Bytes.Bytes), last : Reply.Optional(Bytes.Bytes), consumers : Reply.Optional(List({ consumer : Bytes.Bytes, count : U64 })) }, Reply.Error)
pending_summary = |reply| match reply {
	Array([count, first, last, consumers]) => {
		decoded_consumers = match consumers {
			NullArray => Ok(Absent)
			_ => Decode.list(consumers, consumer_count).map_ok(|values| Present(values))
		}?
		Ok({ count: Reply.integer(count)?, first: Decode.optional_bytes(first)?, last: Decode.optional_bytes(last)?, consumers: decoded_consumers })
	}
	_ => Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
}

expect Streams.xread(NonEmpty.new({ key: Bytes.from_str("s"), id: Bytes.from_str("$") }, []), Streams.ReadOptions.{}).decode(Resp.NullArray) == Ok(Absent)
expect Streams.xread(NonEmpty.new({ key: Bytes.from_str("s"), id: Bytes.from_str("$") }, []), Streams.ReadOptions.{}).decode(Resp.NullBulkString).is_err()
expect Streams.xread(NonEmpty.new({ key: Bytes.from_str("a"), id: Bytes.from_str("0") }, [{ key: "b", id: "$" }]), { block_ms: Present(0) }).command() == Command.new("XREAD", ["BLOCK", "0", "STREAMS", "a", "b", "0", "$"])
expect Streams.xadd("s", "*", NonEmpty.new({ field: Bytes.from_str("f"), value: Bytes.from_str("v") }, []), { no_create: True }).decode(Resp.NullBulkString) == Ok(Absent)
expect Streams.xtrim("s", Approximate(Length(100), Present(0)), Delete).command() == Command.new("XTRIM", ["s", "MAXLEN", "~", "100", "LIMIT", "0", "DELREF"])
expect Streams.xack_del("s", "g", Keep, NonEmpty.new(Bytes.from_str("1-0"), [])).decode(Resp.Array([Resp.Integer(-1)])) == Ok([Missing])
expect Streams.xdel_ex("s", Acknowledged, NonEmpty.new(Bytes.from_str("1-0"), [])).decode(Resp.Array([Resp.Integer(0)])).is_err()
expect Streams.xauto_claim("s", "g", "c", 0, "0-0", Absent, Ids).decode(Resp.Array([Resp.bulk_utf8("0-0"), Resp.Array([]), Resp.Array([Resp.bulk_utf8("1-0")])])) == Ok({ next: Bytes.from_str("0-0"), claimed: Ids([]), deleted: [Bytes.from_str("1-0")] })
expect Streams.xpending("s", "g", Summary).decode(Resp.Array([Resp.Integer(0), Resp.NullBulkString, Resp.NullBulkString, Resp.NullArray])) == Ok(Summary({ count: 0, first: Absent, last: Absent, consumers: Absent }))
expect Streams.xpending("s", "g", Summary).decode(Resp.Array([Resp.Integer(1), Resp.bulk_utf8("1-0"), Resp.bulk_utf8("1-0"), Resp.Array([Resp.Array([Resp.bulk_utf8("c"), Resp.bulk_utf8("1")])])])).is_ok()
expect entry_reply(Resp.Array([Resp.bulk_utf8("1-0"), Resp.NullArray]), True, False) == Ok({ id: Bytes.from_str("1-0"), fields: Absent, claimed: Absent })
expect entry_reply(Resp.Array([Resp.bulk_utf8("1-0"), Resp.NullBulkString]), True, False).is_err()
expect entry_reply(Resp.Array([Resp.bulk_utf8("1-0"), Resp.Array([]), Resp.Integer(100), Resp.Integer(2)]), True, True) == Ok({ id: Bytes.from_str("1-0"), fields: Present([]), claimed: Present({ idle_ms: 100, deliveries: 2 }) })
expect entry_reply(Resp.Array([Resp.bulk_utf8("1-0"), Resp.Array([]), Resp.Integer(100), Resp.Integer(2)]), False, False).is_err()
expect Streams.xrev_range("s", "-", "+", Absent).command() == Command.new("XREVRANGE", ["s", "+", "-"])
