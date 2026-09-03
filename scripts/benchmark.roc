## Run Roc, redis-py, go-redis, redis-rs, and hiredis subjects against one isolated
## Redis server. The subjects own workload timing; this Roc program owns
## orchestration, validation, aggregation, and process cleanup.
##
## The established small, fixed shell bridge still supplies parent-death
## supervision for the daemonized
## Redis child. Runtime values cross that boundary only through environment
## variables.
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

Config : {
	iterations : U64,
	warmup : U64,
	samples : U64,
	pipeline_batch : U64,
	timeout_ms : U64,
	order_rotation : U64,
	all_order_rotations : Bool,
	jsonl : [NoJsonl, Jsonl(Str)],
}

Subject : {
	label : Str,
	implementation : Str,
	expected_client_version : Str,
	executable : Str,
	leading_args : List(Str),
}

Provenance : {
	nix_source_id : Str,
	build_mode : Str,
	nix_system : Str,
	os : Str,
	arch : Str,
}

PlannedSubject : { subject : Subject, order_rotation : U64, subject_position : U64 }

BenchmarkRecord : {
	schema : Str,
	implementation : Str,
	client : Str,
	client_version : Str,
	runtime_version : Str,
	redis_version : Str,
	timer : Str,
	workload : Str,
	sample : U64,
	samples : U64,
	iterations : U64,
	warmup : U64,
	pipeline_batch : U64,
	operation_count : U64,
	command_count : U64,
	round_trip_count : U64,
	elapsed_ns : U64,
	validated : Bool,
	nix_source_id : Str,
	build_mode : Str,
	nix_system : Str,
	os : Str,
	arch : Str,
	order_rotation : U64,
	subject_position : U64,
}

SubjectRun : {
	label : Str,
	implementation : Str,
	raw_jsonl : Str,
	records : List(BenchmarkRecord),
}

ProcessOutput : { exit_code : I32, stdout : Str, stderr : Str }

schema : Str
schema = "roc-redis-benchmark/v2"

workloads : List(Str)
workloads = ["ping_sequential", "set_get_sequential", "incr_sequential", "ping_pipeline"]

default_config : Config
default_config = {
	iterations: 10_000,
	warmup: 1_000,
	samples: 5,
	pipeline_batch: 100,
	timeout_ms: 5_000,
	order_rotation: 0,
	all_order_rotations: Bool.False,
	jsonl: NoJsonl,
}

max_iterations : U64
max_iterations = 1_000_000_000

max_samples : U64
max_samples = 1_000

max_pipeline_batch : U64
max_pipeline_batch = 65_536

max_timeout_ms : U64
max_timeout_ms = 300_000

first_random_port : U16
first_random_port = 20_000

random_port_count : U64
random_port_count = 30_000

port_attempts : U8
port_attempts = 20

redis_readiness_attempts : U8
redis_readiness_attempts = 100

service_launch_timeout_seconds : Str
service_launch_timeout_seconds = "10s"

shell_launch_timeout_seconds : Str
shell_launch_timeout_seconds = "5s"

subject_timeout_seconds : Str
subject_timeout_seconds = "1800s"

probe_timeout_seconds : Str
probe_timeout_seconds = "2s"

usage : Str
usage = "usage: roc scripts/benchmark.roc -- [--iterations N] [--warmup N] [--samples N] [--pipeline-batch N] [--timeout-ms N] [--order-rotation 0..9 | --all-order-rotations] [--jsonl PATH]"

watchdog_launch_script : Str
watchdog_launch_script = Str.join_with(
	[
		"set -eu;",
		"case \"$TEST_DIR\" in \"$TEMP_ROOT\"/roc-redis-benchmark-*) ;;",
		"*) exit 1;;",
		"esac;",
		"owner=;",
		"IFS= read -r owner <\"$OWNER_FILE\" || owner=;",
		"[ \"$owner\" = \"$HARNESS_PID\" ];",
		"safe_pid() { case \"$1\" in ''|*[!0-9]*) return 1;;",
		"esac;",
		"[ \"$1\" -gt 1 ] 2>/dev/null;",
		"};",
		"stop_pid() { target=$1;",
		"if safe_pid \"$target\" && kill -0 \"$target\" 2>/dev/null;",
		"then kill -TERM \"$target\" 2>/dev/null || true;",
		"attempt=0;",
		"while kill -0 \"$target\" 2>/dev/null && [ \"$attempt\" -lt 40 ];",
		"do sleep 0.05;",
		"attempt=$((attempt + 1));",
		"done;",
		"if kill -0 \"$target\" 2>/dev/null;",
		"then kill -KILL \"$target\" 2>/dev/null || true;",
		"fi;",
		"fi;",
		"};",
		"stop_group() { leader=$1;",
		"if safe_pid \"$leader\";",
		"then kill -TERM \"$leader\" 2>/dev/null || true;",
		"kill -TERM -- \"-$leader\" 2>/dev/null || true;",
		"attempt=0;",
		"while kill -0 -- \"-$leader\" 2>/dev/null && [ \"$attempt\" -lt 40 ];",
		"do sleep 0.05;",
		"attempt=$((attempt + 1));",
		"done;",
		"if kill -0 \"$leader\" 2>/dev/null;",
		"then kill -KILL \"$leader\" 2>/dev/null || true;",
		"fi;",
		"if kill -0 -- \"-$leader\" 2>/dev/null;",
		"then kill -KILL -- \"-$leader\" 2>/dev/null || true;",
		"fi;",
		"fi;",
		"};",
		"redis_is_owner() { candidate=$1;",
		"safe_pid \"$candidate\" || return 1;",
		"info=$(\"$TIMEOUT_PROGRAM\" --signal=TERM --kill-after=1s 1s \"$REDIS_CLI\" --raw -t 0.5 -s \"$REDIS_SOCKET\" INFO server 2>/dev/null) || return 1;",
		"printf '%s\\n' \"$info\" | tr -d '\\r' | \"$GREP_PROGRAM\" -Fqx \"process_id:$candidate\";",
		"};",
		"(while kill -0 \"$HARNESS_PID\" 2>/dev/null;",
		"do sleep 0.1;",
		"done;",
		"attempt=0;",
		"while [ ! -s \"$SUBJECT_PIDFILE\" ] && [ \"$attempt\" -lt 10 ];",
		"do sleep 0.05;",
		"attempt=$((attempt + 1));",
		"done;",
		"supervisor=;",
		"if [ -r \"$SUBJECT_PIDFILE\" ];",
		"then IFS= read -r supervisor <\"$SUBJECT_PIDFILE\" || supervisor=;",
		"fi;",
		"stop_group \"$supervisor\";",
		"attempt=0;",
		"while [ ! -s \"$REDIS_PIDFILE\" ] && [ \"$attempt\" -lt 240 ];",
		"do sleep 0.05;",
		"attempt=$((attempt + 1));",
		"done;",
		"redis_pid=;",
		"if [ -r \"$REDIS_PIDFILE\" ];",
		"then IFS= read -r redis_pid <\"$REDIS_PIDFILE\" || redis_pid=;",
		"fi;",
		"owned=0;",
		"attempt=0;",
		"while safe_pid \"$redis_pid\" && kill -0 \"$redis_pid\" 2>/dev/null && [ \"$attempt\" -lt 12 ];",
		"do if redis_is_owner \"$redis_pid\";",
		"then owned=1;",
		"break;",
		"fi;",
		"sleep 0.05;",
		"attempt=$((attempt + 1));",
		"done;",
		"preserve=0;",
		"if safe_pid \"$redis_pid\" && kill -0 \"$redis_pid\" 2>/dev/null;",
		"then if [ \"$owned\" -eq 1 ];",
		"then stop_pid \"$redis_pid\";",
		"else preserve=1;",
		"fi;",
		"fi;",
		"if [ \"$preserve\" -eq 0 ];",
		"then rm -f -- \"$REDIS_PIDFILE\" \"$REDIS_SOCKET\" \"$TEST_DIR/redis.log\" \"$TEST_DIR/redis-watchdog.pid\" \"$SUBJECT_PIDFILE\" \"$OWNER_FILE\";",
		"rmdir -- \"$TEST_DIR\" 2>/dev/null || true;",
		"fi) </dev/null >/dev/null 2>&1 &",
		"watchdog=$!;",
		"printf '%s\\n' \"$watchdog\" >\"$WATCHDOG_PIDFILE\";",
		"printf '%s\\n' \"$watchdog\"",
	],
	" ",
)

watchdog_wrapper_script : Str
watchdog_wrapper_script = "set -eu; HARNESS_PID=$PPID; export HARNESS_PID; printf '%s\\n' \"$HARNESS_PID\" >\"$OWNER_FILE\"; exec \"$1\" --signal=TERM --kill-after=2s 5s sh -c \"$2\""

subject_wrapper_script : Str
subject_wrapper_script = "set -eu; printf '%s\\n' \"$PPID\" >\"$SUBJECT_PIDFILE\"; exec \"$@\""

main! : List(OsStr) => Try({}, [BenchmarkFailed(Str), Exit(I32), ..])
main! = |raw_args| {
	args = os_args_to_str(raw_args.drop_first(1)) ? |message| BenchmarkFailed(message)
	if args.contains("--help") or args.contains("-h") {
		Stdout.line!(usage).map_err(|error| BenchmarkFailed("write help: ${Str.inspect(error)}"))
	} else {
		config = parse_options(args, default_config) ? |message| BenchmarkFailed("${message}; ${usage}")
		validate_environment!({})?
		grep_program = required_env!("ROC_REDIS_GREP")?
		require_executable!("pinned grep", grep_program)?
		provenance = load_provenance!({})?
		loaded_subjects = load_subjects!({})?
		rotations = if config.all_order_rotations [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] else [config.order_rotation]
		plan = plan_rotations(loaded_subjects, rotations)?
		test_dir = create_test_dir!({})?

		result = run_in_directory!(test_dir, config, provenance, plan, loaded_subjects, rotations.len(), grep_program)
		delete_result = cleanup_test_directory!(test_dir, result.is_ok())

		match (result, delete_result) {
			(Ok({}), Ok({})) => Ok({})
			(Err(error), Ok({})) => Err(error)
			(Ok({}), Err(error)) => Err(BenchmarkFailed("remove ${test_dir.display()}: ${Str.inspect(error)}"))
			(Err(error), Err(delete_error)) =>
				Err(BenchmarkFailed("${describe_error(error)}; also failed to remove ${test_dir.display()}: ${Str.inspect(delete_error)}"))
			}
	}
}

