import /Bytes
import /Command
import /Commands/Decode
import /NonEmpty
import /NonEmptyBytes
import /Positive
import /Reply
import /Request
import /Resp

## Numeric coordinate/distance text remains exact. Redis validates syntax and
## geographic bounds. Coordinate results are quantized Redis positions, not
## promises to reproduce the original input coordinates exactly.
Geo :: [].{
	Unit : [Meters, Kilometers, Feet, Miles]
	Coordinates : { longitude : Bytes.Bytes, latitude : Bytes.Bytes }
	Point : { coordinates : Coordinates, member : Bytes.Bytes }
	AddOptions := { condition : [Always, IfMissing, IfPresent] ?? Always, changed : Bool ?? False }
	Origin : [Member(Bytes.Bytes), Coordinates(Coordinates)]
	Shape : [Radius({ radius : Bytes.Bytes, unit : Unit }), Box({ width : Bytes.Bytes, height : Bytes.Bytes, unit : Unit })]
	SearchOptions := { order : [Unspecified, Ascending, Descending] ?? Unspecified, count : Reply.Optional({ limit : Positive.Positive, any : Bool }) ?? Absent }
	Output := { distance : Bool ?? False, hash : Bool ?? False, coordinates : Bool ?? False }
	Match : { member : Bytes.Bytes, distance : Reply.Optional(Bytes.Bytes), hash : Reply.Optional(I64), coordinates : Reply.Optional(Coordinates) }
	RadiusMode : [Read(Output), Store({ destination : Bytes.Bytes, distance : Bool })]
	RadiusResult : [Matches(List(Match)), Stored(I64)]

	geo_add : Bytes.Bytes, NonEmpty.NonEmpty(Point), AddOptions -> Request.Request(I64, Reply.Error)
	geo_add = |key, points, options| {
		condition = match options.condition {
			Always => []
			IfMissing => [Bytes.from_str("NX")]
			IfPresent => [Bytes.from_str("XX")]
		}
		changed = if options.changed {
			[Bytes.from_str("CH")]
		} else {
			[]
		}
		arguments = points.to_list().join_map(|point| [point.coordinates.longitude, point.coordinates.latitude, point.member])
		Request.new(Command.new("GEOADD", [key].concat(condition).concat(changed).concat(arguments)), Reply.integer)
	}

	geo_dist : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes, Unit -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	geo_dist = |key, first, second, measurement| Request.new(Command.new("GEODIST", [key, first, second, unit(measurement)]), Decode.optional_bytes)

	geo_hash : Bytes.Bytes, List(Bytes.Bytes) -> Request.Request(List(Reply.Optional(Bytes.Bytes)), Reply.Error)
	geo_hash = |key, members| Request.new(Command.new("GEOHASH", [key].concat(members)), |reply| Decode.counted(reply, members.len(), Decode.optional_bytes))

	geo_pos : Bytes.Bytes, List(Bytes.Bytes) -> Request.Request(List(Reply.Optional(Coordinates)), Reply.Error)
	geo_pos = |key, members| Request.new(
		Command.new("GEOPOS", [key].concat(members)),
		|reply| Decode.counted(
			reply,
			members.len(),
			|value| match value {
				NullArray => Ok(Absent)
				_ => coordinates(value).map_ok(|position| Present(position))
			},
		),
	)

	geo_search : Bytes.Bytes, Origin, Shape, SearchOptions, Output -> Request.Request(List(Match), Reply.Error)
	geo_search = |key, origin, shape, options, output| Request.new(Command.new("GEOSEARCH", [key].concat(origin_args(origin)).concat(shape_args(shape)).concat(search_args(options)).concat(output_args(output))), |reply| Decode.list(reply, |value| decode_match(value, output)))

	geo_search_store : Bytes.Bytes, Bytes.Bytes, Origin, Shape, SearchOptions, Bool -> Request.Request(I64, Reply.Error)
	geo_search_store = |destination, source, origin, shape, options, store_distance| {
		store = if store_distance {
			[Bytes.from_str("STOREDIST")]
		} else {
			[]
		}
		Request.new(Command.new("GEOSEARCHSTORE", [destination, source].concat(origin_args(origin)).concat(shape_args(shape)).concat(search_args(options)).concat(store)), Reply.integer)
	}

	geo_radius : Bytes.Bytes, Coordinates, Bytes.Bytes, Unit, SearchOptions, RadiusMode -> Request.Request(RadiusResult, Reply.Error)
	geo_radius = |key, position, radius, measurement, options, mode| radius_request("GEORADIUS", [key, position.longitude, position.latitude, radius, unit(measurement)], options, mode)

	geo_radius_by_member : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes, Unit, SearchOptions, RadiusMode -> Request.Request(RadiusResult, Reply.Error)
	geo_radius_by_member = |key, member, radius, measurement, options, mode| radius_request("GEORADIUSBYMEMBER", [key, member, radius, unit(measurement)], options, mode)

	geo_radius_ro : Bytes.Bytes, Coordinates, Bytes.Bytes, Unit, SearchOptions, Output -> Request.Request(List(Match), Reply.Error)
	geo_radius_ro = |key, position, radius, measurement, options, output| Request.new(Command.new("GEORADIUS_RO", [key, position.longitude, position.latitude, radius, unit(measurement)].concat(search_args(options)).concat(output_args(output))), |reply| Decode.list(reply, |value| decode_match(value, output)))

	geo_radius_by_member_ro : Bytes.Bytes, Bytes.Bytes, Bytes.Bytes, Unit, SearchOptions, Output -> Request.Request(List(Match), Reply.Error)
	geo_radius_by_member_ro = |key, member, radius, measurement, options, output| Request.new(Command.new("GEORADIUSBYMEMBER_RO", [key, member, radius, unit(measurement)].concat(search_args(options)).concat(output_args(output))), |reply| Decode.list(reply, |value| decode_match(value, output)))
}

