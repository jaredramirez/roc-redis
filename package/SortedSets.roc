import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 Sorted Set command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
SortedSets := {}.{

	## Construct `BZMPOP`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/bzmpop/).
	## Parameters (in order): `timeout`, `first_key`, `other_keys`, `where_`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	bzmpop : List(U8), List(U8), List(List(U8)), List(U8), List(List(U8)) -> Command.Command
	bzmpop = |timeout, first_key, other_keys, where_, options| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("BZMPOP", [timeout].concat([catalog_keys.len().to_str().to_utf8()].concat(catalog_keys)).concat([where_]).concat(options))
	}

	## Construct `BZPOPMAX`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/bzpopmax/).
	## Parameters (in order): `first_key`, `other_keys`, `timeout`.
	bzpopmax : List(U8), List(List(U8)), List(U8) -> Command.Command
	bzpopmax = |first_key, other_keys, timeout| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("BZPOPMAX", catalog_keys.concat([timeout]))
	}

	## Construct `BZPOPMIN`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/bzpopmin/).
	## Parameters (in order): `first_key`, `other_keys`, `timeout`.
	bzpopmin : List(U8), List(List(U8)), List(U8) -> Command.Command
	bzpopmin = |first_key, other_keys, timeout| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("BZPOPMIN", catalog_keys.concat([timeout]))
	}

	## Construct `ZADD`.
	## Available since Redis 1.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zadd/).
	## Parameters (in order): `key`, `options_before_data`, `first_entry`, `other_entries`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zadd : List(U8), List(List(U8)), { score : List(U8), member : List(U8) }, List({ score : List(U8), member : List(U8) }) -> Command.Command
	zadd = |key, options_before_data, first_entry, other_entries| {
		catalog_entries = [first_entry].concat(other_entries)
		Command.from_nonempty_bytes("ZADD", [key].concat(options_before_data).concat(catalog_entries.join_map(|item| [item.score, item.member])))
	}

	## Construct `ZCARD`.
	## Available since Redis 1.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zcard/).
	## Parameters (in order): `key`.
	zcard : List(U8) -> Command.Command
	zcard = |key| {
		Command.from_nonempty_bytes("ZCARD", [key])
	}

	## Construct `ZCOUNT`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zcount/).
	## Parameters (in order): `key`, `min`, `max`.
	zcount : List(U8), List(U8), List(U8) -> Command.Command
	zcount = |key, min, max| {
		Command.from_nonempty_bytes("ZCOUNT", [key, min, max])
	}

	## Construct `ZDIFF`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zdiff/).
	## Parameters (in order): `first_key`, `other_keys`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zdiff : List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	zdiff = |first_key, other_keys, options| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("ZDIFF", [catalog_keys.len().to_str().to_utf8()].concat(catalog_keys).concat(options))
	}

	## Construct `ZDIFFSTORE`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zdiffstore/).
	## Parameters (in order): `destination`, `first_key`, `other_keys`.
	zdiffstore : List(U8), List(U8), List(List(U8)) -> Command.Command
	zdiffstore = |destination, first_key, other_keys| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("ZDIFFSTORE", [destination].concat([catalog_keys.len().to_str().to_utf8()].concat(catalog_keys)))
	}

	## Construct `ZINCRBY`.
	## Available since Redis 1.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zincrby/).
	## Parameters (in order): `key`, `increment`, `member`.
	zincrby : List(U8), List(U8), List(U8) -> Command.Command
	zincrby = |key, increment, member| {
		Command.from_nonempty_bytes("ZINCRBY", [key, increment, member])
	}

	## Construct `ZINTER`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zinter/).
	## Parameters (in order): `first_key`, `other_keys`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zinter : List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	zinter = |first_key, other_keys, options| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("ZINTER", [catalog_keys.len().to_str().to_utf8()].concat(catalog_keys).concat(options))
	}

	## Construct `ZINTERCARD`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zintercard/).
	## Parameters (in order): `first_key`, `other_keys`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zintercard : List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	zintercard = |first_key, other_keys, options| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("ZINTERCARD", [catalog_keys.len().to_str().to_utf8()].concat(catalog_keys).concat(options))
	}

	## Construct `ZINTERSTORE`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zinterstore/).
	## Parameters (in order): `destination`, `first_key`, `other_keys`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zinterstore : List(U8), List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	zinterstore = |destination, first_key, other_keys, options| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("ZINTERSTORE", [destination].concat([catalog_keys.len().to_str().to_utf8()].concat(catalog_keys)).concat(options))
	}

	## Construct `ZLEXCOUNT`.
	## Available since Redis 2.8.9.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zlexcount/).
	## Parameters (in order): `key`, `min`, `max`.
	zlexcount : List(U8), List(U8), List(U8) -> Command.Command
	zlexcount = |key, min, max| {
		Command.from_nonempty_bytes("ZLEXCOUNT", [key, min, max])
	}

	## Construct `ZMPOP`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zmpop/).
	## Parameters (in order): `first_key`, `other_keys`, `where_`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zmpop : List(U8), List(List(U8)), List(U8), List(List(U8)) -> Command.Command
	zmpop = |first_key, other_keys, where_, options| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("ZMPOP", [catalog_keys.len().to_str().to_utf8()].concat(catalog_keys).concat([where_]).concat(options))
	}

	## Construct `ZMSCORE`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zmscore/).
	## Parameters (in order): `key`, `first_member`, `other_members`.
	zmscore : List(U8), List(U8), List(List(U8)) -> Command.Command
	zmscore = |key, first_member, other_members| {
		catalog_members = [first_member].concat(other_members)
		Command.from_nonempty_bytes("ZMSCORE", [key].concat(catalog_members))
	}

	## Construct `ZPOPMAX`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zpopmax/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zpopmax : List(U8), List(List(U8)) -> Command.Command
	zpopmax = |key, options| {
		Command.from_nonempty_bytes("ZPOPMAX", [key].concat(options))
	}

	## Construct `ZPOPMIN`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zpopmin/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zpopmin : List(U8), List(List(U8)) -> Command.Command
	zpopmin = |key, options| {
		Command.from_nonempty_bytes("ZPOPMIN", [key].concat(options))
	}

	## Construct `ZRANDMEMBER`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zrandmember/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zrandmember : List(U8), List(List(U8)) -> Command.Command
	zrandmember = |key, options| {
		Command.from_nonempty_bytes("ZRANDMEMBER", [key].concat(options))
	}

	## Construct `ZRANGE`.
	## Available since Redis 1.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zrange/).
	## Parameters (in order): `key`, `start`, `stop`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zrange : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	zrange = |key, start, stop, options| {
		Command.from_nonempty_bytes("ZRANGE", [key, start, stop].concat(options))
	}

	## Construct `ZRANGEBYLEX`.
	## Available since Redis 2.8.9.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zrangebylex/).
	## Parameters (in order): `key`, `min`, `max`, `options`.
	## Deprecated by Redis; retained for catalog completeness.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zrangebylex : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	zrangebylex = |key, min, max, options| {
		Command.from_nonempty_bytes("ZRANGEBYLEX", [key, min, max].concat(options))
	}

	## Construct `ZRANGEBYSCORE`.
	## Available since Redis 1.0.5.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zrangebyscore/).
	## Parameters (in order): `key`, `min`, `max`, `options`.
	## Deprecated by Redis; retained for catalog completeness.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zrangebyscore : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	zrangebyscore = |key, min, max, options| {
		Command.from_nonempty_bytes("ZRANGEBYSCORE", [key, min, max].concat(options))
	}

	## Construct `ZRANGESTORE`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zrangestore/).
	## Parameters (in order): `dst`, `src`, `min`, `max`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zrangestore : List(U8), List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	zrangestore = |dst, src, min, max, options| {
		Command.from_nonempty_bytes("ZRANGESTORE", [dst, src, min, max].concat(options))
	}

	## Construct `ZRANK`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zrank/).
	## Parameters (in order): `key`, `member`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zrank : List(U8), List(U8), List(List(U8)) -> Command.Command
	zrank = |key, member, options| {
		Command.from_nonempty_bytes("ZRANK", [key, member].concat(options))
	}

	## Construct `ZREM`.
	## Available since Redis 1.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zrem/).
	## Parameters (in order): `key`, `first_member`, `other_members`.
	zrem : List(U8), List(U8), List(List(U8)) -> Command.Command
	zrem = |key, first_member, other_members| {
		catalog_members = [first_member].concat(other_members)
		Command.from_nonempty_bytes("ZREM", [key].concat(catalog_members))
	}

	## Construct `ZREMRANGEBYLEX`.
	## Available since Redis 2.8.9.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zremrangebylex/).
	## Parameters (in order): `key`, `min`, `max`.
	zremrangebylex : List(U8), List(U8), List(U8) -> Command.Command
	zremrangebylex = |key, min, max| {
		Command.from_nonempty_bytes("ZREMRANGEBYLEX", [key, min, max])
	}

	## Construct `ZREMRANGEBYRANK`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zremrangebyrank/).
	## Parameters (in order): `key`, `start`, `stop`.
	zremrangebyrank : List(U8), List(U8), List(U8) -> Command.Command
	zremrangebyrank = |key, start, stop| {
		Command.from_nonempty_bytes("ZREMRANGEBYRANK", [key, start, stop])
	}

	## Construct `ZREMRANGEBYSCORE`.
	## Available since Redis 1.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zremrangebyscore/).
	## Parameters (in order): `key`, `min`, `max`.
	zremrangebyscore : List(U8), List(U8), List(U8) -> Command.Command
	zremrangebyscore = |key, min, max| {
		Command.from_nonempty_bytes("ZREMRANGEBYSCORE", [key, min, max])
	}

	## Construct `ZREVRANGE`.
	## Available since Redis 1.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zrevrange/).
	## Parameters (in order): `key`, `start`, `stop`, `options`.
	## Deprecated by Redis; retained for catalog completeness.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zrevrange : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	zrevrange = |key, start, stop, options| {
		Command.from_nonempty_bytes("ZREVRANGE", [key, start, stop].concat(options))
	}

	## Construct `ZREVRANGEBYLEX`.
	## Available since Redis 2.8.9.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zrevrangebylex/).
	## Parameters (in order): `key`, `max`, `min`, `options`.
	## Deprecated by Redis; retained for catalog completeness.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zrevrangebylex : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	zrevrangebylex = |key, max, min, options| {
		Command.from_nonempty_bytes("ZREVRANGEBYLEX", [key, max, min].concat(options))
	}

	## Construct `ZREVRANGEBYSCORE`.
	## Available since Redis 2.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zrevrangebyscore/).
	## Parameters (in order): `key`, `max`, `min`, `options`.
	## Deprecated by Redis; retained for catalog completeness.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zrevrangebyscore : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	zrevrangebyscore = |key, max, min, options| {
		Command.from_nonempty_bytes("ZREVRANGEBYSCORE", [key, max, min].concat(options))
	}

	## Construct `ZREVRANK`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zrevrank/).
	## Parameters (in order): `key`, `member`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zrevrank : List(U8), List(U8), List(List(U8)) -> Command.Command
	zrevrank = |key, member, options| {
		Command.from_nonempty_bytes("ZREVRANK", [key, member].concat(options))
	}

	## Construct `ZSCAN`.
	## Available since Redis 2.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zscan/).
	## Parameters (in order): `key`, `cursor`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zscan : List(U8), List(U8), List(List(U8)) -> Command.Command
	zscan = |key, cursor, options| {
		Command.from_nonempty_bytes("ZSCAN", [key, cursor].concat(options))
	}

	## Construct `ZSCORE`.
	## Available since Redis 1.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zscore/).
	## Parameters (in order): `key`, `member`.
	zscore : List(U8), List(U8) -> Command.Command
	zscore = |key, member| {
		Command.from_nonempty_bytes("ZSCORE", [key, member])
	}

	## Construct `ZUNION`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zunion/).
	## Parameters (in order): `first_key`, `other_keys`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zunion : List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	zunion = |first_key, other_keys, options| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("ZUNION", [catalog_keys.len().to_str().to_utf8()].concat(catalog_keys).concat(options))
	}

	## Construct `ZUNIONSTORE`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/zunionstore/).
	## Parameters (in order): `destination`, `first_key`, `other_keys`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	zunionstore : List(U8), List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	zunionstore = |destination, first_key, other_keys, options| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("ZUNIONSTORE", [destination].concat([catalog_keys.len().to_str().to_utf8()].concat(catalog_keys)).concat(options))
	}
}

