import /Bytes
import /Command
import /Commands/Decode
import /NonEmpty
import /NonEmptyBytes
import /Positive
import /Reply
import /Request
import /Resp

## Scores remain Redis decimal bytes, including infinities, without a client
## float round trip. Redis validates numeric syntax and stateful constraints.
SortedSets :: [].{
	Scored : { member : Bytes.Bytes, score : Bytes.Bytes }
	ScoreBound : [NegativeInfinity, PositiveInfinity, Inclusive(Bytes.Bytes), Exclusive(Bytes.Bytes)]
	LexBound : [NegativeInfinity, PositiveInfinity, Inclusive(Bytes.Bytes), Exclusive(Bytes.Bytes)]
	Limit : { offset : I64, count : I64 }
	Range : [Ranks({ start : I64, end : I64 }), Scores({ min : ScoreBound, max : ScoreBound, limit : Reply.Optional(Limit) }), Lex({ min : LexBound, max : LexBound, limit : Reply.Optional(Limit) })]
	Output : [Members, WithScores]
	RangeResult : [Members(List(Bytes.Bytes)), WithScores(List(Scored))]
	AddMode : [Add(NonEmpty.NonEmpty(Scored)), Increment(Scored)]
	AddOptions := { condition : [Always, IfMissing, IfPresent, IfGreater, IfLess, IfPresentGreater, IfPresentLess] ?? Always, changed : Bool ?? False }
	AddResult : [Count(I64), Score(Reply.Optional(Bytes.Bytes))]
	WeightedKeys : [Keys(NonEmpty.NonEmpty(Bytes.Bytes)), Weighted(NonEmpty.NonEmpty({ key : Bytes.Bytes, weight : Bytes.Bytes }))]
	Aggregate : [Sum, Min, Max, Count]
	RankMode : [Rank, WithScore]
	RankResult : [Rank(Reply.Optional(I64)), WithScore(Reply.Optional({ rank : I64, score : Bytes.Bytes }))]
	RandomMode : [One, Members(I64), WithScores(I64)]
	RandomResult : [One(Reply.Optional(Bytes.Bytes)), Members(List(Bytes.Bytes)), WithScores(List(Scored))]
	ScanOptions := { pattern : Reply.Optional(Bytes.Bytes) ?? Absent, count : Reply.Optional(U64) ?? Absent }
	zcard : Bytes.Bytes -> Request.Request(I64, Reply.Error)
	zcard = |key| Request.new(Command.new("ZCARD", [key]), Reply.integer)

	zscore : Bytes.Bytes, Bytes.Bytes -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	zscore = |key, member| Request.new(Command.new("ZSCORE", [key, member]), Decode.optional_bytes)

	zincr_by : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes -> Request.Request(Bytes.Bytes, Reply.Error)
	zincr_by = |key, increment, member| Request.new(Command.new("ZINCRBY", [key, increment, member]), Decode.bytes)

	zrem : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	zrem = |key, members| Request.new(Command.new("ZREM", [key].concat(members.to_list())), Reply.integer)

	zcount : Bytes.Bytes, ScoreBound, ScoreBound -> Request.Request(I64, Reply.Error)
	zcount = |key, min, max| Request.new(Command.new("ZCOUNT", [key, score_bound(min), score_bound(max)]), Reply.integer)

	zlex_count : Bytes.Bytes, LexBound, LexBound -> Request.Request(I64, Reply.Error)
	zlex_count = |key, min, max| Request.new(Command.new("ZLEXCOUNT", [key, lex_bound(min), lex_bound(max)]), Reply.integer)

	zrem_range_by_rank : Bytes.Bytes, I64, I64 -> Request.Request(I64, Reply.Error)
	zrem_range_by_rank = |key, start, end| Request.new(Command.new("ZREMRANGEBYRANK", [key, signed(start), signed(end)]), Reply.integer)

	zrem_range_by_score : Bytes.Bytes, ScoreBound, ScoreBound -> Request.Request(I64, Reply.Error)
	zrem_range_by_score = |key, min, max| Request.new(Command.new("ZREMRANGEBYSCORE", [key, score_bound(min), score_bound(max)]), Reply.integer)

	zrem_range_by_lex : Bytes.Bytes, LexBound, LexBound -> Request.Request(I64, Reply.Error)
	zrem_range_by_lex = |key, min, max| Request.new(Command.new("ZREMRANGEBYLEX", [key, lex_bound(min), lex_bound(max)]), Reply.integer)

	zdiff_store : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	zdiff_store = |destination, keys| Request.new(Command.new("ZDIFFSTORE", [destination, decimal(keys.len())].concat(keys.to_list())), Reply.integer)

	zunion : WeightedKeys, Aggregate, Output -> Request.Request(RangeResult, Reply.Error)
	zunion = |keys, aggregate, output| range_request("ZUNION", weighted_args(keys, aggregate), output)

	zunion_store : Bytes.Bytes, WeightedKeys, Aggregate -> Request.Request(I64, Reply.Error)
	zunion_store = |destination, keys, aggregate| Request.new(Command.new("ZUNIONSTORE", [destination].concat(weighted_args(keys, aggregate))), Reply.integer)

	zinter : WeightedKeys, Aggregate, Output -> Request.Request(RangeResult, Reply.Error)
	zinter = |keys, aggregate, output| range_request("ZINTER", weighted_args(keys, aggregate), output)

	zinter_store : Bytes.Bytes, WeightedKeys, Aggregate -> Request.Request(I64, Reply.Error)
	zinter_store = |destination, keys, aggregate| Request.new(Command.new("ZINTERSTORE", [destination].concat(weighted_args(keys, aggregate))), Reply.integer)

	zpop_min : Bytes.Bytes, U64 -> Request.Request(List(Scored), Reply.Error)
	zpop_min = |key, count| Request.new(Command.new("ZPOPMIN", [key, decimal(count)]), scored_pairs)

	bzpop_min : NonEmpty.NonEmpty(Bytes.Bytes), Bytes.Bytes -> Request.Request(Reply.Optional({ key : Bytes.Bytes, item : Scored }), Reply.Error)
	bzpop_min = |keys, timeout_seconds| Request.new(Command.new("BZPOPMIN", keys.to_list().append(timeout_seconds)), blocking_pop)

	zpop_max : Bytes.Bytes, U64 -> Request.Request(List(Scored), Reply.Error)
	zpop_max = |key, count| Request.new(Command.new("ZPOPMAX", [key, decimal(count)]), scored_pairs)

	bzpop_max : NonEmpty.NonEmpty(Bytes.Bytes), Bytes.Bytes -> Request.Request(Reply.Optional({ key : Bytes.Bytes, item : Scored }), Reply.Error)
	bzpop_max = |keys, timeout_seconds| Request.new(Command.new("BZPOPMAX", keys.to_list().append(timeout_seconds)), blocking_pop)

	zrank : Bytes.Bytes, Bytes.Bytes, RankMode -> Request.Request(RankResult, Reply.Error)
	zrank = |key, member, mode| rank_request("ZRANK", key, member, mode)

	zrev_rank : Bytes.Bytes, Bytes.Bytes, RankMode -> Request.Request(RankResult, Reply.Error)
	zrev_rank = |key, member, mode| rank_request("ZREVRANK", key, member, mode)

	zrange_by_score : Bytes.Bytes, ScoreBound, ScoreBound, Reply.Optional(Limit), Output -> Request.Request(RangeResult, Reply.Error)
	zrange_by_score = |key, min, max, limit, output| range_request("ZRANGEBYSCORE", [key, score_bound(min), score_bound(max)].concat(limit_args(limit)), output)

	zrev_range_by_score : Bytes.Bytes, ScoreBound, ScoreBound, Reply.Optional(Limit), Output -> Request.Request(RangeResult, Reply.Error)

	## Accept logical min/max like zrange_by_score; reverse their wire order.
	zrev_range_by_score = |key, min, max, limit, output| range_request("ZREVRANGEBYSCORE", [key, score_bound(max), score_bound(min)].concat(limit_args(limit)), output)

	zrange_by_lex : Bytes.Bytes, LexBound, LexBound, Reply.Optional(Limit) -> Request.Request(List(Bytes.Bytes), Reply.Error)
	zrange_by_lex = |key, min, max, limit| Request.new(Command.new("ZRANGEBYLEX", [key, lex_bound(min), lex_bound(max)].concat(limit_args(limit))), Decode.bytes_list)

	zrev_range_by_lex : Bytes.Bytes, LexBound, LexBound, Reply.Optional(Limit) -> Request.Request(List(Bytes.Bytes), Reply.Error)
	zrev_range_by_lex = |key, min, max, limit| Request.new(Command.new("ZREVRANGEBYLEX", [key, lex_bound(max), lex_bound(min)].concat(limit_args(limit))), Decode.bytes_list)

	zadd : Bytes.Bytes, AddMode, AddOptions -> Request.Request(AddResult, Reply.Error)
	zadd = |key, mode, options| {
		condition : List(Bytes.Bytes)
		condition = match options.condition {
			Always => []
			IfMissing => ["NX"]
			IfPresent => ["XX"]
			IfGreater => ["GT"]
			IfLess => ["LT"]
			IfPresentGreater => ["XX", "GT"]
			IfPresentLess => ["XX", "LT"]
		}
		changed = if options.changed {
			[Bytes.from_str("CH")]
		} else {
			[]
		}
		values = match mode {
			Add(items) => items.to_list().join_map(|item| [item.score, item.member])
			Increment(item) => [Bytes.from_str("INCR"), item.score, item.member]
		}
		Request.new(
			Command.new("ZADD", [key].concat(condition).concat(changed).concat(values)),
			|reply| match mode {
				Add(_) => Reply.integer(reply).map_ok(|count| Count(count))
				Increment(_) => Decode.optional_bytes(reply).map_ok(|score| Score(score))
			},
		)
	}

	zrange : Bytes.Bytes, Range, Bool, Output -> Request.Request(RangeResult, Reply.Error)
	zrange = |key, range, reverse, output| range_request("ZRANGE", [key].concat(range_args(range, reverse)), output)

	zrange_store : Bytes.Bytes, Bytes.Bytes, Range, Bool -> Request.Request(I64, Reply.Error)
	zrange_store = |destination, source, range, reverse| Request.new(Command.new("ZRANGESTORE", [destination, source].concat(range_args(range, reverse))), Reply.integer)

	zrev_range : Bytes.Bytes, I64, I64, Output -> Request.Request(RangeResult, Reply.Error)
	zrev_range = |key, start, end, output| range_request("ZREVRANGE", [key, signed(start), signed(end)], output)

	zdiff : NonEmpty.NonEmpty(Bytes.Bytes), Output -> Request.Request(RangeResult, Reply.Error)
	zdiff = |keys, output| range_request("ZDIFF", [decimal(keys.len())].concat(keys.to_list()), output)

	zinter_card : NonEmpty.NonEmpty(Bytes.Bytes), Reply.Optional(U64) -> Request.Request(I64, Reply.Error)
	zinter_card = |keys, limit| Request.new(
		Command.new(
			"ZINTERCARD",
			[decimal(keys.len())].concat(keys.to_list()).concat(
				match limit {
					Absent => []
					Present(value) => [Bytes.from_str("LIMIT"), decimal(value)]
				},
			),
		),
		Reply.integer,
	)

	zmscore : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(Reply.Optional(Bytes.Bytes)), Reply.Error)
	zmscore = |key, members| Request.new(Command.new("ZMSCORE", [key].concat(members.to_list())), |reply| Decode.counted(reply, members.len(), Decode.optional_bytes))

	zrand_member : Bytes.Bytes, RandomMode -> Request.Request(RandomResult, Reply.Error)
	zrand_member = |key, mode| Request.new(
		Command.new(
			"ZRANDMEMBER",
			[key].concat(
				match mode {
					One => []
					Members(count) => [signed(count)]
					WithScores(count) => [signed(count), Bytes.from_str("WITHSCORES")]
				},
			),
		),
		|reply| match mode {
			One => Decode.optional_bytes(reply).map_ok(|value| One(value))
			Members(_) => Decode.bytes_list(reply).map_ok(|values| Members(values))
			WithScores(_) => scored_pairs(reply).map_ok(|values| WithScores(values))
		},
	)

	zscan : Bytes.Bytes, Bytes.Bytes, ScanOptions -> Request.Request({ cursor : Bytes.Bytes, values : List(Scored) }, Reply.Error)
	zscan = |key, cursor, options| {
		pattern = match options.pattern {
			Absent => []
			Present(value) => [Bytes.from_str("MATCH"), value]
		}
		count = match options.count {
			Absent => []
			Present(value) => [Bytes.from_str("COUNT"), decimal(value)]
		}
		Request.new(Command.new("ZSCAN", [key, cursor].concat(pattern).concat(count)), |reply| Decode.scan(reply, scored_pairs))
	}

	zmpop : NonEmpty.NonEmpty(Bytes.Bytes), [Min, Max], Positive.Positive -> Request.Request(Reply.Optional({ key : Bytes.Bytes, items : List(Scored) }), Reply.Error)
	zmpop = |keys, side, count| Request.new(Command.new("ZMPOP", pop_args(keys, side, count)), multi_pop)

	bzmpop : Bytes.Bytes, NonEmpty.NonEmpty(Bytes.Bytes), [Min, Max], Positive.Positive -> Request.Request(Reply.Optional({ key : Bytes.Bytes, items : List(Scored) }), Reply.Error)
	bzmpop = |timeout_seconds, keys, side, count| Request.new(Command.new("BZMPOP", [timeout_seconds].concat(pop_args(keys, side, count))), multi_pop)
}

