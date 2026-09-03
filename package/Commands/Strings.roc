import /Bytes
import /Command
import /NonEmpty
import /NonEmptyBytes
import /Positive
import /Reply
import /Request
import /Resp as Resp

## Typed Redis string commands. Names and values accept binary-safe literals.
## Server version support, numeric overflow, key types, and state-dependent
## conditions are checked by Redis and remain server errors.
Strings :: [].{
	Condition : [Always, IfMissing, IfPresent, IfEqual(Bytes.Bytes), IfNotEqual(Bytes.Bytes), IfDigestEqual(Bytes.Bytes), IfDigestNotEqual(Bytes.Bytes)]
	Expiration : [ClearTtl, KeepTtl, Seconds(Positive.Positive), Milliseconds(Positive.Positive), UnixSeconds(Positive.Positive), UnixMilliseconds(Positive.Positive)]
	GetExpiration : [Unchanged, Persist, Seconds(Positive.Positive), Milliseconds(Positive.Positive), UnixSeconds(Positive.Positive), UnixMilliseconds(Positive.Positive)]
	Return : [Status, PreviousValue]
	SetResult : [Applied, NotApplied, Previous(Reply.Optional(Bytes.Bytes))]
	SetOptions := {
		condition : Condition ?? Always,
		expiration : Expiration ?? ClearTtl,
		reply : Return ?? Status,
	}
	MultiSetOptions := {
		condition : [Always, IfMissing, IfPresent] ?? Always,
		expiration : Expiration ?? ClearTtl,
	}
	Pair : { key : Bytes.Bytes, value : Bytes.Bytes }
	LcsIndices := { minimum_match_length : U64 ?? 0, with_match_length : Bool ?? False }
	LcsMode : [Subsequence, Length, Indices(LcsIndices)]
	Range : { start : U64, end : U64 }
	LcsMatch : { first : Range, second : Range, length : Reply.Optional(U64) }
	LcsResult : [Subsequence(Bytes.Bytes), Length(U64), Indices({ matches : List(LcsMatch), length : U64 })]

	## Redis 7+. Positions are inclusive byte offsets, not Unicode characters.
	## Redis performs quadratic work in the two input lengths; use small values.
	## Filtered matches do not change the total subsequence length.
	lcs : Bytes.Bytes, Bytes.Bytes, LcsMode -> Request.Request(LcsResult, Reply.Error)
	lcs = |first, second, mode| {
		arguments : List(Bytes.Bytes)
		arguments = match mode {
			Subsequence => []
			Length => ["LEN"]
			Indices(options) => {
				base : List(Bytes.Bytes)
				base = ["IDX", "MINMATCHLEN", unsigned(options.minimum_match_length)]
				if options.with_match_length {
					base.append("WITHMATCHLEN")
				} else {
					base
				}
			}
		}
		Request.new(
			Command.new("LCS", [first, second].concat(arguments)),
			|response| match mode {
				Subsequence => Reply.bulk(response).map_ok(|bytes| Subsequence(Bytes.from_list(bytes)))
				Length => nonnegative(response).map_ok(|length| Length(length))
				Indices(options) => decode_lcs_indices(response, options).map_ok(|value| Indices(value))
			},
		)
	}
	Increment(value) := {
		by : value,
		lower : Reply.Optional(value) ?? Absent,
		upper : Reply.Optional(value) ?? Absent,
		saturate : Bool ?? False,
	}
	IncrementMode : [Integer(Increment(I64)), Decimal(Increment(Bytes.Bytes))]
	IncrementExpiration : [Unchanged, Persist, Expire({ at : [Seconds(Positive.Positive), Milliseconds(Positive.Positive), UnixSeconds(Positive.Positive), UnixMilliseconds(Positive.Positive)], only_without_ttl : Bool })]
	IncrementResult : [Integers({ value : I64, applied : I64 }), Decimals({ value : Bytes.Bytes, applied : Bytes.Bytes })]

	## Redis 8.8+. Bounds use the same numeric representation as the increment.
	## Decimal text is checked by Redis. The actual delta may be zero or capped;
	## callers must not assume it equals the requested delta.
	incr_ex : Bytes.Bytes, IncrementMode, IncrementExpiration -> Request.Request(IncrementResult, Reply.Error)
	incr_ex = |key, mode, expiration| {
		arguments = match mode {
			Integer(options) => [key, Bytes.from_str("BYINT")].concat(increment_args(options, signed))
			Decimal(options) => [key, Bytes.from_str("BYFLOAT")].concat(increment_args(options, |value| value))
		}
		Request.new(
			Command.new("INCREX", arguments.concat(increment_expiration_args(expiration))),
			|response| {
				values = Reply.array(response)?
				match values {
					[value, applied] => match mode {
						Integer(_) => Ok(Integers({ value: Reply.integer(value)?, applied: Reply.integer(applied)? }))
						Decimal(_) => Ok(Decimals({ value: Bytes.from_list(Reply.bulk(value)?), applied: Bytes.from_list(Reply.bulk(applied)?) }))
					}
					_ => Err(UnexpectedReply({ actual: response, expected: ArrayReply }))
				}
			},
		)
	}

	get : Bytes.Bytes -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	get = |key| Request.new(Command.new("GET", [key]), optional_bytes)

	## Exhaustive SET surface, including conditional and GET reply modes.
	## PreviousValue returns the old value even in cases where a condition fails;
	## it must not be interpreted as confirmation that the write happened.
	set : Bytes.Bytes, Bytes.Bytes, SetOptions -> Request.Request(SetResult, Reply.Error)
	set = |key, value, options| {
		arguments = [key, value].concat(condition_args(options.condition)).concat(expiration_args(options.expiration))
		with_reply = if options.reply == PreviousValue {
			arguments.append("GET")
		} else {
			arguments
		}
		Request.new(Command.new("SET", with_reply), |response| decode_set(options, response))
	}

	append : Bytes.Bytes, Bytes.Bytes -> Request.Request(I64, Reply.Error)
	append = |key, value| integer_request("APPEND", [key, value])

	incr : Bytes.Bytes -> Request.Request(I64, Reply.Error)
	incr = |key| integer_request("INCR", [key])

	incr_by : Bytes.Bytes, I64 -> Request.Request(I64, Reply.Error)
	incr_by = |key, amount| integer_request("INCRBY", [key, signed(amount)])

	decr : Bytes.Bytes -> Request.Request(I64, Reply.Error)
	decr = |key| integer_request("DECR", [key])

	decr_by : Bytes.Bytes, I64 -> Request.Request(I64, Reply.Error)
	decr_by = |key, amount| integer_request("DECRBY", [key, signed(amount)])

	## Decimal text is retained exactly; Redis validates its numeric range and
	## syntax. This avoids narrowing Redis's long-double values to Roc F64.
	incr_by_float : Bytes.Bytes, Bytes.Bytes -> Request.Request(Bytes.Bytes, Reply.Error)
	incr_by_float = |key, amount| bytes_request("INCRBYFLOAT", [key, amount])

	get_del : Bytes.Bytes -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	get_del = |key| Request.new(Command.new("GETDEL", [key]), optional_bytes)

	get_ex : Bytes.Bytes, GetExpiration -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	get_ex = |key, expiration| Request.new(Command.new("GETEX", [key].concat(get_expiration_args(expiration))), optional_bytes)

	get_range : Bytes.Bytes, I64, I64 -> Request.Request(Bytes.Bytes, Reply.Error)
	get_range = |key, start, end| bytes_request("GETRANGE", [key, signed(start), signed(end)])

	## Deprecated Redis command, retained for catalog coverage.
	get_set : Bytes.Bytes, Bytes.Bytes -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	get_set = |key, value| Request.new(Command.new("GETSET", [key, value]), optional_bytes)

	set_range : Bytes.Bytes, U64, Bytes.Bytes -> Request.Request(I64, Reply.Error)
	set_range = |key, offset, value| integer_request("SETRANGE", [key, unsigned(offset), value])

	str_len : Bytes.Bytes -> Request.Request(I64, Reply.Error)
	str_len = |key| integer_request("STRLEN", [key])

	mget : NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(Reply.Optional(Bytes.Bytes)), Reply.Error)
	mget = |keys| Request.new(
		Command.new("MGET", keys.to_list()),
		|response| {
			values = Reply.optional_bulk_array(response)?
			if values.len() != keys.len() {
				return Err(UnexpectedReply({ actual: response, expected: OptionalBulkArrayReply }))
			}
			Ok(
				values.map(
					|value| match value {
						Absent => Absent
						Present(bytes) => Present(Bytes.from_list(bytes))
					},
				),
			)
		},
	)

	mset : NonEmpty.NonEmpty(Pair) -> Request.Request({}, Reply.Error)
	mset = |pairs| Request.new(Command.new("MSET", pair_args(pairs)), Reply.okay)

	mset_nx : NonEmpty.NonEmpty(Pair) -> Request.Request(Bool, Reply.Error)
	mset_nx = |pairs| Request.new(Command.new("MSETNX", pair_args(pairs)), Reply.integer_boolean)

	mset_ex : NonEmpty.NonEmpty(Pair), MultiSetOptions -> Request.Request(Bool, Reply.Error)
	mset_ex = |pairs, options| {
		condition = match options.condition {
			Always => []
			IfMissing => [Bytes.from_str("NX")]
			IfPresent => [Bytes.from_str("XX")]
		}
		arguments = [unsigned(pairs.len())].concat(pair_args(pairs)).concat(condition).concat(expiration_args(options.expiration))
		Request.new(Command.new("MSETEX", arguments), Reply.integer_boolean)
	}

	set_nx : Bytes.Bytes, Bytes.Bytes -> Request.Request(Bool, Reply.Error)
	set_nx = |key, value| Request.new(Command.new("SETNX", [key, value]), Reply.integer_boolean)

	set_ex : Bytes.Bytes, Positive.Positive, Bytes.Bytes -> Request.Request({}, Reply.Error)
	set_ex = |key, seconds, value| Request.new(Command.new("SETEX", [key, unsigned(seconds.to_u64()), value]), Reply.okay)

	pset_ex : Bytes.Bytes, Positive.Positive, Bytes.Bytes -> Request.Request({}, Reply.Error)
	pset_ex = |key, milliseconds, value| Request.new(Command.new("PSETEX", [key, unsigned(milliseconds.to_u64()), value]), Reply.okay)

	substr : Bytes.Bytes, I64, I64 -> Request.Request(Bytes.Bytes, Reply.Error)
	substr = |key, start, end| bytes_request("SUBSTR", [key, signed(start), signed(end)])

	digest : Bytes.Bytes -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	digest = |key| Request.new(Command.new("DIGEST", [key]), optional_bytes)

	delex : Bytes.Bytes, [Always, IfEqual(Bytes.Bytes), IfNotEqual(Bytes.Bytes), IfDigestEqual(Bytes.Bytes), IfDigestNotEqual(Bytes.Bytes)] -> Request.Request(Bool, Reply.Error)
	delex = |key, condition| {
		arguments = match condition {
			Always => []
			IfEqual(value) => [Bytes.from_str("IFEQ"), value]
			IfNotEqual(value) => [Bytes.from_str("IFNE"), value]
			IfDigestEqual(value) => [Bytes.from_str("IFDEQ"), value]
			IfDigestNotEqual(value) => [Bytes.from_str("IFDNE"), value]
		}
		Request.new(Command.new("DELEX", [key].concat(arguments)), Reply.integer_boolean)
	}
}

