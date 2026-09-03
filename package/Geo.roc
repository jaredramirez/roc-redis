import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 Geo command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
Geo := {}.{

	## Construct `GEOADD`.
	## Available since Redis 3.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/geoadd/).
	## Parameters (in order): `key`, `options_before_data`, `first_entry`, `other_entries`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	geoadd : List(U8), List(List(U8)), { longitude : List(U8), latitude : List(U8), member : List(U8) }, List({ longitude : List(U8), latitude : List(U8), member : List(U8) }) -> Command.Command
	geoadd = |key, options_before_data, first_entry, other_entries| {
		catalog_entries = [first_entry].concat(other_entries)
		Command.from_nonempty_bytes("GEOADD", [key].concat(options_before_data).concat(catalog_entries.join_map(|item| [item.longitude, item.latitude, item.member])))
	}

	## Construct `GEODIST`.
	## Available since Redis 3.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/geodist/).
	## Parameters (in order): `key`, `member1`, `member2`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	geodist : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	geodist = |key, member1, member2, options| {
		Command.from_nonempty_bytes("GEODIST", [key, member1, member2].concat(options))
	}

	## Construct `GEOHASH`.
	## Available since Redis 3.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/geohash/).
	## Parameters (in order): `key`, `members`.
	geohash : List(U8), List(List(U8)) -> Command.Command
	geohash = |key, members| {
		Command.from_nonempty_bytes("GEOHASH", [key].concat(members))
	}

	## Construct `GEOPOS`.
	## Available since Redis 3.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/geopos/).
	## Parameters (in order): `key`, `members`.
	geopos : List(U8), List(List(U8)) -> Command.Command
	geopos = |key, members| {
		Command.from_nonempty_bytes("GEOPOS", [key].concat(members))
	}

	## Construct `GEORADIUS`.
	## Available since Redis 3.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/georadius/).
	## Parameters (in order): `key`, `longitude`, `latitude`, `radius`, `unit`, `options`.
	## Deprecated by Redis; retained for catalog completeness.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	georadius : List(U8), List(U8), List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	georadius = |key, longitude, latitude, radius, unit, options| {
		Command.from_nonempty_bytes("GEORADIUS", [key, longitude, latitude, radius, unit].concat(options))
	}

	## Construct `GEORADIUS_RO`.
	## Available since Redis 3.2.10.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/georadius_ro/).
	## Parameters (in order): `key`, `longitude`, `latitude`, `radius`, `unit`, `options`.
	## Deprecated by Redis; retained for catalog completeness.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	georadius_ro : List(U8), List(U8), List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	georadius_ro = |key, longitude, latitude, radius, unit, options| {
		Command.from_nonempty_bytes("GEORADIUS_RO", [key, longitude, latitude, radius, unit].concat(options))
	}

	## Construct `GEORADIUSBYMEMBER`.
	## Available since Redis 3.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/georadiusbymember/).
	## Parameters (in order): `key`, `member`, `radius`, `unit`, `options`.
	## Deprecated by Redis; retained for catalog completeness.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	georadiusbymember : List(U8), List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	georadiusbymember = |key, member, radius, unit, options| {
		Command.from_nonempty_bytes("GEORADIUSBYMEMBER", [key, member, radius, unit].concat(options))
	}

	## Construct `GEORADIUSBYMEMBER_RO`.
	## Available since Redis 3.2.10.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/georadiusbymember_ro/).
	## Parameters (in order): `key`, `member`, `radius`, `unit`, `options`.
	## Deprecated by Redis; retained for catalog completeness.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	georadiusbymember_ro : List(U8), List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	georadiusbymember_ro = |key, member, radius, unit, options| {
		Command.from_nonempty_bytes("GEORADIUSBYMEMBER_RO", [key, member, radius, unit].concat(options))
	}

	## Construct `GEOSEARCH`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/geosearch/).
	## Parameters (in order): `key`, `from`, `by`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	geosearch : List(U8), { first : List(U8), rest : List(List(U8)) }, { first : List(U8), rest : List(List(U8)) }, List(List(U8)) -> Command.Command
	geosearch = |key, from, by, options| {
		Command.from_nonempty_bytes("GEOSEARCH", [key].concat([from.first].concat(from.rest)).concat([by.first].concat(by.rest)).concat(options))
	}

	## Construct `GEOSEARCHSTORE`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/geosearchstore/).
	## Parameters (in order): `destination`, `source`, `from`, `by`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	geosearchstore : List(U8), List(U8), { first : List(U8), rest : List(List(U8)) }, { first : List(U8), rest : List(List(U8)) }, List(List(U8)) -> Command.Command
	geosearchstore = |destination, source, from, by, options| {
		Command.from_nonempty_bytes("GEOSEARCHSTORE", [destination, source].concat([from.first].concat(from.rest)).concat([by.first].concat(by.rest)).concat(options))
	}
}

