import /Bytes
import /Command
import /Commands/Decode
import /NonEmpty
import /NonEmptyBytes
import /Positive
import /Reply
import /Request
import /Resp

## Blocking operations still produce exactly one reply. Configure platform
## deadlines accordingly; a transport timeout is not a Redis timeout reply.
## Timeout seconds are decimal bytes so Redis's fractional precision is retained.
Lists :: [].{
	Side : [Left, Right]
	PopMode : [One, Many(U64)]
	PopResult : [One(Reply.Optional(Bytes.Bytes)), Many(Reply.Optional(List(Bytes.Bytes)))]
	MoveMany : [One, UpTo({ count : Positive.Positive, order : [OneByOne, Bulk] }), Exactly({ count : Positive.Positive, order : [OneByOne, Bulk] })]
	PositionOptions := { rank : I64 ?? 1, max_len : U64 ?? 0 }
	PositionMode : [One, Many(U64)]
	PositionResult : [One(Reply.Optional(I64)), Many(List(I64))]
	lindex : Bytes.Bytes, I64 -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	lindex = |key, index| Request.new(Command.new("LINDEX", [key, signed(index)]), Decode.optional_bytes)

	llen : Bytes.Bytes -> Request.Request(I64, Reply.Error)
	llen = |key| Request.new(Command.new("LLEN", [key]), Reply.integer)

	linsert : Bytes.Bytes, [Before, After], Bytes.Bytes, Bytes.Bytes -> Request.Request(I64, Reply.Error)
	linsert = |key, position, pivot, value| Request.new(
		Command.new(
			"LINSERT",
			[
				key,
				match position {
					Before => Bytes.from_str("BEFORE")
					After => Bytes.from_str("AFTER")
				},
				pivot,
				value,
			],
		),
		Reply.integer,
	)

	lpush : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	lpush = |key, values| Request.new(Command.new("LPUSH", [key].concat(values.to_list())), Reply.integer)

	lpush_x : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	lpush_x = |key, values| Request.new(Command.new("LPUSHX", [key].concat(values.to_list())), Reply.integer)

	rpush : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	rpush = |key, values| Request.new(Command.new("RPUSH", [key].concat(values.to_list())), Reply.integer)

	rpush_x : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	rpush_x = |key, values| Request.new(Command.new("RPUSHX", [key].concat(values.to_list())), Reply.integer)

	lrange : Bytes.Bytes, I64, I64 -> Request.Request(List(Bytes.Bytes), Reply.Error)
	lrange = |key, start, end| Request.new(Command.new("LRANGE", [key, signed(start), signed(end)]), Decode.bytes_list)

	lrem : Bytes.Bytes, I64, Bytes.Bytes -> Request.Request(I64, Reply.Error)
	lrem = |key, count, value| Request.new(Command.new("LREM", [key, signed(count), value]), Reply.integer)

	lset : Bytes.Bytes, I64, Bytes.Bytes -> Request.Request({}, Reply.Error)
	lset = |key, index, value| Request.new(Command.new("LSET", [key, signed(index), value]), Reply.okay)

	ltrim : Bytes.Bytes, I64, I64 -> Request.Request({}, Reply.Error)
	ltrim = |key, start, end| Request.new(Command.new("LTRIM", [key, signed(start), signed(end)]), Reply.okay)

	lmove : Bytes.Bytes, Bytes.Bytes, Side, Side -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	lmove = |source, destination, from, to| Request.new(Command.new("LMOVE", [source, destination, side(from), side(to)]), Decode.optional_bytes)

	blmove : Bytes.Bytes, Bytes.Bytes, Side, Side, Bytes.Bytes -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	blmove = |source, destination, from, to, timeout_seconds| Request.new(Command.new("BLMOVE", [source, destination, side(from), side(to), timeout_seconds]), Decode.optional_bytes)

	rpop_lpush : Bytes.Bytes, Bytes.Bytes -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	rpop_lpush = |source, destination| Request.new(Command.new("RPOPLPUSH", [source, destination]), Decode.optional_bytes)

	brpop_lpush : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	brpop_lpush = |source, destination, timeout_seconds| Request.new(Command.new("BRPOPLPUSH", [source, destination, timeout_seconds]), Decode.optional_bytes)

	lpop : Bytes.Bytes, PopMode -> Request.Request(PopResult, Reply.Error)
	lpop = |key, mode| pop_request("LPOP", key, mode)

	rpop : Bytes.Bytes, PopMode -> Request.Request(PopResult, Reply.Error)
	rpop = |key, mode| pop_request("RPOP", key, mode)

	blpop : NonEmpty.NonEmpty(Bytes.Bytes), Bytes.Bytes -> Request.Request(Reply.Optional({ key : Bytes.Bytes, value : Bytes.Bytes }), Reply.Error)
	blpop = |keys, timeout_seconds| Request.new(Command.new("BLPOP", keys.to_list().append(timeout_seconds)), blocking_pop)

	brpop : NonEmpty.NonEmpty(Bytes.Bytes), Bytes.Bytes -> Request.Request(Reply.Optional({ key : Bytes.Bytes, value : Bytes.Bytes }), Reply.Error)
	brpop = |keys, timeout_seconds| Request.new(Command.new("BRPOP", keys.to_list().append(timeout_seconds)), blocking_pop)

	lmpop : NonEmpty.NonEmpty(Bytes.Bytes), Side, Positive.Positive -> Request.Request(Reply.Optional({ key : Bytes.Bytes, values : List(Bytes.Bytes) }), Reply.Error)
	lmpop = |keys, direction, count| Request.new(Command.new("LMPOP", multi_pop_args(keys, direction, count)), multi_pop)

	blmpop : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes), Side, Positive.Positive -> Request.Request(Reply.Optional({ key : Bytes.Bytes, values : List(Bytes.Bytes) }), Reply.Error)
	blmpop = |timeout_seconds, keys, direction, count| Request.new(Command.new("BLMPOP", [timeout_seconds].concat(multi_pop_args(keys, direction, count))), multi_pop)

	lmove_m : Bytes.Bytes, Bytes.Bytes, Side, Side, MoveMany -> Request.Request(Reply.Optional(List(Bytes.Bytes)), Reply.Error)
	lmove_m = |source, destination, from, to, count| Request.new(Command.new("LMOVEM", [source, destination, side(from), side(to)].concat(move_many_args(count))), optional_list)

	blmove_m : Bytes.Bytes, Bytes.Bytes, Side, Side, Bytes.Bytes, MoveMany -> Request.Request(Reply.Optional(List(Bytes.Bytes)), Reply.Error)
	blmove_m = |source, destination, from, to, timeout_seconds, count| Request.new(Command.new("BLMOVEM", [source, destination, side(from), side(to), timeout_seconds].concat(move_many_args(count))), optional_list)

	lpos : Bytes.Bytes, Bytes.Bytes, PositionMode, PositionOptions -> Request.Request(PositionResult, Reply.Error)
	lpos = |key, element, mode, options| {
		count = match mode {
			One => []
			Many(value) => [Bytes.from_str("COUNT"), decimal(value)]
		}
		Request.new(
			Command.new("LPOS", [key, element, "RANK", signed(options.rank)].concat(count).concat(["MAXLEN", decimal(options.max_len)])),
			|reply| match mode {
				One => match reply {
					NullBulkString => Ok(One(Absent))
					_ => Reply.integer(reply).map_ok(|value| One(Present(value)))
				}
				Many(_) => Decode.list(reply, Reply.integer).map_ok(|values| Many(values))
			},
		)
	}
}

