import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 Session command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
## Commands that change protocol, suppress replies, or close the socket are
## encoding-only here; `Execute.request!` assumes one RESP2 reply and a reusable connection.
Session := {}.{

	## Construct `AUTH`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/auth/).
	## Parameters (in order): `options_before_password`, `password`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	auth : List(List(U8)), List(U8) -> Command.Command
	auth = |options_before_password, password| {
		Command.from_nonempty_bytes("AUTH", options_before_password.concat([password]))
	}

	## Construct `CLIENT CACHING`.
	## Available since Redis 6.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-caching/).
	## Parameters (in order): `mode`.
	client_caching : List(U8) -> Command.Command
	client_caching = |mode| {
		Command.from_nonempty_bytes("CLIENT", [['C', 'A', 'C', 'H', 'I', 'N', 'G']].concat([mode]))
	}

	## Construct `CLIENT GETNAME`.
	## Available since Redis 2.6.9.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-getname/).
	client_getname : {} -> Command.Command
	client_getname = |_| {
		Command.from_nonempty_bytes("CLIENT", [['G', 'E', 'T', 'N', 'A', 'M', 'E']])
	}

	## Construct `CLIENT GETREDIR`.
	## Available since Redis 6.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-getredir/).
	client_getredir : {} -> Command.Command
	client_getredir = |_| {
		Command.from_nonempty_bytes("CLIENT", [['G', 'E', 'T', 'R', 'E', 'D', 'I', 'R']])
	}

	## Construct `CLIENT ID`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-id/).
	client_id : {} -> Command.Command
	client_id = |_| {
		Command.from_nonempty_bytes("CLIENT", [['I', 'D']])
	}

	## Construct `CLIENT INFO`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-info/).
	client_info : {} -> Command.Command
	client_info = |_| {
		Command.from_nonempty_bytes("CLIENT", [['I', 'N', 'F', 'O']])
	}

	## Construct `CLIENT KILL`.
	## Available since Redis 2.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-kill/).
	## Parameters (in order): `filter`.
	client_kill : { first : List(U8), rest : List(List(U8)) } -> Command.Command
	client_kill = |filter| {
		Command.from_nonempty_bytes("CLIENT", [['K', 'I', 'L', 'L']].concat([filter.first].concat(filter.rest)))
	}

	## Construct `CLIENT LIST`.
	## Available since Redis 2.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-list/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	client_list : List(List(U8)) -> Command.Command
	client_list = |options| {
		Command.from_nonempty_bytes("CLIENT", [['L', 'I', 'S', 'T']].concat(options))
	}

	## Construct `CLIENT NO-EVICT`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-no-evict/).
	## Parameters (in order): `enabled`.
	client_no_evict : List(U8) -> Command.Command
	client_no_evict = |enabled| {
		Command.from_nonempty_bytes("CLIENT", [['N', 'O', '-', 'E', 'V', 'I', 'C', 'T']].concat([enabled]))
	}

	## Construct `CLIENT NO-TOUCH`.
	## Available since Redis 7.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-no-touch/).
	## Parameters (in order): `enabled`.
	client_no_touch : List(U8) -> Command.Command
	client_no_touch = |enabled| {
		Command.from_nonempty_bytes("CLIENT", [['N', 'O', '-', 'T', 'O', 'U', 'C', 'H']].concat([enabled]))
	}

	## Construct `CLIENT PAUSE`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-pause/).
	## Parameters (in order): `timeout`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	client_pause : List(U8), List(List(U8)) -> Command.Command
	client_pause = |timeout, options| {
		Command.from_nonempty_bytes("CLIENT", [['P', 'A', 'U', 'S', 'E']].concat([timeout].concat(options)))
	}

	## Construct `CLIENT REPLY`.
	## Available since Redis 3.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-reply/).
	## Parameters (in order): `action`.
	client_reply : List(U8) -> Command.Command
	client_reply = |action| {
		Command.from_nonempty_bytes("CLIENT", [['R', 'E', 'P', 'L', 'Y']].concat([action]))
	}

	## Construct `CLIENT SETINFO`.
	## Available since Redis 7.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-setinfo/).
	## Parameters (in order): `attr`.
	client_setinfo : { first : List(U8), rest : List(List(U8)) } -> Command.Command
	client_setinfo = |attr| {
		Command.from_nonempty_bytes("CLIENT", [['S', 'E', 'T', 'I', 'N', 'F', 'O']].concat([attr.first].concat(attr.rest)))
	}

	## Construct `CLIENT SETNAME`.
	## Available since Redis 2.6.9.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-setname/).
	## Parameters (in order): `connection_name`.
	client_setname : List(U8) -> Command.Command
	client_setname = |connection_name| {
		Command.from_nonempty_bytes("CLIENT", [['S', 'E', 'T', 'N', 'A', 'M', 'E']].concat([connection_name]))
	}

	## Construct `CLIENT TRACKING`.
	## Available since Redis 6.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-tracking/).
	## Parameters (in order): `status`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	client_tracking : List(U8), List(List(U8)) -> Command.Command
	client_tracking = |status, options| {
		Command.from_nonempty_bytes("CLIENT", [['T', 'R', 'A', 'C', 'K', 'I', 'N', 'G']].concat([status].concat(options)))
	}

	## Construct `CLIENT TRACKINGINFO`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-trackinginfo/).
	client_trackinginfo : {} -> Command.Command
	client_trackinginfo = |_| {
		Command.from_nonempty_bytes("CLIENT", [['T', 'R', 'A', 'C', 'K', 'I', 'N', 'G', 'I', 'N', 'F', 'O']])
	}

	## Construct `CLIENT UNBLOCK`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-unblock/).
	## Parameters (in order): `client_id_2`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	client_unblock : List(U8), List(List(U8)) -> Command.Command
	client_unblock = |client_id_2, options| {
		Command.from_nonempty_bytes("CLIENT", [['U', 'N', 'B', 'L', 'O', 'C', 'K']].concat([client_id_2].concat(options)))
	}

	## Construct `CLIENT UNPAUSE`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/client-unpause/).
	client_unpause : {} -> Command.Command
	client_unpause = |_| {
		Command.from_nonempty_bytes("CLIENT", [['U', 'N', 'P', 'A', 'U', 'S', 'E']])
	}

	## Construct `ECHO`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/echo/).
	## Parameters (in order): `message`.
	echo : List(U8) -> Command.Command
	echo = |message| {
		Command.from_nonempty_bytes("ECHO", [message])
	}

	## Construct `HELLO`.
	## Available since Redis 6.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hello/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	hello : List(List(U8)) -> Command.Command
	hello = |options| {
		Command.from_nonempty_bytes("HELLO", options)
	}

	## Construct `PING`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/ping/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	ping : List(List(U8)) -> Command.Command
	ping = |options| {
		Command.from_nonempty_bytes("PING", options)
	}

	## Construct `QUIT`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/quit/).
	## Deprecated by Redis; retained for catalog completeness.
	quit : {} -> Command.Command
	quit = |_| {
		Command.from_nonempty_bytes("QUIT", [])
	}

	## Construct `RESET`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/reset/).
	reset : {} -> Command.Command
	reset = |_| {
		Command.from_nonempty_bytes("RESET", [])
	}

	## Construct `SELECT`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/select/).
	## Parameters (in order): `index`.
	select : List(U8) -> Command.Command
	select = |index| {
		Command.from_nonempty_bytes("SELECT", [index])
	}
}