decimal : U64 -> Bytes.Bytes
decimal = |value| Bytes.from_str(value.to_str())

signed : I64 -> Bytes.Bytes
signed = |value| Bytes.from_str(value.to_str())

score_bound : SortedSets.ScoreBound -> Bytes.Bytes
score_bound = |bound| match bound {
	NegativeInfinity => "-inf"
	PositiveInfinity => "+inf"
	Inclusive(value) => value
	Exclusive(value) => Bytes.from_list(['('].concat(value.to_list()))
}

lex_bound : SortedSets.LexBound -> Bytes.Bytes
lex_bound = |bound| match bound {
	NegativeInfinity => "-"
	PositiveInfinity => "+"
	Inclusive(value) => Bytes.from_list(['['].concat(value.to_list()))
	Exclusive(value) => Bytes.from_list(['('].concat(value.to_list()))
}

limit_args : Reply.Optional(SortedSets.Limit) -> List(Bytes.Bytes)
limit_args = |limit| match limit {
	Absent => []
	Present(value) => ["LIMIT", signed(value.offset), signed(value.count)]
}

range_args : SortedSets.Range, Bool -> List(Bytes.Bytes)
range_args = |range, reverse| {
	rev = if reverse {
		[Bytes.from_str("REV")]
	} else {
		[]
	}
	match range {
		Ranks(bounds) => [signed(bounds.start), signed(bounds.end)].concat(rev)
		Scores(bounds) => {
			limits = if reverse {
				[score_bound(bounds.max), score_bound(bounds.min)]
			} else {
				[score_bound(bounds.min), score_bound(bounds.max)]
			}
			limits.append("BYSCORE").concat(rev).concat(limit_args(bounds.limit))
		}
		Lex(bounds) => {
			limits = if reverse {
				[lex_bound(bounds.max), lex_bound(bounds.min)]
			} else {
				[lex_bound(bounds.min), lex_bound(bounds.max)]
			}
			limits.append("BYLEX").concat(rev).concat(limit_args(bounds.limit))
		}
	}
}

