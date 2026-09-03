# Dict-of-nested-record JSON codec postcheck panic

Roc compiler: `nightly-2026-09-04-c125b82`

The repro derives a JSON parser for `Dict(Str, RawDoc)`, where `RawDoc` has a
single optional `List(RawArgument)` field and `RawArgument` is a one-field
record. It observes only the decoded dictionary's length. The control parses a
`RawDoc` directly and consumes the nested leaf field. Both sources are read
from the environment so constant evaluation cannot remove their parsers.

From the repository root, with the basic-cli archive available in Roc's cache:

```sh
timeout 120 roc build --opt=dev --no-cache \
  --output=/tmp/roc-json-postcheck-control \
  roc-bugs/generated-json-optional-field-postcheck/control/main.roc

timeout 120 roc build --opt=dev --no-cache \
  --output=/tmp/roc-json-postcheck-repro \
  roc-bugs/generated-json-optional-field-postcheck/repro/main.roc
```

Expected: both applications build successfully.

Actual: the direct, fully consumed `RawDoc` control builds, while the
`Dict(Str, RawDoc)` repro panics during postcheck:

```text
postcheck invariant violated: checked generated codec contract was missing required method call parse_record_field (subject: present)
```

Discarding part of a decoded value may permit optimization, but it must not
leave the compiler's generated codec contract in an invalid state.

This was found in the Redis command-catalog tool while decoding the object
returned by `COMMAND DOCS`. Its production workaround requests one documented
command at a time, removes the exactly known outer object field, derives a
parser for `RawDoc` directly, and immediately converts every nested field into
the catalog's domain type. That preserves typed JSON validation without using
the crashing generated-codec path.

`scripts/check-known-bug.roc` builds the control and repro to randomized
temporary outputs, removes those artifacts, and requires both exit status 134
and the exact postcheck invariant text from the failing build.
