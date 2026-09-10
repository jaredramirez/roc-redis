import Resp

LineKind : [ArrayLengthLine, BulkLengthLine, ErrorLine, IntegerLine, SimpleLine]

LineState : {
	content : List(U8),
	kind : LineKind,
	saw_carriage_return : Bool,
	start : U64,
}

BulkState : {
	content : BulkBuffer,
	remaining : U64,
	start : U64,
}

## Received pieces, newest first. Older pieces are at least twice the size of
## their newer neighbor. This bounds the piece list logarithmically even when
## caller/compiler ownership prevents in-place list growth.
## For example, piece lengths [2 KiB, 8 KiB] mean the older 8 KiB precede
## the newer 2 KiB on the wire. Pushing 5 KiB first merges 2 + 5, then
## 8 + 7, leaving [15 KiB]. finish walks pieces oldest-first. Up to 4 KiB the
## prefix stays in one piece to avoid small-reply bookkeeping overhead.
BulkBuffer : { pieces : List(List(U8)), length : U64 }

empty_bulk_buffer : BulkBuffer
empty_bulk_buffer = { pieces: [], length: 0 }

flat_bulk_prefix_limit : U64
flat_bulk_prefix_limit = 4096

buffer_push : BulkBuffer, List(U8) -> BulkBuffer
buffer_push = |buffer, bytes| {
	if bytes.is_empty() {
		return buffer
	}
	# Keep a small received prefix flat. Its copying cost is bounded by this
	# fixed threshold; larger payloads still use geometrically balanced pieces.
	if buffer.length <= flat_bulk_prefix_limit and bytes.len() <= flat_bulk_prefix_limit - buffer.length {
		prefix = buffer.pieces.first() ?? []
		return { pieces: [prefix.concat(bytes)], length: buffer.length + bytes.len() }
	}
	var $piece = bytes
	var $older = buffer.pieces
	while !$older.is_empty() {
		first = $older.first() ?? []
		if first.len() / 2 >= $piece.len() {
			break
		}
		$piece = first.concat($piece)
		$older = $older.drop_first(1)
	}
	{ pieces: [$piece].concat($older), length: buffer.length + bytes.len() }
}

buffer_finish : BulkBuffer, List(U8) -> List(U8)
buffer_finish = |buffer, final_bytes| {
	if buffer.length == 0 {
		return final_bytes
	}
	if buffer.pieces.len() == 1 {
		return (buffer.pieces.first() ?? []).concat(final_bytes)
	}
	var $result = List.with_capacity(buffer.length + final_bytes.len())
	var $index = buffer.pieces.len()
	while $index > 0 {
		$index = $index - 1
		$result = $result.concat(buffer.pieces.get($index) ?? [])
	}
	$result.concat(final_bytes)
}