expect Command.encode(Geo.geoadd([0, 1, 255], [[0, 2, 255], [0, 3, 255]], { longitude: ['4', '.', '5'], latitude: ['5', '.', '5'], member: [0, 6, 255] }, [{ longitude: ['7', '.', '5'], latitude: ['8', '.', '5'], member: [0, '\t', 255] }])) == ['*', '1', '0', '\r', '\n', '$', '6', '\r', '\n', 'G', 'E', 'O', 'A', 'D', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', '4', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '5', '.', '5', '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n', '$', '3', '\r', '\n', '7', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '8', '.', '5', '\r', '\n', '$', '3', '\r', '\n', 0, '\t', 255, '\r', '\n']

expect Command.encode(Geo.geoadd([0, 1, 255], [], { longitude: ['4', '.', '5'], latitude: ['5', '.', '5'], member: [0, 6, 255] }, [])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'G', 'E', 'O', 'A', 'D', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '4', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '5', '.', '5', '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n']

expect Command.encode(Geo.geodist([0, 1, 255], [0, 2, 255], [0, 3, 255], [[0, 4, 255], [0, 5, 255]])) == ['*', '6', '\r', '\n', '$', '7', '\r', '\n', 'G', 'E', 'O', 'D', 'I', 'S', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Geo.geodist([0, 1, 255], [0, 2, 255], [0, 3, 255], [])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'G', 'E', 'O', 'D', 'I', 'S', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Geo.geohash([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'G', 'E', 'O', 'H', 'A', 'S', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Geo.geohash([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'G', 'E', 'O', 'H', 'A', 'S', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Geo.geopos([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'G', 'E', 'O', 'P', 'O', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Geo.geopos([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'G', 'E', 'O', 'P', 'O', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Geo.georadius([0, 1, 255], ['2', '.', '5'], ['3', '.', '5'], ['4', '.', '5'], ['M'], [[0, 5, 255], [0, 6, 255]])) == ['*', '8', '\r', '\n', '$', '9', '\r', '\n', 'G', 'E', 'O', 'R', 'A', 'D', 'I', 'U', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '2', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '4', '.', '5', '\r', '\n', '$', '1', '\r', '\n', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n']

expect Command.encode(Geo.georadius([0, 1, 255], ['2', '.', '5'], ['3', '.', '5'], ['4', '.', '5'], ['M'], [])) == ['*', '6', '\r', '\n', '$', '9', '\r', '\n', 'G', 'E', 'O', 'R', 'A', 'D', 'I', 'U', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '2', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '4', '.', '5', '\r', '\n', '$', '1', '\r', '\n', 'M', '\r', '\n']

expect Command.encode(Geo.georadius_ro([0, 1, 255], ['2', '.', '5'], ['3', '.', '5'], ['4', '.', '5'], ['M'], [[0, 5, 255], [0, 6, 255]])) == ['*', '8', '\r', '\n', '$', '1', '2', '\r', '\n', 'G', 'E', 'O', 'R', 'A', 'D', 'I', 'U', 'S', '_', 'R', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '2', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '4', '.', '5', '\r', '\n', '$', '1', '\r', '\n', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n']

expect Command.encode(Geo.georadius_ro([0, 1, 255], ['2', '.', '5'], ['3', '.', '5'], ['4', '.', '5'], ['M'], [])) == ['*', '6', '\r', '\n', '$', '1', '2', '\r', '\n', 'G', 'E', 'O', 'R', 'A', 'D', 'I', 'U', 'S', '_', 'R', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', '2', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n', '$', '3', '\r', '\n', '4', '.', '5', '\r', '\n', '$', '1', '\r', '\n', 'M', '\r', '\n']

expect Command.encode(Geo.georadiusbymember([0, 1, 255], [0, 2, 255], ['3', '.', '5'], ['M'], [[0, 4, 255], [0, 5, 255]])) == ['*', '7', '\r', '\n', '$', '1', '7', '\r', '\n', 'G', 'E', 'O', 'R', 'A', 'D', 'I', 'U', 'S', 'B', 'Y', 'M', 'E', 'M', 'B', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n', '$', '1', '\r', '\n', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Geo.georadiusbymember([0, 1, 255], [0, 2, 255], ['3', '.', '5'], ['M'], [])) == ['*', '5', '\r', '\n', '$', '1', '7', '\r', '\n', 'G', 'E', 'O', 'R', 'A', 'D', 'I', 'U', 'S', 'B', 'Y', 'M', 'E', 'M', 'B', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n', '$', '1', '\r', '\n', 'M', '\r', '\n']

expect Command.encode(Geo.georadiusbymember_ro([0, 1, 255], [0, 2, 255], ['3', '.', '5'], ['M'], [[0, 4, 255], [0, 5, 255]])) == ['*', '7', '\r', '\n', '$', '2', '0', '\r', '\n', 'G', 'E', 'O', 'R', 'A', 'D', 'I', 'U', 'S', 'B', 'Y', 'M', 'E', 'M', 'B', 'E', 'R', '_', 'R', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n', '$', '1', '\r', '\n', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Geo.georadiusbymember_ro([0, 1, 255], [0, 2, 255], ['3', '.', '5'], ['M'], [])) == ['*', '5', '\r', '\n', '$', '2', '0', '\r', '\n', 'G', 'E', 'O', 'R', 'A', 'D', 'I', 'U', 'S', 'B', 'Y', 'M', 'E', 'M', 'B', 'E', 'R', '_', 'R', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n', '$', '1', '\r', '\n', 'M', '\r', '\n']

expect Command.encode(Geo.geosearch([0, 1, 255], { first: ['F', 'R', 'O', 'M', 'M', 'E', 'M', 'B', 'E', 'R'], rest: [[0, 2, 255]] }, { first: ['B', 'Y', 'R', 'A', 'D', 'I', 'U', 'S'], rest: [['3', '.', '5'], ['M']] }, [[0, 4, 255], [0, 5, 255]])) == ['*', '9', '\r', '\n', '$', '9', '\r', '\n', 'G', 'E', 'O', 'S', 'E', 'A', 'R', 'C', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '0', '\r', '\n', 'F', 'R', 'O', 'M', 'M', 'E', 'M', 'B', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '8', '\r', '\n', 'B', 'Y', 'R', 'A', 'D', 'I', 'U', 'S', '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n', '$', '1', '\r', '\n', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Geo.geosearch([0, 1, 255], { first: ['F', 'R', 'O', 'M', 'M', 'E', 'M', 'B', 'E', 'R'], rest: [[0, 2, 255]] }, { first: ['B', 'Y', 'R', 'A', 'D', 'I', 'U', 'S'], rest: [['3', '.', '5'], ['M']] }, [])) == ['*', '7', '\r', '\n', '$', '9', '\r', '\n', 'G', 'E', 'O', 'S', 'E', 'A', 'R', 'C', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '0', '\r', '\n', 'F', 'R', 'O', 'M', 'M', 'E', 'M', 'B', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '8', '\r', '\n', 'B', 'Y', 'R', 'A', 'D', 'I', 'U', 'S', '\r', '\n', '$', '3', '\r', '\n', '3', '.', '5', '\r', '\n', '$', '1', '\r', '\n', 'M', '\r', '\n']

expect Command.encode(Geo.geosearchstore([0, 1, 255], [0, 2, 255], { first: ['F', 'R', 'O', 'M', 'M', 'E', 'M', 'B', 'E', 'R'], rest: [[0, 3, 255]] }, { first: ['B', 'Y', 'R', 'A', 'D', 'I', 'U', 'S'], rest: [['4', '.', '5'], ['M']] }, [[0, 5, 255], [0, 6, 255]])) == ['*', '1', '0', '\r', '\n', '$', '1', '4', '\r', '\n', 'G', 'E', 'O', 'S', 'E', 'A', 'R', 'C', 'H', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '1', '0', '\r', '\n', 'F', 'R', 'O', 'M', 'M', 'E', 'M', 'B', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '8', '\r', '\n', 'B', 'Y', 'R', 'A', 'D', 'I', 'U', 'S', '\r', '\n', '$', '3', '\r', '\n', '4', '.', '5', '\r', '\n', '$', '1', '\r', '\n', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n']

expect Command.encode(Geo.geosearchstore([0, 1, 255], [0, 2, 255], { first: ['F', 'R', 'O', 'M', 'M', 'E', 'M', 'B', 'E', 'R'], rest: [[0, 3, 255]] }, { first: ['B', 'Y', 'R', 'A', 'D', 'I', 'U', 'S'], rest: [['4', '.', '5'], ['M']] }, [])) == ['*', '8', '\r', '\n', '$', '1', '4', '\r', '\n', 'G', 'E', 'O', 'S', 'E', 'A', 'R', 'C', 'H', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '1', '0', '\r', '\n', 'F', 'R', 'O', 'M', 'M', 'E', 'M', 'B', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '8', '\r', '\n', 'B', 'Y', 'R', 'A', 'D', 'I', 'U', 'S', '\r', '\n', '$', '3', '\r', '\n', '4', '.', '5', '\r', '\n', '$', '1', '\r', '\n', 'M', '\r', '\n']