expect Command.encode(Session.auth([[0, 1, 255], [0, 2, 255]], [0, 3, 255])) == ['*', '4', '\r', '\n', '$', '4', '\r', '\n', 'A', 'U', 'T', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Session.auth([], [0, 3, 255])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'A', 'U', 'T', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Session.client_caching(['Y', 'E', 'S'])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '7', '\r', '\n', 'C', 'A', 'C', 'H', 'I', 'N', 'G', '\r', '\n', '$', '3', '\r', '\n', 'Y', 'E', 'S', '\r', '\n']

expect Command.encode(Session.client_getname({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '7', '\r', '\n', 'G', 'E', 'T', 'N', 'A', 'M', 'E', '\r', '\n']

expect Command.encode(Session.client_getredir({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '8', '\r', '\n', 'G', 'E', 'T', 'R', 'E', 'D', 'I', 'R', '\r', '\n']

expect Command.encode(Session.client_id({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '2', '\r', '\n', 'I', 'D', '\r', '\n']

expect Command.encode(Session.client_info({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '4', '\r', '\n', 'I', 'N', 'F', 'O', '\r', '\n']

expect Command.encode(Session.client_kill({ first: [0, 1, 255], rest: [] })) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '4', '\r', '\n', 'K', 'I', 'L', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Session.client_list([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '4', '\r', '\n', 'L', 'I', 'S', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Session.client_list([])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '4', '\r', '\n', 'L', 'I', 'S', 'T', '\r', '\n']

expect Command.encode(Session.client_no_evict(['O', 'N'])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '8', '\r', '\n', 'N', 'O', '-', 'E', 'V', 'I', 'C', 'T', '\r', '\n', '$', '2', '\r', '\n', 'O', 'N', '\r', '\n']

expect Command.encode(Session.client_no_touch(['O', 'N'])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '8', '\r', '\n', 'N', 'O', '-', 'T', 'O', 'U', 'C', 'H', '\r', '\n', '$', '2', '\r', '\n', 'O', 'N', '\r', '\n']

expect Command.encode(Session.client_pause(['1'], [[0, 2, 255], [0, 3, 255]])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '5', '\r', '\n', 'P', 'A', 'U', 'S', 'E', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Session.client_pause(['1'], [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '5', '\r', '\n', 'P', 'A', 'U', 'S', 'E', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n']

expect Command.encode(Session.client_reply(['O', 'N'])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '5', '\r', '\n', 'R', 'E', 'P', 'L', 'Y', '\r', '\n', '$', '2', '\r', '\n', 'O', 'N', '\r', '\n']

expect Command.encode(Session.client_setinfo({ first: ['L', 'I', 'B', '-', 'N', 'A', 'M', 'E'], rest: [[0, 1, 255]] })) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '7', '\r', '\n', 'S', 'E', 'T', 'I', 'N', 'F', 'O', '\r', '\n', '$', '8', '\r', '\n', 'L', 'I', 'B', '-', 'N', 'A', 'M', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Session.client_setname([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '7', '\r', '\n', 'S', 'E', 'T', 'N', 'A', 'M', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Session.client_tracking(['O', 'N'], [[0, 1, 255], [0, 2, 255]])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '8', '\r', '\n', 'T', 'R', 'A', 'C', 'K', 'I', 'N', 'G', '\r', '\n', '$', '2', '\r', '\n', 'O', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Session.client_tracking(['O', 'N'], [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '8', '\r', '\n', 'T', 'R', 'A', 'C', 'K', 'I', 'N', 'G', '\r', '\n', '$', '2', '\r', '\n', 'O', 'N', '\r', '\n']

expect Command.encode(Session.client_trackinginfo({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '1', '2', '\r', '\n', 'T', 'R', 'A', 'C', 'K', 'I', 'N', 'G', 'I', 'N', 'F', 'O', '\r', '\n']

expect Command.encode(Session.client_unblock(['1'], [[0, 2, 255], [0, 3, 255]])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '7', '\r', '\n', 'U', 'N', 'B', 'L', 'O', 'C', 'K', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Session.client_unblock(['1'], [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '7', '\r', '\n', 'U', 'N', 'B', 'L', 'O', 'C', 'K', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n']

expect Command.encode(Session.client_unpause({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'C', 'L', 'I', 'E', 'N', 'T', '\r', '\n', '$', '7', '\r', '\n', 'U', 'N', 'P', 'A', 'U', 'S', 'E', '\r', '\n']

expect Command.encode(Session.echo([0, 1, 255])) == ['*', '2', '\r', '\n', '$', '4', '\r', '\n', 'E', 'C', 'H', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Session.hello([[0, 1, 255], [0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '5', '\r', '\n', 'H', 'E', 'L', 'L', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Session.hello([])) == ['*', '1', '\r', '\n', '$', '5', '\r', '\n', 'H', 'E', 'L', 'L', 'O', '\r', '\n']

expect Command.encode(Session.ping([[0, 1, 255], [0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'P', 'I', 'N', 'G', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Session.ping([])) == ['*', '1', '\r', '\n', '$', '4', '\r', '\n', 'P', 'I', 'N', 'G', '\r', '\n']

expect Command.encode(Session.quit({})) == ['*', '1', '\r', '\n', '$', '4', '\r', '\n', 'Q', 'U', 'I', 'T', '\r', '\n']

expect Command.encode(Session.reset({})) == ['*', '1', '\r', '\n', '$', '5', '\r', '\n', 'R', 'E', 'S', 'E', 'T', '\r', '\n']

expect Command.encode(Session.select(['1'])) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'S', 'E', 'L', 'E', 'C', 'T', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n']
