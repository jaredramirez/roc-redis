## Snapshot, generate, and verify the Redis OSS command-construction catalog.
##
## The platform is used only for filesystem and child-process effects. Manifest
## validation and Roc source generation remain pure and deterministic.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
}

import HarnessText
import pf.Cmd
import pf.Env
import pf.OsStr
import pf.Path
import pf.Random
import pf.Sleep
import pf.Stderr
import pf.Stdout

redis_version : Str
redis_version = "8.10.1"

manifest_path : Path.Path
manifest_path = Path.utf8("metadata/redis-8.10.1-command-catalog.json")

command_timeout : Str
command_timeout = "10s"

startup_attempts : U8
startup_attempts = 20

pidfile_attempts : U8
pidfile_attempts = 100

# Redis 7.0 redis-cli has no -t option. GNU timeout bounds the whole probe.
expect !(watchdog_launch_script.contains(" -t ")) and watchdog_launch_script.contains("--kill-after=1s")

watchdog_launch_script : Str
watchdog_launch_script = Str.join_with(
	[
		"set -eu;",
		"safe_pid() { case \"$1\" in ''|*[!0-9]*) return 1;;",
		"esac;",
		"[ \"$1\" -gt 1 ] 2>/dev/null;",
		"};",
		"context_is_owned() { case \"$TEMP_DIR\" in /tmp/rrc-*) ;;",
		"*) return 1;;",
		"esac;",
		"owner=;",
		"if [ -r \"$OWNER_FILE\" ];",
		"then IFS= read -r owner <\"$OWNER_FILE\" || owner=;",
		"fi;",
		"[ \"$owner\" = \"$HARNESS_PID\" ];",
		"};",
		"redis_is_owner() { candidate=$1;",
		"safe_pid \"$candidate\" || return 1;",
		"context_is_owned || return 1;",
		"info=$(\"$TIMEOUT_PROGRAM\" --signal=TERM --kill-after=1s 1s \"$REDIS_CLI\" --raw -s \"$REDIS_SOCKET\" INFO server 2>/dev/null) || return 1;",
		"info=$(printf '%s' \"$info\" | tr -d '\\r');",
		"nl='\n';",
		"case \"$nl$info$nl\" in *\"$nl\"\"process_id:$candidate\"\"$nl\"*) return 0;;",
		"*) return 1;;",
		"esac;",
		"};",
		"redis_endpoint_absent() { status=0;",
		"\"$TIMEOUT_PROGRAM\" --signal=TERM --kill-after=1s 1s \"$REDIS_CLI\" --raw -s \"$REDIS_SOCKET\" PING >/dev/null 2>&1 || status=$?;",
		"[ \"$status\" -eq 1 ] || return 1;",
		"sleep 0.05;",
		"status=0;",
		"\"$TIMEOUT_PROGRAM\" --signal=TERM --kill-after=1s 1s \"$REDIS_CLI\" --raw -s \"$REDIS_SOCKET\" PING >/dev/null 2>&1 || status=$?;",
		"[ \"$status\" -eq 1 ];",
		"};",
		"(while kill -0 \"$HARNESS_PID\" 2>/dev/null && [ ! -e \"$CLEANUP_REQUEST\" ];",
		"do sleep 0.1;",
		"done;",
		"limit=300;",
		"if [ -e \"$CLEANUP_REQUEST\" ];",
		"then limit=100;",
		"fi;",
		"owned=0;",
		"child=;",
		"attempt=0;",
		"while [ \"$attempt\" -lt \"$limit\" ];",
		"do child=;",
		"if [ -r \"$REDIS_PIDFILE\" ];",
		"then IFS= read -r child <\"$REDIS_PIDFILE\" || child=;",
		"fi;",
		"if ! safe_pid \"$child\";",
		"then printf 'pending\\n' >\"$PENDING_ACK\";",
		"fi;",
		"if safe_pid \"$child\" && kill -0 \"$child\" 2>/dev/null && redis_is_owner \"$child\";",
		"then owned=1;",
		"break;",
		"fi;",
		"sleep 0.05;",
		"attempt=$((attempt + 1));",
		"done;",
		"preserve=1;",
		"if safe_pid \"$child\" && kill -0 \"$child\" 2>/dev/null;",
		"then if [ \"$owned\" -eq 1 ] && redis_is_owner \"$child\";",
		"then kill -TERM \"$child\" 2>/dev/null || true;",
		"attempt=0;",
		"while kill -0 \"$child\" 2>/dev/null && [ \"$attempt\" -lt 40 ];",
		"do sleep 0.05;",
		"attempt=$((attempt + 1));",
		"done;",
		"if kill -0 \"$child\" 2>/dev/null && redis_is_owner \"$child\";",
		"then kill -KILL \"$child\" 2>/dev/null || true;",
		"attempt=0;",
		"while kill -0 \"$child\" 2>/dev/null && [ \"$attempt\" -lt 40 ];",
		"do sleep 0.05;",
		"attempt=$((attempt + 1));",
		"done;",
		"fi;",
		"fi;",
		"fi;",
		"if { ! safe_pid \"$child\" || ! kill -0 \"$child\" 2>/dev/null;",
		"} && redis_endpoint_absent;",
		"then preserve=0;",
		"fi;",
		"if [ \"$preserve\" -eq 0 ] && context_is_owned;",
		"then rm -f -- \"$REDIS_SOCKET\" \"$REDIS_PIDFILE\" \"$TEMP_DIR/redis.log\" \"$WATCHDOG_PIDFILE\" \"$OWNER_FILE\" \"$CLEANUP_REQUEST\" \"$PENDING_ACK\";",
		"rmdir -- \"$TEMP_DIR\" 2>/dev/null || true;",
		"fi) </dev/null >/dev/null 2>&1 &",
		"watchdog=$!;",
		"printf '%s\\n' \"$watchdog\" >\"$WATCHDOG_PIDFILE\";",
		"printf '%s\\n' \"$watchdog\"",
	],
	" ",
)

watchdog_wrapper_script : Str
watchdog_wrapper_script = "set -eu; if [ -n \"$MONITORED_PID\" ]; then HARNESS_PID=$MONITORED_PID; else HARNESS_PID=$PPID; fi; case \"$HARNESS_PID\" in ''|*[!0-9]*) exit 64;; esac; [ \"$HARNESS_PID\" -gt 1 ] 2>/dev/null || exit 64; export HARNESS_PID; printf '%s\\n' \"$HARNESS_PID\" >\"$OWNER_FILE\"; exec \"$1\" --signal=TERM --kill-after=2s 5s sh -c \"$2\""

expected_scoped_count : U64
expected_scoped_count = 449

expected_included_count : U64
expected_included_count = 405

expected_public_contract : List(Str)
expected_public_contract = ["COMMAND LIST", "COMMAND DOCS", "COMMAND INFO"]

scope_groups : List(Str)
scope_groups = [
	"generic",
	"string",
	"hash",
	"list",
	"set",
	"sorted-set",
	"stream",
	"bitmap",
	"hyperloglog",
	"geo",
	"array",
	"module",
	"cluster",
	"connection",
	"pubsub",
	"scripting",
	"server",
	"transactions",
]

module_policies : List({ group : Str, module_name : Str, count : U64 })
module_policies = [
	{ group: "generic", module_name: "Keyspace", count: 32 },
	{ group: "string", module_name: "Strings", count: 26 },
	{ group: "hash", module_name: "Hashes", count: 32 },
	{ group: "list", module_name: "Lists", count: 24 },
	{ group: "set", module_name: "Sets", count: 19 },
	{ group: "sorted-set", module_name: "SortedSets", count: 35 },
	{ group: "stream", module_name: "Streams", count: 24 },
	{ group: "bitmap", module_name: "Bitmaps", count: 7 },
	{ group: "hyperloglog", module_name: "HyperLogLog", count: 3 },
	{ group: "geo", module_name: "Geo", count: 10 },
	{ group: "array", module_name: "Arrays", count: 18 },
	{ group: "module", module_name: "VectorSets", count: 13 },
	{ group: "cluster", module_name: "Cluster", count: 32 },
	{ group: "connection", module_name: "Connect", count: 24 },
	{ group: "pubsub", module_name: "PubSub", count: 13 },
	{ group: "scripting", module_name: "Scripting", count: 19 },
	{ group: "server", module_name: "Server", count: 69 },
	{ group: "transactions", module_name: "Transactions", count: 5 },
]

vector_set_commands : List(Str)
vector_set_commands = [
	"vadd",
	"vcard",
	"vdim",
	"vemb",
	"vgetattr",
	"vinfo",
	"vismember",
	"vlinks",
	"vrandmember",
	"vrange",
	"vrem",
	"vsetattr",
	"vsim",
]

vector_constructor_overrides : List(Str)
vector_constructor_overrides = ["vadd", "vsim"]

constructor_argument_overrides : List(Str)
constructor_argument_overrides = ["hotkeys|start", "vadd", "vsim"]

exclusion_policies : List({ command : Str, reason : Str })
exclusion_policies = [
	{ command: "acl", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "acl|help", reason: "HELP-only command, not an operational API" },
	{ command: "backup", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "backup|help", reason: "HELP-only command, not an operational API" },
	{ command: "client", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "client|help", reason: "HELP-only command, not an operational API" },
	{ command: "cluster", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "cluster|help", reason: "HELP-only command, not an operational API" },
	{ command: "cluster|syncslots", reason: "Redis documents this as an internal cluster migration command" },
	{ command: "command|help", reason: "HELP-only command, not an operational API" },
	{ command: "config", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "config|help", reason: "HELP-only command, not an operational API" },
	{ command: "debug", reason: "Redis marks this internal debugging command as SYSCMD" },
	{ command: "function", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "function|help", reason: "HELP-only command, not an operational API" },
	{ command: "himport", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "hotkeys", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "hotkeys|help", reason: "HELP-only command, not an operational API" },
	{ command: "latency", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "latency|help", reason: "HELP-only command, not an operational API" },
	{ command: "memory", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "memory|help", reason: "HELP-only command, not an operational API" },
	{ command: "module", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "module|help", reason: "HELP-only command, not an operational API" },
	{ command: "object", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "object|help", reason: "HELP-only command, not an operational API" },
	{ command: "pfdebug", reason: "Redis marks this internal debugging command as SYSCMD" },
	{ command: "pfselftest", reason: "Redis marks this internal test command as SYSCMD" },
	{ command: "psync", reason: "Redis documents this as an internal replication command" },
	{ command: "pubsub", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "pubsub|help", reason: "HELP-only command, not an operational API" },
	{ command: "replconf", reason: "Redis marks this internal replication command as SYSCMD" },
	{ command: "restore-asking", reason: "Redis marks this internal cluster migration command as SYSCMD" },
	{ command: "script", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "script|help", reason: "HELP-only command, not an operational API" },
	{ command: "slowlog", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "slowlog|help", reason: "HELP-only command, not an operational API" },
	{ command: "sync", reason: "Redis documents this as an internal replication command" },
	{ command: "xgroup", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "xgroup|help", reason: "HELP-only command, not an operational API" },
	{ command: "xidmprecord", reason: "Redis documents this as an internal AOF-replay command" },
	{ command: "xinfo", reason: "container-only command; use its ordinary subcommand constructors" },
	{ command: "xinfo|help", reason: "HELP-only command, not an operational API" },
	{ command: "xsetid", reason: "Redis documents this as an internal stream replication command" },
]

Argument := {
	name : Str,
	type : Str,
	token : Str,
	flags : List(Str),
	arguments : List(Argument),
}.{}

ConstructorArguments : [Original, Override(List(Argument))]

Entry : {
	command : Str,
	group : Str,
	arity : I64,
	since : Str,
	arguments : List(Argument),
	module_name : Str,
	constructor : Str,
	doc_flags : List(Str),
	constructor_arguments : ConstructorArguments,
	status : Str,
	reason : Str,
}

Provenance : {
	contract : List(Str),
	description : Str,
	scoped_command_count : U64,
	module_group_commands : List(Str),
	constructor_argument_overrides : List(Str),
}

Manifest : {
	redis_version : Str,
	provenance : Provenance,
	scope_groups : List(Str),
	entries : List(Entry),
}

Doc : {
	since : Str,
	group : Str,
	module_name : Str,
	doc_flags : List(Str),
	arguments : List(Argument),
}

RawArgument0 : {
	name : Str,
	type : Str,
	token ?: Str,
	flags ?: List(Str),
	arguments ?: List({}),
}

RawArgument1 : {
	name : Str,
	type : Str,
	token ?: Str,
	flags ?: List(Str),
	arguments ?: List(RawArgument0),
}

RawArgument2 : {
	name : Str,
	type : Str,
	token ?: Str,
	flags ?: List(Str),
	arguments ?: List(RawArgument1),
}

RawArgument3 : {
	name : Str,
	type : Str,
	token ?: Str,
	flags ?: List(Str),
	arguments ?: List(RawArgument2),
}

RawArgument4 : {
	name : Str,
	type : Str,
	token ?: Str,
	flags ?: List(Str),
	arguments ?: List(RawArgument3),
}

RawEntry : {
	command : Str,
	group : Str,
	arity : I64,
	since : Str,
	arguments : List(RawArgument4),
	module_name : Str,
	constructor : Str,
	doc_flags ?: List(Str),
	constructor_arguments ?: List(RawArgument4),
	status : Str,
	reason ?: Str,
}

RawManifest : {
	redis_version : Str,
	provenance : Provenance,
	scope_groups : List(Str),
	entries : List(RawEntry),
}

RawDoc : {
	since ?: Str,
	group : Str,
	module_name ?: Str,
	doc_flags ?: List(Str),
	arguments ?: List(RawArgument4),
}

Cli : {
	action : [Check, Generate, Snapshot],
	live : Bool,
	redis_cli : Str,
	redis_server : Str,
	socket ?: Str,
	host : Str,
	port ?: U16,
}

default_cli : [Check, Generate, Snapshot] -> Cli
default_cli = |action| {
	action,
	live: Bool.False,
	redis_cli: "redis-cli",
	redis_server: "redis-server",
	host: "127.0.0.1",
}

main! : List(OsStr) => Try({}, [CatalogFailed(Str), Exit(I32), ..])
main! = |raw_args| {
	args = os_args_to_str(raw_args.drop_first(1))?
	cli = parse_cli(args)?

	match cli.action {
		Generate => generate_action!(cli)
		Check => check_action!(cli)
		Snapshot => snapshot_action!(cli)
	}
}

os_args_to_str : List(OsStr) -> Try(List(Str), [CatalogFailed(Str), ..])
os_args_to_str = |args|
	match args {
		[] => Ok([])
		[first, .. as rest] => {
			text = OsStr.to_str_try(first) ? |_| CatalogFailed("command-line argument is not valid UTF-8")
			remaining = os_args_to_str(rest)?
			Ok(remaining.prepend(text))
		}
	}

parse_cli : List(Str) -> Try(Cli, [CatalogFailed(Str), ..])
parse_cli = |args|
	match args {
		["generate", .. as rest] => parse_options(rest, default_cli(Generate))
		["check", .. as rest] => parse_options(rest, default_cli(Check))
		["snapshot", .. as rest] => parse_options(rest, default_cli(Snapshot))
		_ => Err(CatalogFailed(usage))
	}

usage : Str
usage = "usage: roc scripts/command-catalog.roc -- (generate | check | snapshot) [--live] [--redis-cli PATH] [--redis-server PATH] [--socket PATH | --host HOST --port PORT]"

parse_options : List(Str), Cli -> Try(Cli, [CatalogFailed(Str), ..])
parse_options = |args, cli|
	match args {
		[] => validate_cli(cli)
		["--live", .. as rest] => parse_options(rest, { ..cli, live: Bool.True })
		["--redis-cli", value, .. as rest] => parse_options(rest, { ..cli, redis_cli: value })
		["--redis-server", value, .. as rest] => parse_options(rest, { ..cli, redis_server: value })
		["--socket", value, .. as rest] => parse_options(rest, { ..cli, socket: value })
		["--host", value, .. as rest] => parse_options(rest, { ..cli, host: value })
		["--port", value, .. as rest] => {
			port = parse_port(value)?
			parse_options(rest, { ..cli, port })
		}
		[option, ..] => Err(CatalogFailed("unknown or incomplete option ${Str.inspect(option)}; ${usage}"))
	}

validate_cli : Cli -> Try(Cli, [CatalogFailed(Str), ..])
validate_cli = |cli| {
	has_socket = cli.?socket.is_ok()
	has_port = cli.?port.is_ok()

	if cli.action == Generate and (cli.live or has_socket or has_port or cli.redis_cli != "redis-cli" or cli.redis_server != "redis-server" or cli.host != "127.0.0.1") {
		Err(CatalogFailed("generate does not accept Redis connection options"))
	} else if cli.live and cli.action != Check {
		Err(CatalogFailed("--live is accepted only by check"))
	} else if cli.live and (has_socket or has_port) {
		Err(CatalogFailed("--live cannot be combined with --socket or --port"))
	} else if has_socket and has_port {
		Err(CatalogFailed("--socket and --port are mutually exclusive"))
	} else {
		Ok(cli)
	}
}

parse_port : Str -> Try(U16, [CatalogFailed(Str), ..])
parse_port = |text| {
	invalid = CatalogFailed("port must be a decimal integer from 1 through 65535")
	bytes = text.to_utf8()
	if bytes.is_empty() or bytes.len() > 5 or !(bytes.all(|byte| byte >= 48 and byte <= 57)) {
		Err(invalid)
	} else {
		port = U16.from_str(text) ? |_| invalid
		if port == 0 Err(invalid) else Ok(port)
	}
}

generate_action! : Cli => Try({}, [CatalogFailed(Str), ..])
generate_action! = |_cli| {
	manifest = load_manifest!({})?
	generated = generate_files(manifest)?
	formatted = format_generated_files!(generated)?
	typed = typed_catalog_file!(manifest)?
	write_generated_files!(formatted.append(typed))?
	Stdout.line!("generated ${formatted.len().to_str()} Roc modules")
		.map_err(|error| CatalogFailed("write success message: ${Str.inspect(error)}"))
}

check_action! : Cli => Try({}, [CatalogFailed(Str), ..])
check_action! = |cli| {
	manifest = load_manifest!({})?
	generated = generate_files(manifest)?
	formatted = format_generated_files!(generated)?
	check_generated_files!(formatted)?
	typed = typed_catalog_file!(manifest)?
	check_generated_files!([typed])?

	wants_external = cli.?socket.is_ok() or cli.?port.is_ok()
	if cli.live {
		live = snapshot_from_temporary_redis!(cli)?
		compare_manifests(manifest, live)?
	} else if wants_external {
		verify_redis_server_binary!(cli.redis_server)?
		live = snapshot_from_connection!(cli.redis_cli, connection_arguments(cli)?)?
		compare_manifests(manifest, live)?
	}

	Stdout.line!("command catalog is complete and generated files are current")
		.map_err(|error| CatalogFailed("write success message: ${Str.inspect(error)}"))
}

snapshot_action! : Cli => Try({}, [CatalogFailed(Str), ..])
snapshot_action! = |cli| {
	manifest =
		if cli.?socket.is_ok() or cli.?port.is_ok() {
			verify_redis_server_binary!(cli.redis_server)?
			snapshot_from_connection!(cli.redis_cli, connection_arguments(cli)?)?
		} else {
			snapshot_from_temporary_redis!(cli)?
		}
	contents = encode_manifest(manifest)
	write_manifest_atomically!(contents)?
	Stdout.line!("wrote ${manifest_path.display()} (${manifest.entries.len().to_str()} entries)")
		.map_err(|error| CatalogFailed("write success message: ${Str.inspect(error)}"))
}

compare_manifests : Manifest, Manifest -> Try({}, [CatalogFailed(Str), ..])
compare_manifests = |expected, actual|
	if encode_manifest(expected) == encode_manifest(actual) {
		Ok({})
	} else {
		Err(CatalogFailed("live Redis public command contract differs from the checked-in manifest"))
	}

connection_arguments : Cli -> Try(List(Str), [CatalogFailed(Str), ..])
connection_arguments = |cli|
	match cli.?socket {
		Ok(socket) => Ok(["-s", socket])
		Err(_) =>
			match cli.?port {
				Ok(port) => Ok(["-h", cli.host, "-p", port.to_str()])
				Err(_) => Err(CatalogFailed("a Redis socket or port was not provided"))
			}
		}

