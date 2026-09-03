import Command

## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.
## Binary-safe Redis OSS 8.10.1 Cluster command constructors.
##
## Scalar wire arguments are `List(U8)`. Required variadic arguments use
## a first value plus a remaining list, so an empty required collection is
## unrepresentable. Count prefixes are derived automatically. Parameters
## beginning with `options` are deliberately raw token lists for grammars whose
## combinations Redis validates; they are inserted verbatim and may be empty.
## A `{ first, rest }` record is a non-empty raw token sequence for a required
## grammar choice; Redis validates the sequence when it executes the command.
## Cluster constructors encode wire commands only. Slot routing, node selection,
## and MOVED/ASK handling remain application responsibilities.
Cluster := {}.{

	## Construct `ASKING`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/asking/).
	asking : {} -> Command.Command
	asking = |_| {
		Command.from_nonempty_bytes("ASKING", [])
	}

	## Construct `CLUSTER ADDSLOTS`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-addslots/).
	## Parameters (in order): `first_slot`, `other_slots`.
	cluster_addslots : List(U8), List(List(U8)) -> Command.Command
	cluster_addslots = |first_slot, other_slots| {
		catalog_slots = [first_slot].concat(other_slots)
		Command.from_nonempty_bytes("CLUSTER", [['A', 'D', 'D', 'S', 'L', 'O', 'T', 'S']].concat(catalog_slots))
	}

	## Construct `CLUSTER ADDSLOTSRANGE`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-addslotsrange/).
	## Parameters (in order): `first_range`, `other_ranges`.
	cluster_addslotsrange : { start_slot : List(U8), end_slot : List(U8) }, List({ start_slot : List(U8), end_slot : List(U8) }) -> Command.Command
	cluster_addslotsrange = |first_range, other_ranges| {
		catalog_ranges = [first_range].concat(other_ranges)
		Command.from_nonempty_bytes("CLUSTER", [['A', 'D', 'D', 'S', 'L', 'O', 'T', 'S', 'R', 'A', 'N', 'G', 'E']].concat(catalog_ranges.join_map(|item| [item.start_slot, item.end_slot])))
	}

	## Construct `CLUSTER BUMPEPOCH`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-bumpepoch/).
	cluster_bumpepoch : {} -> Command.Command
	cluster_bumpepoch = |_| {
		Command.from_nonempty_bytes("CLUSTER", [['B', 'U', 'M', 'P', 'E', 'P', 'O', 'C', 'H']])
	}

	## Construct `CLUSTER COUNT-FAILURE-REPORTS`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-count-failure-reports/).
	## Parameters (in order): `node_id`.
	cluster_count_failure_reports : List(U8) -> Command.Command
	cluster_count_failure_reports = |node_id| {
		Command.from_nonempty_bytes("CLUSTER", [['C', 'O', 'U', 'N', 'T', '-', 'F', 'A', 'I', 'L', 'U', 'R', 'E', '-', 'R', 'E', 'P', 'O', 'R', 'T', 'S']].concat([node_id]))
	}

	## Construct `CLUSTER COUNTKEYSINSLOT`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-countkeysinslot/).
	## Parameters (in order): `slot`.
	cluster_countkeysinslot : List(U8) -> Command.Command
	cluster_countkeysinslot = |slot| {
		Command.from_nonempty_bytes("CLUSTER", [['C', 'O', 'U', 'N', 'T', 'K', 'E', 'Y', 'S', 'I', 'N', 'S', 'L', 'O', 'T']].concat([slot]))
	}

	## Construct `CLUSTER DELSLOTS`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-delslots/).
	## Parameters (in order): `first_slot`, `other_slots`.
	cluster_delslots : List(U8), List(List(U8)) -> Command.Command
	cluster_delslots = |first_slot, other_slots| {
		catalog_slots = [first_slot].concat(other_slots)
		Command.from_nonempty_bytes("CLUSTER", [['D', 'E', 'L', 'S', 'L', 'O', 'T', 'S']].concat(catalog_slots))
	}

	## Construct `CLUSTER DELSLOTSRANGE`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-delslotsrange/).
	## Parameters (in order): `first_range`, `other_ranges`.
	cluster_delslotsrange : { start_slot : List(U8), end_slot : List(U8) }, List({ start_slot : List(U8), end_slot : List(U8) }) -> Command.Command
	cluster_delslotsrange = |first_range, other_ranges| {
		catalog_ranges = [first_range].concat(other_ranges)
		Command.from_nonempty_bytes("CLUSTER", [['D', 'E', 'L', 'S', 'L', 'O', 'T', 'S', 'R', 'A', 'N', 'G', 'E']].concat(catalog_ranges.join_map(|item| [item.start_slot, item.end_slot])))
	}

	## Construct `CLUSTER FAILOVER`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-failover/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	cluster_failover : List(List(U8)) -> Command.Command
	cluster_failover = |options| {
		Command.from_nonempty_bytes("CLUSTER", [['F', 'A', 'I', 'L', 'O', 'V', 'E', 'R']].concat(options))
	}

	## Construct `CLUSTER FLUSHSLOTS`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-flushslots/).
	cluster_flushslots : {} -> Command.Command
	cluster_flushslots = |_| {
		Command.from_nonempty_bytes("CLUSTER", [['F', 'L', 'U', 'S', 'H', 'S', 'L', 'O', 'T', 'S']])
	}

	## Construct `CLUSTER FORGET`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-forget/).
	## Parameters (in order): `node_id`.
	cluster_forget : List(U8) -> Command.Command
	cluster_forget = |node_id| {
		Command.from_nonempty_bytes("CLUSTER", [['F', 'O', 'R', 'G', 'E', 'T']].concat([node_id]))
	}

	## Construct `CLUSTER GETKEYSINSLOT`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-getkeysinslot/).
	## Parameters (in order): `slot`, `count`.
	cluster_getkeysinslot : List(U8), List(U8) -> Command.Command
	cluster_getkeysinslot = |slot, count| {
		Command.from_nonempty_bytes("CLUSTER", [['G', 'E', 'T', 'K', 'E', 'Y', 'S', 'I', 'N', 'S', 'L', 'O', 'T']].concat([slot, count]))
	}

	## Construct `CLUSTER INFO`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-info/).
	cluster_info : {} -> Command.Command
	cluster_info = |_| {
		Command.from_nonempty_bytes("CLUSTER", [['I', 'N', 'F', 'O']])
	}

	## Construct `CLUSTER KEYSLOT`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-keyslot/).
	## Parameters (in order): `key`.
	cluster_keyslot : List(U8) -> Command.Command
	cluster_keyslot = |key| {
		Command.from_nonempty_bytes("CLUSTER", [['K', 'E', 'Y', 'S', 'L', 'O', 'T']].concat([key]))
	}

	## Construct `CLUSTER LINKS`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-links/).
	cluster_links : {} -> Command.Command
	cluster_links = |_| {
		Command.from_nonempty_bytes("CLUSTER", [['L', 'I', 'N', 'K', 'S']])
	}

	## Construct `CLUSTER MEET`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-meet/).
	## Parameters (in order): `ip`, `port`, `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	cluster_meet : List(U8), List(U8), List(List(U8)) -> Command.Command
	cluster_meet = |ip, port, options| {
		Command.from_nonempty_bytes("CLUSTER", [['M', 'E', 'E', 'T']].concat([ip, port].concat(options)))
	}

	## Construct `CLUSTER MIGRATION`.
	## Available since Redis 8.4.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-migration/).
	## Parameters (in order): `subcommand`.
	cluster_migration : { first : List(U8), rest : List(List(U8)) } -> Command.Command
	cluster_migration = |subcommand| {
		Command.from_nonempty_bytes("CLUSTER", [['M', 'I', 'G', 'R', 'A', 'T', 'I', 'O', 'N']].concat([subcommand.first].concat(subcommand.rest)))
	}

	## Construct `CLUSTER MYID`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-myid/).
	cluster_myid : {} -> Command.Command
	cluster_myid = |_| {
		Command.from_nonempty_bytes("CLUSTER", [['M', 'Y', 'I', 'D']])
	}

	## Construct `CLUSTER MYSHARDID`.
	## Available since Redis 7.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-myshardid/).
	cluster_myshardid : {} -> Command.Command
	cluster_myshardid = |_| {
		Command.from_nonempty_bytes("CLUSTER", [['M', 'Y', 'S', 'H', 'A', 'R', 'D', 'I', 'D']])
	}

	## Construct `CLUSTER NODES`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-nodes/).
	cluster_nodes : {} -> Command.Command
	cluster_nodes = |_| {
		Command.from_nonempty_bytes("CLUSTER", [['N', 'O', 'D', 'E', 'S']])
	}

	## Construct `CLUSTER REPLICAS`.
	## Available since Redis 5.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-replicas/).
	## Parameters (in order): `node_id`.
	cluster_replicas : List(U8) -> Command.Command
	cluster_replicas = |node_id| {
		Command.from_nonempty_bytes("CLUSTER", [['R', 'E', 'P', 'L', 'I', 'C', 'A', 'S']].concat([node_id]))
	}

	## Construct `CLUSTER REPLICATE`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-replicate/).
	## Parameters (in order): `node_id`.
	cluster_replicate : List(U8) -> Command.Command
	cluster_replicate = |node_id| {
		Command.from_nonempty_bytes("CLUSTER", [['R', 'E', 'P', 'L', 'I', 'C', 'A', 'T', 'E']].concat([node_id]))
	}

	## Construct `CLUSTER RESET`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-reset/).
	## Parameters (in order): `options`.
	## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.
	cluster_reset : List(List(U8)) -> Command.Command
	cluster_reset = |options| {
		Command.from_nonempty_bytes("CLUSTER", [['R', 'E', 'S', 'E', 'T']].concat(options))
	}

	## Construct `CLUSTER SAVECONFIG`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-saveconfig/).
	cluster_saveconfig : {} -> Command.Command
	cluster_saveconfig = |_| {
		Command.from_nonempty_bytes("CLUSTER", [['S', 'A', 'V', 'E', 'C', 'O', 'N', 'F', 'I', 'G']])
	}

	## Construct `CLUSTER SET-CONFIG-EPOCH`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-set-config-epoch/).
	## Parameters (in order): `config_epoch`.
	cluster_set_config_epoch : List(U8) -> Command.Command
	cluster_set_config_epoch = |config_epoch| {
		Command.from_nonempty_bytes("CLUSTER", [['S', 'E', 'T', '-', 'C', 'O', 'N', 'F', 'I', 'G', '-', 'E', 'P', 'O', 'C', 'H']].concat([config_epoch]))
	}

	## Construct `CLUSTER SETSLOT`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-setslot/).
	## Parameters (in order): `slot`, `subcommand`.
	cluster_setslot : List(U8), { first : List(U8), rest : List(List(U8)) } -> Command.Command
	cluster_setslot = |slot, subcommand| {
		Command.from_nonempty_bytes("CLUSTER", [['S', 'E', 'T', 'S', 'L', 'O', 'T']].concat([slot].concat([subcommand.first].concat(subcommand.rest))))
	}

	## Construct `CLUSTER SHARDS`.
	## Available since Redis 7.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-shards/).
	cluster_shards : {} -> Command.Command
	cluster_shards = |_| {
		Command.from_nonempty_bytes("CLUSTER", [['S', 'H', 'A', 'R', 'D', 'S']])
	}

	## Construct `CLUSTER SLAVES`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-slaves/).
	## Parameters (in order): `node_id`.
	## Deprecated by Redis; retained for catalog completeness.
	cluster_slaves : List(U8) -> Command.Command
	cluster_slaves = |node_id| {
		Command.from_nonempty_bytes("CLUSTER", [['S', 'L', 'A', 'V', 'E', 'S']].concat([node_id]))
	}

	## Construct `CLUSTER SLOT-STATS`.
	## Available since Redis 8.2.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-slot-stats/).
	## Parameters (in order): `filter`.
	cluster_slot_stats : { first : List(U8), rest : List(List(U8)) } -> Command.Command
	cluster_slot_stats = |filter| {
		Command.from_nonempty_bytes("CLUSTER", [['S', 'L', 'O', 'T', '-', 'S', 'T', 'A', 'T', 'S']].concat([filter.first].concat(filter.rest)))
	}

	## Construct `CLUSTER SLOTS`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/cluster-slots/).
	## Deprecated by Redis; retained for catalog completeness.
	cluster_slots : {} -> Command.Command
	cluster_slots = |_| {
		Command.from_nonempty_bytes("CLUSTER", [['S', 'L', 'O', 'T', 'S']])
	}

	## Construct `READONLY`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/readonly/).
	readonly : {} -> Command.Command
	readonly = |_| {
		Command.from_nonempty_bytes("READONLY", [])
	}

	## Construct `READWRITE`.
	## Available since Redis 3.0.0.
	## [Official Redis command documentation](https://redis.io/docs/latest/commands/readwrite/).
	readwrite : {} -> Command.Command
	readwrite = |_| {
		Command.from_nonempty_bytes("READWRITE", [])
	}
}

