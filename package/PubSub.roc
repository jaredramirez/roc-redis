import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 Pub/Sub command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
## Subscription-changing commands are encoding-only here. `Execute.request!` and
## `Execute.batch!` cannot manage RESP2 subscription streams or unsolicited messages.
PubSub := {}.{

	## Construct `PSUBSCRIBE`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/psubscribe/).
	## Parameters (in order): `first_pattern`, `other_patterns`.
	psubscribe : List(U8), List(List(U8)) -> Command.Command
	psubscribe = |first_pattern, other_patterns| {
		catalog_patterns = [first_pattern].concat(other_patterns)
		Command.from_nonempty_bytes("PSUBSCRIBE", catalog_patterns)
	}

	## Construct `PUBLISH`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/publish/).
	## Parameters (in order): `channel`, `message`.
	publish : List(U8), List(U8) -> Command.Command
	publish = |channel, message| {
		Command.from_nonempty_bytes("PUBLISH", [channel, message])
	}

	## Construct `PUBSUB CHANNELS`.
	## Available since Redis 2.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/pubsub-channels/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	pubsub_channels : List(List(U8)) -> Command.Command
	pubsub_channels = |options| {
		Command.from_nonempty_bytes("PUBSUB", [['C', 'H', 'A', 'N', 'N', 'E', 'L', 'S']].concat(options))
	}

	## Construct `PUBSUB NUMPAT`.
	## Available since Redis 2.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/pubsub-numpat/).
	pubsub_numpat : {} -> Command.Command
	pubsub_numpat = |_| {
		Command.from_nonempty_bytes("PUBSUB", [['N', 'U', 'M', 'P', 'A', 'T']])
	}

	## Construct `PUBSUB NUMSUB`.
	## Available since Redis 2.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/pubsub-numsub/).
	## Parameters (in order): `channels`.
	pubsub_numsub : List(List(U8)) -> Command.Command
	pubsub_numsub = |channels| {
		Command.from_nonempty_bytes("PUBSUB", [['N', 'U', 'M', 'S', 'U', 'B']].concat(channels))
	}

	## Construct `PUBSUB SHARDCHANNELS`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/pubsub-shardchannels/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	pubsub_shardchannels : List(List(U8)) -> Command.Command
	pubsub_shardchannels = |options| {
		Command.from_nonempty_bytes("PUBSUB", [['S', 'H', 'A', 'R', 'D', 'C', 'H', 'A', 'N', 'N', 'E', 'L', 'S']].concat(options))
	}

	## Construct `PUBSUB SHARDNUMSUB`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/pubsub-shardnumsub/).
	## Parameters (in order): `shardchannels`.
	pubsub_shardnumsub : List(List(U8)) -> Command.Command
	pubsub_shardnumsub = |shardchannels| {
		Command.from_nonempty_bytes("PUBSUB", [['S', 'H', 'A', 'R', 'D', 'N', 'U', 'M', 'S', 'U', 'B']].concat(shardchannels))
	}

	## Construct `PUNSUBSCRIBE`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/punsubscribe/).
	## Parameters (in order): `patterns`.
	punsubscribe : List(List(U8)) -> Command.Command
	punsubscribe = |patterns| {
		Command.from_nonempty_bytes("PUNSUBSCRIBE", patterns)
	}

	## Construct `SPUBLISH`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/spublish/).
	## Parameters (in order): `shardchannel`, `message`.
	spublish : List(U8), List(U8) -> Command.Command
	spublish = |shardchannel, message| {
		Command.from_nonempty_bytes("SPUBLISH", [shardchannel, message])
	}

	## Construct `SSUBSCRIBE`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/ssubscribe/).
	## Parameters (in order): `first_shardchannel`, `other_shardchannels`.
	ssubscribe : List(U8), List(List(U8)) -> Command.Command
	ssubscribe = |first_shardchannel, other_shardchannels| {
		catalog_shardchannels = [first_shardchannel].concat(other_shardchannels)
		Command.from_nonempty_bytes("SSUBSCRIBE", catalog_shardchannels)
	}

	## Construct `SUBSCRIBE`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/subscribe/).
	## Parameters (in order): `first_channel`, `other_channels`.
	subscribe : List(U8), List(List(U8)) -> Command.Command
	subscribe = |first_channel, other_channels| {
		catalog_channels = [first_channel].concat(other_channels)
		Command.from_nonempty_bytes("SUBSCRIBE", catalog_channels)
	}

	## Construct `SUNSUBSCRIBE`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/sunsubscribe/).
	## Parameters (in order): `shardchannels`.
	sunsubscribe : List(List(U8)) -> Command.Command
	sunsubscribe = |shardchannels| {
		Command.from_nonempty_bytes("SUNSUBSCRIBE", shardchannels)
	}

	## Construct `UNSUBSCRIBE`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/unsubscribe/).
	## Parameters (in order): `channels`.
	unsubscribe : List(List(U8)) -> Command.Command
	unsubscribe = |channels| {
		Command.from_nonempty_bytes("UNSUBSCRIBE", channels)
	}
}