snapshot_from_connection! : Str, List(Str) => Try(Manifest, [CatalogFailed(Str), ..])
snapshot_from_connection! = |redis_cli, connection| {
	timeout_program = find_timeout_program!({})?
	snapshot_with_timeout!(timeout_program, redis_cli, connection)
}

snapshot_with_timeout! : Str, Str, List(Str) => Try(Manifest, [CatalogFailed(Str), ..])
snapshot_with_timeout! = |timeout_program, redis_cli, connection| {
	info = redis_command!(timeout_program, redis_cli, connection, ["INFO", "server"], Bool.False)?
	actual_version = HarnessText.redis_info_field(info, "redis_version") ? |_| CatalogFailed("INFO server did not contain redis_version")
	if actual_version != redis_version {
		return Err(CatalogFailed("expected Redis ${redis_version}, found ${actual_version}"))
	}

	listed_json = redis_command!(timeout_program, redis_cli, connection, ["COMMAND", "LIST"], Bool.True)?
	listed_result : Try(List(Str), _)
	listed_result = Json.parse(listed_json)
	listed = listed_result ? |error| CatalogFailed("invalid JSON from COMMAND LIST: ${Str.inspect(error)}")
	listed_names = listed.map(Str.with_ascii_lowercased).sort_with(str_order)
	if has_duplicate_adjacent(listed_names) {
		return Err(CatalogFailed("COMMAND LIST contained duplicate normalized names"))
	}

	docs = fetch_command_docs!(timeout_program, redis_cli, connection, listed_names, Dict.from_list([]))?
	documented_names = docs.keys().sort_with(str_order)
	if documented_names != listed_names {
		missing = list_difference(listed_names, documented_names)
		unexpected = list_difference(documented_names, listed_names)
		return Err(CatalogFailed("COMMAND LIST and COMMAND DOCS names differ: missing docs=${Str.inspect(missing)}; unexpected docs=${Str.inspect(unexpected)}"))
	}

	module_names = docs.to_list().keep_if(|(_name, doc)| doc.group == "module").map(|(name, _doc)| name).sort_with(str_order)
	if module_names != vector_set_commands {
		missing = list_difference(vector_set_commands, module_names)
		unexpected = list_difference(module_names, vector_set_commands)
		return Err(CatalogFailed("Redis module-group commands differ from the built-in vector-set policy: missing vectors=${Str.inspect(missing)}; unexpected module commands=${Str.inspect(unexpected)}"))
	}
	wrong_identity = vector_set_commands.keep_if(
		|name|
			match docs.get(name) {
				Ok(doc) => doc.module_name != "vectorset"
				Err(_) => Bool.True
			},
	)
	if !wrong_identity.is_empty() {
		return Err(CatalogFailed("expected Redis to identify vector-set commands as module `vectorset`: ${Str.inspect(wrong_identity)}"))
	}

	scoped_names = scoped_command_names(listed_names, docs)?
	entries = build_live_entries!(timeout_program, redis_cli, connection, scoped_names, docs)?
	manifest = {
		redis_version,
		provenance: {
			contract: expected_public_contract,
			description: "Normalized public replies from an unmodified Redis OSS 8.10.1 server; Redis internal command JSON is not vendored.",
			scoped_command_count: entries.len(),
			module_group_commands: vector_set_commands,
			constructor_argument_overrides,
		},
		scope_groups,
		entries,
	}
	validate_manifest(manifest)?
	Ok(manifest)
}

redis_command! : Str, Str, List(Str), List(Str), Bool => Try(Str, [CatalogFailed(Str), ..])
redis_command! = |timeout_program, redis_cli, connection, arguments, json_output| {
	json_arguments = if json_output ["--json"] else []
	all_arguments = connection.concat(json_arguments).concat(arguments)
	outcome = run_bounded_output!(timeout_program, redis_cli, all_arguments)?
	if outcome.exit_code == 0 {
		Ok(outcome.stdout.trim())
	} else {
		Err(CatalogFailed("${Str.join_with(arguments, " ")} failed with exit ${outcome.exit_code.to_str()}: ${bounded_output(outcome)}"))
	}
}

fetch_command_docs! : Str, Str, List(Str), List(Str), Dict(Str, Doc) => Try(Dict(Str, Doc), [CatalogFailed(Str), ..])
fetch_command_docs! = |timeout_program, redis_cli, connection, remaining, collected| {
	match remaining {
		[] => Ok(collected)
		[name, .. as rest] => {
			# The pinned compiler panics while generating a JSON codec for
			# Dict(Str, RawDoc); see roc-bugs/generated-json-optional-field-postcheck.
			# Asking for exactly one name lets us validate the outer object shape and
			# derive the otherwise-identical RawDoc codec directly.
			json = redis_command!(timeout_program, redis_cli, connection, ["COMMAND", "DOCS", name], Bool.True)?
			doc_json = unwrap_single_doc_json(name, docs_json_for_roc(json))?
			parsed_result : Try(RawDoc, _)
			parsed_result = Json.parse(doc_json)
			raw = parsed_result ? |error| CatalogFailed("invalid JSON from COMMAND DOCS ${name}: ${Str.inspect(error)}")
			(normalized_name, doc) = doc_from_raw(name, raw)?
			if collected.contains(normalized_name) {
				Err(CatalogFailed("COMMAND DOCS contained duplicate normalized name ${normalized_name}"))
			} else {
				fetch_command_docs!(timeout_program, redis_cli, connection, rest, collected.insert(normalized_name, doc))
			}
		}
	}
}

unwrap_single_doc_json : Str, Str -> Try(Str, [CatalogFailed(Str), ..])
unwrap_single_doc_json = |name, json| {
	lowercase_prefix = "{${Json.to_str(name)}:"
	uppercase_prefix = "{${Json.to_str(name.with_ascii_uppercased())}:"
	prefix =
		if json.starts_with(lowercase_prefix) {
			lowercase_prefix
		} else if json.starts_with(uppercase_prefix) {
			uppercase_prefix
		} else {
			return Err(CatalogFailed("COMMAND DOCS ${name} did not return exactly its named JSON object field"))
		}
	if json.ends_with("}") {
		value = json.drop_prefix(prefix).drop_suffix("}")
		if value.is_empty() Err(CatalogFailed("COMMAND DOCS ${name} returned an empty JSON value")) else Ok(value)
	} else {
		Err(CatalogFailed("COMMAND DOCS ${name} did not return exactly its named JSON object field"))
	}
}

doc_from_raw : Str, RawDoc -> Try((Str, Doc), [CatalogFailed(Str), ..])
doc_from_raw = |name, raw| {
	arguments = (raw.?arguments ?? []).map_try(argument_from_raw4)?
	Ok((
		name.with_ascii_lowercased(),
		{
			since: raw.?since ?? "unknown",
			group: raw.group,
			module_name: raw.?module_name ?? "",
			doc_flags: (raw.?doc_flags ?? []).sort_with(str_order),
			arguments,
		},
	))
}

list_difference : List(Str), List(Str) -> List(Str)
list_difference = |left, right| left.keep_if(|item| !(right.contains(item)))

scoped_command_names : List(Str), Dict(Str, Doc) -> Try(List(Str), [CatalogFailed(Str), ..])
scoped_command_names = |names, docs|
	match names {
		[] => Ok([])
		[first, .. as rest] => {
			doc = docs.get(first) ? |_| CatalogFailed("COMMAND DOCS omitted ${first}")
			following = scoped_command_names(rest, docs)?
			if scope_groups.contains(doc.group) Ok(following.prepend(first)) else Ok(following)
		}
	}

build_live_entries! : Str, Str, List(Str), List(Str), Dict(Str, Doc) => Try(List(Entry), [CatalogFailed(Str), ..])
build_live_entries! = |timeout_program, redis_cli, connection, names, docs|
	match names {
		[] => Ok([])
		[name, .. as rest] => {
			doc = docs.get(name) ? |_| CatalogFailed("COMMAND DOCS omitted ${name}")
			arity = read_command_arity!(timeout_program, redis_cli, connection, name)?
			policy = module_policy_for_group(doc.group) ? |_| CatalogFailed("unexpected group for ${name}: ${doc.group}")
			constructor_arguments =
				if constructor_argument_overrides.contains(name) {
					Override(constructor_arguments_override(name, doc.arguments)?)
				} else {
					Original
				}
			exclusion = exclusion_policies.find_first(|policy_item| policy_item.command == name)
			status = if exclusion.is_ok() "excluded" else "included"
			reason = match exclusion {
				Ok(policy_item) => policy_item.reason
				Err(_) => ""
			}
			entry = {
				command: name,
				group: doc.group,
				arity,
				since: doc.since,
				arguments: doc.arguments,
				module_name: policy.module_name,
				constructor: constructor_name(name),
				doc_flags: doc.doc_flags,
				constructor_arguments,
				status,
				reason,
			}
			following = build_live_entries!(timeout_program, redis_cli, connection, rest, docs)?
			Ok(following.prepend(entry))
		}
	}

read_command_arity! : Str, Str, List(Str), Str => Try(I64, [CatalogFailed(Str), ..])
read_command_arity! = |timeout_program, redis_cli, connection, requested| {
	output = redis_command!(timeout_program, redis_cli, connection, ["--raw", "COMMAND", "INFO", requested], Bool.False)?
	lines = output.split_on("\n").map(Str.trim)
	actual_name = lines.get(0) ? |_| CatalogFailed("COMMAND INFO returned no entry for ${requested}")
	arity_text = lines.get(1) ? |_| CatalogFailed("COMMAND INFO omitted arity for ${requested}")
	if actual_name.with_ascii_lowercased() != requested {
		Err(CatalogFailed("COMMAND INFO returned ${Str.inspect(actual_name)} for ${requested}"))
	} else {
		parse_signed_decimal(arity_text).map_err(|_| CatalogFailed("COMMAND INFO returned invalid arity ${Str.inspect(arity_text)} for ${requested}"))
	}
}

parse_signed_decimal : Str -> Try(I64, [InvalidDecimal])
parse_signed_decimal = |text| {
	digits = if text.starts_with("-") text.drop_prefix("-") else text
	bytes = digits.to_utf8()
	if bytes.is_empty() or !(bytes.all(|byte| byte >= 48 and byte <= 57)) {
		Err(InvalidDecimal)
	} else {
		I64.from_str(text).map_err(|_| InvalidDecimal)
	}
}

TemporaryRedis : {
	directory : Path.Path,
	log_path : Path.Path,
	pid : Str,
	socket_path : Path.Path,
	watchdog_pid : Str,
}

snapshot_from_temporary_redis! : Cli => Try(Manifest, [CatalogFailed(Str), ..])
snapshot_from_temporary_redis! = |cli| {
	verify_redis_server_binary!(cli.redis_server)?
	timeout_program = find_timeout_program!({})?
	verify_temporary_redis_startup_window_sigkill!(cli.redis_server, cli.redis_cli, timeout_program)?
	directory = create_redis_temp_dir!(timeout_program, 8)?
	start_result = start_temporary_redis!(cli.redis_server, cli.redis_cli, timeout_program, directory, "")

	match start_result {
		Err(error) => {
			cleanup = remove_temporary_redis_directory_if_idle!(timeout_program, directory)
			combine_value_and_cleanup(Err(error), cleanup)
		}
		Ok(server) => {
			connection = ["-s", server.socket_path.display()]
			ready_result = wait_for_temporary_owner!(timeout_program, cli.redis_cli, connection, server, startup_attempts)
			snapshot_result = match ready_result {
				Ok({}) => {
					result = snapshot_with_timeout!(timeout_program, cli.redis_cli, connection)
					match (result, ensure_watchdog_active!(timeout_program, server)) {
						(Ok(manifest), Ok({})) => Ok(manifest)
						(Err(error), _) => Err(CatalogFailed(describe_catalog_error(error)))
						(Ok(_), Err(error)) => Err(CatalogFailed(describe_catalog_error(error)))
					}
				}
				Err(error) => Err(error)
			}
			stop_result = stop_temporary_redis!(timeout_program, cli.redis_cli, connection, server)
			without_server = combine_value_and_cleanup(snapshot_result, stop_result)
			cleanup = remove_temporary_redis_directory_if_idle!(timeout_program, directory)
			combine_value_and_cleanup(without_server, cleanup)
		}
	}
}

verify_redis_server_binary! : Str => Try({}, [CatalogFailed(Str), ..])
verify_redis_server_binary! = |redis_server| {
	timeout_program = find_timeout_program!({})?
	outcome = run_bounded_output!(timeout_program, redis_server, ["--version"])?
	if outcome.exit_code != 0 {
		Err(CatalogFailed("${redis_server} --version failed with exit ${outcome.exit_code.to_str()}: ${bounded_output(outcome)}"))
	} else {
		version_token = outcome.stdout.split_on(" ").find_first(|token| token.starts_with("v=")) ? |_| CatalogFailed("could not parse ${redis_server} --version output")
		actual = version_token.drop_prefix("v=").trim()
		if actual == redis_version Ok({}) else Err(CatalogFailed("expected ${redis_server} version ${redis_version}, found ${actual}"))
	}
}

create_redis_temp_dir! : Str, U8 => Try(Path.Path, [CatalogFailed(Str), ..])
create_redis_temp_dir! = |timeout_program, attempts_remaining| {
	seed = Random.seed_u64!() ? |error| CatalogFailed("choose temporary Redis directory: ${Str.inspect(error)}")
	path = Path.utf8("/tmp").join("rrc-${seed.to_str()}")
	match path.create_dir!() {
		Ok({}) => {
			outcome = run_bounded_output!(timeout_program, "chmod", ["700", path.display()])?
			if outcome.exit_code == 0 {
				Ok(path)
			} else {
				cleanup = path.delete_all!()
				_ = cleanup
				Err(CatalogFailed("chmod 700 ${path.display()} failed with exit ${outcome.exit_code.to_str()}: ${bounded_output(outcome)}"))
			}
		}
		Err(PathErr(AlreadyExists, _)) if attempts_remaining > 1 => create_redis_temp_dir!(timeout_program, attempts_remaining - 1)
		Err(error) => Err(CatalogFailed("create temporary Redis directory ${path.display()}: ${Str.inspect(error)}"))
	}
}

verify_temporary_redis_startup_window_sigkill! : Str, Str, Str => Try({}, [CatalogFailed(Str), ..])
verify_temporary_redis_startup_window_sigkill! = |redis_server, redis_cli, timeout_program| {
	directory = create_redis_temp_dir!(timeout_program, 8)?
	result = run_temporary_redis_startup_window_sigkill!(redis_server, redis_cli, timeout_program, directory)
	cleanup = remove_temporary_redis_directory_if_idle!(timeout_program, directory)
	combine_value_and_cleanup(result, cleanup)
}

run_temporary_redis_startup_window_sigkill! : Str, Str, Str, Path.Path => Try({}, [CatalogFailed(Str), ..])
run_temporary_redis_startup_window_sigkill! = |redis_server, redis_cli, timeout_program, directory| {
	sentinel_pid = launch_startup_window_sentinel!(timeout_program)?
	result = run_temporary_redis_startup_window_with_sentinel!(redis_server, redis_cli, timeout_program, directory, sentinel_pid)
	sentinel_cleanup = stop_known_process!(timeout_program, sentinel_pid, "startup-window sentinel")
	combine_value_and_cleanup(result, sentinel_cleanup)
}

run_temporary_redis_startup_window_with_sentinel! : Str, Str, Str, Path.Path, Str => Try({}, [CatalogFailed(Str), ..])
run_temporary_redis_startup_window_with_sentinel! = |redis_server, redis_cli, timeout_program, directory, sentinel_pid| {
	socket_path = directory.join("redis.sock")
	pid_path = directory.join("redis.pid")
	log_path = directory.join("redis.log")
	watchdog_pid = launch_parent_death_watchdog!(timeout_program, redis_cli, directory, sentinel_pid)?
	if !(process_is_alive_bounded!(timeout_program, watchdog_pid)) {
		return Err(CatalogFailed("startup-window parent-death watchdog ${watchdog_pid} exited before Redis launch"))
	}
	# Make the watchdog observe an existing-but-empty pidfile after parent death,
	# then publish the real Redis PID only when the delayed daemon starts.
	pid_path.write_utf8!("") ? |error| CatalogFailed("write empty startup-window Redis pidfile: ${Str.inspect(error)}")
	kill_result = terminate_process!(timeout_program, sentinel_pid, "KILL")
	if kill_result.is_err() {
		return combine_value_and_cleanup(Err(CatalogFailed("could not SIGKILL startup-window sentinel: ${describe_try(kill_result)}")), stop_known_process!(timeout_program, watchdog_pid, "startup-window parent-death watchdog"))
	}
	_ = wait_for_process_exit!(timeout_program, sentinel_pid, 40)
	wait_for_marker!(directory.join("redis-pid.pending"), "temporary Redis watchdog empty-pidfile acknowledgment", 100)?
	outcome = launch_temporary_redis_daemon!(redis_server, timeout_program, directory, socket_path, pid_path, log_path)?
	if outcome.exit_code != 0 {
		cleanup = cleanup_failed_temporary_redis!(timeout_program, redis_cli, socket_path, pid_path, directory.join("redis-cleanup.request"), watchdog_pid)
		return combine_value_and_cleanup(Err(CatalogFailed("delayed startup-window Redis launch exited ${outcome.exit_code.to_str()}: ${bounded_output(outcome)}")), cleanup)
	}
	if !(wait_for_process_exit!(timeout_program, watchdog_pid, 400)) {
		cleanup = cleanup_failed_temporary_redis!(timeout_program, redis_cli, socket_path, pid_path, directory.join("redis-cleanup.request"), watchdog_pid)
		return combine_value_and_cleanup(Err(CatalogFailed("preinstalled watchdog did not finish delayed startup-window cleanup after sentinel SIGKILL")), cleanup)
	}
	socket_exists = socket_path.exists!() ? |error| CatalogFailed("inspect startup-window Redis socket after watchdog cleanup: ${Str.inspect(error)}")
	pid_active = pidfile_process_is_alive_bounded!(timeout_program, pid_path, "startup-window Redis")?
	if socket_exists or pid_active {
		Err(CatalogFailed("preinstalled watchdog left delayed startup-window Redis identity active after sentinel SIGKILL"))
	} else {
		Ok({})
	}
}

launch_startup_window_sentinel! : Str => Try(Str, [CatalogFailed(Str), ..])
launch_startup_window_sentinel! = |timeout_program| {
	outcome = run_bounded_output_with_limit!(timeout_program, "5s", "sh", ["-c", "sleep 30 </dev/null >/dev/null 2>&1 & child=$!; printf '%s\\n' \"$child\""])?
	if outcome.exit_code == 0 {
		parse_pid_output(outcome.stdout).map_err(|error| CatalogFailed("launch startup-window sentinel: ${describe_catalog_error(error)}"))
	} else {
		Err(CatalogFailed("launch startup-window sentinel exited ${outcome.exit_code.to_str()}: ${bounded_output(outcome)}"))
	}
}

remove_temporary_redis_directory_if_idle! : Str, Path.Path => Try({}, [CatalogFailed(Str), ..])
remove_temporary_redis_directory_if_idle! = |timeout_program, directory| {
	exists = directory.exists!() ? |error| CatalogFailed("inspect temporary Redis directory ${directory.display()}: ${Str.inspect(error)}")
	if !exists {
		Ok({})
	} else {
		redis_active = pidfile_process_is_alive_bounded!(timeout_program, directory.join("redis.pid"), "temporary Redis")?
		watchdog_active = pidfile_process_is_alive_bounded!(timeout_program, directory.join("watchdog.pid"), "parent-death watchdog")?
		socket_exists = directory.join("redis.sock").exists!() ? |error| CatalogFailed("inspect temporary Redis socket in ${directory.display()}: ${Str.inspect(error)}")
		cleanup_requested = directory.join("redis-cleanup.request").exists!() ? |error| CatalogFailed("inspect temporary Redis cleanup request in ${directory.display()}: ${Str.inspect(error)}")
		if redis_active or watchdog_active or socket_exists or cleanup_requested {
			Err(CatalogFailed("refusing to remove temporary Redis directory ${directory.display()}: Redis, its watchdog, or its private socket may still be active; identity evidence was preserved"))
		} else {
			directory.delete_all!().map_err(|error| CatalogFailed("remove temporary Redis directory ${directory.display()}: ${Str.inspect(error)}"))
		}
	}
}

