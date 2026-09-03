Inner :: [].{
	Options := { enabled : Bool ?? False }
	new : Options -> Bool
	new = |options| options.enabled
}
