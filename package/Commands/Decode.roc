import /Bytes
import /Reply
import /Resp

## Internal shared reply shapes for command families, not a public API layer.
Decode :: [].{
	bytes : Resp.Resp -> Try(Bytes.Bytes, Reply.Error)
	bytes = |reply| Reply.bulk(reply).map_ok(Bytes.from_list)

	optional_bytes : Resp.Resp -> Try(Reply.Optional(Bytes.Bytes), Reply.Error)
	optional_bytes = |reply| Reply.bulk_or_null(reply).map_ok(
		|value| match value {
			Absent => Absent
			Present(payload) => Present(Bytes.from_list(payload))
		},
	)

	list : Resp.Resp, (Resp.Resp -> Try(value, Reply.Error)) -> Try(List(value), Reply.Error)
	list = |reply, decode| {
		items = Reply.array(reply)?
		var $values = List.with_capacity(items.len())
		for item in items {
			$values = $values.append(decode(item)?)
		}
		Ok($values)
	}

	bytes_list : Resp.Resp -> Try(List(Bytes.Bytes), Reply.Error)
	bytes_list = |reply| Decode.list(reply, Decode.bytes)

	## Counted parallel replies must preserve one result per supplied argument.
	counted : Resp.Resp, U64, (Resp.Resp -> Try(value, Reply.Error)) -> Try(List(value), Reply.Error)
	counted = |reply, expected, decode| {
		items = Reply.array(reply)?
		if items.len() != expected {
			return Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
		}
		Decode.list(reply, decode)
	}

	## SCAN cursors are opaque server values. Keep them as exact bytes rather
	## than interpreting them as offsets or assuming a nonempty page means done.
	scan : Resp.Resp, (Resp.Resp -> Try(value, Reply.Error)) -> Try({ cursor : Bytes.Bytes, values : value }, Reply.Error)
	scan = |reply, decode| match reply {
		Array([cursor, items]) => Ok({ cursor: Decode.bytes(cursor)?, values: decode(items)? })
		_ => Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
	}
}
