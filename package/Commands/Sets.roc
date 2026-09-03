import /Bytes
import /Command
import /Commands/Decode
import /NonEmpty
import /Reply
import /Request
import /Resp

Sets :: [].{
	ScanOptions := { pattern : Reply.Optional(Bytes.Bytes) ?? Absent, count : Reply.Optional(U64) ?? Absent }
	RandomMode : [One, Distinct(U64), WithRepetition(U64)]
	RandomResult : [One(Reply.Optional(Bytes.Bytes)), Many(List(Bytes.Bytes))]
	PopMode : [One, Many(U64)]

	sadd : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	sadd = |key, members| Request.new(Command.new("SADD", [key].concat(members.to_list())), Reply.integer)

	scard : Bytes.Bytes -> Request.Request(I64, Reply.Error)
	scard = |key| Request.new(Command.new("SCARD", [key]), Reply.integer)

	sdiff : NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(Bytes.Bytes), Reply.Error)
	sdiff = |keys| Request.new(Command.new("SDIFF", keys.to_list()), Decode.bytes_list)

	sdiff_card : NonEmpty.NonEmpty(Bytes.Bytes), Reply.Optional(U64) -> Request.Request(I64, Reply.Error)
	sdiff_card = |keys, limit| Request.new(
		Command.new(
			"SDIFFCARD",
			[decimal(keys.len())].concat(keys.to_list()).concat(
				match limit {
					Absent => []
					Present(value) => [Bytes.from_str("LIMIT"), decimal(value)]
				},
			),
		),
		Reply.integer,
	)

	sdiff_store : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	sdiff_store = |destination, keys| Request.new(Command.new("SDIFFSTORE", [destination].concat(keys.to_list())), Reply.integer)

	sinter : NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(Bytes.Bytes), Reply.Error)
	sinter = |keys| Request.new(Command.new("SINTER", keys.to_list()), Decode.bytes_list)

	sinter_card : NonEmpty.NonEmpty(Bytes.Bytes), Reply.Optional(U64) -> Request.Request(I64, Reply.Error)
	sinter_card = |keys, limit| Request.new(
		Command.new(
			"SINTERCARD",
			[decimal(keys.len())].concat(keys.to_list()).concat(
				match limit {
					Absent => []
					Present(value) => [Bytes.from_str("LIMIT"), decimal(value)]
				},
			),
		),
		Reply.integer,
	)

	sinter_store : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	sinter_store = |destination, keys| Request.new(Command.new("SINTERSTORE", [destination].concat(keys.to_list())), Reply.integer)

	sis_member : Bytes.Bytes, Bytes.Bytes -> Request.Request(Bool, Reply.Error)
	sis_member = |key, member| Request.new(Command.new("SISMEMBER", [key, member]), Reply.integer_boolean)

	smis_member : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(Bool), Reply.Error)
	smis_member = |key, members| Request.new(Command.new("SMISMEMBER", [key].concat(members.to_list())), |reply| Decode.counted(reply, members.len(), Reply.integer_boolean))

	smembers : Bytes.Bytes -> Request.Request(List(Bytes.Bytes), Reply.Error)
	smembers = |key| Request.new(Command.new("SMEMBERS", [key]), Decode.bytes_list)

	smove : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes -> Request.Request(Bool, Reply.Error)
	smove = |source, destination, member| Request.new(Command.new("SMOVE", [source, destination, member]), Reply.integer_boolean)

	spop : Bytes.Bytes, PopMode -> Request.Request(RandomResult, Reply.Error)
	spop = |key, mode| Request.new(
		Command.new(
			"SPOP",
			[key].concat(
				match mode {
					One => []
					Many(count) => [decimal(count)]
				},
			),
		),
		|reply| match mode {
			One => Decode.optional_bytes(reply).map_ok(|value| One(value))
			Many(_) => Decode.bytes_list(reply).map_ok(|values| Many(values))
		},
	)

	## Counted forms always return arrays; One returns a nullable bulk string.
	## Distinct may return fewer elements than requested; WithRepetition may
	## duplicate elements. Redis validates the count's supported integer range.
	srand_member : Bytes.Bytes, RandomMode -> Request.Request(RandomResult, Reply.Error)
	srand_member = |key, mode| Request.new(
		Command.new(
			"SRANDMEMBER",
			[key].concat(
				match mode {
					One => []
					Distinct(count) => [decimal(count)]
					WithRepetition(count) => [Bytes.from_str("-${count.to_str()}")]
				},
			),
		),
		|reply| match mode {
			One => Decode.optional_bytes(reply).map_ok(|value| One(value))
			_ => Decode.bytes_list(reply).map_ok(|values| Many(values))
		},
	)

	srem : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	srem = |key, members| Request.new(Command.new("SREM", [key].concat(members.to_list())), Reply.integer)

	sscan : Bytes.Bytes, Bytes.Bytes, ScanOptions -> Request.Request({ cursor : Bytes.Bytes, values : List(Bytes.Bytes) }, Reply.Error)
	sscan = |key, cursor, options| {
		pattern = match options.pattern {
			Absent => []
			Present(value) => [Bytes.from_str("MATCH"), value]
		}
		count = match options.count {
			Absent => []
			Present(value) => [Bytes.from_str("COUNT"), decimal(value)]
		}
		Request.new(Command.new("SSCAN", [key, cursor].concat(pattern).concat(count)), |reply| Decode.scan(reply, Decode.bytes_list))
	}

	sunion : NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(Bytes.Bytes), Reply.Error)
	sunion = |keys| Request.new(Command.new("SUNION", keys.to_list()), Decode.bytes_list)

	sunion_card : NonEmpty.NonEmpty(Bytes.Bytes), Reply.Optional(U64) -> Request.Request(I64, Reply.Error)
	sunion_card = |keys, limit| Request.new(
		Command.new(
			"SUNIONCARD",
			[decimal(keys.len())].concat(keys.to_list()).concat(
				match limit {
					Absent => []
					Present(value) => [Bytes.from_str("LIMIT"), decimal(value)]
				},
			),
		),
		Reply.integer,
	)

	sunion_store : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	sunion_store = |destination, keys| Request.new(Command.new("SUNIONSTORE", [destination].concat(keys.to_list())), Reply.integer)
}

decimal : U64 -> Bytes.Bytes
decimal = |value| Bytes.from_str(value.to_str())

expect Sets.sis_member("set", "item").decode(Resp.Integer(1)) == Ok(True)
expect Sets.sis_member("set", "item").decode(Resp.Integer(2)).is_err()
expect Sets.smis_member("set", NonEmpty.new(Bytes.from_str("item"), [])).decode(Resp.Array([])).is_err()
expect Sets.spop("set", One).decode(Resp.NullBulkString) == Ok(One(Absent))
expect Sets.spop("set", Many(2)).decode(Resp.NullBulkString).is_err()
expect Sets.srand_member("set", WithRepetition(3)).command() == Command.new("SRANDMEMBER", ["set", "-3"])
expect Sets.sinter_card(NonEmpty.new(Bytes.from_str("a"), ["b"]), Present(5)).command() == Command.new("SINTERCARD", ["2", "a", "b", "LIMIT", "5"])
expect Sets.sscan("set", "0", Sets.ScanOptions.{}).decode(Resp.Array([Resp.bulk_utf8("42"), Resp.Array([])])) == Ok({ cursor: Bytes.from_str("42"), values: [] })
