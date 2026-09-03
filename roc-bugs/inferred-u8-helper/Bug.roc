Bug := [].{}

get_or_zero = |bytes, index|
	match bytes.get(index) {
		Ok(byte) => byte
		Err(_) => 0
	}

is_pair = |bytes, index|
	get_or_zero(bytes, index) == 13 and get_or_zero(bytes, index + 1) == 10

is_pair_typed : List(U8), U64 -> Bool
is_pair_typed = |bytes, index|
	get_or_zero(bytes, index) == 13 and get_or_zero(bytes, index + 1) == 10

## This failed on nightly-2026-09-03-62fcb65 even though `bytes` contains
## exactly 13 followed by 10. It is retained as a regression expectation.
expect {
	bytes : List(U8)
	bytes = [13, 10]
	is_pair(bytes, 0)
}

## The explicitly annotated form passed both before and after the fix.
expect {
	bytes : List(U8)
	bytes = [13, 10]
	is_pair_typed(bytes, 0)
}
