import Bytes
import Resp

## Strict, reusable decoders for common Redis RESP2 reply shapes.
##
## Nullable decoders accept the matching null kind and reject the other kind.
## Redis error replies are separated from shape mismatches. Commands with
## richer or version-dependent replies can continue to inspect `Resp.Resp`
## directly instead of using one of these decoders.
Reply := [].{

	## Error prefixes are Redis conventions, not RESP syntax. Unknown prefixes
	## stay binary-safe; the original error bytes remain in Execute.ServerError.
	ErrorClass : [Generic, WrongType, Moved, Ask, NoAuth, WrongPass, NoPermission, Busy, Loading, ReadOnly, OutOfMemory, ClusterDown, TryAgain, ExecAbort, NoScript, Unknown(Bytes.Bytes)]

	classify_error : Bytes.Bytes -> ErrorClass
	classify_error = |error| {
		bytes = error.to_list()
		var $end = 0.U64
		for byte in bytes {
			if byte == ' ' {
				break
			}
			$end = $end + 1
		}
		prefix = bytes.take_first($end)
		match prefix {
			['E', 'R', 'R'] => Generic
			['W', 'R', 'O', 'N', 'G', 'T', 'Y', 'P', 'E'] => WrongType
			['M', 'O', 'V', 'E', 'D'] => Moved
			['A', 'S', 'K'] => Ask
			['N', 'O', 'A', 'U', 'T', 'H'] => NoAuth
			['W', 'R', 'O', 'N', 'G', 'P', 'A', 'S', 'S'] => WrongPass
			['N', 'O', 'P', 'E', 'R', 'M'] => NoPermission
			['B', 'U', 'S', 'Y'] => Busy
			['L', 'O', 'A', 'D', 'I', 'N', 'G'] => Loading
			['R', 'E', 'A', 'D', 'O', 'N', 'L', 'Y'] => ReadOnly
			['O', 'O', 'M'] => OutOfMemory
			['C', 'L', 'U', 'S', 'T', 'E', 'R', 'D', 'O', 'W', 'N'] => ClusterDown
			['T', 'R', 'Y', 'A', 'G', 'A', 'I', 'N'] => TryAgain
			['E', 'X', 'E', 'C', 'A', 'B', 'O', 'R', 'T'] => ExecAbort
			['N', 'O', 'S', 'C', 'R', 'I', 'P', 'T'] => NoScript
			_ => Unknown(Bytes.from_list(prefix))
		}
	}
	Expected : [
		ArrayOrNullReply,
		ArrayReply,
		BulkOrNullReply,
		BulkReply,
		IntegerBooleanReply,
		IntegerReply,
		OkayReply,
		OptionalBulkArrayReply,
		SimpleReply,
	]

	## UnexpectedReply retains the complete actual value for diagnostics. Map
	## errors to a compact application-owned summary before storing or queueing
	## them long-term; retaining this error can keep large reply trees alive.
	Error : [
		ServerError(List(U8)),
		UnexpectedReply({ actual : Resp.Resp, expected : Expected }),
	]

	Optional(value) : [Absent, Present(value)]

	OptionalArray : Optional(List(Resp.Resp))

	OptionalBytes : Optional(List(U8))

	## Compose after any decoder that returns bytes. Text interpretation is
	## explicit and rejects malformed UTF-8 rather than replacing bytes.
	utf8 : List(U8) -> Try(Str, [InvalidUtf8])
	utf8 = |bytes| Str.from_utf8(bytes).map_err(|_| InvalidUtf8)

	## Preserve any RESP2 value, including a Redis error reply.
	raw : Resp.Resp -> Try(Resp.Resp, Error)
	raw = |value| Ok(value)

	## Decode a required bulk-string reply.
	bulk : Resp.Resp -> Try(List(U8), Error)
	bulk = |value|
		match value {
			Resp.BulkString(bytes) => Ok(bytes)
			Resp.ErrorReply(bytes) => Err(ServerError(bytes))
			_ => unexpected(BulkReply, value)
		}

	## Decode a bulk string or RESP null, as returned by commands such as GET.
	bulk_or_null : Resp.Resp -> Try(OptionalBytes, Error)
	bulk_or_null = |value|
		match value {
			Resp.BulkString(bytes) => Ok(Present(bytes))
			Resp.NullBulkString => Ok(Absent)
			Resp.ErrorReply(bytes) => Err(ServerError(bytes))
			_ => unexpected(BulkOrNullReply, value)
		}

	## Decode an integer reply without narrowing its signed RESP2 range.
	integer : Resp.Resp -> Try(I64, Error)
	integer = |value|
		match value {
			Resp.Integer(number) => Ok(number)
			Resp.ErrorReply(bytes) => Err(ServerError(bytes))
			_ => unexpected(IntegerReply, value)
		}

	## Decode Redis's conventional integer boolean (`0` or `1`) strictly.
	integer_boolean : Resp.Resp -> Try(Bool, Error)
	integer_boolean = |value|
		match value {
			Resp.Integer(0) => Ok(False)
			Resp.Integer(1) => Ok(True)
			Resp.ErrorReply(bytes) => Err(ServerError(bytes))
			_ => unexpected(IntegerBooleanReply, value)
		}

	## Decode any simple-string reply as binary bytes.
	simple : Resp.Resp -> Try(List(U8), Error)
	simple = |value|
		match value {
			Resp.SimpleString(bytes) => Ok(bytes)
			Resp.ErrorReply(bytes) => Err(ServerError(bytes))
			_ => unexpected(SimpleReply, value)
		}

	## Require Redis's exact `+OK` status reply.
	okay : Resp.Resp -> Try({}, Error)
	okay = |value|
		match value {
			Resp.SimpleString([79, 75]) => Ok({})
			Resp.ErrorReply(bytes) => Err(ServerError(bytes))
			_ => unexpected(OkayReply, value)
		}

	## Decode an array without imposing a schema on its elements.
	array : Resp.Resp -> Try(List(Resp.Resp), Error)
	array = |value|
		match value {
			Resp.Array(values) => Ok(values)
			Resp.ErrorReply(bytes) => Err(ServerError(bytes))
			_ => unexpected(ArrayReply, value)
		}

	## Decode an array or RESP null, as returned by blocking collection commands.
	array_or_null : Resp.Resp -> Try(OptionalArray, Error)
	array_or_null = |value|
		match value {
			Resp.Array(values) => Ok(Present(values))
			Resp.NullArray => Ok(Absent)
			Resp.ErrorReply(bytes) => Err(ServerError(bytes))
			_ => unexpected(ArrayOrNullReply, value)
		}

	## Decode an array whose elements are bulk strings or nulls, such as MGET.
	optional_bulk_array : Resp.Resp -> Try(List(OptionalBytes), Error)
	optional_bulk_array = |value|
		match value {
			Resp.Array(values) => decode_optional_bulk_values(values, [])
			Resp.ErrorReply(bytes) => Err(ServerError(bytes))
			_ => unexpected(OptionalBulkArrayReply, value)
		}
}