pidfile_process_is_alive_bounded! : Str, Path.Path, Str => Try(Bool, [CatalogFailed(Str), ..])
pidfile_process_is_alive_bounded! = |timeout_program, pid_path, label| {
	match pid_path.is_file!() {
		Ok(Bool.False) => Ok(Bool.False)
		Ok(Bool.True) => {
			pid = read_pid_file!(pid_path) ? |error| CatalogFailed("${label} identity check failed: ${describe_catalog_error(error)}")
			Ok(process_is_alive_bounded!(timeout_program, pid))
		}
		Err(error) => Err(CatalogFailed("inspect ${label} pidfile ${pid_path.display()}: ${Str.inspect(error)}"))
	}
}

launch_temporary_redis_daemon! : Str, Str, Path.Path, Path.Path, Path.Path, Path.Path => Try({ exit_code : I32, stdout : Str, stderr : Str }, [CatalogFailed(Str), ..])
launch_temporary_redis_daemon! = |redis_server, timeout_program, directory, socket_path, pid_path, log_path|
	run_bounded_output!(
		timeout_program,
		redis_server,
		[
			"--port",
			"0",
			"--unixsocket",
			socket_path.display(),
			"--unixsocketperm",
			"700",
			"--save",
			"",
			"--appendonly",
			"no",
			"--daemonize",
			"yes",
			"--supervised",
			"no",
			"--dir",
			directory.display(),
			"--pidfile",
			pid_path.display(),
			"--logfile",
			log_path.display(),
			"--loglevel",
			"warning",
		],
	)

start_temporary_redis! : Str, Str, Str, Path.Path, Str => Try(TemporaryRedis, [CatalogFailed(Str), ..])
start_temporary_redis! = |redis_server, redis_cli, timeout_program, directory, monitored_pid| {
	socket_path = directory.join("redis.sock")
	pid_path = directory.join("redis.pid")
	log_path = directory.join("redis.log")
	cleanup_request_path = directory.join("redis-cleanup.request")
	delete_if_present!(cleanup_request_path)?
	watchdog_pid = launch_parent_death_watchdog!(timeout_program, redis_cli, directory, monitored_pid)?
	if !(process_is_alive_bounded!(timeout_program, watchdog_pid)) {
		return Err(CatalogFailed("parent-death watchdog ${watchdog_pid} exited before Redis launch"))
	}
	outcome_result = launch_temporary_redis_daemon!(redis_server, timeout_program, directory, socket_path, pid_path, log_path)
	outcome = match outcome_result {
		Ok(value) => value
		Err(error) => {
			cleanup = cleanup_failed_temporary_redis!(timeout_program, redis_cli, socket_path, pid_path, cleanup_request_path, watchdog_pid)
			match cleanup {
				Ok({}) => return Err(error)
				Err(cleanup_error) => return Err(CatalogFailed("${describe_catalog_error(error)}; startup cleanup failed: ${describe_catalog_error(cleanup_error)}"))
			}
		}
	}
	if outcome.exit_code != 0 {
		message = "temporary Redis failed to start with exit ${outcome.exit_code.to_str()}: ${bounded_output(outcome)}; log: ${read_best_effort!(log_path)}"
		cleanup = cleanup_failed_temporary_redis!(timeout_program, redis_cli, socket_path, pid_path, cleanup_request_path, watchdog_pid)
		match cleanup {
			Ok({}) => Err(CatalogFailed(message))
			Err(error) => Err(CatalogFailed("${message}; startup cleanup failed: ${describe_catalog_error(error)}"))
		}
	} else {
		match wait_for_startup_pid!(timeout_program, pid_path, watchdog_pid, pidfile_attempts) {
			Ok(pid) => Ok({ directory, log_path, pid, socket_path, watchdog_pid })
			Err(error) => {
				cleanup = cleanup_failed_temporary_redis!(timeout_program, redis_cli, socket_path, pid_path, cleanup_request_path, watchdog_pid)
				match cleanup {
					Ok({}) => Err(error)
					Err(cleanup_error) => Err(CatalogFailed("${describe_catalog_error(error)}; startup cleanup failed: ${describe_catalog_error(cleanup_error)}"))
				}
			}
		}
	}
}

request_catalog_watchdog_cleanup! : Str, Str, Path.Path, Path.Path, Path.Path, Str => Try({}, [CatalogFailed(Str), ..])
request_catalog_watchdog_cleanup! = |timeout_program, redis_cli, socket_path, cleanup_request_path, child_pid_path, watchdog_pid| {
	cleanup_request_path.write_utf8!("cleanup\n") ? |error| CatalogFailed("request temporary Redis watchdog cleanup: ${Str.inspect(error)}")
	if !(wait_for_process_exit!(timeout_program, watchdog_pid, 500)) {
		Err(CatalogFailed("parent-death watchdog ${watchdog_pid} did not finish requested startup cleanup"))
	} else {
		endpoint_absent = temporary_redis_endpoint_absent!(timeout_program, redis_cli, socket_path)?
		match child_pid_path.is_file!() {
			Ok(Bool.False) if endpoint_absent => Ok({})
			Ok(Bool.False) => Err(CatalogFailed("temporary Redis endpoint still responds after requested watchdog cleanup; identity evidence was preserved"))
			Ok(Bool.True) => {
				pid = read_pid_file!(child_pid_path)?
				if process_is_alive_bounded!(timeout_program, pid) {
					Err(CatalogFailed("temporary Redis process ${pid} remained active after requested watchdog cleanup"))
				} else if !endpoint_absent {
					Err(CatalogFailed("temporary Redis endpoint still responds for exited pidfile PID ${pid}; identity evidence was preserved"))
				} else {
					Ok({})
				}
			}
			Err(error) => Err(CatalogFailed("inspect temporary Redis pidfile after watchdog cleanup: ${Str.inspect(error)}"))
		}
	}
}

cleanup_failed_temporary_redis! : Str, Str, Path.Path, Path.Path, Path.Path, Str => Try({}, [CatalogFailed(Str), ..])
cleanup_failed_temporary_redis! = |timeout_program, redis_cli, socket_path, pid_path, cleanup_request_path, watchdog_pid| {
	pidfile_exists = pid_path.is_file!() ? |error| CatalogFailed("inspect temporary Redis pidfile during startup cleanup: ${Str.inspect(error)}")
	socket_exists = socket_path.exists!() ? |error| CatalogFailed("inspect temporary Redis socket during startup cleanup: ${Str.inspect(error)}")
	if !pidfile_exists and !socket_exists {
		request_catalog_watchdog_cleanup!(timeout_program, redis_cli, socket_path, cleanup_request_path, pid_path, watchdog_pid)
	} else {
		redis_result = stop_from_pidfile!(timeout_program, redis_cli, socket_path, pid_path)
		match redis_result {
			Err(error) => finish_catalog_watchdog_takeover!(timeout_program, redis_cli, socket_path, error, cleanup_request_path, pid_path, watchdog_pid)
			Ok({}) => finish_stopped_temporary_redis_cleanup!(timeout_program, socket_path, watchdog_pid)
		}
	}
}

finish_catalog_watchdog_takeover! : Str, Str, Path.Path, [CatalogFailed(Str), ..], Path.Path, Path.Path, Str => Try({}, [CatalogFailed(Str), ..])
finish_catalog_watchdog_takeover! = |timeout_program, redis_cli, socket_path, original_error, cleanup_request_path, pid_path, watchdog_pid| {
	watchdog_result = request_catalog_watchdog_cleanup!(timeout_program, redis_cli, socket_path, cleanup_request_path, pid_path, watchdog_pid)
	match watchdog_result {
		Ok({}) => Ok({})
		Err(watchdog_error) => Err(CatalogFailed("${describe_catalog_error(original_error)}; watchdog takeover also failed: ${describe_catalog_error(watchdog_error)}"))
	}
}

finish_stopped_temporary_redis_cleanup! : Str, Path.Path, Str => Try({}, [CatalogFailed(Str), ..])
finish_stopped_temporary_redis_cleanup! = |timeout_program, socket_path, watchdog_pid| {
	socket_cleanup = delete_if_present!(socket_path)
	watchdog_cleanup = stop_known_process!(timeout_program, watchdog_pid, "parent-death watchdog")
	combine_unit_results(socket_cleanup, watchdog_cleanup)
}

read_pid_file! : Path.Path => Try(Str, [CatalogFailed(Str), ..])
read_pid_file! = |pid_path| {
	contents = pid_path.read_utf8!() ? |error| CatalogFailed("read temporary Redis pidfile ${pid_path.display()}: ${Str.inspect(error)}")
	pid = contents.trim()
	bytes = pid.to_utf8()
	if bytes.is_empty() or !(bytes.all(|byte| byte >= 48 and byte <= 57)) {
		Err(CatalogFailed("temporary Redis wrote an invalid pidfile: ${Str.inspect(contents)}"))
	} else {
		number = U64.from_str(pid) ? |_| CatalogFailed("temporary Redis wrote an invalid pidfile: ${Str.inspect(contents)}")
		if !contents.ends_with("\n") {
			Err(CatalogFailed("temporary Redis wrote a non-terminated pidfile: ${Str.inspect(contents)}"))
		} else if number > 1 {
			Ok(pid)
		} else {
			Err(CatalogFailed("temporary Redis wrote an unsafe process ID: ${pid}"))
		}
	}
}

wait_for_startup_pid! : Str, Path.Path, Str, U8 => Try(Str, [CatalogFailed(Str), ..])
wait_for_startup_pid! = |timeout_program, pid_path, watchdog_pid, attempts_remaining| {
	if attempts_remaining == 0 {
		Err(CatalogFailed("temporary Redis did not populate its pidfile during startup"))
	} else if !(process_is_alive_bounded!(timeout_program, watchdog_pid)) {
		Err(CatalogFailed("parent-death watchdog ${watchdog_pid} exited while waiting for the Redis pidfile"))
	} else {
		match pid_path.is_file!() {
			Ok(Bool.False) => {
				Sleep.millis!(50)
				wait_for_startup_pid!(timeout_program, pid_path, watchdog_pid, attempts_remaining - 1)
			}
			Ok(Bool.True) => {
				contents = pid_path.read_utf8!() ? |error| CatalogFailed("read temporary Redis startup pidfile ${pid_path.display()}: ${Str.inspect(error)}")
				match startup_pid_state(contents) {
					PendingPid => {
						Sleep.millis!(50)
						wait_for_startup_pid!(timeout_program, pid_path, watchdog_pid, attempts_remaining - 1)
					}
					ReadyPid(pid) => confirm_startup_pid!(timeout_program, pid_path, watchdog_pid, attempts_remaining - 1, pid)
					InvalidPid(_) => {
						Sleep.millis!(50)
						wait_for_startup_pid!(timeout_program, pid_path, watchdog_pid, attempts_remaining - 1)
					}
				}
			}
			Err(error) => Err(CatalogFailed("inspect temporary Redis startup pidfile ${pid_path.display()}: ${Str.inspect(error)}"))
		}
	}
}

confirm_startup_pid! : Str, Path.Path, Str, U8, Str => Try(Str, [CatalogFailed(Str), ..])
confirm_startup_pid! = |timeout_program, pid_path, watchdog_pid, attempts_remaining, candidate| {
	Sleep.millis!(10)
	contents = pid_path.read_utf8!() ? |error| CatalogFailed("confirm temporary Redis startup pidfile ${pid_path.display()}: ${Str.inspect(error)}")
	match startup_pid_state(contents) {
		ReadyPid(pid) if pid == candidate => Ok(pid)
		_ => wait_for_startup_pid!(timeout_program, pid_path, watchdog_pid, attempts_remaining)
	}
}

StartupPidState : [InvalidPid(Str), PendingPid, ReadyPid(Str)]

startup_pid_state : Str -> StartupPidState
startup_pid_state = |contents| {
	if contents.trim().is_empty() {
		PendingPid
	} else {
		match parse_pid_output(contents) {
			Ok(pid) if contents.ends_with("\n") => ReadyPid(pid)
			Ok(_) => InvalidPid("temporary Redis pidfile was not newline-terminated")
			Err(error) => InvalidPid(describe_catalog_error(error))
		}
	}
}

first_ready_startup_pid : List(Str) -> Try(Str, [NoReadyPid])
first_ready_startup_pid = |observations|
	match observations {
		[] => Err(NoReadyPid)
		[first, .. as rest] =>
			match startup_pid_state(first) {
				ReadyPid(pid) => Ok(pid)
				PendingPid => first_ready_startup_pid(rest)
				InvalidPid(_) => first_ready_startup_pid(rest)
			}
		}

launch_parent_death_watchdog! : Str, Str, Path.Path, Str => Try(Str, [CatalogFailed(Str), ..])
launch_parent_death_watchdog! = |timeout_program, redis_cli, directory, monitored_pid| {
	pid_path = directory.join("watchdog.pid")
	delete_if_present!(pid_path)?
	pending_ack_path = directory.join("redis-pid.pending")
	delete_if_present!(pending_ack_path)?
	# basic-cli does not expose the current process ID. This fixed wrapper is
	# spawned directly so PPID identifies this Roc process, then immediately
	# execs GNU timeout to bound the complete watchdog-launch operation.
	command = Cmd.new_str("sh")
		.args_str(["-c", watchdog_wrapper_script, "roc-command-catalog-watchdog", timeout_program, watchdog_launch_script])
		.env_str("TEMP_DIR", directory.display())
		.env_str("WATCHDOG_PIDFILE", pid_path.display())
		.env_str("OWNER_FILE", directory.join("harness.owner").display())
		.env_str("REDIS_PIDFILE", directory.join("redis.pid").display())
		.env_str("REDIS_SOCKET", directory.join("redis.sock").display())
		.env_str("REDIS_CLI", redis_cli)
		.env_str("TIMEOUT_PROGRAM", timeout_program)
		.env_str("MONITORED_PID", monitored_pid)
		.env_str("CLEANUP_REQUEST", directory.join("redis-cleanup.request").display())
		.env_str("PENDING_ACK", pending_ack_path.display())
	match command.exec_output!() {
		Ok({ stdout_utf8, stderr_utf8_lossy }) => {
			captured = parse_pid_output(stdout_utf8)
			pidfile = read_pid_file!(pid_path)
			match (captured, pidfile) {
				(Ok(pid), Ok(file_pid)) if pid == file_pid =>
					if process_is_alive_bounded!(timeout_program, pid) {
						Ok(pid)
					} else {
						Err(CatalogFailed("parent-death watchdog exited during launch"))
					}
				(Ok(pid), Ok(file_pid)) => {
					_ = stop_known_process!(timeout_program, pid, "captured parent-death watchdog")
					Err(CatalogFailed("parent-death watchdog PID mismatch: captured ${pid}, pidfile ${file_pid}; pidfile PID was not signaled and identity evidence was preserved"))
				}
				(Ok(pid), Err(error)) => {
					_ = stop_known_process!(timeout_program, pid, "parent-death watchdog")
					Err(error)
				}
				(Err(error), Ok(pid)) => {
					Err(CatalogFailed("${describe_catalog_error(error)}; refusing to signal uncorroborated pidfile watchdog PID ${pid}; identity evidence was preserved"))
				}
				(Err(error), Err(pidfile_error)) => Err(CatalogFailed("${describe_catalog_error(error)}; ${describe_catalog_error(pidfile_error)}; stderr: ${stderr_utf8_lossy.trim()}"))
			}
		}
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) =>
			watchdog_launch_failure!(timeout_program, pid_path, stdout_utf8_lossy, "launch parent-death watchdog exited ${exit_code.to_str()}: ${HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy).trim()}")
		Err(error) => watchdog_launch_failure!(timeout_program, pid_path, "", "launch parent-death watchdog: ${Str.inspect(error)}")
	}
}

watchdog_launch_failure! : Str, Path.Path, Str, Str => Try(a, [CatalogFailed(Str), ..])
watchdog_launch_failure! = |timeout_program, pid_path, captured_output, message| {
	captured = parse_pid_output(captured_output)
	pidfile = read_pid_file!(pid_path)
	match (captured, pidfile) {
		(Ok(pid), Ok(file_pid)) if pid == file_pid => {
			cleanup = stop_known_process!(timeout_program, pid, "parent-death watchdog")
			if cleanup.is_ok() Err(CatalogFailed(message)) else Err(CatalogFailed("${message}; watchdog cleanup failed: ${describe_try(cleanup)}"))
		}
		(Ok(pid), Ok(file_pid)) => {
			cleanup = stop_known_process!(timeout_program, pid, "captured parent-death watchdog")
			if cleanup.is_ok() {
				Err(CatalogFailed("${message}; refusing to signal mismatched pidfile watchdog PID ${file_pid}; identity evidence was preserved"))
			} else {
				Err(CatalogFailed("${message}; captured watchdog cleanup failed: ${describe_try(cleanup)}; mismatched pidfile PID ${file_pid} was not signaled"))
			}
		}
		(Ok(pid), Err(_)) => {
			cleanup = stop_known_process!(timeout_program, pid, "captured parent-death watchdog")
			if cleanup.is_ok() Err(CatalogFailed(message)) else Err(CatalogFailed("${message}; watchdog cleanup failed: ${describe_try(cleanup)}"))
		}
		(Err(_), Ok(pid)) => {
			Err(CatalogFailed("${message}; refusing to signal uncorroborated pidfile watchdog PID ${pid}; identity evidence was preserved"))
		}
		(Err(_), Err(_)) => Err(CatalogFailed(message))
	}
}

parse_pid_output : Str -> Try(Str, [CatalogFailed(Str), ..])
parse_pid_output = |contents| {
	pid = contents.trim()
	bytes = pid.to_utf8()
	if bytes.is_empty() or !(bytes.all(|byte| byte >= 48 and byte <= 57)) {
		Err(CatalogFailed("expected one positive process ID, received ${Str.inspect(contents)}"))
	} else {
		number = U64.from_str(pid) ? |_| CatalogFailed("invalid process ID ${Str.inspect(pid)}")
		if number > 1 Ok(pid) else Err(CatalogFailed("unsafe process ID ${pid}"))
	}
}

stop_from_pidfile! : Str, Str, Path.Path, Path.Path => Try({}, [CatalogFailed(Str), ..])
stop_from_pidfile! = |timeout_program, redis_cli, socket_path, pid_path| {
	match pid_path.is_file!() {
		Ok(Bool.False) => stop_from_private_socket_if_present!(timeout_program, redis_cli, socket_path)
		Ok(Bool.True) => {
			pid = read_pid_file!(pid_path)?
			stop_redis_process!(timeout_program, redis_cli, socket_path, pid, "pidfile-owned temporary Redis")
		}
		Err(error) => Err(CatalogFailed("inspect temporary Redis pidfile ${pid_path.display()}: ${Str.inspect(error)}"))
	}
}

stop_from_private_socket_if_present! : Str, Str, Path.Path => Try({}, [CatalogFailed(Str), ..])
stop_from_private_socket_if_present! = |timeout_program, redis_cli, socket_path| {
	socket_exists = socket_path.exists!() ? |error| CatalogFailed("inspect temporary Redis socket ${socket_path.display()}: ${Str.inspect(error)}")
	if !socket_exists {
		Ok({})
	} else {
		connection = ["-s", socket_path.display()]
		info = redis_command_with_limit!(timeout_program, "1s", redis_cli, connection, ["INFO", "server"], Bool.False) ? |error|
			CatalogFailed("refusing to remove or signal through existing socket ${socket_path.display()}: exact Redis identity could not be established: ${describe_catalog_error(error)}")
		pid_text = HarnessText.redis_info_field(info, "process_id") ? |_| CatalogFailed("refusing to signal Redis at ${socket_path.display()}: INFO omitted process_id")
		pid = parse_pid_output(pid_text) ? |error| CatalogFailed("refusing to signal Redis at ${socket_path.display()}: ${describe_catalog_error(error)}")
		stop_redis_process!(timeout_program, redis_cli, socket_path, pid, "private-socket-owned temporary Redis")
	}
}

