import Resp

LineKind : [ArrayLengthLine, BulkLengthLine, ErrorLine, IntegerLine, SimpleLine]

LineState : {
	content : List(U8),
	kind : LineKind,
	saw_carriage_return : Bool,
	start : U64,
}

BulkState : {
	content : List(U8),
	remaining : U64,
	start : U64,
}

BulkEndState : {
	content : List(U8),
	start : U64,
}

ArrayFrame : {
	remaining : U64,
	start : U64,
	values : List(Resp.Resp),
}

ParserState : [
	AwaitType,
	ReadingBulk(BulkState),
	ReadingLine(LineState),
	WantBulkCarriageReturn(BulkEndState),
	WantBulkLineFeed(BulkEndState),
]

## A genuinely incremental, platform-independent RESP2 decoder.
##
## The decoder retains parsed state rather than a copy of the incomplete wire
## frame. Each input byte is examined once. `Progress.values` may contain zero,
## one, or several complete top-level replies, so transport reads and RESP
## values never need to share boundaries.
Decoder := {
	limits : Limits,
	offset : U64,
	stack : List(ArrayFrame),
	state : ParserState,
	value_count : U64,
}.{

	## Resource limits applied independently to each top-level RESP value.
	## Limits are invariant to how the transport fragments that value.
	## `max_frame_length` includes every wire byte in the value, while
	## `max_line_length` counts only bytes between a type prefix and CRLF.
	## `max_values` counts an aggregate itself plus all of its descendants.
	## `max_depth` counts array prefixes (including empty and null arrays), so a
	## top-level array has depth one. Array and bulk limits count immediate
	## elements and payload bytes, respectively.
	Limits : {
		max_array_length : U64,
		max_bulk_length : U64,
		max_depth : U64,
		max_frame_length : U64,
		max_line_length : U64,
		max_values : U64,
	}

	## What the decoder was waiting for when the byte stream ended.
	EndContext : [
		ArrayItems({ remaining : U64 }),
		BulkCarriageReturn,
		BulkData({ remaining : U64 }),
		BulkLineFeed,
		LineEnd,
		LineFeed,
	]

	## A malformed or resource-exhausting RESP frame. Every `at` offset is
	## relative to the start of the current top-level frame.
	DecodeError : [
		ArrayLengthLimitExceeded({ actual : U64, at : U64, limit : U64 }),
		BulkLengthLimitExceeded({ actual : U64, at : U64, limit : U64 }),
		ExpectedBulkTerminator({ actual : U8, at : U64, expected : U8 }),
		FrameLengthLimitExceeded({ at : U64, limit : U64 }),
		InvalidArrayLength({ at : U64, header : List(U8) }),
		InvalidBulkLength({ at : U64, header : List(U8) }),
		InvalidInteger({ at : U64, header : List(U8) }),
		InvalidLineEnding({ at : U64 }),
		LineLengthLimitExceeded({ at : U64, limit : U64 }),
		NestingLimitExceeded({ at : U64, limit : U64 }),
		UnexpectedEnd({ at : U64, context : EndContext }),
		UnknownType({ at : U64, byte : U8 }),
		ValueLimitExceeded({ at : U64, limit : U64 }),
	]

	## The result of feeding a chunk. A failure also returns any complete
	## top-level values which preceded the malformed frame in the same input.
	## A failed decoder is terminal and must not be reused.
	FeedResult : [
		Failed({ completed : List(Resp.Resp), error : DecodeError }),
		Progress({ decoder : Decoder, values : List(Resp.Resp) }),
	]

	## Redis-compatible defaults. The 512 MiB bulk limit matches Redis's
	## default maximum string value; network clients should normally choose
	## lower per-connection limits with [Decoder.with_limits].
	default_limits : Limits
	default_limits = {
		max_array_length: 1_000_000,
		max_bulk_length: 536_870_912,
		max_depth: 128,
		max_frame_length: 536_936_448,
		max_line_length: 65_536,
		max_values: 1_000_000,
	}

	## Construct an empty decoder with [Decoder.default_limits].
	init : {} -> Decoder
	init = |_|
		new_decoder(Decoder.default_limits)

	## Construct an empty decoder with caller-selected limits.
	with_limits : Limits -> Decoder
	with_limits = |limits|
		new_decoder(limits)

	## Bytes consumed into the incomplete top-level frame. This is a logical
	## frame offset; the decoder does not retain all of those raw bytes.
	buffered_len : Decoder -> U64
	buffered_len = |decoder| decoder.offset

	## Decode every complete top-level RESP2 value in `chunk`.
	feed : Decoder, List(U8) -> FeedResult
	feed = |decoder, chunk|
		consume_chunk({ chunk, completed: [], decoder, index: 0 })

	## Assert that the stream ended between frames rather than inside one.
	finish : Decoder -> Try({}, DecodeError)
	finish = |decoder|
		match decoder.state {
			AwaitType =>
				match decoder.stack {
					[] => Ok({})
					[frame, ..] => Err(UnexpectedEnd({ at: decoder.offset, context: ArrayItems({ remaining: frame.remaining }) }))
				}
			ReadingBulk(bulk) => Err(UnexpectedEnd({ at: decoder.offset, context: BulkData({ remaining: bulk.remaining }) }))
			ReadingLine(line) =>
				if line.saw_carriage_return {
					Err(UnexpectedEnd({ at: decoder.offset, context: LineFeed }))
				} else {
					Err(UnexpectedEnd({ at: decoder.offset, context: LineEnd }))
				}
			WantBulkCarriageReturn(_) => Err(UnexpectedEnd({ at: decoder.offset, context: BulkCarriageReturn }))
			WantBulkLineFeed(_) => Err(UnexpectedEnd({ at: decoder.offset, context: BulkLineFeed }))
		}
}

