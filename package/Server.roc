import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 Server command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
## `MONITOR` and commands that close the server or connection are encoding-only
## here and require application-specific transport lifecycle handling.
Server := {}.{

	## Construct `ACL CAT`.
	## Available since Redis 6.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/acl-cat/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	acl_cat : List(List(U8)) -> Command.Command
	acl_cat = |options| {
		Command.from_nonempty_bytes("ACL", [['C', 'A', 'T']].concat(options))
	}

	## Construct `ACL DELUSER`.
	## Available since Redis 6.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/acl-deluser/).
	## Parameters (in order): `first_username`, `other_usernames`.
	acl_deluser : List(U8), List(List(U8)) -> Command.Command
	acl_deluser = |first_username, other_usernames| {
		catalog_usernames = [first_username].concat(other_usernames)
		Command.from_nonempty_bytes("ACL", [['D', 'E', 'L', 'U', 'S', 'E', 'R']].concat(catalog_usernames))
	}

	## Construct `ACL DRYRUN`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/acl-dryrun/).
	## Parameters (in order): `username`, `command_2`, `args`.
	acl_dryrun : List(U8), List(U8), List(List(U8)) -> Command.Command
	acl_dryrun = |username, command_2, args| {
		Command.from_nonempty_bytes("ACL", [['D', 'R', 'Y', 'R', 'U', 'N']].concat([username, command_2].concat(args)))
	}

	## Construct `ACL GENPASS`.
	## Available since Redis 6.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/acl-genpass/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	acl_genpass : List(List(U8)) -> Command.Command
	acl_genpass = |options| {
		Command.from_nonempty_bytes("ACL", [['G', 'E', 'N', 'P', 'A', 'S', 'S']].concat(options))
	}

	## Construct `ACL GETUSER`.
	## Available since Redis 6.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/acl-getuser/).
	## Parameters (in order): `username`.
	acl_getuser : List(U8) -> Command.Command
	acl_getuser = |username| {
		Command.from_nonempty_bytes("ACL", [['G', 'E', 'T', 'U', 'S', 'E', 'R']].concat([username]))
	}

	## Construct `ACL LIST`.
	## Available since Redis 6.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/acl-list/).
	acl_list : {} -> Command.Command
	acl_list = |_| {
		Command.from_nonempty_bytes("ACL", [['L', 'I', 'S', 'T']])
	}

	## Construct `ACL LOAD`.
	## Available since Redis 6.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/acl-load/).
	acl_load : {} -> Command.Command
	acl_load = |_| {
		Command.from_nonempty_bytes("ACL", [['L', 'O', 'A', 'D']])
	}

	## Construct `ACL LOG`.
	## Available since Redis 6.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/acl-log/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	acl_log : List(List(U8)) -> Command.Command
	acl_log = |options| {
		Command.from_nonempty_bytes("ACL", [['L', 'O', 'G']].concat(options))
	}

	## Construct `ACL SAVE`.
	## Available since Redis 6.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/acl-save/).
	acl_save : {} -> Command.Command
	acl_save = |_| {
		Command.from_nonempty_bytes("ACL", [['S', 'A', 'V', 'E']])
	}

	## Construct `ACL SETUSER`.
	## Available since Redis 6.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/acl-setuser/).
	## Parameters (in order): `username`, `rules`.
	acl_setuser : List(U8), List(List(U8)) -> Command.Command
	acl_setuser = |username, rules| {
		Command.from_nonempty_bytes("ACL", [['S', 'E', 'T', 'U', 'S', 'E', 'R']].concat([username].concat(rules)))
	}

	## Construct `ACL USERS`.
	## Available since Redis 6.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/acl-users/).
	acl_users : {} -> Command.Command
	acl_users = |_| {
		Command.from_nonempty_bytes("ACL", [['U', 'S', 'E', 'R', 'S']])
	}

	## Construct `ACL WHOAMI`.
	## Available since Redis 6.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/acl-whoami/).
	acl_whoami : {} -> Command.Command
	acl_whoami = |_| {
		Command.from_nonempty_bytes("ACL", [['W', 'H', 'O', 'A', 'M', 'I']])
	}

	## Construct `BACKUP ABORT`.
	## Available since Redis 8.10.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/backup-abort/).
	backup_abort : {} -> Command.Command
	backup_abort = |_| {
		Command.from_nonempty_bytes("BACKUP", [['A', 'B', 'O', 'R', 'T']])
	}

	## Construct `BACKUP CLEANUP`.
	## Available since Redis 8.10.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/backup-cleanup/).
	backup_cleanup : {} -> Command.Command
	backup_cleanup = |_| {
		Command.from_nonempty_bytes("BACKUP", [['C', 'L', 'E', 'A', 'N', 'U', 'P']])
	}

	## Construct `BACKUP LIST`.
	## Available since Redis 8.10.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/backup-list/).
	backup_list : {} -> Command.Command
	backup_list = |_| {
		Command.from_nonempty_bytes("BACKUP", [['L', 'I', 'S', 'T']])
	}

	## Construct `BACKUP SEAL`.
	## Available since Redis 8.10.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/backup-seal/).
	backup_seal : {} -> Command.Command
	backup_seal = |_| {
		Command.from_nonempty_bytes("BACKUP", [['S', 'E', 'A', 'L']])
	}

	## Construct `BACKUP START`.
	## Available since Redis 8.10.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/backup-start/).
	backup_start : {} -> Command.Command
	backup_start = |_| {
		Command.from_nonempty_bytes("BACKUP", [['S', 'T', 'A', 'R', 'T']])
	}

	## Construct `BACKUP STATUS`.
	## Available since Redis 8.10.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/backup-status/).
	backup_status : {} -> Command.Command
	backup_status = |_| {
		Command.from_nonempty_bytes("BACKUP", [['S', 'T', 'A', 'T', 'U', 'S']])
	}

	## Construct `BGREWRITEAOF`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/bgrewriteaof/).
	bgrewriteaof : {} -> Command.Command
	bgrewriteaof = |_| {
		Command.from_nonempty_bytes("BGREWRITEAOF", [])
	}

	## Construct `BGSAVE`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/bgsave/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	bgsave : List(List(U8)) -> Command.Command
	bgsave = |options| {
		Command.from_nonempty_bytes("BGSAVE", options)
	}

	## Construct `COMMAND`.
	## Available since Redis 2.8.13.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/command/).
	command : {} -> Command.Command
	command = |_| {
		Command.from_nonempty_bytes("COMMAND", [])
	}

	## Construct `COMMAND COUNT`.
	## Available since Redis 2.8.13.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/command-count/).
	command_count : {} -> Command.Command
	command_count = |_| {
		Command.from_nonempty_bytes("COMMAND", [['C', 'O', 'U', 'N', 'T']])
	}

	## Construct `COMMAND DOCS`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/command-docs/).
	## Parameters (in order): `command_names`.
	command_docs : List(List(U8)) -> Command.Command
	command_docs = |command_names| {
		Command.from_nonempty_bytes("COMMAND", [['D', 'O', 'C', 'S']].concat(command_names))
	}

	## Construct `COMMAND GETKEYS`.
	## Available since Redis 2.8.13.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/command-getkeys/).
	## Parameters (in order): `command_2`, `args`.
	command_getkeys : List(U8), List(List(U8)) -> Command.Command
	command_getkeys = |command_2, args| {
		Command.from_nonempty_bytes("COMMAND", [['G', 'E', 'T', 'K', 'E', 'Y', 'S']].concat([command_2].concat(args)))
	}

	## Construct `COMMAND GETKEYSANDFLAGS`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/command-getkeysandflags/).
	## Parameters (in order): `command_2`, `args`.
	command_getkeysandflags : List(U8), List(List(U8)) -> Command.Command
	command_getkeysandflags = |command_2, args| {
		Command.from_nonempty_bytes("COMMAND", [['G', 'E', 'T', 'K', 'E', 'Y', 'S', 'A', 'N', 'D', 'F', 'L', 'A', 'G', 'S']].concat([command_2].concat(args)))
	}

	## Construct `COMMAND INFO`.
	## Available since Redis 2.8.13.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/command-info/).
	## Parameters (in order): `command_names`.
	command_info : List(List(U8)) -> Command.Command
	command_info = |command_names| {
		Command.from_nonempty_bytes("COMMAND", [['I', 'N', 'F', 'O']].concat(command_names))
	}

	## Construct `COMMAND LIST`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/command-list/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	command_list : List(List(U8)) -> Command.Command
	command_list = |options| {
		Command.from_nonempty_bytes("COMMAND", [['L', 'I', 'S', 'T']].concat(options))
	}

	## Construct `CONFIG GET`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/config-get/).
	## Parameters (in order): `first_parameter`, `other_parameters`.
	config_get : List(U8), List(List(U8)) -> Command.Command
	config_get = |first_parameter, other_parameters| {
		catalog_parameters = [first_parameter].concat(other_parameters)
		Command.from_nonempty_bytes("CONFIG", [['G', 'E', 'T']].concat(catalog_parameters))
	}

	## Construct `CONFIG RESETSTAT`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/config-resetstat/).
	config_resetstat : {} -> Command.Command
	config_resetstat = |_| {
		Command.from_nonempty_bytes("CONFIG", [['R', 'E', 'S', 'E', 'T', 'S', 'T', 'A', 'T']])
	}

	## Construct `CONFIG REWRITE`.
	## Available since Redis 2.8.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/config-rewrite/).
	config_rewrite : {} -> Command.Command
	config_rewrite = |_| {
		Command.from_nonempty_bytes("CONFIG", [['R', 'E', 'W', 'R', 'I', 'T', 'E']])
	}

	## Construct `CONFIG SET`.
	## Available since Redis 2.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/config-set/).
	## Parameters (in order): `first_entry`, `other_entries`.
	config_set : { parameter : List(U8), value : List(U8) }, List({ parameter : List(U8), value : List(U8) }) -> Command.Command
	config_set = |first_entry, other_entries| {
		catalog_entries = [first_entry].concat(other_entries)
		Command.from_nonempty_bytes("CONFIG", [['S', 'E', 'T']].concat(catalog_entries.join_map(|item| [item.parameter, item.value])))
	}

	## Construct `DBSIZE`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/dbsize/).
	dbsize : {} -> Command.Command
	dbsize = |_| {
		Command.from_nonempty_bytes("DBSIZE", [])
	}

	## Construct `FAILOVER`.
	## Available since Redis 6.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/failover/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	failover : List(List(U8)) -> Command.Command
	failover = |options| {
		Command.from_nonempty_bytes("FAILOVER", options)
	}

	## Construct `FLUSHALL`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/flushall/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	flushall : List(List(U8)) -> Command.Command
	flushall = |options| {
		Command.from_nonempty_bytes("FLUSHALL", options)
	}

	## Construct `FLUSHDB`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/flushdb/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	flushdb : List(List(U8)) -> Command.Command
	flushdb = |options| {
		Command.from_nonempty_bytes("FLUSHDB", options)
	}

	## Construct `HOTKEYS GET`.
	## Available since Redis 8.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hotkeys-get/).
	hotkeys_get : {} -> Command.Command
	hotkeys_get = |_| {
		Command.from_nonempty_bytes("HOTKEYS", [['G', 'E', 'T']])
	}

	## Construct `HOTKEYS RESET`.
	## Available since Redis 8.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hotkeys-reset/).
	hotkeys_reset : {} -> Command.Command
	hotkeys_reset = |_| {
		Command.from_nonempty_bytes("HOTKEYS", [['R', 'E', 'S', 'E', 'T']])
	}

	## Construct `HOTKEYS START`.
	## Available since Redis 8.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hotkeys-start/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	hotkeys_start : List(List(U8)) -> Command.Command
	hotkeys_start = |options| {
		Command.from_nonempty_bytes("HOTKEYS", [['S', 'T', 'A', 'R', 'T']].concat(options))
	}

	## Construct `HOTKEYS STOP`.
	## Available since Redis 8.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/hotkeys-stop/).
	hotkeys_stop : {} -> Command.Command
	hotkeys_stop = |_| {
		Command.from_nonempty_bytes("HOTKEYS", [['S', 'T', 'O', 'P']])
	}

	## Construct `INFO`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/info/).
	## Parameters (in order): `sections`.
	info : List(List(U8)) -> Command.Command
	info = |sections| {
		Command.from_nonempty_bytes("INFO", sections)
	}

	## Construct `LASTSAVE`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/lastsave/).
	lastsave : {} -> Command.Command
	lastsave = |_| {
		Command.from_nonempty_bytes("LASTSAVE", [])
	}

	## Construct `LATENCY DOCTOR`.
	## Available since Redis 2.8.13.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/latency-doctor/).
	latency_doctor : {} -> Command.Command
	latency_doctor = |_| {
		Command.from_nonempty_bytes("LATENCY", [['D', 'O', 'C', 'T', 'O', 'R']])
	}

	## Construct `LATENCY GRAPH`.
	## Available since Redis 2.8.13.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/latency-graph/).
	## Parameters (in order): `event`.
	latency_graph : List(U8) -> Command.Command
	latency_graph = |event| {
		Command.from_nonempty_bytes("LATENCY", [['G', 'R', 'A', 'P', 'H']].concat([event]))
	}

	## Construct `LATENCY HISTOGRAM`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/latency-histogram/).
	## Parameters (in order): `commands`.
	latency_histogram : List(List(U8)) -> Command.Command
	latency_histogram = |commands| {
		Command.from_nonempty_bytes("LATENCY", [['H', 'I', 'S', 'T', 'O', 'G', 'R', 'A', 'M']].concat(commands))
	}

	## Construct `LATENCY HISTORY`.
	## Available since Redis 2.8.13.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/latency-history/).
	## Parameters (in order): `event`.
	latency_history : List(U8) -> Command.Command
	latency_history = |event| {
		Command.from_nonempty_bytes("LATENCY", [['H', 'I', 'S', 'T', 'O', 'R', 'Y']].concat([event]))
	}

	## Construct `LATENCY LATEST`.
	## Available since Redis 2.8.13.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/latency-latest/).
	latency_latest : {} -> Command.Command
	latency_latest = |_| {
		Command.from_nonempty_bytes("LATENCY", [['L', 'A', 'T', 'E', 'S', 'T']])
	}

	## Construct `LATENCY RESET`.
	## Available since Redis 2.8.13.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/latency-reset/).
	## Parameters (in order): `events`.
	latency_reset : List(List(U8)) -> Command.Command
	latency_reset = |events| {
		Command.from_nonempty_bytes("LATENCY", [['R', 'E', 'S', 'E', 'T']].concat(events))
	}

	## Construct `LOLWUT`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/lolwut/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	lolwut : List(List(U8)) -> Command.Command
	lolwut = |options| {
		Command.from_nonempty_bytes("LOLWUT", options)
	}

	## Construct `MEMORY DOCTOR`.
	## Available since Redis 4.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/memory-doctor/).
	memory_doctor : {} -> Command.Command
	memory_doctor = |_| {
		Command.from_nonempty_bytes("MEMORY", [['D', 'O', 'C', 'T', 'O', 'R']])
	}

	## Construct `MEMORY MALLOC-STATS`.
	## Available since Redis 4.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/memory-malloc-stats/).
	memory_malloc_stats : {} -> Command.Command
	memory_malloc_stats = |_| {
		Command.from_nonempty_bytes("MEMORY", [['M', 'A', 'L', 'L', 'O', 'C', '-', 'S', 'T', 'A', 'T', 'S']])
	}

	## Construct `MEMORY PURGE`.
	## Available since Redis 4.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/memory-purge/).
	memory_purge : {} -> Command.Command
	memory_purge = |_| {
		Command.from_nonempty_bytes("MEMORY", [['P', 'U', 'R', 'G', 'E']])
	}

	## Construct `MEMORY STATS`.
	## Available since Redis 4.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/memory-stats/).
	memory_stats : {} -> Command.Command
	memory_stats = |_| {
		Command.from_nonempty_bytes("MEMORY", [['S', 'T', 'A', 'T', 'S']])
	}

	## Construct `MEMORY USAGE`.
	## Available since Redis 4.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/memory-usage/).
	## Parameters (in order): `key`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	memory_usage : List(U8), List(List(U8)) -> Command.Command
	memory_usage = |key, options| {
		Command.from_nonempty_bytes("MEMORY", [['U', 'S', 'A', 'G', 'E']].concat([key].concat(options)))
	}

	## Construct `MODULE LIST`.
	## Available since Redis 4.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/module-list/).
	module_list : {} -> Command.Command
	module_list = |_| {
		Command.from_nonempty_bytes("MODULE", [['L', 'I', 'S', 'T']])
	}

	## Construct `MODULE LOAD`.
	## Available since Redis 4.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/module-load/).
	## Parameters (in order): `path`, `args`.
	module_load : List(U8), List(List(U8)) -> Command.Command
	module_load = |path, args| {
		Command.from_nonempty_bytes("MODULE", [['L', 'O', 'A', 'D']].concat([path].concat(args)))
	}

	## Construct `MODULE LOADEX`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/module-loadex/).
	## Parameters (in order): `path`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	module_loadex : List(U8), List(List(U8)) -> Command.Command
	module_loadex = |path, options| {
		Command.from_nonempty_bytes("MODULE", [['L', 'O', 'A', 'D', 'E', 'X']].concat([path].concat(options)))
	}

	## Construct `MODULE UNLOAD`.
	## Available since Redis 4.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/module-unload/).
	## Parameters (in order): `name`.
	module_unload : List(U8) -> Command.Command
	module_unload = |name| {
		Command.from_nonempty_bytes("MODULE", [['U', 'N', 'L', 'O', 'A', 'D']].concat([name]))
	}

	## Construct `MONITOR`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/monitor/).
	monitor : {} -> Command.Command
	monitor = |_| {
		Command.from_nonempty_bytes("MONITOR", [])
	}

	## Construct `REPLICAOF`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/replicaof/).
	## Parameters (in order): `args`.
	replicaof : { first : List(U8), rest : List(List(U8)) } -> Command.Command
	replicaof = |args| {
		Command.from_nonempty_bytes("REPLICAOF", [args.first].concat(args.rest))
	}

	## Construct `ROLE`.
	## Available since Redis 2.8.12.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/role/).
	role : {} -> Command.Command
	role = |_| {
		Command.from_nonempty_bytes("ROLE", [])
	}

	## Construct `SAVE`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/save/).
	save : {} -> Command.Command
	save = |_| {
		Command.from_nonempty_bytes("SAVE", [])
	}

	## Construct `SHUTDOWN`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/shutdown/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	shutdown : List(List(U8)) -> Command.Command
	shutdown = |options| {
		Command.from_nonempty_bytes("SHUTDOWN", options)
	}

	## Construct `SLAVEOF`.
	## Available since Redis 1.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/slaveof/).
	## Parameters (in order): `args`.
	## Deprecated by Redis; retained for catalog completeness.
	slaveof : { first : List(U8), rest : List(List(U8)) } -> Command.Command
	slaveof = |args| {
		Command.from_nonempty_bytes("SLAVEOF", [args.first].concat(args.rest))
	}

	## Construct `SLOWLOG GET`.
	## Available since Redis 2.2.12.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/slowlog-get/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	slowlog_get : List(List(U8)) -> Command.Command
	slowlog_get = |options| {
		Command.from_nonempty_bytes("SLOWLOG", [['G', 'E', 'T']].concat(options))
	}

	## Construct `SLOWLOG LEN`.
	## Available since Redis 2.2.12.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/slowlog-len/).
	slowlog_len : {} -> Command.Command
	slowlog_len = |_| {
		Command.from_nonempty_bytes("SLOWLOG", [['L', 'E', 'N']])
	}

	## Construct `SLOWLOG RESET`.
	## Available since Redis 2.2.12.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/slowlog-reset/).
	slowlog_reset : {} -> Command.Command
	slowlog_reset = |_| {
		Command.from_nonempty_bytes("SLOWLOG", [['R', 'E', 'S', 'E', 'T']])
	}

	## Construct `SWAPDB`.
	## Available since Redis 4.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/swapdb/).
	## Parameters (in order): `index1`, `index2`.
	swapdb : List(U8), List(U8) -> Command.Command
	swapdb = |index1, index2| {
		Command.from_nonempty_bytes("SWAPDB", [index1, index2])
	}

	## Construct `TIME`.
	## Available since Redis 2.6.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/time/).
	time : {} -> Command.Command
	time = |_| {
		Command.from_nonempty_bytes("TIME", [])
	}

	## Construct `TRIMSLOTS`.
	## Available since Redis 8.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/trimslots/).
	## Parameters (in order): `first_slot_range`, `other_slot_ranges`.
	trimslots : { startslot : List(U8), endslot : List(U8) }, List({ startslot : List(U8), endslot : List(U8) }) -> Command.Command
	trimslots = |first_slot_range, other_slot_ranges| {
		catalog_slot_ranges = [first_slot_range].concat(other_slot_ranges)
		Command.from_nonempty_bytes("TRIMSLOTS", [['R', 'A', 'N', 'G', 'E', 'S'], catalog_slot_ranges.len().to_str().to_utf8()].concat(catalog_slot_ranges.join_map(|item| [item.startslot, item.endslot])))
	}
}

