Accepted :: { text : Str }.{
	is_eq : _
	from_quote : Str -> Try(Accepted, [BadQuotedBytes(Str), ..])
	from_quote = |text| Ok(Accepted.{ text })
}

value : Accepted
value = "text"

expect value == value
