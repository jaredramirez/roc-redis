positive : U64 -> Try(U64, [Zero])
positive = |number| if number == 0 {
	Err(Zero)
} else {
	Ok(number)
}

number : U64
number = {
	Ok(value) = positive(1)
	value
}

expect number == 1
