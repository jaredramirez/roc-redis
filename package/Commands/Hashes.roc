import /Bytes
import /Command
import /Commands/Decode
import /NonEmpty
import /Positive
import /Reply
import /Request
import /Resp

Hashes :: [].{
	Pair : { field : Bytes.Bytes, value : Bytes.Bytes }
	ExpireCondition : [Always, IfPersistent, IfExpiring, IfLater, IfEarlier]
	ExpireResult : [MissingField, ConditionNotMet, ExpirationSet, Deleted]
	PersistResult : [MissingField, AlreadyPersistent, Persisted]
	ExpirationValue : [MissingField, Persistent, Value(U64)]
	ReadExpiration : [Unchanged, Persist, Seconds(Positive.Positive), Milliseconds(Positive.Positive), UnixSeconds(Positive.Positive), UnixMilliseconds(Positive.Positive)]
	WriteExpiration : [ClearTtl, KeepTtl, Seconds(Positive.Positive), Milliseconds(Positive.Positive), UnixSeconds(Positive.Positive), UnixMilliseconds(Positive.Positive)]
	SetOptions := { condition : [Always, IfAllMissing, IfAllPresent] ?? Always, expiration : WriteExpiration ?? ClearTtl }
	RandomMode : [One, Fields(I64), WithValues(I64)]
	RandomResult : [One(Reply.Optional(Bytes.Bytes)), Fields(List(Bytes.Bytes)), WithValues(List(Pair))]
	ScanMode : [Fields, WithValues]
	ScanOptions := { pattern : Reply.Optional(Bytes.Bytes) ?? Absent, count : Reply.Optional(U64) ?? Absent }
	ScanResult : [Fields({ cursor : Bytes.Bytes, values : List(Bytes.Bytes) }), WithValues({ cursor : Bytes.Bytes, values : List(Pair) })]
	hdel : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	hdel = |key, fields| Request.new(Command.new("HDEL", [key].concat(fields.to_list())), Reply.integer)

	hexists : Bytes.Bytes, Bytes.Bytes -> Request.Request(Bool, Reply.Error)
	hexists = |key, field| Request.new(Command.new("HEXISTS", [key, field]), Reply.integer_boolean)

	hget : Bytes.Bytes, Bytes.Bytes -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	hget = |key, field| Request.new(Command.new("HGET", [key, field]), Decode.optional_bytes)

	hget_all : Bytes.Bytes -> Request.Request(List(Pair), Reply.Error)
	hget_all = |key| Request.new(Command.new("HGETALL", [key]), pairs)

	hincr_by : Bytes.Bytes, Bytes.Bytes, I64 -> Request.Request(I64, Reply.Error)
	hincr_by = |key, field, amount| Request.new(Command.new("HINCRBY", [key, field, signed(amount)]), Reply.integer)

	hincr_by_float : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes -> Request.Request(Bytes.Bytes, Reply.Error)
	hincr_by_float = |key, field, amount| Request.new(Command.new("HINCRBYFLOAT", [key, field, amount]), Decode.bytes)

	hkeys : Bytes.Bytes -> Request.Request(List(Bytes.Bytes), Reply.Error)
	hkeys = |key| Request.new(Command.new("HKEYS", [key]), Decode.bytes_list)

	hlen : Bytes.Bytes -> Request.Request(I64, Reply.Error)
	hlen = |key| Request.new(Command.new("HLEN", [key]), Reply.integer)

	hvals : Bytes.Bytes -> Request.Request(List(Bytes.Bytes), Reply.Error)
	hvals = |key| Request.new(Command.new("HVALS", [key]), Decode.bytes_list)

	hstrlen : Bytes.Bytes, Bytes.Bytes -> Request.Request(I64, Reply.Error)
	hstrlen = |key, field| Request.new(Command.new("HSTRLEN", [key, field]), Reply.integer)

	hset : Bytes.Bytes, NonEmpty.NonEmpty(Pair) -> Request.Request(I64, Reply.Error)
	hset = |key, values| Request.new(Command.new("HSET", [key].concat(pair_args(values))), Reply.integer)

	hmset : Bytes.Bytes, NonEmpty.NonEmpty(Pair) -> Request.Request({}, Reply.Error)
	hmset = |key, values| Request.new(Command.new("HMSET", [key].concat(pair_args(values))), Reply.okay)

	hset_nx : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes -> Request.Request(Bool, Reply.Error)
	hset_nx = |key, field, value| Request.new(Command.new("HSETNX", [key, field, value]), Reply.integer_boolean)

	hexpire : Bytes.Bytes, I64, ExpireCondition, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(ExpireResult), Reply.Error)
	hexpire = |key, time, condition, fields| Request.new(Command.new("HEXPIRE", [key, signed(time)].concat(condition_args(condition)).concat(field_args(fields))), |reply| Decode.counted(reply, fields.len(), expire_result))

	hexpire_at : Bytes.Bytes, I64, ExpireCondition, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(ExpireResult), Reply.Error)
	hexpire_at = |key, time, condition, fields| Request.new(Command.new("HEXPIREAT", [key, signed(time)].concat(condition_args(condition)).concat(field_args(fields))), |reply| Decode.counted(reply, fields.len(), expire_result))

	hpexpire : Bytes.Bytes, I64, ExpireCondition, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(ExpireResult), Reply.Error)
	hpexpire = |key, time, condition, fields| Request.new(Command.new("HPEXPIRE", [key, signed(time)].concat(condition_args(condition)).concat(field_args(fields))), |reply| Decode.counted(reply, fields.len(), expire_result))

	hpexpire_at : Bytes.Bytes, I64, ExpireCondition, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(ExpireResult), Reply.Error)
	hpexpire_at = |key, time, condition, fields| Request.new(Command.new("HPEXPIREAT", [key, signed(time)].concat(condition_args(condition)).concat(field_args(fields))), |reply| Decode.counted(reply, fields.len(), expire_result))

	## The numeric TTL value is in the command's units. For EXPIRETIME variants
	## it is an absolute Unix timestamp rather than a remaining duration.
	httl : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(ExpirationValue), Reply.Error)
	httl = |key, fields| Request.new(Command.new("HTTL", [key].concat(field_args(fields))), |reply| Decode.counted(reply, fields.len(), ttl_result))

	hpttl : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(ExpirationValue), Reply.Error)
	hpttl = |key, fields| Request.new(Command.new("HPTTL", [key].concat(field_args(fields))), |reply| Decode.counted(reply, fields.len(), ttl_result))

	hexpire_time : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(ExpirationValue), Reply.Error)
	hexpire_time = |key, fields| Request.new(Command.new("HEXPIRETIME", [key].concat(field_args(fields))), |reply| Decode.counted(reply, fields.len(), ttl_result))

	hpexpire_time : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(ExpirationValue), Reply.Error)
	hpexpire_time = |key, fields| Request.new(Command.new("HPEXPIRETIME", [key].concat(field_args(fields))), |reply| Decode.counted(reply, fields.len(), ttl_result))

	hpersist : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(PersistResult), Reply.Error)
	hpersist = |key, fields| Request.new(Command.new("HPERSIST", [key].concat(field_args(fields))), |reply| Decode.counted(reply, fields.len(), persist_result))

	hmget : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(Reply.Optional(Bytes.Bytes)), Reply.Error)
	hmget = |key, fields| Request.new(Command.new("HMGET", [key].concat(fields.to_list())), |reply| Decode.counted(reply, fields.len(), Decode.optional_bytes))

	hget_del : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(Reply.Optional(Bytes.Bytes)), Reply.Error)
	hget_del = |key, fields| Request.new(Command.new("HGETDEL", [key].concat(field_args(fields))), |reply| Decode.counted(reply, fields.len(), Decode.optional_bytes))

	hget_ex : Bytes.Bytes, ReadExpiration, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(Reply.Optional(Bytes.Bytes)), Reply.Error)
	hget_ex = |key, expiration, fields| Request.new(Command.new("HGETEX", [key].concat(read_expiration_args(expiration)).concat(field_args(fields))), |reply| Decode.counted(reply, fields.len(), Decode.optional_bytes))

	hset_ex : Bytes.Bytes, NonEmpty.NonEmpty(Pair), SetOptions -> Request.Request(Bool, Reply.Error)
	hset_ex = |key, values, options| {
		condition = match options.condition {
			Always => []
			IfAllMissing => [Bytes.from_str("FNX")]
			IfAllPresent => [Bytes.from_str("FXX")]
		}
		Request.new(Command.new("HSETEX", [key].concat(condition).concat(write_expiration_args(options.expiration)).concat(["FIELDS", decimal(values.len())]).concat(pair_args(values))), Reply.integer_boolean)
	}

	hrand_field : Bytes.Bytes, RandomMode -> Request.Request(RandomResult, Reply.Error)
	hrand_field = |key, mode| Request.new(
		Command.new(
			"HRANDFIELD",
			[key].concat(
				match mode {
					One => []
					Fields(count) => [signed(count)]
					WithValues(count) => [signed(count), Bytes.from_str("WITHVALUES")]
				},
			),
		),
		|reply| match mode {
			One => Decode.optional_bytes(reply).map_ok(|value| One(value))
			Fields(_) => Decode.bytes_list(reply).map_ok(|values| Fields(values))
			WithValues(_) => pairs(reply).map_ok(|values| WithValues(values))
		},
	)

	hscan : Bytes.Bytes, Bytes.Bytes, ScanMode, ScanOptions -> Request.Request(ScanResult, Reply.Error)
	hscan = |key, cursor, mode, options| {
		pattern = match options.pattern {
			Absent => []
			Present(value) => [Bytes.from_str("MATCH"), value]
		}
		count = match options.count {
			Absent => []
			Present(value) => [Bytes.from_str("COUNT"), decimal(value)]
		}
		values = match mode {
			Fields => [Bytes.from_str("NOVALUES")]
			WithValues => []
		}
		Request.new(
			Command.new("HSCAN", [key, cursor].concat(pattern).concat(count).concat(values)),
			|reply| match mode {
				Fields => Decode.scan(reply, Decode.bytes_list).map_ok(|page| Fields(page))
				WithValues => Decode.scan(reply, pairs).map_ok(|page| WithValues(page))
			},
		)
	}

	## HIMPORT fieldsets are local to the connection. Keep the same exclusive
	## connection across PREPARE and SET; Redis checks duplicate fields and the
	## value count. Do not silently reprepare or retry on a replacement stream.
	himport_prepare : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request({}, Reply.Error)
	himport_prepare = |name, fields| Request.new(Command.new("HIMPORT", ["PREPARE", name].concat(fields.to_list())), Reply.okay)

	himport_set : Bytes.Bytes, Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request({}, Reply.Error)
	himport_set = |key, name, values| Request.new(Command.new("HIMPORT", ["SET", key, name].concat(values.to_list())), Reply.okay)

	himport_discard : Bytes.Bytes -> Request.Request(Bool, Reply.Error)
	himport_discard = |name| Request.new(Command.new("HIMPORT", ["DISCARD", name]), Reply.integer_boolean)

	himport_discard_all : {} -> Request.Request(I64, Reply.Error)
	himport_discard_all = |_| Request.new(Command.new("HIMPORT", ["DISCARDALL"]), Reply.integer)
}