expect buffer_push(empty_bulk_buffer, []) == empty_bulk_buffer
expect buffer_finish(empty_bulk_buffer, [0, 255]) == [0, 255]
expect {
	var $buffer = empty_bulk_buffer
	var $expected = []
	var $valid = True
	for length in [1.U64, 3, 2, 31, 0, 256, 7, 1, 1024, 8192, 63, 2] {
		bytes = List.repeat(length.to_u8_wrap(), length)
		$buffer = buffer_push($buffer, bytes)
		$expected = $expected.concat(bytes)
		$valid = $valid and $buffer.length == $expected.len()
		$valid = $valid and buffer_finish($buffer, [42]) == $expected.append(42)
		var $index = 1.U64
		while $index < $buffer.pieces.len() {
			newer = $buffer.pieces.get($index - 1) ?? []
			older = $buffer.pieces.get($index) ?? []
			$valid = $valid and !newer.is_empty() and older.len() / 2 >= newer.len()
			$index = $index + 1
		}
	}
	$valid
}
expect {
	var $buffer = empty_bulk_buffer
	var $expected = List.with_capacity(8192)
	var $index = 0.U64
	while $index < 8192 {
		byte = $index.to_u8_wrap()
		$buffer = buffer_push($buffer, [byte])
		$expected = $expected.append(byte)
		$index = $index + 1
	}
	$buffer.length == 8192 and $buffer.pieces.len() <= 14 and buffer_finish($buffer, []) == $expected
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

	## Conservative per-reply defaults, shared with Config.default. These are
	## protocol limits, not a heap or aggregate exchange budget. Direct callers
	## must also bound input chunks and the total replies/bytes they retain.
	default_limits : Limits
	default_limits = {
		max_array_length: 65_536,
		max_bulk_length: 8 * 1024 * 1024,
		max_depth: 64,
		max_frame_length: 16 * 1024 * 1024,
		max_line_length: 65_536,
		max_values: 131_072,
	}

	## Explicit larger policy for Redis-sized values. Not an exchange or heap
	## limit; use only with caller-owned aggregate and input-chunk budgets.
	redis_compatible_limits : Limits
	redis_compatible_limits = {
		max_array_length: 1_000_000,
		max_bulk_length: 536_870_912,
		max_depth: 128,
		max_frame_length: 536_936_448,
		max_line_length: 65_536,
		max_values: 1_000_000,
	}

	## Construct an empty decoder with [Decoder.default_limits].
	init : () -> Decoder
	init = ||
		new_decoder(Decoder.default_limits)

	## Construct an empty decoder with caller-selected limits.
	with_limits : Limits -> Decoder
	with_limits = |limits|
		new_decoder(limits)

	## Bytes consumed into the incomplete top-level frame. This is a logical
	## frame offset; the decoder does not retain all of those raw bytes.
	buffered_len : Decoder -> U64
	buffered_len = |decoder| decoder.offset

	## Decode every complete top-level RESP2 value in `chunk`. Per-reply limits
	## reset between values; this does not limit aggregate chunk/output size.
	## Execute supplies read-size and cumulative exchange limits for clients.
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

## Test oracle: process every byte through the scalar state machine. Keep it
## independent of the span fast paths to compare fragmentation and limit errors.
scalar_feed : Decoder, List(U8) -> Decoder.FeedResult
scalar_feed = |decoder, chunk| {
	var $decoder = decoder
	var $values = []
	for byte in chunk {
		match step_byte($decoder, byte) {
			StepContinue(next) => {
				$decoder = next
			}
			StepEmitted({ decoder: next, value }) => {
				$decoder = next
				$values = $values.append(value)
			}
			StepFailed(error) => return Failed({ completed: $values, error })
		}
	}
	Progress({ decoder: $decoder, values: $values })
}

expect {
	frames = ["+PONG\r\n", "-ERR binary\r\n", "+abc\n", "+abcd\rX", "+abcd\r\n:1\r\n", "*2\r\n+abcd\r\n-x\r\n", "+unterminated"].map(Str.to_utf8).concat([
		['+', 0, 255, '\r', '\n'],
		['-', 255, 0, '\r', '\n'],
	])
	var $okay = True
	for wire in frames {
		for line_limit in [1.U64, 3, 4, 5, 100] {
			for frame_limit in [1.U64, 4, 6, 7, 100] {
				limits = { ..Decoder.default_limits, max_line_length: line_limit, max_frame_length: frame_limit }
				var $split = 0.U64
				while $split <= wire.len() {
					first = wire.take_first($split)
					second = wire.drop_first($split)
					fast = Decoder.feed(Decoder.with_limits(limits), first)
					slow = scalar_feed(Decoder.with_limits(limits), first)
					$okay = $okay and Str.inspect(fast) == Str.inspect(slow)
					match (fast, slow) {
						(Progress({ decoder: fast_decoder, .. }), Progress({ decoder: slow_decoder, .. })) => {
							$okay = $okay and Str.inspect(Decoder.feed(fast_decoder, second)) == Str.inspect(scalar_feed(slow_decoder, second))
						}
						_ => {}
					}
					$split = $split + 1
				}
			}
		}
	}
	$okay
}

## A large advertised payload is rejected without receiving/allocating it.
expect match Decoder.feed(Decoder.init(), "$8388609\r\n".to_utf8()) {
	Failed({ completed: [], error: BulkLengthLimitExceeded({ actual: 8_388_609, at: 0, limit: 8_388_608 }) }) => True
	_ => False
}

## Opting into the larger policy accepts that header, but still needs payload.
expect match Decoder.feed(Decoder.with_limits(Decoder.redis_compatible_limits), "$8388609\r\n".to_utf8()) {
	Progress({ decoder, values: [] }) => Decoder.finish(decoder).is_err()
	_ => False
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
			ReadingLine(line) if !line.saw_carriage_return and (line.kind == SimpleLine or line.kind == ErrorLine) and $decoder.offset < $decoder.limits.max_frame_length and line.content.len() < $decoder.limits.max_line_length => {
				available = chunk.len() - $index
				frame_budget = $decoder.limits.max_frame_length - $decoder.offset
				line_budget = $decoder.limits.max_line_length - line.content.len()
				limit = available.min(frame_budget).min(line_budget)
				var $count = 0.U64
				while $count < limit {
					byte = get_or_zero(chunk, $index + $count)
					if byte == '\r' or byte == '\n' {
						break
					}
					$count = $count + 1
				}
				if $count > 0 {
					# Only received non-terminator bytes are copied. Leave delimiters
					# and limit errors to the scalar path so offsets stay identical.
					content = line.content.concat(chunk.sublist({ start: $index, len: $count }))
					$decoder = { ..$decoder, state: ReadingLine({ ..line, content }), offset: $decoder.offset + $count }
					$index = $index + $count
				} else {
					match step_byte($decoder, get_or_zero(chunk, $index)) {
						StepContinue(next_decoder) => {
							$decoder = next_decoder
						}
						StepEmitted({ decoder: next_decoder, value }) => {
							$decoder = next_decoder
							$completed = $completed.append(value)
						}
						StepFailed(error) => return Failed({ completed: $completed, error })
					}
					$index = $index + 1
				}
			}
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
				span = chunk.sublist({ start: $index, len: count })
				state = if count == bulk.remaining {
					WantBulkCarriageReturn({ content: buffer_finish(bulk.content, span), start: bulk.start })
				} else {
					ReadingBulk({ content: buffer_push(bulk.content, span), start: bulk.start, remaining: bulk.remaining - count })
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
		# Detach the old state before passing its payload separately. Keeping
		# both aliases here reproduces the pinned LLVM backend's miscompilation.
		state = decoder.state
		detached = with_state(decoder, AwaitType)
		match state {
			AwaitType => step_type(detached, byte)
			ReadingBulk(bulk) => step_bulk_data(detached, bulk, byte)
			ReadingLine(line) => step_line(detached, line, byte)
			WantBulkCarriageReturn(bulk) => step_bulk_carriage_return(detached, bulk, byte)
			WantBulkLineFeed(bulk) => step_bulk_line_feed(detached, bulk, byte)
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
						bulk = { content: empty_bulk_buffer, remaining: length, start: line.start }
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
	if bulk.remaining <= 1 {
		end = { content: buffer_finish(bulk.content, [byte]), start: bulk.start }
		StepContinue(advance_with_state(decoder, WantBulkCarriageReturn(end)))
	} else {
		updated = { content: buffer_push(bulk.content, [byte]), remaining: bulk.remaining - 1, start: bulk.start }
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

decode_one : List(U8) -> Try({ decoder : Decoder, value : Resp.Resp }, [Incomplete, Malformed(Decoder.DecodeError)])
decode_one = |bytes|
	match Decoder.feed(Decoder.init(), bytes) {
		Progress({ decoder, values: [value] }) => Ok({ decoder, value })
		Progress(_) => Err(Incomplete)
		Failed({ error, .. }) => Err(Malformed(error))
	}

## All seven semantic RESP2 reply variants decode from official wire forms.
expect decode_one(Str.to_utf8("+OK\r\n"))?.value == SimpleString(Str.to_utf8("OK"))

expect decode_one(Str.to_utf8("+\r\n"))?.value == SimpleString([])

expect decode_one(Str.to_utf8("-ERR wrong\r\n"))?.value == ErrorReply(Str.to_utf8("ERR wrong"))

expect decode_one(Str.to_utf8(":-42\r\n"))?.value == Integer(-42)

expect decode_one(Str.to_utf8(":01\r\n"))?.value == Integer(1)

expect decode_one(Str.to_utf8("$5\r\nhello\r\n"))?.value == BulkString(Str.to_utf8("hello"))

expect decode_one(Str.to_utf8("$01\r\nx\r\n"))?.value == BulkString(Str.to_utf8("x"))

expect decode_one(Str.to_utf8("$-1\r\n"))?.value == NullBulkString

expect decode_one(Str.to_utf8("*-1\r\n"))?.value == NullArray

expect decode_one(Str.to_utf8("*0\r\n"))?.value == Array([])

expect {
	decoded = decode_one(Str.to_utf8("*3\r\n:1\r\n$-1\r\n*2\r\n+OK\r\n$0\r\n\r\n"))?
	decoded.value == Array([Integer(1), NullBulkString, Array([SimpleString(Str.to_utf8("OK")), BulkString([])])])
}

## Bulk strings are length-delimited and preserve embedded CRLF and invalid UTF-8.
expect {
	wire = Str.to_utf8("$4\r\n").concat([0, 13, 10, 255, 13, 10])
	decode_one(wire)?.value == BulkString([0, 13, 10, 255])
}

## Multiple replies are emitted in order and a partial tail resumes without
## re-emitting already completed values.
expect {
	first = Decoder.feed(Decoder.init(), Str.to_utf8("+OK\r\n:2\r\n$5\r\nhe"))
	match first {
		Failed(_) => False
		Progress({ decoder, values }) =>
			if values != [SimpleString(Str.to_utf8("OK")), Integer(2)] or Decoder.buffered_len(decoder) != 6 {
				False
			} else {
				match Decoder.feed(decoder, Str.to_utf8("llo\r\n")) {
					Failed(_) => False
					Progress({ decoder: done, values: resumed }) => resumed == [BulkString(Str.to_utf8("hello"))] and Decoder.finish(done) == Ok({})
				}
			}
		}
}

## A nested frame can be split at every byte boundary without changing it.
expect {
	wire = Str.to_utf8("*2\r\n$4\r\nPONG\r\n:123\r\n")
	expected = Array([BulkString(Str.to_utf8("PONG")), Integer(123)])
	all_two_part_splits_work(wire, expected, 0)
}

## Both null encodings remain distinct at every possible read boundary.
expect {
	wire = "*2\r\n$-1\r\n*-1\r\n".to_utf8()
	all_two_part_splits_work(wire, Array([NullBulkString, NullArray]), 0)
}

## Span-based bulk copying preserves every possible byte, including framing
## characters. The larger fragmentation matrix runs in client_contract.roc.
expect {
	var $payload = List.with_capacity(256)
	var $byte = 0.U16
	while $byte < 256 {
		$payload = $payload.append($byte.to_u8_wrap())
		$byte = $byte + 1
	}
	wire = "$256\r\n".to_utf8().concat($payload).concat(['\r', '\n'])
	expected = BulkString($payload)
	decode_one(wire)?.value == expected
}

## Exhausting the frame budget inside a bulk span fails at the exact next byte.
expect {
	decoder = Decoder.with_limits(test_limits(10, 100, 10, 9, 10, 10))
	match Decoder.feed(decoder, "$10\r\nabcdefghij\r\n".to_utf8()) {
		Failed({ completed: [], error: FrameLengthLimitExceeded({ at: 9, limit: 9 }) }) => True
		_ => False
	}
}

all_two_part_splits_work : List(U8), Resp.Resp, U64 -> Bool
all_two_part_splits_work = |wire, expected, split|
	if split > wire.len() {
		True
	} else {
		first = wire.sublist({ start: 0, len: split })
		second = wire.sublist({ start: split, len: wire.len() - split })
		match Decoder.feed(Decoder.init(), first) {
			Failed(_) => False
			Progress({ decoder, values: first_values }) =>
				match Decoder.feed(decoder, second) {
					Failed(_) => False
					Progress({ decoder: final_decoder, values: second_values }) => {
						values = first_values.concat(second_values)
						values == [expected] and Decoder.finish(final_decoder) == Ok({}) and all_two_part_splits_work(wire, expected, split + 1)
					}
				}
			}
	}

## Feeding a frame one byte at a time has the same result as one-shot input.
expect {
	wire = Str.to_utf8("*2\r\n$4\r\nPONG\r\n:123\r\n")
	expected = Array([BulkString(Str.to_utf8("PONG")), Integer(123)])
	feed_single_bytes(Decoder.init(), wire, 0, []) == SingleByteDone([expected])
}

SingleByteResult : [SingleByteDone(List(Resp.Resp)), SingleByteFailed]

feed_single_bytes : Decoder, List(U8), U64, List(Resp.Resp) -> SingleByteResult
feed_single_bytes = |decoder, wire, index, values|
	if index >= wire.len() {
		if Decoder.finish(decoder) == Ok({}) {
			SingleByteDone(values)
		} else {
			SingleByteFailed
		}
	} else {
		chunk = wire.sublist({ start: index, len: 1 })
		match Decoder.feed(decoder, chunk) {
			Failed(_) => SingleByteFailed
			Progress({ decoder: next, values: emitted }) => feed_single_bytes(next, wire, index + 1, values.concat(emitted))
		}
	}

## Truncation reports which part of the frame is incomplete.
expect {
	match Decoder.feed(Decoder.init(), Str.to_utf8("$5\r\nhel")) {
		Failed(_) => False
		Progress({ decoder, values }) =>
			values.is_empty() and Decoder.finish(decoder) == Err(UnexpectedEnd({ at: 7, context: BulkData({ remaining: 2 }) }))
		}
}

expect {
	match Decoder.feed(Decoder.init(), Str.to_utf8("+OK\r")) {
		Progress({ decoder, values: [] }) => Decoder.finish(decoder) == Err(UnexpectedEnd({ at: 4, context: LineFeed }))
		_ => False
	}
}

expect {
	match Decoder.feed(Decoder.init(), Str.to_utf8("$0\r\n")) {
		Progress({ decoder, values: [] }) => Decoder.finish(decoder) == Err(UnexpectedEnd({ at: 4, context: BulkCarriageReturn }))
		_ => False
	}
}

expect {
	match Decoder.feed(Decoder.init(), Str.to_utf8("$0\r\n\r")) {
		Progress({ decoder, values: [] }) => Decoder.finish(decoder) == Err(UnexpectedEnd({ at: 5, context: BulkLineFeed }))
		_ => False
	}
}

expect {
	match Decoder.feed(Decoder.init(), Str.to_utf8("*2\r\n:1\r\n")) {
		Progress({ decoder, values: [] }) => Decoder.finish(decoder) == Err(UnexpectedEnd({ at: 8, context: ArrayItems({ remaining: 1 }) }))
		_ => False
	}
}

## Numeric grammar is strict RESP decimal, and the full I64 range is accepted.
expect decode_one(Str.to_utf8(":+1\r\n"))?.value == Integer(1)

expect decode_one(Str.to_utf8(":9223372036854775807\r\n"))?.value == Integer(9223372036854775807)

expect decode_one(Str.to_utf8(":-9223372036854775808\r\n"))?.value == Integer(-9223372036854775808)

expect invalid_integer(Str.to_utf8(":9223372036854775808\r\n"))

expect invalid_integer(Str.to_utf8(":-9223372036854775809\r\n"))

expect invalid_integer(Str.to_utf8(":0x10\r\n"))

expect invalid_integer(Str.to_utf8(":0b10\r\n"))

expect invalid_integer(Str.to_utf8(":0o10\r\n"))

expect invalid_integer(Str.to_utf8(":1_0\r\n"))

expect invalid_integer(Str.to_utf8(":+\r\n"))

invalid_integer : List(U8) -> Bool
invalid_integer = |wire|
	match Decoder.feed(Decoder.init(), wire) {
		Failed({ error: InvalidInteger(_), .. }) => True
		_ => False
	}

## Lengths are unsigned decimal, except for the exact legacy null token `-1`.
expect invalid_bulk_length(Str.to_utf8("$+1\r\n"))

expect invalid_bulk_length(Str.to_utf8("$-0\r\n"))

expect invalid_bulk_length(Str.to_utf8("$-01\r\n"))

expect invalid_bulk_length(Str.to_utf8("$-0x1\r\n"))

expect invalid_bulk_length(Str.to_utf8("$1_0\r\n"))

expect invalid_array_length(Str.to_utf8("*+1\r\n"))

expect invalid_array_length(Str.to_utf8("*-01\r\n"))

invalid_bulk_length : List(U8) -> Bool
invalid_bulk_length = |wire|
	match Decoder.feed(Decoder.init(), wire) {
		Failed({ error: InvalidBulkLength(_), .. }) => True
		_ => False
	}

invalid_array_length : List(U8) -> Bool
invalid_array_length = |wire|
	match Decoder.feed(Decoder.init(), wire) {
		Failed({ error: InvalidArrayLength(_), .. }) => True
		_ => False
	}

## The first invalid bulk terminator byte fails immediately, without waiting
## for another byte or end-of-stream.
expect {
	match Decoder.feed(Decoder.init(), Str.to_utf8("$2\r\nokX")) {
		Failed({ completed: [], error: ExpectedBulkTerminator({ actual: 88, at: 6, expected: 13 }) }) => True
		_ => False
	}
}

expect {
	match Decoder.feed(Decoder.init(), Str.to_utf8("+OK\rX")) {
		Failed({ completed: [], error: InvalidLineEnding({ at: 4 }) }) => True
		_ => False
	}
}

expect {
	match Decoder.feed(Decoder.init(), Str.to_utf8("$0\r\n\rX")) {
		Failed({ completed: [], error: ExpectedBulkTerminator({ actual: 88, at: 5, expected: 10 }) }) => True
		_ => False
	}
}

expect invalid_integer(Str.to_utf8(":\r\n"))

expect invalid_bulk_length(Str.to_utf8("$\r\n"))

expect invalid_array_length(Str.to_utf8("*\r\n"))

expect invalid_bulk_length(Str.to_utf8("$18446744073709551616\r\n"))

expect invalid_array_length(Str.to_utf8("*18446744073709551616\r\n"))

## Complete replies preceding a malformed frame are preserved.
expect {
	match Decoder.feed(Decoder.init(), Str.to_utf8("+OK\r\n?")) {
		Failed({ completed: [SimpleString(bytes)], error: UnknownType({ at: 0, byte: 63 }) }) => bytes == Str.to_utf8("OK")
		_ => False
	}
}

test_limits : U64, U64, U64, U64, U64, U64 -> Decoder.Limits
test_limits = |array, bulk, depth, frame, line, values| {
	max_array_length: array,
	max_bulk_length: bulk,
	max_depth: depth,
	max_frame_length: frame,
	max_line_length: line,
	max_values: values,
}

## Every resource limit accepts its exact boundary and rejects one beyond it.
expect {
	ok = Decoder.with_limits(test_limits(10, 10, 10, 100, 3, 10))
	too_short = Decoder.with_limits(test_limits(10, 10, 10, 100, 2, 10))
	decode_with(ok, Str.to_utf8("+abc\r\n")) == Decoded(SimpleString(Str.to_utf8("abc"))) and failed_line_limit(Decoder.feed(too_short, Str.to_utf8("+abc\r\n")))
}

expect {
	ok = Decoder.with_limits(test_limits(10, 2, 10, 100, 10, 10))
	too_short = Decoder.with_limits(test_limits(10, 1, 10, 100, 10, 10))
	decode_with(ok, Str.to_utf8("$2\r\nok\r\n")) == Decoded(BulkString(Str.to_utf8("ok"))) and failed_bulk_limit(Decoder.feed(too_short, Str.to_utf8("$2\r\nok\r\n")))
}

expect {
	ok = Decoder.with_limits(test_limits(1, 10, 10, 100, 10, 10))
	too_short = Decoder.with_limits(test_limits(0, 10, 10, 100, 10, 10))
	decode_with(ok, Str.to_utf8("*1\r\n:1\r\n")) == Decoded(Array([Integer(1)])) and failed_array_limit(Decoder.feed(too_short, Str.to_utf8("*1\r\n:1\r\n")))
}

expect {
	ok = Decoder.with_limits(test_limits(10, 10, 2, 100, 10, 10))
	too_shallow = Decoder.with_limits(test_limits(10, 10, 1, 100, 10, 10))
	wire = Str.to_utf8("*1\r\n*0\r\n")
	decode_with(ok, wire) == Decoded(Array([Array([])])) and failed_depth_limit(Decoder.feed(too_shallow, wire))
}

expect {
	zero_depth = Decoder.with_limits(test_limits(10, 10, 0, 100, 10, 10))
	failed_depth_limit(Decoder.feed(zero_depth, Str.to_utf8("*0\r\n")))
}

expect {
	one_level = Decoder.with_limits(test_limits(10, 10, 1, 100, 10, 10))
	failed_depth_limit(Decoder.feed(one_level, Str.to_utf8("*1\r\n*-1\r\n")))
}

expect {
	one_value = Decoder.with_limits(test_limits(10, 10, 10, 100, 10, 1))
	two_values = Decoder.with_limits(test_limits(10, 10, 10, 100, 10, 2))
	wire = Str.to_utf8("*1\r\n:1\r\n")
	failed_value_limit(Decoder.feed(one_value, wire)) and decode_with(two_values, wire) == Decoded(Array([Integer(1)]))
}

expect {
	per_frame = Decoder.with_limits(test_limits(10, 10, 10, 100, 10, 1))
	match Decoder.feed(per_frame, Str.to_utf8(":1\r\n:2\r\n")) {
		Progress({ decoder, values }) => values == [Integer(1), Integer(2)] and Decoder.finish(decoder) == Ok({})
		_ => False
	}
}

## Frame-byte limits are independent of chunking. The example frame is 8 bytes.
expect {
	wire = Str.to_utf8("$2\r\nok\r\n")
	whole_ok = Decoder.with_limits(test_limits(10, 10, 10, 8, 10, 10))
	split_ok = Decoder.with_limits(test_limits(10, 10, 10, 8, 10, 10))
	whole_small = Decoder.with_limits(test_limits(10, 10, 10, 7, 10, 10))
	split_small = Decoder.with_limits(test_limits(10, 10, 10, 7, 10, 10))
	decode_with(whole_ok, wire) == Decoded(BulkString(Str.to_utf8("ok"))) and feed_in_two(split_ok, wire, 4) == Decoded(BulkString(Str.to_utf8("ok"))) and failed_frame_limit(Decoder.feed(whole_small, wire)) and feed_in_two(split_small, wire, 4) == LimitedFrame
}

## Malformed and resource-limited frames fail identically at every possible
## two-chunk split, including empty chunks at either edge.
expect {
	wire = Str.to_utf8("$2\r\nokX")
	expected = ExpectedBulkTerminator({ actual: 88, at: 6, expected: 13 })
	all_splits_fail_with(wire, Decoder.default_limits, expected, 0)
}

expect {
	wire = Str.to_utf8(":1_0\r\n")
	expected = InvalidInteger({ at: 2, header: Str.to_utf8("1_0") })
	all_splits_fail_with(wire, Decoder.default_limits, expected, 0)
}

expect {
	limits = test_limits(10, 10, 10, 7, 10, 10)
	wire = Str.to_utf8("$2\r\nok\r\n")
	expected = FrameLengthLimitExceeded({ at: 7, limit: 7 })
	all_splits_fail_with(wire, limits, expected, 0)
}

expect {
	limits = test_limits(10, 10, 10, 100, 10, 1)
	wire = Str.to_utf8("*1\r\n:1\r\n")
	expected = ValueLimitExceeded({ at: 0, limit: 1 })
	all_splits_fail_with(wire, limits, expected, 0)
}

expect {
	limits = test_limits(10, 10, 10, 5, 10, 10)
	match Decoder.feed(limits |> Decoder.with_limits, Str.to_utf8("+OK\r\n+LONG\r\n")) {
		Failed({ completed: [SimpleString(ok)], error: FrameLengthLimitExceeded({ at: 5, limit: 5 }) }) => ok == Str.to_utf8("OK")
		_ => False
	}
}

all_splits_fail_with : List(U8), Decoder.Limits, Decoder.DecodeError, U64 -> Bool
all_splits_fail_with = |wire, limits, expected, split|
	if split > wire.len() {
		True
	} else {
		first = wire.sublist({ start: 0, len: split })
		second = wire.sublist({ start: split, len: wire.len() - split })
		first_result = Decoder.feed(Decoder.with_limits(limits), first)
		this_split_matches =
			match first_result {
				Failed({ completed: [], error }) => error == expected
				Failed(_) => False
				Progress({ decoder, values: [] }) =>
					match Decoder.feed(decoder, second) {
						Failed({ completed: [], error }) => error == expected
						_ => False
					}
				Progress(_) => False
			}
		this_split_matches and all_splits_fail_with(wire, limits, expected, split + 1)
	}

DecodeWithResult : [Decoded(Resp.Resp), DecodeWithFailed]

decode_with : Decoder, List(U8) -> DecodeWithResult
decode_with = |decoder, wire|
	match Decoder.feed(decoder, wire) {
		Progress({ decoder: done, values: [value] }) =>
			if Decoder.finish(done) == Ok({}) {
				Decoded(value)
			} else {
				DecodeWithFailed
			}
		_ => DecodeWithFailed
	}

TwoFeedResult : [Decoded(Resp.Resp), LimitedFrame, TwoFeedFailed]

feed_in_two : Decoder, List(U8), U64 -> TwoFeedResult
feed_in_two = |decoder, wire, split| {
	first = wire.sublist({ start: 0, len: split })
	second = wire.sublist({ start: split, len: wire.len() - split })
	match Decoder.feed(decoder, first) {
		Failed({ error: FrameLengthLimitExceeded(_), .. }) => LimitedFrame
		Failed(_) => TwoFeedFailed
		Progress({ decoder: next, values: first_values }) =>
			match Decoder.feed(next, second) {
				Failed({ error: FrameLengthLimitExceeded(_), .. }) => LimitedFrame
				Failed(_) => TwoFeedFailed
				Progress({ decoder: done, values: second_values }) =>
					match first_values.concat(second_values) {
						[value] => if Decoder.finish(done) == Ok({}) {
							Decoded(value)
						} else {
							TwoFeedFailed
						}
						_ => TwoFeedFailed
					}
				}
		}
}

failed_line_limit : Decoder.FeedResult -> Bool
failed_line_limit = |result|
	match result {
		Failed({ error: LineLengthLimitExceeded(_), .. }) => True
		_ => False
	}

failed_bulk_limit : Decoder.FeedResult -> Bool
failed_bulk_limit = |result|
	match result {
		Failed({ error: BulkLengthLimitExceeded(_), .. }) => True
		_ => False
	}

failed_array_limit : Decoder.FeedResult -> Bool
failed_array_limit = |result|
	match result {
		Failed({ error: ArrayLengthLimitExceeded(_), .. }) => True
		_ => False
	}

failed_depth_limit : Decoder.FeedResult -> Bool
failed_depth_limit = |result|
	match result {
		Failed({ error: NestingLimitExceeded(_), .. }) => True
		_ => False
	}

failed_value_limit : Decoder.FeedResult -> Bool
failed_value_limit = |result|
	match result {
		Failed({ error: ValueLimitExceeded(_), .. }) => True
		_ => False
	}

failed_frame_limit : Decoder.FeedResult -> Bool
failed_frame_limit = |result|
	match result {
		Failed({ error: FrameLengthLimitExceeded(_), .. }) => True
		_ => False
	}
