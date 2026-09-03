## A list with at least one element. Used for required Redis variadic operands.
NonEmpty(item) :: { first : item, rest : List(item) }.{
	new : item, List(item) -> NonEmpty(item)
	new = |first, rest| NonEmpty.{ first, rest }

	from_list : List(item) -> Try(NonEmpty(item), [EmptyList])
	from_list = |items| match items {
		[] => Err(EmptyList)
		[first, .. as rest] => Ok(NonEmpty.{ first, rest })
	}

	to_list : NonEmpty(item) -> List(item)
	to_list = |items| [items.first].concat(items.rest)

	len : NonEmpty(item) -> U64
	len = |items| 1 + items.rest.len()
}

expect NonEmpty.from_list([]).is_err()

expect NonEmpty.new(1, [2, 3]).to_list() == [1, 2, 3]