range_request : NonEmptyBytes.NonEmptyBytes, List(Bytes.Bytes), SortedSets.Output -> Request.Request(SortedSets.RangeResult, Reply.Error)
range_request = |name, arguments, output| Request.new(
	Command.new(
		name,
		match output {
			Members => arguments
			WithScores => arguments.append("WITHSCORES")
		},
	),
	|reply| match output {
		Members => Decode.bytes_list(reply).map_ok(|values| Members(values))
		WithScores => scored_pairs(reply).map_ok(|values| WithScores(values))
	},
)

scored_pairs : Resp.Resp -> Try(List(SortedSets.Scored), Reply.Error)
scored_pairs = |reply| {
	items = Reply.array(reply)?
	if items.len() % 2 != 0 {
		return Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
	}
	var $values = List.with_capacity(items.len() / 2)
	var $remaining = items
	while !$remaining.is_empty() {
		match $remaining {
			[member, score, .. as rest] => {
				$values = $values.append({ member: Decode.bytes(member)?, score: Decode.bytes(score)? })
				$remaining = rest
			}
			_ => {
				return Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
			}
		}
	}
	Ok($values)
}

weighted_args : SortedSets.WeightedKeys, SortedSets.Aggregate -> List(Bytes.Bytes)
weighted_args = |input, aggregate| {
	arguments = match input {
		Keys(keys) => [decimal(keys.len())].concat(keys.to_list())
		Weighted(items) => {
			values = items.to_list()
			[decimal(items.len())].concat(values.map(|item| item.key)).append("WEIGHTS").concat(values.map(|item| item.weight))
		}
	}
	arguments.concat([
		"AGGREGATE",
		match aggregate {
			Sum => Bytes.from_str("SUM")
			Min => Bytes.from_str("MIN")
			Max => Bytes.from_str("MAX")
			Count => Bytes.from_str("COUNT")
		},
	])
}

