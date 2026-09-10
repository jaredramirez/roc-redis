import /Bytes
import /Command
import /Commands/Decode
import /NonEmpty
import /Reply
import /Request
import /Resp

## Cluster administration, not routing or automatic MOVED/ASK retries.
## Slot numbers use U16; Redis validates the 0..16383 range and ownership.
## Topology/introspection schemas remain caller-decoded for version flexibility.
Cluster :: [].{
	SlotRange : { start : U16, end : U16 }
	SlotState : [Importing(Bytes.Bytes), Migrating(Bytes.Bytes), Node(Bytes.Bytes), Stable]

	## Current encodes the catalog's bare STATUS form; Redis 8.10.1 rejects it
	## with an arity error. Use All or Id on that server version.
	Migration : [Import(NonEmpty.NonEmpty(SlotRange)), Cancel([Id(Bytes.Bytes), All]), Status([Current, Id(Bytes.Bytes), All])]
	SlotFilter : [Range(SlotRange), OrderBy({ metric : Bytes.Bytes, limit : Reply.Optional(U64), order : [Ascending, Descending] })]

	meet : Bytes.Bytes, U16, Reply.Optional(U16) -> Request.Request({}, Reply.Error)
	meet = |host, port, bus_port| Request.new(
		Command.new(
			"CLUSTER",
			["MEET", host, decimal(port.to_u64())].concat(
				match bus_port {
					Absent => []
					Present(value) => [decimal(value.to_u64())]
				},
			),
		),
		Reply.okay,
	)

	set_slot : U16, SlotState -> Request.Request({}, Reply.Error)
	set_slot = |slot, state| Request.new(
		Command.new(
			"CLUSTER",
			["SETSLOT", decimal(slot.to_u64())].concat(
				match state {
					Importing(node) => ["IMPORTING", node]
					Migrating(node) => ["MIGRATING", node]
					Node(node) => ["NODE", node]
					Stable => ["STABLE"]
				},
			),
		),
		Reply.okay,
	)

	failover : [Default, Force, Takeover] -> Request.Request({}, Reply.Error)
	failover = |mode| Request.new(
		Command.new(
			"CLUSTER",
			["FAILOVER"].concat(
				match mode {
					Default => []
					Force => ["FORCE"]
					Takeover => ["TAKEOVER"]
				},
			),
		),
		Reply.okay,
	)

	reset : [Soft, Hard] -> Request.Request({}, Reply.Error)
	reset = |mode| Request.new(
		Command.new(
			"CLUSTER",
			[
				"RESET",
				match mode {
					Soft => "SOFT"
					Hard => "HARD"
				},
			],
		),
		Reply.okay,
	)

	migration : Migration, (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	migration = |mode, decode| {
		args = match mode {
			Import(ranges) => {
				var $args = ["IMPORT"]
				for range in ranges.to_list() {
					$args = $args.concat([decimal(range.start.to_u64()), decimal(range.end.to_u64())])
				}
				$args
			}
			Cancel(target) => ["CANCEL"].concat(
				match target {
					Id(id) => ["ID", id]
					All => ["ALL"]
				},
			)
			Status(target) => ["STATUS"].concat(
				match target {
					Current => []
					Id(id) => ["ID", id]
					All => ["ALL"]
				},
			)
		}
		Request.new(Command.new("CLUSTER", ["MIGRATION"].concat(args)), decode)
	}

	slot_stats : SlotFilter, (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	slot_stats = |filter, decode| {
		args = match filter {
			Range(range) => ["SLOTSRANGE", decimal(range.start.to_u64()), decimal(range.end.to_u64())]
			OrderBy(options) => ["ORDERBY", options.metric].concat(
				match options.limit {
					Absent => []
					Present(limit) => ["LIMIT", decimal(limit)]
				},
			).append(
				match options.order {
					Ascending => "ASC"
					Descending => "DESC"
				},
			)
		}
		Request.new(Command.new("CLUSTER", ["SLOT-STATS"].concat(args)), decode)
	}

	bump_epoch : () -> Request.Request(Bytes.Bytes, Reply.Error)
	bump_epoch = || Request.new(Command.new("CLUSTER", ["BUMPEPOCH"].concat([])), simple_bytes)

	flush_slots : () -> Request.Request({}, Reply.Error)
	flush_slots = || Request.new(Command.new("CLUSTER", ["FLUSHSLOTS"].concat([])), Reply.okay)

	save_config : () -> Request.Request({}, Reply.Error)
	save_config = || Request.new(Command.new("CLUSTER", ["SAVECONFIG"].concat([])), Reply.okay)

	info : () -> Request.Request(Bytes.Bytes, Reply.Error)
	info = || Request.new(Command.new("CLUSTER", ["INFO"].concat([])), Decode.bytes)

	my_id : () -> Request.Request(Bytes.Bytes, Reply.Error)
	my_id = || Request.new(Command.new("CLUSTER", ["MYID"].concat([])), Decode.bytes)

	my_shard_id : () -> Request.Request(Bytes.Bytes, Reply.Error)
	my_shard_id = || Request.new(Command.new("CLUSTER", ["MYSHARDID"].concat([])), Decode.bytes)

	nodes : () -> Request.Request(Bytes.Bytes, Reply.Error)
	nodes = || Request.new(Command.new("CLUSTER", ["NODES"].concat([])), Decode.bytes)

	forget : Bytes.Bytes -> Request.Request({}, Reply.Error)
	forget = |node| Request.new(Command.new("CLUSTER", ["FORGET"].concat([node])), Reply.okay)

	replicate : Bytes.Bytes -> Request.Request({}, Reply.Error)
	replicate = |node| Request.new(Command.new("CLUSTER", ["REPLICATE"].concat([node])), Reply.okay)

	replicas : Bytes.Bytes -> Request.Request(List(Bytes.Bytes), Reply.Error)
	replicas = |node| Request.new(Command.new("CLUSTER", ["REPLICAS"].concat([node])), Decode.bytes_list)

	slaves : Bytes.Bytes -> Request.Request(List(Bytes.Bytes), Reply.Error)
	slaves = |node| Request.new(Command.new("CLUSTER", ["SLAVES"].concat([node])), Decode.bytes_list)

	count_failure_reports : Bytes.Bytes -> Request.Request(I64, Reply.Error)
	count_failure_reports = |node| Request.new(Command.new("CLUSTER", ["COUNT-FAILURE-REPORTS"].concat([node])), Reply.integer)

	count_keys_in_slot : U16 -> Request.Request(I64, Reply.Error)
	count_keys_in_slot = |slot| Request.new(Command.new("CLUSTER", ["COUNTKEYSINSLOT"].concat([decimal(slot.to_u64())])), Reply.integer)

	get_keys_in_slot : U16, U64 -> Request.Request(List(Bytes.Bytes), Reply.Error)
	get_keys_in_slot = |slot, count| Request.new(Command.new("CLUSTER", ["GETKEYSINSLOT"].concat([decimal(slot.to_u64()), decimal(count)])), Decode.bytes_list)

	key_slot : Bytes.Bytes -> Request.Request(I64, Reply.Error)
	key_slot = |key| Request.new(Command.new("CLUSTER", ["KEYSLOT"].concat([key])), Reply.integer)

	set_config_epoch : U64 -> Request.Request({}, Reply.Error)
	set_config_epoch = |epoch| Request.new(Command.new("CLUSTER", ["SET-CONFIG-EPOCH"].concat([decimal(epoch)])), Reply.okay)

	add_slots : NonEmpty.NonEmpty(U16) -> Request.Request({}, Reply.Error)
	add_slots = |slots| Request.new(Command.new("CLUSTER", ["ADDSLOTS"].concat(slots.to_list().map(|slot| decimal(slot.to_u64())))), Reply.okay)

	del_slots : NonEmpty.NonEmpty(U16) -> Request.Request({}, Reply.Error)
	del_slots = |slots| Request.new(Command.new("CLUSTER", ["DELSLOTS"].concat(slots.to_list().map(|slot| decimal(slot.to_u64())))), Reply.okay)

	add_slots_range : NonEmpty.NonEmpty(SlotRange) -> Request.Request({}, Reply.Error)
	add_slots_range = |ranges| {
		var $args = ["ADDSLOTSRANGE"]
		for range in ranges.to_list() {
			$args = $args.concat([decimal(range.start.to_u64()), decimal(range.end.to_u64())])
		}
		Request.new(Command.new("CLUSTER", $args), Reply.okay)
	}

	del_slots_range : NonEmpty.NonEmpty(SlotRange) -> Request.Request({}, Reply.Error)
	del_slots_range = |ranges| {
		var $args = ["DELSLOTSRANGE"]
		for range in ranges.to_list() {
			$args = $args.concat([decimal(range.start.to_u64()), decimal(range.end.to_u64())])
		}
		Request.new(Command.new("CLUSTER", $args), Reply.okay)
	}

	links : (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	links = |decode| Request.new(Command.new("CLUSTER", ["LINKS"]), decode)

	shards : (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	shards = |decode| Request.new(Command.new("CLUSTER", ["SHARDS"]), decode)

	slots : (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	slots = |decode| Request.new(Command.new("CLUSTER", ["SLOTS"]), decode)

	## Changes state on this connection. Keep exclusive ownership until the
	## dependent request has completed; this library does not route it for you.
	asking : () -> Request.Request({}, Reply.Error)
	asking = || Request.new(Command.new("ASKING", []), Reply.okay)

	## Changes state on this connection. Keep exclusive ownership until the
	## dependent request has completed; this library does not route it for you.
	read_only : () -> Request.Request({}, Reply.Error)
	read_only = || Request.new(Command.new("READONLY", []), Reply.okay)

	## Changes state on this connection. Keep exclusive ownership until the
	## dependent request has completed; this library does not route it for you.
	read_write : () -> Request.Request({}, Reply.Error)
	read_write = || Request.new(Command.new("READWRITE", []), Reply.okay)
}

decimal : U64 -> Bytes.Bytes
decimal = |value| Bytes.from_str(value.to_str())

simple_bytes : Resp.Resp -> Try(Bytes.Bytes, Reply.Error)
simple_bytes = |reply| Reply.simple(reply).map_ok(Bytes.from_list)

expect Cluster.add_slots(NonEmpty.new(0, [16383])).command() == Command.new("CLUSTER", ["ADDSLOTS", "0", "16383"])
expect Cluster.add_slots_range(NonEmpty.new({ start: 1, end: 9 }, [{ start: 11, end: 12 }])).command() == Command.new("CLUSTER", ["ADDSLOTSRANGE", "1", "9", "11", "12"])
expect Cluster.set_slot(1, Importing("node")).command() == Command.new("CLUSTER", ["SETSLOT", "1", "IMPORTING", "node"])
expect Cluster.meet("127.0.0.1", 6379, Present(16379)).command() == Command.new("CLUSTER", ["MEET", "127.0.0.1", "6379", "16379"])
expect Cluster.bump_epoch().decode(Resp.simple_utf8("BUMPED 1")) == Ok(Bytes.from_str("BUMPED 1"))
expect Cluster.get_keys_in_slot(1, 10).decode(Resp.Array([Resp.bulk_utf8("key")])) == Ok([Bytes.from_str("key")])
expect Cluster.migration(Cancel(All), Reply.okay).command() == Command.new("CLUSTER", ["MIGRATION", "CANCEL", "ALL"])
expect Cluster.migration(Import(NonEmpty.new({ start: 1, end: 2 }, [{ start: 4, end: 5 }])), Reply.bulk).command() == Command.new("CLUSTER", ["MIGRATION", "IMPORT", "1", "2", "4", "5"])
expect Cluster.slot_stats(OrderBy({ metric: "key-count", limit: Present(10), order: Descending }), Reply.array).command() == Command.new("CLUSTER", ["SLOT-STATS", "ORDERBY", "key-count", "LIMIT", "10", "DESC"])
expect Cluster.asking().decode(Resp.simple_utf8("OK")) == Ok({})
