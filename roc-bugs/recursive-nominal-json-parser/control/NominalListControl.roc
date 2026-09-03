## Control: replacing the recursive List element with Str makes the same
## nominal record/list JSON parser derivation terminate.
NominalListControl :: [].{}

FlatNode := {
	children : List(Str),
}.{
	parser_for : _
	is_eq : _
}

parse_node : Str -> Try(FlatNode, [InvalidJson(Str), MissingRequiredField(Str)])
parse_node = |source| Json.parse(source)

expect parse_node("{\"children\":[]}") == Ok(FlatNode.{ children: [] })