rank_request : NonEmptyBytes.NonEmptyBytes, Bytes.Bytes, Bytes.Bytes, SortedSets.RankMode -> Request.Request(SortedSets.RankResult, Reply.Error)
rank_request = |name, key, member, mode| Request.new(
	Command.new(
		name,
		match mode {
			Rank => [key, member]
			WithScore => [key, member, "WITHSCORE"]
		},
	),
	|reply| match (mode, reply) {
		(Rank, NullBulkString) => Ok(Rank(Absent))
		(Rank, Integer(value)) if value >= 0 => Ok(Rank(Present(value)))
		(WithScore, NullArray) => Ok(WithScore(Absent))
		(WithScore, Array([Integer(rank), score])) if rank >= 0 => Ok(WithScore(Present({ rank, score: Decode.bytes(score)? })))
		_ => Err(UnexpectedReply({ actual: reply, expected: ArrayOrNullReply }))
	},
)

blocking_pop : Resp.Resp -> Try(Reply.Optional({ key : Bytes.Bytes, item : SortedSets.Scored }), Reply.Error)
blocking_pop = |reply| match reply {
	NullArray => Ok(Absent)
	Array([key, member, score]) => Ok(Present({ key: Decode.bytes(key)?, item: { member: Decode.bytes(member)?, score: Decode.bytes(score)? } }))
	_ => Err(UnexpectedReply({ actual: reply, expected: ArrayOrNullReply }))
}