cleanup_test_directory! : Path.Path, Bool => Try({}, [BenchmarkFailed(Str), ..])
cleanup_test_directory! = |test_dir, run_succeeded| {
	watchdog_active = pidfile_process_is_alive!(test_dir.join("redis-watchdog.pid"), "benchmark lifecycle watchdog")?
	redis_active = pidfile_process_is_alive!(test_dir.join("redis.pid"), "Redis")?
	if watchdog_active or redis_active {
		if run_succeeded {
			Err(BenchmarkFailed("refusing to remove ${test_dir.display()} while an owned process remains active"))
		} else {
			# Preserve the watchdog's identity files until this controller exits;
			# the watchdog then performs parent-death cleanup.
			Ok({})
		}
	} else {
		test_dir.delete_all!().map_err(|error| BenchmarkFailed("remove ${test_dir.display()}: ${Str.inspect(error)}"))
	}
}

pidfile_process_is_alive! : Path.Path, Str => Try(Bool, [BenchmarkFailed(Str), ..])
pidfile_process_is_alive! = |pid_path, label|
	match read_pid_if_present!(pid_path, label) {
		Ok(NoPid) => Ok(Bool.False)
		Ok(Pid(pid)) => process_is_alive!(pid)
		Err(error) => Err(error)
	}

os_args_to_str : List(OsStr) -> Try(List(Str), Str)
os_args_to_str = |args|
	match args {
		[] => Ok([])
		[first, .. as rest] => {
			text = OsStr.to_str_try(first) ? |_| "command-line argument is not valid UTF-8"
			following = os_args_to_str(rest)?
			Ok(following.prepend(text))
		}
	}

parse_options : List(Str), Config -> Try(Config, Str)
parse_options = |args, config|
	match args {
		[] => Ok(config)
		["--iterations", value, .. as rest] => {
			iterations = parse_bounded_decimal("iterations", value, 1, max_iterations)?
			parse_options(rest, { ..config, iterations })
		}
		["--warmup", value, .. as rest] => {
			warmup = parse_bounded_decimal("warmup", value, 0, max_iterations)?
			parse_options(rest, { ..config, warmup })
		}
		["--samples", value, .. as rest] => {
			samples = parse_bounded_decimal("samples", value, 1, max_samples)?
			parse_options(rest, { ..config, samples })
		}
		["--pipeline-batch", value, .. as rest] => {
			pipeline_batch = parse_bounded_decimal("pipeline-batch", value, 1, max_pipeline_batch)?
			parse_options(rest, { ..config, pipeline_batch })
		}
		["--timeout-ms", value, .. as rest] => {
			timeout_ms = parse_bounded_decimal("timeout-ms", value, 1, max_timeout_ms)?
			parse_options(rest, { ..config, timeout_ms })
		}
		["--order-rotation", value, .. as rest] => {
			order_rotation = parse_bounded_decimal("order-rotation", value, 0, 9)?
			parse_options(rest, { ..config, order_rotation })
		}
		["--all-order-rotations", .. as rest] => parse_options(rest, { ..config, all_order_rotations: Bool.True })
		["--jsonl", value, .. as rest] if !(value.is_empty()) => parse_options(rest, { ..config, jsonl: Jsonl(value) })
		[option, ..] => Err("unknown or incomplete option ${Str.inspect(option)}")
	}

parse_bounded_decimal : Str, Str, U64, U64 -> Try(U64, Str)
parse_bounded_decimal = |name, value, minimum, maximum| {
	bytes = value.to_utf8()
	if bytes.is_empty() or !(bytes.all(|byte| byte >= 48 and byte <= 57)) {
		Err("${name} must be a decimal integer from ${minimum.to_str()} through ${maximum.to_str()}")
	} else {
		parsed = U64.from_str(value) ? |_| "${name} must be a decimal integer from ${minimum.to_str()} through ${maximum.to_str()}"
		if parsed < minimum or parsed > maximum {
			Err("${name} must be a decimal integer from ${minimum.to_str()} through ${maximum.to_str()}")
		} else {
			Ok(parsed)
		}
	}
}

validate_environment! : {} => Try({}, [BenchmarkFailed(Str), ..])
validate_environment! = |_| {
	match Env.platform!().os {
		LINUX => {}
		MACOS => {}
		other => return Err(BenchmarkFailed("the benchmark controller requires a POSIX host, not ${Str.inspect(other)}"))
	}

	missing = missing_commands!(["redis-server", "redis-cli", "timeout", "sh", "kill", "sleep", "chmod", "tr", "rm", "rmdir"])
	if missing.is_empty() {
		version = run_bounded_output!("timeout", ["--version"])?
		if version.exit_code == 0 and version.stdout.starts_with("timeout (GNU coreutils)") {
			Ok({})
		} else {
			Err(BenchmarkFailed("GNU timeout is required${suffix_output(HarnessText.combine_output(version.stdout, version.stderr))}"))
		}
	} else {
		Err(BenchmarkFailed("required commands not found: ${Str.join_with(missing, ", ")}"))
	}
}

missing_commands! : List(Str) => List(Str)
missing_commands! = |commands|
	match commands {
		[] => []
		[command, .. as rest] => {
			missing_rest = missing_commands!(rest)
			if Cmd.check_available!(command) missing_rest else missing_rest.prepend(command)
		}
	}

load_provenance! : {} => Try(Provenance, [BenchmarkFailed(Str), ..])
load_provenance! = |_| {
	nix_source_id = required_env!("ROC_REDIS_NIX_SOURCE_ID")?
	build_mode = required_env!("ROC_REDIS_BUILD_MODE")?
	nix_system = required_env!("ROC_REDIS_NIX_SYSTEM")?
	os = required_env!("ROC_REDIS_OS")?
	arch = required_env!("ROC_REDIS_ARCH")?

	if !([nix_source_id, build_mode, nix_system, os, arch].all(is_safe_metadata)) {
		Err(BenchmarkFailed("benchmark provenance must contain 1 through 128 safe ASCII characters per field"))
	} else if build_mode != "dev" and build_mode != "speed" {
		Err(BenchmarkFailed("benchmark build mode must be dev or experimental speed, received ${Str.inspect(build_mode)}"))
	} else if nix_system != "${arch}-${os}" {
		Err(BenchmarkFailed("Nix system ${Str.inspect(nix_system)} does not match architecture/OS ${Str.inspect(arch)}-${Str.inspect(os)}"))
	} else {
		Ok({ nix_source_id, build_mode, nix_system, os, arch })
	}
}

load_subjects! : {} => Try(List(Subject), [BenchmarkFailed(Str), ..])
load_subjects! = |_| {
	roc_executable = required_env!("ROC_REDIS_ROC_BENCHMARK")?
	python_executable = required_env!("ROC_REDIS_PYTHON")?
	python_script = required_env!("ROC_REDIS_PYTHON_BENCHMARK")?
	go_executable = required_env!("ROC_REDIS_GO_BENCHMARK")?
	rust_executable = required_env!("ROC_REDIS_RUST_BENCHMARK")?
	c_executable = required_env!("ROC_REDIS_C_BENCHMARK")?
	roc_client_version = required_env!("ROC_REDIS_ROC_CLIENT_VERSION")?
	python_client_version = required_env!("ROC_REDIS_PYTHON_CLIENT_VERSION")?
	go_client_version = required_env!("ROC_REDIS_GO_CLIENT_VERSION")?
	rust_client_version = required_env!("ROC_REDIS_RUST_CLIENT_VERSION")?
	c_client_version = required_env!("ROC_REDIS_C_CLIENT_VERSION")?

	require_executable!("Roc benchmark", roc_executable)?
	require_executable!("Python interpreter", python_executable)?
	require_file!("redis-py benchmark", python_script)?
	require_executable!("Go benchmark", go_executable)?
	require_executable!("Rust benchmark", rust_executable)?
	require_executable!("C benchmark", c_executable)?
	if !([roc_client_version, python_client_version, go_client_version, rust_client_version, c_client_version].all(is_safe_metadata)) {
		return Err(BenchmarkFailed("expected client versions must contain 1 through 128 safe ASCII characters"))
	}

	Ok([
		{ label: "roc-redis", implementation: "roc", expected_client_version: roc_client_version, executable: roc_executable, leading_args: [] },
		{ label: "redis-py", implementation: "python", expected_client_version: python_client_version, executable: python_executable, leading_args: [python_script] },
		{ label: "go-redis", implementation: "go", expected_client_version: go_client_version, executable: go_executable, leading_args: [] },
		{ label: "redis-rs", implementation: "rust", expected_client_version: rust_client_version, executable: rust_executable, leading_args: [] },
		{ label: "hiredis", implementation: "c", expected_client_version: c_client_version, executable: c_executable, leading_args: [] },
	])
}

rotate_subjects : List(Subject), U64 -> Try(List(Subject), [BenchmarkFailed(Str), ..])
rotate_subjects = |subjects, rotation| {
	count = subjects.len()
	if count == 0 or count > 5 {
		return Err(BenchmarkFailed("subject catalog must contain 1 through 5 entries"))
	}
	if rotation >= count * 2 {
		return Err(BenchmarkFailed("order rotation exceeds twice the subject count"))
	}
	# Cyclic rotations in both directions give each subject two appearances at
	# each position. This is positional balance, not every possible permutation
	# or full pairwise carryover balance for five subjects.
	base = if rotation < count {
		subjects
	} else {
		match subjects {
			[first, .. as rest] => {
				var $reversed = []
				for subject in rest {
					$reversed = [subject].concat($reversed)
				}
				[first].concat($reversed)
			}
			[] => []
		}
	}
	offset = rotation % count
	Ok(base.drop_first(offset).concat(base.take_first(offset)))
}

