import /Bytes
import /Command
import /Commands/Decode
import /NonEmpty
import /Positive
import /Reply
import /Request
import /Resp

## Redis sparse arrays (8.8+). Indices are unsigned; Redis validates its
## implementation-specific maximum. Holes are distinct from empty byte values.
Arrays :: [].{
	Range : { start : U64, end : U64 }
	IndexedValue : { index : U64, value : Bytes.Bytes }
	Bound : [First, Last, Index(U64)]
	Predicate : [Exact(Bytes.Bytes), Contains(Bytes.Bytes), Glob(Bytes.Bytes), Regex(Bytes.Bytes)]
	GrepOptions := { combine : [All, Any] ?? All, limit : Reply.Optional(Positive.Positive) ?? Absent, no_case : Bool ?? False }
	GrepMode : [Indices, WithValues]
	GrepResult : [Indices(List(U64)), WithValues(List(IndexedValue))]
	Operation : [Sum, Min, Max, And, Or, Xor, Match(Bytes.Bytes), Used]
	OperationResult : [Decimal(Reply.Optional(Bytes.Bytes)), Integer(Reply.Optional(I64)), Count(I64)]

	arcount : Bytes.Bytes -> Request.Request(I64, Reply.Error)
	arcount = |key| Request.new(Command.new("ARCOUNT", [key]), Reply.integer)

	arlen : Bytes.Bytes -> Request.Request(I64, Reply.Error)
	arlen = |key| Request.new(Command.new("ARLEN", [key]), Reply.integer)

	arnext : Bytes.Bytes -> Request.Request(I64, Reply.Error)
	arnext = |key| Request.new(Command.new("ARNEXT", [key]), Reply.integer)

	ardel : Bytes.Bytes, NonEmpty.NonEmpty(U64) -> Request.Request(I64, Reply.Error)
	ardel = |key, indices| Request.new(Command.new("ARDEL", [key].concat(indices.to_list().map(decimal))), Reply.integer)

	ardel_range : Bytes.Bytes, NonEmpty.NonEmpty(Range) -> Request.Request(I64, Reply.Error)
	ardel_range = |key, ranges| {
		var $args = [key]
		for range in ranges.to_list() {
			$args = $args.concat([decimal(range.start), decimal(range.end)])
		}
		Request.new(Command.new("ARDELRANGE", $args), Reply.integer)
	}

	arget : Bytes.Bytes, U64 -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	arget = |key, index| Request.new(Command.new("ARGET", [key, decimal(index)]), Decode.optional_bytes)

	## Includes every hole in the inclusive range. Prefer ARSCAN for sparse
	## data; a wide ARGETRANGE can produce a large response even for a missing key.
	arget_range : Bytes.Bytes, Range -> Request.Request(List(Reply.Optional(Bytes.Bytes)), Reply.Error)
	arget_range = |key, range| Request.new(Command.new("ARGETRANGE", [key, decimal(range.start), decimal(range.end)]), |reply| Decode.list(reply, Decode.optional_bytes))

	armget : Bytes.Bytes, NonEmpty.NonEmpty(U64) -> Request.Request(List(Reply.Optional(Bytes.Bytes)), Reply.Error)
	armget = |key, indices| {
		values = indices.to_list()
		Request.new(Command.new("ARMGET", [key].concat(values.map(decimal))), |reply| Decode.counted(reply, values.len(), Decode.optional_bytes))
	}

	armset : Bytes.Bytes, NonEmpty.NonEmpty(IndexedValue) -> Request.Request(I64, Reply.Error)
	armset = |key, values| {
		var $args = [key]
		for item in values.to_list() {
			$args = $args.concat([decimal(item.index), item.value])
		}
		Request.new(Command.new("ARMSET", $args), Reply.integer)
	}

	arset : Bytes.Bytes, U64, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	arset = |key, index, values| Request.new(Command.new("ARSET", [key, decimal(index)].concat(values.to_list())), Reply.integer)

	## Returns the last written index, not the number of inserted values.
	arinsert : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	arinsert = |key, values| Request.new(Command.new("ARINSERT", [key].concat(values.to_list())), Reply.integer)

	arring : Bytes.Bytes, Positive.Positive, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	arring = |key, size, values| Request.new(Command.new("ARRING", [key, decimal(size.to_u64())].concat(values.to_list())), Reply.integer)

	arseek : Bytes.Bytes, U64 -> Request.Request(Bool, Reply.Error)
	arseek = |key, index| Request.new(Command.new("ARSEEK", [key, decimal(index)]), Reply.integer_boolean)

	arlast_items : Bytes.Bytes, U64, Bool -> Request.Request(List(Bytes.Bytes), Reply.Error)
	arlast_items = |key, count, reverse| Request.new(
		Command.new(
			"ARLASTITEMS",
			[key, decimal(count)].concat(
				if reverse {
					["REV"]
				} else {
					[]
				},
			),
		),
		Decode.bytes_list,
	)

	arscan : Bytes.Bytes, Range, Reply.Optional(Positive.Positive) -> Request.Request(List(IndexedValue), Reply.Error)
	arscan = |key, range, limit| Request.new(Command.new("ARSCAN", [key, decimal(range.start), decimal(range.end)].concat(limit_args(limit))), |reply| Decode.list(reply, indexed_pair))

	## ARINFO is version-extensible introspection; the caller owns its schema.
	arinfo : Bytes.Bytes, Bool, (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	arinfo = |key, full, decode| Request.new(
		Command.new(
			"ARINFO",
			[key].concat(
				if full {
					["FULL"]
				} else {
					[]
				},
			),
		),
		decode,
	)

	argrep : Bytes.Bytes, Bound, Bound, NonEmpty.NonEmpty(Predicate), GrepOptions, GrepMode -> Request.Request(GrepResult, Reply.Error)
	argrep = |key, start, end, predicates, options, mode| {
		var $args = [key, bound_arg(start), bound_arg(end)]
		for predicate in predicates.to_list() {
			$args = $args.concat(
				match predicate {
					Exact(value) => ["EXACT", value]
					Contains(value) => ["MATCH", value]
					Glob(value) => ["GLOB", value]
					Regex(value) => ["RE", value]
				},
			)
		}
		$args = $args.append(
			match options.combine {
				All => "AND"
				Any => "OR"
			},
		).concat(limit_args(options.limit))
		if options.no_case {
			$args = $args.append("NOCASE")
		}
		if mode == WithValues {
			$args = $args.append("WITHVALUES")
		}
		Request.new(
			Command.new("ARGREP", $args),
			|reply| match mode {
				Indices => Decode.list(reply, index_reply).map_ok(|values| Indices(values))
				WithValues => Decode.list(reply, indexed_pair).map_ok(|values| WithValues(values))
			},
		)
	}

	arop : Bytes.Bytes, Range, Operation -> Request.Request(OperationResult, Reply.Error)
	arop = |key, range, operation| {
		args = match operation {
			Sum => ["SUM"]
			Min => ["MIN"]
			Max => ["MAX"]
			And => ["AND"]
			Or => ["OR"]
			Xor => ["XOR"]
			Match(value) => ["MATCH", value]
			Used => ["USED"]
		}
		Request.new(
			Command.new("AROP", [key, decimal(range.start), decimal(range.end)].concat(args)),
			|reply| match operation {
				Sum | Min | Max => Decode.optional_bytes(reply).map_ok(|value| Decimal(value))
				And | Or | Xor => optional_integer(reply).map_ok(|value| Integer(value))
				Match(_) | Used => Reply.integer(reply).map_ok(|value| Count(value))
			},
		)
	}
}

decimal : U64 -> Bytes.Bytes
decimal = |value| Bytes.from_str(value.to_str())

bound_arg : Arrays.Bound -> Bytes.Bytes
bound_arg = |bound| match bound {
	First => "-"
	Last => "+"
	Index(index) => decimal(index)
}

limit_args : Reply.Optional(Positive.Positive) -> List(Bytes.Bytes)
limit_args = |limit| match limit {
	Absent => []
	Present(value) => ["LIMIT", decimal(value.to_u64())]
}

index_reply : Resp.Resp -> Try(U64, Reply.Error)
index_reply = |reply| {
	value = Reply.integer(reply)?
	if value < 0 {
		Err(UnexpectedReply({ actual: reply, expected: IntegerReply }))
	} else {
		Ok(value.to_u64_wrap())
	}
}

optional_integer : Resp.Resp -> Try(Reply.Optional(I64), Reply.Error)
optional_integer = |reply| match reply {
	NullBulkString => Ok(Absent)
	_ => Reply.integer(reply).map_ok(|value| Present(value))
}

indexed_pair : Resp.Resp -> Try(Arrays.IndexedValue, Reply.Error)
indexed_pair = |reply| match reply {
	Array([index, value]) => Ok({ index: index_reply(index)?, value: Decode.bytes(value)? })
	_ => Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
}

expect Arrays.arget("a", 3).decode(Resp.NullBulkString) == Ok(Absent)
expect Arrays.arget("a", 3).decode(Resp.NullArray).is_err()
expect Arrays.arseek("a", 3).decode(Resp.Integer(1)) == Ok(True)
expect Arrays.arseek("a", 3).decode(Resp.Integer(2)).is_err()
expect Arrays.armget("a", NonEmpty.new(0, [2])).decode(Resp.Array([Resp.NullBulkString])).is_err()
expect Arrays.ardel_range("a", NonEmpty.new({ start: 2, end: 8 }, [])).command() == Command.new("ARDELRANGE", ["a", "2", "8"])
expect Arrays.arop("a", { start: 0, end: 9 }, Used).decode(Resp.Integer(0)) == Ok(Count(0))
expect Arrays.arop("a", { start: 0, end: 9 }, And).decode(Resp.NullBulkString) == Ok(Integer(Absent))
expect Arrays.arop("a", { start: 0, end: 9 }, Sum).decode(Resp.bulk_utf8("1.5")) == Ok(Decimal(Present(Bytes.from_str("1.5"))))
expect Arrays.arscan("a", { start: 0, end: 9 }, Absent).decode(Resp.Array([Resp.Array([Resp.Integer(2), Resp.bulk_utf8("x")])])) == Ok([{ index: 2, value: Bytes.from_str("x") }])
expect Arrays.arscan("a", { start: 0, end: 9 }, Absent).decode(Resp.Array([Resp.Integer(2)])).is_err()

## Pinned Redis t_array.c emits nested pairs for both ARSCAN and ARGREP
## WITHVALUES. Their online return-information paragraphs incorrectly say flat.
expect Arrays.argrep("a", First, Last, NonEmpty.new(Contains(Bytes.from_str("x")), []), Arrays.GrepOptions.{}, WithValues).decode(Resp.Array([Resp.Array([Resp.Integer(2), Resp.bulk_utf8("x")])])) == Ok(WithValues([{ index: 2, value: Bytes.from_str("x") }]))
expect Arrays.argrep("a", First, Last, NonEmpty.new(Exact(Bytes.from_str("x")), []), { combine: Any, no_case: True, limit: Present(1) }, Indices).command() == Command.new("ARGREP", ["a", "-", "+", "EXACT", "x", "OR", "LIMIT", "1", "NOCASE"])