decimal : U64 -> Bytes.Bytes
decimal = |value| Bytes.from_str(value.to_str())

signed : I64 -> Bytes.Bytes
signed = |value| Bytes.from_str(value.to_str())

side : Lists.Side -> Bytes.Bytes
side = |direction| match direction {
	Left => "LEFT"
	Right => "RIGHT"
}

optional_list : Resp.Resp -> Try(Reply.Optional(List(Bytes.Bytes)), Reply.Error)
optional_list = |reply| match reply {
	NullArray => Ok(Absent)
	_ => Decode.bytes_list(reply).map_ok(|values| Present(values))
}

pop_request : NonEmptyBytes.NonEmptyBytes, Bytes.Bytes, Lists.PopMode -> Request.Request(Lists.PopResult, Reply.Error)
pop_request = |name, key, mode| Request.new(
	Command.new(
		name,
		[key].concat(
			match mode {
				One => []
				Many(count) => [decimal(count)]
			},
		),
	),
	|reply| match mode {
		One => Decode.optional_bytes(reply).map_ok(|value| One(value))
		Many(_) => optional_list(reply).map_ok(|values| Many(values))
	},
)

blocking_pop : Resp.Resp -> Try(Reply.Optional({ key : Bytes.Bytes, value : Bytes.Bytes }), Reply.Error)
blocking_pop = |reply| match reply {
	NullArray => Ok(Absent)
	Array([key, value]) => Ok(Present({ key: Decode.bytes(key)?, value: Decode.bytes(value)? }))
	_ => Err(UnexpectedReply({ actual: reply, expected: ArrayOrNullReply }))
}