wait_for_temporary_owner! : Str, Str, List(Str), TemporaryRedis, U8 => Try({}, [CatalogFailed(Str), ..])
wait_for_temporary_owner! = |timeout_program, redis_cli, connection, server, attempts_remaining| {
	if attempts_remaining == 0 {
		Err(CatalogFailed("temporary Redis did not become ready within five seconds; log: ${read_best_effort!(server.log_path)}"))
	} else if !(process_is_alive_bounded!(timeout_program, server.watchdog_pid)) {
		Err(CatalogFailed("parent-death watchdog ${server.watchdog_pid} exited while temporary Redis ${server.pid} remained alive"))
	} else {
		ping = redis_command_with_limit!(timeout_program, "0.25s", redis_cli, connection, ["PING"], Bool.False)
		match ping {
			Ok(reply) if reply == "PONG" => {
				info = redis_command_with_limit!(timeout_program, "0.25s", redis_cli, connection, ["INFO", "server"], Bool.False)?
				owner = HarnessText.redis_info_field(info, "process_id") ? |_| CatalogFailed("temporary Redis INFO omitted process_id")
				if owner == server.pid Ok({}) else Err(CatalogFailed("refusing temporary Redis connection owned by process ${owner}; expected ${server.pid}"))
			}
			_ => {
				Sleep.millis!(50)
				wait_for_temporary_owner!(timeout_program, redis_cli, connection, server, attempts_remaining - 1)
			}
		}
	}
}

stop_temporary_redis! : Str, Str, List(Str), TemporaryRedis => Try({}, [CatalogFailed(Str), ..])
stop_temporary_redis! = |timeout_program, redis_cli, connection, server| {
	_ = connection
	child_result = stop_redis_process!(timeout_program, redis_cli, server.socket_path, server.pid, "temporary Redis")
	match child_result {
		Err(error) => Err(error)
		Ok({}) => finish_stopped_temporary_redis_cleanup!(timeout_program, server.socket_path, server.watchdog_pid)
	}
}

SignalDecision : [AlreadyExited, RefuseUnowned, SignalOwned]

signal_decision : Bool, Bool -> SignalDecision
signal_decision = |alive, owns_identity|
	if !alive AlreadyExited else if owns_identity SignalOwned else RefuseUnowned

temporary_redis_endpoint_absent! : Str, Str, Path.Path => Try(Bool, [CatalogFailed(Str), ..])
temporary_redis_endpoint_absent! = |timeout_program, redis_cli, socket_path| {
	outcome = run_bounded_output_with_limit!(timeout_program, "1s", redis_cli, ["--raw", "-s", socket_path.display(), "PING"])?
	if outcome.exit_code == 0 {
		Ok(Bool.False)
	} else if outcome.exit_code == 1 {
		Ok(Bool.True)
	} else {
		Err(CatalogFailed("temporary Redis endpoint absence probe exited ${outcome.exit_code.to_str()}: ${bounded_output(outcome)}"))
	}
}

stop_redis_process! : Str, Str, Path.Path, Str, Str => Try({}, [CatalogFailed(Str), ..])
stop_redis_process! = |timeout_program, redis_cli, socket_path, pid, label| {
	connection = ["-s", socket_path.display()]
	match signal_decision(process_is_alive_bounded!(timeout_program, pid), temporary_server_is_owner!(timeout_program, redis_cli, connection, pid)) {
		AlreadyExited => finish_temporary_redis_stop!(timeout_program, redis_cli, socket_path, pid)
		RefuseUnowned => Err(CatalogFailed("refusing to signal process ${pid}: exact Redis INFO ownership of ${socket_path.display()} was not established"))
		SignalOwned => {
			term_result = terminate_process!(timeout_program, pid, "TERM")
			if wait_for_process_exit!(timeout_program, pid, 40) {
				finish_temporary_redis_stop!(timeout_program, redis_cli, socket_path, pid)
			} else {
				match signal_decision(process_is_alive_bounded!(timeout_program, pid), temporary_server_is_owner!(timeout_program, redis_cli, connection, pid)) {
					AlreadyExited => finish_temporary_redis_stop!(timeout_program, redis_cli, socket_path, pid)
					RefuseUnowned => Err(CatalogFailed("refusing SIGKILL for process ${pid}: exact Redis INFO ownership was lost after SIGTERM; TERM=${describe_try(term_result)}"))
					SignalOwned => {
						kill_result = terminate_process!(timeout_program, pid, "KILL")
						if wait_for_process_exit!(timeout_program, pid, 40) {
							finish_temporary_redis_stop!(timeout_program, redis_cli, socket_path, pid)
						} else {
							Err(CatalogFailed("${label} process ${pid} did not exit after identity-guarded SIGKILL; TERM=${describe_try(term_result)}, KILL=${describe_try(kill_result)}"))
						}
					}
				}
			}
		}
	}
}

finish_temporary_redis_stop! : Str, Str, Path.Path, Str => Try({}, [CatalogFailed(Str), ..])
finish_temporary_redis_stop! = |timeout_program, redis_cli, socket_path, pid|
	if temporary_redis_endpoint_absent!(timeout_program, redis_cli, socket_path)? {
		Ok({})
	} else {
		Err(CatalogFailed("refusing cleanup for exited PID ${pid}: Redis endpoint ${socket_path.display()} still responds and may belong to a different process"))
	}

ensure_watchdog_active! : Str, TemporaryRedis => Try({}, [CatalogFailed(Str), ..])
ensure_watchdog_active! = |timeout_program, server| {
	if process_is_alive_bounded!(timeout_program, server.watchdog_pid) {
		Ok({})
	} else if process_is_alive_bounded!(timeout_program, server.pid) {
		Err(CatalogFailed("parent-death watchdog ${server.watchdog_pid} exited while temporary Redis ${server.pid} remained alive"))
	} else {
		Err(CatalogFailed("temporary Redis ${server.pid} exited before live catalog verification completed"))
	}
}

stop_known_process! : Str, Str, Str => Try({}, [CatalogFailed(Str), ..])
stop_known_process! = |timeout_program, pid, label| {
	if !(process_is_alive_bounded!(timeout_program, pid)) {
		Ok({})
	} else {
		term_result = terminate_process!(timeout_program, pid, "TERM")
		if wait_for_process_exit!(timeout_program, pid, 40) {
			Ok({})
		} else {
			kill_result = terminate_process!(timeout_program, pid, "KILL")
			if wait_for_process_exit!(timeout_program, pid, 40) {
				Ok({})
			} else {
				Err(CatalogFailed("${label} process ${pid} did not exit after SIGKILL; TERM=${describe_try(term_result)}, KILL=${describe_try(kill_result)}"))
			}
		}
	}
}

describe_try : Try({}, [CatalogFailed(Str), ..]) -> Str
describe_try = |result|
	match result {
		Ok({}) => "ok"
		Err(error) => describe_catalog_error(error)
	}

combine_unit_results : Try({}, [CatalogFailed(Str), ..]), Try({}, [CatalogFailed(Str), ..]) -> Try({}, [CatalogFailed(Str), ..])
combine_unit_results = |first, second|
	match (first, second) {
		(Ok({}), Ok({})) => Ok({})
		(Err(error), Ok({})) => Err(CatalogFailed(describe_catalog_error(error)))
		(Ok({}), Err(error)) => Err(CatalogFailed(describe_catalog_error(error)))
		(Err(first_error), Err(second_error)) => Err(CatalogFailed("${describe_catalog_error(first_error)}; ${describe_catalog_error(second_error)}"))
	}

temporary_server_is_owner! : Str, Str, List(Str), Str => Bool
temporary_server_is_owner! = |timeout_program, redis_cli, connection, expected_pid|
	match redis_command_with_limit!(timeout_program, "2s", redis_cli, connection, ["INFO", "server"], Bool.False) {
		Ok(info) => HarnessText.redis_info_field(info, "process_id") == Ok(expected_pid)
		Err(_) => Bool.False
	}

terminate_process! : Str, Str, Str => Try({}, [CatalogFailed(Str), ..])
terminate_process! = |timeout_program, pid, signal| {
	outcome = run_bounded_output_with_limit!(timeout_program, "2s", "kill", ["-${signal}", pid])?
	if outcome.exit_code == 0 Ok({}) else Err(CatalogFailed("kill -${signal} ${pid} exited ${outcome.exit_code.to_str()}: ${bounded_output(outcome)}"))
}

wait_for_process_exit! : Str, Str, U16 => Bool
wait_for_process_exit! = |timeout_program, pid, attempts_remaining| {
	if !(process_is_alive_bounded!(timeout_program, pid)) {
		Bool.True
	} else if attempts_remaining == 0 {
		Bool.False
	} else {
		Sleep.millis!(50)
		wait_for_process_exit!(timeout_program, pid, attempts_remaining - 1)
	}
}

wait_for_marker! : Path.Path, Str, U8 => Try({}, [CatalogFailed(Str), ..])
wait_for_marker! = |path, label, attempts_remaining| {
	exists = path.is_file!() ? |error| CatalogFailed("inspect ${label}: ${Str.inspect(error)}")
	acknowledged = if exists {
		contents = path.read_utf8!() ? |error| CatalogFailed("read ${label}: ${Str.inspect(error)}")
		contents == "pending\n"
	} else {
		Bool.False
	}
	if acknowledged {
		Ok({})
	} else if attempts_remaining == 0 {
		Err(CatalogFailed("timed out waiting for ${label}"))
	} else {
		Sleep.millis!(25)
		wait_for_marker!(path, label, attempts_remaining - 1)
	}
}

process_is_alive_bounded! : Str, Str => Bool
process_is_alive_bounded! = |timeout_program, pid|
	match run_bounded_output_with_limit!(timeout_program, "1s", "kill", ["-0", pid]) {
		Ok(outcome) => outcome.exit_code == 0
		Err(_) => Bool.False
	}

read_best_effort! : Path.Path => Str
read_best_effort! = |path|
	match path.read_utf8!() {
		Ok(contents) => contents
		Err(error) => "<unavailable: ${Str.inspect(error)}>"
	}

encode_manifest : Manifest -> Str
encode_manifest = |manifest| {
	provenance = encode_json_object(
		[
			"\"contract\": ${encode_string_array(manifest.provenance.contract, 4)}",
			"\"description\": ${Json.to_str(manifest.provenance.description)}",
			"\"scoped_command_count\": ${manifest.provenance.scoped_command_count.to_str()}",
			"\"module_group_commands\": ${encode_string_array(manifest.provenance.module_group_commands, 4)}",
			"\"constructor_argument_overrides\": ${encode_string_array(manifest.provenance.constructor_argument_overrides, 4)}",
		],
		2,
	)
	entries = encode_json_array(manifest.entries.map(|entry| encode_entry(entry, 4)), 2)
	encode_json_object(
		[
			"\"redis_version\": ${Json.to_str(manifest.redis_version)}",
			"\"provenance\": ${provenance}",
			"\"scope_groups\": ${encode_string_array(manifest.scope_groups, 2)}",
			"\"entries\": ${entries}",
		],
		0,
	).concat("\n")
}

encode_entry : Entry, U64 -> Str
encode_entry = |entry, indentation| {
	base = [
		"\"command\": ${Json.to_str(entry.command)}",
		"\"group\": ${Json.to_str(entry.group)}",
		"\"arity\": ${entry.arity.to_str()}",
		"\"since\": ${Json.to_str(entry.since)}",
		"\"arguments\": ${encode_argument_array(entry.arguments, indentation + 2)}",
		"\"module\": ${Json.to_str(entry.module_name)}",
		"\"constructor\": ${Json.to_str(entry.constructor)}",
	]
	with_override = match entry.constructor_arguments {
		Original => base
		Override(arguments) => base.append("\"constructor_arguments\": ${encode_argument_array(arguments, indentation + 2)}")
	}
	with_flags = if entry.doc_flags.is_empty() with_override else with_override.append("\"doc_flags\": ${encode_string_array(entry.doc_flags, indentation + 2)}")
	with_status = with_flags.append("\"status\": ${Json.to_str(entry.status)}")
	fields = if entry.reason.is_empty() with_status else with_status.append("\"reason\": ${Json.to_str(entry.reason)}")
	encode_json_object(fields, indentation)
}

encode_argument_array : List(Argument), U64 -> Str
encode_argument_array = |arguments, indentation|
	encode_json_array(arguments.map(|argument| encode_argument(argument, indentation + 2)), indentation)

encode_argument : Argument, U64 -> Str
encode_argument = |argument, indentation| {
	base = [
		"\"name\": ${Json.to_str(argument.name)}",
		"\"type\": ${Json.to_str(argument.type)}",
	]
	with_token = if argument.token.is_empty() base else base.append("\"token\": ${Json.to_str(argument.token)}")
	with_flags = if argument.flags.is_empty() with_token else with_token.append("\"flags\": ${encode_string_array(argument.flags, indentation + 2)}")
	fields = if argument.arguments.is_empty() with_flags else with_flags.append("\"arguments\": ${encode_argument_array(argument.arguments, indentation + 2)}")
	encode_json_object(fields, indentation)
}

encode_string_array : List(Str), U64 -> Str
encode_string_array = |values, indentation| encode_json_array(values.map(Json.to_str), indentation)

encode_json_array : List(Str), U64 -> Str
encode_json_array = |items, indentation| {
	if items.is_empty() {
		"[]"
	} else {
		item_prefix = " ".repeat(indentation + 2)
		closing = " ".repeat(indentation)
		"[\n${item_prefix}${Str.join_with(items, ",\n${item_prefix}")}\n${closing}]"
	}
}

encode_json_object : List(Str), U64 -> Str
encode_json_object = |fields, indentation| {
	field_prefix = " ".repeat(indentation + 2)
	closing = " ".repeat(indentation)
	"{\n${field_prefix}${Str.join_with(fields, ",\n${field_prefix}")}\n${closing}}"
}

write_manifest_atomically! : Str => Try({}, [CatalogFailed(Str), ..])
write_manifest_atomically! = |contents| {
	seed = Random.seed_u64!() ? |error| CatalogFailed("choose manifest atomic-write name: ${Str.inspect(error)}")
	temporary = Path.utf8("${manifest_path.display()}.catalog-${seed.to_str()}.tmp")
	temporary.write_utf8!(contents) ? |error| CatalogFailed("write temporary manifest ${temporary.display()}: ${Str.inspect(error)}")
	match temporary.rename!(manifest_path) {
		Ok({}) => Ok({})
		Err(error) => {
			cleanup = delete_if_present!(temporary)
			message = "atomically replace ${manifest_path.display()}: ${Str.inspect(error)}"
			match cleanup {
				Ok({}) => Err(CatalogFailed(message))
				Err(cleanup_error) => Err(CatalogFailed("${message}; ${describe_catalog_error(cleanup_error)}"))
			}
		}
	}
}

load_manifest! : {} => Try(Manifest, [CatalogFailed(Str), ..])
load_manifest! = |_| {
	contents = manifest_path.read_utf8!() ? |error| CatalogFailed("read ${manifest_path.display()}: ${Str.inspect(error)}")
	if contents.contains("\"summary\"") {
		Err(CatalogFailed("manifest must not contain Redis summary prose"))
	} else {
		parsed : Try(RawManifest, _)
		parsed = Json.parse(manifest_json_for_roc(contents))
		raw = parsed ? |error| CatalogFailed("parse ${manifest_path.display()}: ${Str.inspect(error)}")
		manifest = manifest_from_raw(raw)?
		validate_manifest(manifest)?
		Ok(manifest)
	}
}

manifest_from_raw : RawManifest -> Try(Manifest, [CatalogFailed(Str), ..])
manifest_from_raw = |raw| {
	entries = raw.entries.map_try(entry_from_raw)?
	Ok({
		redis_version: raw.redis_version,
		provenance: raw.provenance,
		scope_groups: raw.scope_groups,
		entries,
	})
}

entry_from_raw : RawEntry -> Try(Entry, [CatalogFailed(Str), ..])
entry_from_raw = |raw| {
	arguments = raw.arguments.map_try(argument_from_raw4)?
	constructor_arguments =
		match raw.?constructor_arguments {
			Ok(raw_arguments) => Override(raw_arguments.map_try(argument_from_raw4)?)
			Err(_) => Original
		}
	Ok({
		command: raw.command,
		group: raw.group,
		arity: raw.arity,
		since: raw.since,
		arguments,
		module_name: raw.module_name,
		constructor: raw.constructor,
		doc_flags: (raw.?doc_flags ?? []).sort_with(str_order),
		constructor_arguments,
		status: raw.status,
		reason: raw.?reason ?? "",
	})
}

argument_from_raw4 : RawArgument4 -> Try(Argument, [CatalogFailed(Str), ..])
argument_from_raw4 = |raw| {
	children = (raw.?arguments ?? []).map_try(argument_from_raw3)?
	Ok(argument_from_fields(raw.name, raw.type, raw.?token, raw.?flags, children))
}

argument_from_raw3 : RawArgument3 -> Try(Argument, [CatalogFailed(Str), ..])
argument_from_raw3 = |raw| {
	children = (raw.?arguments ?? []).map_try(argument_from_raw2)?
	Ok(argument_from_fields(raw.name, raw.type, raw.?token, raw.?flags, children))
}

argument_from_raw2 : RawArgument2 -> Try(Argument, [CatalogFailed(Str), ..])
argument_from_raw2 = |raw| {
	children = (raw.?arguments ?? []).map_try(argument_from_raw1)?
	Ok(argument_from_fields(raw.name, raw.type, raw.?token, raw.?flags, children))
}

argument_from_raw1 : RawArgument1 -> Try(Argument, [CatalogFailed(Str), ..])
argument_from_raw1 = |raw| {
	children = (raw.?arguments ?? []).map_try(argument_from_raw0)?
	Ok(argument_from_fields(raw.name, raw.type, raw.?token, raw.?flags, children))
}

argument_from_raw0 : RawArgument0 -> Try(Argument, [CatalogFailed(Str), ..])
argument_from_raw0 = |raw| {
	unexpected_children = raw.?arguments ?? []
	if unexpected_children.is_empty() {
		Ok(argument_from_fields(raw.name, raw.type, raw.?token, raw.?flags, []))
	} else {
		Err(CatalogFailed("argument metadata exceeds the supported nesting depth of five at ${Str.inspect(raw.name)}"))
	}
}

argument_from_fields : Str, Str, Try(Str, [MissingField]), Try(List(Str), [MissingField]), List(Argument) -> Argument
argument_from_fields = |name, type_, token, flags, arguments|
	Argument.{
		name,
		type: type_,
		token: token ?? "",
		flags: (flags ?? []).sort_with(str_order),
		arguments,
	}

validate_manifest : Manifest -> Try({}, [CatalogFailed(Str), ..])
validate_manifest = |manifest| {
	if manifest.redis_version != redis_version {
		Err(CatalogFailed("manifest is not pinned to Redis ${redis_version}"))
	} else if manifest.scope_groups != scope_groups {
		Err(CatalogFailed("manifest scope groups differ from the generated-module policy"))
	} else if manifest.provenance.contract != expected_public_contract {
		Err(CatalogFailed("manifest provenance does not name the expected public contract"))
	} else if manifest.provenance.scoped_command_count != manifest.entries.len() {
		Err(CatalogFailed("manifest provenance count does not match its entries"))
	} else if manifest.provenance.module_group_commands != vector_set_commands {
		Err(CatalogFailed("manifest vector-set command policy differs from the expected set"))
	} else if manifest.provenance.constructor_argument_overrides != constructor_argument_overrides {
		Err(CatalogFailed("manifest constructor overrides differ from the expected set"))
	} else if manifest.entries.len() != expected_scoped_count {
		Err(CatalogFailed("expected ${expected_scoped_count.to_str()} in-scope entries, found ${manifest.entries.len().to_str()}"))
	} else {
		validate_entries(manifest.entries)
	}
}

validate_entries : List(Entry) -> Try({}, [CatalogFailed(Str), ..])
validate_entries = |entries| {
	names = entries.map(|entry| entry.command)
	if names != names.sort_with(str_order) {
		Err(CatalogFailed("manifest entries must be sorted by command name"))
	} else if has_duplicate_adjacent(names) {
		Err(CatalogFailed("manifest contains duplicate command names"))
	} else {
		validate_entry_rows(entries)?
		validate_exclusions(entries)?
		validate_modules(entries)?
		validate_vectors(entries)?
		validate_overrides(entries)?
		Ok({})
	}
}