StepResult : [
	StepContinue(Decoder),
	StepEmitted({ decoder : Decoder, value : Resp.Resp }),
	StepFailed(Decoder.DecodeError),
]

SignedDecimalResult : [SignedDecimal(I64), SignedDecimalInvalid(U64)]

LengthResult : [LengthInvalid(U64), LengthNull, LengthValue(U64)]

DigitResult : [DigitInvalid(U64), DigitsValid]

## State supplied to the chunk loop. Bulk payloads are appended in spans, while
## framing bytes use the byte-level state machine for precise error offsets.
ChunkState : {
	chunk : List(U8),
	completed : List(Resp.Resp),
	decoder : Decoder,
	index : U64,
}

new_decoder : Decoder.Limits -> Decoder
new_decoder = |limits| {
	limits,
	offset: 0,
	stack: [],
	state: AwaitType,
	value_count: 0,
}

consume_chunk : ChunkState -> Decoder.FeedResult
consume_chunk = |{ chunk, completed, decoder, index }| {
	var $decoder = decoder
	var $completed = completed
	var $index = index
	while $index < chunk.len() {
		match $decoder.state {
			ReadingBulk(bulk) if $decoder.offset < $decoder.limits.max_frame_length => {
				available = chunk.len() - $index
				budget = $decoder.limits.max_frame_length - $decoder.offset
				payload_count = if bulk.remaining < available {
					bulk.remaining
				} else {
					available
				}
				count = if payload_count < budget {
					payload_count
				} else {
					budget
				}
				# Append only bytes actually received. An advertised bulk length
				# alone must not trigger a proportional allocation.
				content = bulk.content.append_sublist(chunk, { start: $index, len: count })
				state = if count == bulk.remaining {
					WantBulkCarriageReturn({ content, start: bulk.start })
				} else {
					ReadingBulk({ content, start: bulk.start, remaining: bulk.remaining - count })
				}
				$decoder = { ..$decoder, state, offset: $decoder.offset + count }
				$index = $index + count
			}
			_ => {
				match step_byte($decoder, get_or_zero(chunk, $index)) {
					StepContinue(next_decoder) => {
						$decoder = next_decoder
					}
					StepEmitted({ decoder: next_decoder, value }) => {
						$decoder = next_decoder
						$completed = $completed.append(value)
					}
					StepFailed(error) => {
						return Failed({ completed: $completed, error })
					}
				}
				$index = $index + 1
			}
		}
	}
	Progress({ decoder: $decoder, values: $completed })
}

step_byte : Decoder, U8 -> StepResult
step_byte = |decoder, byte|
	if decoder.offset >= decoder.limits.max_frame_length {
		StepFailed(FrameLengthLimitExceeded({ at: decoder.offset, limit: decoder.limits.max_frame_length }))
	} else {
		match decoder.state {
			AwaitType => step_type(decoder, byte)
			ReadingBulk(bulk) => step_bulk_data(decoder, bulk, byte)
			ReadingLine(line) => step_line(decoder, line, byte)
			WantBulkCarriageReturn(bulk) => step_bulk_carriage_return(decoder, bulk, byte)
			WantBulkLineFeed(bulk) => step_bulk_line_feed(decoder, bulk, byte)
		}
	}

step_type : Decoder, U8 -> StepResult
step_type = |decoder, byte|
	match byte {
		'+' => begin_line(decoder, SimpleLine)
		'-' => begin_line(decoder, ErrorLine)
		':' => begin_line(decoder, IntegerLine)
		'$' => begin_line(decoder, BulkLengthLine)
		'*' => {
			if decoder.value_count >= decoder.limits.max_values {
				StepFailed(ValueLimitExceeded({ at: decoder.offset, limit: decoder.limits.max_values }))
			} else if decoder.stack.len() >= decoder.limits.max_depth {
				StepFailed(NestingLimitExceeded({ at: decoder.offset, limit: decoder.limits.max_depth }))
			} else {
				begin_line_unchecked(decoder, ArrayLengthLine)
			}
		}
		_ => StepFailed(UnknownType({ at: decoder.offset, byte }))
	}

