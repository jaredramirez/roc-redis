import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 Scripting command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
Scripting := {}.{

	## Construct `EVAL`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/eval/).
	## Parameters (in order): `script`, `keys`, `args`.
	eval : List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	eval = |script, keys, args| {
		Command.from_nonempty_bytes("EVAL", [script].concat([keys.len().to_str().to_utf8()].concat(keys)).concat(args))
	}

	## Construct `EVAL_RO`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/eval_ro/).
	## Parameters (in order): `script`, `keys`, `args`.
	eval_ro : List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	eval_ro = |script, keys, args| {
		Command.from_nonempty_bytes("EVAL_RO", [script].concat([keys.len().to_str().to_utf8()].concat(keys)).concat(args))
	}

	## Construct `EVALSHA`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/evalsha/).
	## Parameters (in order): `sha1`, `keys`, `args`.
	evalsha : List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	evalsha = |sha1, keys, args| {
		Command.from_nonempty_bytes("EVALSHA", [sha1].concat([keys.len().to_str().to_utf8()].concat(keys)).concat(args))
	}

	## Construct `EVALSHA_RO`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/evalsha_ro/).
	## Parameters (in order): `sha1`, `keys`, `args`.
	evalsha_ro : List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	evalsha_ro = |sha1, keys, args| {
		Command.from_nonempty_bytes("EVALSHA_RO", [sha1].concat([keys.len().to_str().to_utf8()].concat(keys)).concat(args))
	}

	## Construct `FCALL`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/fcall/).
	## Parameters (in order): `function`, `keys`, `args`.
	fcall : List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	fcall = |function, keys, args| {
		Command.from_nonempty_bytes("FCALL", [function].concat([keys.len().to_str().to_utf8()].concat(keys)).concat(args))
	}

	## Construct `FCALL_RO`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/fcall_ro/).
	## Parameters (in order): `function`, `keys`, `args`.
	fcall_ro : List(U8), List(List(U8)), List(List(U8)) -> Command.Command
	fcall_ro = |function, keys, args| {
		Command.from_nonempty_bytes("FCALL_RO", [function].concat([keys.len().to_str().to_utf8()].concat(keys)).concat(args))
	}

	## Construct `FUNCTION DELETE`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/function-delete/).
	## Parameters (in order): `library_name`.
	function_delete : List(U8) -> Command.Command
	function_delete = |library_name| {
		Command.from_nonempty_bytes("FUNCTION", [['D', 'E', 'L', 'E', 'T', 'E']].concat([library_name]))
	}

	## Construct `FUNCTION DUMP`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/function-dump/).
	function_dump : () -> Command.Command
	function_dump = || {
		Command.from_nonempty_bytes("FUNCTION", [['D', 'U', 'M', 'P']])
	}

	## Construct `FUNCTION FLUSH`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/function-flush/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	function_flush : List(List(U8)) -> Command.Command
	function_flush = |options| {
		Command.from_nonempty_bytes("FUNCTION", [['F', 'L', 'U', 'S', 'H']].concat(options))
	}

	## Construct `FUNCTION KILL`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/function-kill/).
	function_kill : () -> Command.Command
	function_kill = || {
		Command.from_nonempty_bytes("FUNCTION", [['K', 'I', 'L', 'L']])
	}

	## Construct `FUNCTION LIST`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/function-list/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	function_list : List(List(U8)) -> Command.Command
	function_list = |options| {
		Command.from_nonempty_bytes("FUNCTION", [['L', 'I', 'S', 'T']].concat(options))
	}

	## Construct `FUNCTION LOAD`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/function-load/).
	## Parameters (in order): `options_before_function_code`, `function_code`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	function_load : List(List(U8)), List(U8) -> Command.Command
	function_load = |options_before_function_code, function_code| {
		Command.from_nonempty_bytes("FUNCTION", [['L', 'O', 'A', 'D']].concat(options_before_function_code.concat([function_code])))
	}

	## Construct `FUNCTION RESTORE`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/function-restore/).
	## Parameters (in order): `serialized_value`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	function_restore : List(U8), List(List(U8)) -> Command.Command
	function_restore = |serialized_value, options| {
		Command.from_nonempty_bytes("FUNCTION", [['R', 'E', 'S', 'T', 'O', 'R', 'E']].concat([serialized_value].concat(options)))
	}

	## Construct `FUNCTION STATS`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/function-stats/).
	function_stats : () -> Command.Command
	function_stats = || {
		Command.from_nonempty_bytes("FUNCTION", [['S', 'T', 'A', 'T', 'S']])
	}

	## Construct `SCRIPT DEBUG`.
	## Available since Redis 3.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/script-debug/).
	## Parameters (in order): `mode`.
	script_debug : List(U8) -> Command.Command
	script_debug = |mode| {
		Command.from_nonempty_bytes("SCRIPT", [['D', 'E', 'B', 'U', 'G']].concat([mode]))
	}

	## Construct `SCRIPT EXISTS`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/script-exists/).
	## Parameters (in order): `first_sha1`, `other_sha1s`.
	script_exists : List(U8), List(List(U8)) -> Command.Command
	script_exists = |first_sha1, other_sha1s| {
		catalog_sha1s = [first_sha1].concat(other_sha1s)
		Command.from_nonempty_bytes("SCRIPT", [['E', 'X', 'I', 'S', 'T', 'S']].concat(catalog_sha1s))
	}

	## Construct `SCRIPT FLUSH`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/script-flush/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	script_flush : List(List(U8)) -> Command.Command
	script_flush = |options| {
		Command.from_nonempty_bytes("SCRIPT", [['F', 'L', 'U', 'S', 'H']].concat(options))
	}

	## Construct `SCRIPT KILL`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/script-kill/).
	script_kill : () -> Command.Command
	script_kill = || {
		Command.from_nonempty_bytes("SCRIPT", [['K', 'I', 'L', 'L']])
	}

	## Construct `SCRIPT LOAD`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/script-load/).
	## Parameters (in order): `script`.
	script_load : List(U8) -> Command.Command
	script_load = |script| {
		Command.from_nonempty_bytes("SCRIPT", [['L', 'O', 'A', 'D']].concat([script]))
	}
}