unit : Geo.Unit -> Bytes.Bytes
unit = |value| match value {
	Meters => "m"
	Kilometers => "km"
	Feet => "ft"
	Miles => "mi"
}

origin_args : Geo.Origin -> List(Bytes.Bytes)
origin_args = |origin| match origin {
	Member(value) => ["FROMMEMBER", value]
	Coordinates(value) => ["FROMLONLAT", value.longitude, value.latitude]
}

shape_args : Geo.Shape -> List(Bytes.Bytes)
shape_args = |shape| match shape {
	Radius(value) => ["BYRADIUS", value.radius, unit(value.unit)]
	Box(value) => ["BYBOX", value.width, value.height, unit(value.unit)]
}

search_args : Geo.SearchOptions -> List(Bytes.Bytes)
search_args = |options| {
	order : List(Bytes.Bytes)
	order = match options.order {
		Unspecified => []
		Ascending => ["ASC"]
		Descending => ["DESC"]
	}
	count = match options.count {
		Absent => []
		Present(value) => {
			base : List(Bytes.Bytes)
			base = ["COUNT", Bytes.from_str(value.limit.to_u64().to_str())]
			if value.any {
				base.append("ANY")
			} else {
				base
			}
		}
	}
	order.concat(count)
}

output_args : Geo.Output -> List(Bytes.Bytes)
output_args = |output| {
	var $arguments = []
	if output.distance {
		$arguments = $arguments.append(Bytes.from_str("WITHDIST"))
	}
	if output.hash {
		$arguments = $arguments.append(Bytes.from_str("WITHHASH"))
	}
	if output.coordinates {
		$arguments = $arguments.append(Bytes.from_str("WITHCOORD"))
	}
	$arguments
}

coordinates : Resp.Resp -> Try(Geo.Coordinates, Reply.Error)
coordinates = |reply| match reply {
	Array([longitude, latitude]) => Ok({ longitude: Decode.bytes(longitude)?, latitude: Decode.bytes(latitude)? })
	_ => Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
}

