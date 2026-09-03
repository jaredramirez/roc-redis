positive : U64 -> Try(U64, [Zero])
positive = |number| if number == 0 {
	Err(Zero)
} else {
	Ok(number)
}

expect {
	Ok(number) = positive(1)
	number == 1
}