expect Command.encode(SortedSets.bzmpop(['1', '.', '5'], [0, 2, 255], [[0, 3, 255]], ['M', 'I', 'N'], [[0, 4, 255], [0, 5, 255]])) == ['*', '8', '\r', '\n', '$', '6', '\r', '\n', 'B', 'Z', 'M', 'P', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', '1', '.', '5', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 'M', 'I', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(SortedSets.bzmpop(['1', '.', '5'], [0, 2, 255], [], ['M', 'I', 'N'], [])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'B', 'Z', 'M', 'P', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', '1', '.', '5', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 'M', 'I', 'N', '\r', '\n']

expect Command.encode(SortedSets.bzpopmax([0, 1, 255], [[0, 2, 255]], ['3', '.', '5'])) == ['*', '4', '\r', '\n', '$', '8', '\r', '\n', 'B', 'Z', 'P', 'O', 'P', 'M', 'A', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n']

expect Command.encode(SortedSets.bzpopmax([0, 1, 255], [], ['3', '.', '5'])) == ['*', '3', '\r', '\n', '$', '8', '\r', '\n', 'B', 'Z', 'P', 'O', 'P', 'M', 'A', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n']

expect Command.encode(SortedSets.bzpopmin([0, 1, 255], [[0, 2, 255]], ['3', '.', '5'])) == ['*', '4', '\r', '\n', '$', '8', '\r', '\n', 'B', 'Z', 'P', 'O', 'P', 'M', 'I', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n']

expect Command.encode(SortedSets.bzpopmin([0, 1, 255], [], ['3', '.', '5'])) == ['*', '3', '\r', '\n', '$', '8', '\r', '\n', 'B', 'Z', 'P', 'O', 'P', 'M', 'I', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n']

expect Command.encode(SortedSets.zadd([0, 1, 255], [[0, 2, 255], [0, 3, 255]], { score: ['4', '.', '5'], member: [0, 5, 255] }, [{ score: ['6', '.', '5'], member: [0, 7, 255] }])) == ['*', '8', '\r', '\n', '$', '4', '\r', '\n', 'Z', 'A', 'D', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', '4', '.', '5', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', '6', '.', '5', '\r', '\n', '$', '3', '\r', '\n', 0, 7, 255, '\r', '\n']

expect Command.encode(SortedSets.zadd([0, 1, 255], [], { score: ['4', '.', '5'], member: [0, 5, 255] }, [])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'Z', 'A', 'D', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '4', '.', '5', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(SortedSets.zcard([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '5', '\r', '\n', 'Z', 'C', 'A', 'R', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(SortedSets.zcount([0, 1, 255], ['2', '.', '5'], ['3', '.', '5'])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'Z', 'C', 'O', 'U', 'N', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '2', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n']

expect Command.encode(SortedSets.zdiff([0, 1, 255], [[0, 2, 255]], [[0, 3, 255], [0, 4, 255]])) == ['*', '6', '\r', '\n', '$', '5', '\r', '\n', 'Z', 'D', 'I', 'F', 'F', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(SortedSets.zdiff([0, 1, 255], [], [])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'Z', 'D', 'I', 'F', 'F', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(SortedSets.zdiffstore([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '5', '\r', '\n', '$', '1', '0', '\r', '\n', 'Z', 'D', 'I', 'F', 'F', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(SortedSets.zdiffstore([0, 1, 255], [0, 2, 255], [])) == ['*', '4', '\r', '\n', '$', '1', '0', '\r', '\n', 'Z', 'D', 'I', 'F', 'F', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(SortedSets.zincrby([0, 1, 255], ['2'], [0, 3, 255])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'Z', 'I', 'N', 'C', 'R', 'B', 'Y', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(SortedSets.zinter([0, 1, 255], [[0, 2, 255]], [[0, 3, 255], [0, 4, 255]])) == ['*', '6', '\r', '\n', '$', '6', '\r', '\n', 'Z', 'I', 'N', 'T', 'E', 'R', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(SortedSets.zinter([0, 1, 255], [], [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'Z', 'I', 'N', 'T', 'E', 'R', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(SortedSets.zintercard([0, 1, 255], [[0, 2, 255]], [[0, 3, 255], [0, 4, 255]])) == ['*', '6', '\r', '\n', '$', '1', '0', '\r', '\n', 'Z', 'I', 'N', 'T', 'E', 'R', 'C', 'A', 'R', 'D', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(SortedSets.zintercard([0, 1, 255], [], [])) == ['*', '3', '\r', '\n', '$', '1', '0', '\r', '\n', 'Z', 'I', 'N', 'T', 'E', 'R', 'C', 'A', 'R', 'D', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(SortedSets.zinterstore([0, 1, 255], [0, 2, 255], [[0, 3, 255]], [[0, 4, 255], [0, 5, 255]])) == ['*', '7', '\r', '\n', '$', '1', '1', '\r', '\n', 'Z', 'I', 'N', 'T', 'E', 'R', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(SortedSets.zinterstore([0, 1, 255], [0, 2, 255], [], [])) == ['*', '4', '\r', '\n', '$', '1', '1', '\r', '\n', 'Z', 'I', 'N', 'T', 'E', 'R', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(SortedSets.zlexcount([0, 1, 255], [0, 2, 255], [0, 3, 255])) == ['*', '4', '\r', '\n', '$', '9', '\r', '\n', 'Z', 'L', 'E', 'X', 'C', 'O', 'U', 'N', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(SortedSets.zmpop([0, 1, 255], [[0, 2, 255]], ['M', 'I', 'N'], [[0, 3, 255], [0, 4, 255]])) == ['*', '7', '\r', '\n', '$', '5', '\r', '\n', 'Z', 'M', 'P', 'O', 'P', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 'M', 'I', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(SortedSets.zmpop([0, 1, 255], [], ['M', 'I', 'N'], [])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'Z', 'M', 'P', 'O', 'P', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 'M', 'I', 'N', '\r', '\n']

expect Command.encode(SortedSets.zmscore([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'Z', 'M', 'S', 'C', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(SortedSets.zmscore([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'Z', 'M', 'S', 'C', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(SortedSets.zpopmax([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'Z', 'P', 'O', 'P', 'M', 'A', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(SortedSets.zpopmax([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'Z', 'P', 'O', 'P', 'M', 'A', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(SortedSets.zpopmin([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'Z', 'P', 'O', 'P', 'M', 'I', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(SortedSets.zpopmin([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'Z', 'P', 'O', 'P', 'M', 'I', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(SortedSets.zrandmember([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '1', '1', '\r', '\n', 'Z', 'R', 'A', 'N', 'D', 'M', 'E', 'M', 'B', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(SortedSets.zrandmember([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '1', '1', '\r', '\n', 'Z', 'R', 'A', 'N', 'D', 'M', 'E', 'M', 'B', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(SortedSets.zrange([0, 1, 255], [0, 2, 255], [0, 3, 255], [[0, 4, 255], [0, 5, 255]])) == ['*', '6', '\r', '\n', '$', '6', '\r', '\n', 'Z', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(SortedSets.zrange([0, 1, 255], [0, 2, 255], [0, 3, 255], [])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'Z', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(SortedSets.zrangebylex([0, 1, 255], [0, 2, 255], [0, 3, 255], [[0, 4, 255], [0, 5, 255]])) == ['*', '6', '\r', '\n', '$', '1', '1', '\r', '\n', 'Z', 'R', 'A', 'N', 'G', 'E', 'B', 'Y', 'L', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(SortedSets.zrangebylex([0, 1, 255], [0, 2, 255], [0, 3, 255], [])) == ['*', '4', '\r', '\n', '$', '1', '1', '\r', '\n', 'Z', 'R', 'A', 'N', 'G', 'E', 'B', 'Y', 'L', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(SortedSets.zrangebyscore([0, 1, 255], ['2', '.', '5'], ['3', '.', '5'], [[0, 4, 255], [0, 5, 255]])) == ['*', '6', '\r', '\n', '$', '1', '3', '\r', '\n', 'Z', 'R', 'A', 'N', 'G', 'E', 'B', 'Y', 'S', 'C', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '2', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(SortedSets.zrangebyscore([0, 1, 255], ['2', '.', '5'], ['3', '.', '5'], [])) == ['*', '4', '\r', '\n', '$', '1', '3', '\r', '\n', 'Z', 'R', 'A', 'N', 'G', 'E', 'B', 'Y', 'S', 'C', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '2', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n']

expect Command.encode(SortedSets.zrangestore([0, 1, 255], [0, 2, 255], [0, 3, 255], [0, 4, 255], [[0, 5, 255], [0, 6, 255]])) == ['*', '7', '\r', '\n', '$', '1', '1', '\r', '\n', 'Z', 'R', 'A', 'N', 'G', 'E', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n']

expect Command.encode(SortedSets.zrangestore([0, 1, 255], [0, 2, 255], [0, 3, 255], [0, 4, 255], [])) == ['*', '5', '\r', '\n', '$', '1', '1', '\r', '\n', 'Z', 'R', 'A', 'N', 'G', 'E', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(SortedSets.zrank([0, 1, 255], [0, 2, 255], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '5', '\r', '\n', 'Z', 'R', 'A', 'N', 'K', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(SortedSets.zrank([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'Z', 'R', 'A', 'N', 'K', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(SortedSets.zrem([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'Z', 'R', 'E', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(SortedSets.zrem([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'Z', 'R', 'E', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(SortedSets.zremrangebylex([0, 1, 255], [0, 2, 255], [0, 3, 255])) == ['*', '4', '\r', '\n', '$', '1', '4', '\r', '\n', 'Z', 'R', 'E', 'M', 'R', 'A', 'N', 'G', 'E', 'B', 'Y', 'L', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(SortedSets.zremrangebyrank([0, 1, 255], ['2'], ['3'])) == ['*', '4', '\r', '\n', '$', '1', '5', '\r', '\n', 'Z', 'R', 'E', 'M', 'R', 'A', 'N', 'G', 'E', 'B', 'Y', 'R', 'A', 'N', 'K', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n']

expect Command.encode(SortedSets.zremrangebyscore([0, 1, 255], ['2', '.', '5'], ['3', '.', '5'])) == ['*', '4', '\r', '\n', '$', '1', '6', '\r', '\n', 'Z', 'R', 'E', 'M', 'R', 'A', 'N', 'G', 'E', 'B', 'Y', 'S', 'C', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '2', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n']

expect Command.encode(SortedSets.zrevrange([0, 1, 255], ['2'], ['3'], [[0, 4, 255], [0, 5, 255]])) == ['*', '6', '\r', '\n', '$', '9', '\r', '\n', 'Z', 'R', 'E', 'V', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(SortedSets.zrevrange([0, 1, 255], ['2'], ['3'], [])) == ['*', '4', '\r', '\n', '$', '9', '\r', '\n', 'Z', 'R', 'E', 'V', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n']

expect Command.encode(SortedSets.zrevrangebylex([0, 1, 255], [0, 2, 255], [0, 3, 255], [[0, 4, 255], [0, 5, 255]])) == ['*', '6', '\r', '\n', '$', '1', '4', '\r', '\n', 'Z', 'R', 'E', 'V', 'R', 'A', 'N', 'G', 'E', 'B', 'Y', 'L', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(SortedSets.zrevrangebylex([0, 1, 255], [0, 2, 255], [0, 3, 255], [])) == ['*', '4', '\r', '\n', '$', '1', '4', '\r', '\n', 'Z', 'R', 'E', 'V', 'R', 'A', 'N', 'G', 'E', 'B', 'Y', 'L', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(SortedSets.zrevrangebyscore([0, 1, 255], ['2', '.', '5'], ['3', '.', '5'], [[0, 4, 255], [0, 5, 255]])) == ['*', '6', '\r', '\n', '$', '1', '6', '\r', '\n', 'Z', 'R', 'E', 'V', 'R', 'A', 'N', 'G', 'E', 'B', 'Y', 'S', 'C', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '2', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(SortedSets.zrevrangebyscore([0, 1, 255], ['2', '.', '5'], ['3', '.', '5'], [])) == ['*', '4', '\r', '\n', '$', '1', '6', '\r', '\n', 'Z', 'R', 'E', 'V', 'R', 'A', 'N', 'G', 'E', 'B', 'Y', 'S', 'C', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '2', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n']

expect Command.encode(SortedSets.zrevrank([0, 1, 255], [0, 2, 255], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '8', '\r', '\n', 'Z', 'R', 'E', 'V', 'R', 'A', 'N', 'K', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(SortedSets.zrevrank([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '8', '\r', '\n', 'Z', 'R', 'E', 'V', 'R', 'A', 'N', 'K', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(SortedSets.zscan([0, 1, 255], ['2'], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '5', '\r', '\n', 'Z', 'S', 'C', 'A', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(SortedSets.zscan([0, 1, 255], ['2'], [])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'Z', 'S', 'C', 'A', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(SortedSets.zscore([0, 1, 255], [0, 2, 255])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'Z', 'S', 'C', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(SortedSets.zunion([0, 1, 255], [[0, 2, 255]], [[0, 3, 255], [0, 4, 255]])) == ['*', '6', '\r', '\n', '$', '6', '\r', '\n', 'Z', 'U', 'N', 'I', 'O', 'N', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(SortedSets.zunion([0, 1, 255], [], [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'Z', 'U', 'N', 'I', 'O', 'N', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(SortedSets.zunionstore([0, 1, 255], [0, 2, 255], [[0, 3, 255]], [[0, 4, 255], [0, 5, 255]])) == ['*', '7', '\r', '\n', '$', '1', '1', '\r', '\n', 'Z', 'U', 'N', 'I', 'O', 'N', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(SortedSets.zunionstore([0, 1, 255], [0, 2, 255], [], [])) == ['*', '4', '\r', '\n', '$', '1', '1', '\r', '\n', 'Z', 'U', 'N', 'I', 'O', 'N', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']
