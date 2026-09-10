import /Bytes
import /Command
import /Commands/Decode
import /NonEmpty
import /Positive
import /Reply
import /Request
import /Resp

## Server administration. Construction is pure; execution can be destructive
## or privileged. No command here is run automatically for connection setup.
Server :: [].{
	Pair : { name : Bytes.Bytes, value : Bytes.Bytes }
	FlushMode : [Default, Sync, Async]
	CommandFilter : [All, Module(Bytes.Bytes), Category(Bytes.Bytes), Pattern(Bytes.Bytes)]
	Failover : [Abort, Start({ target : Reply.Optional({ host : Bytes.Bytes, port : U16, force : Bool }), timeout_ms : Reply.Optional(U64) })]
	Replica : [Independent, Follow({ host : Bytes.Bytes, port : U16 })]
	Shutdown : [Abort, Stop({ persistence : [Default, Save, NoSave], now : Bool, force : Bool })]
	HotkeyOptions := { count : Reply.Optional(Positive.Positive) ?? Absent, duration_seconds : Reply.Optional(Positive.Positive) ?? Absent, sample_ratio : Reply.Optional(Positive.Positive) ?? Absent, slots : List(U16) ?? [] }
	LogMode : [Get(Reply.Optional(U64)), Reset]
	LogResult : [Entries(List(Resp.Resp)), Reset]
	LatencySample : { timestamp : I64, milliseconds : I64 }
	LatencyEvent : { event : Bytes.Bytes, timestamp : I64, milliseconds : I64, maximum_ms : I64 }

	acl_dry_run : Bytes.Bytes, Command.Command -> Request.Request({}, Reply.Error)
	acl_dry_run = |username, command| Request.new(Command.new("ACL", ["DRYRUN", username].concat(command.to_parts().map(Bytes.from_list))), Reply.okay)

	acl_log : LogMode -> Request.Request(LogResult, Reply.Error)
	acl_log = |mode| Request.new(
		Command.new(
			"ACL",
			["LOG"].concat(
				match mode {
					Get(count) => optional_count(count)
					Reset => ["RESET"]
				},
			),
		),
		|reply| match mode {
			Get(_) => Reply.array(reply).map_ok(|entries| Entries(entries))
			Reset => Reply.okay(reply).map_ok(|_| Reset)
		},
	)

	command_list : CommandFilter -> Request.Request(List(Bytes.Bytes), Reply.Error)
	command_list = |filter| Request.new(
		Command.new(
			"COMMAND",
			["LIST"].concat(
				match filter {
					All => []
					Module(name) => ["FILTERBY", "MODULE", name]
					Category(name) => ["FILTERBY", "ACLCAT", name]
					Pattern(pattern) => ["FILTERBY", "PATTERN", pattern]
				},
			),
		),
		Decode.bytes_list,
	)

	config_get : NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(Pair), Reply.Error)
	config_get = |patterns| Request.new(Command.new("CONFIG", ["GET"].concat(patterns.to_list())), pairs)

	config_set : NonEmpty.NonEmpty(Pair) -> Request.Request({}, Reply.Error)
	config_set = |settings| {
		var $args = ["SET"]
		for setting in settings.to_list() {
			$args = $args.concat([setting.name, setting.value])
		}
		Request.new(Command.new("CONFIG", $args), Reply.okay)
	}

	failover : Failover -> Request.Request({}, Reply.Error)
	failover = |mode| {
		args = match mode {
			Abort => ["ABORT"]
			Start(options) => (match options.target {
				Absent => []
				Present(target) => ["TO", target.host, decimal(target.port.to_u64())].concat(
					if target.force {
						["FORCE"]
					} else {
						[]
					},
				)
			}).concat(number_option("TIMEOUT", options.timeout_ms))
		}
		Request.new(Command.new("FAILOVER", args), Reply.okay)
	}

	hotkeys_start : [Cpu, Network, Both], HotkeyOptions -> Request.Request({}, Reply.Error)
	hotkeys_start = |metrics, options| {
		args = ["START", "METRICS"].concat(
			match metrics {
				Cpu => ["1", "CPU"]
				Network => ["1", "NET"]
				Both => ["2", "CPU", "NET"]
			},
		)
			.concat(positive_option("COUNT", options.count)).concat(positive_option("DURATION", options.duration_seconds)).concat(positive_option("SAMPLE", options.sample_ratio))
			.concat(
				if options.slots.is_empty() {
					[]
				} else {
					["SLOTS", decimal(options.slots.len())].concat(options.slots.map(|slot| decimal(slot.to_u64())))
				},
			)
		Request.new(Command.new("HOTKEYS", args), Reply.okay)
	}

	module_load_ex : Bytes.Bytes, List(Pair), List(Bytes.Bytes) -> Request.Request({}, Reply.Error)
	module_load_ex = |path, configs, args| {
		var $arguments = ["LOADEX", path]
		for config in configs {
			$arguments = $arguments.concat(["CONFIG", config.name, config.value])
		}
		if !args.is_empty() {
			$arguments = $arguments.append("ARGS").concat(args)
		}
		Request.new(Command.new("MODULE", $arguments), Reply.okay)
	}

	memory_usage : Bytes.Bytes, Reply.Optional(U64) -> Request.Request(Reply.Optional(I64), Reply.Error)
	memory_usage = |key, samples| Request.new(
		Command.new("MEMORY", ["USAGE", key].concat(number_option("SAMPLES", samples))),
		|reply| match reply {
			NullBulkString => Ok(Absent)
			_ => Reply.integer(reply).map_ok(|value| Present(value))
		},
	)

	latency_history : Bytes.Bytes -> Request.Request(List(LatencySample), Reply.Error)
	latency_history = |event| Request.new(
		Command.new("LATENCY", ["HISTORY", event]),
		|reply| Decode.list(
			reply,
			|sample| match sample {
				Array([timestamp, milliseconds]) => Ok({ timestamp: Reply.integer(timestamp)?, milliseconds: Reply.integer(milliseconds)? })
				_ => Err(UnexpectedReply({ actual: sample, expected: ArrayReply }))
			},
		),
	)

	latency_latest : () -> Request.Request(List(LatencyEvent), Reply.Error)
	latency_latest = || Request.new(
		Command.new("LATENCY", ["LATEST"]),
		|reply| Decode.list(
			reply,
			|sample| match sample {
				Array([event, timestamp, milliseconds, maximum]) => Ok({ event: Decode.bytes(event)?, timestamp: Reply.integer(timestamp)?, milliseconds: Reply.integer(milliseconds)?, maximum_ms: Reply.integer(maximum)? })
				_ => Err(UnexpectedReply({ actual: sample, expected: ArrayReply }))
			},
		),
	)

	time : () -> Request.Request({ seconds : U64, microseconds : U64 }, Reply.Error)
	time = || Request.new(
		Command.new("TIME", []),
		|reply| match reply {
			Array([seconds, microseconds]) => {
				fraction = unsigned_bulk(microseconds)?
				if fraction >= 1_000_000 {
					return Err(UnexpectedReply({ actual: microseconds, expected: BulkReply }))
				}
				Ok({ seconds: unsigned_bulk(seconds)?, microseconds: fraction })
			}
			_ => Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
		},
	)

	trim_slots : NonEmpty.NonEmpty({ start : U16, end : U16 }) -> Request.Request({}, Reply.Error)
	trim_slots = |ranges| {
		var $args = ["RANGES", decimal(ranges.len())]
		for range in ranges.to_list() {
			$args = $args.concat([decimal(range.start.to_u64()), decimal(range.end.to_u64())])
		}
		Request.new(Command.new("TRIMSLOTS", $args), Reply.okay)
	}

	## MONITOR begins an unbounded feed. Use a dedicated streaming adapter,
	## never Execute.request! or Execute.no_reply! on an ordinary connection.
	monitor : () -> Command.Command
	monitor = || Command.new("MONITOR", [])

	## Successful shutdown closes the connection without a reply; errors still
	## reply. A dedicated shutdown adapter must distinguish these outcomes.
	shutdown : Shutdown -> Command.Command
	shutdown = |mode| Command.new(
		"SHUTDOWN",
		match mode {
			Abort => ["ABORT"]
			Stop(options) => (match options.persistence {
				Default => []
				Save => ["SAVE"]
				NoSave => ["NOSAVE"]
			})
				.concat(
					if options.now {
						["NOW"]
					} else {
						[]
					},
				).concat(
				if options.force {
					["FORCE"]
				} else {
					[]
				},
			)
		},
	)

	## Unlike successful shutdown, ABORT has a normal acknowledgement.
	shutdown_abort : () -> Request.Request({}, Reply.Error)
	shutdown_abort = || Request.new(Command.new("SHUTDOWN", ["ABORT"]), Reply.okay)

	acl_cat : Reply.Optional(Bytes.Bytes) -> Request.Request(List(Bytes.Bytes), Reply.Error)
	acl_cat = |category| Request.new(Command.new("ACL", ["CAT"].concat(optional_bytes(category))), Decode.bytes_list)

	acl_del_user : NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	acl_del_user = |users| Request.new(Command.new("ACL", ["DELUSER"].concat(users.to_list())), Reply.integer)

	acl_gen_pass : Reply.Optional(U64) -> Request.Request(Bytes.Bytes, Reply.Error)
	acl_gen_pass = |bits| Request.new(Command.new("ACL", ["GENPASS"].concat(optional_count(bits))), Decode.bytes)

	acl_list : () -> Request.Request(List(Bytes.Bytes), Reply.Error)
	acl_list = || Request.new(Command.new("ACL", ["LIST"]), Decode.bytes_list)

	acl_load : () -> Request.Request({}, Reply.Error)
	acl_load = || Request.new(Command.new("ACL", ["LOAD"]), Reply.okay)

	acl_save : () -> Request.Request({}, Reply.Error)
	acl_save = || Request.new(Command.new("ACL", ["SAVE"]), Reply.okay)

	acl_set_user : Bytes.Bytes, List(Bytes.Bytes) -> Request.Request({}, Reply.Error)
	acl_set_user = |username, rules| Request.new(Command.new("ACL", ["SETUSER", username].concat(rules)), Reply.okay)

	acl_users : () -> Request.Request(List(Bytes.Bytes), Reply.Error)
	acl_users = || Request.new(Command.new("ACL", ["USERS"]), Decode.bytes_list)

	acl_who_am_i : () -> Request.Request(Bytes.Bytes, Reply.Error)
	acl_who_am_i = || Request.new(Command.new("ACL", ["WHOAMI"]), Decode.bytes)

	backup_abort : () -> Request.Request({}, Reply.Error)
	backup_abort = || Request.new(Command.new("BACKUP", ["ABORT"]), Reply.okay)

	backup_cleanup : () -> Request.Request({}, Reply.Error)
	backup_cleanup = || Request.new(Command.new("BACKUP", ["CLEANUP"]), Reply.okay)

	backup_seal : () -> Request.Request({}, Reply.Error)
	backup_seal = || Request.new(Command.new("BACKUP", ["SEAL"]), Reply.okay)

	backup_start : () -> Request.Request({}, Reply.Error)
	backup_start = || Request.new(Command.new("BACKUP", ["START"]), Reply.okay)

	bgrewrite_aof : () -> Request.Request(Bytes.Bytes, Reply.Error)
	bgrewrite_aof = || Request.new(Command.new("BGREWRITEAOF", []), simple_bytes)

	bgsave : Bool -> Request.Request(Bytes.Bytes, Reply.Error)
	bgsave = |schedule| Request.new(
		Command.new(
			"BGSAVE",
			if schedule {
				["SCHEDULE"]
			} else {
				[]
			},
		),
		simple_bytes,
	)

	command_count : () -> Request.Request(I64, Reply.Error)
	command_count = || Request.new(Command.new("COMMAND", ["COUNT"]), Reply.integer)

	command_get_keys : Command.Command -> Request.Request(List(Bytes.Bytes), Reply.Error)
	command_get_keys = |command| Request.new(Command.new("COMMAND", ["GETKEYS"].concat(command.to_parts().map(Bytes.from_list))), Decode.bytes_list)

	config_reset_stat : () -> Request.Request({}, Reply.Error)
	config_reset_stat = || Request.new(Command.new("CONFIG", ["RESETSTAT"]), Reply.okay)

	config_rewrite : () -> Request.Request({}, Reply.Error)
	config_rewrite = || Request.new(Command.new("CONFIG", ["REWRITE"]), Reply.okay)

	dbsize : () -> Request.Request(I64, Reply.Error)
	dbsize = || Request.new(Command.new("DBSIZE", []), Reply.integer)

	flush_all : FlushMode -> Request.Request({}, Reply.Error)
	flush_all = |mode| Request.new(Command.new("FLUSHALL", flush_args(mode)), Reply.okay)

	flush_db : FlushMode -> Request.Request({}, Reply.Error)
	flush_db = |mode| Request.new(Command.new("FLUSHDB", flush_args(mode)), Reply.okay)

	hotkeys_reset : () -> Request.Request({}, Reply.Error)
	hotkeys_reset = || Request.new(Command.new("HOTKEYS", ["RESET"]), Reply.okay)

	hotkeys_stop : () -> Request.Request({}, Reply.Error)
	hotkeys_stop = || Request.new(Command.new("HOTKEYS", ["STOP"]), Reply.okay)

	info : List(Bytes.Bytes) -> Request.Request(Bytes.Bytes, Reply.Error)
	info = |sections| Request.new(Command.new("INFO", sections), Decode.bytes)

	last_save : () -> Request.Request(I64, Reply.Error)
	last_save = || Request.new(Command.new("LASTSAVE", []), Reply.integer)

	latency_doctor : () -> Request.Request(Bytes.Bytes, Reply.Error)
	latency_doctor = || Request.new(Command.new("LATENCY", ["DOCTOR"]), Decode.bytes)

	latency_graph : Bytes.Bytes -> Request.Request(Bytes.Bytes, Reply.Error)
	latency_graph = |event| Request.new(Command.new("LATENCY", ["GRAPH", event]), Decode.bytes)

	latency_reset : List(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	latency_reset = |events| Request.new(Command.new("LATENCY", ["RESET"].concat(events)), Reply.integer)

	lolwut : Reply.Optional(U64) -> Request.Request(Bytes.Bytes, Reply.Error)
	lolwut = |version| Request.new(Command.new("LOLWUT", number_option("VERSION", version)), Decode.bytes)

	memory_doctor : () -> Request.Request(Bytes.Bytes, Reply.Error)
	memory_doctor = || Request.new(Command.new("MEMORY", ["DOCTOR"]), Decode.bytes)

	memory_malloc_stats : () -> Request.Request(Bytes.Bytes, Reply.Error)
	memory_malloc_stats = || Request.new(Command.new("MEMORY", ["MALLOC-STATS"]), Decode.bytes)

	memory_purge : () -> Request.Request({}, Reply.Error)
	memory_purge = || Request.new(Command.new("MEMORY", ["PURGE"]), Reply.okay)

	module_load : Bytes.Bytes, List(Bytes.Bytes) -> Request.Request({}, Reply.Error)
	module_load = |path, args| Request.new(Command.new("MODULE", ["LOAD", path].concat(args)), Reply.okay)

	module_unload : Bytes.Bytes -> Request.Request({}, Reply.Error)
	module_unload = |name| Request.new(Command.new("MODULE", ["UNLOAD", name]), Reply.okay)

	replica_of : Replica -> Request.Request({}, Reply.Error)
	replica_of = |replica| Request.new(Command.new("REPLICAOF", replica_args(replica)), Reply.okay)

	slave_of : Replica -> Request.Request({}, Reply.Error)
	slave_of = |replica| Request.new(Command.new("SLAVEOF", replica_args(replica)), Reply.okay)

	save : () -> Request.Request({}, Reply.Error)
	save = || Request.new(Command.new("SAVE", []), Reply.okay)

	slowlog_len : () -> Request.Request(I64, Reply.Error)
	slowlog_len = || Request.new(Command.new("SLOWLOG", ["LEN"]), Reply.integer)

	slowlog_reset : () -> Request.Request({}, Reply.Error)
	slowlog_reset = || Request.new(Command.new("SLOWLOG", ["RESET"]), Reply.okay)

	swap_db : U64, U64 -> Request.Request({}, Reply.Error)
	swap_db = |first, second| Request.new(Command.new("SWAPDB", [decimal(first), decimal(second)]), Reply.okay)

	## Version-extensible administration reply; supply the schema you need.
	acl_get_user : Bytes.Bytes, (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	acl_get_user = |username, decode| Request.new(Command.new("ACL", ["GETUSER", username]), decode)

	## Version-extensible administration reply; supply the schema you need.
	backup_list : (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	backup_list = |decode| Request.new(Command.new("BACKUP", ["LIST"]), decode)

	## Version-extensible administration reply; supply the schema you need.
	backup_status : (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	backup_status = |decode| Request.new(Command.new("BACKUP", ["STATUS"]), decode)

	## Version-extensible administration reply; supply the schema you need.
	command : (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	command = |decode| Request.new(Command.new("COMMAND", []), decode)

	## Version-extensible administration reply; supply the schema you need.
	command_docs : List(Bytes.Bytes), (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	command_docs = |commands, decode| Request.new(Command.new("COMMAND", ["DOCS"].concat(commands)), decode)

	## Version-extensible administration reply; supply the schema you need.
	command_info : List(Bytes.Bytes), (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	command_info = |commands, decode| Request.new(Command.new("COMMAND", ["INFO"].concat(commands)), decode)

	## Version-extensible administration reply; supply the schema you need.
	command_get_keys_and_flags : Command.Command, (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	command_get_keys_and_flags = |invocation, decode| Request.new(Command.new("COMMAND", ["GETKEYSANDFLAGS"].concat(invocation.to_parts().map(Bytes.from_list))), decode)

	## Version-extensible administration reply; supply the schema you need.
	hotkeys_get : (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	hotkeys_get = |decode| Request.new(Command.new("HOTKEYS", ["GET"]), decode)

	## Version-extensible administration reply; supply the schema you need.
	latency_histogram : List(Bytes.Bytes), (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	latency_histogram = |commands, decode| Request.new(Command.new("LATENCY", ["HISTOGRAM"].concat(commands)), decode)

	## Version-extensible administration reply; supply the schema you need.
	memory_stats : (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	memory_stats = |decode| Request.new(Command.new("MEMORY", ["STATS"]), decode)

	## Version-extensible administration reply; supply the schema you need.
	module_list : (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	module_list = |decode| Request.new(Command.new("MODULE", ["LIST"]), decode)

	## Version-extensible administration reply; supply the schema you need.
	role : (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	role = |decode| Request.new(Command.new("ROLE", []), decode)

	## Version-extensible administration reply; supply the schema you need.
	slowlog_get : Reply.Optional(I64), (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	slowlog_get = |count, decode| Request.new(
		Command.new(
			"SLOWLOG",
			["GET"].concat(
				match count {
					Absent => []
					Present(value) => [Bytes.from_str(value.to_str())]
				},
			),
		),
		decode,
	)
}

decimal : U64 -> Bytes.Bytes
decimal = |value| Bytes.from_str(value.to_str())

optional_count : Reply.Optional(U64) -> List(Bytes.Bytes)
optional_count = |value| match value {
	Absent => []
	Present(number) => [decimal(number)]
}

optional_bytes : Reply.Optional(Bytes.Bytes) -> List(Bytes.Bytes)
optional_bytes = |value| match value {
	Absent => []
	Present(data) => [data]
}

number_option : Bytes.Bytes, Reply.Optional(U64) -> List(Bytes.Bytes)
number_option = |name, value| match value {
	Absent => []
	Present(number) => [name, decimal(number)]
}

positive_option : Bytes.Bytes, Reply.Optional(Positive.Positive) -> List(Bytes.Bytes)
positive_option = |name, value| match value {
	Absent => []
	Present(number) => [name, decimal(number.to_u64())]
}

flush_args : Server.FlushMode -> List(Bytes.Bytes)
flush_args = |mode| match mode {
	Default => []
	Sync => ["SYNC"]
	Async => ["ASYNC"]
}

replica_args : Server.Replica -> List(Bytes.Bytes)
replica_args = |replica| match replica {
	Independent => ["NO", "ONE"]
	Follow(target) => [target.host, decimal(target.port.to_u64())]
}

simple_bytes : Resp.Resp -> Try(Bytes.Bytes, Reply.Error)
simple_bytes = |reply| Reply.simple(reply).map_ok(Bytes.from_list)

unsigned_bulk : Resp.Resp -> Try(U64, Reply.Error)
unsigned_bulk = |reply| {
	data = Reply.bulk(reply)?
	string = Str.from_utf8(data).map_err(|_| UnexpectedReply({ actual: reply, expected: BulkReply }))?
	U64.from_str(string).map_err(|_| UnexpectedReply({ actual: reply, expected: BulkReply }))
}

pairs : Resp.Resp -> Try(List(Server.Pair), Reply.Error)
pairs = |reply| {
	items = Reply.array(reply)?
	if items.len() % 2 != 0 {
		return Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
	}
	var $pairs = List.with_capacity(items.len() / 2)
	var $remaining = items
	while !$remaining.is_empty() {
		match $remaining {
			[name, value, .. as rest] => {
				$pairs = $pairs.append({ name: Decode.bytes(name)?, value: Decode.bytes(value)? })
				$remaining = rest
			}
			_ => return Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
		}
	}
	Ok($pairs)
}

expect Server.acl_dry_run("u", Command.new("GET", ["key"])).command() == Command.new("ACL", ["DRYRUN", "u", "GET", "key"])
expect Server.config_set(NonEmpty.new({ name: Bytes.from_str("a"), value: Bytes.from_str("1") }, [{ name: "b", value: "2" }])).command() == Command.new("CONFIG", ["SET", "a", "1", "b", "2"])
expect Server.config_get(NonEmpty.new(Bytes.from_str("*"), [])).decode(Resp.Array([Resp.bulk_utf8("port"), Resp.bulk_utf8("6379")])) == Ok([{ name: Bytes.from_str("port"), value: Bytes.from_str("6379") }])
expect Server.config_get(NonEmpty.new(Bytes.from_str("*"), [])).decode(Resp.Array([Resp.bulk_utf8("port")])).is_err()
expect Server.hotkeys_start(Both, { count: Present(10), slots: [1, 2] }).command() == Command.new("HOTKEYS", ["START", "METRICS", "2", "CPU", "NET", "COUNT", "10", "SLOTS", "2", "1", "2"])
expect Server.module_load_ex("module.so", [{ name: "a", value: "b" }, { name: "c", value: "d" }], ["x"]).command() == Command.new("MODULE", ["LOADEX", "module.so", "CONFIG", "a", "b", "CONFIG", "c", "d", "ARGS", "x"])
expect Server.acl_log(Reset).decode(Resp.simple_utf8("OK")) == Ok(Reset)
expect Server.acl_log(Get(Absent)).decode(Resp.Array([])) == Ok(Entries([]))
expect Server.time().decode(Resp.Array([Resp.bulk_utf8("123"), Resp.bulk_utf8("456")])) == Ok({ seconds: 123, microseconds: 456 })
expect Server.time().decode(Resp.Array([Resp.bulk_utf8("123"), Resp.bulk_utf8("1000000")])).is_err()
expect Server.memory_usage("missing", Absent).decode(Resp.NullBulkString) == Ok(Absent)
expect Server.memory_usage("missing", Absent).decode(Resp.NullArray).is_err()
expect Server.shutdown(Stop({ persistence: NoSave, now: True, force: False })) == Command.new("SHUTDOWN", ["NOSAVE", "NOW"])
expect Server.monitor() == Command.new("MONITOR", [])
expect Server.replica_of(Independent).command() == Command.new("REPLICAOF", ["NO", "ONE"])
expect Server.trim_slots(NonEmpty.new({ start: 1, end: 2 }, [{ start: 4, end: 5 }])).command() == Command.new("TRIMSLOTS", ["RANGES", "2", "1", "2", "4", "5"])
