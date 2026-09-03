import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 Transaction command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
## A transaction sequence must remain ordered on one exclusive connection.
## `Execute.batch!` batches writes but does not by itself create a transaction.
Transactions := {}.{

	## Construct `DISCARD`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/discard/).
	discard : {} -> Command.Command
	discard = |_| {
		Command.from_nonempty_bytes("DISCARD", [])
	}

	## Construct `EXEC`.
	## Available since Redis 1.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/exec/).
	exec : {} -> Command.Command
	exec = |_| {
		Command.from_nonempty_bytes("EXEC", [])
	}

	## Construct `MULTI`.
	## Available since Redis 1.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/multi/).
	multi : {} -> Command.Command
	multi = |_| {
		Command.from_nonempty_bytes("MULTI", [])
	}

	## Construct `UNWATCH`.
	## Available since Redis 2.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/unwatch/).
	unwatch : {} -> Command.Command
	unwatch = |_| {
		Command.from_nonempty_bytes("UNWATCH", [])
	}

	## Construct `WATCH`.
	## Available since Redis 2.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/watch/).
	## Parameters (in order): `first_key`, `other_keys`.
	watch : List(U8), List(List(U8)) -> Command.Command
	watch = |first_key, other_keys| {
		catalog_keys = [first_key].concat(other_keys)
		Command.from_nonempty_bytes("WATCH", catalog_keys)
	}
}

expect Command.encode(Transactions.discard({})) == ['*', '1', '\r', '\n', '$', '7', '\r', '\n', 'D', 'I', 'S', 'C', 'A', 'R', 'D', '\r', '\n']

expect Command.encode(Transactions.exec({})) == ['*', '1', '\r', '\n', '$', '4', '\r', '\n', 'E', 'X', 'E', 'C', '\r', '\n']

expect Command.encode(Transactions.multi({})) == ['*', '1', '\r', '\n', '$', '5', '\r', '\n', 'M', 'U', 'L', 'T', 'I', '\r', '\n']

expect Command.encode(Transactions.unwatch({})) == ['*', '1', '\r', '\n', '$', '7', '\r', '\n', 'U', 'N', 'W', 'A', 'T', 'C', 'H', '\r', '\n']

expect Command.encode(Transactions.watch([0, 1, 255], [[0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'W', 'A', 'T', 'C', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Transactions.watch([0, 1, 255], [])) == ['*', '2', '\r', '\n', '$', '5', '\r', '\n', 'W', 'A', 'T', 'C', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']
