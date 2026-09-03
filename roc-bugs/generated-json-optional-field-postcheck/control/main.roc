app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.22.2/9zUBxb1LtXYVc4eR4hAtd1WQDwBYDhM6HQdZz1UFCm2m.tar.zst",
}

import pf.Env
import pf.OsStr
import pf.Stdout

RawArgument : { name : Str }

RawDoc : { arguments ?: List(RawArgument) }

main! = |_| {
	source = Env.var_str!(OsStr.from_str("ROC_JSON_CONTROL")) ?? "{\"arguments\":[]}"
	parsed : Try(RawDoc, _)
	parsed = Json.parse(source)
	match parsed {
		Ok(value) => {
			arguments = value.?arguments ?? []
			Stdout.line!(Str.join_with(arguments.map(|argument| argument.name), ","))
		}
		Err(error) => Stdout.line!(Str.inspect(error))
	}
}
