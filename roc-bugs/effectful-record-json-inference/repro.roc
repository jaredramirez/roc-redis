app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.22.2/9zUBxb1LtXYVc4eR4hAtd1WQDwBYDhM6HQdZz1UFCm2m.tar.zst",
}
import pf.Stdout

Transport : { read! : U64 => Try(List(U8), [TraceFailed(Str)]) }

Event : { label : Str, requested : U64 }

make : Str -> Transport
make = |label| {
	read!: |requested| {
		event = { label, requested }
		Stdout.line!(Json.to_str(event)) ? |_| TraceFailed("trace output failed")
		Ok([0])
	},
}

main! = |_args| Ok({})
