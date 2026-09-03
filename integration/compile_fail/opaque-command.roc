app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "../../package/main.roc",
}

import redis.Command

command = Command.{ parts: [] }

main! = |_args| {
	_ = command.to_parts()
	Ok({})
}