plan_rotations : List(Subject), List(U64) -> Try(List(PlannedSubject), [BenchmarkFailed(Str), ..])
plan_rotations = |subjects, rotations|
	match rotations {
		[] => Ok([])
		[rotation, .. as rest] => {
			rotated = rotate_subjects(subjects, rotation)?
			planned = plan_subject_positions(rotated, rotation, 1)
			following = plan_rotations(subjects, rest)?
			Ok(planned.concat(following))
		}
	}

plan_subject_positions : List(Subject), U64, U64 -> List(PlannedSubject)
plan_subject_positions = |subjects, order_rotation, subject_position|
	match subjects {
		[] => []
		[subject, .. as rest] =>
			[{ subject, order_rotation, subject_position }].concat(plan_subject_positions(rest, order_rotation, subject_position + 1))
		}

required_env! : Str => Try(Str, [BenchmarkFailed(Str), ..])
required_env! = |name|
	match Env.var_str!(OsStr.from_str(name)) {
		Ok(value) if !(value.is_empty()) => Ok(value)
		Ok(_) => Err(BenchmarkFailed("${name} must not be empty"))
		Err(VarNotFound(_)) => Err(BenchmarkFailed("${name} is required; use `nix run .#benchmark` to supply the pinned subjects"))
		Err(error) => Err(BenchmarkFailed("read ${name}: ${Str.inspect(error)}"))
	}

is_safe_metadata : Str -> Bool
is_safe_metadata = |value| {
	bytes = value.to_utf8()
	bytes.len() >= 1 and bytes.len() <= 128 and bytes.all(|byte|
		(byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) or byte == 43 or byte == 45 or byte == 46 or byte == 58 or byte == 95)
}

require_executable! : Str, Str => Try({}, [BenchmarkFailed(Str), ..])
require_executable! = |label, value| {
	path = Path.utf8(value)
	is_executable = path.is_executable!() ? |error| BenchmarkFailed("inspect ${label} executable ${path.display()}: ${Str.inspect(error)}")
	if is_executable {
		Ok({})
	} else {
		Err(BenchmarkFailed("${label} is not executable: ${path.display()}"))
	}
}

require_file! : Str, Str => Try({}, [BenchmarkFailed(Str), ..])
require_file! = |label, value| {
	path = Path.utf8(value)
	is_file = path.is_file!() ? |error| BenchmarkFailed("inspect ${label} file ${path.display()}: ${Str.inspect(error)}")
	if is_file {
		Ok({})
	} else {
		Err(BenchmarkFailed("${label} file was not found: ${path.display()}"))
	}
}

create_test_dir! : {} => Try(Path.Path, [BenchmarkFailed(Str), ..])
create_test_dir! = |_| create_test_dir_with_attempts!(8)

create_test_dir_with_attempts! : U8 => Try(Path.Path, [BenchmarkFailed(Str), ..])
create_test_dir_with_attempts! = |attempts_remaining| {
	seed = Random.seed_u64!() ? |error| BenchmarkFailed("choose benchmark directory: ${Str.inspect(error)}")
	path = Env.temp_dir!().join("roc-redis-benchmark-${seed.to_str()}")
	match path.create_dir!() {
		Ok({}) => {
			outcome = run_bounded_output!("chmod", ["700", path.display()])?
			if outcome.exit_code == 0 {
				Ok(path)
			} else {
				cleanup = path.delete_all!()
				_ = cleanup
				Err(BenchmarkFailed("chmod 700 ${path.display()} exited ${outcome.exit_code.to_str()}${suffix_output(HarnessText.combine_output(outcome.stdout, outcome.stderr))}"))
			}
		}
		Err(PathErr(AlreadyExists, _)) if attempts_remaining > 1 => create_test_dir_with_attempts!(attempts_remaining - 1)
		Err(error) => Err(BenchmarkFailed("create ${path.display()}: ${Str.inspect(error)}"))
	}
}

RedisServer : { pid : Str, port : U16, socket_path : Path.Path, version : Str, watchdog_pid : Str }

run_in_directory! : Path.Path, Config, Provenance, List(PlannedSubject), List(Subject), U64, Str => Try({}, [BenchmarkFailed(Str), ..])
run_in_directory! = |test_dir, config, provenance, plan, subject_catalog, rotation_count, grep_program| {
	watchdog_pid = launch_watchdog!(test_dir, grep_program)?
	seed_result = Random.seed_u64!().map_err(|error| BenchmarkFailed("choose Redis port: ${Str.inspect(error)}"))
	match seed_result {
		Err(error) => {
			watchdog_result = stop_process!(watchdog_pid, "benchmark lifecycle watchdog")
			combine_value_and_cleanup(Err(error), watchdog_result)
		}
		Ok(seed) =>
			match start_redis!(test_dir, seed, 0, watchdog_pid) {
				Err(error) => finish_failed_start!(test_dir, watchdog_pid, error)
				Ok(redis) => {
					benchmark_result = run_planned_subjects!(plan, redis, test_dir, seed, config, provenance, [])
					stop_result = stop_redis!(redis)

					match (benchmark_result, stop_result) {
						(Ok(runs), Ok({})) => finish_results!(runs, config, redis.version, subject_catalog, rotation_count)
						(Err(error), Ok({})) => Err(error)
						(Ok(_), Err(error)) => Err(error)
						(Err(error), Err(stop_error)) => Err(BenchmarkFailed("${describe_error(error)}; Redis cleanup also failed: ${describe_error(stop_error)}"))
					}
				}
			}
		}
}

finish_failed_start! : Path.Path, Str, [BenchmarkFailed(Str), ..] => Try(a, [BenchmarkFailed(Str), ..])
finish_failed_start! = |test_dir, watchdog_pid, original_error| {
	redis_active_result = pidfile_process_is_alive!(test_dir.join("redis.pid"), "Redis")
	match redis_active_result {
		Ok(Bool.True) => Err(BenchmarkFailed(describe_error(original_error)))
		Ok(Bool.False) => {
			watchdog_result = stop_process!(watchdog_pid, "benchmark lifecycle watchdog")
			combine_value_and_cleanup(Err(original_error), watchdog_result)
		}
		Err(error) => Err(BenchmarkFailed("${describe_error(original_error)}; could not establish failed-start cleanup state: ${describe_error(error)}"))
	}
}

run_planned_subjects! : List(PlannedSubject), RedisServer, Path.Path, U64, Config, Provenance, List(SubjectRun) => Try(List(SubjectRun), [BenchmarkFailed(Str), ..])
run_planned_subjects! = |remaining, redis, test_dir, seed, config, provenance, completed|
	match remaining {
		[] => Ok(completed)
		[planned, .. as rest] => {
			subject = planned.subject
			rotation_config = { ..config, order_rotation: planned.order_rotation }
			ensure_watchdog_active!(redis)?
			run = run_subject!(subject, redis, test_dir, seed, rotation_config, provenance, planned.subject_position)?
			ensure_watchdog_active!(redis)?
			db_size = redis_db_size!(redis.socket_path, redis.pid)?
			if db_size != 0 {
				Err(BenchmarkFailed("${subject.label} left ${db_size.to_str()} keys in the isolated Redis database"))
			} else {
				next_seed = increment_seed(seed)
				run_planned_subjects!(rest, redis, test_dir, next_seed, config, provenance, completed.append(run))
			}
		}
	}

increment_seed : U64 -> U64
increment_seed = |seed| if seed == U64.highest 0 else seed + 1

run_subject! : Subject, RedisServer, Path.Path, U64, Config, Provenance, U64 => Try(SubjectRun, [BenchmarkFailed(Str), ..])
run_subject! = |subject, redis, test_dir, seed, config, provenance, subject_position| {
	prefix = benchmark_prefix(subject.implementation, seed, config.order_rotation, subject_position)
	arguments = subject.leading_args.concat([
		"--host",
		"127.0.0.1",
		"--port",
		redis.port.to_str(),
		"--iterations",
		config.iterations.to_str(),
		"--warmup",
		config.warmup.to_str(),
		"--samples",
		config.samples.to_str(),
		"--pipeline-batch",
		config.pipeline_batch.to_str(),
		"--timeout-ms",
		config.timeout_ms.to_str(),
		"--key-prefix",
		prefix,
		"--nix-source-id",
		provenance.nix_source_id,
		"--build-mode",
		provenance.build_mode,
		"--nix-system",
		provenance.nix_system,
		"--os",
		provenance.os,
		"--arch",
		provenance.arch,
		"--order-rotation",
		config.order_rotation.to_str(),
		"--subject-position",
		subject_position.to_str(),
	])

	outcome_result = run_subject_process!(subject, arguments, test_dir)
	watchdog_result = ensure_watchdog_active!(redis)
	outcome = combine_value_and_cleanup(outcome_result, watchdog_result)?
	if outcome.exit_code == 0 {
		if !(outcome.stderr.is_empty()) {
			Stderr.write!(outcome.stderr) ? |error| BenchmarkFailed("write ${subject.label} diagnostics: ${Str.inspect(error)}")
		}
		lines = strict_jsonl_lines(outcome.stdout)?
		records = parse_record_lines(lines, 1, [])?
		validate_records(subject, records, config, redis.version, provenance, subject_position)?
		normalized = "${Str.join_with(lines, "\n")}\n"
		Ok({ label: subject.label, implementation: subject.implementation, raw_jsonl: normalized, records })
	} else {
		output = HarnessText.combine_output(outcome.stdout, outcome.stderr)
		if outcome.exit_code == 124 or outcome.exit_code == 137 {
			Err(BenchmarkFailed("${subject.label} exceeded ${subject_timeout_seconds}${suffix_output(output)}"))
		} else if outcome.exit_code == 125 or outcome.exit_code == 126 or outcome.exit_code == 127 {
			Err(BenchmarkFailed("could not invoke ${subject.label} through GNU timeout (exit ${outcome.exit_code.to_str()})${suffix_output(output)}"))
		} else {
			Err(BenchmarkFailed("${subject.label} exited ${outcome.exit_code.to_str()}${suffix_output(output)}"))
		}
	}
}

benchmark_prefix : Str, U64, U64, U64 -> Str
benchmark_prefix = |implementation, seed, order_rotation, subject_position|
# Rotation and position make every campaign lease/key set distinct even if
# the random seed happens to wrap while planning multiple subject runs.
	"roc-redis-bench:${implementation}:${seed.to_str()}:r${order_rotation.to_str()}:p${subject_position.to_str()}"