expect Command.encode(Cluster.asking({})) == ['*', '1', '\r', '\n', '$', '6', '\r', '\n', 'A', 'S', 'K', 'I', 'N', 'G', '\r', '\n']

expect Command.encode(Cluster.cluster_addslots(['1'], [['2']])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '8', '\r', '\n', 'A', 'D', 'D', 'S', 'L', 'O', 'T', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Cluster.cluster_addslots(['1'], [])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '8', '\r', '\n', 'A', 'D', 'D', 'S', 'L', 'O', 'T', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n']

expect Command.encode(Cluster.cluster_addslotsrange({ start_slot: ['1'], end_slot: ['2'] }, [{ start_slot: ['3'], end_slot: ['4'] }])) == ['*', '6', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '1', '3', '\r', '\n', 'A', 'D', 'D', 'S', 'L', 'O', 'T', 'S', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n', '$', '1', '\r', '\n', '4', '\r', '\n']

expect Command.encode(Cluster.cluster_addslotsrange({ start_slot: ['1'], end_slot: ['2'] }, [])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '1', '3', '\r', '\n', 'A', 'D', 'D', 'S', 'L', 'O', 'T', 'S', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Cluster.cluster_bumpepoch({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '9', '\r', '\n', 'B', 'U', 'M', 'P', 'E', 'P', 'O', 'C', 'H', '\r', '\n']

expect Command.encode(Cluster.cluster_count_failure_reports([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '2', '1', '\r', '\n', 'C', 'O', 'U', 'N', 'T', '-', 'F', 'A', 'I', 'L', 'U', 'R', 'E', '-', 'R', 'E', 'P', 'O', 'R', 'T', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Cluster.cluster_countkeysinslot(['1'])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '1', '5', '\r', '\n', 'C', 'O', 'U', 'N', 'T', 'K', 'E', 'Y', 'S', 'I', 'N', 'S', 'L', 'O', 'T', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n']

expect Command.encode(Cluster.cluster_delslots(['1'], [['2']])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '8', '\r', '\n', 'D', 'E', 'L', 'S', 'L', 'O', 'T', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Cluster.cluster_delslots(['1'], [])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '8', '\r', '\n', 'D', 'E', 'L', 'S', 'L', 'O', 'T', 'S', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n']

expect Command.encode(Cluster.cluster_delslotsrange({ start_slot: ['1'], end_slot: ['2'] }, [{ start_slot: ['3'], end_slot: ['4'] }])) == ['*', '6', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '1', '3', '\r', '\n', 'D', 'E', 'L', 'S', 'L', 'O', 'T', 'S', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '1', '\r', '\n', '3', '\r', '\n', '$', '1', '\r', '\n', '4', '\r', '\n']

expect Command.encode(Cluster.cluster_delslotsrange({ start_slot: ['1'], end_slot: ['2'] }, [])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '1', '3', '\r', '\n', 'D', 'E', 'L', 'S', 'L', 'O', 'T', 'S', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Cluster.cluster_failover([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '8', '\r', '\n', 'F', 'A', 'I', 'L', 'O', 'V', 'E', 'R', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Cluster.cluster_failover([])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '8', '\r', '\n', 'F', 'A', 'I', 'L', 'O', 'V', 'E', 'R', '\r', '\n']

expect Command.encode(Cluster.cluster_flushslots({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '1', '0', '\r', '\n', 'F', 'L', 'U', 'S', 'H', 'S', 'L', 'O', 'T', 'S', '\r', '\n']

expect Command.encode(Cluster.cluster_forget([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '6', '\r', '\n', 'F', 'O', 'R', 'G', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Cluster.cluster_getkeysinslot(['1'], ['2'])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '1', '3', '\r', '\n', 'G', 'E', 'T', 'K', 'E', 'Y', 'S', 'I', 'N', 'S', 'L', 'O', 'T', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Cluster.cluster_info({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '4', '\r', '\n', 'I', 'N', 'F', 'O', '\r', '\n']

expect Command.encode(Cluster.cluster_keyslot([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '7', '\r', '\n', 'K', 'E', 'Y', 'S', 'L', 'O', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Cluster.cluster_links({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '5', '\r', '\n', 'L', 'I', 'N', 'K', 'S', '\r', '\n']

expect Command.encode(Cluster.cluster_meet([0, 1, 255], ['2'], [[0, 3, 255], [0, 4, 255]])) == ['*', '6', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '4', '\r', '\n', 'M', 'E', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n', '$', '3', '\r', '\n', 0, 3, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 4, 255, '\r', '\n']

expect Command.encode(Cluster.cluster_meet([0, 1, 255], ['2'], [])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '4', '\r', '\n', 'M', 'E', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Cluster.cluster_migration({ first: ['I', 'M', 'P', 'O', 'R', 'T'], rest: [['1'], ['2']] })) == ['*', '5', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '9', '\r', '\n', 'M', 'I', 'G', 'R', 'A', 'T', 'I', 'O', 'N', '\r', '\n', '$', '6', '\r', '\n', 'I', 'M', 'P', 'O', 'R', 'T', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Cluster.cluster_migration({ first: ['C', 'A', 'N', 'C', 'E', 'L'], rest: [['A', 'L', 'L']] })) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '9', '\r', '\n', 'M', 'I', 'G', 'R', 'A', 'T', 'I', 'O', 'N', '\r', '\n', '$', '6', '\r', '\n', 'C', 'A', 'N', 'C', 'E', 'L', '\r', '\n', '$', '3', '\r', '\n', 'A', 'L', 'L', '\r', '\n']

expect Command.encode(Cluster.cluster_myid({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '4', '\r', '\n', 'M', 'Y', 'I', 'D', '\r', '\n']

expect Command.encode(Cluster.cluster_myshardid({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '9', '\r', '\n', 'M', 'Y', 'S', 'H', 'A', 'R', 'D', 'I', 'D', '\r', '\n']

expect Command.encode(Cluster.cluster_nodes({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '5', '\r', '\n', 'N', 'O', 'D', 'E', 'S', '\r', '\n']

expect Command.encode(Cluster.cluster_replicas([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '8', '\r', '\n', 'R', 'E', 'P', 'L', 'I', 'C', 'A', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Cluster.cluster_replicate([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '9', '\r', '\n', 'R', 'E', 'P', 'L', 'I', 'C', 'A', 'T', 'E', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Cluster.cluster_reset([[0, 1, 255], [0, 2, 255]])) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '5', '\r', '\n', 'R', 'E', 'S', 'E', 'T', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Cluster.cluster_reset([])) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '5', '\r', '\n', 'R', 'E', 'S', 'E', 'T', '\r', '\n']

expect Command.encode(Cluster.cluster_saveconfig({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '1', '0', '\r', '\n', 'S', 'A', 'V', 'E', 'C', 'O', 'N', 'F', 'I', 'G', '\r', '\n']

expect Command.encode(Cluster.cluster_set_config_epoch(['1'])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '1', '6', '\r', '\n', 'S', 'E', 'T', '-', 'C', 'O', 'N', 'F', 'I', 'G', '-', 'E', 'P', 'O', 'C', 'H', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n']

expect Command.encode(Cluster.cluster_setslot(['1'], { first: ['I', 'M', 'P', 'O', 'R', 'T', 'I', 'N', 'G'], rest: [[0, 2, 255]] })) == ['*', '5', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '7', '\r', '\n', 'S', 'E', 'T', 'S', 'L', 'O', 'T', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '9', '\r', '\n', 'I', 'M', 'P', 'O', 'R', 'T', 'I', 'N', 'G', '\r', '\n', '$', '3', '\r', '\n', 0, 2, 255, '\r', '\n']

expect Command.encode(Cluster.cluster_setslot(['1'], { first: ['S', 'T', 'A', 'B', 'L', 'E'], rest: [] })) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '7', '\r', '\n', 'S', 'E', 'T', 'S', 'L', 'O', 'T', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '6', '\r', '\n', 'S', 'T', 'A', 'B', 'L', 'E', '\r', '\n']

expect Command.encode(Cluster.cluster_shards({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '6', '\r', '\n', 'S', 'H', 'A', 'R', 'D', 'S', '\r', '\n']

expect Command.encode(Cluster.cluster_slaves([0, 1, 255])) == ['*', '3', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '6', '\r', '\n', 'S', 'L', 'A', 'V', 'E', 'S', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Cluster.cluster_slot_stats({ first: ['S', 'L', 'O', 'T', 'S', 'R', 'A', 'N', 'G', 'E'], rest: [['1'], ['2']] })) == ['*', '5', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '1', '0', '\r', '\n', 'S', 'L', 'O', 'T', '-', 'S', 'T', 'A', 'T', 'S', '\r', '\n', '$', '1', '0', '\r', '\n', 'S', 'L', 'O', 'T', 'S', 'R', 'A', 'N', 'G', 'E', '\r', '\n', '$', '1', '\r', '\n', '1', '\r', '\n', '$', '1', '\r', '\n', '2', '\r', '\n']

expect Command.encode(Cluster.cluster_slot_stats({ first: ['O', 'R', 'D', 'E', 'R', 'B', 'Y'], rest: [[0, 1, 255]] })) == ['*', '4', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '1', '0', '\r', '\n', 'S', 'L', 'O', 'T', '-', 'S', 'T', 'A', 'T', 'S', '\r', '\n', '$', '7', '\r', '\n', 'O', 'R', 'D', 'E', 'R', 'B', 'Y', '\r', '\n', '$', '3', '\r', '\n', 0, 1, 255, '\r', '\n']

expect Command.encode(Cluster.cluster_slots({})) == ['*', '2', '\r', '\n', '$', '7', '\r', '\n', 'C', 'L', 'U', 'S', 'T', 'E', 'R', '\r', '\n', '$', '5', '\r', '\n', 'S', 'L', 'O', 'T', 'S', '\r', '\n']

expect Command.encode(Cluster.readonly({})) == ['*', '1', '\r', '\n', '$', '8', '\r', '\n', 'R', 'E', 'A', 'D', 'O', 'N', 'L', 'Y', '\r', '\n']

expect Command.encode(Cluster.readwrite({})) == ['*', '1', '\r', '\n', '$', '9', '\r', '\n', 'R', 'E', 'A', 'D', 'W', 'R', 'I', 'T', 'E', '\r', '\n']