has_duplicate_adjacent : List(Str) -> Bool
has_duplicate_adjacent = |names|
	match names {
		[first, second, .. as rest] => first == second or has_duplicate_adjacent([second].concat(rest))
		_ => Bool.False
	}

str_order : Str, Str -> [Before, Same, After]
str_order = |left, right| bytes_order(left.to_utf8(), right.to_utf8())

bytes_order : List(U8), List(U8) -> [Before, Same, After]
bytes_order = |left, right|
	match (left, right) {
		([], []) => Same
		([], [_, ..]) => Before
		([_, ..], []) => After
		([left_byte, .. as left_rest], [right_byte, .. as right_rest]) =>
			if left_byte < right_byte {
				Before
			} else if left_byte > right_byte {
				After
			} else {
				bytes_order(left_rest, right_rest)
			}
		}

validate_entry_rows : List(Entry) -> Try({}, [CatalogFailed(Str), ..])
validate_entry_rows = |entries|
	match entries {
		[] => Ok({})
		[entry, .. as rest] => {
			policy = module_policy_for_group(entry.group) ? |_| CatalogFailed("unexpected group for ${entry.command}: ${entry.group}")
			expected_constructor = constructor_name(entry.command)
			if entry.module_name != policy.module_name {
				Err(CatalogFailed("wrong module for ${entry.command}: ${entry.module_name}"))
			} else if entry.constructor != expected_constructor {
				Err(CatalogFailed("wrong constructor for ${entry.command}: expected ${expected_constructor}"))
			} else if entry.status != "included" and entry.status != "excluded" {
				Err(CatalogFailed("invalid status for ${entry.command}: ${entry.status}"))
			} else {
				validate_entry_rows(rest)
			}
		}
	}

validate_exclusions : List(Entry) -> Try({}, [CatalogFailed(Str), ..])
validate_exclusions = |entries| {
	excluded = entries.keep_if(|entry| entry.status == "excluded")
	if excluded.len() != exclusion_policies.len() {
		Err(CatalogFailed("manifest exclusions differ from policy"))
	} else if exclusion_policies.all(
		|policy|
			match excluded.find_first(|entry| entry.command == policy.command) {
				Ok(entry) => entry.reason == policy.reason
				Err(_) => Bool.False
			},
	) {
		Ok({})
	} else {
		Err(CatalogFailed("manifest exclusion names or reasons differ from policy"))
	}
}

validate_modules : List(Entry) -> Try({}, [CatalogFailed(Str), ..])
validate_modules = |entries| {
	included = entries.keep_if(|entry| entry.status == "included")
	if included.len() != expected_included_count {
		Err(CatalogFailed("expected ${expected_included_count.to_str()} constructors, found ${included.len().to_str()}"))
	} else if module_policies.all(|policy| included.count_if(|entry| entry.module_name == policy.module_name) == policy.count) {
		Ok({})
	} else {
		Err(CatalogFailed("included command counts differ from module policy"))
	}
}

validate_vectors : List(Entry) -> Try({}, [CatalogFailed(Str), ..])
validate_vectors = |entries| {
	actual = entries.keep_if(|entry| entry.group == "module").map(|entry| entry.command)
	if actual == vector_set_commands Ok({}) else Err(CatalogFailed("manifest module-group entries differ from the vector-set policy"))
}

validate_overrides : List(Entry) -> Try({}, [CatalogFailed(Str), ..])
validate_overrides = |entries| {
	overridden = entries.keep_if(
		|entry|
			match entry.constructor_arguments {
				Override(_) => Bool.True
				Original => Bool.False
			},
	).map(|entry| entry.command)
	if overridden != constructor_argument_overrides {
		Err(CatalogFailed("manifest constructor override entries differ from policy"))
	} else {
		validate_override_rows(entries)
	}
}

validate_override_rows : List(Entry) -> Try({}, [CatalogFailed(Str), ..])
validate_override_rows = |entries|
	match entries {
		[] => Ok({})
		[entry, .. as rest] if constructor_argument_overrides.contains(entry.command) => {
			actual = match entry.constructor_arguments {
				Override(arguments) => arguments
				Original => return Err(CatalogFailed("missing constructor arguments for ${entry.command}"))
			}
			expected = constructor_arguments_override(entry.command, entry.arguments)?
			if arguments_equal(actual, expected) validate_override_rows(rest) else Err(CatalogFailed("stale constructor argument override for ${entry.command}"))
		}
		[_entry, .. as rest] => validate_override_rows(rest)
	}

module_policy_for_group : Str -> Try({ group : Str, module_name : Str, count : U64 }, [NotFound])
module_policy_for_group = |group| module_policies.find_first(|policy| policy.group == group)

manifest_json_for_roc : Str -> Str
manifest_json_for_roc = |contents|
	module_policies.fold(
		contents,
		|rewritten, policy|
			rewritten
				.replace_each("\"module\": ${Json.to_str(policy.module_name)}", "\"module_name\": ${Json.to_str(policy.module_name)}")
				.replace_each("\"module\":${Json.to_str(policy.module_name)}", "\"module_name\":${Json.to_str(policy.module_name)}"),
	)

docs_json_for_roc : Str -> Str
docs_json_for_roc = |contents|
	contents
		.replace_each("\"module\":\"vectorset\"", "\"module_name\":\"vectorset\"")
		.replace_each("\"module\": \"vectorset\"", "\"module_name\": \"vectorset\"")

argument_flags : Argument -> List(Str)
argument_flags = |argument| argument.flags

argument_children : Argument -> List(Argument)
argument_children = |argument| argument.arguments

argument_token : Argument -> Str
argument_token = |argument| argument.token

entry_doc_flags : Entry -> List(Str)
entry_doc_flags = |entry| entry.doc_flags

entry_constructor_arguments : Entry -> List(Argument)
entry_constructor_arguments = |entry|
	match entry.constructor_arguments {
		Override(arguments) => arguments
		Original => entry.arguments
	}

arguments_equal : List(Argument), List(Argument) -> Bool
arguments_equal = |left, right|
	match (left, right) {
		([], []) => Bool.True
		([left_first, .. as left_rest], [right_first, .. as right_rest]) =>
			argument_equal(left_first, right_first) and arguments_equal(left_rest, right_rest)
		_ => Bool.False
	}

argument_equal : Argument, Argument -> Bool
argument_equal = |left, right|
	left.name == right.name
		and left.type == right.type
			and left.token == right.token
				and left.flags == right.flags
					and arguments_equal(left.arguments, right.arguments)

constructor_arguments_override : Str, List(Argument) -> Try(List(Argument), [CatalogFailed(Str), ..])
constructor_arguments_override = |command, arguments|
	if command == "hotkeys|start" {
		match arguments {
			[first, .. as rest] if first.name == "metrics" and first.type == "block" and first.token == "METRICS" and !(is_optional(first)) and rest.all(is_optional) =>
				Ok([{ ..first, flags: ["optional"] }].concat(rest))
			_ => Err(CatalogFailed("unsupported Redis HOTKEYS START argument metadata shape"))
		}
	} else {
		vector_constructor_arguments(command, arguments)
	}

vector_constructor_arguments : Str, List(Argument) -> Try(List(Argument), [CatalogFailed(Str), ..])
vector_constructor_arguments = |command, arguments| {
	names = arguments.map(|argument| argument.name)
	if command == "vadd" {
		expected_prefix = ["key", "reduce", "format", "vector", "element"]
		if names.take_first(expected_prefix.len()) != expected_prefix {
			Err(CatalogFailed("unsupported Redis VADD argument metadata shape: ${Str.inspect(names)}"))
		} else {
			Ok(arguments.take_first(2).concat([vector_input_choice("input", Bool.False)]).concat(arguments.drop_first(4)))
		}
	} else if command == "vsim" {
		expected_prefix = ["key", "format", "vector_or_element"]
		if names.take_first(expected_prefix.len()) != expected_prefix {
			Err(CatalogFailed("unsupported Redis VSIM argument metadata shape: ${Str.inspect(names)}"))
		} else {
			key = arguments.get(0) ? |_| CatalogFailed("missing VSIM key metadata")
			Ok([key, vector_input_choice("query", Bool.True)].concat(arguments.drop_first(3)))
		}
	} else {
		Err(CatalogFailed("unexpected vector constructor override: ${command}"))
	}
}

vector_input_choice : Str, Bool -> Argument
vector_input_choice = |name, include_element| {
	element = Argument.{
		name: "element",
		type: "block",
		token: "ELE",
		flags: [],
		arguments: [Argument.{ name: "element", type: "string", token: "", flags: [], arguments: [] }],
	}
	fp32 = Argument.{
		name: "fp32",
		type: "block",
		token: "FP32",
		flags: [],
		arguments: [Argument.{ name: "blob", type: "string", token: "", flags: [], arguments: [] }],
	}
	values = Argument.{
		name: "values",
		type: "block",
		token: "VALUES",
		flags: [],
		arguments: [
			Argument.{ name: "num", type: "integer", token: "", flags: [], arguments: [] },
			Argument.{ name: "value", type: "double", token: "", flags: ["multiple"], arguments: [] },
		],
	}
	alternatives = if include_element [element, fp32, values] else [fp32, values]
	Argument.{ name, type: "oneof", token: "", flags: [], arguments: alternatives }
}

Parameter : { name : Str, roc_type : Str, sample : Str, minimal_sample : Str }

Segment : {
	parameters : List(Parameter),
	statements : List(Str),
	expression : Str,
	sample_arguments : List(List(U8)),
	minimal_sample_arguments : List(List(U8)),
}

CompilerState : {
	command : Str,
	used_names : List(Str),
	sample_counter : U64,
}

CompiledSegment : { segment : Segment, state : CompilerState }

CompiledSegments : { segments : List(Segment), state : CompilerState }

SampledArguments : { arguments : List(List(U8)), state : CompilerState }

empty_segment : Segment
empty_segment = {
	parameters: [],
	statements: [],
	expression: "[]",
	sample_arguments: [],
	minimal_sample_arguments: [],
}

initial_compiler_state : Str -> CompilerState
initial_compiler_state = |command| { command, used_names: [], sample_counter: 1 }

allocate_name : Str, CompilerState -> { name : Str, state : CompilerState }
allocate_name = |requested, state| {
	base = identifier(requested)
	name = unused_name(base, 2, state.used_names)
	{
		name,
		state: { ..state, used_names: state.used_names.append(name) },
	}
}

unused_name : Str, U64, List(Str) -> Str
unused_name = |base, suffix, used_names| {
	candidate = if suffix == 2 and !(used_names.contains(base)) base else "${base}_${suffix.to_str()}"
	if used_names.contains(candidate) unused_name(base, suffix + 1, used_names) else candidate
}

sample_scalar : Argument, CompilerState -> { sample : List(U8), state : CompilerState }
sample_scalar = |argument, state| {
	value = state.sample_counter
	sample =
		if ["integer", "unix-time"].contains(argument.type) {
			value.to_str().to_utf8()
		} else if argument.type == "double" {
			"${value.to_str()}.5".to_utf8()
		} else {
			[0, U64.to_u8_wrap(value % 251), 255]
		}
	{ sample, state: { ..state, sample_counter: value + 1 } }
}

is_optional : Argument -> Bool
is_optional = |argument| argument.flags.contains("optional")

is_required_multiple : Argument -> Bool
is_required_multiple = |argument| argument.flags.contains("multiple") and !(is_optional(argument))

is_optional_bare_multiple : Argument -> Bool
is_optional_bare_multiple = |argument|
	is_optional(argument)
		and argument.flags.contains("multiple")
			and argument.token.is_empty()
				and is_scalar_type(argument.type)

is_scalar_type : Str -> Bool
is_scalar_type = |argument_type|
	["key", "string", "integer", "double", "unix-time", "pattern"].contains(argument_type)

drop_optional_prefix : List(Argument) -> List(Argument)
drop_optional_prefix = |arguments|
	match arguments {
		[first, .. as rest] if is_optional(first) => drop_optional_prefix(rest)
		_ => arguments
	}

compile_nodes : List(Argument), CompilerState -> Try(CompiledSegments, [CatalogFailed(Str), ..])
compile_nodes = |arguments, state|
	match arguments {
		[] => Ok({ segments: [], state })
		[first, .. as rest] => {
			compiled_and_remaining =
				if is_optional_bare_multiple(first) {
					{ compiled: compile_optional_multiple(first, state), remaining: rest }
				} else if is_optional(first) {
					remaining = drop_optional_prefix(rest)
					following = match remaining {
						[next, ..] => Following(next)
						[] => AtEnd
					}
					{ compiled: compile_raw_options(following, state), remaining }
				} else {
					match rest {
						[second, .. as remaining] if first.type == "integer"
							and ["numkeys", "numfields", "numids", "numranges"].contains(first.name)
								and is_required_multiple(second) =>
							{
								compiled: compile_counted_multiple(first, second, "", state),
								remaining,
							}
						[second, .. as remaining] if first.type == "integer"
							and ["numkeys", "numfields", "numids", "numranges"].contains(first.name)
								and is_optional_bare_multiple(second) =>
							{
								compiled: compile_counted_optional_multiple(first, second, "", state),
								remaining,
							}
						_ => { compiled: compile_node(first, state), remaining: rest }
					}
				}
			compiled = compiled_and_remaining.compiled?
			following = compile_nodes(compiled_and_remaining.remaining, compiled.state)?
			Ok({ segments: following.segments.prepend(compiled.segment), state: following.state })
		}
	}

compile_raw_options : [AtEnd, Following(Argument)], CompilerState -> Try(CompiledSegment, [CatalogFailed(Str), ..])
compile_raw_options = |following, state| {
	requested = match following {
		AtEnd => "options"
		Following(argument) => "options_before_${argument.name}"
	}
	allocated = allocate_name(requested, state)
	sampled = sample_raw_arguments(allocated.state)
	Ok({
		segment: {
			..empty_segment,
			parameters: [{ name: allocated.name, roc_type: "List(List(U8))", sample: raw_arguments_expression(sampled.arguments), minimal_sample: "[]" }],
			expression: allocated.name,
			sample_arguments: sampled.arguments,
			minimal_sample_arguments: [],
		},
		state: sampled.state,
	})
}

compile_optional_multiple : Argument, CompilerState -> Try(CompiledSegment, [CatalogFailed(Str), ..])
compile_optional_multiple = |argument, state| {
	allocated = allocate_name(pluralize(argument.name), state)
	sampled = sample_raw_arguments(allocated.state)
	Ok({
		segment: {
			..empty_segment,
			parameters: [{ name: allocated.name, roc_type: "List(List(U8))", sample: raw_arguments_expression(sampled.arguments), minimal_sample: "[]" }],
			expression: allocated.name,
			sample_arguments: sampled.arguments,
			minimal_sample_arguments: [],
		},
		state: sampled.state,
	})
}

sample_raw_arguments : CompilerState -> SampledArguments
sample_raw_arguments = |state| {
	argument = Argument.{ name: "sample", type: "string", token: "", flags: [], arguments: [] }
	first = sample_scalar(argument, state)
	second = sample_scalar(argument, first.state)
	{ arguments: [first.sample, second.sample], state: second.state }
}

raw_arguments_expression : List(List(U8)) -> Str
raw_arguments_expression = |arguments| "[${Str.join_with(arguments.map(bytes_expression), ", ")}]"

compile_node : Argument, CompilerState -> Try(CompiledSegment, [CatalogFailed(Str), ..])
compile_node = |argument, state| {
	if argument.type == "pure-token" {
		if argument.token.is_empty() {
			Err(CatalogFailed("pure token without token in ${state.command}"))
		} else {
			token_bytes = argument.token.to_utf8()
			Ok({
				segment: { ..empty_segment, expression: "[${bytes_expression(token_bytes)}]", sample_arguments: [token_bytes], minimal_sample_arguments: [token_bytes] },
				state,
			})
		}
	} else if is_scalar_type(argument.type) {
		if is_required_multiple(argument) compile_multiple_scalar(argument, argument.token, state) else compile_scalar(argument, state)
	} else if argument.type == "oneof" {
		if is_required_multiple(argument) compile_multiple_oneof(argument, state) else compile_oneof(argument, state)
	} else if argument.type == "block" {
		if is_required_multiple(argument) compile_multiple_block(argument, argument.token, state) else compile_block(argument, state)
	} else {
		Err(CatalogFailed("unsupported argument type ${Str.inspect(argument.type)} in ${state.command}"))
	}
}

compile_scalar : Argument, CompilerState -> Try(CompiledSegment, [CatalogFailed(Str), ..])
compile_scalar = |argument, state| {
	allocated = allocate_name(argument.name, state)
	sampled = sample_scalar(argument, allocated.state)
	pieces = if argument.token.is_empty() [allocated.name] else [bytes_expression(argument.token.to_utf8()), allocated.name]
	samples = if argument.token.is_empty() [sampled.sample] else [argument.token.to_utf8(), sampled.sample]
	Ok({
		segment: {
			..empty_segment,
			parameters: [{ name: allocated.name, roc_type: "List(U8)", sample: bytes_expression(sampled.sample), minimal_sample: bytes_expression(sampled.sample) }],
			expression: "[${Str.join_with(pieces, ", ")}]",
			sample_arguments: samples,
			minimal_sample_arguments: samples,
		},
		state: sampled.state,
	})
}

compile_multiple_scalar : Argument, Str, CompilerState -> Try(CompiledSegment, [CatalogFailed(Str), ..])
compile_multiple_scalar = |argument, token, state| {
	names = repeated_names(argument.name)
	first_allocated = allocate_name("first_${names.item}", state)
	others_allocated = allocate_name("other_${names.collection}", first_allocated.state)
	values_allocated = allocate_name("catalog_${names.collection}", others_allocated.state)
	first_sampled = sample_scalar(argument, values_allocated.state)
	other_sampled = sample_scalar(argument, first_sampled.state)
	values = values_allocated.name
	base_expression = values
	expression = if token.is_empty() base_expression else "[${bytes_expression(token.to_utf8())}].concat(${values})"
	samples = if token.is_empty() [first_sampled.sample, other_sampled.sample] else [token.to_utf8(), first_sampled.sample, other_sampled.sample]
	minimal_samples = if token.is_empty() [first_sampled.sample] else [token.to_utf8(), first_sampled.sample]
	Ok({
		segment: {
			parameters: [
				{ name: first_allocated.name, roc_type: "List(U8)", sample: bytes_expression(first_sampled.sample), minimal_sample: bytes_expression(first_sampled.sample) },
				{ name: others_allocated.name, roc_type: "List(List(U8))", sample: "[${bytes_expression(other_sampled.sample)}]", minimal_sample: "[]" },
			],
			statements: ["${values} = [${first_allocated.name}].concat(${others_allocated.name})"],
			expression,
			sample_arguments: samples,
			minimal_sample_arguments: minimal_samples,
		},
		state: other_sampled.state,
	})
}

compile_oneof : Argument, CompilerState -> Try(CompiledSegment, [CatalogFailed(Str), ..])
compile_oneof = |argument, state| {
	if vector_constructor_overrides.contains(state.command) and ["input", "query"].contains(argument.name) {
		compile_vector_input(argument, state)
	} else {
		match argument.arguments {
			[] => Err(CatalogFailed("empty oneof in ${state.command}"))
			[first_alternative, ..] => {
				sampled = sample_node(first_alternative, state)?
				minimal_alternative = minimum_alternative(argument.arguments, state.command)?
				minimal_sampled = sample_minimum_node(minimal_alternative, state)?
				allocated = allocate_name(argument.name, sampled.state)
				counts = argument.arguments.map_try(minimum_token_count)?
				if counts.all(|count| count == 1) {
					first_sample = sampled.arguments.first() ? |_| CatalogFailed("oneof sample was unexpectedly empty in ${state.command}")
					minimal_first_sample = minimal_sampled.arguments.first() ? |_| CatalogFailed("minimal oneof sample was unexpectedly empty in ${state.command}")
					Ok({
						segment: {
							..empty_segment,
							parameters: [{ name: allocated.name, roc_type: "List(U8)", sample: bytes_expression(first_sample), minimal_sample: bytes_expression(minimal_first_sample) }],
							expression: "[${allocated.name}]",
							sample_arguments: sampled.arguments,
							minimal_sample_arguments: minimal_sampled.arguments,
						},
						state: allocated.state,
					})
				} else {
					sample = nonempty_arguments_expression(sampled.arguments)?
					minimal_sample = nonempty_arguments_expression(minimal_sampled.arguments)?
					Ok({
						segment: {
							..empty_segment,
							parameters: [
								{
									name: allocated.name,
									roc_type: "{ first : List(U8), rest : List(List(U8)) }",
									sample,
									minimal_sample,
								},
							],
							expression: "[${allocated.name}.first].concat(${allocated.name}.rest)",
							sample_arguments: sampled.arguments,
							minimal_sample_arguments: minimal_sampled.arguments,
						},
						state: allocated.state,
					})
				}
			}
		}
	}
}

