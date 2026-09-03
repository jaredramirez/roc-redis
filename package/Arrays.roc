import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 Array command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
Arrays := {}.{

	## Construct `ARCOUNT`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/arcount/).
	## Parameters (in order): `key`.
	arcount : List(U8) -> Command.Command
	arcount = |key| {
		Command.from_nonempty_bytes("ARCOUNT", [key])
	}

	## Construct `ARDEL`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/ardel/).
	## Parameters (in order): `key`, `first_index`, `other_indices`.
	ardel : List(U8), List(U8), List(List(U8)) -> Command.Command
	ardel = |key, first_index, other_indices| {
		catalog_indices = [first_index].concat(other_indices)
		Command.from_nonempty_bytes("ARDEL", [key].concat(catalog_indices))
	}

	## Construct `ARDELRANGE`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/ardelrange/).
	## Parameters (in order): `key`, `first_range`, `other_ranges`.
	ardelrange : List(U8), { start : List(U8), end : List(U8) }, List({ start : List(U8), end : List(U8) }) -> Command.Command
	ardelrange = |key, first_range, other_ranges| {
		catalog_ranges = [first_range].concat(other_ranges)
		Command.from_nonempty_bytes("ARDELRANGE", [key].concat(catalog_ranges.join_map(|item| [item.start, item.end])))
	}

	## Construct `ARGET`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/arget/).
	## Parameters (in order): `key`, `index`.
	arget : List(U8), List(U8) -> Command.Command
	arget = |key, index| {
		Command.from_nonempty_bytes("ARGET", [key, index])
	}

	## Construct `ARGETRANGE`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/argetrange/).
	## Parameters (in order): `key`, `start`, `end`.
	argetrange : List(U8), List(U8), List(U8) -> Command.Command
	argetrange = |key, start, end| {
		Command.from_nonempty_bytes("ARGETRANGE", [key, start, end])
	}

	## Construct `ARGREP`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/argrep/).
	## Parameters (in order): `key`, `start`, `end`, `first_predicate`, `other_predicates`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	argrep : List(U8), List(U8), List(U8), { operator : List(U8), operand : List(U8) }, List({ operator : List(U8), operand : List(U8) }), List(List(U8)) -> Command.Command
	argrep = |key, start, end, first_predicate, other_predicates, options| {
		catalog_predicates = [first_predicate].concat(other_predicates)
		Command.from_nonempty_bytes("ARGREP", [key, start, end].concat(catalog_predicates.join_map(|item| [item.operator, item.operand])).concat(options))
	}

	## Construct `ARINFO`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/arinfo/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	arinfo : List(U8), List(List(U8)) -> Command.Command
	arinfo = |key, options| {
		Command.from_nonempty_bytes("ARINFO", [key].concat(options))
	}

	## Construct `ARINSERT`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/arinsert/).
	## Parameters (in order): `key`, `first_value`, `other_values`.
	arinsert : List(U8), List(U8), List(List(U8)) -> Command.Command
	arinsert = |key, first_value, other_values| {
		catalog_values = [first_value].concat(other_values)
		Command.from_nonempty_bytes("ARINSERT", [key].concat(catalog_values))
	}

	## Construct `ARLASTITEMS`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/arlastitems/).
	## Parameters (in order): `key`, `count`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	arlastitems : List(U8), List(U8), List(List(U8)) -> Command.Command
	arlastitems = |key, count, options| {
		Command.from_nonempty_bytes("ARLASTITEMS", [key, count].concat(options))
	}

	## Construct `ARLEN`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/arlen/).
	## Parameters (in order): `key`.
	arlen : List(U8) -> Command.Command
	arlen = |key| {
		Command.from_nonempty_bytes("ARLEN", [key])
	}

	## Construct `ARMGET`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/armget/).
	## Parameters (in order): `key`, `first_index`, `other_indices`.
	armget : List(U8), List(U8), List(List(U8)) -> Command.Command
	armget = |key, first_index, other_indices| {
		catalog_indices = [first_index].concat(other_indices)
		Command.from_nonempty_bytes("ARMGET", [key].concat(catalog_indices))
	}

	## Construct `ARMSET`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/armset/).
	## Parameters (in order): `key`, `first_entry`, `other_entries`.
	armset : List(U8), { index : List(U8), value : List(U8) }, List({ index : List(U8), value : List(U8) }) -> Command.Command
	armset = |key, first_entry, other_entries| {
		catalog_entries = [first_entry].concat(other_entries)
		Command.from_nonempty_bytes("ARMSET", [key].concat(catalog_entries.join_map(|item| [item.index, item.value])))
	}

	## Construct `ARNEXT`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/arnext/).
	## Parameters (in order): `key`.
	arnext : List(U8) -> Command.Command
	arnext = |key| {
		Command.from_nonempty_bytes("ARNEXT", [key])
	}

	## Construct `AROP`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/arop/).
	## Parameters (in order): `key`, `start`, `end`, `operation`.
	arop : List(U8), List(U8), List(U8), { first : List(U8), rest : List(List(U8)) } -> Command.Command
	arop = |key, start, end, operation| {
		Command.from_nonempty_bytes("AROP", [key, start, end].concat([operation.first].concat(operation.rest)))
	}

	## Construct `ARRING`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/arring/).
	## Parameters (in order): `key`, `size`, `first_value`, `other_values`.
	arring : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	arring = |key, size, first_value, other_values| {
		catalog_values = [first_value].concat(other_values)
		Command.from_nonempty_bytes("ARRING", [key, size].concat(catalog_values))
	}

	## Construct `ARSCAN`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/arscan/).
	## Parameters (in order): `key`, `start`, `end`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	arscan : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	arscan = |key, start, end, options| {
		Command.from_nonempty_bytes("ARSCAN", [key, start, end].concat(options))
	}

	## Construct `ARSEEK`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/arseek/).
	## Parameters (in order): `key`, `index`.
	arseek : List(U8), List(U8) -> Command.Command
	arseek = |key, index| {
		Command.from_nonempty_bytes("ARSEEK", [key, index])
	}

	## Construct `ARSET`.
	## Available since Redis 8.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/arset/).
	## Parameters (in order): `key`, `index`, `first_value`, `other_values`.
	arset : List(U8), List(U8), List(U8), List(List(U8)) -> Command.Command
	arset = |key, index, first_value, other_values| {
		catalog_values = [first_value].concat(other_values)
		Command.from_nonempty_bytes("ARSET", [key, index].concat(catalog_values))
	}
}

