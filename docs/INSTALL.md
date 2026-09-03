# Trying the preview

A public preview URL has not yet been published or verified. Do not treat a
placeholder or the package's local bundle test as an available release.

For now, use the checkout's runnable examples:

```console
nix develop
roc --opt=dev examples/composition.roc
```

That example needs no Redis service. The [CLI and webserver connectors](../examples/README.md)
also show the complete app declaration, pinned platform, config, and transport.

For a sibling application next to a checkout named `roc-redis`, the dependency
declaration is:

```roc
app [main!] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
    redis: "../roc-redis/package/main.roc",
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
Once the preview is published, replace the local `redis` path with the actual
content-addressed archive URL from the release and verify that URL using the
fresh-consumer procedure in [the release checklist](PREVIEW-CHECKLIST.md).