compile_vector_input : Argument, CompilerState -> Try(CompiledSegment, [CatalogFailed(Str), ..])
compile_vector_input = |argument, state| {
	name_allocated = allocate_name(argument.name, state)
	encoded_allocated = allocate_name("encoded_${name_allocated.name}", name_allocated.state)
	include_element = state.command == "vsim"
	values_type = "{ first : List(U8), rest : List(List(U8)) }"
	tags = if include_element ["Element(List(U8))", "Fp32(List(U8))", "Values(${values_type})"] else ["Fp32(List(U8))", "Values(${values_type})"]
	branches =
		if include_element {
			[
				"Element(element) => [${bytes_expression("ELE".to_utf8())}, element]",
				"Fp32(blob) => [${bytes_expression("FP32".to_utf8())}, blob]",
				vector_values_branch,
			]
		} else {
			[
				"Fp32(blob) => [${bytes_expression("FP32".to_utf8())}, blob]",
				vector_values_branch,
			]
		}
	statement = "${encoded_allocated.name} = match ${name_allocated.name} {\n\t${Str.join_with(branches, "\n\t")}\n}"
	sample_argument = Argument.{ name: "sample", type: "string", token: "", flags: [], arguments: [] }
	sampled = sample_scalar(sample_argument, encoded_allocated.state)
	sample = if include_element "Element(${bytes_expression(sampled.sample)})" else "Fp32(${bytes_expression(sampled.sample)})"
	sample_arguments = if include_element ["ELE".to_utf8(), sampled.sample] else ["FP32".to_utf8(), sampled.sample]
	Ok({
		segment: {
			parameters: [{ name: name_allocated.name, roc_type: "[${Str.join_with(tags, ", ")}]", sample, minimal_sample: sample }],
			statements: [statement],
			expression: encoded_allocated.name,
			sample_arguments,
			minimal_sample_arguments: sample_arguments,
		},
		state: sampled.state,
	})
}

vector_values_branch : Str
vector_values_branch = "Values({ first, rest }) => {\n\tvalues = [first].concat(rest)\n\t[${bytes_expression("VALUES".to_utf8())}, values.len().to_str().to_utf8()].concat(values)\n}"

compile_multiple_oneof : Argument, CompilerState -> Try(CompiledSegment, [CatalogFailed(Str), ..])
compile_multiple_oneof = |argument, state| {
	counts = argument.arguments.map_try(minimum_token_count)?
	if counts.is_empty() or !(counts.all(|count| count == 2)) {
		Err(CatalogFailed("unsupported repeated oneof shape in ${state.command}"))
	} else {
		first_alternative = argument.arguments.first() ? |_| CatalogFailed("empty repeated oneof in ${state.command}")
		last_alternative = argument.arguments.last() ? |_| CatalogFailed("empty repeated oneof in ${state.command}")
		names = repeated_names(argument.name)
		first_allocated = allocate_name("first_${names.item}", state)
		others_allocated = allocate_name("other_${names.collection}", first_allocated.state)
		values_allocated = allocate_name("catalog_${names.collection}", others_allocated.state)
		first_sampled = sample_node(first_alternative, values_allocated.state)?
		other_sampled = sample_node(last_alternative, first_sampled.state)?
		if first_sampled.arguments.len() != 2 or other_sampled.arguments.len() != 2 {
			Err(CatalogFailed("repeated oneof sample did not contain two tokens in ${state.command}"))
		} else {
			first_operator = first_sampled.arguments.get(0) ? |_| CatalogFailed("missing repeated oneof operator sample in ${state.command}")
			first_operand = first_sampled.arguments.get(1) ? |_| CatalogFailed("missing repeated oneof operand sample in ${state.command}")
			other_operator = other_sampled.arguments.get(0) ? |_| CatalogFailed("missing repeated oneof operator sample in ${state.command}")
			other_operand = other_sampled.arguments.get(1) ? |_| CatalogFailed("missing repeated oneof operand sample in ${state.command}")
			record_type = "{ operator : List(U8), operand : List(U8) }"
			Ok({
				segment: {
					parameters: [
						{
							name: first_allocated.name,
							roc_type: record_type,
							sample: record_expression(["operator", "operand"], [first_operator, first_operand]),
							minimal_sample: record_expression(["operator", "operand"], [first_operator, first_operand]),
						},
						{
							name: others_allocated.name,
							roc_type: "List(${record_type})",
							sample: "[${record_expression(["operator", "operand"], [other_operator, other_operand])}]",
							minimal_sample: "[]",
						},
					],
					statements: ["${values_allocated.name} = [${first_allocated.name}].concat(${others_allocated.name})"],
					expression: "${values_allocated.name}.join_map(|item| [item.operator, item.operand])",
					sample_arguments: first_sampled.arguments.concat(other_sampled.arguments),
					minimal_sample_arguments: first_sampled.arguments,
				},
				state: other_sampled.state,
			})
		}
	}
}

compile_block : Argument, CompilerState -> Try(CompiledSegment, [CatalogFailed(Str), ..])
compile_block = |argument, state| {
	match argument.arguments {
		[first, second] if first.type == "integer"
			and ["numkeys", "numfields", "numids", "numranges"].contains(first.name)
				and is_required_multiple(second) =>
			compile_counted_multiple(first, second, argument.token, state)
		[first, second] if is_required_multiple(first) and is_required_multiple(second) =>
			compile_parallel_multiple(argument, first, second, state)
		children => {
			compiled = compile_nodes(children, state)?
			parameters = compiled.segments.join_map(|segment| segment.parameters)
			statements = compiled.segments.join_map(|segment| segment.statements)
			expressions = compiled.segments.map(|segment| segment.expression).keep_if(|expression| expression != "[]")
			samples = compiled.segments.join_map(|segment| segment.sample_arguments)
			minimal_samples = compiled.segments.join_map(|segment| segment.minimal_sample_arguments)
			prefixed_expressions = if argument.token.is_empty() expressions else expressions.prepend("[${bytes_expression(argument.token.to_utf8())}]")
			prefixed_samples = if argument.token.is_empty() samples else samples.prepend(argument.token.to_utf8())
			prefixed_minimal_samples = if argument.token.is_empty() minimal_samples else minimal_samples.prepend(argument.token.to_utf8())
			Ok({
				segment: {
					parameters,
					statements,
					expression: concat_expressions(prefixed_expressions),
					sample_arguments: prefixed_samples,
					minimal_sample_arguments: prefixed_minimal_samples,
				},
				state: compiled.state,
			})
		}
	}
}

compile_multiple_block : Argument, Str, CompilerState -> Try(CompiledSegment, [CatalogFailed(Str), ..])
compile_multiple_block = |argument, token, state| {
	children = argument.arguments
	valid = !(children.is_empty()) and children.all(|child| is_scalar_type(child.type) and !(is_optional(child)) and child.flags.is_empty() and child.token.is_empty())
	if !valid {
		Err(CatalogFailed("unsupported repeated block shape in ${state.command}"))
	} else {
		field_names = unique_field_names(children.map(|child| child.name))
		record_type = "{ ${Str.join_with(field_names.map(|name| "${name} : List(U8)"), ", ")} }"
		names = repeated_names(argument.name)
		first_allocated = allocate_name("first_${names.item}", state)
		others_allocated = allocate_name("other_${names.collection}", first_allocated.state)
		values_allocated = allocate_name("catalog_${names.collection}", others_allocated.state)
		first_samples = sample_scalars(children, values_allocated.state)
		other_samples = sample_scalars(children, first_samples.state)
		flattened = Str.join_with(field_names.map(|name| "item.${name}"), ", ")
		base_expression = "${values_allocated.name}.join_map(|item| [${flattened}])"
		expression = if token.is_empty() base_expression else "[${bytes_expression(token.to_utf8())}].concat(${base_expression})"
		samples = first_samples.arguments.concat(other_samples.arguments)
		prefixed_samples = if token.is_empty() samples else samples.prepend(token.to_utf8())
		Ok({
			segment: {
				parameters: [
					{
						name: first_allocated.name,
						roc_type: record_type,
						sample: record_expression(field_names, first_samples.arguments),
						minimal_sample: record_expression(field_names, first_samples.arguments),
					},
					{
						name: others_allocated.name,
						roc_type: "List(${record_type})",
						sample: "[${record_expression(field_names, other_samples.arguments)}]",
						minimal_sample: "[]",
					},
				],
				statements: ["${values_allocated.name} = [${first_allocated.name}].concat(${others_allocated.name})"],
				expression,
				sample_arguments: prefixed_samples,
				minimal_sample_arguments: if token.is_empty() first_samples.arguments else first_samples.arguments.prepend(token.to_utf8()),
			},
			state: other_samples.state,
		})
	}
}

compile_counted_multiple : Argument, Argument, Str, CompilerState -> Try(CompiledSegment, [CatalogFailed(Str), ..])
compile_counted_multiple = |_count_argument, values_argument, token, state| {
	compiled_result =
		if values_argument.type == "block" {
			compile_multiple_block(values_argument, "", state)
		} else {
			compile_multiple_scalar(values_argument, "", state)
		}
	compiled = compiled_result?
	statement = compiled.segment.statements.first() ? |_| CatalogFailed("counted collection had no binding in ${state.command}")
	assignment = statement.split_first(" = ") ? |_| CatalogFailed("invalid counted collection binding in ${state.command}")
	count = "${assignment.before}.len().to_str().to_utf8()"
	prefix = if token.is_empty() [count] else [bytes_expression(token.to_utf8()), count]
	prefix_samples = if token.is_empty() ["2".to_utf8()] else [token.to_utf8(), "2".to_utf8()]
	minimal_prefix_samples = if token.is_empty() ["1".to_utf8()] else [token.to_utf8(), "1".to_utf8()]
	Ok({
		segment: {
			..compiled.segment,
			expression: "[${Str.join_with(prefix, ", ")}].concat(${compiled.segment.expression})",
			sample_arguments: prefix_samples.concat(compiled.segment.sample_arguments),
			minimal_sample_arguments: minimal_prefix_samples.concat(compiled.segment.minimal_sample_arguments),
		},
		state: compiled.state,
	})
}

compile_counted_optional_multiple : Argument, Argument, Str, CompilerState -> Try(CompiledSegment, [CatalogFailed(Str), ..])
compile_counted_optional_multiple = |_count_argument, values_argument, token, state| {
	compiled = compile_optional_multiple(values_argument, state)?
	parameter = compiled.segment.parameters.first() ? |_| CatalogFailed("counted optional collection had no parameter in ${state.command}")
	count = "${parameter.name}.len().to_str().to_utf8()"
	prefix = if token.is_empty() [count] else [bytes_expression(token.to_utf8()), count]
	prefix_samples = if token.is_empty() ["2".to_utf8()] else [token.to_utf8(), "2".to_utf8()]
	minimal_prefix_samples = if token.is_empty() ["0".to_utf8()] else [token.to_utf8(), "0".to_utf8()]
	Ok({
		segment: {
			..compiled.segment,
			expression: "[${Str.join_with(prefix, ", ")}].concat(${compiled.segment.expression})",
			sample_arguments: prefix_samples.concat(compiled.segment.sample_arguments),
			minimal_sample_arguments: minimal_prefix_samples,
		},
		state: compiled.state,
	})
}

compile_parallel_multiple : Argument, Argument, Argument, CompilerState -> Try(CompiledSegment, [CatalogFailed(Str), ..])
compile_parallel_multiple = |argument, first_child, second_child, state| {
	field_names = unique_field_names([first_child.name, second_child.name])
	first_field = field_names.get(0) ? |_| CatalogFailed("missing first parallel field in ${state.command}")
	second_field = field_names.get(1) ? |_| CatalogFailed("missing second parallel field in ${state.command}")
	record_type = "{ ${first_field} : List(U8), ${second_field} : List(U8) }"
	names = repeated_names(argument.name)
	first_allocated = allocate_name("first_${names.item}", state)
	others_allocated = allocate_name("other_${names.collection}", first_allocated.state)
	values_allocated = allocate_name("catalog_${names.collection}", others_allocated.state)
	first_samples = sample_scalars([first_child, second_child], values_allocated.state)
	other_samples = sample_scalars([first_child, second_child], first_samples.state)
	first_first = first_samples.arguments.get(0) ? |_| CatalogFailed("missing first parallel sample in ${state.command}")
	first_second = first_samples.arguments.get(1) ? |_| CatalogFailed("missing second parallel sample in ${state.command}")
	other_first = other_samples.arguments.get(0) ? |_| CatalogFailed("missing first parallel sample in ${state.command}")
	other_second = other_samples.arguments.get(1) ? |_| CatalogFailed("missing second parallel sample in ${state.command}")
	prefix = if argument.token.is_empty() "[]" else "[${bytes_expression(argument.token.to_utf8())}]"
	expression = "${prefix}.concat(${values_allocated.name}.map(|item| item.${first_field})).concat(${values_allocated.name}.map(|item| item.${second_field}))"
	samples = [first_first, other_first, first_second, other_second]
	prefixed_samples = if argument.token.is_empty() samples else samples.prepend(argument.token.to_utf8())
	Ok({
		segment: {
			parameters: [
				{
					name: first_allocated.name,
					roc_type: record_type,
					sample: record_expression(field_names, [first_first, first_second]),
					minimal_sample: record_expression(field_names, [first_first, first_second]),
				},
				{
					name: others_allocated.name,
					roc_type: "List(${record_type})",
					sample: "[${record_expression(field_names, [other_first, other_second])}]",
					minimal_sample: "[]",
				},
			],
			statements: ["${values_allocated.name} = [${first_allocated.name}].concat(${others_allocated.name})"],
			expression,
			sample_arguments: prefixed_samples,
			minimal_sample_arguments: if argument.token.is_empty() [first_first, first_second] else [argument.token.to_utf8(), first_first, first_second],
		},
		state: other_samples.state,
	})
}

sample_scalars : List(Argument), CompilerState -> SampledArguments
sample_scalars = |arguments, state|
	match arguments {
		[] => { arguments: [], state }
		[first, .. as rest] => {
			sampled = sample_scalar(first, state)
			following = sample_scalars(rest, sampled.state)
			{ arguments: following.arguments.prepend(sampled.sample), state: following.state }
		}
	}

minimum_alternative : List(Argument), Str -> Try(Argument, [CatalogFailed(Str), ..])
minimum_alternative = |alternatives, command|
	match alternatives {
		[] => Err(CatalogFailed("empty oneof while selecting a minimal sample in ${command}"))
		[first, .. as rest] => {
			count = minimum_token_count(first)?
			minimum_alternative_help(rest, first, count)
		}
	}

minimum_alternative_help : List(Argument), Argument, U64 -> Try(Argument, [CatalogFailed(Str), ..])
minimum_alternative_help = |remaining, selected, selected_count|
	match remaining {
		[] => Ok(selected)
		[first, .. as rest] => {
			count = minimum_token_count(first)?
			if count < selected_count {
				minimum_alternative_help(rest, first, count)
			} else {
				minimum_alternative_help(rest, selected, selected_count)
			}
		}
	}

minimum_token_count : Argument -> Try(U64, [CatalogFailed(Str), ..])
minimum_token_count = |argument| {
	prefix : U64
	prefix = if argument.token.is_empty() 0 else 1
	if argument.type == "pure-token" {
		Ok(1)
	} else if is_scalar_type(argument.type) {
		Ok(prefix + 1)
	} else if argument.type == "block" {
		counts = argument.arguments.keep_if(|child| !(is_optional(child))).map_try(minimum_token_count)?
		Ok(prefix + counts.sum())
	} else if argument.type == "oneof" {
		counts = argument.arguments.map_try(minimum_token_count)?
		minimum = list_min_u64(counts) ? |_| CatalogFailed("empty oneof while counting tokens")
		Ok(prefix + minimum)
	} else {
		Err(CatalogFailed("unsupported argument type while counting: ${Str.inspect(argument.type)}"))
	}
}

list_min_u64 : List(U64) -> Try(U64, [NotFound])
list_min_u64 = |values|
	match values {
		[] => Err(NotFound)
		[first, .. as rest] => Ok(rest.fold(first, |lowest, value| if value < lowest value else lowest))
	}

sample_node : Argument, CompilerState -> Try(SampledArguments, [CatalogFailed(Str), ..])
sample_node = |argument, state| {
	prefix = if argument.token.is_empty() [] else [argument.token.to_utf8()]
	if argument.type == "pure-token" {
		if argument.token.is_empty() Err(CatalogFailed("pure token without token while sampling ${state.command}")) else Ok({ arguments: [argument.token.to_utf8()], state })
	} else if is_scalar_type(argument.type) {
		sampled = sample_scalar(argument, state)
		Ok({ arguments: prefix.append(sampled.sample), state: sampled.state })
	} else if argument.type == "block" {
		sampled = sample_required_nodes(argument.arguments, state)?
		Ok({ arguments: prefix.concat(sampled.arguments), state: sampled.state })
	} else if argument.type == "oneof" {
		first = argument.arguments.first() ? |_| CatalogFailed("empty oneof while sampling ${state.command}")
		sampled = sample_node(first, state)?
		Ok({ arguments: prefix.concat(sampled.arguments), state: sampled.state })
	} else {
		Err(CatalogFailed("unsupported sample argument type ${Str.inspect(argument.type)} in ${state.command}"))
	}
}

sample_minimum_node : Argument, CompilerState -> Try(SampledArguments, [CatalogFailed(Str), ..])
sample_minimum_node = |argument, state| {
	prefix = if argument.token.is_empty() [] else [argument.token.to_utf8()]
	if argument.type == "pure-token" {
		if argument.token.is_empty() Err(CatalogFailed("pure token without token while minimally sampling ${state.command}")) else Ok({ arguments: [argument.token.to_utf8()], state })
	} else if is_scalar_type(argument.type) {
		sampled = sample_scalar(argument, state)
		Ok({ arguments: prefix.append(sampled.sample), state: sampled.state })
	} else if argument.type == "block" {
		sampled = sample_minimum_required_nodes(argument.arguments, state)?
		Ok({ arguments: prefix.concat(sampled.arguments), state: sampled.state })
	} else if argument.type == "oneof" {
		alternative = minimum_alternative(argument.arguments, state.command)?
		sampled = sample_minimum_node(alternative, state)?
		Ok({ arguments: prefix.concat(sampled.arguments), state: sampled.state })
	} else {
		Err(CatalogFailed("unsupported minimal sample argument type ${Str.inspect(argument.type)} in ${state.command}"))
	}
}

sample_minimum_required_nodes : List(Argument), CompilerState -> Try(SampledArguments, [CatalogFailed(Str), ..])
sample_minimum_required_nodes = |arguments, state|
	match arguments {
		[] => Ok({ arguments: [], state })
		[first, .. as rest] if is_optional(first) => sample_minimum_required_nodes(rest, state)
		[first, .. as rest] => {
			sampled = sample_minimum_node(first, state)?
			following = sample_minimum_required_nodes(rest, sampled.state)?
			Ok({ arguments: sampled.arguments.concat(following.arguments), state: following.state })
		}
	}

sample_required_nodes : List(Argument), CompilerState -> Try(SampledArguments, [CatalogFailed(Str), ..])
sample_required_nodes = |arguments, state|
	match arguments {
		[] => Ok({ arguments: [], state })
		[first, .. as rest] if is_optional(first) => sample_required_nodes(rest, state)
		[first, .. as rest] => {
			sampled = sample_node(first, state)?
			following = sample_required_nodes(rest, sampled.state)?
			Ok({ arguments: sampled.arguments.concat(following.arguments), state: following.state })
		}
	}

pluralize : Str -> Str
pluralize = |name|
	if name == "index" {
		"indices"
	} else if name.ends_with("y") and !(["ay", "ey", "oy"].any(|suffix| name.ends_with(suffix))) {
		"${name.drop_suffix("y")}ies"
	} else if name.ends_with("s") {
		"${name}_list"
	} else {
		"${name}s"
	}