signed : I64 -> Bytes.Bytes
signed = |value| Bytes.from_str(value.to_str())

nonnegative : Resp.Resp -> Try(U64, Reply.Error)
nonnegative = |response| {
	number = Reply.integer(response)?
	if number < 0 {
		Err(UnexpectedReply({ actual: response, expected: IntegerReply }))
	} else {
		Ok(number.to_u64_wrap())
	}
}

decode_lcs_range : Resp.Resp -> Try(Strings.Range, Reply.Error)
decode_lcs_range = |response| match response {
	Array([first, last]) => {
		start = nonnegative(first)?
		end = nonnegative(last)?
		if start > end {
			Err(UnexpectedReply({ actual: response, expected: ArrayReply }))
		} else {
			Ok({ start, end })
		}
	}
	_ => Err(UnexpectedReply({ actual: response, expected: ArrayReply }))
}

decode_lcs_match : Resp.Resp, Strings.LcsIndices -> Try(Strings.LcsMatch, Reply.Error)
decode_lcs_match = |response, options| {
	parts = Reply.array(response)?
	match parts {
		[first_reply, second_reply, .. as rest] => {
			first = decode_lcs_range(first_reply)?
			second = decode_lcs_range(second_reply)?
			# Both ends came from nonnegative I64, so this addition cannot overflow.
			span = first.end - first.start + 1
			if span != second.end - second.start + 1 or span < options.minimum_match_length {
				return Err(UnexpectedReply({ actual: response, expected: ArrayReply }))
			}
			length = match (options.with_match_length, rest) {
				(False, []) => Absent
				(True, [length_reply]) => {
					reported_length = nonnegative(length_reply)?
					if reported_length != span {
						return Err(UnexpectedReply({ actual: response, expected: ArrayReply }))
					}
					Present(reported_length)
				}
				_ => {
					return Err(UnexpectedReply({ actual: response, expected: ArrayReply }))
				}
			}
			Ok({ first, second, length })
		}
		_ => Err(UnexpectedReply({ actual: response, expected: ArrayReply }))
	}
}