part : List(Resp.Resp), U64, Resp.Resp -> Try(Resp.Resp, Reply.Error)
part = |items, index, reply| items.get(index).map_err(|_| UnexpectedReply({ actual: reply, expected: ArrayReply }))

decode_match : Resp.Resp, Geo.Output -> Try(Geo.Match, Reply.Error)
decode_match = |reply, output| {
	if !output.distance and !output.hash and !output.coordinates {
		return Ok({ member: Decode.bytes(reply)?, distance: Absent, hash: Absent, coordinates: Absent })
	}
	items = Reply.array(reply)?
	distance_size = if output.distance {
		1.U64
	} else {
		0
	}
	hash_size = if output.hash {
		1.U64
	} else {
		0
	}
	coordinate_size = if output.coordinates {
		1.U64
	} else {
		0
	}
	if items.len() != 1 + distance_size + hash_size + coordinate_size {
		return Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
	}
	Ok({
		member: Decode.bytes(part(items, 0, reply)?)?,
		distance: if output.distance {
			Present(Decode.bytes(part(items, 1, reply)?)?)
		} else {
			Absent
		},
		hash: if output.hash {
			Present(Reply.integer(part(items, 1 + distance_size, reply)?)?)
		} else {
			Absent
		},
		coordinates: if output.coordinates {
			Present(coordinates(part(items, 1 + distance_size + hash_size, reply)?)?)
		} else {
			Absent
		},
	})
}

radius_request : NonEmptyBytes.NonEmptyBytes, List(Bytes.Bytes), Geo.SearchOptions, Geo.RadiusMode -> Request.Request(Geo.RadiusResult, Reply.Error)
radius_request = |name, arguments, options, mode| {
	output = match mode {
		Read(settings) => output_args(settings)
		Store(settings) => [
			if settings.distance {
				Bytes.from_str("STOREDIST")
			} else {
				Bytes.from_str("STORE")
			},
			settings.destination,
		]
	}
	Request.new(
		Command.new(name, arguments.concat(search_args(options)).concat(output)),
		|reply| match mode {
			Read(settings) => Decode.list(reply, |value| decode_match(value, settings)).map_ok(|matches| Matches(matches))
			Store(_) => Reply.integer(reply).map_ok(|count| Stored(count))
		},
	)
}

expect Geo.geo_pos("key", ["missing"]).decode(Resp.Array([Resp.NullArray])) == Ok([Absent])
expect Geo.geo_pos("key", ["missing"]).decode(Resp.Array([Resp.NullBulkString])).is_err()
expect Geo.geo_hash("key", ["missing"]).decode(Resp.Array([Resp.NullBulkString])) == Ok([Absent])
expect {
	request = Geo.geo_search("key", Member("origin"), Radius({ radius: "1", unit: Kilometers }), Geo.SearchOptions.{}, Geo.Output.{ distance: True, hash: True, coordinates: True })
	reply = Resp.Array([Resp.Array([Resp.bulk_utf8("member"), Resp.bulk_utf8("0.5"), Resp.Integer(123), Resp.Array([Resp.bulk_utf8("1.2"), Resp.bulk_utf8("3.4")])])])
	request.decode(reply) == Ok([{ member: Bytes.from_str("member"), distance: Present(Bytes.from_str("0.5")), hash: Present(123), coordinates: Present({ longitude: Bytes.from_str("1.2"), latitude: Bytes.from_str("3.4") }) }])
}
expect Geo.geo_search("key", Member("origin"), Radius({ radius: "1", unit: Meters }), Geo.SearchOptions.{}, Geo.Output.{}).decode(Resp.Array([Resp.bulk_utf8("member")])) == Ok([{ member: Bytes.from_str("member"), distance: Absent, hash: Absent, coordinates: Absent }])