begin_line : Decoder, LineKind -> StepResult
begin_line = |decoder, kind|
	if decoder.value_count >= decoder.limits.max_values {
		StepFailed(ValueLimitExceeded({ at: decoder.offset, limit: decoder.limits.max_values }))
	} else {
		begin_line_unchecked(decoder, kind)
	}

begin_line_unchecked : Decoder, LineKind -> StepResult
begin_line_unchecked = |decoder, kind| {
	line = {
		content: [],
		kind,
		saw_carriage_return: False,
		start: decoder.offset,
	}
	StepContinue(advance_with_state(decoder, ReadingLine(line)))
}

step_line : Decoder, LineState, U8 -> StepResult
step_line = |decoder, line, byte| {
	at = decoder.offset
	if line.saw_carriage_return {
		if byte == 10 {
			finish_line(advance_with_state(decoder, AwaitType), line)
		} else {
			StepFailed(
				InvalidLineEnding(
					{ at: at },
				),
			)
		}
	} else if byte == 13 {
		updated = {
			content: line.content,
			kind: line.kind,
			saw_carriage_return: True,
			start: line.start,
		}
		StepContinue(advance_with_state(decoder, ReadingLine(updated)))
	} else if byte == 10 {
		StepFailed(
			InvalidLineEnding(
				{ at: at },
			),
		)
	} else if line.content.len() >= decoder.limits.max_line_length {
		StepFailed(LineLengthLimitExceeded({ at, limit: decoder.limits.max_line_length }))
	} else {
		updated = {
			content: line.content.append(byte),
			kind: line.kind,
			saw_carriage_return: False,
			start: line.start,
		}
		StepContinue(advance_with_state(decoder, ReadingLine(updated)))
	}
}

finish_line : Decoder, LineState -> StepResult
finish_line = |decoder, line|
	match line.kind {
		SimpleLine => complete_value(decoder, SimpleString(line.content), line.start)
		ErrorLine => complete_value(decoder, ErrorReply(line.content), line.start)
		IntegerLine =>
			match parse_signed_decimal(line.content) {
				SignedDecimal(value) => complete_value(decoder, Integer(value), line.start)
				SignedDecimalInvalid(relative) => StepFailed(InvalidInteger({ at: header_at(line.start, relative), header: line.content }))
			}
		BulkLengthLine =>
			match parse_length(line.content) {
				LengthInvalid(relative) => StepFailed(InvalidBulkLength({ at: header_at(line.start, relative), header: line.content }))
				LengthNull => complete_value(decoder, NullBulkString, line.start)
				LengthValue(length) => {
					if length > decoder.limits.max_bulk_length {
						StepFailed(BulkLengthLimitExceeded({ actual: length, at: line.start, limit: decoder.limits.max_bulk_length }))
					} else {
						bulk = { content: [], remaining: length, start: line.start }
						if length == 0 {
							StepContinue(with_state(decoder, WantBulkCarriageReturn({ content: [], start: line.start })))
						} else {
							StepContinue(with_state(decoder, ReadingBulk(bulk)))
						}
					}
				}
			}
		ArrayLengthLine =>
			match parse_length(line.content) {
				LengthInvalid(relative) => StepFailed(InvalidArrayLength({ at: header_at(line.start, relative), header: line.content }))
				LengthNull => complete_value(decoder, NullArray, line.start)
				LengthValue(length) => {
					if length > decoder.limits.max_array_length {
						StepFailed(ArrayLengthLimitExceeded({ actual: length, at: line.start, limit: decoder.limits.max_array_length }))
					} else {
						available = decoder.limits.max_values - decoder.value_count
						if length >= available {
							StepFailed(ValueLimitExceeded({ at: line.start, limit: decoder.limits.max_values }))
						} else if length == 0 {
							complete_value(decoder, Array([]), line.start)
						} else {
							frame = { remaining: length, start: line.start, values: [] }
							StepContinue(with_stack_and_state(decoder, [frame].concat(decoder.stack), AwaitType))
						}
					}
				}
			}
		}

step_bulk_data : Decoder, BulkState, U8 -> StepResult
step_bulk_data = |decoder, bulk, byte| {
	content = bulk.content.append(byte)
	if bulk.remaining <= 1 {
		end = { content, start: bulk.start }
		StepContinue(advance_with_state(decoder, WantBulkCarriageReturn(end)))
	} else {
		updated = { content, remaining: bulk.remaining - 1, start: bulk.start }
		StepContinue(advance_with_state(decoder, ReadingBulk(updated)))
	}
}

