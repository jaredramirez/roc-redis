## Binary-safe bytes. Quoted literals are UTF-8; arbitrary byte lists need no
## validation. Converting bytes back to text explicitly checks UTF-8.
Bytes :: { bytes : List(U8) }.{
	is_eq : _

	from_list : List(U8) -> Bytes
	from_list = |bytes| Bytes.{ bytes }

	from_str : Str -> Bytes
	from_str = |text| Bytes.{ bytes: text.to_utf8() }

	from_quote : Str -> Try(Bytes, [BadQuotedBytes(Str), ..])
	from_quote = |text| Ok(Bytes.from_str(text))

	to_list : Bytes -> List(U8)
	to_list = |value| value.bytes

	to_utf8 : Bytes -> Try(Str, [InvalidUtf8])
	to_utf8 = |value| Str.from_utf8(value.bytes).map_err(|_| InvalidUtf8)

	len : Bytes -> U64
	len = |value| value.bytes.len()

	is_empty : Bytes -> Bool
	is_empty = |value| value.bytes.is_empty()
}

literal : Bytes
literal = "café"

expect literal.to_list() == "café".to_utf8()

expect literal.len() == 5

expect Bytes.from_list([0, 255, '\r', '\n']).to_list() == [0, 255, '\r', '\n']

expect Bytes.from_list([255]).to_utf8() == Err(InvalidUtf8)

expect Bytes.from_list([]).to_utf8() == Ok("")
