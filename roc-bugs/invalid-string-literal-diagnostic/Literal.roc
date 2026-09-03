Literal :: { text : Str }.{
	from_quote : Str -> Try(Literal, [BadQuotedBytes(Str), ..])
	from_quote = |_| Err(BadQuotedBytes("string literal intentionally rejected"))
}

value : Literal
value = "text"