expect Command.encode(Scripting.eval([0, 1, 255], [[0, 2, 255], [0, 3, 255]], [[0, 4, 255], [0, 5, 255]])) == ['*', '7', '\r', '\n', '$', '4', '\r', '\n', 'E', 'V', 'A', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Scripting.eval([0, 1, 255], [], [])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'E', 'V', 'A', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '0', '\r', '\n']

expect Command.encode(Scripting.eval_ro([0, 1, 255], [[0, 2, 255], [0, 3, 255]], [[0, 4, 255], [0, 5, 255]])) == ['*', '7', '\r', '\n', '$', '7', '\r', '\n', 'E', 'V', 'A', 'L', '_', 'R', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Scripting.eval_ro([0, 1, 255], [], [])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'E', 'V', 'A', 'L', '_', 'R', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '0', '\r', '\n']

expect Command.encode(Scripting.evalsha([0, 1, 255], [[0, 2, 255], [0, 3, 255]], [[0, 4, 255], [0, 5, 255]])) == ['*', '7', '\r', '\n', '$', '7', '\r', '\n', 'E', 'V', 'A', 'L', 'S', 'H', 'A', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Scripting.evalsha([0, 1, 255], [], [])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'E', 'V', 'A', 'L', 'S', 'H', 'A', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '0', '\r', '\n']

expect Command.encode(Scripting.evalsha_ro([0, 1, 255], [[0, 2, 255], [0, 3, 255]], [[0, 4, 255], [0, 5, 255]])) == ['*', '7', '\r', '\n', '$', '1', '0', '\r', '\n', 'E', 'V', 'A', 'L', 'S', 'H', 'A', '_', 'R', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Scripting.evalsha_ro([0, 1, 255], [], [])) == ['*', '3', '\r', '\n', '$', '1', '0', '\r', '\n', 'E', 'V', 'A', 'L', 'S', 'H', 'A', '_', 'R', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '0', '\r', '\n']

expect Command.encode(Scripting.fcall([0, 1, 255], [[0, 2, 255], [0, 3, 255]], [[0, 4, 255], [0, 5, 255]])) == ['*', '7', '\r', '\n', '$', '5', '\r', '\n', 'F', 'C', 'A', 'L', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Scripting.fcall([0, 1, 255], [], [])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'F', 'C', 'A', 'L', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '0', '\r', '\n']

expect Command.encode(Scripting.fcall_ro([0, 1, 255], [[0, 2, 255], [0, 3, 255]], [[0, 4, 255], [0, 5, 255]])) == ['*', '7', '\r', '\n', '$', '8', '\r', '\n', 'F', 'C', 'A', 'L', 'L', '_', 'R', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 5, 255, '\r', '\n']

expect Command.encode(Scripting.fcall_ro([0, 1, 255], [], [])) == ['*', '3', '\r', '\n', '$', '8', '\r', '\n', 'F', 'C', 'A', 'L', 'L', '_', 'R', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '0', '\r', '\n']