repeated_names : Str -> { item : Str, collection : Str }
repeated_names = |name| {
	item = identifier(name)
	if item == "data" {
		{ item: "entry", collection: "entries" }
	} else if item == "streams" {
		{ item: "stream", collection: "streams" }
	} else if item == "slots" {
		{ item: "slot_range", collection: "slot_ranges" }
	} else {
		{ item, collection: pluralize(item) }
	}
}

unique_field_names : List(Str) -> List(Str)
unique_field_names = |names| unique_field_names_help(names, [], []).names

unique_field_names_help : List(Str), List(Str), List(Str) -> { names : List(Str), used : List(Str) }
unique_field_names_help = |remaining, reversed, used|
	match remaining {
		[] => { names: reversed.fold([], |result, name| result.prepend(name)), used }
		[first, .. as rest] => {
			base = identifier(first)
			name = unused_name(base, 2, used)
			unique_field_names_help(rest, reversed.prepend(name), used.append(name))
		}
	}

concat_expressions : List(Str) -> Str
concat_expressions = |expressions| {
	# Keep the pending segment separate from the completed list. Reading last()
	# and replacing that same list triggers pinned-compiler heap corruption;
	# see roc-bugs/generator-list-coalescing.
	var $completed = []
	var $pending = ""
	for expression in expressions {
		if $pending.is_empty() {
			$pending = expression
		} else {
			match (simple_list_elements($pending), simple_list_elements(expression)) {
				(Ok(left), Ok(right)) => {
					separator = if left.is_empty() or right.is_empty() "" else ", "
					$pending = "[${left}${separator}${right}]"
				}
				_ => {
					$completed = $completed.append($pending)
					$pending = expression
				}
			}
		}
	}
	segments = if $pending.is_empty() $completed else $completed.append($pending)
	match segments {
		[] => "[]"
		[first, .. as rest] => rest.fold(first, |result, expression| "${result}.concat(${expression})")
	}
}

## Only combine lists of bare generated variable names. This is not a Roc
## expression parser: tokens, nested lists, calls, and arbitrary grammar
## expressions keep their original rendering and evaluation order.
simple_list_elements : Str -> Try(Str, [NotSimpleList])
simple_list_elements = |expression| {
	if !expression.starts_with("[") or !expression.ends_with("]") {
		return Err(NotSimpleList)
	}
	inner = expression.drop_prefix("[").drop_suffix("]")
	if inner.is_empty() {
		return Ok("")
	}
	for name in inner.split_on(", ") {
		bytes = name.to_utf8()
		first = bytes.first() ?? 0
		if !((first >= 'a' and first <= 'z') or first == '_') {
			return Err(NotSimpleList)
		}
		if !bytes.all(|byte| (byte >= 'a' and byte <= 'z') or (byte >= '0' and byte <= '9') or byte == '_') {
			return Err(NotSimpleList)
		}
	}
	Ok(inner)
}

expect concat_expressions(["[key]", "[value]"]) == "[key, value]"
expect concat_expressions(["[key]", "options", "[value]", "[count]"]) == "[key].concat(options).concat([value, count])"
expect concat_expressions(["[]", "[key]"]) == "[key]"
expect concat_expressions(["[key]", "[value].map(f)"]) == "[key].concat([value].map(f))"
expect simple_list_elements("[['X']]").is_err()
expect simple_list_elements("[key].concat([value])").is_err()

bytes_expression : List(U8) -> Str
bytes_expression = |value| "[${Str.join_with(value.map(byte_expression), ", ")}]"

byte_expression : U8 -> Str
byte_expression = |byte|
	match byte {
		'\r' => "'\\r'"
		'\n' => "'\\n'"
		'\t' => "'\\t'"
		39 => "'\\''"
		92 => "'\\\\'"
		_ if byte >= 32 and byte <= 126 => "'${Str.from_utf8([byte]) ?? ""}'"
		_ => byte.to_str()
	}

record_expression : List(Str), List(List(U8)) -> Str
record_expression = |fields, values| {
	pairs = record_fields(fields, values)
	"{ ${Str.join_with(pairs, ", ")} }"
}

record_fields : List(Str), List(List(U8)) -> List(Str)
record_fields = |fields, values|
	match (fields, values) {
		([], []) => []
		([field, .. as field_rest], [value, .. as value_rest]) => record_fields(field_rest, value_rest).prepend("${field}: ${bytes_expression(value)}")
		_ => []
	}

nonempty_arguments_expression : List(List(U8)) -> Try(Str, [CatalogFailed(Str), ..])
nonempty_arguments_expression = |arguments|
	match arguments {
		[] => Err(CatalogFailed("nonempty arguments cannot be empty"))
		[first, .. as rest] => Ok("{ first: ${bytes_expression(first)}, rest: [${Str.join_with(rest.map(bytes_expression), ", ")}] }")
	}

resp_encode : List(List(U8)) -> List(U8)
resp_encode = |parts| "*${parts.len().to_str()}\r\n".to_utf8().concat(parts.join_map(resp_encode_bulk))

resp_encode_bulk : List(U8) -> List(U8)
resp_encode_bulk = |part| "$${part.len().to_str()}\r\n".to_utf8().concat(part).concat([13, 10])

split_wire_name : Str -> { command_name : List(U8), fixed_arguments : List(List(U8)) }
split_wire_name = |name| {
	pieces = name.with_ascii_uppercased().split_on("|")
	command_name = pieces.first() ?? ""
	{ command_name: command_name.to_utf8(), fixed_arguments: pieces.drop_first(1).map(Str.to_utf8) }
}

GeneratedFile : { path : Path.Path, contents : Str }

generate_files : Manifest -> Try(List(GeneratedFile), [CatalogFailed(Str), ..])
generate_files = |manifest| {
	validate_manifest(manifest)?
	included = manifest.entries.keep_if(|entry| entry.status == "included")
	generate_module_files(module_policies, included)
}

generate_module_files : List({ group : Str, module_name : Str, count : U64 }), List(Entry) -> Try(List(GeneratedFile), [CatalogFailed(Str), ..])
generate_module_files = |policies, included|
	match policies {
		[] => Ok([])
		[policy, .. as rest] => {
			entries = included.keep_if(|entry| entry.module_name == policy.module_name).sort_with(|left, right| str_order(left.command, right.command))
			contents = render_module(policy.group, policy.module_name, entries)?
			following = generate_module_files(rest, included)?
			Ok(following.prepend({ path: Path.utf8("package/${policy.module_name}.roc"), contents }))
		}
	}

render_module : Str, Str, List(Entry) -> Try(Str, [CatalogFailed(Str), ..])
render_module = |group, module_name, entries| {
	constructor_names = entries.map(|entry| entry.constructor)
	rendered = entries.map_try(|entry| render_function_with_reserved(entry, constructor_names))?
	functions = rendered.map(|item| item.function)
	tests = rendered.join_map(|item| item.tests)
	title = if module_name == "VectorSets" "Vector Set" else group_title(group)
	Ok(
		"import Command\n\n"
			.concat("## GENERATED FILE: do not edit directly; regenerate with `scripts/command-catalog.roc generate`.\n")
			.concat("## Binary-safe Redis OSS ${redis_version} ${title} command constructors.\n")
			.concat("##\n")
			.concat("## Scalar wire arguments are `List(U8)`. Required variadic arguments use\n")
			.concat("## a first value plus a remaining list, so an empty required collection is\n")
			.concat("## unrepresentable. Count prefixes are derived automatically. Parameters\n")
			.concat("## beginning with `options` are deliberately raw token lists for grammars whose\n")
			.concat("## combinations Redis validates; they are inserted verbatim and may be empty.\n")
			.concat("## A `{ first, rest }` record is a non-empty raw token sequence for a required\n")
			.concat("## grammar choice; Redis validates the sequence when it executes the command.\n")
			.concat(module_scope_notice(group))
			.concat("${module_name} := {}.{\n")
			.concat(Str.join_with(functions, "\n\n"))
			.concat("\n}\n\n")
			.concat(Str.join_with(tests, "\n\n"))
			.concat("\n"),
	)
}

module_scope_notice : Str -> Str
module_scope_notice = |group|
	match group {
		"cluster" => "## Cluster constructors encode wire commands only. Slot routing, node selection,\n## and MOVED/ASK handling remain application responsibilities.\n"
		"connection" => "## Commands that change protocol, suppress replies, or close the socket are\n## encoding-only here; `Execute.request!` assumes one RESP2 reply and a reusable connection.\n"
		"pubsub" => "## Subscription-changing commands are encoding-only here. `Execute.request!` and\n## `Execute.batch!` cannot manage RESP2 subscription streams or unsolicited messages.\n"
		"server" => "## `MONITOR` and commands that close the server or connection are encoding-only\n## here and require application-specific transport lifecycle handling.\n"
		"transactions" => "## A transaction sequence must remain ordered on one exclusive connection.\n## `Execute.batch!` batches writes but does not by itself create a transaction.\n"
		_ => ""
	}

group_title : Str -> Str
group_title = |group|
	match group {
		"generic" => "Generic"
		"string" => "String"
		"hash" => "Hash"
		"list" => "List"
		"set" => "Set"
		"sorted-set" => "Sorted Set"
		"stream" => "Stream"
		"bitmap" => "Bitmap"
		"hyperloglog" => "Hyperloglog"
		"geo" => "Geo"
		"array" => "Array"
		"cluster" => "Cluster"
		"connection" => "Connect"
		"pubsub" => "Pub/Sub"
		"scripting" => "Scripting"
		"server" => "Server"
		"transactions" => "Transaction"
		_ => group
	}

render_function : Entry -> Try({ function : Str, tests : List(Str) }, [CatalogFailed(Str), ..])
render_function = |entry| render_function_with_reserved(entry, [])

render_function_with_reserved : Entry, List(Str) -> Try({ function : Str, tests : List(Str) }, [CatalogFailed(Str), ..])
render_function_with_reserved = |entry, reserved_names| {
	initial_state = { command: entry.command, used_names: reserved_names, sample_counter: 1 }
	compiled = compile_nodes(entry_constructor_arguments(entry), initial_state)?
	parameters = compiled.segments.join_map(|segment| segment.parameters)
	statements = compiled.segments.join_map(|segment| segment.statements)
	expressions = compiled.segments.map(|segment| segment.expression).keep_if(|expression| expression != "[]")
	samples = compiled.segments.join_map(|segment| segment.sample_arguments)
	minimal_samples = compiled.segments.join_map(|segment| segment.minimal_sample_arguments)
	arguments_expression = concat_expressions(expressions)
	wire = split_wire_name(entry.command)
	if wire.command_name.is_empty() {
		return Err(CatalogFailed("empty command name for ${entry.command}"))
	}
	command_name = Str.from_utf8(wire.command_name) ? |_| CatalogFailed("non-UTF-8 command name for ${entry.command}")
	fixed_expression = if wire.fixed_arguments.is_empty() "[]" else "[${Str.join_with(wire.fixed_arguments.map(bytes_expression), ", ")}]"
	full_arguments = concat_expressions([fixed_expression, arguments_expression].keep_if(|expression| expression != "[]"))
	signature = if parameters.is_empty() "{}" else Str.join_with(parameters.map(|parameter| parameter.roc_type), ", ")
	closure = if parameters.is_empty() "|_|" else "|${Str.join_with(parameters.map(|parameter| parameter.name), ", ")}|"
	lines = function_doc_lines(entry, parameters)
		.concat([
			"\t${entry.constructor} : ${signature} -> Command.Command",
			"\t${entry.constructor} = ${closure} {",
		])
		.concat(statements.map(|statement| "\t\t${statement}"))
		.concat([
			"\t\tCommand.from_nonempty_bytes(${Str.inspect(command_name)}, ${full_arguments})",
			"\t}",
		])
	invocation = if parameters.is_empty() "{}" else Str.join_with(parameters.map(|parameter| parameter.sample), ", ")
	minimal_invocation = if parameters.is_empty() "{}" else Str.join_with(parameters.map(|parameter| parameter.minimal_sample), ", ")
	expected_parts = [wire.command_name].concat(wire.fixed_arguments).concat(samples)
	minimal_expected_parts = [wire.command_name].concat(wire.fixed_arguments).concat(minimal_samples)
	validate_sample_arity(entry, expected_parts.len())?
	validate_minimal_sample_arity(entry, minimal_expected_parts.len())?
	primary_test = "expect Command.encode(${entry.module_name}.${entry.constructor}(${invocation})) == ${bytes_expression(resp_encode(expected_parts))}"
	minimal_tests =
		if minimal_invocation == invocation and minimal_expected_parts == expected_parts {
			[]
		} else {
			["expect Command.encode(${entry.module_name}.${entry.constructor}(${minimal_invocation})) == ${bytes_expression(resp_encode(minimal_expected_parts))}"]
		}
	Ok({
		function: Str.join_with(lines, "\n"),
		tests: [primary_test].concat(minimal_tests).concat(render_vector_selector_tests(entry.command)),
	})
}

function_doc_lines : Entry, List(Parameter) -> List(Str)
function_doc_lines = |entry, parameters| {
	base = [
		"\t## Construct `${entry.command.with_ascii_uppercased().replace_each("|", " ")}`.",
		"\t## Available since Redis ${entry.since}.",
		"\t## [Official Redis command documentation](${command_docs_url(entry.command)}).",
	]
	with_parameters =
		if parameters.is_empty() {
			base
		} else {
			names = Str.join_with(parameters.map(|parameter| "`${parameter.name}`"), ", ")
			base.append("\t## Parameters (in order): ${names}.")
		}
	with_vectors =
		if entry.command == "vadd" {
			with_parameters.append("\t## `input` is `Fp32(blob)` or `Values({ first, rest })`; the non-empty VALUES count is derived automatically.")
		} else if entry.command == "vsim" {
			with_parameters.append("\t## `query` is `Element(element)`, `Fp32(blob)`, or `Values({ first, rest })`; the non-empty VALUES count is derived automatically.")
		} else {
			with_parameters
		}
	with_deprecation =
		if entry.doc_flags.any(|flag| flag.with_ascii_lowercased() == "deprecated") {
			with_vectors.append("\t## Deprecated by Redis; retained for catalog completeness.")
		} else {
			with_vectors
		}
	if parameters.any(|parameter| parameter.name.starts_with("options")) {
		with_deprecation.append("\t## Parameters beginning with `options` are unvalidated wire arguments in the documented syntax position.")
	} else {
		with_deprecation
	}
}

command_docs_url : Str -> Str
command_docs_url = |name| "https://redis.io/docs/latest/commands/${name.replace_each("|", "-")}/"

validate_sample_arity : Entry, U64 -> Try({}, [CatalogFailed(Str), ..])
validate_sample_arity = |entry, actual| {
	if entry.arity > 0 and actual != I64.to_u64_wrap(entry.arity) {
		Err(CatalogFailed("generated sample arity for ${entry.command} is ${actual.to_str()}, expected exactly ${entry.arity.to_str()}"))
	} else if entry.arity < 0 and actual < I64.to_u64_wrap(-entry.arity) {
		Err(CatalogFailed("generated sample arity for ${entry.command} is ${actual.to_str()}, expected at least ${(-entry.arity).to_str()}"))
	} else {
		Ok({})
	}
}

validate_minimal_sample_arity : Entry, U64 -> Try({}, [CatalogFailed(Str), ..])
validate_minimal_sample_arity = |entry, actual| {
	expected = if entry.arity < 0 I64.to_u64_wrap(-entry.arity) else I64.to_u64_wrap(entry.arity)
	if actual == expected {
		Ok({})
	} else {
		Err(CatalogFailed("generated minimal sample arity for ${entry.command} is ${actual.to_str()}, expected exactly ${expected.to_str()}"))
	}
}

render_vector_selector_tests : Str -> List(Str)
render_vector_selector_tests = |command| {
	key = [0, 240, 255]
	blob = [0, 1, 2, 3, 255]
	values = ["1.25".to_utf8(), "-2.5".to_utf8()]
	values_expression = "Values({ first: ${bytes_expression(values.get(0) ?? [])}, rest: [${bytes_expression(values.get(1) ?? [])}] })"
	if command == "vadd" {
		element = [0, 241, 255]
		invocation = "VectorSets.vadd(${bytes_expression(key)}, [], ${values_expression}, ${bytes_expression(element)}, [])"
		expected = resp_encode(["VADD".to_utf8(), key, "VALUES".to_utf8(), "2".to_utf8()].concat(values).append(element))
		["expect Command.encode(${invocation}) == ${bytes_expression(expected)}"]
	} else if command == "vsim" {
		fp32_invocation = "VectorSets.vsim(${bytes_expression(key)}, Fp32(${bytes_expression(blob)}), [])"
		fp32_expected = resp_encode(["VSIM".to_utf8(), key, "FP32".to_utf8(), blob])
		values_invocation = "VectorSets.vsim(${bytes_expression(key)}, ${values_expression}, [])"
		values_expected = resp_encode(["VSIM".to_utf8(), key, "VALUES".to_utf8(), "2".to_utf8()].concat(values))
		[
			"expect Command.encode(${fp32_invocation}) == ${bytes_expression(fp32_expected)}",
			"expect Command.encode(${values_invocation}) == ${bytes_expression(values_expected)}",
		]
	} else {
		[]
	}
}

format_generated_files! : List(GeneratedFile) => Try(List(GeneratedFile), [CatalogFailed(Str), ..])
format_generated_files! = |files| {
	timeout_program = find_timeout_program!({})?
	temp_dir = create_catalog_temp_dir!(8)?
	format_result = format_files_in_dir!(files, temp_dir, timeout_program, 0)
	cleanup_result = temp_dir.delete_all!().map_err(|error| CatalogFailed("remove formatter temporary directory ${temp_dir.display()}: ${Str.inspect(error)}"))
	combine_value_and_cleanup(format_result, cleanup_result)
}

find_timeout_program! : {} => Try(Str, [CatalogFailed(Str), ..])
find_timeout_program! = |_| {
	if Cmd.check_available!("timeout") {
		Ok("timeout")
	} else if Cmd.check_available!("gtimeout") {
		Ok("gtimeout")
	} else {
		Err(CatalogFailed("GNU timeout is required; enter the Nix development shell or install coreutils"))
	}
}

create_catalog_temp_dir! : U8 => Try(Path.Path, [CatalogFailed(Str), ..])
create_catalog_temp_dir! = |attempts_remaining| {
	seed = Random.seed_u64!() ? |error| CatalogFailed("choose temporary directory name: ${Str.inspect(error)}")
	path = Env.temp_dir!().join("roc-redis-command-catalog-${seed.to_str()}")
	match path.create_dir!() {
		Ok({}) => Ok(path)
		Err(PathErr(AlreadyExists, _)) if attempts_remaining > 1 => create_catalog_temp_dir!(attempts_remaining - 1)
		Err(error) => Err(CatalogFailed("create temporary directory ${path.display()}: ${Str.inspect(error)}"))
	}
}

format_files_in_dir! : List(GeneratedFile), Path.Path, Str, U64 => Try(List(GeneratedFile), [CatalogFailed(Str), ..])
format_files_in_dir! = |files, temp_dir, timeout_program, index|
	match files {
		[] => Ok([])
		[first, .. as rest] => {
			input = temp_dir.join("input-${index.to_str()}.roc")
			output = temp_dir.join("output-${index.to_str()}.roc")
			input.write_utf8!(first.contents) ? |error| CatalogFailed("write formatter input: ${Str.inspect(error)}")
			outcome = run_bounded_output!(
				timeout_program,
				"sh",
				[
					"-c",
					"roc fmt --stdin < \"$1\" > \"$2\"",
					"roc-command-catalog-format",
					input.display(),
					output.display(),
				],
			)?
			if outcome.exit_code != 0 {
				Err(CatalogFailed("roc fmt --stdin failed for ${first.path.display()} with exit ${outcome.exit_code.to_str()}: ${bounded_output(outcome)}"))
			} else {
				contents = output.read_utf8!() ? |error| CatalogFailed("read formatted ${first.path.display()}: ${Str.inspect(error)}")
				following = format_files_in_dir!(rest, temp_dir, timeout_program, index + 1)?
				Ok(following.prepend({ ..first, contents }))
			}
		}
	}