decimal : U64 -> Bytes.Bytes
decimal = |value| Bytes.from_str(value.to_str())

signed : I64 -> Bytes.Bytes
signed = |value| Bytes.from_str(value.to_str())

field_args : NonEmpty.NonEmpty(Bytes.Bytes) -> List(Bytes.Bytes)
field_args = |fields| [Bytes.from_str("FIELDS"), decimal(fields.len())].concat(fields.to_list())

pair_args : NonEmpty.NonEmpty(Hashes.Pair) -> List(Bytes.Bytes)
pair_args = |values| values.to_list().join_map(|pair| [pair.field, pair.value])

pairs : Resp.Resp -> Try(List(Hashes.Pair), Reply.Error)
pairs = |reply| {
	items = Reply.array(reply)?
	if items.len() % 2 != 0 {
		return Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
	}
	var $pairs = List.with_capacity(items.len() / 2)
	var $remaining = items
	while !$remaining.is_empty() {
		match $remaining {
			[field, value, .. as rest] => {
				$pairs = $pairs.append({ field: Decode.bytes(field)?, value: Decode.bytes(value)? })
				$remaining = rest
			}
			_ => {
				return Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
			}
		}
	}
	Ok($pairs)
}

condition_args : Hashes.ExpireCondition -> List(Bytes.Bytes)
condition_args = |condition| match condition {
	Always => []
	IfPersistent => ["NX"]
	IfExpiring => ["XX"]
	IfLater => ["GT"]
	IfEarlier => ["LT"]
}

