## A positive U64, used for Redis expirations and strictly positive counts.
## Numeric literals are validated at compile time; runtime values use from_u64.
Positive :: { value : U64 }.{
	is_eq : _

	from_u64 : U64 -> Try(Positive, [Zero])
	from_u64 = |value| if value == 0 {
		Err(Zero)
	} else {
		Ok(Positive.{ value: value })
	}

	from_numeral : Numeral -> Try(Positive, [InvalidNumeral(Str), ..])
	from_numeral = |numeral| {
		value = U64.from_numeral(numeral)?
		Positive.from_u64(value).map_err(|_| InvalidNumeral("expected a positive integer"))
	}

	to_u64 : Positive -> U64
	to_u64 = |positive| positive.value
}

timeout : Positive
timeout = 60_000

expect timeout.to_u64() == 60_000

expect Positive.from_u64(0) == Err(Zero)