expect Command.encode(PubSub.psubscribe([0, 1, 255], [[0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '1', '0', '\r', '\n', 'P', 'S', 'U', 'B', 'S', 'C', 'R', 'I', 'B', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(PubSub.psubscribe([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '1', '0', '\r', '\n', 'P', 'S', 'U', 'B', 'S', 'C', 'R', 'I', 'B', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(PubSub.publish([0, 1, 255], [0, 2, 255])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'P', 'U', 'B', 'L', 'I', 'S', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(PubSub.pubsub_channels([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'P', 'U', 'B', 'S', 'U', 'B', '\r', '\n', '$', '8', '\r', '\n', 'C', 'H', 'A', 'N', 'N', 'E', 'L', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(PubSub.pubsub_channels([])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'P', 'U', 'B', 'S', 'U', 'B', '\r', '\n', '$', '8', '\r', '\n', 'C', 'H', 'A', 'N', 'N', 'E', 'L', 'S', '\r', '\n']

expect Command.encode(PubSub.pubsub_numpat({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'P', 'U', 'B', 'S', 'U', 'B', '\r', '\n', '$', '6', '\r', '\n', 'N', 'U', 'M', 'P', 'A', 'T', '\r', '\n']

expect Command.encode(PubSub.pubsub_numsub([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'P', 'U', 'B', 'S', 'U', 'B', '\r', '\n', '$', '6', '\r', '\n', 'N', 'U', 'M', 'S', 'U', 'B', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(PubSub.pubsub_numsub([])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'P', 'U', 'B', 'S', 'U', 'B', '\r', '\n', '$', '6', '\r', '\n', 'N', 'U', 'M', 'S', 'U', 'B', '\r', '\n']

expect Command.encode(PubSub.pubsub_shardchannels([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'P', 'U', 'B', 'S', 'U', 'B', '\r', '\n', '$', '1', '3', '\r', '\n', 'S', 'H', 'A', 'R', 'D', 'C', 'H', 'A', 'N', 'N', 'E', 'L', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(PubSub.pubsub_shardchannels([])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'P', 'U', 'B', 'S', 'U', 'B', '\r', '\n', '$', '1', '3', '\r', '\n', 'S', 'H', 'A', 'R', 'D', 'C', 'H', 'A', 'N', 'N', 'E', 'L', 'S', '\r', '\n']

expect Command.encode(PubSub.pubsub_shardnumsub([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'P', 'U', 'B', 'S', 'U', 'B', '\r', '\n', '$', '1', '1', '\r', '\n', 'S', 'H', 'A', 'R', 'D', 'N', 'U', 'M', 'S', 'U', 'B', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(PubSub.pubsub_shardnumsub([])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'P', 'U', 'B', 'S', 'U', 'B', '\r', '\n', '$', '1', '1', '\r', '\n', 'S', 'H', 'A', 'R', 'D', 'N', 'U', 'M', 'S', 'U', 'B', '\r', '\n']

expect Command.encode(PubSub.punsubscribe([[0, 1, 255], [0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '1', '2', '\r', '\n', 'P', 'U', 'N', 'S', 'U', 'B', 'S', 'C', 'R', 'I', 'B', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(PubSub.punsubscribe([])) == ['*', '1', '\r', '\n', '$', '1', '2', '\r', '\n', 'P', 'U', 'N', 'S', 'U', 'B', 'S', 'C', 'R', 'I', 'B', 'E', '\r', '\n']

expect Command.encode(PubSub.spublish([0, 1, 255], [0, 2, 255])) == ['*', '3', '\r', '\n', '$', '8', '\r', '\n', 'S', 'P', 'U', 'B', 'L', 'I', 'S', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(PubSub.ssubscribe([0, 1, 255], [[0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '1', '0', '\r', '\n', 'S', 'S', 'U', 'B', 'S', 'C', 'R', 'I', 'B', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(PubSub.ssubscribe([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '1', '0', '\r', '\n', 'S', 'S', 'U', 'B', 'S', 'C', 'R', 'I', 'B', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(PubSub.subscribe([0, 1, 255], [[0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '9', '\r', '\n', 'S', 'U', 'B', 'S', 'C', 'R', 'I', 'B', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(PubSub.subscribe([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '9', '\r', '\n', 'S', 'U', 'B', 'S', 'C', 'R', 'I', 'B', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(PubSub.sunsubscribe([[0, 1, 255], [0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '1', '2', '\r', '\n', 'S', 'U', 'N', 'S', 'U', 'B', 'S', 'C', 'R', 'I', 'B', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(PubSub.sunsubscribe([])) == ['*', '1', '\r', '\n', '$', '1', '2', '\r', '\n', 'S', 'U', 'N', 'S', 'U', 'B', 'S', 'C', 'R', 'I', 'B', 'E', '\r', '\n']

expect Command.encode(PubSub.unsubscribe([[0, 1, 255], [0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '1', '1', '\r', '\n', 'U', 'N', 'S', 'U', 'B', 'S', 'C', 'R', 'I', 'B', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(PubSub.unsubscribe([])) == ['*', '1', '\r', '\n', '$', '1', '1', '\r', '\n', 'U', 'N', 'S', 'U', 'B', 'S', 'C', 'R', 'I', 'B', 'E', '\r', '\n']
