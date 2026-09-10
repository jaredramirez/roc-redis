app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "../../package/main.roc",
}

import redis.Client
import redis.Config

# Database 0 is the default, expressed by leaving the database unset. A positive
# index excludes 0, so selecting database 0 must fail to compile.
client = Config.default |> Config.build |> Client.new |> Client.with_db(0)

main! = |_args| {
	_ = client
	Ok({})
}