run_subject_process! : Subject, List(Str), Path.Path => Try(ProcessOutput, [BenchmarkFailed(Str), ..])
run_subject_process! = |subject, arguments, test_dir| {
	pid_path = test_dir.join("subject-supervisor.pid")
	delete_if_present!(pid_path)?
	wrapped = [
		"--signal=TERM",
		"--kill-after=2s",
		subject_timeout_seconds,
		"sh",
		"-c",
		subject_wrapper_script,
		"roc-redis-benchmark-subject",
		subject.executable,
	].concat(arguments)
	command = Cmd.new_str("timeout").args_str(wrapped).env(OsStr.from_str("SUBJECT_PIDFILE"), pid_path.to_os_str())
	outcome_result = match command.exec_output!() {
		Ok({ stdout_utf8, stderr_utf8_lossy }) => Ok({ exit_code: 0, stdout: stdout_utf8, stderr: stderr_utf8_lossy })
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) =>
			Ok({ exit_code, stdout: stdout_utf8_lossy, stderr: stderr_utf8_lossy })
		Err(error) => Err(BenchmarkFailed("could not start ${subject.label}: ${Str.inspect(error)}"))
	}
	stop_result = stop_subject_from_pidfile!(pid_path)
	without_process = combine_value_and_cleanup(outcome_result, stop_result)
	delete_result = delete_if_present!(pid_path)
	combine_value_and_cleanup(without_process, delete_result)
}

strict_jsonl_lines : Str -> Try(List(Str), [BenchmarkFailed(Str), ..])
strict_jsonl_lines = |output| {
	parts = output.split_on("\n")
	lines = match parts.last() {
		Ok(last) if last.is_empty() => parts.drop_last(1)
		_ => parts
	}
	if lines.is_empty() {
		Err(BenchmarkFailed("benchmark subject emitted no JSONL records"))
	} else {
		first_blank = first_blank_line(lines, 1)
		match first_blank {
			Ok(line_number) => Err(BenchmarkFailed("benchmark subject emitted a blank JSONL line at line ${line_number.to_str()}"))
			Err(NoBlankLine) => Ok(lines)
		}
	}
}

first_blank_line : List(Str), U64 -> Try(U64, [NoBlankLine])
first_blank_line = |lines, line_number|
	match lines {
		[] => Err(NoBlankLine)
		[first, .. as rest] =>
			if first.is_empty() {
				Ok(line_number)
			} else {
				first_blank_line(rest, line_number + 1)
			}
		}

parse_records : Str -> Try(List(BenchmarkRecord), [BenchmarkFailed(Str), ..])
parse_records = |output| {
	lines = strict_jsonl_lines(output)?
	parse_record_lines(lines, 1, [])
}

parse_record_lines : List(Str), U64, List(BenchmarkRecord) -> Try(List(BenchmarkRecord), [BenchmarkFailed(Str), ..])
parse_record_lines = |remaining, line_number, parsed|
	match remaining {
		[] => Ok(parsed)
		[line, .. as rest] => {
			result : Try(BenchmarkRecord, _)
			result = Json.parse(line)
			record = result ? |error| BenchmarkFailed("invalid benchmark JSON on line ${line_number.to_str()}: ${Str.inspect(error)}")
			parse_record_lines(rest, line_number + 1, parsed.append(record))
		}
	}

validate_records : Subject, List(BenchmarkRecord), Config, Str, Provenance, U64 -> Try({}, [BenchmarkFailed(Str), ..])
validate_records = |subject, records, config, redis_version, provenance, subject_position| {
	expected_count = config.samples * workloads.len()
	if records.len() != expected_count {
		Err(BenchmarkFailed("${subject.label} emitted ${records.len().to_str()} records; expected ${expected_count.to_str()}"))
	} else {
		validate_record_sequence(subject, records, config, redis_version, provenance, subject_position, 0)
	}
}

validate_record_sequence : Subject, List(BenchmarkRecord), Config, Str, Provenance, U64, U64 -> Try({}, [BenchmarkFailed(Str), ..])
validate_record_sequence = |subject, remaining, config, redis_version, provenance, subject_position, index|
	match remaining {
		[] => Ok({})
		[record, .. as rest] => {
			workload_index = index / config.samples
			expected_workload = workloads.get(workload_index) ? |_| BenchmarkFailed("internal workload index ${workload_index.to_str()} is out of range")
			expected_sample = (index % config.samples) + 1
			expected_commands = if expected_workload == "set_get_sequential" config.iterations * 2 else config.iterations
			expected_round_trips =
				if expected_workload == "set_get_sequential" {
					config.iterations * 2
				} else if expected_workload == "ping_pipeline" {
					ceiling_divide(config.iterations, config.pipeline_batch)
				} else {
					config.iterations
				}
			expected_timer = if subject.implementation == "roc" "utc_wall_clock" else "monotonic"

			problem = validate_record(record, subject, config, redis_version, provenance, subject_position, expected_workload, expected_sample, expected_commands, expected_round_trips, expected_timer)
			match problem {
				Ok({}) => validate_record_sequence(subject, rest, config, redis_version, provenance, subject_position, index + 1)
				Err(message) => Err(BenchmarkFailed("${subject.label} record ${(index + 1).to_str()}: ${message}"))
			}
		}
	}

validate_record : BenchmarkRecord, Subject, Config, Str, Provenance, U64, Str, U64, U64, U64, Str -> Try({}, Str)
validate_record = |record, subject, config, redis_version, provenance, subject_position, expected_workload, expected_sample, expected_commands, expected_round_trips, expected_timer| {
	if record.schema != schema {
		Err("schema was ${Str.inspect(record.schema)}, expected ${Str.inspect(schema)}")
	} else if record.implementation != subject.implementation {
		Err("implementation was ${Str.inspect(record.implementation)}, expected ${Str.inspect(subject.implementation)}")
	} else if record.client != subject.label {
		Err("client was ${Str.inspect(record.client)}, expected ${Str.inspect(subject.label)}")
	} else if record.client_version != subject.expected_client_version {
		Err("client_version was ${Str.inspect(record.client_version)}, expected pinned ${Str.inspect(subject.expected_client_version)}")
	} else if !(is_safe_metadata(record.runtime_version)) {
		Err("runtime_version must contain 1 through 128 safe ASCII characters")
	} else if record.redis_version != redis_version {
		Err("redis_version was ${Str.inspect(record.redis_version)}, expected ${Str.inspect(redis_version)}")
	} else if record.nix_source_id != provenance.nix_source_id or record.build_mode != provenance.build_mode or record.nix_system != provenance.nix_system or record.os != provenance.os or record.arch != provenance.arch {
		Err("build provenance does not match the controller")
	} else if record.order_rotation != config.order_rotation or record.subject_position != subject_position {
		Err("execution-order metadata was rotation ${record.order_rotation.to_str()} position ${record.subject_position.to_str()}, expected rotation ${config.order_rotation.to_str()} position ${subject_position.to_str()}")
	} else if record.timer != expected_timer {
		Err("timer was ${Str.inspect(record.timer)}, expected ${Str.inspect(expected_timer)}")
	} else if record.workload != expected_workload {
		Err("workload was ${Str.inspect(record.workload)}, expected ${Str.inspect(expected_workload)}")
	} else if record.sample != expected_sample or record.samples != config.samples {
		Err("sample metadata was ${record.sample.to_str()}/${record.samples.to_str()}, expected ${expected_sample.to_str()}/${config.samples.to_str()}")
	} else if record.iterations != config.iterations or record.warmup != config.warmup or record.pipeline_batch != config.pipeline_batch {
		Err("configuration metadata does not match the controller")
	} else if record.operation_count != config.iterations {
		Err("operation_count was ${record.operation_count.to_str()}, expected ${config.iterations.to_str()}")
	} else if record.command_count != expected_commands {
		Err("command_count was ${record.command_count.to_str()}, expected ${expected_commands.to_str()}")
	} else if record.round_trip_count != expected_round_trips {
		Err("round_trip_count was ${record.round_trip_count.to_str()}, expected ${expected_round_trips.to_str()}")
	} else if record.elapsed_ns == 0 {
		Err("elapsed_ns must be positive")
	} else if !(record.validated) {
		Err("subject did not mark the sample validated")
	} else {
		Ok({})
	}
}

ceiling_divide : U64, U64 -> U64
ceiling_divide = |value, divisor| value / divisor + (if value % divisor == 0 0 else 1)

finish_results! : List(SubjectRun), Config, Str, List(Subject), U64 => Try({}, [BenchmarkFailed(Str), ..])
finish_results! = |runs, config, redis_version, subject_catalog, rotation_count| {
	expected_runs = rotation_count * subject_catalog.len()
	expected_records = expected_runs * workloads.len() * config.samples
	actual_records = count_run_records(runs)
	if runs.len() != expected_runs or actual_records != expected_records {
		return Err(BenchmarkFailed("campaign produced ${runs.len().to_str()} subject runs and ${actual_records.to_str()} records; expected ${expected_runs.to_str()} runs and ${expected_records.to_str()} records"))
	}

	match config.jsonl {
		NoJsonl => {}
		Jsonl(output_name) => {
			output_path = Path.utf8(output_name)
			contents = Str.join_with(runs.map(|run| run.raw_jsonl), "")
			write_jsonl_atomically!(output_path, contents)?
			Stdout.line!("Validated samples: ${output_path.display()}") ? |error| BenchmarkFailed("write JSONL path: ${Str.inspect(error)}")
		}
	}

	total_samples = config.samples * rotation_count
	Stdout.line!("Isolated Redis ${redis_version} benchmark: ${config.iterations.to_str()} measured operations/sample, ${config.warmup.to_str()} warmup, ${total_samples.to_str()} samples across ${rotation_count.to_str()} order rotation(s)") ? |error| BenchmarkFailed("write benchmark heading: ${Str.inspect(error)}")
	Stdout.line!("client | timer | workload | median time | operations/s | Redis commands/s") ? |error| BenchmarkFailed("write benchmark heading: ${Str.inspect(error)}")
	Stdout.line!("--- | --- | --- | ---: | ---: | ---:") ? |error| BenchmarkFailed("write benchmark heading: ${Str.inspect(error)}")
	print_subject_summaries!(runs, subject_catalog, rotation_count)
}