step_bulk_carriage_return : Decoder, BulkEndState, U8 -> StepResult
step_bulk_carriage_return = |decoder, bulk, byte|
	if byte == 13 {
		StepContinue(advance_with_state(decoder, WantBulkLineFeed(bulk)))
	} else {
		StepFailed(ExpectedBulkTerminator({ actual: byte, at: decoder.offset, expected: 13 }))
	}

step_bulk_line_feed : Decoder, BulkEndState, U8 -> StepResult
step_bulk_line_feed = |decoder, bulk, byte|
	if byte == 10 {
		complete_value(advance_with_state(decoder, AwaitType), BulkString(bulk.content), bulk.start)
	} else {
		StepFailed(ExpectedBulkTerminator({ actual: byte, at: decoder.offset, expected: 10 }))
	}

complete_value : Decoder, Resp.Resp, U64 -> StepResult
complete_value = |decoder, value, start|
	if decoder.value_count >= decoder.limits.max_values {
		StepFailed(ValueLimitExceeded({ at: start, limit: decoder.limits.max_values }))
	} else {
		counted = with_value_count(decoder, decoder.value_count + 1)
		match counted.stack {
			[] => StepEmitted({ decoder: new_decoder(counted.limits), value })
			[frame, .. as rest] => {
				values = frame.values.append(value)
				if frame.remaining <= 1 {
					parent = with_stack_and_state(counted, rest, AwaitType)
					complete_value(parent, Array(values), frame.start)
				} else {
					updated = { remaining: frame.remaining - 1, start: frame.start, values }
					StepContinue(with_stack_and_state(counted, [updated].concat(rest), AwaitType))
				}
			}
		}
	}

advance_with_state : Decoder, ParserState -> Decoder
advance_with_state = |decoder, state| {
	limits: decoder.limits,
	offset: decoder.offset + 1,
	stack: decoder.stack,
	state,
	value_count: decoder.value_count,
}

with_state : Decoder, ParserState -> Decoder
with_state = |decoder, state| {
	limits: decoder.limits,
	offset: decoder.offset,
	stack: decoder.stack,
	state,
	value_count: decoder.value_count,
}

with_stack_and_state : Decoder, List(ArrayFrame), ParserState -> Decoder
with_stack_and_state = |decoder, stack, state| {
	limits: decoder.limits,
	offset: decoder.offset,
	stack,
	state,
	value_count: decoder.value_count,
}

with_value_count : Decoder, U64 -> Decoder
with_value_count = |decoder, value_count| {
	limits: decoder.limits,
	offset: decoder.offset,
	stack: decoder.stack,
	state: decoder.state,
	value_count,
}

parse_signed_decimal : List(U8) -> SignedDecimalResult
parse_signed_decimal = |bytes|
	if bytes.is_empty() {
		SignedDecimalInvalid(0)
	} else {
		first = get_or_zero(bytes, 0)
		digits_start = if first == 43 or first == 45 {
			1
		} else {
			0
		}
		if digits_start >= bytes.len() {
			SignedDecimalInvalid(digits_start)
		} else {
			match validate_decimal_digits(bytes, digits_start) {
				DigitInvalid(index) => SignedDecimalInvalid(index)
				DigitsValid =>
					match Str.from_utf8(bytes) {
						Err(_) => SignedDecimalInvalid(0)
						Ok(text) =>
							match I64.from_str(text) {
								Err(_) => SignedDecimalInvalid(bytes.len() - 1)
								Ok(value) => SignedDecimal(value)
							}
						}
				}
		}
	}

parse_length : List(U8) -> LengthResult
parse_length = |bytes|
	if bytes == [45, 49] {
		LengthNull
	} else if bytes.is_empty() {
		LengthInvalid(0)
	} else {
		match validate_decimal_digits(bytes, 0) {
			DigitInvalid(index) => LengthInvalid(index)
			DigitsValid =>
				match Str.from_utf8(bytes) {
					Err(_) => LengthInvalid(0)
					Ok(text) =>
						match U64.from_str(text) {
							Err(_) => LengthInvalid(bytes.len() - 1)
							Ok(value) => LengthValue(value)
						}
					}
			}
	}

validate_decimal_digits : List(U8), U64 -> DigitResult
validate_decimal_digits = |bytes, index|
	if index >= bytes.len() {
		DigitsValid
	} else {
		byte = get_or_zero(bytes, index)
		if byte >= 48 and byte <= 57 {
			validate_decimal_digits(bytes, index + 1)
		} else {
			DigitInvalid(index)
		}
	}

header_at : U64, U64 -> U64
header_at = |start, relative|
	start + 1 + relative

get_or_zero : List(U8), U64 -> U8
get_or_zero = |bytes, index|
	match bytes.get(index) {
		Ok(byte) => byte
		Err(_) => 0
	}
