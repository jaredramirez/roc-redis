## Minimal reproduction for a checker hang while deriving a JSON parser for a
## recursive nominal record.
RecursiveNominalJsonParser :: [].{}

Node := {
	children : List(Node),
}.{
	parser_for : _
}

parse_node : Str -> Try(Node, [InvalidJson(Str), MissingRequiredField(Str)])
parse_node = |source| Json.parse(source)

expect parse_node("{\"children\":[]}").is_ok()