unexpected : Reply.Expected, Resp.Resp -> Try(a, Reply.Error)
unexpected = |expected, actual| Err(UnexpectedReply({ actual, expected }))

decode_optional_bulk_values : List(Resp.Resp), List(Reply.OptionalBytes) -> Try(List(Reply.OptionalBytes), Reply.Error)
decode_optional_bulk_values = |remaining, decoded|
	match remaining {
		[] => Ok(decoded)
		[value, .. as rest] => {
			item =
				match value {
					Resp.BulkString(bytes) => Ok(Present(bytes))
					Resp.NullBulkString => Ok(Absent)
					Resp.ErrorReply(bytes) => Err(ServerError(bytes))
					_ => unexpected(OptionalBulkArrayReply, value)
				}?
			decode_optional_bulk_values(rest, decoded.append(item))
		}
	}

expect Reply.bulk(Resp.BulkString([0, 255])) == Ok([0, 255])

expect Reply.utf8([255]) == Err(InvalidUtf8)

expect Reply.utf8("café".to_utf8()) == Ok("café")

expect Reply.classify_error("WRONGTYPE arbitrary message") == WrongType

expect Reply.classify_error("MOVED 1234 localhost:6379") == Moved

expect Reply.classify_error("NOSCRIPT") == NoScript

expect Reply.classify_error(Bytes.from_list([255, ' ', 0])) == Unknown(Bytes.from_list([255]))

expect Reply.classify_error("ERRISH message") == Unknown(Bytes.from_str("ERRISH"))

expect Reply.bulk_or_null(Resp.NullBulkString) == Ok(Absent)

expect Reply.bulk_or_null(Resp.BulkString([1])) == Ok(Present([1]))

expect Reply.integer_boolean(Resp.Integer(0)) == Ok(False)

expect Reply.integer_boolean(Resp.Integer(1)) == Ok(True)

expect {
	match Reply.integer_boolean(Resp.Integer(2)) {
		Err(UnexpectedReply({ expected: IntegerBooleanReply, .. })) => True
		_ => False
	}
}

expect Reply.okay(Resp.SimpleString([79, 75])) == Ok({})

expect Reply.array_or_null(Resp.Array([Resp.Integer(1)])) == Ok(Present([Resp.Integer(1)]))

expect Reply.array_or_null(Resp.NullArray) == Ok(Absent)

expect Reply.array_or_null(Resp.NullBulkString).is_err()

expect Reply.bulk_or_null(Resp.NullArray).is_err()

expect {
	match Reply.integer(Resp.ErrorReply(Str.to_utf8("ERR nope"))) {
		Err(ServerError(bytes)) => bytes == Str.to_utf8("ERR nope")
		_ => False
	}
}

expect {
	value = Resp.Array([Resp.BulkString([1]), Resp.NullBulkString, Resp.BulkString([0, 255])])
	Reply.optional_bulk_array(value) == Ok([Present([1]), Absent, Present([0, 255])])
}

expect {
	match Reply.optional_bulk_array(Resp.Integer(1)) {
		Err(UnexpectedReply({ expected: OptionalBulkArrayReply, .. })) => True
		_ => False
	}
}

expect {
	value = Resp.Array([Resp.BulkString([1]), Resp.Integer(2)])
	match Reply.optional_bulk_array(value) {
		Err(UnexpectedReply({ actual: Resp.Integer(2), expected: OptionalBulkArrayReply })) => True
		_ => False
	}
}
