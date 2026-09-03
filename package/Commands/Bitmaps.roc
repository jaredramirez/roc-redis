import /Bytes
import /Command
import /Commands/Decode
import /NonEmpty
import /Reply
import /Request
import /Resp

Bitmaps :: [].{
	Unit : [Byte, Bit]
	CountRange : [All, Range({ start : I64, end : I64, unit : Unit })]
	PositionRange : [All, From(I64), Range({ start : I64, end : I64, unit : Unit })]
	Operation : [Not(Bytes.Bytes), And(NonEmpty.NonEmpty(Bytes.Bytes)), Or(NonEmpty.NonEmpty(Bytes.Bytes)), Xor(NonEmpty.NonEmpty(Bytes.Bytes)), Diff(NonEmpty.NonEmpty(Bytes.Bytes)), Diff1(NonEmpty.NonEmpty(Bytes.Bytes)), AndOr(NonEmpty.NonEmpty(Bytes.Bytes)), One(NonEmpty.NonEmpty(Bytes.Bytes))]

	## Redis checks widths (signed 1..64, unsigned 1..63), offsets, and numeric
	## range. No floating-point conversion is applied to bitfield values.
	Encoding : [Signed(U8), Unsigned(U8)]
	Offset : [Bits(U64), Elements(U64)]
	Field : { encoding : Encoding, offset : Offset }
	FieldOperation : [Get(Field), Set({ field : Field, value : I64 }), Increment({ field : Field, value : I64 }), Overflow([Wrap, Saturate, Fail])]

	get_bit : Bytes.Bytes, U64 -> Request.Request(Bool, Reply.Error)
	get_bit = |key, offset| Request.new(Command.new("GETBIT", [key, decimal(offset)]), Reply.integer_boolean)

	set_bit : Bytes.Bytes, U64, Bool -> Request.Request(Bool, Reply.Error)
	set_bit = |key, offset, value| Request.new(Command.new("SETBIT", [key, decimal(offset), bit(value)]), Reply.integer_boolean)

	bit_count : Bytes.Bytes, CountRange -> Request.Request(I64, Reply.Error)
	bit_count = |key, range| Request.new(
		Command.new(
			"BITCOUNT",
			[key].concat(
				match range {
					All => []
					Range(bounds) => [signed(bounds.start), signed(bounds.end), unit(bounds.unit)]
				},
			),
		),
		Reply.integer,
	)

	bit_pos : Bytes.Bytes, Bool, PositionRange -> Request.Request(I64, Reply.Error)
	bit_pos = |key, value, range| Request.new(
		Command.new(
			"BITPOS",
			[key, bit(value)].concat(
				match range {
					All => []
					From(start) => [signed(start)]
					Range(bounds) => [signed(bounds.start), signed(bounds.end), unit(bounds.unit)]
				},
			),
		),
		Reply.integer,
	)

	bit_op : Bytes.Bytes, Operation -> Request.Request(I64, Reply.Error)
	bit_op = |destination, operation| {
		selected = match operation {
			Not(key) => { name: Bytes.from_str("NOT"), keys: [key] }
			And(keys) => { name: Bytes.from_str("AND"), keys: keys.to_list() }
			Or(keys) => { name: Bytes.from_str("OR"), keys: keys.to_list() }
			Xor(keys) => { name: Bytes.from_str("XOR"), keys: keys.to_list() }
			Diff(keys) => { name: Bytes.from_str("DIFF"), keys: keys.to_list() }
			Diff1(keys) => { name: Bytes.from_str("DIFF1"), keys: keys.to_list() }
			AndOr(keys) => { name: Bytes.from_str("ANDOR"), keys: keys.to_list() }
			One(keys) => { name: Bytes.from_str("ONE"), keys: keys.to_list() }
		}
		Request.new(Command.new("BITOP", [selected.name, destination].concat(selected.keys)), Reply.integer)
	}

	bit_field : Bytes.Bytes, List(FieldOperation) -> Request.Request(List(Reply.Optional(I64)), Reply.Error)
	bit_field = |key, operations| {
		var $count = 0.U64
		var $arguments = [key]
		for operation in operations {
			match operation {
				Overflow(mode) => {
					$arguments = $arguments.concat([
						"OVERFLOW",
						match mode {
							Wrap => Bytes.from_str("WRAP")
							Saturate => Bytes.from_str("SAT")
							Fail => Bytes.from_str("FAIL")
						},
					])
				}
				Get(field) => {
					$arguments = $arguments.concat(["GET"].concat(field_args(field)))
					$count = $count + 1
				}
				Set(settings) => {
					$arguments = $arguments.concat(["SET"].concat(field_args(settings.field)).append(signed(settings.value)))
					$count = $count + 1
				}
				Increment(settings) => {
					$arguments = $arguments.concat(["INCRBY"].concat(field_args(settings.field)).append(signed(settings.value)))
					$count = $count + 1
				}
			}
		}
		count = $count
		Request.new(
			Command.new("BITFIELD", $arguments),
			|reply| Decode.counted(
				reply,
				count,
				|value| match value {
					NullBulkString => Ok(Absent)
					_ => Reply.integer(value).map_ok(|number| Present(number))
				},
			),
		)
	}

	## Read-only construction has no SET/INCRBY/OVERFLOW alternatives.
	bit_field_ro : Bytes.Bytes, List(Field) -> Request.Request(List(I64), Reply.Error)
	bit_field_ro = |key, fields| Request.new(Command.new("BITFIELD_RO", [key].concat(fields.join_map(|field| [Bytes.from_str("GET")].concat(field_args(field))))), |reply| Decode.counted(reply, fields.len(), Reply.integer))
}

decimal : U64 -> Bytes.Bytes
decimal = |value| Bytes.from_str(value.to_str())

signed : I64 -> Bytes.Bytes
signed = |value| Bytes.from_str(value.to_str())

bit : Bool -> Bytes.Bytes
bit = |value| if value {
	"1"
} else {
	"0"
}

unit : Bitmaps.Unit -> Bytes.Bytes
unit = |value| match value {
	Bit => "BIT"
	Byte => "BYTE"
}

field_args : Bitmaps.Field -> List(Bytes.Bytes)
field_args = |field| [
	match field.encoding {
		Signed(width) => Bytes.from_str("i${width.to_str()}")
		Unsigned(width) => Bytes.from_str("u${width.to_str()}")
	},
	match field.offset {
		Bits(value) => decimal(value)
		Elements(value) => Bytes.from_str("#${value.to_str()}")
	},
]

expect Bitmaps.bit_op("destination", Not("source")).command() == Command.new("BITOP", ["NOT", "destination", "source"])
expect Bitmaps.bit_count("key", Range({ start: -2, end: -1, unit: Bit })).command() == Command.new("BITCOUNT", ["key", "-2", "-1", "BIT"])
expect Bitmaps.get_bit("key", 0).decode(Resp.Integer(2)).is_err()
expect {
	field : Bitmaps.Field
	field = { encoding: Signed(8), offset: Elements(2) }
	request = Bitmaps.bit_field("key", [Overflow(Fail), Increment({ field, value: 1 })])
	request.command() == Command.new("BITFIELD", ["key", "OVERFLOW", "FAIL", "INCRBY", "i8", "#2", "1"])
		and request.decode(Resp.Array([Resp.NullBulkString])) == Ok([Absent])
			and request.decode(Resp.Array([])).is_err()
}
