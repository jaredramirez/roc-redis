import /Bytes
import /Command
import /Commands/Decode
import /NonEmpty
import /Positive
import /Reply
import /Request
import /Resp

## RESP2 vector-set commands. Decimal components/scores remain exact bytes;
## FP32 input is little-endian IEEE-754 data, validated by Redis. JSON attribute
## interpretation belongs to the application, not this protocol library.
VectorSets :: [].{
	Vector : [Fp32(Bytes.Bytes), Values(NonEmpty.NonEmpty(Bytes.Bytes))]
	Query : [Element(Bytes.Bytes), Vector(Vector)]
	AddOptions := { reduce : Reply.Optional(Positive.Positive) ?? Absent, cas : Bool ?? False, quantization : [Default, None, Binary, Q8] ?? Default, exploration : Reply.Optional(Positive.Positive) ?? Absent, attributes : Reply.Optional(Bytes.Bytes) ?? Absent, links : Reply.Optional(Positive.Positive) ?? Absent }
	SearchOptions := { scores : Bool ?? False, attributes : Bool ?? False, count : Reply.Optional(U64) ?? Absent, epsilon : Reply.Optional(Bytes.Bytes) ?? Absent, exploration : Reply.Optional(Positive.Positive) ?? Absent, filter : Reply.Optional(Bytes.Bytes) ?? Absent, filter_effort : Reply.Optional(U64) ?? Absent, exact : Bool ?? False, no_thread : Bool ?? False }
	Match : { element : Bytes.Bytes, score : Reply.Optional(Bytes.Bytes), attributes : Reply.Optional(Bytes.Bytes) }
	EmbeddingMode : [Values, Raw]
	Embedding : [Values(Reply.Optional(List(Bytes.Bytes))), Raw(Reply.Optional({ quantization : Bytes.Bytes, data : Bytes.Bytes, norm : Bytes.Bytes, range : Reply.Optional(Bytes.Bytes) }))]
	RandomMode : [One, Many(I64)]
	RandomResult : [One(Reply.Optional(Bytes.Bytes)), Many(List(Bytes.Bytes))]
	Bound : [Minimum, Maximum, Inclusive(Bytes.Bytes), Exclusive(Bytes.Bytes)]

	vadd : Bytes.Bytes, Vector, Bytes.Bytes, AddOptions -> Request.Request(Bool, Reply.Error)
	vadd = |key, vector, element, options| {
		var $args = [key].concat(positive_option("REDUCE", options.reduce)).concat(vector_args(vector)).append(element)
		if options.cas {
			$args = $args.append("CAS")
		}
		$args = $args.concat(
			match options.quantization {
				Default => []
				None => ["NOQUANT"]
				Binary => ["BIN"]
				Q8 => ["Q8"]
			},
		)
		$args = $args.concat(positive_option("EF", options.exploration)).concat(bytes_option("SETATTR", options.attributes)).concat(positive_option("M", options.links))
		Request.new(Command.new("VADD", $args), Reply.integer_boolean)
	}

	vcard : Bytes.Bytes -> Request.Request(I64, Reply.Error)
	vcard = |key| Request.new(Command.new("VCARD", [key]), Reply.integer)

	vdim : Bytes.Bytes -> Request.Request(I64, Reply.Error)
	vdim = |key| Request.new(Command.new("VDIM", [key]), Reply.integer)

	vis_member : Bytes.Bytes, Bytes.Bytes -> Request.Request(Bool, Reply.Error)
	vis_member = |key, element| Request.new(Command.new("VISMEMBER", [key, element]), Reply.integer_boolean)

	vrem : Bytes.Bytes, Bytes.Bytes -> Request.Request(Bool, Reply.Error)
	vrem = |key, element| Request.new(Command.new("VREM", [key, element]), Reply.integer_boolean)

	vset_attr : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes -> Request.Request(Bool, Reply.Error)
	vset_attr = |key, element, json| Request.new(Command.new("VSETATTR", [key, element, json]), Reply.integer_boolean)

	vget_attr : Bytes.Bytes, Bytes.Bytes -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	vget_attr = |key, element| Request.new(Command.new("VGETATTR", [key, element]), Decode.optional_bytes)

	## Introspection fields may expand with the Redis module version.
	vinfo : Bytes.Bytes, (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	vinfo = |key, decode| Request.new(Command.new("VINFO", [key]), decode)

	vemb : Bytes.Bytes, Bytes.Bytes, EmbeddingMode -> Request.Request(Embedding, Reply.Error)
	vemb = |key, element, mode| Request.new(
		Command.new(
			"VEMB",
			[key, element].concat(
				if mode == Raw {
					["RAW"]
				} else {
					[]
				},
			),
		),
		|reply| match mode {
			Values => match reply {
				NullBulkString => Ok(Values(Absent))
				_ => Decode.bytes_list(reply).map_ok(|values| Values(Present(values)))
			}
			Raw => match reply {
				NullBulkString => Ok(Raw(Absent))
				_ => raw_embedding(reply).map_ok(|value| Raw(Present(value)))
			}
		},
	)

	## Outer list is HNSW levels, highest first. Missing keys/elements use a
	## null bulk reply, not a null array, even though a present result is nested.
	vlinks : Bytes.Bytes, Bytes.Bytes, Bool -> Request.Request(Reply.Optional(List(List(Match))), Reply.Error)
	vlinks = |key, element, scores| Request.new(
		Command.new(
			"VLINKS",
			[key, element].concat(
				if scores {
					["WITHSCORES"]
				} else {
					[]
				},
			),
		),
		|reply| match reply {
			NullBulkString => Ok(Absent)
			_ => Decode.list(reply, |level| matches(level, scores, False)).map_ok(|levels| Present(levels))
		},
	)

	vrand_member : Bytes.Bytes, RandomMode -> Request.Request(RandomResult, Reply.Error)
	vrand_member = |key, mode| Request.new(
		Command.new(
			"VRANDMEMBER",
			[key].concat(
				match mode {
					One => []
					Many(count) => [Bytes.from_str(count.to_str())]
				},
			),
		),
		|reply| match mode {
			One => Decode.optional_bytes(reply).map_ok(|value| One(value))
			Many(_) => Decode.bytes_list(reply).map_ok(|values| Many(values))
		},
	)

	vrange : Bytes.Bytes, Bound, Bound, Reply.Optional(I64) -> Request.Request(List(Bytes.Bytes), Reply.Error)
	vrange = |key, start, end, count| Request.new(
		Command.new(
			"VRANGE",
			[key, bound_arg(start), bound_arg(end)].concat(
				match count {
					Absent => []
					Present(value) => [Bytes.from_str(value.to_str())]
				},
			),
		),
		Decode.bytes_list,
	)

	vsim : Bytes.Bytes, Query, SearchOptions -> Request.Request(List(Match), Reply.Error)
	vsim = |key, query, options| {
		var $args = [key].concat(
			match query {
				Element(element) => ["ELE", element]
				Vector(vector) => vector_args(vector)
			},
		)
		if options.scores {
			$args = $args.append("WITHSCORES")
		}
		if options.attributes {
			$args = $args.append("WITHATTRIBS")
		}
		$args = $args.concat(number_option("COUNT", options.count)).concat(bytes_option("EPSILON", options.epsilon)).concat(positive_option("EF", options.exploration)).concat(bytes_option("FILTER", options.filter)).concat(number_option("FILTER-EF", options.filter_effort))
		if options.exact {
			$args = $args.append("TRUTH")
		}
		if options.no_thread {
			$args = $args.append("NOTHREAD")
		}
		Request.new(Command.new("VSIM", $args), |reply| matches(reply, options.scores, options.attributes))
	}
}

vector_args : VectorSets.Vector -> List(Bytes.Bytes)
vector_args = |vector| match vector {
	Fp32(data) => ["FP32", data]
	Values(values) => ["VALUES", Bytes.from_str(values.len().to_str())].concat(values.to_list())
}

positive_option : Bytes.Bytes, Reply.Optional(Positive.Positive) -> List(Bytes.Bytes)
positive_option = |name, value| match value {
	Absent => []
	Present(number) => [name, Bytes.from_str(number.to_u64().to_str())]
}

number_option : Bytes.Bytes, Reply.Optional(U64) -> List(Bytes.Bytes)
number_option = |name, value| match value {
	Absent => []
	Present(number) => [name, Bytes.from_str(number.to_str())]
}

bytes_option : Bytes.Bytes, Reply.Optional(Bytes.Bytes) -> List(Bytes.Bytes)
bytes_option = |name, value| match value {
	Absent => []
	Present(data) => [name, data]
}

bound_arg : VectorSets.Bound -> Bytes.Bytes
bound_arg = |bound| match bound {
	Minimum => "-"
	Maximum => "+"
	Inclusive(value) => Bytes.from_list(['['].concat(value.to_list()))
	Exclusive(value) => Bytes.from_list(['('].concat(value.to_list()))
}

raw_embedding : Resp.Resp -> Try({ quantization : Bytes.Bytes, data : Bytes.Bytes, norm : Bytes.Bytes, range : Reply.Optional(Bytes.Bytes) }, Reply.Error)
raw_embedding = |reply| match reply {
	Array([quantization, data, norm]) => Ok({ quantization: Bytes.from_list(Reply.simple(quantization)?), data: Decode.bytes(data)?, norm: Decode.bytes(norm)?, range: Absent })
	Array([quantization, data, norm, range]) => Ok({ quantization: Bytes.from_list(Reply.simple(quantization)?), data: Decode.bytes(data)?, norm: Decode.bytes(norm)?, range: Present(Decode.bytes(range)?) })
	_ => Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
}

matches : Resp.Resp, Bool, Bool -> Try(List(VectorSets.Match), Reply.Error)
matches = |reply, scores, attributes| {
	items = Reply.array(reply)?
	width = 1.U64 + (
		if scores {
			1
		} else {
			0
		}
	) + (
		if attributes {
			1
		} else {
			0
		}
	)
	if items.len() % width != 0 {
		return Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
	}
	var $values = List.with_capacity(items.len() / width)
	var $index = 0.U64
	while $index < items.len() {
		element_reply = items.get($index).map_err(|_| UnexpectedReply({ actual: reply, expected: ArrayReply }))?
		element = Decode.bytes(element_reply)?
		$index = $index + 1
		score = if scores {
			item = items.get($index).map_err(|_| UnexpectedReply({ actual: reply, expected: ArrayReply }))?
			$index = $index + 1
			Present(Decode.bytes(item)?)
		} else {
			Absent
		}
		attribute = if attributes {
			item = items.get($index).map_err(|_| UnexpectedReply({ actual: reply, expected: ArrayReply }))?
			$index = $index + 1
			Decode.optional_bytes(item)?
		} else {
			Absent
		}
		$values = $values.append({ element, score, attributes: attribute })
	}
	Ok($values)
}

expect VectorSets.vadd("v", Values(NonEmpty.new(Bytes.from_str("1"), ["2"])), "a", VectorSets.AddOptions.{}).command() == Command.new("VADD", ["v", "VALUES", "2", "1", "2", "a"])
expect VectorSets.vemb("v", "a", Values).decode(Resp.NullBulkString) == Ok(Values(Absent))
expect VectorSets.vemb("v", "a", Values).decode(Resp.NullArray).is_err()
expect VectorSets.vemb("v", "a", Raw).decode(Resp.Array([Resp.simple_utf8("fp32"), Resp.BulkString([0, 255]), Resp.bulk_utf8("1")])).is_ok()
expect VectorSets.vlinks("v", "a", True).decode(Resp.Array([Resp.Array([Resp.bulk_utf8("b"), Resp.bulk_utf8("0.5")])])) == Ok(Present([[{ element: Bytes.from_str("b"), score: Present(Bytes.from_str("0.5")), attributes: Absent }]]))
expect VectorSets.vsim("v", Element("a"), { scores: True, attributes: True }).decode(Resp.Array([Resp.bulk_utf8("a"), Resp.bulk_utf8("1"), Resp.NullBulkString])) == Ok([{ element: Bytes.from_str("a"), score: Present(Bytes.from_str("1")), attributes: Absent }])
expect VectorSets.vsim("v", Element("a"), { scores: True }).decode(Resp.Array([Resp.bulk_utf8("a")])).is_err()
expect VectorSets.vrange("v", Inclusive("a"), Maximum, Present(-1)).command() == Command.new("VRANGE", ["v", "[a", "+", "-1"])
