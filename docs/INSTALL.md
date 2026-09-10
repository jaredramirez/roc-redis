# Trying 0.1.0-rc2

Use the release's exact content-addressed archive URL with Roc
`nightly-2026-09-07-14d9829`. The dev backend is recommended.

For now, use the checkout's runnable examples:

```console
nix develop
roc --opt=dev examples/composition.roc
```

That example needs no Redis service. The [CLI and webserver connectors](../examples/README.md)
also show the complete app declaration, pinned platform, config, and transport.

This complete application needs no Redis server. Save it as `main.roc` and run
`roc --opt=dev main.roc`; it prints the GET command's parts:

```roc
app [main!] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "https://github.com/jaredramirez/roc-redis/releases/download/0.1.0-rc2/xob6JGzB3sHAE31nHg8acAASiRJtWecX5j43fuweP7J.tar.zst",
}

import pf.Stdout
import redis.Commands
import redis.Command

main! = |_args| {
    request = Commands.Strings.get("example")
    Stdout.line!(Str.inspect(Command.to_parts(request.command())))?
    Ok({})
}
```

Use the exact compiler from `.roc-version`, not an arbitrary newer nightly.
This package is licensed under [Apache 2.0](../LICENSE); preserve the license
and applicable notices when redistributing it.
For a complete TCP read/modify/write application, copy the [README example](../README.md).
For local development in a sibling directory, replace the Redis URL with
`../roc-redis/package/main.roc`.

The release URL deliberately includes a fixed tag and filename, not a mutable
`latest` redirect. Upgrade both together when choosing a newer release.
Publication validation is recorded in [the release checklist](PREVIEW-CHECKLIST.md).