pop_args : NonEmpty.NonEmpty(Bytes.Bytes), [Min, Max], Positive.Positive -> List(Bytes.Bytes)
pop_args = |keys, side, count| [decimal(keys.len())].concat(keys.to_list()).concat([
	match side {
		Min => Bytes.from_str("MIN")
		Max => Bytes.from_str("MAX")
	},
	"COUNT",
	decimal(count.to_u64()),
])

multi_pop : Resp.Resp -> Try(Reply.Optional({ key : Bytes.Bytes, items : List(SortedSets.Scored) }), Reply.Error)
multi_pop = |reply| match reply {
	NullArray => Ok(Absent)
	Array([key, items]) => {
		values = Decode.list(
			items,
			|item| match item {
				Array([member, score]) => Ok({ member: Decode.bytes(member)?, score: Decode.bytes(score)? })
				_ => Err(UnexpectedReply({ actual: item, expected: ArrayReply }))
			},
		)?
		if values.is_empty() {
			return Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
		}
		Ok(Present({ key: Decode.bytes(key)?, items: values }))
	}
	_ => Err(UnexpectedReply({ actual: reply, expected: ArrayOrNullReply }))
}

expect SortedSets.zrank("key", "member", Rank).decode(Resp.NullBulkString) == Ok(Rank(Absent))
expect SortedSets.zrev_range_by_score("key", Inclusive(Bytes.from_str("1")), PositiveInfinity, Absent, Members).command() == Command.new("ZREVRANGEBYSCORE", ["key", "+inf", "1"])
expect SortedSets.zrev_range_by_lex("key", Inclusive(Bytes.from_str("a")), Exclusive(Bytes.from_str("z")), Absent).command() == Command.new("ZREVRANGEBYLEX", ["key", "(z", "[a"])
expect SortedSets.zrank("key", "member", WithScore).decode(Resp.NullArray) == Ok(WithScore(Absent))
expect SortedSets.zrank("key", "member", WithScore).decode(Resp.NullBulkString).is_err()
expect SortedSets.zrange("key", Scores({ min: Inclusive(Bytes.from_str("1")), max: PositiveInfinity, limit: Absent }), True, Members).command() == Command.new("ZRANGE", ["key", "+inf", "1", "BYSCORE", "REV"])
expect SortedSets.zpop_min("key", 2).decode(Resp.Array([Resp.bulk_utf8("member"), Resp.bulk_utf8("1.5")])) == Ok([{ member: Bytes.from_str("member"), score: Bytes.from_str("1.5") }])
expect SortedSets.zpop_min("key", 2).decode(Resp.Array([Resp.bulk_utf8("member")])).is_err()
expect SortedSets.zadd("key", Increment({ member: "m", score: "1" }), SortedSets.AddOptions.{ condition: IfPresent }).decode(Resp.NullBulkString) == Ok(Score(Absent))
expect SortedSets.zunion(Weighted(NonEmpty.new({ key: Bytes.from_str("key"), weight: Bytes.from_str("2") }, [])), Sum, WithScores).command() == Command.new("ZUNION", ["1", "key", "WEIGHTS", "2", "AGGREGATE", "SUM", "WITHSCORES"])