expire_result : Resp.Resp -> Try(Hashes.ExpireResult, Reply.Error)
expire_result = |reply| match reply {
	Integer(-2) => Ok(MissingField)
	Integer(0) => Ok(ConditionNotMet)
	Integer(1) => Ok(ExpirationSet)
	Integer(2) => Ok(Deleted)
	_ => Err(UnexpectedReply({ actual: reply, expected: IntegerReply }))
}

persist_result : Resp.Resp -> Try(Hashes.PersistResult, Reply.Error)
persist_result = |reply| match reply {
	Integer(-2) => Ok(MissingField)
	Integer(-1) => Ok(AlreadyPersistent)
	Integer(1) => Ok(Persisted)
	_ => Err(UnexpectedReply({ actual: reply, expected: IntegerReply }))
}

ttl_result : Resp.Resp -> Try(Hashes.ExpirationValue, Reply.Error)
ttl_result = |reply| match reply {
	Integer(-2) => Ok(MissingField)
	Integer(-1) => Ok(Persistent)
	Integer(value) if value >= 0 => Ok(Value(value.to_u64_wrap()))
	_ => Err(UnexpectedReply({ actual: reply, expected: IntegerReply }))
}

read_expiration_args : Hashes.ReadExpiration -> List(Bytes.Bytes)
read_expiration_args = |expiration| match expiration {
	Unchanged => []
	Persist => ["PERSIST"]
	Seconds(value) => ["EX", decimal(value.to_u64())]
	Milliseconds(value) => ["PX", decimal(value.to_u64())]
	UnixSeconds(value) => ["EXAT", decimal(value.to_u64())]
	UnixMilliseconds(value) => ["PXAT", decimal(value.to_u64())]
}