expect Command.encode(Scripting.function_delete([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '8', '\r', '\n', 'F', 'U', 'N', 'C', 'T', 'I', 'O', 'N', '\r', '\n', '$', '6', '\r', '\n', 'D', 'E', 'L', 'E', 'T', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Scripting.function_dump()) == ['*', '2', '\r', '\n', '$', '8', '\r', '\n', 'F', 'U', 'N', 'C', 'T', 'I', 'O', 'N', '\r', '\n', '$', '4', '\r', '\n', 'D', 'U', 'M', 'P', '\r', '\n']

expect Command.encode(Scripting.function_flush([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '8', '\r', '\n', 'F', 'U', 'N', 'C', 'T', 'I', 'O', 'N', '\r', '\n', '$', '5', '\r', '\n', 'F', 'L', 'U', 'S', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Scripting.function_flush([])) == ['*', '2', '\r', '\n', '$', '8', '\r', '\n', 'F', 'U', 'N', 'C', 'T', 'I', 'O', 'N', '\r', '\n', '$', '5', '\r', '\n', 'F', 'L', 'U', 'S', 'H', '\r', '\n']

expect Command.encode(Scripting.function_kill()) == ['*', '2', '\r', '\n', '$', '8', '\r', '\n', 'F', 'U', 'N', 'C', 'T', 'I', 'O', 'N', '\r', '\n', '$', '4', '\r', '\n', 'K', 'I', 'L', 'L', '\r', '\n']

expect Command.encode(Scripting.function_list([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '8', '\r', '\n', 'F', 'U', 'N', 'C', 'T', 'I', 'O', 'N', '\r', '\n', '$', '4', '\r', '\n', 'L', 'I', 'S', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Scripting.function_list([])) == ['*', '2', '\r', '\n', '$', '8', '\r', '\n', 'F', 'U', 'N', 'C', 'T', 'I', 'O', 'N', '\r', '\n', '$', '4', '\r', '\n', 'L', 'I', 'S', 'T', '\r', '\n']

expect Command.encode(Scripting.function_load([[0, 1, 255], [0, 2, 255]], [0, 3, 255])) == ['*', '5', '\r', '\n', '$', '8', '\r', '\n', 'F', 'U', 'N', 'C', 'T', 'I', 'O', 'N', '\r', '\n', '$', '4', '\r', '\n', 'L', 'O', 'A', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Scripting.function_load([], [0, 3, 255])) == ['*', '3', '\r', '\n', '$', '8', '\r', '\n', 'F', 'U', 'N', 'C', 'T', 'I', 'O', 'N', '\r', '\n', '$', '4', '\r', '\n', 'L', 'O', 'A', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Scripting.function_restore([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '5', '\r', '\n', '$', '8', '\r', '\n', 'F', 'U', 'N', 'C', 'T', 'I', 'O', 'N', '\r', '\n', '$', '7', '\r', '\n', 'R', 'E', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Scripting.function_restore([0, 1, 255], [])) == ['*', '3', '\r', '\n', '$', '8', '\r', '\n', 'F', 'U', 'N', 'C', 'T', 'I', 'O', 'N', '\r', '\n', '$', '7', '\r', '\n', 'R', 'E', 'S', 'T', 'O', 'R', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Scripting.function_stats()) == ['*', '2', '\r', '\n', '$', '8', '\r', '\n', 'F', 'U', 'N', 'C', 'T', 'I', 'O', 'N', '\r', '\n', '$', '5', '\r', '\n', 'S', 'T', 'A', 'T', 'S', '\r', '\n']

expect Command.encode(Scripting.script_debug(['Y', 'E', 'S'])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'S', 'C', 'R', 'I', 'P', 'T', '\r', '\n', '$', '5', '\r', '\n', 'D', 'E', 'B', 'U', 'G', '\r', '\n', '$', '3', '\r', '\n', 'Y', 'E', 'S', '\r', '\n']

expect Command.encode(Scripting.script_exists([0, 1, 255], [[0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'S', 'C', 'R', 'I', 'P', 'T', '\r', '\n', '$', '6', '\r', '\n', 'E', 'X', 'I', 'S', 'T', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Scripting.script_exists([0, 1, 255], [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'S', 'C', 'R', 'I', 'P', 'T', '\r', '\n', '$', '6', '\r', '\n', 'E', 'X', 'I', 'S', 'T', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Scripting.script_flush([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'S', 'C', 'R', 'I', 'P', 'T', '\r', '\n', '$', '5', '\r', '\n', 'F', 'L', 'U', 'S', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Scripting.script_flush([])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'S', 'C', 'R', 'I', 'P', 'T', '\r', '\n', '$', '5', '\r', '\n', 'F', 'L', 'U', 'S', 'H', '\r', '\n']

expect Command.encode(Scripting.script_kill()) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'S', 'C', 'R', 'I', 'P', 'T', '\r', '\n', '$', '4', '\r', '\n', 'K', 'I', 'L', 'L', '\r', '\n']

expect Command.encode(Scripting.script_load([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'S', 'C', 'R', 'I', 'P', 'T', '\r', '\n', '$', '4', '\r', '\n', 'L', 'O', 'A', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']
