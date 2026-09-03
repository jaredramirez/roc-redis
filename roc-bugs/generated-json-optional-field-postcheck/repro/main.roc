app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.22.2/9zUBxb1LtXYVc4eR4hAtd1WQDwBYDhM6HQdZz1UFCm2m.tar.zst",
}

import pf.Env
import pf.OsStr
import pf.Stdout

RawArgument : { name : Str }

RawDoc : { arguments ?: List(RawArgument) }

main! = |_| {
	# Read at runtime so constant evaluation cannot remove the generated parser.
	source = Env.var_str!(OsStr.from_str("ROC_JSON_REPRO")) ?? "{\"item\":{\"arguments\":[]}}"
	parsed : Try(Dict(Str, RawDoc), _)
	parsed = Json.parse(source)
	match parsed {
		Ok(value) => Stdout.line!(value.len().to_str())
		Err(error) => Stdout.line!(Str.inspect(error))
	}
}
