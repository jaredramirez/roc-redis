# API design and implementation status

The reviewed API is implemented. Preserve the current public modules during
readability work; no renaming or migration is part of this pass.

## Current design

- Raw command families construct Command values; Commands families construct
  typed Request values or explicitly encoding-only plans.
- Request combines one command and a custom semantic decoder.
- Batch combines commands into one exchange, retaining per-element Try values
  when requested. No transaction atomicity is implied.
- Execute.request!, Execute.batch!, and Execute.no_reply! expose only their
  relevant capabilities and error families.
- Config uses a pure builder and one final build. Prefer a module-level
  Ok(config) destructure for constant settings.
- Bytes and NonEmptyBytes accept literals; binary payloads need no UTF-8
  validation. Reply.utf8 is explicit when text is wanted.
- Platforms own connections and effects. Pooling, retries, and connection-state
  protocols are not silently added to the ordinary request boundary.

See the [module map](docs/modules.md), [README](README.md), and
[current quality notes](QUALITY-REVIEW.md).

## Decisions and history

The [full accepted review and implementation sequence](docs/history/api-plan.md)
retains every original decision, completion report, and benchmark candidate.
The [simplification checklist](SIMPLIFICATION-PLAN.md) tracks the current pass.