count_run_records : List(SubjectRun) -> U64
count_run_records = |runs|
	match runs {
		[] => 0
		[first, .. as rest] => first.records.len() + count_run_records(rest)
	}

write_jsonl_atomically! : Path.Path, Str => Try({}, [BenchmarkFailed(Str), ..])
write_jsonl_atomically! = |output_path, contents| {
	seed = Random.seed_u64!() ? |error| BenchmarkFailed("choose JSONL atomic-write name: ${Str.inspect(error)}")
	temporary = Path.utf8("${output_path.display()}.benchmark-${seed.to_str()}.tmp")
	write_result = temporary.write_utf8!(contents).map_err(|error| BenchmarkFailed("write temporary JSONL ${temporary.display()}: ${Str.inspect(error)}"))
	match write_result {
		Err(error) => {
			_ = delete_if_present!(temporary)
			Err(error)
		}
		Ok({}) =>
			match temporary.rename!(output_path) {
				Ok({}) => Ok({})
				Err(error) => {
					cleanup = delete_if_present!(temporary)
					message = "atomically replace ${output_path.display()}: ${Str.inspect(error)}"
					match cleanup {
						Ok({}) => Err(BenchmarkFailed(message))
						Err(cleanup_error) => Err(BenchmarkFailed("${message}; ${describe_error(cleanup_error)}"))
					}
				}
			}
		}
}

print_subject_summaries! : List(SubjectRun), List(Subject), U64 => Try({}, [BenchmarkFailed(Str), ..])
print_subject_summaries! = |runs, subjects, rotation_count|
	match subjects {
		[] => Ok({})
		[subject, .. as rest] => {
			matching = runs.keep_if(|run| run.implementation == subject.implementation)
			if matching.len() != rotation_count {
				Err(BenchmarkFailed("${subject.label} produced ${matching.len().to_str()} runs; expected ${rotation_count.to_str()}"))
			} else {
				first = matching.first() ? |_| BenchmarkFailed("internal error: no runs for ${subject.label}")
				combined = { ..first, raw_jsonl: "", records: collect_run_records(matching) }
				print_workload_summaries!(combined, workloads)?
				print_subject_summaries!(runs, rest, rotation_count)
			}
		}
	}

collect_run_records : List(SubjectRun) -> List(BenchmarkRecord)
collect_run_records = |runs|
	match runs {
		[] => []
		[first, .. as rest] => first.records.concat(collect_run_records(rest))
	}

print_workload_summaries! : SubjectRun, List(Str) => Try({}, [BenchmarkFailed(Str), ..])
print_workload_summaries! = |run, remaining|
	match remaining {
		[] => Ok({})
		[workload, .. as rest] => {
			records = run.records.keep_if(|record| record.workload == workload)
			first = records.first() ? |_| BenchmarkFailed("internal error: no ${workload} records for ${run.label}")
			median_ns = median(records.map(|record| record.elapsed_ns)) ? |message| BenchmarkFailed(message)
			operations_per_second = rate_per_second(first.operation_count, median_ns) ? |message| BenchmarkFailed("${run.label} ${workload} operations/s: ${message}")
			commands_per_second = rate_per_second(first.command_count, median_ns) ? |message| BenchmarkFailed("${run.label} ${workload} commands/s: ${message}")
			line = "${run.label} | ${first.timer} | ${workload} | ${format_milliseconds(median_ns)} ms | ${operations_per_second.to_str()} | ${commands_per_second.to_str()}"
			Stdout.line!(line) ? |error| BenchmarkFailed("write benchmark result: ${Str.inspect(error)}")
			print_workload_summaries!(run, rest)
		}
	}

median : List(U64) -> Try(U64, Str)
median = |values| {
	sorted = values.sort_with(u64_order)
	length = sorted.len()
	if length == 0 {
		Err("cannot calculate a median for an empty sample")
	} else if length % 2 == 1 {
		sorted.get(length / 2).map_err(|_| "internal median index is out of range")
	} else {
		upper = sorted.get(length / 2) ? |_| "internal upper median index is out of range"
		lower = sorted.get(length / 2 - 1) ? |_| "internal lower median index is out of range"
		Ok(lower + (upper - lower) / 2)
	}
}

u64_order : U64, U64 -> [Before, Same, After]
u64_order = |left, right|
	if left < right Before else if left > right After else Same

rate_per_second : U64, U64 -> Try(U64, Str)
rate_per_second = |count, elapsed_ns| {
	if elapsed_ns == 0 {
		Err("elapsed nanoseconds must be positive")
	} else {
		numerator : U128
		numerator = U64.to_u128(count) * 1_000_000_000
		rate = numerator / U64.to_u128(elapsed_ns)
		if rate > U64.to_u128(U64.highest) {
			Err("calculated rate does not fit in U64")
		} else {
			Ok(U128.to_u64_wrap(rate))
		}
	}
}

format_milliseconds : U64 -> Str
format_milliseconds = |nanoseconds| {
	whole = nanoseconds / 1_000_000
	fraction = (nanoseconds % 1_000_000) / 1_000
	"${whole.to_str()}.${pad_three(fraction)}"
}

pad_three : U64 -> Str
pad_three = |value|
	if value < 10 {
		"00${value.to_str()}"
	} else if value < 100 {
		"0${value.to_str()}"
	} else {
		value.to_str()
	}

start_redis! : Path.Path, U64, U8, Str => Try(RedisServer, [BenchmarkFailed(Str), ..])
start_redis! = |test_dir, seed, attempt, watchdog_pid| {
	if attempt >= port_attempts {
		Err(BenchmarkFailed("could not start isolated Redis after ${port_attempts.to_str()} port attempts; last log: ${read_log_best_effort!(test_dir.join("redis.log"))}"))
	} else {
		ensure_process_active!(watchdog_pid, "benchmark lifecycle watchdog")?
		port = random_port(seed, attempt)
		match start_redis_candidate!(test_dir, port, watchdog_pid) {
			Ok(StartedRedis(server)) => Ok(server)
			Ok(RedisUnavailable) => start_redis!(test_dir, seed, attempt + 1, watchdog_pid)
			Err(error) => Err(error)
		}
	}
}

start_redis_candidate! : Path.Path, U16, Str => Try([StartedRedis(RedisServer), RedisUnavailable], [BenchmarkFailed(Str), ..])
start_redis_candidate! = |test_dir, port, watchdog_pid| {
	pid_path = test_dir.join("redis.pid")
	log_path = test_dir.join("redis.log")
	socket_path = test_dir.join("redis.sock")
	delete_if_present!(pid_path)?
	delete_if_present!(socket_path)?
	arguments = [
		"--bind",
		"127.0.0.1",
		"--protected-mode",
		"yes",
		"--port",
		port.to_str(),
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
		test_dir.display(),
		"--pidfile",
		pid_path.display(),
		"--logfile",
		log_path.display(),
		"--loglevel",
		"warning",
	]
	launch_result = run_bounded_output_with_limit!(service_launch_timeout_seconds, "redis-server", arguments)
	match launch_result {
		Err(error) => {
			cleanup = stop_redis_from_pidfile!(socket_path, pid_path, "Redis")
			fail_after_cleanup(describe_error(error), cleanup)
		}
		Ok(outcome) if outcome.exit_code != 0 => {
			cleanup = stop_redis_from_pidfile!(socket_path, pid_path, "Redis")
			match cleanup {
				Ok({}) => Ok(RedisUnavailable)
				Err(error) => Err(error)
			}
		}
		Ok(_) =>
			match wait_for_redis_owner!(socket_path, pid_path, watchdog_pid, redis_readiness_attempts) {
				Ok(RedisReady(pid)) => {
					version = redis_server_version!(socket_path, pid)?
					Ok(StartedRedis({ pid, port, socket_path, version, watchdog_pid }))
				}
				Ok(RedisNotReady) => {
					cleanup = stop_redis_from_pidfile!(socket_path, pid_path, "Redis")
					match cleanup {
						Ok({}) => Ok(RedisUnavailable)
						Err(error) => Err(error)
					}
				}
				Err(error) => {
					cleanup = stop_redis_from_pidfile!(socket_path, pid_path, "Redis")
					match cleanup {
						Ok({}) => Err(error)
						Err(cleanup_error) => Err(BenchmarkFailed("${describe_error(error)}; cleanup also failed: ${describe_error(cleanup_error)}"))
					}
				}
			}
		}
}

wait_for_redis_owner! : Path.Path, Path.Path, Str, U8 => Try([RedisReady(Str), RedisNotReady], [BenchmarkFailed(Str), ..])
wait_for_redis_owner! = |socket_path, pid_path, watchdog_pid, attempts_remaining| {
	if attempts_remaining == 0 {
		Ok(RedisNotReady)
	} else {
		ensure_process_active!(watchdog_pid, "benchmark lifecycle watchdog")?
		match read_pid_if_present!(pid_path, "Redis") {
			Ok(Pid(pid)) =>
				if redis_is_owner!(socket_path, pid)? {
					Ok(RedisReady(pid))
				} else {
					Sleep.millis!(50)
					wait_for_redis_owner!(socket_path, pid_path, watchdog_pid, attempts_remaining - 1)
				}
			Ok(NoPid) => {
				Sleep.millis!(50)
				wait_for_redis_owner!(socket_path, pid_path, watchdog_pid, attempts_remaining - 1)
			}
			Err(error) => Err(error)
		}
	}
}

