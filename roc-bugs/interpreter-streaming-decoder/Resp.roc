Resp := [
	Array(List(Resp)),
	BulkString(List(U8)),
	ErrorReply(List(U8)),
	Integer(I64),
	Null,
	SimpleString(List(U8)),
].{
	is_eq : _
}
