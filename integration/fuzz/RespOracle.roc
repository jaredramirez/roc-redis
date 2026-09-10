import redis.Decoder
import redis.Resp

## A deliberately small, one-shot RESP2 reference implementation for fuzz tests.
## It does not use Decoder's state machine, scalar path, or parsing helpers.
RespOracle :: [].{
	Reference : [Complete(List(Resp.Resp)), Incomplete(List(Resp.Resp)), Invalid(List(Resp.Resp))]
	Observed : [Decoded(List(Resp.Resp)), Failed({ completed : List(Resp.Resp), error : Decoder.DecodeError }), Unfinished({ completed : List(Resp.Resp), error : Decoder.DecodeError })]

	encode : Resp.Resp -> List(U8)
	encode = |value| match value {
		Resp.Array(values) => "*${values.len().to_str()}\r\n".to_utf8().concat(values.join_map(RespOracle.encode))
		Resp.BulkString(bytes) => "$${bytes.len().to_str()}\r\n".to_utf8().concat(bytes).concat(['\r', '\n'])
		Resp.ErrorReply(bytes) => ['-'].concat(bytes).concat(['\r', '\n'])
		Resp.Integer(number) => [':'].concat(number.to_str().to_utf8()).concat(['\r', '\n'])
		Resp.NullBulkString => "$-1\r\n".to_utf8()
		Resp.NullArray => "*-1\r\n".to_utf8()
		Resp.SimpleString(bytes) => ['+'].concat(bytes).concat(['\r', '\n'])
	}

	reference : List(U8) -> Reference
	reference = |wire| parse_all(wire, 0, [])

	observe : List(U8) -> Observed
	observe = |wire| observe_chunks(wire, [])

	observe_chunks : List(U8), List(U8) -> Observed
	observe_chunks = |wire, sizes| feed_scheduled(Decoder.init(), wire, 0, sizes, [])

	observe_single_bytes : List(U8) -> Observed
	observe_single_bytes = |wire| feed_single(Decoder.init(), wire, 0, [])

	## Compare protocol acceptance and completed top-level prefixes. The reference
	## intentionally does not duplicate Decoder's library-specific error taxonomy.
	agrees : Reference, Observed -> Bool
	agrees = |expected, observed| match expected {
		Complete(values) => match observed {
			Decoded(actual) => actual == values
			_ => False
		}
		Invalid(completed) => match observed {
			Failed({ completed: actual, .. }) => actual == completed
			_ => False
		}
		Incomplete(completed) => match observed {
			Decoded(_) => False
			Failed({ completed: actual, .. }) => actual == completed
			Unfinished({ completed: actual, .. }) => actual == completed
		}
	}
}

OneResult : [OneComplete({ next : U64, value : Resp.Resp }), OneIncomplete, OneInvalid]

LineResult : [LineComplete({ content : List(U8), next : U64 }), LineIncomplete, LineInvalid]

LengthResult : [LengthInvalid, LengthNull, LengthValue(U64)]

parse_all = |wire, index, values|
	if index >= wire.len() {
		Complete(values)
	} else {
		match parse_one(wire, index, 0) {
			OneComplete({ next, value }) => parse_all(wire, next, values.append(value))
			OneIncomplete => Incomplete(values)
			OneInvalid => Invalid(values)
		}
	}

parse_one : List(U8), U64, U64 -> OneResult
parse_one = |wire, index, depth|
	match wire.get(index) {
		Err(_) => OneIncomplete
		Ok(prefix) => match prefix {
			'+' => parse_text(wire, index, False)
			'-' => parse_text(wire, index, True)
			':' => parse_integer(wire, index)
			'$' => parse_bulk(wire, index)
			'*' => parse_array(wire, index, depth)
			_ => OneInvalid
		}
	}

parse_text = |wire, index, is_error|
	match scan_line(wire, index + 1, index + 1) {
		LineIncomplete => OneIncomplete
		LineInvalid => OneInvalid
		LineComplete({ content, next }) => OneComplete({ next, value: if is_error Resp.ErrorReply(content) else Resp.SimpleString(content) })
	}

parse_integer = |wire, index|
	match scan_line(wire, index + 1, index + 1) {
		LineIncomplete => OneIncomplete
		LineInvalid => OneInvalid
		LineComplete({ content, next }) =>
			if !valid_signed_decimal(content) {
				OneInvalid
			} else {
				match Str.from_utf8(content) {
					Err(_) => OneInvalid
					Ok(text) => match I64.from_str(text) {
						Err(_) => OneInvalid
						Ok(number) => OneComplete({ next, value: Resp.Integer(number) })
					}
				}
			}
		}