launch_watchdog! : Path.Path, Str => Try(Str, [BenchmarkFailed(Str), ..])
launch_watchdog! = |test_dir, grep_program| {
	pid_path = test_dir.join("redis-watchdog.pid")
	delete_if_present!(pid_path)?
	command =
		Cmd.new_str("sh")
			.args_str(["-c", watchdog_wrapper_script, "roc-redis-benchmark-watchdog", "timeout", watchdog_launch_script])
			.env(OsStr.from_str("TEST_DIR"), test_dir.to_os_str())
			.env(OsStr.from_str("WATCHDOG_PIDFILE"), pid_path.to_os_str())
			.env(OsStr.from_str("REDIS_PIDFILE"), test_dir.join("redis.pid").to_os_str())
			.env(OsStr.from_str("REDIS_SOCKET"), test_dir.join("redis.sock").to_os_str())
			.env(OsStr.from_str("SUBJECT_PIDFILE"), test_dir.join("subject-supervisor.pid").to_os_str())
			.env(OsStr.from_str("OWNER_FILE"), test_dir.join("controller.owner").to_os_str())
			.env_str("TIMEOUT_PROGRAM", "timeout")
			.env_str("REDIS_CLI", "redis-cli")
			.env_str("GREP_PROGRAM", grep_program)
			.env(OsStr.from_str("TEMP_ROOT"), Env.temp_dir!().to_os_str())

	match command.exec_output!() {
		Ok({ stdout_utf8, stderr_utf8_lossy }) => {
			captured_pid = HarnessText.parse_pid_text(stdout_utf8)
			pidfile_pid = read_pid_if_present!(pid_path, "Redis watchdog")
			match (captured_pid, pidfile_pid) {
				(Ok(pid), Ok(Pid(file_pid))) if pid == file_pid =>
					if process_is_alive!(pid)? {
						Ok(pid)
					} else {
						Err(BenchmarkFailed("Redis parent-death watchdog exited during launch"))
					}
				(Ok(pid), Ok(Pid(file_pid))) => {
					cleanup = cleanup_pid_pair!(FoundPid(pid), FoundPid(file_pid), "Redis watchdog")
					fail_after_cleanup("Redis watchdog PID mismatch: captured ${pid}, pidfile ${file_pid}", cleanup)
				}
				(Ok(pid), Ok(NoPid)) => {
					cleanup = stop_process!(pid, "Redis watchdog")
					fail_after_cleanup("Redis watchdog returned PID ${pid} without writing its pidfile${suffix_output(stderr_utf8_lossy)}", cleanup)
				}
				(Ok(pid), Err(error)) => {
					cleanup = stop_process!(pid, "Redis watchdog")
					fail_after_cleanup(describe_error(error), cleanup)
				}
				(Err(message), Ok(Pid(pid))) => {
					cleanup = stop_process!(pid, "Redis watchdog")
					fail_after_cleanup("Redis watchdog ${message}${suffix_output(stderr_utf8_lossy)}", cleanup)
				}
				(Err(message), Ok(NoPid)) => Err(BenchmarkFailed("Redis watchdog ${message}${suffix_output(stderr_utf8_lossy)}"))
				(Err(message), Err(pid_error)) => Err(BenchmarkFailed("Redis watchdog ${message}; ${describe_error(pid_error)}${suffix_output(stderr_utf8_lossy)}"))
			}
		}
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) => {
			cleanup = cleanup_launched_process!(pid_path, stdout_utf8_lossy, "Redis watchdog")
			output = HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy)
			message = if exit_code == 124 or exit_code == 137 "Redis watchdog launch exceeded ${shell_launch_timeout_seconds}s${suffix_output(output)}" else "Redis watchdog launch exited ${exit_code.to_str()}${suffix_output(output)}"
			fail_after_cleanup(message, cleanup)
		}
		Err(error) => {
			cleanup = cleanup_launched_process!(pid_path, "", "Redis watchdog")
			fail_after_cleanup("could not launch Redis watchdog: ${Str.inspect(error)}", cleanup)
		}
	}
}

redis_db_size! : Path.Path, Str => Try(U64, [BenchmarkFailed(Str), ..])
redis_db_size! = |socket_path, expected_pid| {
	if !(redis_is_owner!(socket_path, expected_pid)?) {
		Err(BenchmarkFailed("refusing DBSIZE: process ${expected_pid} no longer owns ${socket_path.display()}"))
	} else {
		outcome = redis_cli_outcome!(socket_path, ["DBSIZE"], probe_timeout_seconds)?
		if outcome.exit_code == 0 {
			parse_bounded_decimal("Redis DBSIZE", HarnessText.first_line(outcome.stdout).trim(), 0, U64.highest).map_err(|message| BenchmarkFailed(message))
		} else {
			Err(BenchmarkFailed("redis-cli DBSIZE exited ${outcome.exit_code.to_str()}${suffix_output(HarnessText.combine_output(outcome.stdout, outcome.stderr))}"))
		}
	}
}

redis_cli_outcome! : Path.Path, List(Str), Str => Try(ProcessOutput, [BenchmarkFailed(Str), ..])
redis_cli_outcome! = |socket_path, arguments, limit|
	run_bounded_output_with_limit!(limit, "redis-cli", ["--raw", "-t", "1", "-s", socket_path.display()].concat(arguments))

redis_is_owner! : Path.Path, Str => Try(Bool, [BenchmarkFailed(Str), ..])
redis_is_owner! = |socket_path, expected_pid| {
	outcome = redis_cli_outcome!(socket_path, ["INFO", "server"], probe_timeout_seconds)?
	if outcome.exit_code != 0 {
		Ok(Bool.False)
	} else {
		Ok(HarnessText.redis_info_field(outcome.stdout, "process_id") == Ok(expected_pid))
	}
}

redis_server_version! : Path.Path, Str => Try(Str, [BenchmarkFailed(Str), ..])
redis_server_version! = |socket_path, expected_pid| {
	outcome = redis_cli_outcome!(socket_path, ["INFO", "server"], probe_timeout_seconds)?
	if outcome.exit_code != 0 {
		Err(BenchmarkFailed("redis-cli INFO server exited ${outcome.exit_code.to_str()}${suffix_output(HarnessText.combine_output(outcome.stdout, outcome.stderr))}"))
	} else if HarnessText.redis_info_field(outcome.stdout, "process_id") != Ok(expected_pid) {
		Err(BenchmarkFailed("Redis ownership changed while reading its version"))
	} else {
		version = HarnessText.redis_info_field(outcome.stdout, "redis_version")
			? |_| BenchmarkFailed("Redis INFO server omitted redis_version")
		if is_safe_version(version) {
			Ok(version)
		} else {
			Err(BenchmarkFailed("Redis INFO server returned invalid redis_version ${Str.inspect(version)}"))
		}
	}
}

is_safe_version : Str -> Bool
is_safe_version = |version| {
	bytes = version.to_utf8()
	bytes.len() >= 1 and bytes.len() <= 128 and bytes.all(|byte|
		(byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) or byte == 43 or byte == 45 or byte == 46 or byte == 95)
}

stop_redis! : RedisServer => Try({}, [BenchmarkFailed(Str), ..])
stop_redis! = |redis| {
	if redis_is_owner!(redis.socket_path, redis.pid)? {
		child_result = stop_process!(redis.pid, "Redis")
		match child_result {
			Ok({}) => stop_process!(redis.watchdog_pid, "Redis parent-death watchdog")
			Err(error) => Err(error)
		}
	} else if process_is_alive!(redis.pid)? {
		Err(BenchmarkFailed("refusing to signal process ${redis.pid}: it no longer owns Redis port ${redis.port.to_str()}"))
	} else {
		stop_process!(redis.watchdog_pid, "Redis parent-death watchdog")
	}
}

stop_redis_from_pidfile! : Path.Path, Path.Path, Str => Try({}, [BenchmarkFailed(Str), ..])
stop_redis_from_pidfile! = |socket_path, pid_path, label|
	match read_pid_if_present!(pid_path, label) {
		Ok(Pid(pid)) =>
			if redis_is_owner!(socket_path, pid)? {
				stop_process!(pid, label)
			} else if process_is_alive!(pid)? {
				Err(BenchmarkFailed("refusing to signal pidfile process ${pid}: ownership of ${socket_path.display()} was not established"))
			} else {
				Ok({})
			}
		Ok(NoPid) => Ok({})
		Err(error) => Err(error)
	}

stop_subject_from_pidfile! : Path.Path => Try({}, [BenchmarkFailed(Str), ..])
stop_subject_from_pidfile! = |pid_path|
	match read_pid_if_present!(pid_path, "subject supervisor") {
		Ok(Pid(pid)) => stop_process_group!(pid, "subject supervisor")
		Ok(NoPid) => Ok({})
		Err(error) => Err(error)
	}

stop_process! : Str, Str => Try({}, [BenchmarkFailed(Str), ..])
stop_process! = |pid, label| {
	if !(process_is_alive!(pid)?) {
		Ok({})
	} else {
		term_result = signal_pid!(pid, "TERM", label)
		if wait_for_exit!(pid, 40)? {
			Ok({})
		} else {
			kill_result = signal_pid!(pid, "KILL", label)
			if wait_for_exit!(pid, 40)? {
				Ok({})
			} else {
				Err(BenchmarkFailed("${label} process ${pid} did not exit after SIGKILL; TERM=${describe_signal_result(term_result)}, KILL=${describe_signal_result(kill_result)}"))
			}
		}
	}
}

stop_process_group! : Str, Str => Try({}, [BenchmarkFailed(Str), ..])
stop_process_group! = |leader, label| {
	if !(process_group_is_alive!(leader)?) {
		Ok({})
	} else {
		term_result = signal_group!(leader, "TERM", label)
		if wait_for_group_exit!(leader, 40)? {
			Ok({})
		} else {
			kill_result = signal_group!(leader, "KILL", label)
			if wait_for_group_exit!(leader, 40)? {
				Ok({})
			} else {
				Err(BenchmarkFailed("${label} process group ${leader} did not exit after SIGKILL; TERM=${describe_signal_result(term_result)}, KILL=${describe_signal_result(kill_result)}"))
			}
		}
	}
}

signal_pid! : Str, Str, Str => Try({}, [BenchmarkFailed(Str), ..])
signal_pid! = |pid, signal, label| {
	outcome = run_bounded_output!("kill", ["-${signal}", pid])?
	if outcome.exit_code == 0 Ok({}) else Err(BenchmarkFailed("kill -${signal} ${pid} for ${label} exited ${outcome.exit_code.to_str()}${suffix_output(HarnessText.combine_output(outcome.stdout, outcome.stderr))}"))
}

