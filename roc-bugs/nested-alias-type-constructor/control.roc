app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.22.2/9zUBxb1LtXYVc4eR4hAtd1WQDwBYDhM6HQdZz1UFCm2m.tar.zst",
	nested: "main.roc",
}

import nested.Outer

main! = |_| Ok({})

expect Outer.Inner.new({ enabled: True }) == True
