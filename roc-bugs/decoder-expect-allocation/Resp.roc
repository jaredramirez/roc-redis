## A semantic RESP2 value.
##
## String-like values contain bytes rather than `Str`, because Redis replies
## may contain arbitrary binary data. NullBulkString (`$-1`) and NullArray
## (`*-1`) remain distinct. An `ErrorReply` is a valid server response, not
## a protocol decoding failure.
Resp := [
	Array(List(Resp)),
	BulkString(List(U8)),
	ErrorReply(List(U8)),
	Integer(I64),
	NullBulkString,
	NullArray,
	SimpleString(List(U8)),
].{
	is_eq : _

	## Construct a bulk string from UTF-8 text.
	bulk_utf8 : Str -> Resp
	bulk_utf8 = |text| BulkString(Str.to_utf8(text))

	## Construct a simple string from UTF-8 text.
	simple_utf8 : Str -> Resp
	simple_utf8 = |text| SimpleString(Str.to_utf8(text))

	## Construct an error reply from UTF-8 text.
	error_utf8 : Str -> Resp
	error_utf8 = |text| ErrorReply(Str.to_utf8(text))
}

## UTF-8 helpers preserve the same bytes as direct construction.
expect Resp.bulk_utf8("hello") == BulkString([104, 101, 108, 108, 111])