signal_group! : Str, Str, Str => Try({}, [BenchmarkFailed(Str), ..])
signal_group! = |leader, signal, label| {
	outcome = run_bounded_output!("kill", ["-${signal}", "--", "-${leader}"])?
	if outcome.exit_code == 0 Ok({}) else Err(BenchmarkFailed("kill -${signal} -- -${leader} for ${label} exited ${outcome.exit_code.to_str()}${suffix_output(HarnessText.combine_output(outcome.stdout, outcome.stderr))}"))
}

describe_signal_result : Try({}, [BenchmarkFailed(Str), ..]) -> Str
describe_signal_result = |result|
	match result {
		Ok({}) => "ok"
		Err(error) => describe_error(error)
	}

wait_for_exit! : Str, U8 => Try(Bool, [BenchmarkFailed(Str), ..])
wait_for_exit! = |pid, attempts_remaining| {
	if !(process_is_alive!(pid)?) {
		Ok(Bool.True)
	} else if attempts_remaining == 0 {
		Ok(Bool.False)
	} else {
		Sleep.millis!(50)
		wait_for_exit!(pid, attempts_remaining - 1)
	}
}

wait_for_group_exit! : Str, U8 => Try(Bool, [BenchmarkFailed(Str), ..])
wait_for_group_exit! = |leader, attempts_remaining| {
	if !(process_group_is_alive!(leader)?) {
		Ok(Bool.True)
	} else if attempts_remaining == 0 {
		Ok(Bool.False)
	} else {
		Sleep.millis!(50)
		wait_for_group_exit!(leader, attempts_remaining - 1)
	}
}

process_is_alive! : Str => Try(Bool, [BenchmarkFailed(Str), ..])
process_is_alive! = |pid| {
	outcome = run_bounded_output!("kill", ["-0", pid])?
	Ok(outcome.exit_code == 0)
}

process_group_is_alive! : Str => Try(Bool, [BenchmarkFailed(Str), ..])
process_group_is_alive! = |leader| {
	outcome = run_bounded_output!("kill", ["-0", "--", "-${leader}"])?
	Ok(outcome.exit_code == 0)
}

ensure_process_active! : Str, Str => Try({}, [BenchmarkFailed(Str), ..])
ensure_process_active! = |pid, label| {
	if process_is_alive!(pid)? Ok({}) else Err(BenchmarkFailed("${label} process ${pid} is not running"))
}

ensure_watchdog_active! : RedisServer => Try({}, [BenchmarkFailed(Str), ..])
ensure_watchdog_active! = |redis| {
	ensure_process_active!(redis.watchdog_pid, "benchmark lifecycle watchdog")?
	if redis_is_owner!(redis.socket_path, redis.pid)? {
		Ok({})
	} else {
		Err(BenchmarkFailed("Redis process ${redis.pid} no longer owns ${redis.socket_path.display()}"))
	}
}

read_pid_if_present! : Path.Path, Str => Try([Pid(Str), NoPid], [BenchmarkFailed(Str), ..])
read_pid_if_present! = |pid_path, label|
	match pid_path.is_file!() {
		Ok(Bool.False) => Ok(NoPid)
		Ok(Bool.True) => {
			contents = pid_path.read_utf8!() ? |error| BenchmarkFailed("read ${label} pidfile: ${Str.inspect(error)}")
			pid = HarnessText.parse_pid_text(contents) ? |message| BenchmarkFailed("${label} wrote an invalid pidfile: ${message}")
			Ok(Pid(pid))
		}
		Err(error) => Err(BenchmarkFailed("inspect ${label} pidfile: ${Str.inspect(error)}"))
	}

parse_pid_text : Str -> Try(Str, Str)
parse_pid_text = |text| {
	pid = HarnessText.first_line(text)
	remaining = text.split_on("\n").drop_first(1)
	if HarnessText.valid_pid(pid) and remaining.all(|line| line.is_empty()) {
		Ok(pid)
	} else {
		Err("expected one positive process ID, received ${Str.inspect(text)}")
	}
}

random_port : U64, U8 -> U16
random_port = |seed, attempt| {
	seed_offset = seed % random_port_count
	attempt_offset = (U8.to_u64(attempt) * 7_919) % random_port_count
	offset = (seed_offset + attempt_offset) % random_port_count
	U64.to_u16_wrap(U16.to_u64(first_random_port) + offset)
}

run_bounded_output! : Str, List(Str) => Try(ProcessOutput, [BenchmarkFailed(Str), ..])
run_bounded_output! = |program, arguments|
	run_bounded_output_with_limit!(probe_timeout_seconds, program, arguments)

run_bounded_output_with_limit! : Str, Str, List(Str) => Try(ProcessOutput, [BenchmarkFailed(Str), ..])
run_bounded_output_with_limit! = |limit, program, arguments| {
	wrapped = ["--signal=TERM", "--kill-after=2s", limit, program].concat(arguments)
	match Cmd.new_str("timeout").args_str(wrapped).exec_output!() {
		Ok({ stdout_utf8, stderr_utf8_lossy }) => Ok({ exit_code: 0, stdout: stdout_utf8, stderr: stderr_utf8_lossy })
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) => {
			if exit_code == 124 or exit_code == 137 {
				Err(BenchmarkFailed("${program} timed out after ${limit}${suffix_output(HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy))}"))
			} else if exit_code == 125 or exit_code == 126 or exit_code == 127 {
				Err(BenchmarkFailed("GNU timeout could not invoke ${program} (exit ${exit_code.to_str()})${suffix_output(HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy))}"))
			} else {
				Ok({ exit_code, stdout: stdout_utf8_lossy, stderr: stderr_utf8_lossy })
			}
		}
		Err(error) => Err(BenchmarkFailed("execute ${program}: ${Str.inspect(error)}"))
	}
}

delete_if_present! : Path.Path => Try({}, [BenchmarkFailed(Str), ..])
delete_if_present! = |path| {
	exists = path.exists!() ? |error| BenchmarkFailed("inspect ${path.display()}: ${Str.inspect(error)}")
	if exists {
		path.delete!().map_err(|error| BenchmarkFailed("delete ${path.display()}: ${Str.inspect(error)}"))
	} else {
		Ok({})
	}
}

cleanup_launched_process! : Path.Path, Str, Str => Try({}, [BenchmarkFailed(Str), ..])
cleanup_launched_process! = |pid_path, captured_output, label| {
	captured_pid =
		match HarnessText.parse_pid_text(captured_output) {
			Ok(pid) => FoundPid(pid)
			Err(_) => MissingPid
		}
	pidfile_result = read_pid_if_present!(pid_path, label)
	pidfile_pid =
		match pidfile_result {
			Ok(Pid(pid)) => FoundPid(pid)
			_ => MissingPid
		}
	cleanup_result = cleanup_pid_pair!(captured_pid, pidfile_pid, label)
	match (pidfile_result, cleanup_result) {
		(Ok(_), Ok({})) => Ok({})
		(Err(error), Ok({})) => Err(BenchmarkFailed(describe_error(error)))
		(Ok(_), Err(error)) => Err(BenchmarkFailed(describe_error(error)))
		(Err(error), Err(cleanup_error)) => Err(BenchmarkFailed("${describe_error(error)}; process cleanup also failed: ${describe_error(cleanup_error)}"))
	}
}

cleanup_pid_pair! : [FoundPid(Str), MissingPid], [FoundPid(Str), MissingPid], Str => Try({}, [BenchmarkFailed(Str), ..])
cleanup_pid_pair! = |first, second, label|
	match (first, second) {
		(MissingPid, MissingPid) => Ok({})
		(FoundPid(pid), MissingPid) => stop_process!(pid, "captured ${label} process")
		(MissingPid, FoundPid(pid)) => stop_process!(pid, "pidfile ${label} process")
		(FoundPid(first_pid), FoundPid(second_pid)) if first_pid == second_pid => stop_process!(first_pid, "${label} process")
		(FoundPid(first_pid), FoundPid(second_pid)) => {
			first_result = stop_process!(first_pid, "captured ${label} process")
			second_result = stop_process!(second_pid, "pidfile ${label} process")
			combine_cleanup_results(first_result, second_result)
		}
	}

combine_cleanup_results : Try({}, [BenchmarkFailed(Str), ..]), Try({}, [BenchmarkFailed(Str), ..]) -> Try({}, [BenchmarkFailed(Str), ..])
combine_cleanup_results = |first, second|
	match (first, second) {
		(Ok({}), Ok({})) => Ok({})
		(Err(error), Ok({})) => Err(BenchmarkFailed(describe_error(error)))
		(Ok({}), Err(error)) => Err(BenchmarkFailed(describe_error(error)))
		(Err(first_error), Err(second_error)) => Err(BenchmarkFailed("${describe_error(first_error)}; ${describe_error(second_error)}"))
	}

combine_value_and_cleanup : Try(a, [BenchmarkFailed(Str), ..]), Try({}, [BenchmarkFailed(Str), ..]) -> Try(a, [BenchmarkFailed(Str), ..])
combine_value_and_cleanup = |value_result, cleanup_result|
	match (value_result, cleanup_result) {
		(Ok(value), Ok({})) => Ok(value)
		(Err(error), Ok({})) => Err(BenchmarkFailed(describe_error(error)))
		(Ok(_), Err(error)) => Err(BenchmarkFailed(describe_error(error)))
		(Err(error), Err(cleanup_error)) => Err(BenchmarkFailed("${describe_error(error)}; cleanup also failed: ${describe_error(cleanup_error)}"))
	}

fail_after_cleanup : Str, Try({}, [BenchmarkFailed(Str), ..]) -> Try(a, [BenchmarkFailed(Str), ..])
fail_after_cleanup = |message, cleanup_result|
	match cleanup_result {
		Ok({}) => Err(BenchmarkFailed(message))
		Err(error) => Err(BenchmarkFailed("${message}; cleanup also failed: ${describe_error(error)}"))
	}

read_log_best_effort! : Path.Path => Str
read_log_best_effort! = |path|
	match path.read_utf8!() {
		Ok(contents) => contents
		Err(error) => "<unavailable: ${Str.inspect(error)}>"
	}

suffix_output : Str -> Str
suffix_output = |output| if output.is_empty() "" else ":\n${output}"

