import /Types

Control :: [].{
	is_ok : Types.Types -> Bool
	is_ok = |value| match value {
		Okay => True
		Missing => False
	}
}

expect Control.is_ok(Types.Okay)

expect !Control.is_ok(Types.Missing)