expect Command.encode(Server.acl_cat([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '3', '\r', '\n', 'C', 'A', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.acl_cat([])) == ['*', '2', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '3', '\r', '\n', 'C', 'A', 'T', '\r', '\n']

expect Command.encode(Server.acl_deluser([0, 1, 255], [[0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '7', '\r', '\n', 'D', 'E', 'L', 'U', 'S', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.acl_deluser([0, 1, 255], [])) == ['*', '3', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '7', '\r', '\n', 'D', 'E', 'L', 'U', 'S', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Server.acl_dryrun([0, 1, 255], [0, 2, 255], [[0, 3, 255], [0, 4, 255]])) == ['*', '6', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '6', '\r', '\n', 'D', 'R', 'Y', 'R', 'U', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Server.acl_dryrun([0, 1, 255], [0, 2, 255], [])) == ['*', '4', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '6', '\r', '\n', 'D', 'R', 'Y', 'R', 'U', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.acl_genpass([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '7', '\r', '\n', 'G', 'E', 'N', 'P', 'A', 'S', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.acl_genpass([])) == ['*', '2', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '7', '\r', '\n', 'G', 'E', 'N', 'P', 'A', 'S', 'S', '\r', '\n']

expect Command.encode(Server.acl_getuser([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '7', '\r', '\n', 'G', 'E', 'T', 'U', 'S', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Server.acl_list({})) == ['*', '2', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '4', '\r', '\n', 'L', 'I', 'S', 'T', '\r', '\n']

expect Command.encode(Server.acl_load({})) == ['*', '2', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '4', '\r', '\n', 'L', 'O', 'A', 'D', '\r', '\n']

expect Command.encode(Server.acl_log([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '3', '\r', '\n', 'L', 'O', 'G', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.acl_log([])) == ['*', '2', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '3', '\r', '\n', 'L', 'O', 'G', '\r', '\n']

expect Command.encode(Server.acl_save({})) == ['*', '2', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '4', '\r', '\n', 'S', 'A', 'V', 'E', '\r', '\n']

expect Command.encode(Server.acl_setuser([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '5', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '7', '\r', '\n', 'S', 'E', 'T', 'U', 'S', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Server.acl_setuser([0, 1, 255], [])) == ['*', '3', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '7', '\r', '\n', 'S', 'E', 'T', 'U', 'S', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Server.acl_users({})) == ['*', '2', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '5', '\r', '\n', 'U', 'S', 'E', 'R', 'S', '\r', '\n']

expect Command.encode(Server.acl_whoami({})) == ['*', '2', '\r', '\n', '$', '3', '\r', '\n', 'A', 'C', 'L', '\r', '\n', '$', '6', '\r', '\n', 'W', 'H', 'O', 'A', 'M', 'I', '\r', '\n']

expect Command.encode(Server.backup_abort({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'B', 'A', 'C', 'K', 'U', 'P', '\r', '\n', '$', '5', '\r', '\n', 'A', 'B', 'O', 'R', 'T', '\r', '\n']

expect Command.encode(Server.backup_cleanup({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'B', 'A', 'C', 'K', 'U', 'P', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'E', 'A', 'N', 'U', 'P', '\r', '\n']

expect Command.encode(Server.backup_list({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'B', 'A', 'C', 'K', 'U', 'P', '\r', '\n', '$', '4', '\r', '\n', 'L', 'I', 'S', 'T', '\r', '\n']

expect Command.encode(Server.backup_seal({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'B', 'A', 'C', 'K', 'U', 'P', '\r', '\n', '$', '4', '\r', '\n', 'S', 'E', 'A', 'L', '\r', '\n']

expect Command.encode(Server.backup_start({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'B', 'A', 'C', 'K', 'U', 'P', '\r', '\n', '$', '5', '\r', '\n', 'S', 'T', 'A', 'R', 'T', '\r', '\n']

expect Command.encode(Server.backup_status({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'B', 'A', 'C', 'K', 'U', 'P', '\r', '\n', '$', '6', '\r', '\n', 'S', 'T', 'A', 'T', 'U', 'S', '\r', '\n']

expect Command.encode(Server.bgrewriteaof({})) == ['*', '1', '\r', '\n', '$', '1', '2', '\r', '\n', 'B', 'G', 'R', 'E', 'W', 'R', 'I', 'T', 'E', 'A', 'O', 'F', '\r', '\n']

expect Command.encode(Server.bgsave([[0, 1, 255], [0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'B', 'G', 'S', 'A', 'V', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.bgsave([])) == ['*', '1', '\r', '\n', '$', '6', '\r', '\n', 'B', 'G', 'S', 'A', 'V', 'E', '\r', '\n']

expect Command.encode(Server.command({})) == ['*', '1', '\r', '\n', '$', '7', '\r', '\n', 'C', 'O', 'M', 'M', 'A', 'N', 'D', '\r', '\n']

expect Command.encode(Server.command_count({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'C', 'O', 'M', 'M', 'A', 'N', 'D', '\r', '\n', '$', '5', '\r', '\n', 'C', 'O', 'U', 'N', 'T', '\r', '\n']

expect Command.encode(Server.command_docs([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'C', 'O', 'M', 'M', 'A', 'N', 'D', '\r', '\n', '$', '4', '\r', '\n', 'D', 'O', 'C', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.command_docs([])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'C', 'O', 'M', 'M', 'A', 'N', 'D', '\r', '\n', '$', '4', '\r', '\n', 'D', 'O', 'C', 'S', '\r', '\n']

expect Command.encode(Server.command_getkeys([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '5', '\r', '\n', '$', '7', '\r', '\n', 'C', 'O', 'M', 'M', 'A', 'N', 'D', '\r', '\n', '$', '7', '\r', '\n', 'G', 'E', 'T', 'K', 'E', 'Y', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Server.command_getkeys([0, 1, 255], [])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'C', 'O', 'M', 'M', 'A', 'N', 'D', '\r', '\n', '$', '7', '\r', '\n', 'G', 'E', 'T', 'K', 'E', 'Y', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Server.command_getkeysandflags([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '5', '\r', '\n', '$', '7', '\r', '\n', 'C', 'O', 'M', 'M', 'A', 'N', 'D', '\r', '\n', '$', '1', '5', '\r', '\n', 'G', 'E', 'T', 'K', 'E', 'Y', 'S', 'A', 'N', 'D', 'F', 'L', 'A', 'G', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Server.command_getkeysandflags([0, 1, 255], [])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'C', 'O', 'M', 'M', 'A', 'N', 'D', '\r', '\n', '$', '1', '5', '\r', '\n', 'G', 'E', 'T', 'K', 'E', 'Y', 'S', 'A', 'N', 'D', 'F', 'L', 'A', 'G', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Server.command_info([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'C', 'O', 'M', 'M', 'A', 'N', 'D', '\r', '\n', '$', '4', '\r', '\n', 'I', 'N', 'F', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.command_info([])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'C', 'O', 'M', 'M', 'A', 'N', 'D', '\r', '\n', '$', '4', '\r', '\n', 'I', 'N', 'F', 'O', '\r', '\n']

expect Command.encode(Server.command_list([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'C', 'O', 'M', 'M', 'A', 'N', 'D', '\r', '\n', '$', '4', '\r', '\n', 'L', 'I', 'S', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.command_list([])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'C', 'O', 'M', 'M', 'A', 'N', 'D', '\r', '\n', '$', '4', '\r', '\n', 'L', 'I', 'S', 'T', '\r', '\n']

expect Command.encode(Server.config_get([0, 1, 255], [[0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'C', 'O', 'N', 'F', 'I', 'G', '\r', '\n', '$', '3', '\r', '\n', 'G', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.config_get([0, 1, 255], [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'C', 'O', 'N', 'F', 'I', 'G', '\r', '\n', '$', '3', '\r', '\n', 'G', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Server.config_resetstat({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'C', 'O', 'N', 'F', 'I', 'G', '\r', '\n', '$', '9', '\r', '\n', 'R', 'E', 'S', 'E', 'T', 'S', 'T', 'A', 'T', '\r', '\n']

expect Command.encode(Server.config_rewrite({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'C', 'O', 'N', 'F', 'I', 'G', '\r', '\n', '$', '7', '\r', '\n', 'R', 'E', 'W', 'R', 'I', 'T', 'E', '\r', '\n']

expect Command.encode(Server.config_set({ parameter: [0, 1, 255], value: [0, 2, 255] }, [{ parameter: [0, 3, 255], value: [0, 4, 255] }])) == ['*', '6', '\r', '\n', '$', '6', '\r', '\n', 'C', 'O', 'N', 'F', 'I', 'G', '\r', '\n', '$', '3', '\r', '\n', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Server.config_set({ parameter: [0, 1, 255], value: [0, 2, 255] }, [])) == ['*', '4', '\r', '\n', '$', '6', '\r', '\n', 'C', 'O', 'N', 'F', 'I', 'G', '\r', '\n', '$', '3', '\r', '\n', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.dbsize({})) == ['*', '1', '\r', '\n', '$', '6', '\r', '\n', 'D', 'B', 'S', 'I', 'Z', 'E', '\r', '\n']

expect Command.encode(Server.failover([[0, 1, 255], [0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '8', '\r', '\n', 'F', 'A', 'I', 'L', 'O', 'V', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.failover([])) == ['*', '1', '\r', '\n', '$', '8', '\r', '\n', 'F', 'A', 'I', 'L', 'O', 'V', 'E', 'R', '\r', '\n']

expect Command.encode(Server.flushall([[0, 1, 255], [0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '8', '\r', '\n', 'F', 'L', 'U', 'S', 'H', 'A', 'L', 'L', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.flushall([])) == ['*', '1', '\r', '\n', '$', '8', '\r', '\n', 'F', 'L', 'U', 'S', 'H', 'A', 'L', 'L', '\r', '\n']

expect Command.encode(Server.flushdb([[0, 1, 255], [0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'F', 'L', 'U', 'S', 'H', 'D', 'B', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.flushdb([])) == ['*', '1', '\r', '\n', '$', '7', '\r', '\n', 'F', 'L', 'U', 'S', 'H', 'D', 'B', '\r', '\n']

expect Command.encode(Server.hotkeys_get({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'H', 'O', 'T', 'K', 'E', 'Y', 'S', '\r', '\n', '$', '3', '\r', '\n', 'G', 'E', 'T', '\r', '\n']

expect Command.encode(Server.hotkeys_reset({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'H', 'O', 'T', 'K', 'E', 'Y', 'S', '\r', '\n', '$', '5', '\r', '\n', 'R', 'E', 'S', 'E', 'T', '\r', '\n']

expect Command.encode(Server.hotkeys_start([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'H', 'O', 'T', 'K', 'E', 'Y', 'S', '\r', '\n', '$', '5', '\r', '\n', 'S', 'T', 'A', 'R', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.hotkeys_start([])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'H', 'O', 'T', 'K', 'E', 'Y', 'S', '\r', '\n', '$', '5', '\r', '\n', 'S', 'T', 'A', 'R', 'T', '\r', '\n']

expect Command.encode(Server.hotkeys_stop({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'H', 'O', 'T', 'K', 'E', 'Y', 'S', '\r', '\n', '$', '4', '\r', '\n', 'S', 'T', 'O', 'P', '\r', '\n']

expect Command.encode(Server.info([[0, 1, 255], [0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '4', '\r', '\n', 'I', 'N', 'F', 'O', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.info([])) == ['*', '1', '\r', '\n', '$', '4', '\r', '\n', 'I', 'N', 'F', 'O', '\r', '\n']

expect Command.encode(Server.lastsave({})) == ['*', '1', '\r', '\n', '$', '8', '\r', '\n', 'L', 'A', 'S', 'T', 'S', 'A', 'V', 'E', '\r', '\n']

expect Command.encode(Server.latency_doctor({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'L', 'A', 'T', 'E', 'N', 'C', 'Y', '\r', '\n', '$', '6', '\r', '\n', 'D', 'O', 'C', 'T', 'O', 'R', '\r', '\n']

expect Command.encode(Server.latency_graph([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'L', 'A', 'T', 'E', 'N', 'C', 'Y', '\r', '\n', '$', '5', '\r', '\n', 'G', 'R', 'A', 'P', 'H', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Server.latency_histogram([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'L', 'A', 'T', 'E', 'N', 'C', 'Y', '\r', '\n', '$', '9', '\r', '\n', 'H', 'I', 'S', 'T', 'O', 'G', 'R', 'A', 'M', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.latency_histogram([])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'L', 'A', 'T', 'E', 'N', 'C', 'Y', '\r', '\n', '$', '9', '\r', '\n', 'H', 'I', 'S', 'T', 'O', 'G', 'R', 'A', 'M', '\r', '\n']

expect Command.encode(Server.latency_history([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'L', 'A', 'T', 'E', 'N', 'C', 'Y', '\r', '\n', '$', '7', '\r', '\n', 'H', 'I', 'S', 'T', 'O', 'R', 'Y', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Server.latency_latest({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'L', 'A', 'T', 'E', 'N', 'C', 'Y', '\r', '\n', '$', '6', '\r', '\n', 'L', 'A', 'T', 'E', 'S', 'T', '\r', '\n']

expect Command.encode(Server.latency_reset([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'L', 'A', 'T', 'E', 'N', 'C', 'Y', '\r', '\n', '$', '5', '\r', '\n', 'R', 'E', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.latency_reset([])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'L', 'A', 'T', 'E', 'N', 'C', 'Y', '\r', '\n', '$', '5', '\r', '\n', 'R', 'E', 'S', 'E', 'T', '\r', '\n']

expect Command.encode(Server.lolwut([[0, 1, 255], [0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'L', 'O', 'L', 'W', 'U', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.lolwut([])) == ['*', '1', '\r', '\n', '$', '6', '\r', '\n', 'L', 'O', 'L', 'W', 'U', 'T', '\r', '\n']

expect Command.encode(Server.memory_doctor({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'M', 'E', 'M', 'O', 'R', 'Y', '\r', '\n', '$', '6', '\r', '\n', 'D', 'O', 'C', 'T', 'O', 'R', '\r', '\n']

expect Command.encode(Server.memory_malloc_stats({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'M', 'E', 'M', 'O', 'R', 'Y', '\r', '\n', '$', '1', '2', '\r', '\n', 'M', 'A', 'L', 'L', 'O', 'C', '-', 'S', 'T', 'A', 'T', 'S', '\r', '\n']

expect Command.encode(Server.memory_purge({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'M', 'E', 'M', 'O', 'R', 'Y', '\r', '\n', '$', '5', '\r', '\n', 'P', 'U', 'R', 'G', 'E', '\r', '\n']

expect Command.encode(Server.memory_stats({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'M', 'E', 'M', 'O', 'R', 'Y', '\r', '\n', '$', '5', '\r', '\n', 'S', 'T', 'A', 'T', 'S', '\r', '\n']

expect Command.encode(Server.memory_usage([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'M', 'E', 'M', 'O', 'R', 'Y', '\r', '\n', '$', '5', '\r', '\n', 'U', 'S', 'A', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Server.memory_usage([0, 1, 255], [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'M', 'E', 'M', 'O', 'R', 'Y', '\r', '\n', '$', '5', '\r', '\n', 'U', 'S', 'A', 'G', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Server.module_list({})) == ['*', '2', '\r', '\n', '$', '6', '\r', '\n', 'M', 'O', 'D', 'U', 'L', 'E', '\r', '\n', '$', '4', '\r', '\n', 'L', 'I', 'S', 'T', '\r', '\n']

expect Command.encode(Server.module_load([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'M', 'O', 'D', 'U', 'L', 'E', '\r', '\n', '$', '4', '\r', '\n', 'L', 'O', 'A', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Server.module_load([0, 1, 255], [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'M', 'O', 'D', 'U', 'L', 'E', '\r', '\n', '$', '4', '\r', '\n', 'L', 'O', 'A', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Server.module_loadex([0, 1, 255], [[0, 2, 255], [0, 3, 255]])) == ['*', '5', '\r', '\n', '$', '6', '\r', '\n', 'M', 'O', 'D', 'U', 'L', 'E', '\r', '\n', '$', '6', '\r', '\n', 'L', 'O', 'A', 'D', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n']

expect Command.encode(Server.module_loadex([0, 1, 255], [])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'M', 'O', 'D', 'U', 'L', 'E', '\r', '\n', '$', '6', '\r', '\n', 'L', 'O', 'A', 'D', 'E', 'X', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Server.module_unload([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'M', 'O', 'D', 'U', 'L', 'E', '\r', '\n', '$', '6', '\r', '\n', 'U', 'N', 'L', 'O', 'A', 'D', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Server.monitor({})) == ['*', '1', '\r', '\n', '$', '7', '\r', '\n', 'M', 'O', 'N', 'I', 'T', 'O', 'R', '\r', '\n']

expect Command.encode(Server.replicaof({ first: [0, 1, 255], rest: [['2']] })) == ['*', '3', '\r', '\n', '$', '9', '\r', '\n', 'R', 'E', 'P', 'L', 'I', 'C', 'A', 'O', 'F', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Server.role({})) == ['*', '1', '\r', '\n', '$', '4', '\r', '\n', 'R', 'O', 'L', 'E', '\r', '\n']

expect Command.encode(Server.save({})) == ['*', '1', '\r', '\n', '$', '4', '\r', '\n', 'S', 'A', 'V', 'E', '\r', '\n']

expect Command.encode(Server.shutdown([[0, 1, 255], [0, 2, 255]])) == ['*', '3', '\r', '\n', '$', '8', '\r', '\n', 'S', 'H', 'U', 'T', 'D', 'O', 'W', 'N', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.shutdown([])) == ['*', '1', '\r', '\n', '$', '8', '\r', '\n', 'S', 'H', 'U', 'T', 'D', 'O', 'W', 'N', '\r', '\n']

expect Command.encode(Server.slaveof({ first: [0, 1, 255], rest: [['2']] })) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'S', 'L', 'A', 'V', 'E', 'O', 'F', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Server.slowlog_get([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'S', 'L', 'O', 'W', 'L', 'O', 'G', '\r', '\n', '$', '3', '\r', '\n', 'G', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Server.slowlog_get([])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'S', 'L', 'O', 'W', 'L', 'O', 'G', '\r', '\n', '$', '3', '\r', '\n', 'G', 'E', 'T', '\r', '\n']

expect Command.encode(Server.slowlog_len({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'S', 'L', 'O', 'W', 'L', 'O', 'G', '\r', '\n', '$', '3', '\r', '\n', 'L', 'E', 'N', '\r', '\n']

expect Command.encode(Server.slowlog_reset({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'S', 'L', 'O', 'W', 'L', 'O', 'G', '\r', '\n', '$', '5', '\r', '\n', 'R', 'E', 'S', 'E', 'T', '\r', '\n']

expect Command.encode(Server.swapdb(['1'], ['2'])) == ['*', '3', '\r', '\n', '$', '6', '\r', '\n', 'S', 'W', 'A', 'P', 'D', 'B', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Server.time({})) == ['*', '1', '\r', '\n', '$', '4', '\r', '\n', 'T', 'I', 'M', 'E', '\r', '\n']

expect Command.encode(Server.trimslots({ startslot: ['1'], endslot: ['2'] }, [{ startslot: ['3'], endslot: ['4'] }])) == ['*', '7', '\r', '\n', '$', '9', '\r', '\n', 'T', 'R', 'I', 'M', 'S', 'L', 'O', 'T', 'S', '\r', '\n', '$', '6', '\r', '\n', 'R', 'A', 'N', 'G', 'E', 'S', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n', '$', '1', '\r', '\n', '4', '\r', '\n']

expect Command.encode(Server.trimslots({ startslot: ['1'], endslot: ['2'] }, [])) == ['*', '5', '\r', '\n', '$', '9', '\r', '\n', 'T', 'R', 'I', 'M', 'S', 'L', 'O', 'T', 'S', '\r', '\n', '$', '6', '\r', '\n', 'R', 'A', 'N', 'G', 'E', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']
