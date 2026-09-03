import Bytes

## A byte sequence containing at least one byte, such as a command name.
NonEmptyBytes :: { bytes : Bytes.Bytes }.{
	is_eq : _

	from_bytes : Bytes.Bytes -> Try(NonEmptyBytes, [EmptyBytes])
	from_bytes = |bytes|
		if bytes.is_empty() {
			Err(EmptyBytes)
		} else {
			Ok(NonEmptyBytes.{ bytes })
		}

	from_quote : Str -> Try(NonEmptyBytes, [BadQuotedBytes(Str), ..])
	from_quote = |text|
		NonEmptyBytes.from_bytes(Bytes.from_str(text)).map_err(|_| BadQuotedBytes("expected non-empty bytes"))

	to_bytes : NonEmptyBytes -> Bytes.Bytes
	to_bytes = |value| value.bytes
}

name : NonEmptyBytes
name = "PING"

expect name.to_bytes().to_list() == ['P', 'I', 'N', 'G']

expect NonEmptyBytes.from_bytes(Bytes.from_list([])) == Err(EmptyBytes)

expect NonEmptyBytes.from_bytes(Bytes.from_list([0])).is_ok()