write_expiration_args : Hashes.WriteExpiration -> List(Bytes.Bytes)
write_expiration_args = |expiration| match expiration {
	ClearTtl => []
	KeepTtl => ["KEEPTTL"]
	Seconds(value) => ["EX", decimal(value.to_u64())]
	Milliseconds(value) => ["PX", decimal(value.to_u64())]
	UnixSeconds(value) => ["EXAT", decimal(value.to_u64())]
	UnixMilliseconds(value) => ["PXAT", decimal(value.to_u64())]
}

expect Hashes.hget_all("hash").decode(Resp.Array([Resp.bulk_utf8("field"), Resp.BulkString([0, 255])])) == Ok([{ field: Bytes.from_str("field"), value: Bytes.from_list([0, 255]) }])
expect Hashes.hget_all("hash").decode(Resp.Array([Resp.bulk_utf8("field")])).is_err()
expect Hashes.hmget("hash", NonEmpty.new(Bytes.from_str("field"), [])).decode(Resp.Array([])).is_err()
expect Hashes.hexpire("hash", 0, Always, NonEmpty.new(Bytes.from_str("field"), [])).decode(Resp.Array([Resp.Integer(2)])) == Ok([Deleted])
expect Hashes.httl("hash", NonEmpty.new(Bytes.from_str("a"), ["b", "c"])).decode(Resp.Array([Resp.Integer(-2), Resp.Integer(-1), Resp.Integer(0)])) == Ok([MissingField, Persistent, Value(0)])
expect Hashes.hpersist("hash", NonEmpty.new(Bytes.from_str("field"), [])).decode(Resp.Array([Resp.Integer(0)])).is_err()
expect Hashes.hset_ex("hash", NonEmpty.new({ field: Bytes.from_str("a"), value: Bytes.from_str("b") }, []), Hashes.SetOptions.{ condition: IfAllMissing }).command() == Command.new("HSETEX", ["hash", "FNX", "FIELDS", "1", "a", "b"])
expect Hashes.hrand_field("hash", WithValues(-2)).command() == Command.new("HRANDFIELD", ["hash", "-2", "WITHVALUES"])
expect Hashes.hscan("hash", "0", Fields, Hashes.ScanOptions.{}).decode(Resp.Array([Resp.bulk_utf8("0"), Resp.Array([Resp.bulk_utf8("field")])])) == Ok(Fields({ cursor: Bytes.from_str("0"), values: [Bytes.from_str("field")] }))