expect Command.encode(Arrays.arcount([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'A', 'R', 'C', 'O', 'U', 'N', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Arrays.ardel([0, 1, 255], ['2'], [['3']])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'A', 'R', 'D', 'E', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n']

expect Command.encode(Arrays.ardel([0, 1, 255], ['2'], [])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'A', 'R', 'D', 'E', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Arrays.ardelrange([0, 1, 255], { start: ['2'], end: ['3'] }, [{ start: ['4'], end: ['5'] }])) == ['*', '6', '\r', '\n', '$', '1', '0', '\r', '\n', 'A', 'R', 'D', 'E', 'L', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n', '$', '1', '\r', '\n', '4', '\r', '\n', '$', '1', '\r', '\n', '5', '\r', '\n']

expect Command.encode(Arrays.ardelrange([0, 1, 255], { start: ['2'], end: ['3'] }, [])) == ['*', '4', '\r', '\n', '$', '1', '0', '\r', '\n', 'A', 'R', 'D', 'E', 'L', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n']

expect Command.encode(Arrays.arget([0, 1, 255], ['2'])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'A', 'R', 'G', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Arrays.argetrange([0, 1, 255], ['2'], ['3'])) == ['*', '4', '\r', '\n', '$', '1', '0', '\r', '\n', 'A', 'R', 'G', 'E', 'T', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n']

expect Command.encode(Arrays.argrep([0, 1, 255], [0, 2, 255], [0, 3, 255], { operator: ['E', 'X', 'A', 'C', 'T'], operand: [0, 4, 255] }, [{ operator: ['R', 'E'], operand: [0, 5, 255] }], [[0, 6, 255], [0, 7, 255]])) == ['*', '1', '0', '\r', '\n', '$', '6', '\r', '\n', 'A', 'R', 'G', 'R', 'E', 'P', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '5', '\r', '\n', 'E', 'X', 'A', 'C', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '2', '\r', '\n', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 6, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 7, 255, '\r', '\n']

expect Command.encode(Arrays.argrep([0, 1, 255], [0, 2, 255], [0, 3, 255], { operator: ['E', 'X', 'A', 'C', 'T'], operand: [0, 4, 255] }, [], [])) == ['*', '6', '\r', '\n', '$', '6', '\r', '\n', 'A', 'R', 'G', 'R', 'E', 'P', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '5', '\r', '\n', 'E', 'X', 'A', 'C', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Arrays.arinfo([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'A', 'R', 'I', 'N', 'F', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Arrays.arinfo([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'A', 'R', 'I', 'N', 'F', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Arrays.arinsert([0, 1, 255], [0, 2, 255], [[0, 3, 255]])) == ['*', '4', '\r', '\n', '$', '8', '\r', '\n', 'A', 'R', 'I', 'N', 'S', 'E', 'R', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Arrays.arinsert([0, 1, 255], [0, 2, 255], [])) == ['*', '3', '\r', '\n', '$', '8', '\r', '\n', 'A', 'R', 'I', 'N', 'S', 'E', 'R', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Arrays.arlastitems([0, 1, 255], ['2'], [[0, 3, 255], [0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '1', '1', '\r', '\n', 'A', 'R', 'L', 'A', 'S', 'T', 'I', 'T', 'E', 'M', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Arrays.arlastitems([0, 1, 255], ['2'], [])) == ['*', '3', '\r', '\n', '$', '1', '1', '\r', '\n', 'A', 'R', 'L', 'A', 'S', 'T', 'I', 'T', 'E', 'M', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Arrays.arlen([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '5', '\r', '\n', 'A', 'R', 'L', 'E', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Arrays.armget([0, 1, 255], ['2'], [['3']])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'A', 'R', 'M', 'G', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n']

expect Command.encode(Arrays.armget([0, 1, 255], ['2'], [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'A', 'R', 'M', 'G', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Arrays.armset([0, 1, 255], { index: ['2'], value: [0, 3, 255] }, [{ index: ['4'], value: [0, 5, 255] }])) == ['*', '6', '\r', '\n', '$', '6', '\r', '\n', 'A', 'R', 'M', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '1', '\r', '\n', '4', '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Arrays.armset([0, 1, 255], { index: ['2'], value: [0, 3, 255] }, [])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'A', 'R', 'M', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Arrays.arnext([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'A', 'R', 'N', 'E', 'X', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Arrays.arop([0, 1, 255], ['2'], ['3'], { first: ['S', 'U', 'M'], rest: [] })) == ['*', '5', '\r', '\n', '$', '4', '\r', '\n', 'A', 'R', 'O', 'P', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n', '$', '3', '\r', '\n', 'S', 'U', 'M', '\r', '\n']

expect Command.encode(Arrays.arring([0, 1, 255], ['2'], [0, 3, 255], [[0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'A', 'R', 'R', 'I', 'N', 'G', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Arrays.arring([0, 1, 255], ['2'], [0, 3, 255], [])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'A', 'R', 'R', 'I', 'N', 'G', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Arrays.arscan([0, 1, 255], ['2'], ['3'], [[0, 4, 255], [0, 5, 255]])) == ['*', '6', '\r', '\n', '$', '6', '\r', '\n', 'A', 'R', 'S', 'C', 'A', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Arrays.arscan([0, 1, 255], ['2'], ['3'], [])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'A', 'R', 'S', 'C', 'A', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n']

expect Command.encode(Arrays.arseek([0, 1, 255], ['2'])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'A', 'R', 'S', 'E', 'E', 'K', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Arrays.arset([0, 1, 255], ['2'], [0, 3, 255], [[0, 4, 255]])) == ['*', '5', '\r', '\n', '$', '5', '\r', '\n', 'A', 'R', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Arrays.arset([0, 1, 255], ['2'], [0, 3, 255], [])) == ['*', '4', '\r', '\n', '$', '5', '\r', '\n', 'A', 'R', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']