decode_lcs_indices : Resp.Resp, Strings.LcsIndices -> Try({ matches : List(Strings.LcsMatch), length : U64 }, Reply.Error)
decode_lcs_indices = |response, options| {
	# RESP2 encodes this map as alternating key/value pairs. Accept either order
	# while rejecting missing, duplicate, or unknown fields.
	parts = Reply.array(response)?
	fields = match parts {
		[BulkString(['m', 'a', 't', 'c', 'h', 'e', 's']), matches, BulkString(['l', 'e', 'n']), length] => { matches, length }
		[BulkString(['l', 'e', 'n']), length, BulkString(['m', 'a', 't', 'c', 'h', 'e', 's']), matches] => { matches, length }
		_ => {
			return Err(UnexpectedReply({ actual: response, expected: ArrayReply }))
		}
	}
	length = nonnegative(fields.length)?
	matches = Reply.array(fields.matches)?
	var $decoded = List.with_capacity(matches.len())
	var $remaining = length
	var $previous = Absent
	for item in matches {
		decoded = decode_lcs_match(item, options)?
		span = decoded.first.end - decoded.first.start + 1
		if span > $remaining {
			return Err(UnexpectedReply({ actual: response, expected: ArrayReply }))
		}
		match $previous {
			Present(previous) if decoded.first.end >= previous.first.start or decoded.second.end >= previous.second.start => {
				return Err(UnexpectedReply({ actual: response, expected: ArrayReply }))
			}
			_ => {}
		}
		$remaining = $remaining - span
		$previous = Present(decoded)
		$decoded = $decoded.append(decoded)
	}
	if options.minimum_match_length <= 1 and $remaining != 0 {
		return Err(UnexpectedReply({ actual: response, expected: ArrayReply }))
	}
	Ok({ matches: $decoded, length })
}