multi_pop : Resp.Resp -> Try(Reply.Optional({ key : Bytes.Bytes, values : List(Bytes.Bytes) }), Reply.Error)
multi_pop = |reply| match reply {
	NullArray => Ok(Absent)
	Array([key, values]) => {
		decoded = Decode.bytes_list(values)?
		if decoded.is_empty() {
			return Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
		}
		Ok(Present({ key: Decode.bytes(key)?, values: decoded }))
	}
	_ => Err(UnexpectedReply({ actual: reply, expected: ArrayOrNullReply }))
}

multi_pop_args : NonEmpty.NonEmpty(Bytes.Bytes), Lists.Side, Positive.Positive -> List(Bytes.Bytes)
multi_pop_args = |keys, direction, count| [decimal(keys.len())].concat(keys.to_list()).concat([side(direction), "COUNT", decimal(count.to_u64())])

move_many_args : Lists.MoveMany -> List(Bytes.Bytes)
move_many_args = |count| match count {
	One => []
	UpTo(options) => [
		"COUNT",
		decimal(options.count.to_u64()),
		match options.order {
			OneByOne => Bytes.from_str("OBO")
			Bulk => Bytes.from_str("BULK")
		},
	]
	Exactly(options) => [
		"EXACTLY",
		decimal(options.count.to_u64()),
		match options.order {
			OneByOne => Bytes.from_str("OBO")
			Bulk => Bytes.from_str("BULK")
		},
	]
}

expect Lists.lpop("key", One).decode(Resp.NullBulkString) == Ok(One(Absent))
expect Lists.lpop("key", Many(2)).decode(Resp.NullArray) == Ok(Many(Absent))
expect Lists.lpop("key", Many(2)).decode(Resp.NullBulkString).is_err()
expect Lists.lpop("key", One).decode(Resp.NullArray).is_err()
expect Lists.lmove_m("a", "b", Left, Right, Exactly({ count: 2, order: Bulk })).command() == Command.new("LMOVEM", ["a", "b", "LEFT", "RIGHT", "EXACTLY", "2", "BULK"])
expect Lists.blpop(NonEmpty.new(Bytes.from_str("a"), ["b"]), "0.5").command() == Command.new("BLPOP", ["a", "b", "0.5"])
expect Lists.blpop(NonEmpty.new(Bytes.from_str("a"), []), "1").decode(Resp.NullArray) == Ok(Absent)
expect Lists.lmpop(NonEmpty.new(Bytes.from_str("a"), []), Left, 1).decode(Resp.Array([Resp.bulk_utf8("a"), Resp.Array([])])).is_err()
expect Lists.lpos("a", "b", One, Lists.PositionOptions.{}).decode(Resp.NullBulkString) == Ok(One(Absent))
expect Lists.lpos("a", "b", Many(0), Lists.PositionOptions.{}).decode(Resp.Array([])) == Ok(Many([]))