describe_error : [BenchmarkFailed(Str), ..] -> Str
describe_error = |error|
	match error {
		BenchmarkFailed(message) => message
		other => Str.inspect(other)
	}

test_config : Config
test_config = { ..default_config, iterations: 10, warmup: 2, samples: 1, pipeline_batch: 4, timeout_ms: 50 }

test_subject : Subject
test_subject = { label: "redis-py", implementation: "python", expected_client_version: "8.1.0", executable: "/python", leading_args: ["benchmark.py"] }

test_provenance : Provenance
test_provenance = { nix_source_id: "abc123-source", build_mode: "dev", nix_system: "aarch64-darwin", os: "darwin", arch: "aarch64" }

test_record : Str, U64, U64 -> BenchmarkRecord
test_record = |workload, command_count, round_trip_count| {
	{
		schema,
		implementation: "python",
		client: "redis-py",
		client_version: "8.1.0",
		runtime_version: "3.13.7",
		redis_version: "8.10.1",
		timer: "monotonic",
		workload,
		sample: 1,
		samples: test_config.samples,
		iterations: test_config.iterations,
		warmup: test_config.warmup,
		pipeline_batch: test_config.pipeline_batch,
		operation_count: test_config.iterations,
		command_count,
		round_trip_count,
		elapsed_ns: 1_000,
		validated: Bool.True,
		nix_source_id: test_provenance.nix_source_id,
		build_mode: test_provenance.build_mode,
		nix_system: test_provenance.nix_system,
		os: test_provenance.os,
		arch: test_provenance.arch,
		order_rotation: test_config.order_rotation,
		subject_position: 2,
	}
}

test_records : List(BenchmarkRecord)
test_records = [
	test_record("ping_sequential", 10, 10),
	test_record("set_get_sequential", 20, 20),
	test_record("incr_sequential", 10, 10),
	test_record("ping_pipeline", 10, 3),
]

test_subjects : List(Subject)
test_subjects = [
	{ label: "roc-redis", implementation: "roc", expected_client_version: "0.1.0-dev", executable: "/roc", leading_args: [] },
	test_subject,
	{ label: "go-redis", implementation: "go", expected_client_version: "v9.22.0", executable: "/go", leading_args: [] },
]

test_record_json : Str
test_record_json = "{\"schema\":\"roc-redis-benchmark/v2\",\"implementation\":\"python\",\"client\":\"redis-py\",\"client_version\":\"8.1.0\",\"runtime_version\":\"3.13.7\",\"redis_version\":\"8.10.1\",\"nix_source_id\":\"abc123-source\",\"build_mode\":\"dev\",\"nix_system\":\"aarch64-darwin\",\"os\":\"darwin\",\"arch\":\"aarch64\",\"order_rotation\":0,\"subject_position\":2,\"timer\":\"monotonic\",\"workload\":\"ping_sequential\",\"sample\":1,\"samples\":1,\"iterations\":10,\"warmup\":2,\"pipeline_batch\":4,\"operation_count\":10,\"command_count\":10,\"round_trip_count\":10,\"elapsed_ns\":1000,\"validated\":true}"

expect parse_bounded_decimal("value", "0", 0, 10) == Ok(0)
expect parse_bounded_decimal("value", "10", 0, 10) == Ok(10)
expect ["", "-1", "+1", "1_0", "11"].all(|value| parse_bounded_decimal("value", value, 0, 10).is_err())
expect parse_options(["--iterations", "2000", "--warmup", "0", "--samples", "3", "--pipeline-batch", "64", "--timeout-ms", "9000"], default_config) == Ok({ ..default_config, iterations: 2000, warmup: 0, samples: 3, pipeline_batch: 64, timeout_ms: 9000 })
expect parse_options(["--jsonl", "results.jsonl"], default_config) == Ok({ ..default_config, jsonl: Jsonl("results.jsonl") })
expect parse_options(["--order-rotation", "2"], default_config) == Ok({ ..default_config, order_rotation: 2 })
expect parse_options(["--all-order-rotations"], default_config) == Ok({ ..default_config, all_order_rotations: Bool.True })
expect [["--iterations"], ["--samples", "0"], ["--unknown", "1"], ["--jsonl", ""], ["--order-rotation", "10"]].all(|args| parse_options(args, default_config).is_err())
expect parse_bounded_decimal("value", "18446744073709551616", 0, U64.highest).is_err()
expect ceiling_divide(1, 100) == 1
expect ceiling_divide(100, 100) == 1
expect ceiling_divide(101, 100) == 2
expect median([]) == Err("cannot calculate a median for an empty sample")
expect median([9]) == Ok(9)
expect median([9, 1, 5]) == Ok(5)
expect median([10, 2, 8, 4]) == Ok(6)
expect format_milliseconds(12_345_678) == "12.345"
expect HarnessText.valid_pid("2")
expect !(HarnessText.valid_pid("1"))
expect HarnessText.parse_pid_text("123\n") == Ok("123")
expect ["", "0", "1", "+2", "-2", "2_0", "18446744073709551616", "123\r\n", "123\n456\n"].all(|text| HarnessText.parse_pid_text(text).is_err())
expect random_port(0, 0) == 20_000
expect random_port(29_999, 0) == 49_999
expect increment_seed(41) == 42
expect increment_seed(U64.highest) == 0
expect strict_jsonl_lines("{}") == Ok(["{}"])
expect strict_jsonl_lines("{}\n") == Ok(["{}"])
expect ["", "\n", "\n{}\n", "{}\n\n", "{}\n\n{}\n"].all(|output| strict_jsonl_lines(output).is_err())
expect parse_records("${test_record_json}\n") == Ok([test_record("ping_sequential", 10, 10)])
expect parse_records("${test_record_json}\n\n").is_err()
expect validate_records(test_subject, test_records, test_config, "8.10.1", test_provenance, 2).is_ok()
expect validate_records(test_subject, test_records.drop_last(1), test_config, "8.10.1", test_provenance, 2).is_err()
expect validate_records(test_subject, test_records.set(0, { ..test_record("ping_sequential", 10, 10), client: "not-redis-py" })?, test_config, "8.10.1", test_provenance, 2).is_err()
expect validate_records(test_subject, test_records.set(0, { ..test_record("ping_sequential", 10, 10), client_version: "8.0.0" })?, test_config, "8.10.1", test_provenance, 2).is_err()
expect validate_records(test_subject, test_records.set(0, { ..test_record("ping_sequential", 10, 10), nix_source_id: "other-source" })?, test_config, "8.10.1", test_provenance, 2).is_err()
expect validate_records(test_subject, test_records.set(1, { ..test_record("set_get_sequential", 20, 20), command_count: 19 })?, test_config, "8.10.1", test_provenance, 2).is_err()
expect validate_records(test_subject, test_records.set(3, { ..test_record("ping_pipeline", 10, 3), round_trip_count: 2 })?, test_config, "8.10.1", test_provenance, 2).is_err()
expect validate_records(test_subject, test_records.set(0, { ..test_record("ping_sequential", 10, 10), elapsed_ns: 0 })?, test_config, "8.10.1", test_provenance, 2).is_err()
expect validate_records(test_subject, test_records, test_config, "8.8.2", test_provenance, 2).is_err()
expect HarnessText.redis_info_field("# Server\r\nprocess_id:42\r\nredis_version:8.10.1\r\n", "process_id") == Ok("42")
expect HarnessText.redis_info_field("process_id:420\n", "process_id") != Ok("42")
expect is_safe_version("8.10.1") and is_safe_version("8.10.1-rc1") and !(is_safe_version("bad version"))
expect rotate_subjects(test_subjects, 0).map_ok(|items| items.map(|item| item.implementation)) == Ok(["roc", "python", "go"])
expect rotate_subjects(test_subjects, 1).map_ok(|items| items.map(|item| item.implementation)) == Ok(["python", "go", "roc"])
expect rotate_subjects(test_subjects, 2).map_ok(|items| items.map(|item| item.implementation)) == Ok(["go", "roc", "python"])
expect rotate_subjects(test_subjects, 3).map_ok(|items| items.map(|item| item.implementation)) == Ok(["roc", "go", "python"])
expect rotate_subjects(test_subjects, 4).map_ok(|items| items.map(|item| item.implementation)) == Ok(["go", "python", "roc"])
expect rotate_subjects(test_subjects, 5).map_ok(|items| items.map(|item| item.implementation)) == Ok(["python", "roc", "go"])
expect rotate_subjects(test_subjects, 6).is_err()

expect {
	subjects = test_subjects.concat([
		{ label: "redis-rs", implementation: "rust", expected_client_version: "1.6.0", executable: "/rust", leading_args: [] },
		{ label: "hiredis", implementation: "c", expected_client_version: "1.4.1", executable: "/c", leading_args: [] },
	])
	plan = plan_rotations(subjects, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])?
	plan.len() == 50 and subjects.all(|subject| [1, 2, 3, 4, 5].all(|position| plan.keep_if(|item| item.subject.implementation == subject.implementation and item.subject_position == position).len() == 2))
}
expect plan_rotations(test_subjects, [0, 1, 2, 3, 4, 5]).map_ok(|items| items.map(|item| "${item.order_rotation.to_str()}:${item.subject_position.to_str()}:${item.subject.implementation}")) == Ok(["0:1:roc", "0:2:python", "0:3:go", "1:1:python", "1:2:go", "1:3:roc", "2:1:go", "2:2:roc", "2:3:python", "3:1:roc", "3:2:go", "3:3:python", "4:1:go", "4:2:python", "4:3:roc", "5:1:python", "5:2:roc", "5:3:go"])
expect benchmark_prefix("roc", U64.highest, 0, 1) != benchmark_prefix("roc", 0, 3, 1)
expect rate_per_second(2_000_000_000, 1) == Ok(2_000_000_000_000_000_000)
expect rate_per_second(U64.highest, 1).is_err()
expect rate_per_second(1, 0).is_err()
expect watchdog_launch_script.contains("--kill-after=1s") and watchdog_launch_script.contains("tr -d '\\r' | \"$GREP_PROGRAM\" -Fqx") and watchdog_wrapper_script.contains("--kill-after=2s") and subject_wrapper_script.contains("SUBJECT_PIDFILE")
