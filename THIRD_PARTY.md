# Third-party provenance

This notice records provenance; it does not replace an upstream license or
grant rights to upstream material.

## Redis command contract

`metadata/redis-8.10.1-command-catalog.json` records a normalized public contract
from an unmodified Redis 8.10.1 server using `COMMAND LIST`, `COMMAND DOCS`, and
`COMMAND INFO`. Its provenance is recorded in the file itself. It includes
command/argument names, flags, grouping, arity, and version facts. Redis internal
command JSON/source files are not vendored. The generator explicitly rejects a
manifest containing the `summary` field; copied Redis summary prose is excluded.

Generated Roc constructors are rendered by this project's generator. Their
documentation links to the corresponding upstream command documentation.
Redis and its contributors are credited as the source of the public command
contract; this project is not an official Redis client or an endorsed product.

References, checked September 8, 2026:

- [COMMAND DOCS](https://redis.io/docs/latest/commands/command-docs/)
- [Redis 8.10.1 upstream license](https://github.com/redis/redis/blob/8.10.1/LICENSE.txt)
- [Redis licensing overview](https://redis.io/legal/licenses/)

Redis 8 server software has RSALv2, SSPLv1, and AGPLv3 license options. That is
not a statement that this independent network client uses any of those licenses,
nor a legal determination about database rights or all metadata uses. Do not
copy upstream implementation or documentation into the project without checking
the applicable terms. Obtain qualified advice if broader redistribution changes
the current scope.

## External tools, platforms, and benchmark clients

Roc, basic-cli, basic-webserver, roc-http, roc-fuzz, Redis, redis-py, go-redis,
redis-rs, hiredis, and Nix dependencies are separately obtained upstream projects.
Pinned archives/versions are recorded in `nix/toolchain.nix`, the Roc application
headers, language lockfiles, and `flake.lock`. They are not vendored into the
platform-independent `package/` source tree. Retain their own notices when
redistributing their code or binaries; the project's license does not replace
those terms.