parse_bulk = |wire, index|
	match scan_line(wire, index + 1, index + 1) {
		LineIncomplete => OneIncomplete
		LineInvalid => OneInvalid
		LineComplete({ content, next }) => match parse_length(content) {
			LengthInvalid => OneInvalid
			LengthNull => OneComplete({ next, value: Resp.NullBulkString })
			LengthValue(length) => {
				limits = Decoder.default_limits
				if length > limits.max_bulk_length {
					OneInvalid
				} else if length > wire.len() - next {
					OneIncomplete
				} else {
					end = next + length
					if end >= wire.len() {
						OneIncomplete
					} else if end + 1 >= wire.len() {
						if wire.get(end) == Ok('\r') OneIncomplete else OneInvalid
					} else if wire.get(end) != Ok('\r') or wire.get(end + 1) != Ok('\n') {
						OneInvalid
					} else {
						OneComplete({ next: end + 2, value: Resp.BulkString(wire.sublist({ start: next, len: length })) })
					}
				}
			}
		}
	}

parse_array = |wire, index, depth|
	match scan_line(wire, index + 1, index + 1) {
		LineIncomplete => OneIncomplete
		LineInvalid => OneInvalid
		LineComplete({ content, next }) => match parse_length(content) {
			LengthInvalid => OneInvalid
			LengthNull => OneComplete({ next, value: Resp.NullArray })
			LengthValue(length) => {
				limits = Decoder.default_limits
				if length > limits.max_array_length or depth >= limits.max_depth or length >= limits.max_values {
					OneInvalid
				} else {
					parse_array_items(wire, next, depth + 1, length, [])
				}
			}
		}
	}

parse_array_items = |wire, index, depth, remaining, values|
	if remaining == 0 {
		OneComplete({ next: index, value: Resp.Array(values) })
	} else {
		match parse_one(wire, index, depth) {
			OneComplete({ next, value }) => parse_array_items(wire, next, depth, remaining - 1, values.append(value))
			OneIncomplete => OneIncomplete
			OneInvalid => OneInvalid
		}
	}

scan_line : List(U8), U64, U64 -> LineResult
scan_line = |wire, start, index|
	match wire.get(index) {
		Err(_) => LineIncomplete
		Ok('\n') => LineInvalid
		Ok('\r') => match wire.get(index + 1) {
			Err(_) => LineIncomplete
			Ok('\n') => LineComplete({ content: wire.sublist({ start, len: index - start }), next: index + 2 })
			Ok(_) => LineInvalid
		}
		Ok(_) => scan_line(wire, start, index + 1)
	}

valid_signed_decimal = |bytes|
	if bytes.is_empty() {
		False
	} else {
		first = bytes.first() ?? 0
		start = if first == '+' or first == '-' 1 else 0
		start < bytes.len() and all_digits(bytes, start)
	}

all_digits = |bytes, index|
	if index >= bytes.len() {
		True
	} else {
		byte = bytes.get(index) ?? 0
		byte >= '0' and byte <= '9' and all_digits(bytes, index + 1)
	}

parse_length = |bytes|
	if bytes == ['-', '1'] {
		LengthNull
	} else if bytes.is_empty() or !all_digits(bytes, 0) {
		LengthInvalid
	} else {
		accumulate_length(bytes, 0, 0)
	}

accumulate_length = |bytes, index, value|
	if index >= bytes.len() {
		LengthValue(value)
	} else {
		digit = (bytes.get(index) ?? '0') - '0'
		digit_u64 = digit.to_u64()
		if value > (U64.highest - digit_u64) / 10 {
			LengthInvalid
		} else {
			accumulate_length(bytes, index + 1, value * 10 + digit_u64)
		}
	}

feed_scheduled = |decoder, wire, index, sizes, completed|
	if index >= wire.len() {
		finish_observed(decoder, completed)
	} else {
		(size, rest) = match sizes {
			[] => (wire.len() - index, [])
			[first, .. as following] => (1 + first.to_u64() % 32, following)
		}
		count = size.min(wire.len() - index)
		match Decoder.feed(decoder, wire.sublist({ start: index, len: count })) {
			Failed({ completed: just_completed, error }) => Failed({ completed: completed.concat(just_completed), error })
			Progress({ decoder: next, values }) => feed_scheduled(next, wire, index + count, rest, completed.concat(values))
		}
	}

feed_single = |decoder, wire, index, completed|
	if index >= wire.len() {
		finish_observed(decoder, completed)
	} else {
		match Decoder.feed(decoder, wire.sublist({ start: index, len: 1 })) {
			Failed({ completed: just_completed, error }) => Failed({ completed: completed.concat(just_completed), error })
			Progress({ decoder: next, values }) => feed_single(next, wire, index + 1, completed.concat(values))
		}
	}

finish_observed = |decoder, completed|
	match Decoder.finish(decoder) {
		Ok({}) => Decoded(completed)
		Err(error) => Unfinished({ completed, error })
	}