decode_set : Strings.SetOptions, Resp.Resp -> Try(Strings.SetResult, Reply.Error)
decode_set = |options, response| match options.reply {
	Status => match response {
		SimpleString(['O', 'K']) => Ok(Applied)
		NullBulkString if options.condition != Always => Ok(NotApplied)
		_ => Err(UnexpectedReply({ actual: response, expected: OkayReply }))
	}
	PreviousValue => optional_bytes(response).map_ok(|previous| Previous(previous))
}

increment_args : Strings.Increment(value), (value -> Bytes.Bytes) -> List(Bytes.Bytes)
increment_args = |options, encode| {
	var $arguments = [encode(options.by)]
	match options.lower {
		Absent => {}
		Present(value) => {
			$arguments = $arguments.concat(["LBOUND", encode(value)])
		}
	}
	match options.upper {
		Absent => {}
		Present(value) => {
			$arguments = $arguments.concat(["UBOUND", encode(value)])
		}
	}
	if options.saturate {
		$arguments = $arguments.append("SATURATE")
	}
	$arguments
}

increment_expiration_args : Strings.IncrementExpiration -> List(Bytes.Bytes)
increment_expiration_args = |expiration| match expiration {
	Unchanged => []
	Persist => ["PERSIST"]
	Expire(settings) => {
		arguments = match settings.at {
			Seconds(value) => [Bytes.from_str("EX"), unsigned(value.to_u64())]
			Milliseconds(value) => [Bytes.from_str("PX"), unsigned(value.to_u64())]
			UnixSeconds(value) => [Bytes.from_str("EXAT"), unsigned(value.to_u64())]
			UnixMilliseconds(value) => [Bytes.from_str("PXAT"), unsigned(value.to_u64())]
		}
		if settings.only_without_ttl {
			arguments.append("ENX")
		} else {
			arguments
		}
	}
}

