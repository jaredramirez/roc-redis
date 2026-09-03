import /Types

Case :: [].{
	is_ok : Types.Types -> Bool
	is_ok = |value| match value {
		Types.Okay => True
		Types.Missing => False
	}
}

expect Case.is_ok(Types.Okay)
