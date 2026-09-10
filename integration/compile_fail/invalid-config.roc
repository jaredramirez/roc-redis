app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "../../package/main.roc",
}

import redis.Config

config = Config.default |> Config.with_read_size(0) |> Config.build

main! = |_args| {
	_ = config.read_size()
	Ok({})
}