unsigned : U64 -> Bytes.Bytes
unsigned = |value| Bytes.from_str(value.to_str())

integer_request : NonEmptyBytes.NonEmptyBytes, List(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
integer_request = |name, arguments| Request.new(Command.new(name, arguments), Reply.integer)

bytes_request : NonEmptyBytes.NonEmptyBytes, List(Bytes.Bytes) -> Request.Request(Bytes.Bytes, Reply.Error)
bytes_request = |name, arguments| Request.new(Command.new(name, arguments), |response| Reply.bulk(response).map_ok(Bytes.from_list))

optional_bytes : Resp.Resp -> Try(Reply.Optional(Bytes.Bytes), Reply.Error)
optional_bytes = |response| Reply.bulk_or_null(response).map_ok(
	|value| match value {
		Absent => Absent
		Present(bytes) => Present(Bytes.from_list(bytes))
	},
)

pair_args : NonEmpty.NonEmpty(Strings.Pair) -> List(Bytes.Bytes)
pair_args = |pairs| pairs.to_list().join_map(|pair| [pair.key, pair.value])

condition_args : Strings.Condition -> List(Bytes.Bytes)
condition_args = |condition| match condition {
	Always => []
	IfMissing => ["NX"]
	IfPresent => ["XX"]
	IfEqual(value) => ["IFEQ", value]
	IfNotEqual(value) => ["IFNE", value]
	IfDigestEqual(value) => ["IFDEQ", value]
	IfDigestNotEqual(value) => ["IFDNE", value]
}

expiration_args : Strings.Expiration -> List(Bytes.Bytes)
expiration_args = |expiration| match expiration {
	ClearTtl => []
	KeepTtl => ["KEEPTTL"]
	Seconds(value) => ["EX", unsigned(value.to_u64())]
	Milliseconds(value) => ["PX", unsigned(value.to_u64())]
	UnixSeconds(value) => ["EXAT", unsigned(value.to_u64())]
	UnixMilliseconds(value) => ["PXAT", unsigned(value.to_u64())]
}

get_expiration_args : Strings.GetExpiration -> List(Bytes.Bytes)
get_expiration_args = |expiration| match expiration {
	Unchanged => []
	Persist => ["PERSIST"]
	Seconds(value) => ["EX", unsigned(value.to_u64())]
	Milliseconds(value) => ["PX", unsigned(value.to_u64())]
	UnixSeconds(value) => ["EXAT", unsigned(value.to_u64())]
	UnixMilliseconds(value) => ["PXAT", unsigned(value.to_u64())]
}

expect Strings.get("key").decode(Resp.BulkString([0, 255])) == Ok(Present(Bytes.from_list([0, 255])))

expect Strings.get("key").decode(Resp.NullArray).is_err()

expect {
	options = Strings.SetOptions.{ condition: IfMissing, expiration: Milliseconds(60_000) }
	request = Strings.set("key", "value", options)
	Command.encode(request.command()) == "*6\r\n$3\r\nSET\r\n$3\r\nkey\r\n$5\r\nvalue\r\n$2\r\nNX\r\n$2\r\nPX\r\n$5\r\n60000\r\n".to_utf8()
}

expect Strings.set("key", "value", Strings.SetOptions.{}).decode(Resp.simple_utf8("OK")) == Ok(Applied)

expect Strings.set("key", "value", Strings.SetOptions.{ condition: IfMissing }).decode(Resp.NullBulkString) == Ok(NotApplied)

expect Strings.set("key", "value", Strings.SetOptions.{ reply: PreviousValue }).decode(Resp.NullBulkString) == Ok(Previous(Absent))

expect Strings.mget(NonEmpty.new(Bytes.from_str("key"), [])).decode(Resp.Array([])).is_err()

expect {
	request = Strings.lcs("first", "second", Subsequence)
	request.command() == Command.new("LCS", ["first", "second"])
		and request.decode(Resp.BulkString([0, 255])) == Ok(Subsequence(Bytes.from_list([0, 255])))
			and request.decode(Resp.NullBulkString).is_err()
}

expect {
	request = Strings.lcs("first", "second", Length)
	request.command() == Command.new("LCS", ["first", "second", "LEN"])
		and request.decode(Resp.Integer(0)) == Ok(Length(0))
			and request.decode(Resp.Integer(-1)).is_err()
}

expect {
	request = Strings.lcs("first", "second", Indices(Strings.LcsIndices.{ minimum_match_length: 4, with_match_length: True }))
	row = Resp.Array([Resp.Array([Resp.Integer(4), Resp.Integer(7)]), Resp.Array([Resp.Integer(5), Resp.Integer(8)]), Resp.Integer(4)])
	reply = Resp.Array([Resp.bulk_utf8("matches"), Resp.Array([row]), Resp.bulk_utf8("len"), Resp.Integer(6)])
	request.command() == Command.new("LCS", ["first", "second", "IDX", "MINMATCHLEN", "4", "WITHMATCHLEN"])
		and request.decode(reply) == Ok(Indices({ matches: [{ first: { start: 4, end: 7 }, second: { start: 5, end: 8 }, length: Present(4) }], length: 6 }))
}

expect {
	request = Strings.lcs("a", "b", Indices(Strings.LcsIndices.{}))
	row = Resp.Array([Resp.Array([Resp.Integer(0), Resp.Integer(1)]), Resp.Array([Resp.Integer(3), Resp.Integer(4)])])
	request.decode(Resp.Array([Resp.bulk_utf8("len"), Resp.Integer(2), Resp.bulk_utf8("matches"), Resp.Array([row])])) == Ok(Indices({ matches: [{ first: { start: 0, end: 1 }, second: { start: 3, end: 4 }, length: Absent }], length: 2 }))
		and request.decode(Resp.Array([Resp.bulk_utf8("matches"), Resp.Array([]), Resp.bulk_utf8("len"), Resp.Integer(0)])) == Ok(Indices({ matches: [], length: 0 }))
}

expect {
	request = Strings.lcs("a", "b", Indices(Strings.LcsIndices.{}))
	valid_range = Resp.Array([Resp.Integer(0), Resp.Integer(1)])
	invalid_rows = [
		Resp.NullArray,
		Resp.Array([valid_range]),
		Resp.Array([valid_range, valid_range, Resp.Integer(2)]),
		Resp.Array([Resp.Array([Resp.Integer(1), Resp.Integer(0)]), valid_range]),
		Resp.Array([Resp.Array([Resp.Integer(-1), Resp.Integer(0)]), valid_range]),
		Resp.Array([Resp.Array([Resp.Integer(0), Resp.Integer(2)]), valid_range]),
	]
	invalid_rows.all(|row| request.decode(Resp.Array([Resp.bulk_utf8("matches"), Resp.Array([row]), Resp.bulk_utf8("len"), Resp.Integer(2)])).is_err())
}

expect {
	request = Strings.lcs("a", "b", Indices(Strings.LcsIndices.{ with_match_length: True }))
	range = Resp.Array([Resp.Integer(0), Resp.Integer(1)])
	[Resp.Array([range, range]), Resp.Array([range, range, Resp.Integer(1)])].all(|row| request.decode(Resp.Array([Resp.bulk_utf8("matches"), Resp.Array([row]), Resp.bulk_utf8("len"), Resp.Integer(2)])).is_err())
}

expect {
	request = Strings.lcs("a", "b", Indices(Strings.LcsIndices.{}))
	range = Resp.Array([Resp.Integer(0), Resp.Integer(1)])
	row = Resp.Array([range, range])
	[
		Resp.Array([Resp.bulk_utf8("len"), Resp.Integer(0), Resp.bulk_utf8("len"), Resp.Integer(0)]),
		Resp.Array([Resp.bulk_utf8("matches"), Resp.Array([]), Resp.bulk_utf8("len"), Resp.Integer(1)]),
		Resp.Array([Resp.bulk_utf8("matches"), Resp.Array([row]), Resp.bulk_utf8("len"), Resp.Integer(1)]),
		Resp.Array([Resp.bulk_utf8("matches"), Resp.Array([row, row]), Resp.bulk_utf8("len"), Resp.Integer(4)]),
	].all(|reply| request.decode(reply).is_err())
}

expect Strings.set("key", "value", Strings.SetOptions.{}).decode(Resp.NullBulkString).is_err()

expect {
	request = Strings.incr_ex("counter", Integer(Strings.Increment.{ by: 5, upper: Present(100), saturate: True }), Expire({ at: Seconds(60), only_without_ttl: True }))
	request.command() == Command.new("INCREX", ["counter", "BYINT", "5", "UBOUND", "100", "SATURATE", "EX", "60", "ENX"])
		and request.decode(Resp.Array([Resp.Integer(100), Resp.Integer(1)])) == Ok(Integers({ value: 100, applied: 1 }))
}

expect {
	request = Strings.incr_ex("counter", Decimal(Strings.Increment.{ by: "0.1" }), Persist)
	request.command() == Command.new("INCREX", ["counter", "BYFLOAT", "0.1", "PERSIST"])
		and request.decode(Resp.Array([Resp.bulk_utf8("0.3"), Resp.bulk_utf8("0.1")])) == Ok(Decimals({ value: Bytes.from_str("0.3"), applied: Bytes.from_str("0.1") }))
			and request.decode(Resp.Array([Resp.Integer(1), Resp.Integer(1)])).is_err()
}

expect {
	request = Strings.incr_ex("counter", Integer(Strings.Increment.{ by: 1 }), Unchanged)
	[Resp.NullArray, Resp.Array([]), Resp.Array([Resp.Integer(1)]), Resp.Array([Resp.Integer(1), Resp.Integer(1), Resp.Integer(1)])].all(|reply| request.decode(reply).is_err())
}