write_generated_files! : List(GeneratedFile) => Try({}, [CatalogFailed(Str), ..])
write_generated_files! = |files| {
	seed = Random.seed_u64!() ? |error| CatalogFailed("choose atomic-write name: ${Str.inspect(error)}")
	write_generated_files_help!(files, seed, 0)
}

write_generated_files_help! : List(GeneratedFile), U64, U64 => Try({}, [CatalogFailed(Str), ..])
write_generated_files_help! = |files, seed, index|
	match files {
		[] => Ok({})
		[first, .. as rest] => {
			temporary = Path.utf8("${first.path.display()}.catalog-${seed.to_str()}-${index.to_str()}.tmp")
			write_result = temporary.write_utf8!(first.contents).map_err(|error| CatalogFailed("write temporary ${temporary.display()}: ${Str.inspect(error)}"))
			match write_result {
				Err(error) => Err(error)
				Ok({}) =>
					match temporary.rename!(first.path) {
						Ok({}) => write_generated_files_help!(rest, seed, index + 1)
						Err(error) => {
							cleanup = delete_if_present!(temporary)
							rename_error = CatalogFailed("atomically replace ${first.path.display()}: ${Str.inspect(error)}")
							match cleanup {
								Ok({}) => Err(rename_error)
								Err(CatalogFailed(cleanup_message)) => Err(CatalogFailed("${describe_catalog_error(rename_error)}; ${cleanup_message}"))
							}
						}
					}
				}
		}
	}

## Typed modules are hand-written semantic APIs. Account for every included
## wire command independently of the generated raw-constructor count. This
## manifest records sender families; type checks and reply tests remain needed.
typed_catalog_file! : Manifest => Try(GeneratedFile, [CatalogFailed(Str), ..])
typed_catalog_file! = |manifest| {
	namespace = Path.utf8("package/Commands.roc").read_utf8!() ? |error| CatalogFailed("read command namespace: ${Str.inspect(error)}")
	var $lines = ["command\tapi\tsender"]
	for policy in module_policies {
		if !namespace.contains("\t${policy.module_name} :") {
			return Err(CatalogFailed("Commands namespace omits ${policy.module_name}"))
		}
		path = Path.utf8("package/Commands/${policy.module_name}.roc")
		source = path.read_utf8!() ? |error| CatalogFailed("read ${path.display()}: ${Str.inspect(error)}")
		signatures = source.split_on("\n").keep_if(|line| line.starts_with("\t") and !line.starts_with("\t\t") and line.contains(" : "))
		for entry in manifest.entries.keep_if(|entry| entry.status == "included" and entry.module_name == policy.module_name) {
			target = typed_normalized_name(
				if entry.command == "type" {
					"key_type"
				} else {
					entry.command.drop_prefix("cluster|")
				},
			)
			matches = signatures.keep_if(
				|line| match line.trim().split_first(" : ") {
					Ok(parts) => typed_normalized_name(parts.before) == target
					Err(_) => False
				},
			)
			match matches {
				[line] => {
					parts = line.trim().split_first(" : ") ? |_| CatalogFailed("invalid signature for ${entry.command}")
					sender = if parts.after.ends_with("-> Command.Command") {
						"encoding-only"
					} else if parts.after.contains("-> Request.Request(") {
						if parts.after.contains("Resp.Resp -> Try(value, error)") {
							"request/custom-decoder"
						} else {
							"request/typed-decoder"
						}
					} else {
						return Err(CatalogFailed("unclassified typed sender for ${entry.command}"))
					}
					$lines = $lines.append("${entry.command}\tCommands.${policy.module_name}.${parts.before}\t${sender}")
				}
				_ => return Err(CatalogFailed("expected exactly one typed API for ${entry.command}, found ${matches.len().to_str()}"))
			}
		}
	}
	Ok({ path: Path.utf8("metadata/typed-command-api.tsv"), contents: Str.join_with($lines, "\n").concat("\n") })
}

typed_normalized_name : Str -> Str
typed_normalized_name = |name| name.replace_each("_", "").replace_each("|", "").replace_each("-", "")

expect typed_normalized_name("client_get_redir") == typed_normalized_name("client|getredir")
expect typed_normalized_name("get_set") != typed_normalized_name("get")

check_generated_files! : List(GeneratedFile) => Try({}, [CatalogFailed(Str), ..])
check_generated_files! = |files| {
	mismatches = generated_mismatches!(files)
	if mismatches.is_empty() {
		Ok({})
	} else {
		Err(CatalogFailed("${Str.join_with(mismatches, "; ")}; run `roc scripts/command-catalog.roc -- generate`"))
	}
}

generated_mismatches! : List(GeneratedFile) => List(Str)
generated_mismatches! = |files|
	match files {
		[] => []
		[first, .. as rest] => {
			following = generated_mismatches!(rest)
			match first.path.read_utf8!() {
				Ok(actual) if actual == first.contents => following
				Ok(_) => following.prepend("stale ${first.path.display()}")
				Err(_) => following.prepend("missing or unreadable ${first.path.display()}")
			}
		}
	}

run_bounded_output! : Str, Str, List(Str) => Try({ exit_code : I32, stdout : Str, stderr : Str }, [CatalogFailed(Str), ..])
run_bounded_output! = |timeout_program, program, arguments|
	run_bounded_output_with_limit!(timeout_program, command_timeout, program, arguments)

run_bounded_output_with_limit! : Str, Str, Str, List(Str) => Try({ exit_code : I32, stdout : Str, stderr : Str }, [CatalogFailed(Str), ..])
run_bounded_output_with_limit! = |timeout_program, limit, program, arguments| {
	wrapped = ["--signal=TERM", "--kill-after=2s", limit, program].concat(arguments)
	match Cmd.new_str(timeout_program).args_str(wrapped).exec_output!() {
		Ok({ stdout_utf8, stderr_utf8_lossy }) => Ok({ exit_code: 0, stdout: stdout_utf8, stderr: stderr_utf8_lossy })
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) => {
			if exit_code == 124 or exit_code == 137 {
				Err(CatalogFailed("${program} timed out after ${limit}: ${HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy)}"))
			} else if exit_code == 125 or exit_code == 126 or exit_code == 127 {
				Err(CatalogFailed("GNU timeout could not invoke ${program}: ${HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy)}"))
			} else {
				Ok({ exit_code, stdout: stdout_utf8_lossy, stderr: stderr_utf8_lossy })
			}
		}
		Err(error) => Err(CatalogFailed("execute ${program}: ${Str.inspect(error)}"))
	}
}

redis_command_with_limit! : Str, Str, Str, List(Str), List(Str), Bool => Try(Str, [CatalogFailed(Str), ..])
redis_command_with_limit! = |timeout_program, limit, redis_cli, connection, arguments, json_output| {
	json_arguments = if json_output ["--json"] else []
	all_arguments = connection.concat(json_arguments).concat(arguments)
	outcome = run_bounded_output_with_limit!(timeout_program, limit, redis_cli, all_arguments)?
	if outcome.exit_code == 0 {
		Ok(outcome.stdout.trim())
	} else {
		Err(CatalogFailed("${Str.join_with(arguments, " ")} failed with exit ${outcome.exit_code.to_str()}: ${bounded_output(outcome)}"))
	}
}

bounded_output : { exit_code : I32, stdout : Str, stderr : Str } -> Str
bounded_output = |outcome| HarnessText.combine_output(outcome.stdout, outcome.stderr).trim()

delete_if_present! : Path.Path => Try({}, [CatalogFailed(Str), ..])
delete_if_present! = |path| {
	exists = path.exists!() ? |error| CatalogFailed("inspect ${path.display()}: ${Str.inspect(error)}")
	if exists path.delete!().map_err(|error| CatalogFailed("delete ${path.display()}: ${Str.inspect(error)}")) else Ok({})
}

combine_value_and_cleanup : Try(a, [CatalogFailed(Str), ..]), Try({}, [CatalogFailed(Str), ..]) -> Try(a, [CatalogFailed(Str), ..])
combine_value_and_cleanup = |value_result, cleanup_result|
	match (value_result, cleanup_result) {
		(Ok(value), Ok({})) => Ok(value)
		(Err(error), Ok({})) => Err(CatalogFailed(describe_catalog_error(error)))
		(Ok(_), Err(error)) => Err(CatalogFailed(describe_catalog_error(error)))
		(Err(error), Err(cleanup_error)) => Err(CatalogFailed("${describe_catalog_error(error)}; ${describe_catalog_error(cleanup_error)}"))
	}

describe_catalog_error : [CatalogFailed(Str), ..] -> Str
describe_catalog_error = |error|
	match error {
		CatalogFailed(message) => message
		_ => Str.inspect(error)
	}

reserved_identifiers : List(Str)
reserved_identifiers = ["as", "else", "expect", "if", "implements", "import", "is", "match", "module", "package", "platform", "provides", "requires", "type", "where", "with"]

constructor_name : Str -> Str
constructor_name = |command| identifier(command.replace_each("|", "_"))

identifier : Str -> Str
identifier = |name| {
	normalized_bytes = identifier_bytes(name.to_utf8(), [], Bool.False)
	trimmed =
		match normalized_bytes.last() {
			Ok(95) => normalized_bytes.drop_last(1)
			_ => normalized_bytes
		}
	nonempty = if trimmed.is_empty() "argument" else Str.from_utf8_lossy(trimmed)
	with_prefix =
		match nonempty.to_utf8().first() {
			Ok(byte) if byte >= 48 and byte <= 57 => "arg_${nonempty}"
			_ => nonempty
		}
	if reserved_identifiers.contains(with_prefix) "${with_prefix}_" else with_prefix
}

identifier_bytes : List(U8), List(U8), Bool -> List(U8)
identifier_bytes = |remaining, output, separator_pending|
	match remaining {
		[] => output
		[byte, .. as rest] => {
			is_upper = byte >= 65 and byte <= 90
			is_lower = byte >= 97 and byte <= 122
			is_digit = byte >= 48 and byte <= 57
			if is_upper or is_lower or is_digit {
				with_separator = if separator_pending and !(output.is_empty()) output.append(95) else output
				lowered : U8
				lowered = if is_upper byte + 32 else byte
				identifier_bytes(rest, with_separator.append(lowered), Bool.False)
			} else {
				identifier_bytes(rest, output, Bool.True)
			}
		}
	}

expect parse_port("1") == Ok(1)
expect parse_port("65535") == Ok(65535)
expect ["", "0", "+1", "0x10", "1_0", "65536"].all(|text| parse_port(text).is_err())
expect identifier("BUILD-EXPLORATION.factor") == "build_exploration_factor"
expect identifier("123") == "arg_123"
expect identifier("type") == "type_"

expect {
	parsed = parse_cli(["check", "--live", "--redis-cli", "/bin/redis-cli", "--redis-server", "/bin/redis-server"])?
	parsed.action == Check and parsed.live and parsed.redis_cli == "/bin/redis-cli" and parsed.redis_server == "/bin/redis-server"
}

expect {
	parsed = parse_cli(["snapshot", "--socket", "/tmp/example.sock"])?
	parsed.action == Snapshot and parsed.?socket == Ok("/tmp/example.sock") and parsed.?port.is_err()
}

expect [
	["generate", "--live"],
	["generate", "--redis-cli", "custom"],
	["check", "--live", "--port", "6379"],
	["snapshot", "--socket", "/tmp/a", "--port", "6379"],
	["check", "--port", "+1"],
].all(|arguments| parse_cli(arguments).is_err())

expect parse_signed_decimal("-12") == Ok(-12) and parse_signed_decimal("42") == Ok(42)
expect ["", "-", "+1", "1_0", "0x10"].all(|text| parse_signed_decimal(text).is_err())
expect parse_pid_output("42\n") == Ok("42")
expect ["", "0", "1", "+2", "2\n3\n"].all(|text| parse_pid_output(text).is_err())

expect ["", "12x", "123\n"].map(startup_pid_state) == [PendingPid, InvalidPid("expected one positive process ID, received \"12x\""), ReadyPid("123")]

expect first_ready_startup_pid(["", "12x", "123\n"]) == Ok("123")

expect startup_pid_state("123") == InvalidPid("temporary Redis pidfile was not newline-terminated")

expect signal_decision(Bool.False, Bool.False) == AlreadyExited
expect signal_decision(Bool.True, Bool.False) == RefuseUnowned
expect signal_decision(Bool.True, Bool.True) == SignalOwned

## The watcher is installed before Redis launch, accepts an explicit monitored
## PID for the forced startup-window test, waits for the later pidfile, and
## establishes exact INFO process_id ownership before both TERM and KILL.
expect watchdog_wrapper_script.contains("$MONITORED_PID") and watchdog_wrapper_script.contains("HARNESS_PID=$PPID")
expect watchdog_launch_script.contains("$CLEANUP_REQUEST") and watchdog_launch_script.contains("context_is_owned")
expect watchdog_launch_script.contains("limit=300") and watchdog_launch_script.contains("IFS= read -r child")
expect watchdog_launch_script.split_on("redis_is_owner \"$child\"").len() == 4
expect watchdog_launch_script.contains("preserve=1") and watchdog_launch_script.contains("&& redis_endpoint_absent; then preserve=0")
expect !(watchdog_launch_script.contains("preserve=0; if safe_pid"))
expect watchdog_launch_script.contains("printf 'pending\\n' >\"$PENDING_ACK\"")

expect {
	info = "# Server\r\nredis_version:8.10.1\r\nprocess_id:42\r\n"
	HarnessText.redis_info_field(info, "redis_version") == Ok("8.10.1")
		and HarnessText.redis_info_field(info, "process_id") == Ok("42")
			and HarnessText.redis_info_field(info, "missing").is_err()
}

expect ["z", "aa", "a", "é"].sort_with(str_order) == ["a", "aa", "z", "é"]
expect list_difference(["a", "b", "c"], ["b", "d"]) == ["a", "c"]
expect repeated_names("index") == { item: "index", collection: "indices" }
expect repeated_names("data") == { item: "entry", collection: "entries" }
expect repeated_names("streams") == { item: "stream", collection: "streams" }
expect repeated_names("slots") == { item: "slot_range", collection: "slot_ranges" }

expect {
	allocated = allocate_name("client_id", { command: "client|unblock", used_names: ["client_id"], sample_counter: 1 })
	allocated.name == "client_id_2" and allocated.state.used_names == ["client_id", "client_id_2"]
}

expect {
	wire = resp_encode(["GET".to_utf8(), [0, 13, 10, 255]])
	wire == "*2\r\n$3\r\nGET\r\n$4\r\n".to_utf8().concat([0, 13, 10, 255, 13, 10])
}

expect {
	argument = Argument.{ name: "key", type: "key", token: "", flags: [], arguments: [] }
	entry : Entry
	entry = {
		command: "get",
		group: "string",
		arity: 2,
		since: "1.0.0",
		arguments: [argument],
		module_name: "Strings",
		constructor: "get",
		doc_flags: [],
		constructor_arguments: Original,
		status: "included",
		reason: "",
	}
	rendered = render_function(entry)?
	rendered.function.contains("get : List(U8) -> Command.Command")
		and rendered.tests.len() == 1
			and (rendered.tests.first() ?? "") == "expect Command.encode(Strings.get([0, 1, 255])) == ['*', '2', '\\r', '\\n', '$', '3', '\\r', '\\n', 'G', 'E', 'T', '\\r', '\\n', '$', '3', '\\r', '\\n', 0, 1, 255, '\\r', '\\n']"
				and validate_sample_arity(entry, 1).is_err()
}

expect {
	following = Argument.{ name: "entries", type: "string", token: "", flags: ["multiple"], arguments: [] }
	compiled = compile_raw_options(Following(following), initial_compiler_state("sample"))?
	parameter = compiled.segment.parameters.first()?
	parameter.name == "options_before_entries"
		and parameter.roc_type == "List(List(U8))"
			and parameter.sample == "[[0, 1, 255], [0, 2, 255]]"
				and parameter.minimal_sample == "[]"
					and compiled.segment.expression == "options_before_entries"
						and compiled.segment.sample_arguments == [[0, 1, 255], [0, 2, 255]]
							and compiled.segment.minimal_sample_arguments == []
								and compiled.state.sample_counter == 3
}

expect {
	argument = Argument.{ name: "item", type: "string", token: "", flags: ["optional", "multiple"], arguments: [] }
	compiled = compile_optional_multiple(argument, initial_compiler_state("sample"))?
	parameter = compiled.segment.parameters.first()?
	parameter.name == "items"
		and parameter.roc_type == "List(List(U8))"
			and parameter.sample == "[[0, 1, 255], [0, 2, 255]]"
				and parameter.minimal_sample == "[]"
					and compiled.segment.expression == "items"
						and compiled.segment.sample_arguments == [[0, 1, 255], [0, 2, 255]]
							and compiled.segment.minimal_sample_arguments == []
								and compiled.state.sample_counter == 3
}

expect {
	count = Argument.{ name: "numkeys", type: "integer", token: "", flags: [], arguments: [] }
	keys = Argument.{ name: "key", type: "key", token: "", flags: ["optional", "multiple"], arguments: [] }
	compiled = compile_counted_optional_multiple(count, keys, "", initial_compiler_state("eval"))?
	parameter = compiled.segment.parameters.first()?
	parameter.name == "keys"
		and parameter.minimal_sample == "[]"
			and compiled.segment.expression == "[keys.len().to_str().to_utf8()].concat(keys)"
				and compiled.segment.minimal_sample_arguments == ["0".to_utf8()]
}

expect {
	entry : Entry
	entry = {
		command: "variadic",
		group: "string",
		arity: -2,
		since: "1.0.0",
		arguments: [],
		module_name: "Strings",
		constructor: "variadic",
		doc_flags: [],
		constructor_arguments: Original,
		status: "included",
		reason: "",
	}
	validate_minimal_sample_arity(entry, 2) == Ok({})
		and validate_minimal_sample_arity(entry, 3).is_err()
			and validate_minimal_sample_arity(entry, 1).is_err()
}

expect {
	vector = vector_input_choice("input", Bool.False)
	compiled = compile_oneof(vector, initial_compiler_state("vadd"))?
	parameter = compiled.segment.parameters.first()?
	parameter.roc_type == "[Fp32(List(U8)), Values({ first : List(U8), rest : List(List(U8)) })]"
		and compiled.segment.sample_arguments == ["FP32".to_utf8(), [0, 1, 255]]
}

expect {
	manifest : Manifest
	manifest = {
		redis_version: "8.10.1",
		provenance: {
			contract: ["COMMAND \"LIST\""],
			description: "line\ncafé",
			scoped_command_count: 0,
			module_group_commands: [],
			constructor_argument_overrides: [],
		},
		scope_groups: [],
		entries: [],
	}
	encoded = encode_manifest(manifest)
	expected = "{\n  \"redis_version\": \"8.10.1\",\n  \"provenance\": {\n    \"contract\": [\n      \"COMMAND \\\"LIST\\\"\"\n    ],\n    \"description\": \"line\\ncafé\",\n    \"scoped_command_count\": 0,\n    \"module_group_commands\": [],\n    \"constructor_argument_overrides\": []\n  },\n  \"scope_groups\": [],\n  \"entries\": []\n}\n"
	parsed_result : Try(RawManifest, _)
	parsed_result = Json.parse(manifest_json_for_roc(encoded))
	raw = parsed_result?
	round_trip = manifest_from_raw(raw)?
	encoded == expected and encode_manifest(round_trip) == encoded
}

expect manifest_json_for_roc("{\"command\":\"module\",\"module\":\"Keyspace\"}") == "{\"command\":\"module\",\"module_name\":\"Keyspace\"}"
expect docs_json_for_roc("{\"module\":{\"group\":\"server\"},\"vadd\":{\"module\":\"vectorset\"}}") == "{\"module\":{\"group\":\"server\"},\"vadd\":{\"module_name\":\"vectorset\"}}"
expect unwrap_single_doc_json("get", "{\"get\":{\"group\":\"string\"}}") == Ok("{\"group\":\"string\"}")
expect unwrap_single_doc_json("vadd", "{\"VADD\":{\"group\":\"module\"}}") == Ok("{\"group\":\"module\"}")
expect ["{}", "{\"set\":{}}", "{ \"get\":{} }", "{\"get\":}"].all(|json| unwrap_single_doc_json("get", json).is_err())
