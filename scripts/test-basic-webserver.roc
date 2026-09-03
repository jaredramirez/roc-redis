## Build the basic-webserver adapter, start isolated Redis and HTTP services,
## verify a nonce-bearing request end to end, and tear everything down.
##
## The existing small, fixed `sh -c` programs remain the qualified bridges for background
## launch and parent-death supervision. Adopting basic-cli's newer native resource
## APIs is a separate lifecycle refactor. Runtime values travel through
## environment variables rather than being interpolated into shell source.
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
import pf.Stdout

build_timeout_seconds : Str
build_timeout_seconds = "120"

service_launch_timeout_seconds : Str
service_launch_timeout_seconds = "10"

shell_launch_timeout_seconds_value : U64
shell_launch_timeout_seconds_value = 5

shell_launch_timeout_seconds : Str
shell_launch_timeout_seconds = shell_launch_timeout_seconds_value.to_str()

first_random_port : U16
first_random_port = 20_000

random_port_count : U64
random_port_count = 30_000

port_attempts : U8
port_attempts = 20

redis_readiness_attempts : U8
redis_readiness_attempts = 40

web_readiness_attempts : U8
web_readiness_attempts = 20

watchdog_poll_millis : U64
watchdog_poll_millis = 50

web_identity_probe_bound_millis : U64
web_identity_probe_bound_millis = 2_000

web_watchdog_pid_attempts : U64
web_watchdog_pid_attempts = 120

web_watchdog_owner_attempts : U64
web_watchdog_owner_attempts = 40

web_watchdog_signal_attempts : U64
web_watchdog_signal_attempts = 40

web_endpoint_absence_probes : U64
web_endpoint_absence_probes = 2

dependent_completion_attempts : U64
dependent_completion_attempts = 2_200

web_watchdog_cleanup_bound_millis : U64
web_watchdog_cleanup_bound_millis = web_watchdog_pid_attempts * watchdog_poll_millis + web_watchdog_owner_attempts * (web_identity_probe_bound_millis + watchdog_poll_millis) + 2 * web_identity_probe_bound_millis + 2 * web_watchdog_signal_attempts * watchdog_poll_millis + web_endpoint_absence_probes * web_identity_probe_bound_millis + watchdog_poll_millis

RedisServer : { pid : Str, port : U16, watchdog_pid : Str }

WebServer : {
	cleanup_safe_path : Path.Path,
	identity_body : Path.Path,
	identity_pid_path : Path.Path,
	identity_target : Str,
	log_path : Path.Path,
	pid : Str,
	pid_path : Path.Path,
	port : U16,
	watchdog_pid : Str,
}

web_launch_script : Str
web_launch_script = "set -eu; sh -c 'set -eu; printf \"%s\\n\" \"$$\" >\"$WEB_PIDFILE\"; exec \"$WEB_BINARY\" </dev/null >\"$WEB_LOG\" 2>&1' & child=$!; printf '%s\\n' \"$child\""

redis_watchdog_script : Str
redis_watchdog_script = Str.join_with(
	[
		"set -eu;",
		"safe_pid() { case \"$1\" in ''|*[!0-9]*) return 1;;",
		"esac;",
		"[ \"$1\" -gt 1 ] 2>/dev/null;",
		"};",
		"context_is_owned() { case \"$TEST_DIR\" in \"$TEMP_ROOT\"/roc-redis-webserver-integration-*) ;;",
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
		"info=$(\"$TIMEOUT_PROGRAM\" --signal=TERM --kill-after=1s 1s \"$REDIS_CLI\" --raw -t 0.5 -h 127.0.0.1 -p \"$SERVICE_PORT\" INFO server 2>/dev/null) || return 1;",
		"info=$(printf '%s' \"$info\" | tr -d '\\r');",
		"nl='\n';",
		"case \"$nl$info$nl\" in *\"$nl\"\"process_id:$candidate\"\"$nl\"*) return 0;;",
		"*) return 1;;",
		"esac;",
		"};",
		"redis_endpoint_absent() { status=0;",
		"\"$TIMEOUT_PROGRAM\" --signal=TERM --kill-after=1s 1s \"$REDIS_CLI\" --raw -t 0.5 -h 127.0.0.1 -p \"$SERVICE_PORT\" PING >/dev/null 2>&1 || status=$?;",
		"[ \"$status\" -eq 1 ] || return 1;",
		"sleep 0.05;",
		"status=0;",
		"\"$TIMEOUT_PROGRAM\" --signal=TERM --kill-after=1s 1s \"$REDIS_CLI\" --raw -t 0.5 -h 127.0.0.1 -p \"$SERVICE_PORT\" PING >/dev/null 2>&1 || status=$?;",
		"[ \"$status\" -eq 1 ];",
		"};",
		"wait_for_dependent_watchdog() { dependent_safe=0;",
		"if [ ! -e \"$DEPENDENT_LAUNCH_MARKER\" ];",
		"then dependent_safe=1;",
		"return;",
		"fi;",
		"attempt=0;",
		"while [ \"$attempt\" -lt ${dependent_completion_attempts.to_str()} ];",
		"do completed=;",
		"if [ -r \"$DEPENDENT_CLEANUP_SAFE\" ];",
		"then IFS= read -r completed <\"$DEPENDENT_CLEANUP_SAFE\" || completed=;",
		"fi;",
		"if [ \"$completed\" = safe ];",
		"then dependent_safe=1;",
		"return;",
		"fi;",
		"sleep 0.05;",
		"attempt=$((attempt + 1));",
		"done;",
		"};",
		"(while kill -0 \"$HARNESS_PID\" 2>/dev/null && [ ! -e \"$CLEANUP_REQUEST\" ];",
		"do sleep 0.1;",
		"done;",
		"context_is_owned || exit 0;",
		"if [ ! -e \"$CLEANUP_REQUEST\" ];",
		"then wait_for_dependent_watchdog;",
		"[ \"$dependent_safe\" -eq 1 ] || exit 0;",
		"fi;",
		"limit=300;",
		"if [ -e \"$CLEANUP_REQUEST\" ];",
		"then limit=100;",
		"fi;",
		"owned=0;",
		"child=;",
		"attempt=0;",
		"while [ \"$attempt\" -lt \"$limit\" ];",
		"do child=;",
		"if [ -r \"$CHILD_PIDFILE\" ];",
		"then IFS= read -r child <\"$CHILD_PIDFILE\" || child=;",
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
		"then rm -f -- \"$CHILD_PIDFILE\" \"$WATCHDOG_PIDFILE\" \"$CLEANUP_REQUEST\" \"$PENDING_ACK\";",
		"fi) </dev/null >/dev/null 2>&1 &",
		"watchdog=$!;",
		"printf '%s\\n' \"$watchdog\" >\"$WATCHDOG_PIDFILE\";",
		"printf '%s\\n' \"$watchdog\"",
	],
	" ",
)

web_watchdog_script : Str
web_watchdog_script = Str.join_with(
	[
		"set -eu;",
		"safe_pid() { case \"$1\" in ''|*[!0-9]*) return 1;;",
		"esac;",
		"[ \"$1\" -gt 1 ] 2>/dev/null;",
		"};",
		"context_is_owned() { case \"$TEST_DIR\" in \"$TEMP_ROOT\"/roc-redis-webserver-integration-*) ;;",
		"*) return 1;;",
		"esac;",
		"owner=;",
		"if [ -r \"$OWNER_FILE\" ];",
		"then IFS= read -r owner <\"$OWNER_FILE\" || owner=;",
		"fi;",
		"[ \"$owner\" = \"$HARNESS_PID\" ];",
		"};",
		"web_is_owner() { candidate=$1;",
		"safe_pid \"$candidate\" || return 1;",
		"context_is_owned || return 1;",
		"child=;",
		"if [ -r \"$CHILD_PIDFILE\" ];",
		"then IFS= read -r child <\"$CHILD_PIDFILE\" || child=;",
		"fi;",
		"[ \"$child\" = \"$candidate\" ] && kill -0 \"$candidate\" 2>/dev/null || return 1;",
		"status=$(\"$TIMEOUT_PROGRAM\" --signal=TERM --kill-after=1s 1s \"$CURL_PROGRAM\" --noproxy '*' --silent --show-error --connect-timeout 0.2 --max-time 0.5 --output \"$IDENTITY_BODY\" --write-out '%{http_code}' \"$IDENTITY_URL\" 2>/dev/null) || return 1;",
		"body=$(cat \"$IDENTITY_BODY\") || return 1;",
		"child=;",
		"if [ -r \"$CHILD_PIDFILE\" ];",
		"then IFS= read -r child <\"$CHILD_PIDFILE\" || child=;",
		"fi;",
		"[ \"$status\" = 200 ] && [ \"$body\" = \"$IDENTITY_TARGET\" ] && [ \"$child\" = \"$candidate\" ] && kill -0 \"$candidate\" 2>/dev/null;",
		"};",
		"web_endpoint_absent() { status=0;",
		"\"$TIMEOUT_PROGRAM\" --signal=TERM --kill-after=1s 1s \"$CURL_PROGRAM\" --noproxy '*' --silent --show-error --connect-timeout 0.2 --max-time 0.5 --output /dev/null \"$IDENTITY_URL\" >/dev/null 2>&1 || status=$?;",
		"[ \"$status\" -eq 7 ] || return 1;",
		"sleep 0.05;",
		"status=0;",
		"\"$TIMEOUT_PROGRAM\" --signal=TERM --kill-after=1s 1s \"$CURL_PROGRAM\" --noproxy '*' --silent --show-error --connect-timeout 0.2 --max-time 0.5 --output /dev/null \"$IDENTITY_URL\" >/dev/null 2>&1 || status=$?;",
		"[ \"$status\" -eq 7 ];",
		"};",
		"(while kill -0 \"$HARNESS_PID\" 2>/dev/null;",
		"do sleep 0.1;",
		"done;",
		"child=;",
		"attempt=0;",
		"while [ \"$attempt\" -lt ${web_watchdog_pid_attempts.to_str()} ];",
		"do child=;",
		"if [ -r \"$CHILD_PIDFILE\" ];",
		"then IFS= read -r child <\"$CHILD_PIDFILE\" || child=;",
		"fi;",
		"if safe_pid \"$child\" && kill -0 \"$child\" 2>/dev/null;",
		"then break;",
		"fi;",
		"printf 'pending\\n' >\"$PENDING_ACK\";",
		"sleep 0.05;",
		"attempt=$((attempt + 1));",
		"done;",
		"owned=0;",
		"attempt=0;",
		"while [ \"$attempt\" -lt ${web_watchdog_owner_attempts.to_str()} ];",
		"do child=;",
		"if [ -r \"$CHILD_PIDFILE\" ];",
		"then IFS= read -r child <\"$CHILD_PIDFILE\" || child=;",
		"fi;",
		"if ! safe_pid \"$child\";",
		"then printf 'pending\\n' >\"$PENDING_ACK\";",
		"fi;",
		"if safe_pid \"$child\" && kill -0 \"$child\" 2>/dev/null && web_is_owner \"$child\";",
		"then owned=1;",
		"break;",
		"fi;",
		"sleep 0.05;",
		"attempt=$((attempt + 1));",
		"done;",
		"preserve=1;",
		"if [ \"$owned\" -eq 1 ];",
		"then if kill -0 \"$child\" 2>/dev/null && web_is_owner \"$child\";",
		"then kill -TERM \"$child\" 2>/dev/null || true;",
		"attempt=0;",
		"while kill -0 \"$child\" 2>/dev/null && [ \"$attempt\" -lt ${web_watchdog_signal_attempts.to_str()} ];",
		"do sleep 0.05;",
		"attempt=$((attempt + 1));",
		"done;",
		"if kill -0 \"$child\" 2>/dev/null && web_is_owner \"$child\";",
		"then kill -KILL \"$child\" 2>/dev/null || true;",
		"attempt=0;",
		"while kill -0 \"$child\" 2>/dev/null && [ \"$attempt\" -lt ${web_watchdog_signal_attempts.to_str()} ];",
		"do sleep 0.05;",
		"attempt=$((attempt + 1));",
		"done;",
		"fi;",
		"fi;",
		"if ! kill -0 \"$child\" 2>/dev/null && web_endpoint_absent;",
		"then preserve=0;",
		"fi;",
		"fi;",
		"if [ \"$preserve\" -eq 0 ] && context_is_owned;",
		"then printf 'safe\\n' >\"$CLEANUP_SAFE\";",
		"rm -f -- \"$CHILD_PIDFILE\" \"$WATCHDOG_PIDFILE\" \"$IDENTITY_BODY\" \"$IDENTITY_PIDFILE\" \"$PENDING_ACK\";",
		"fi) </dev/null >/dev/null 2>&1 &",
		"watchdog=$!;",
		"printf '%s\\n' \"$watchdog\" >\"$WATCHDOG_PIDFILE\";",
		"printf '%s\\n' \"$watchdog\"",
	],
	" ",
)

main! : List(OsStr) => Try({}, [HarnessFailed(Str), Exit(I32), ..])
main! = |args| {
	backend = test_backend!({})?
	validate_environment!(args)?
	harness_pid = capture_harness_pid!({})?
	test_dir = create_test_dir!() ? |error| HarnessFailed("create temporary directory: ${Str.inspect(error)}")

	result = run_in_directory!(test_dir, harness_pid, backend)
	delete_result = remove_test_directory_if_idle!(test_dir)

	match (result, delete_result) {
		(Ok({ redis_port, web_port }), Ok({})) =>
			Stdout.line!("basic-webserver integration passed (HTTP ${web_port.to_str()} -> Redis ${redis_port.to_str()}; subject_backend=${backend})")
				.map_err(|error| HarnessFailed("write success message: ${Str.inspect(error)}"))
		(Err(error), Ok({})) => Err(error)
		(Ok(_), Err(error)) => Err(HarnessFailed("remove ${test_dir.display()}: ${Str.inspect(error)}"))
		(Err(error), Err(delete_error)) =>
			Err(HarnessFailed("${describe_harness_error(error)}; also failed to remove ${test_dir.display()}: ${Str.inspect(delete_error)}"))
		}
}

test_backend! : {} => Try(Str, [HarnessFailed(Str), ..])
test_backend! = |_| match Env.var_str!(OsStr.from_str("ROC_REDIS_TEST_BACKEND")) {
	Ok("dev") => Ok("dev")
	Ok("speed") => Ok("speed")
	Ok("size") => Ok("size")
	Ok(value) => Err(HarnessFailed("ROC_REDIS_TEST_BACKEND must be dev, speed, or size; received ${Str.inspect(value)}"))
	Err(VarNotFound(_)) => Ok("dev")
	Err(error) => Err(HarnessFailed("read ROC_REDIS_TEST_BACKEND: ${Str.inspect(error)}"))
}

remove_test_directory_if_idle! : Path.Path => Try({}, [HarnessFailed(Str), ..])
remove_test_directory_if_idle! = |test_dir| {
	active = any_pidfile_process_alive!([
		test_dir.join("redis.pid"),
		test_dir.join("redis-watchdog.pid"),
		test_dir.join("web.pid"),
		test_dir.join("web-watchdog.pid"),
	])?
	cleanup_requested = test_dir.join("redis-cleanup.request").exists!() ? |error| HarnessFailed("inspect Redis cleanup request: ${Str.inspect(error)}")
	if active or cleanup_requested {
		Err(HarnessFailed("refusing to remove ${test_dir.display()}: a service or watchdog PID is still active; identity evidence was preserved"))
	} else {
		test_dir.delete_all!().map_err(|error| HarnessFailed("remove ${test_dir.display()}: ${Str.inspect(error)}"))
	}
}

any_pidfile_process_alive! : List(Path.Path) => Try(Bool, [HarnessFailed(Str), ..])
any_pidfile_process_alive! = |paths|
	match paths {
		[] => Ok(Bool.False)
		[path, .. as rest] =>
			match read_pid_if_present!(path, "cleanup identity") {
				Ok(Pid(pid)) if process_is_alive!(pid) => Ok(Bool.True)
				Ok(_) => any_pidfile_process_alive!(rest)
				Err(error) => Err(error)
			}
		}

validate_environment! : List(OsStr) => Try({}, [HarnessFailed(Str), ..])
validate_environment! = |args| {
	match args.drop_first(1) {
		[] => {}
		_ => return Err(HarnessFailed("usage: roc scripts/test-basic-webserver.roc"))
	}

	match Env.platform!().os {
		LINUX => {}
		MACOS => {}
		other => return Err(HarnessFailed("the integration harness requires a POSIX host, not ${Str.inspect(other)}"))
	}

	require_commands!(["roc", "redis-server", "redis-cli", "curl", "timeout", "sh", "kill", "sleep", "tr", "cat", "chmod"])?

	source = Path.utf8("integration/basic_webserver.roc")
	source_exists = source.is_file!() ? |error| HarnessFailed("inspect ${source.display()}: ${Str.inspect(error)}")
	if source_exists {
		Ok({})
	} else {
		Err(HarnessFailed("run this command from the roc-redis repository root; integration/basic_webserver.roc was not found"))
	}
}

capture_harness_pid! : {} => Try(Str, [HarnessFailed(Str), ..])
capture_harness_pid! = |_| {
	# This shell is spawned directly by basic-cli, so its parent is the running
	# Roc harness (not the compiler process which originally built it).
	match Cmd.new_str("sh").args_str(["-c", "printf '%s\\n' \"$PPID\""]).exec_output!() {
		Ok({ stdout_utf8, .. }) =>
			HarnessText.parse_pid_text(stdout_utf8).map_err(|message| HarnessFailed("capture harness PID: ${message}"))
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) =>
			Err(HarnessFailed("capture harness PID exited ${exit_code.to_str()}${suffix_output(HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy))}"))
		Err(error) => Err(HarnessFailed("capture harness PID: ${Str.inspect(error)}"))
	}
}

require_commands! : List(Str) => Try({}, [HarnessFailed(Str), ..])
require_commands! = |commands| {
	missing = missing_commands!(commands)
	if missing.is_empty() {
		Ok({})
	} else {
		Err(HarnessFailed("required commands not found: ${Str.join_with(missing, ", ")}"))
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

create_test_dir! : () => Try(Path.Path, _)
create_test_dir! = || create_test_dir_with_attempts!(5)

create_test_dir_with_attempts! : U8 => Try(Path.Path, _)
create_test_dir_with_attempts! = |attempts_remaining| {
	seed = Random.seed_u64!()?
	path = Env.temp_dir!().join("roc-redis-webserver-integration-${seed.to_str()}")
	match path.create_dir!() {
		Ok({}) => {
			match make_directory_private!(path) {
				Ok({}) => Ok(path)
				Err(error) => {
					_ = path.delete_all!()
					Err(error)
				}
			}
		}
		Err(PathErr(AlreadyExists, _)) if attempts_remaining > 1 =>
			create_test_dir_with_attempts!(attempts_remaining - 1)
		Err(error) => Err(error)
	}
}

make_directory_private! : Path.Path => Try({}, [HarnessFailed(Str), ..])
make_directory_private! = |path| {
	exit_code = Cmd.new_str("chmod")
		.arg_str("700")
		.arg(path.to_os_str())
		.exec_exit_code!() ? |error| HarnessFailed("make temporary directory private: ${Str.inspect(error)}")
	if exit_code == 0 Ok({}) else Err(HarnessFailed("chmod 700 ${path.display()} exited ${exit_code.to_str()}"))
}

run_in_directory! : Path.Path, Str, Str => Try({ redis_port : U16, web_port : U16 }, [HarnessFailed(Str), ..])
run_in_directory! = |test_dir, harness_pid, backend| {
	owner_path = test_dir.join("harness.owner")
	owner_path.write_utf8!("${harness_pid}\n") ? |error| HarnessFailed("write harness ownership marker: ${Str.inspect(error)}")
	web_binary = build_web_app!(test_dir, backend)?
	redis_seed = Random.seed_u64!() ? |error| HarnessFailed("choose Redis port: ${Str.inspect(error)}")
	redis = start_redis!(test_dir, harness_pid, redis_seed, 0)?

	web_result = run_with_web!(test_dir, web_binary, harness_pid, redis)
	redis_stop_result = stop_redis!(redis)

	match (web_result, redis_stop_result) {
		(Ok(web_port), Ok({})) => Ok({ redis_port: redis.port, web_port })
		(Err(error), Ok({})) => Err(error)
		(Ok(_), Err(error)) => Err(error)
		(Err(error), Err(stop_error)) =>
			Err(HarnessFailed("${describe_harness_error(error)}; Redis cleanup also failed: ${describe_harness_error(stop_error)}"))
		}
}

build_web_app! : Path.Path, Str => Try(Path.Path, [HarnessFailed(Str), ..])
build_web_app! = |test_dir, backend| {
	web_binary = test_dir.join("basic-webserver-integration")
	command =
		Cmd.new_str("timeout")
			.args_str([
				build_timeout_seconds,
				"roc",
				"build",
				"--opt=${backend}",
				"--output=${web_binary.display()}",
				"integration/basic_webserver.roc",
			])

	require_command_success!("build basic-webserver integration", command)?
	is_executable = web_binary.is_executable!() ? |error| HarnessFailed("inspect built webserver binary: ${Str.inspect(error)}")
	if is_executable {
		Ok(web_binary)
	} else {
		Err(HarnessFailed("roc build succeeded without creating an executable at ${web_binary.display()}"))
	}
}

require_command_success! : Str, Cmd.Cmd => Try({}, [HarnessFailed(Str), ..])
require_command_success! = |label, command| {
	match command.exec_output!() {
		Ok(_) => Ok({})
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) => {
			output = HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy)
			if exit_code == 124 or exit_code == 137 {
				Err(HarnessFailed("${label} exceeded ${build_timeout_seconds}s${suffix_output(output)}"))
			} else {
				Err(HarnessFailed("${label} exited ${exit_code.to_str()}${suffix_output(output)}"))
			}
		}
		Err(error) => Err(HarnessFailed("${label} could not start: ${Str.inspect(error)}"))
	}
}

start_redis! : Path.Path, Str, U64, U8 => Try(RedisServer, [HarnessFailed(Str), ..])
start_redis! = |test_dir, harness_pid, seed, attempt| {
	if attempt >= port_attempts {
		Err(HarnessFailed("could not start isolated Redis after ${port_attempts.to_str()} port attempts; last log: ${read_log_best_effort!(test_dir.join("redis.log"))}"))
	} else {
		port = random_port(seed, attempt)
		match start_redis_candidate!(test_dir, harness_pid, port) {
			Ok(StartedRedis(server)) => Ok(server)
			Ok(RedisUnavailable) => start_redis!(test_dir, harness_pid, seed, attempt + 1)
			Err(error) => Err(error)
		}
	}
}

start_redis_candidate! : Path.Path, Str, U16 => Try([StartedRedis(RedisServer), RedisUnavailable], [HarnessFailed(Str), ..])
start_redis_candidate! = |test_dir, harness_pid, port| {
	pid_path = test_dir.join("redis.pid")
	log_path = test_dir.join("redis.log")
	cleanup_request_path = test_dir.join("redis-cleanup.request")
	delete_if_present!(pid_path)?
	delete_if_present!(cleanup_request_path)?
	watchdog_pid = launch_watchdog!(test_dir, test_dir.join("redis-watchdog.pid"), harness_pid, pid_path, port, "", test_dir.join("redis-watchdog-body"), "Redis", RedisWatchdog)?
	ensure_process_active!(watchdog_pid, "Redis parent-death watchdog")?

	command =
		Cmd.new_str("timeout")
			.args_str([
				service_launch_timeout_seconds,
				"redis-server",
				"--bind",
				"127.0.0.1",
				"--protected-mode",
				"yes",
				"--port",
				port.to_str(),
				"--save",
				"",
				"--appendonly",
				"no",
				"--daemonize",
				"yes",
				"--supervised",
				"no",
				"--dir",
			])
			.arg(test_dir.to_os_str())
			.arg_str("--pidfile")
			.arg(pid_path.to_os_str())
			.arg_str("--logfile")
			.arg(log_path.to_os_str())
			.args_str(["--loglevel", "warning"])

	exit_result = command.exec_exit_code!()
	match exit_result {
		Err(error) => fail_redis_start_after_cleanup!("launch redis-server: ${Str.inspect(error)}", port, pid_path, cleanup_request_path, watchdog_pid)
		Ok(exit_code) => finish_redis_start!(exit_code, port, pid_path, cleanup_request_path, watchdog_pid)
	}
}

finish_redis_start! : I32, U16, Path.Path, Path.Path, Str => Try([StartedRedis(RedisServer), RedisUnavailable], [HarnessFailed(Str), ..])
finish_redis_start! = |exit_code, port, pid_path, cleanup_request_path, watchdog_pid| {
	if exit_code == 124 or exit_code == 137 {
		fail_redis_start_after_cleanup!("redis-server launch exceeded ${service_launch_timeout_seconds}s", port, pid_path, cleanup_request_path, watchdog_pid)
	} else if exit_code == 125 or exit_code == 126 or exit_code == 127 {
		fail_redis_start_after_cleanup!("could not invoke redis-server through GNU timeout (exit ${exit_code.to_str()})", port, pid_path, cleanup_request_path, watchdog_pid)
	} else if exit_code != 0 {
		cleanup_result = cleanup_failed_redis_candidate!(port, pid_path, cleanup_request_path, watchdog_pid)
		match cleanup_result {
			Ok({}) => Ok(RedisUnavailable)
			Err(error) => Err(error)
		}
	} else {
		match wait_for_redis_owner!(port, pid_path, watchdog_pid, redis_readiness_attempts) {
			Ok(RedisReady(pid)) => Ok(StartedRedis({ pid, port, watchdog_pid }))
			Ok(RedisNotReady) => {
				cleanup_result = cleanup_failed_redis_candidate!(port, pid_path, cleanup_request_path, watchdog_pid)
				match cleanup_result {
					Ok({}) => Ok(RedisUnavailable)
					Err(error) => Err(error)
				}
			}
			Err(error) => {
				cleanup_result = cleanup_failed_redis_candidate!(port, pid_path, cleanup_request_path, watchdog_pid)
				match cleanup_result {
					Ok({}) => Err(error)
					Err(cleanup_error) => Err(HarnessFailed("${describe_harness_error(error)}; cleanup also failed: ${describe_harness_error(cleanup_error)}"))
				}
			}
		}
	}
}

fail_redis_start_after_cleanup! : Str, U16, Path.Path, Path.Path, Str => Try(a, [HarnessFailed(Str), ..])
fail_redis_start_after_cleanup! = |message, port, pid_path, cleanup_request_path, watchdog_pid|
	fail_after_cleanup(message, cleanup_failed_redis_candidate!(port, pid_path, cleanup_request_path, watchdog_pid))

cleanup_failed_redis_candidate! : U16, Path.Path, Path.Path, Str => Try({}, [HarnessFailed(Str), ..])
cleanup_failed_redis_candidate! = |port, pid_path, cleanup_request_path, watchdog_pid| {
	match read_pid_if_present!(pid_path, "Redis") {
		Ok(NoPid) => request_watchdog_cleanup!(port, cleanup_request_path, pid_path, watchdog_pid, "Redis")
		Ok(Pid(pid)) => {
			redis_result = stop_redis_process!(port, pid, "Redis")
			match redis_result {
				Ok({}) => stop_process!(watchdog_pid, "Redis parent-death watchdog")
				Err(error) => finish_watchdog_takeover!(error, port, cleanup_request_path, pid_path, watchdog_pid, "Redis")
			}
		}
		Err(error) => finish_watchdog_takeover!(error, port, cleanup_request_path, pid_path, watchdog_pid, "Redis")
	}
}

finish_watchdog_takeover! : [HarnessFailed(Str), ..], U16, Path.Path, Path.Path, Str, Str => Try({}, [HarnessFailed(Str), ..])
finish_watchdog_takeover! = |original_error, port, cleanup_request_path, pid_path, watchdog_pid, label| {
	watchdog_result = request_watchdog_cleanup!(port, cleanup_request_path, pid_path, watchdog_pid, label)
	match watchdog_result {
		Ok({}) => Ok({})
		Err(watchdog_error) => Err(HarnessFailed("${describe_harness_error(original_error)}; watchdog takeover also failed: ${describe_harness_error(watchdog_error)}"))
	}
}

request_watchdog_cleanup! : U16, Path.Path, Path.Path, Str, Str => Try({}, [HarnessFailed(Str), ..])
request_watchdog_cleanup! = |port, cleanup_request_path, child_pid_path, watchdog_pid, label| {
	cleanup_request_path.write_utf8!("cleanup\n") ? |error| HarnessFailed("request ${label} watchdog cleanup: ${Str.inspect(error)}")
	if !(wait_for_exit!(watchdog_pid, 500)) {
		Err(HarnessFailed("${label} parent-death watchdog ${watchdog_pid} did not finish requested startup cleanup"))
	} else {
		endpoint_absent = redis_endpoint_absent!(port)?
		match read_pid_if_present!(child_pid_path, label) {
			Ok(Pid(pid)) if process_is_alive!(pid) => Err(HarnessFailed("${label} process ${pid} remained active after requested watchdog cleanup"))
			Ok(_) if endpoint_absent => Ok({})
			Ok(_) => Err(HarnessFailed("${label} endpoint ${port.to_str()} still responds after requested watchdog cleanup; identity evidence was preserved"))
			Err(error) => Err(error)
		}
	}
}

wait_for_redis_owner! : U16, Path.Path, Str, U8 => Try([RedisReady(Str), RedisNotReady], [HarnessFailed(Str), ..])
wait_for_redis_owner! = |port, pid_path, watchdog_pid, attempts_remaining| {
	if attempts_remaining == 0 {
		Ok(RedisNotReady)
	} else if !(process_is_alive!(watchdog_pid)) {
		Err(HarnessFailed("Redis parent-death watchdog ${watchdog_pid} exited during startup"))
	} else {
		match read_startup_pid_if_present!(pid_path, "Redis") {
			Ok(Pid(pid)) =>
				if redis_is_owner!(port, pid) {
					Ok(RedisReady(pid))
				} else {
					Sleep.millis!(50)
					wait_for_redis_owner!(port, pid_path, watchdog_pid, attempts_remaining - 1)
				}
			Ok(NoPid) => {
				Sleep.millis!(50)
				wait_for_redis_owner!(port, pid_path, watchdog_pid, attempts_remaining - 1)
			}
			Err(error) => Err(error)
		}
	}
}

read_startup_pid_if_present! : Path.Path, Str => Try([Pid(Str), NoPid], [HarnessFailed(Str), ..])
read_startup_pid_if_present! = |pid_path, label| {
	match pid_path.is_file!() {
		Ok(Bool.False) => Ok(NoPid)
		Ok(Bool.True) => {
			contents = pid_path.read_utf8!() ? |error| HarnessFailed("read ${label} startup pidfile: ${Str.inspect(error)}")
			match startup_pid_state(contents) {
				PendingPid => Ok(NoPid)
				ReadyPid(pid) => Ok(Pid(pid))
				# Redis owns this file and may still be completing its tiny write.
				# Startup retries any incomplete contents; strict cleanup does not.
				InvalidPid(_) => Ok(NoPid)
			}
		}
		Err(error) => Err(HarnessFailed("inspect ${label} startup pidfile: ${Str.inspect(error)}"))
	}
}

StartupPidState : [InvalidPid(Str), PendingPid, ReadyPid(Str)]

startup_pid_state : Str -> StartupPidState
startup_pid_state = |contents| {
	if contents.trim().is_empty() {
		PendingPid
	} else {
		match parse_pidfile_text(contents) {
			Ok(pid) => ReadyPid(pid)
			Err(message) => InvalidPid(message)
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

wait_for_published_pid! : Path.Path, Str, U8 => Try([Pid(Str), NoPid], [HarnessFailed(Str), ..])
wait_for_published_pid! = |pid_path, label, attempts_remaining| {
	if attempts_remaining == 0 {
		read_pid_if_present!(pid_path, label)
	} else {
		match read_startup_pid_if_present!(pid_path, label) {
			Ok(Pid(pid)) => Ok(Pid(pid))
			Ok(NoPid) => {
				Sleep.millis!(10)
				wait_for_published_pid!(pid_path, label, attempts_remaining - 1)
			}
			Err(error) => Err(error)
		}
	}
}

WatchdogKind : [RedisWatchdog, WebWatchdog]

launch_watchdog! : Path.Path, Path.Path, Str, Path.Path, U16, Str, Path.Path, Str, WatchdogKind => Try(Str, [HarnessFailed(Str), ..])
launch_watchdog! = |test_dir, pid_path, harness_pid, child_pid_path, service_port, identity_target, identity_body, label, kind| {
	delete_if_present!(pid_path)?
	pending_ack_path = match kind {
		RedisWatchdog => test_dir.join("redis-pid.pending")
		WebWatchdog => test_dir.join("web-pid.pending")
	}
	delete_if_present!(pending_ack_path)?
	script = match kind {
		RedisWatchdog => redis_watchdog_script
		WebWatchdog => web_watchdog_script
	}
	cleanup_request_path = match kind {
		RedisWatchdog => test_dir.join("redis-cleanup.request")
		WebWatchdog => test_dir.join("web-cleanup.request")
	}
	command =
		Cmd.new_str("timeout")
			.args_str([shell_launch_timeout_seconds, "sh", "-c", script])
			.env_str("HARNESS_PID", harness_pid)
			.env(OsStr.from_str("CHILD_PIDFILE"), child_pid_path.to_os_str())
			.env(OsStr.from_str("WATCHDOG_PIDFILE"), pid_path.to_os_str())
			.env(OsStr.from_str("TEST_DIR"), test_dir.to_os_str())
			.env(OsStr.from_str("TEMP_ROOT"), Env.temp_dir!().to_os_str())
			.env(OsStr.from_str("OWNER_FILE"), test_dir.join("harness.owner").to_os_str())
			.env_str("SERVICE_PORT", service_port.to_str())
			.env_str("REDIS_CLI", "redis-cli")
			.env_str("CURL_PROGRAM", "curl")
			.env_str("TIMEOUT_PROGRAM", "timeout")
			.env_str("IDENTITY_TARGET", identity_target)
			.env_str("IDENTITY_URL", "http://127.0.0.1:${service_port.to_str()}${identity_target}")
			.env(OsStr.from_str("IDENTITY_BODY"), identity_body.to_os_str())
			.env(OsStr.from_str("IDENTITY_PIDFILE"), test_dir.join("web.identity").to_os_str())
			.env(OsStr.from_str("DEPENDENT_LAUNCH_MARKER"), test_dir.join("web-launch.intent").to_os_str())
			.env(OsStr.from_str("DEPENDENT_CLEANUP_SAFE"), test_dir.join("web-cleanup.safe").to_os_str())
			.env(OsStr.from_str("CLEANUP_SAFE"), test_dir.join("web-cleanup.safe").to_os_str())
			.env(OsStr.from_str("PENDING_ACK"), pending_ack_path.to_os_str())
			.env(OsStr.from_str("CLEANUP_REQUEST"), cleanup_request_path.to_os_str())

	match command.exec_output!() {
		Ok({ stdout_utf8, stderr_utf8_lossy }) => {
			captured_pid = HarnessText.parse_pid_text(stdout_utf8)
			pidfile_pid = read_pid_if_present!(pid_path, "${label} watchdog")
			match (captured_pid, pidfile_pid) {
				(Ok(pid), Ok(Pid(file_pid))) if pid == file_pid =>
					if process_is_alive!(pid) {
						Ok(pid)
					} else {
						Err(HarnessFailed("${label} parent-death watchdog exited during launch"))
					}
				(Ok(pid), Ok(Pid(file_pid))) => {
					# stdout comes directly from `$!` in the fixed launcher. A
					# mismatched pidfile is evidence only, never a signal target.
					cleanup_result = stop_process!(pid, "captured ${label} watchdog")
					fail_after_cleanup("${label} watchdog PID mismatch: captured ${pid}, pidfile ${file_pid}", cleanup_result)
				}
				(Ok(pid), Ok(NoPid)) => {
					cleanup_result = stop_process!(pid, "${label} watchdog")
					fail_after_cleanup("${label} watchdog returned PID ${pid} without writing its pidfile${suffix_output(stderr_utf8_lossy)}", cleanup_result)
				}
				(Ok(pid), Err(error)) => {
					cleanup_result = stop_process!(pid, "${label} watchdog")
					fail_after_cleanup(describe_harness_error(error), cleanup_result)
				}
				(Err(message), Ok(Pid(pid))) => {
					Err(HarnessFailed("${label} watchdog ${message}; refusing to signal uncorroborated pidfile PID ${pid}; identity evidence was preserved${suffix_output(stderr_utf8_lossy)}"))
				}
				(Err(message), Ok(NoPid)) => Err(HarnessFailed("${label} watchdog ${message}${suffix_output(stderr_utf8_lossy)}"))
				(Err(message), Err(pid_error)) =>
					Err(HarnessFailed("${label} watchdog ${message}; ${describe_harness_error(pid_error)}${suffix_output(stderr_utf8_lossy)}"))
				}
		}
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) => {
			cleanup_result = cleanup_launched_process!(pid_path, stdout_utf8_lossy, "${label} watchdog")
			output = HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy)
			message =
				if exit_code == 124 or exit_code == 137 {
					"${label} watchdog launch exceeded ${shell_launch_timeout_seconds}s${suffix_output(output)}"
				} else {
					"${label} watchdog launch exited ${exit_code.to_str()}${suffix_output(output)}"
				}
			fail_after_cleanup(message, cleanup_result)
		}
		Err(error) => {
			cleanup_result = cleanup_launched_process!(pid_path, "", "${label} watchdog")
			fail_after_cleanup("could not launch ${label} watchdog: ${Str.inspect(error)}", cleanup_result)
		}
	}
}

run_with_web! : Path.Path, Path.Path, Str, RedisServer => Try(U16, [HarnessFailed(Str), ..])
run_with_web! = |test_dir, web_binary, harness_pid, redis| {
	verify_web_startup_window_sigkill!(web_binary, redis.port)?
	web_seed = Random.seed_u64!() ? |error| HarnessFailed("choose HTTP port: ${Str.inspect(error)}")
	web = start_web!(test_dir, web_binary, harness_pid, redis.port, web_seed, 0)?

	test_result = verify_end_to_end!(test_dir, web, redis)
	web_stop_result = stop_web!(web, "basic-webserver")

	match (test_result, web_stop_result) {
		(Ok({}), Ok({})) => Ok(web.port)
		(Err(error), Ok({})) => Err(error)
		(Ok({}), Err(error)) => Err(error)
		(Err(error), Err(stop_error)) =>
			Err(HarnessFailed("${describe_harness_error(error)}; webserver cleanup also failed: ${describe_harness_error(stop_error)}"))
		}
}

start_web! : Path.Path, Path.Path, Str, U16, U64, U8 => Try(WebServer, [HarnessFailed(Str), ..])
start_web! = |test_dir, web_binary, harness_pid, redis_port, seed, attempt| {
	if attempt >= port_attempts {
		Err(HarnessFailed("could not start basic-webserver after ${port_attempts.to_str()} port attempts; last log: ${read_log_best_effort!(test_dir.join("web.log"))}"))
	} else {
		port = random_port(seed, attempt)
		if port == redis_port {
			start_web!(test_dir, web_binary, harness_pid, redis_port, seed, attempt + 1)
		} else {
			identity_target = "/ready/${seed.to_str()}-${attempt.to_str()}-${port.to_str()}"
			match launch_web_candidate!(test_dir, web_binary, harness_pid, redis_port, port, identity_target) {
				Ok(WebUnavailable) => start_web!(test_dir, web_binary, harness_pid, redis_port, seed, attempt + 1)
				Ok(StartedWeb(web)) => {
					match wait_for_web!(web, web_readiness_attempts) {
						Ok(WebReady) => Ok(web)
						Ok(WebNotReady) => {
							stop_result = stop_web!(web, "basic-webserver candidate")
							match stop_result {
								Ok({}) => start_web!(test_dir, web_binary, harness_pid, redis_port, seed, attempt + 1)
								Err(error) => Err(error)
							}
						}
						Err(error) => {
							stop_result = stop_web!(web, "basic-webserver candidate")
							match stop_result {
								Ok({}) => Err(error)
								Err(stop_error) => Err(HarnessFailed("${describe_harness_error(error)}; candidate cleanup also failed: ${describe_harness_error(stop_error)}"))
							}
						}
					}
				}
				Err(error) => Err(error)
			}
		}
	}
}

verify_web_startup_window_sigkill! : Path.Path, U16 => Try({}, [HarnessFailed(Str), ..])
verify_web_startup_window_sigkill! = |web_binary, redis_port| {
	test_dir = create_test_dir!() ? |error| HarnessFailed("create web startup-window test directory: ${Str.inspect(error)}")
	result = run_web_startup_window_sigkill!(test_dir, web_binary, redis_port)
	exists = test_dir.exists!() ? |error| HarnessFailed("inspect web startup-window test directory: ${Str.inspect(error)}")
	cleanup = if exists {
		remove_test_directory_if_idle!(test_dir)
	} else {
		Ok({})
	}
	match (result, cleanup) {
		(Ok({}), Ok({})) => Ok({})
		(Err(error), Ok({})) => Err(error)
		(Ok({}), Err(error)) => Err(error)
		(Err(error), Err(cleanup_error)) => Err(HarnessFailed("${describe_harness_error(error)}; ${describe_harness_error(cleanup_error)}"))
	}
}

run_web_startup_window_sigkill! : Path.Path, Path.Path, U16 => Try({}, [HarnessFailed(Str), ..])
run_web_startup_window_sigkill! = |test_dir, web_binary, redis_port| {
	sentinel_pid = launch_sentinel!({})?
	result = run_web_startup_window_with_sentinel!(test_dir, web_binary, redis_port, sentinel_pid)
	sentinel_cleanup = stop_process!(sentinel_pid, "web startup-window sentinel")
	match (result, sentinel_cleanup) {
		(Ok({}), Ok({})) => Ok({})
		(Err(error), Ok({})) => Err(error)
		(Ok({}), Err(error)) => Err(error)
		(Err(error), Err(cleanup_error)) => Err(HarnessFailed("${describe_harness_error(error)}; sentinel cleanup also failed: ${describe_harness_error(cleanup_error)}"))
	}
}

run_web_startup_window_with_sentinel! : Path.Path, Path.Path, U16, Str => Try({}, [HarnessFailed(Str), ..])
run_web_startup_window_with_sentinel! = |test_dir, web_binary, redis_port, sentinel_pid| {
	test_dir.join("harness.owner").write_utf8!("${sentinel_pid}\n") ? |error| HarnessFailed("write web startup-window ownership marker: ${Str.inspect(error)}")
	seed = Random.seed_u64!() ? |error| HarnessFailed("choose web startup-window port: ${Str.inspect(error)}")
	port = distinct_port(random_port(seed, 0), redis_port)
	target = "/startup-window/${seed.to_str()}-${port.to_str()}"
	pid_path = test_dir.join("web.pid")
	log_path = test_dir.join("web.log")
	identity_body = test_dir.join("web-watchdog-response")
	identity_pid_path = test_dir.join("web.identity")
	cleanup_safe_path = test_dir.join("web-cleanup.safe")
	delete_if_present!(cleanup_safe_path)?
	test_dir.join("web-launch.intent").write_utf8!("launch\n") ? |error| HarnessFailed("write web startup-window launch intent: ${Str.inspect(error)}")
	watchdog_pid = launch_watchdog!(test_dir, test_dir.join("web-watchdog.pid"), sentinel_pid, pid_path, port, target, identity_body, "basic-webserver", WebWatchdog)?
	ensure_process_active!(watchdog_pid, "web startup-window watchdog")?
	# Make the watchdog observe an empty pidfile after parent death before the
	# child-side launcher publishes its stable PID and execs the web server.
	pid_path.write_utf8!("") ? |error| HarnessFailed("write empty startup-window web pidfile: ${Str.inspect(error)}")
	{} = signal_pid!(sentinel_pid, "KILL", "web startup-window sentinel")?
	_ = wait_for_exit!(sentinel_pid, 40)
	wait_for_marker!(test_dir.join("web-pid.pending"), "web watchdog empty-pidfile acknowledgment", 100)?
	launch =
		Cmd.new_str("timeout")
			.args_str([shell_launch_timeout_seconds, "sh", "-c", web_launch_script])
			.env(OsStr.from_str("WEB_BINARY"), web_binary.to_os_str())
			.env(OsStr.from_str("WEB_LOG"), log_path.to_os_str())
			.env(OsStr.from_str("WEB_PIDFILE"), pid_path.to_os_str())
			.env_str("ROC_REDIS_TEST_PORT", redis_port.to_str())
			.env_str("ROC_REDIS_WEBSERVER_PORT", port.to_str())
	match launch.exec_output!() {
		Err(error) => {
			cleanup = cleanup_failed_web_launch!(pid_path, identity_pid_path, cleanup_safe_path, "", port, target, identity_body, log_path, watchdog_pid)
			fail_after_cleanup("launch startup-window web process: ${Str.inspect(error)}", cleanup)
		}
		Ok({ stdout_utf8, .. }) => {
			web_pid = HarnessText.parse_pid_text(stdout_utf8) ? |message| HarnessFailed("launch startup-window web process: ${message}")
			web = { pid: web_pid, pid_path, port, identity_target: target, identity_body, identity_pid_path, cleanup_safe_path, log_path, watchdog_pid }
			web_stopped = wait_for_exit!(web_pid, 200)
			watchdog_stopped = wait_for_exit!(watchdog_pid, 200)
			safe_handoff = exact_marker_present!(cleanup_safe_path, "safe\n", "web startup-window safe-cleanup handoff")?
			endpoint_absent = web_endpoint_absent!(web)?
			if web_stopped and watchdog_stopped and safe_handoff and endpoint_absent {
				Ok({})
			} else {
				cleanup = stop_web!(web, "web startup-window process")
				details = "child_stopped=${Str.inspect(web_stopped)}, watchdog_stopped=${Str.inspect(watchdog_stopped)}, safe_handoff=${Str.inspect(safe_handoff)}, endpoint_absent=${Str.inspect(endpoint_absent)}"
				fail_after_cleanup("preinstalled watchdog did not prove safe cleanup of a web process published after sentinel SIGKILL (${details})", cleanup)
			}
		}
	}
}

distinct_port : U16, U16 -> U16
distinct_port = |candidate, excluded|
	if candidate != excluded candidate else if candidate == 49_999 20_000 else candidate + 1

launch_sentinel! : {} => Try(Str, [HarnessFailed(Str), ..])
launch_sentinel! = |_| {
	command = Cmd.new_str("timeout")
		.args_str([shell_launch_timeout_seconds, "sh", "-c", "sleep 30 </dev/null >/dev/null 2>&1 & child=$!; printf '%s\\n' \"$child\""])
	match command.exec_output!() {
		Ok({ stdout_utf8, .. }) => HarnessText.parse_pid_text(stdout_utf8).map_err(|message| HarnessFailed("launch web startup-window sentinel: ${message}"))
		Err(error) => Err(HarnessFailed("launch web startup-window sentinel: ${Str.inspect(error)}"))
	}
}

launch_web_candidate! : Path.Path, Path.Path, Str, U16, U16, Str => Try([StartedWeb(WebServer), WebUnavailable], [HarnessFailed(Str), ..])
launch_web_candidate! = |test_dir, web_binary, harness_pid, redis_port, web_port, identity_target| {
	pid_path = test_dir.join("web.pid")
	log_path = test_dir.join("web.log")
	identity_body = test_dir.join("web-watchdog-response")
	identity_pid_path = test_dir.join("web.identity")
	cleanup_safe_path = test_dir.join("web-cleanup.safe")
	delete_if_present!(pid_path)?
	delete_if_present!(identity_pid_path)?
	delete_if_present!(cleanup_safe_path)?
	test_dir.join("web-launch.intent").write_utf8!("launch\n") ? |error| HarnessFailed("write basic-webserver launch intent: ${Str.inspect(error)}")
	watchdog_pid = launch_watchdog!(test_dir, test_dir.join("web-watchdog.pid"), harness_pid, pid_path, web_port, identity_target, identity_body, "basic-webserver", WebWatchdog)?
	ensure_process_active!(watchdog_pid, "basic-webserver parent-death watchdog")?

	command =
		Cmd.new_str("timeout")
			.args_str([shell_launch_timeout_seconds, "sh", "-c", web_launch_script])
			.env(OsStr.from_str("WEB_BINARY"), web_binary.to_os_str())
			.env(OsStr.from_str("WEB_LOG"), log_path.to_os_str())
			.env(OsStr.from_str("WEB_PIDFILE"), pid_path.to_os_str())
			.env_str("ROC_REDIS_TEST_PORT", redis_port.to_str())
			.env_str("ROC_REDIS_WEBSERVER_PORT", web_port.to_str())

	launch_result = command.exec_output!()
	match launch_result {
		Ok({ stdout_utf8, stderr_utf8_lossy }) => {
			captured_pid = HarnessText.parse_pid_text(stdout_utf8)
			pidfile_pid = wait_for_published_pid!(pid_path, "basic-webserver", 100)

			match (captured_pid, pidfile_pid) {
				(Ok(pid), Ok(Pid(file_pid))) if pid == file_pid =>
					if process_is_alive!(pid) {
						Ok(StartedWeb({ cleanup_safe_path, identity_body, identity_pid_path, identity_target, log_path, pid, pid_path, port: web_port, watchdog_pid }))
					} else {
						web = { pid, pid_path, port: web_port, identity_target, identity_body, identity_pid_path, cleanup_safe_path, log_path, watchdog_pid }
						stop_web!(web, "exited basic-webserver startup candidate")?
						Ok(WebUnavailable)
					}
				(Ok(pid), Ok(Pid(file_pid))) => {
					cleanup_result = cleanup_web_pid_pair!(FoundPid(pid), FoundPid(file_pid), { pid_path, port: web_port, identity_target, identity_body, identity_pid_path, cleanup_safe_path, log_path, watchdog_pid })
					fail_after_cleanup("webserver launcher PID mismatch: captured ${pid}, pidfile ${file_pid}", cleanup_result)
				}
				(Ok(pid), Ok(NoPid)) => {
					cleanup_result = cleanup_web_pid_pair!(FoundPid(pid), MissingPid, { pid_path, port: web_port, identity_target, identity_body, identity_pid_path, cleanup_safe_path, log_path, watchdog_pid })
					fail_after_cleanup("webserver launcher returned PID ${pid} without writing its pidfile${suffix_output(stderr_utf8_lossy)}", cleanup_result)
				}
				(Ok(pid), Err(error)) => {
					cleanup_result = cleanup_web_pid_pair!(FoundPid(pid), MissingPid, { pid_path, port: web_port, identity_target, identity_body, identity_pid_path, cleanup_safe_path, log_path, watchdog_pid })
					fail_after_cleanup(describe_harness_error(error), cleanup_result)
				}
				(Err(message), Ok(Pid(pid))) => {
					cleanup_result = cleanup_web_pid_pair!(MissingPid, FoundPid(pid), { pid_path, port: web_port, identity_target, identity_body, identity_pid_path, cleanup_safe_path, log_path, watchdog_pid })
					fail_after_cleanup("${message}${suffix_output(stderr_utf8_lossy)}", cleanup_result)
				}
				(Err(message), Ok(NoPid)) => {
					cleanup_result = preserve_web_supervision(watchdog_pid, "launcher output and pidfile did not identify a child")
					fail_after_cleanup("${message}${suffix_output(stderr_utf8_lossy)}", cleanup_result)
				}
				(Err(message), Err(pid_error)) => {
					cleanup_result = preserve_web_supervision(watchdog_pid, "pidfile publication could not be established")
					fail_after_cleanup("${message}; ${describe_harness_error(pid_error)}${suffix_output(stderr_utf8_lossy)}", cleanup_result)
				}
			}
		}
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) => {
			cleanup_result = cleanup_failed_web_launch!(pid_path, identity_pid_path, cleanup_safe_path, stdout_utf8_lossy, web_port, identity_target, identity_body, log_path, watchdog_pid)
			output = HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy)
			if exit_code == 124 or exit_code == 137 {
				fail_after_cleanup("webserver launch bridge exceeded ${shell_launch_timeout_seconds}s${suffix_output(output)}", cleanup_result)
			} else {
				fail_after_cleanup("webserver launch bridge exited ${exit_code.to_str()}${suffix_output(output)}", cleanup_result)
			}
		}
		Err(error) => {
			cleanup_result = cleanup_failed_web_launch!(pid_path, identity_pid_path, cleanup_safe_path, "", web_port, identity_target, identity_body, log_path, watchdog_pid)
			fail_after_cleanup("could not run webserver launch bridge: ${Str.inspect(error)}", cleanup_result)
		}
	}
}

cleanup_failed_web_launch! : Path.Path, Path.Path, Path.Path, Str, U16, Str, Path.Path, Path.Path, Str => Try({}, [HarnessFailed(Str), ..])
cleanup_failed_web_launch! = |pid_path, identity_pid_path, cleanup_safe_path, captured_output, port, identity_target, identity_body, log_path, watchdog_pid| {
	captured = match HarnessText.parse_pid_text(captured_output) {
		Ok(pid) => FoundPid(pid)
		Err(_) => MissingPid
	}
	pidfile_result = wait_for_published_pid!(pid_path, "basic-webserver", 100)
	pidfile = match pidfile_result {
		Ok(Pid(pid)) => FoundPid(pid)
		_ => MissingPid
	}
	cleanup = cleanup_web_pid_pair!(captured, pidfile, { pid_path, port, identity_target, identity_body, identity_pid_path, cleanup_safe_path, log_path, watchdog_pid })
	match (pidfile_result, cleanup) {
		(Ok(_), Ok({})) => Ok({})
		(Err(error), Ok({})) => Err(error)
		(Ok(_), Err(error)) => Err(error)
		(Err(error), Err(cleanup_error)) => Err(HarnessFailed("${describe_harness_error(error)}; cleanup also failed: ${describe_harness_error(cleanup_error)}"))
	}
}

## Identity and supervision paths shared by startup cleanup candidates.
## A context is not proof of ownership: stop_web! must still attest the process.
WebLaunchContext : {
	pid_path : Path.Path,
	port : U16,
	identity_target : Str,
	identity_body : Path.Path,
	identity_pid_path : Path.Path,
	cleanup_safe_path : Path.Path,
	log_path : Path.Path,
	watchdog_pid : Str,
}

cleanup_web_pid_pair! : [FoundPid(Str), MissingPid], [FoundPid(Str), MissingPid], WebLaunchContext => Try({}, [HarnessFailed(Str), ..])
cleanup_web_pid_pair! = |first, second, context| {
	{ pid_path, port, identity_target, identity_body, identity_pid_path, cleanup_safe_path, log_path, watchdog_pid } = context
	cleanup_one! = |pid| stop_web!({ pid, pid_path, port, identity_target, identity_body, identity_pid_path, cleanup_safe_path, log_path, watchdog_pid }, "basic-webserver startup candidate")
	match (first, second) {
		(MissingPid, MissingPid) => preserve_web_supervision(watchdog_pid, "no trusted child PID was published")
		(FoundPid(pid), MissingPid) => cleanup_one!(pid)
		(MissingPid, FoundPid(pid)) => cleanup_one!(pid)
		(FoundPid(first_pid), FoundPid(second_pid)) if first_pid == second_pid => cleanup_one!(first_pid)
		(FoundPid(first_pid), FoundPid(second_pid)) => {
			first_alive = process_is_alive!(first_pid)
			second_alive = process_is_alive!(second_pid)
			if first_alive and second_alive {
				Err(HarnessFailed("refusing to signal mismatched live webserver PIDs ${first_pid} and ${second_pid}"))
			} else if first_alive {
				cleanup_one!(first_pid)
			} else if second_alive {
				cleanup_one!(second_pid)
			} else {
				preserve_web_supervision(watchdog_pid, "mismatched child PIDs both exited before identity-safe cleanup")
			}
		}
	}
}

preserve_web_supervision : Str, Str -> Try({}, [HarnessFailed(Str), ..])
preserve_web_supervision = |watchdog_pid, reason|
	Err(HarnessFailed("${reason}; leaving parent-death watchdog ${watchdog_pid} active so a delayed web child remains supervised"))

cleanup_launched_process! : Path.Path, Str, Str => Try({}, [HarnessFailed(Str), ..])
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
		(Err(error), Ok({})) => Err(HarnessFailed(describe_harness_error(error)))
		(Ok(_), Err(error)) => Err(HarnessFailed(describe_harness_error(error)))
		(Err(error), Err(cleanup_error)) =>
			Err(HarnessFailed("${describe_harness_error(error)}; process cleanup also failed: ${describe_harness_error(cleanup_error)}"))
		}
}

cleanup_pid_pair! : [FoundPid(Str), MissingPid], [FoundPid(Str), MissingPid], Str => Try({}, [HarnessFailed(Str), ..])
cleanup_pid_pair! = |first, second, label|
	match (first, second) {
		(MissingPid, MissingPid) => Ok({})
		(FoundPid(pid), MissingPid) => stop_process!(pid, "captured ${label} process")
		(MissingPid, FoundPid(pid)) => Err(HarnessFailed("refusing to signal uncorroborated pidfile ${label} PID ${pid}; identity evidence was preserved"))
		(FoundPid(first_pid), FoundPid(second_pid)) if first_pid == second_pid =>
			stop_process!(first_pid, "${label} process")
		(FoundPid(first_pid), FoundPid(second_pid)) => {
			first_result = stop_process!(first_pid, "captured ${label} process")
			ambiguity = Err(HarnessFailed("refusing to signal mismatched pidfile ${label} PID ${second_pid}; identity evidence was preserved"))
			combine_cleanup_results(first_result, ambiguity)
		}
	}

combine_cleanup_results : Try({}, [HarnessFailed(Str), ..]), Try({}, [HarnessFailed(Str), ..]) -> Try({}, [HarnessFailed(Str), ..])
combine_cleanup_results = |first, second|
	match (first, second) {
		(Ok({}), Ok({})) => Ok({})
		(Err(error), Ok({})) => Err(HarnessFailed(describe_harness_error(error)))
		(Ok({}), Err(error)) => Err(HarnessFailed(describe_harness_error(error)))
		(Err(first_error), Err(second_error)) =>
			Err(HarnessFailed("${describe_harness_error(first_error)}; ${describe_harness_error(second_error)}"))
		}

fail_after_cleanup : Str, Try({}, [HarnessFailed(Str), ..]) -> Try(a, [HarnessFailed(Str), ..])
fail_after_cleanup = |message, cleanup_result|
	match cleanup_result {
		Ok({}) => Err(HarnessFailed(message))
		Err(error) => Err(HarnessFailed("${message}; cleanup also failed: ${describe_harness_error(error)}"))
	}

wait_for_web! : WebServer, U8 => Try([WebReady, WebNotReady], [HarnessFailed(Str), ..])
wait_for_web! = |web, attempts_remaining| {
	if !(process_is_alive!(web.pid)) or attempts_remaining == 0 {
		Ok(WebNotReady)
	} else if !(process_is_alive!(web.watchdog_pid)) {
		Err(HarnessFailed("parent-death watchdog ${web.watchdog_pid} exited while basic-webserver ${web.pid} remained alive"))
	} else {
		probe = http_probe!(web.port, web.identity_target, web.identity_body)?
		match probe {
			HttpResponse({ body, status }) if status == "200" and body == web.identity_target => {
				# A listener which won a port race can answer the request. Keep the
				# candidate only after binding that response to the exact live child
				# and its private pidfile. This persisted value is readiness evidence;
				# every later signal still requires a fresh nonce-bearing response.
				Sleep.millis!(50)
				if establish_web_attestation!(web)? Ok(WebReady) else Ok(WebNotReady)
			}
			_ => {
				Sleep.millis!(50)
				wait_for_web!(web, attempts_remaining - 1)
			}
		}
	}
}

http_probe! : U16, Str, Path.Path => Try([HttpResponse({ body : Str, status : Str }), HttpRequestFailed(Str)], [HarnessFailed(Str), ..])
http_probe! = |port, target, output_path| {
	delete_if_present!(output_path)?
	url = "http://127.0.0.1:${port.to_str()}${target}"
	command =
		Cmd.new_str("curl")
			.args_str([
				"--noproxy",
				"*",
				"--silent",
				"--show-error",
				"--connect-timeout",
				"0.2",
				"--max-time",
				"0.5",
				"--output",
			])
			.arg(output_path.to_os_str())
			.args_str(["--write-out", "%{http_code}", url])

	match command.exec_output!() {
		Ok({ stdout_utf8, .. }) => {
			body = output_path.read_utf8!() ? |error| HarnessFailed("read HTTP response body: ${Str.inspect(error)}")
			Ok(HttpResponse({ body, status: stdout_utf8 }))
		}
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) =>
			Ok(HttpRequestFailed("curl exited ${exit_code.to_str()}${suffix_output(HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy))}"))
		Err(error) => Err(HarnessFailed("run curl probe: ${Str.inspect(error)}"))
	}
}

verify_end_to_end! : Path.Path, WebServer, RedisServer => Try({}, [HarnessFailed(Str), ..])
verify_end_to_end! = |test_dir, web, redis| {
	nonce = Random.seed_u64!() ? |error| HarnessFailed("choose request nonce: ${Str.inspect(error)}")
	# Exercise 0.16's structured Resource target, including preservation of the
	# distinction between a percent-encoded query and no query.
	target = "/roc-redis/basic-webserver/${nonce.to_str()}?client=roc%20redis&empty="
	probe = http_probe!(web.port, target, test_dir.join("verify-response"))?

	match probe {
		HttpResponse({ body, status }) if status == "200" and body == target => {}
		other => return Err(HarnessFailed("basic-webserver response did not match the Redis-backed request target: ${describe_http_probe(other)}; web log: ${read_log_best_effort!(web.log_path)}"))
	}

	Sleep.millis!(50)
	if !(process_is_alive!(web.pid)) {
		return Err(HarnessFailed("basic-webserver process ${web.pid} exited after serving the verification request; log: ${read_log_best_effort!(web.log_path)}"))
	}
	if !(process_is_alive!(web.watchdog_pid)) {
		return Err(HarnessFailed("basic-webserver parent-death watchdog ${web.watchdog_pid} exited during the integration test"))
	}

	if !(process_is_alive!(redis.pid)) or !(redis_is_owner!(redis.port, redis.pid)) {
		return Err(HarnessFailed("isolated Redis process ${redis.pid} no longer owns port ${redis.port.to_str()}; log: ${read_log_best_effort!(test_dir.join("redis.log"))}"))
	}
	if !(process_is_alive!(redis.watchdog_pid)) {
		return Err(HarnessFailed("Redis parent-death watchdog ${redis.watchdog_pid} exited during the integration test"))
	}

	db_size = redis_db_size!(redis.port)?
	if db_size == "0" {
		Ok({})
	} else {
		Err(HarnessFailed("integration test unexpectedly mutated Redis (DBSIZE=${Str.inspect(db_size)})"))
	}
}

redis_db_size! : U16 => Try(Str, [HarnessFailed(Str), ..])
redis_db_size! = |port| {
	command = Cmd.new_str("redis-cli")
		.args_str(["--raw", "-t", "1", "-h", "127.0.0.1", "-p", port.to_str(), "DBSIZE"])

	match command.exec_output!() {
		Ok({ stdout_utf8, .. }) => Ok(HarnessText.first_line(stdout_utf8))
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) =>
			Err(HarnessFailed("redis-cli DBSIZE exited ${exit_code.to_str()}${suffix_output(HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy))}"))
		Err(error) => Err(HarnessFailed("run redis-cli DBSIZE: ${Str.inspect(error)}"))
	}
}

redis_is_owner! : U16, Str => Bool
redis_is_owner! = |port, expected_pid| {
	result =
		Cmd.new_str("timeout")
			.args_str(["--signal=TERM", "--kill-after=1s", "1", "redis-cli", "--raw", "-t", "0.5", "-h", "127.0.0.1", "-p", port.to_str(), "INFO", "server"])
			.exec_output!()

	match result {
		Ok(output) => HarnessText.redis_info_field(output.stdout_utf8, "process_id") == Ok(expected_pid)
		Err(_) => Bool.False
	}
}

redis_endpoint_absent! : U16 => Try(Bool, [HarnessFailed(Str), ..])
redis_endpoint_absent! = |port|
	match Cmd.new_str("timeout")
		.args_str(["--signal=TERM", "--kill-after=1s", "1", "redis-cli", "--raw", "-t", "0.5", "-h", "127.0.0.1", "-p", port.to_str(), "PING"])
		.exec_output!() {
		Ok(_) => Ok(Bool.False)
		Err(NonZeroExitCode({ exit_code, .. })) if exit_code == 1 => Ok(Bool.True)
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) => Err(HarnessFailed("Redis endpoint absence probe exited ${exit_code.to_str()}${suffix_output(HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy))}"))
		Err(error) => Err(HarnessFailed("probe Redis endpoint absence: ${Str.inspect(error)}"))
	}

web_is_owner! : WebServer => Bool
web_is_owner! = |web| {
	if !(web_pidfile_matches!(web)) or !(process_is_alive!(web.pid)) {
		Bool.False
	} else {
		match http_probe!(web.port, web.identity_target, web.identity_body) {
			# Every signal requires a fresh nonce-bearing response. A persisted PID
			# is readiness evidence only and cannot survive PID reuse.
			Ok(HttpResponse({ body, status })) if status == "200" and body == web.identity_target =>
				web_pidfile_matches!(web) and process_is_alive!(web.pid)
			_ => Bool.False
		}
	}
}

web_pidfile_matches! : WebServer => Bool
web_pidfile_matches! = |web|
	match read_pid_if_present!(web.pid_path, "basic-webserver identity") {
		Ok(Pid(pid)) => pid == web.pid
		_ => Bool.False
	}

web_identity_attested! : WebServer => Bool
web_identity_attested! = |web| {
	if !(web_pidfile_matches!(web)) or !(process_is_alive!(web.pid)) {
		Bool.False
	} else {
		match read_pid_if_present!(web.identity_pid_path, "basic-webserver attestation") {
			Ok(Pid(pid)) => pid == web.pid and process_is_alive!(web.pid)
			_ => Bool.False
		}
	}
}

establish_web_attestation! : WebServer => Try(Bool, [HarnessFailed(Str), ..])
establish_web_attestation! = |web| {
	if !(web_pidfile_matches!(web)) or !(process_is_alive!(web.pid)) {
		Ok(Bool.False)
	} else {
		web.identity_pid_path.write_utf8!("${web.pid}\n") ? |error| HarnessFailed("write basic-webserver identity attestation: ${Str.inspect(error)}")
		Ok(web_identity_attested!(web))
	}
}

SignalDecision : [AlreadyExited, RefuseUnowned, SignalOwned]

signal_decision : Bool, Bool -> SignalDecision
signal_decision = |alive, owns_identity|
	if !alive AlreadyExited else if owns_identity SignalOwned else RefuseUnowned

stop_redis! : RedisServer => Try({}, [HarnessFailed(Str), ..])
stop_redis! = |redis| {
	child_result = stop_redis_process!(redis.port, redis.pid, "Redis")
	match child_result {
		Err(error) => Err(error)
		Ok({}) => stop_process!(redis.watchdog_pid, "Redis parent-death watchdog")
	}
}

stop_redis_process! : U16, Str, Str => Try({}, [HarnessFailed(Str), ..])
stop_redis_process! = |port, pid, label| {
	match signal_decision(process_is_alive!(pid), redis_is_owner!(port, pid)) {
		AlreadyExited => finish_redis_stop!(port, pid)
		RefuseUnowned => Err(HarnessFailed("refusing to signal process ${pid}: exact Redis INFO ownership of port ${port.to_str()} was not established"))
		SignalOwned => {
			term_result = signal_pid!(pid, "TERM", label)
			if wait_for_exit!(pid, 40) {
				finish_redis_stop!(port, pid)
			} else {
				match signal_decision(process_is_alive!(pid), redis_is_owner!(port, pid)) {
					AlreadyExited => finish_redis_stop!(port, pid)
					RefuseUnowned => Err(HarnessFailed("refusing SIGKILL for process ${pid}: exact Redis INFO ownership was lost after SIGTERM; TERM=${describe_signal_result(term_result)}"))
					SignalOwned =>
						match finish_kill!(pid, label, term_result) {
							Ok({}) => finish_redis_stop!(port, pid)
							Err(error) => Err(error)
						}
					}
			}
		}
	}
}

finish_redis_stop! : U16, Str => Try({}, [HarnessFailed(Str), ..])
finish_redis_stop! = |port, pid|
	if redis_endpoint_absent!(port)? {
		Ok({})
	} else {
		Err(HarnessFailed("refusing cleanup for exited PID ${pid}: Redis endpoint ${port.to_str()} still responds and may belong to a different process"))
	}

stop_web! : WebServer, Str => Try({}, [HarnessFailed(Str), ..])
stop_web! = |web, label| {
	child_result = stop_web_process!(web, label)
	match child_result {
		Err(error) => Err(error)
		Ok({}) => {
			watchdog_result = stop_process!(web.watchdog_pid, "${label} parent-death watchdog")
			match watchdog_result {
				Err(error) => Err(error)
				Ok({}) =>
					web.cleanup_safe_path.write_utf8!("safe\n").map_err(|error| HarnessFailed("write ${label} safe-cleanup handoff: ${Str.inspect(error)}"))
				}
		}
	}
}

stop_web_process! : WebServer, Str => Try({}, [HarnessFailed(Str), ..])
stop_web_process! = |web, label| {
	match signal_decision(process_is_alive!(web.pid), web_is_owner!(web)) {
		AlreadyExited => finish_web_stop!(web, label)
		RefuseUnowned => Err(HarnessFailed("refusing to signal process ${web.pid}: private pidfile plus a fresh exact nonce response on port ${web.port.to_str()} was not established"))
		SignalOwned => {
			term_result = signal_pid!(web.pid, "TERM", label)
			if wait_for_exit!(web.pid, 40) {
				finish_web_stop!(web, label)
			} else {
				match signal_decision(process_is_alive!(web.pid), web_is_owner!(web)) {
					AlreadyExited => finish_web_stop!(web, label)
					RefuseUnowned => Err(HarnessFailed("refusing SIGKILL for process ${web.pid}: private child identity was lost after SIGTERM; TERM=${describe_signal_result(term_result)}"))
					SignalOwned =>
						match finish_kill!(web.pid, label, term_result) {
							Ok({}) => finish_web_stop!(web, label)
							Err(error) => Err(error)
						}
					}
			}
		}
	}
}

finish_web_stop! : WebServer, Str => Try({}, [HarnessFailed(Str), ..])
finish_web_stop! = |web, label|
	if web_endpoint_absent!(web)? {
		Ok({})
	} else {
		Err(HarnessFailed("refusing to complete ${label} cleanup: HTTP endpoint ${web.port.to_str()} still responds or its absence is uncertain; identity evidence and watchdog were preserved"))
	}

web_endpoint_absent! : WebServer => Try(Bool, [HarnessFailed(Str), ..])
web_endpoint_absent! = |web| {
	first_absent = web_endpoint_absent_once!(web)?
	if first_absent {
		Sleep.millis!(watchdog_poll_millis)
		web_endpoint_absent_once!(web)
	} else {
		Ok(Bool.False)
	}
}

web_endpoint_absent_once! : WebServer => Try(Bool, [HarnessFailed(Str), ..])
web_endpoint_absent_once! = |web| {
	url = "http://127.0.0.1:${web.port.to_str()}${web.identity_target}"
	command =
		Cmd.new_str("timeout")
			.args_str([
				"--signal=TERM",
				"--kill-after=1s",
				"1",
				"curl",
				"--noproxy",
				"*",
				"--silent",
				"--show-error",
				"--connect-timeout",
				"0.2",
				"--max-time",
				"0.5",
				"--output",
				"/dev/null",
				url,
			])

	match command.exec_output!() {
		Ok(_) => Ok(Bool.False)
		Err(NonZeroExitCode({ exit_code, .. })) if exit_code == 7 => Ok(Bool.True)
		Err(NonZeroExitCode(_)) => Ok(Bool.False)
		Err(error) => Err(HarnessFailed("probe ${web.port.to_str()} for web endpoint absence: ${Str.inspect(error)}"))
	}
}

finish_kill! : Str, Str, Try({}, [HarnessFailed(Str), ..]) => Try({}, [HarnessFailed(Str), ..])
finish_kill! = |pid, label, term_result| {
	kill_result = signal_pid!(pid, "KILL", label)
	if wait_for_exit!(pid, 40) {
		Ok({})
	} else {
		Err(HarnessFailed("${label} process ${pid} did not exit after identity-guarded SIGKILL; TERM=${describe_signal_result(term_result)}, KILL=${describe_signal_result(kill_result)}"))
	}
}

stop_process! : Str, Str => Try({}, [HarnessFailed(Str), ..])
stop_process! = |pid, label| {
	if !(process_is_alive!(pid)) {
		Ok({})
	} else {
		term_result = signal_pid!(pid, "TERM", label)
		if wait_for_exit!(pid, 40) {
			Ok({})
		} else {
			kill_result = signal_pid!(pid, "KILL", label)
			if wait_for_exit!(pid, 40) {
				Ok({})
			} else {
				Err(HarnessFailed("${label} process ${pid} did not exit after SIGKILL; TERM=${describe_signal_result(term_result)}, KILL=${describe_signal_result(kill_result)}"))
			}
		}
	}
}

signal_pid! : Str, Str, Str => Try({}, [HarnessFailed(Str), ..])
signal_pid! = |pid, signal, label| {
	exit_code = Cmd.new_str("kill")
		.args_str(["-${signal}", pid])
		.exec_exit_code!() ? |error| HarnessFailed("signal ${label} process ${pid}: ${Str.inspect(error)}")
	if exit_code == 0 {
		Ok({})
	} else {
		Err(HarnessFailed("kill -${signal} ${pid} exited ${exit_code.to_str()}"))
	}
}

describe_signal_result : Try({}, [HarnessFailed(Str), ..]) -> Str
describe_signal_result = |result|
	match result {
		Ok({}) => "ok"
		Err(error) => describe_harness_error(error)
	}

wait_for_exit! : Str, U16 => Bool
wait_for_exit! = |pid, attempts_remaining| {
	if !(process_is_alive!(pid)) {
		Bool.True
	} else if attempts_remaining == 0 {
		Bool.False
	} else {
		Sleep.millis!(50)
		wait_for_exit!(pid, attempts_remaining - 1)
	}
}

wait_for_marker! : Path.Path, Str, U8 => Try({}, [HarnessFailed(Str), ..])
wait_for_marker! = |path, label, attempts_remaining| {
	acknowledged = exact_marker_present!(path, "pending\n", label)?
	if acknowledged {
		Ok({})
	} else if attempts_remaining == 0 {
		Err(HarnessFailed("timed out waiting for ${label}"))
	} else {
		Sleep.millis!(25)
		wait_for_marker!(path, label, attempts_remaining - 1)
	}
}

exact_marker_present! : Path.Path, Str, Str => Try(Bool, [HarnessFailed(Str), ..])
exact_marker_present! = |path, expected, label| {
	exists = path.is_file!() ? |error| HarnessFailed("inspect ${label}: ${Str.inspect(error)}")
	if exists {
		contents = path.read_utf8!() ? |error| HarnessFailed("read ${label}: ${Str.inspect(error)}")
		Ok(contents == expected)
	} else {
		Ok(Bool.False)
	}
}

process_is_alive! : Str => Bool
process_is_alive! = |pid| {
	match Cmd.new_str("kill").args_str(["-0", pid]).exec_output!() {
		Ok(_) => Bool.True
		_ => Bool.False
	}
}

ensure_process_active! : Str, Str => Try({}, [HarnessFailed(Str), ..])
ensure_process_active! = |pid, label|
	if process_is_alive!(pid) Ok({}) else Err(HarnessFailed("${label} process ${pid} is not running"))

read_pid_if_present! : Path.Path, Str => Try([Pid(Str), NoPid], [HarnessFailed(Str), ..])
read_pid_if_present! = |pid_path, label| {
	match pid_path.is_file!() {
		Ok(Bool.False) => Ok(NoPid)
		Ok(Bool.True) => {
			contents = pid_path.read_utf8!() ? |error| HarnessFailed("read ${label} pidfile: ${Str.inspect(error)}")
			pid = parse_pidfile_text(contents) ? |message| HarnessFailed("${label} wrote an invalid pidfile: ${message}")
			Ok(Pid(pid))
		}
		Err(error) => Err(HarnessFailed("inspect ${label} pidfile: ${Str.inspect(error)}"))
	}
}

parse_pid_text : Str -> Try(Str, Str)
parse_pid_text = |text| {
	pid = HarnessText.first_line(text)
	remaining = text.split_on("\n").drop_first(1)
	only_trailing_empty = remaining.all(|line| line.is_empty())

	if HarnessText.valid_pid(pid) and only_trailing_empty {
		Ok(pid)
	} else {
		Err("expected one positive process ID, received ${Str.inspect(text)}")
	}
}

parse_pidfile_text : Str -> Try(Str, Str)
parse_pidfile_text = |text|
	match HarnessText.parse_pid_text(text) {
		Ok(pid) if text.ends_with("\n") => Ok(pid)
		Ok(_) => Err("expected a newline-terminated process ID, received ${Str.inspect(text)}")
		Err(message) => Err(message)
	}

random_port : U64, U8 -> U16
random_port = |seed, attempt| {
	seed_offset = seed % random_port_count
	attempt_offset = (U8.to_u64(attempt) * 7_919) % random_port_count
	offset = (seed_offset + attempt_offset) % random_port_count
	U64.to_u16_wrap(U16.to_u64(first_random_port) + offset)
}

delete_if_present! : Path.Path => Try({}, [HarnessFailed(Str), ..])
delete_if_present! = |path| {
	exists = path.exists!() ? |error| HarnessFailed("inspect ${path.display()}: ${Str.inspect(error)}")
	if exists {
		path.delete!().map_err(|error| HarnessFailed("delete ${path.display()}: ${Str.inspect(error)}"))
	} else {
		Ok({})
	}
}

read_log_best_effort! : Path.Path => Str
read_log_best_effort! = |path|
	match path.read_utf8!() {
		Ok(contents) => contents
		Err(error) => "<unavailable: ${Str.inspect(error)}>"
	}

describe_http_probe : [HttpResponse({ body : Str, status : Str }), HttpRequestFailed(Str)] -> Str
describe_http_probe = |probe|
	match probe {
		HttpResponse({ body, status }) => "HTTP status ${Str.inspect(status)}, body ${Str.inspect(body)}"
		HttpRequestFailed(message) => message
	}

suffix_output : Str -> Str
suffix_output = |output| if output.is_empty() "" else ":\n${output}"

describe_harness_error : [HarnessFailed(Str), ..] -> Str
describe_harness_error = |error|
	match error {
		HarnessFailed(message) => message
		other => Str.inspect(other)
	}

expect random_port(0, 0) == 20_000

expect random_port(29_999, 0) == 49_999

expect random_port(U64.highest, 19) >= 20_000

expect random_port(U64.highest, 19) <= 49_999

expect HarnessText.valid_pid("2")

expect !(HarnessText.valid_pid(""))

expect !(HarnessText.valid_pid("0"))

expect !(HarnessText.valid_pid("1"))

expect !(HarnessText.valid_pid("12 3"))

expect HarnessText.parse_pid_text("123\n") == Ok("123")

expect HarnessText.parse_pid_text("123\n\n") == Ok("123")

expect HarnessText.parse_pid_text("123\n456\n").is_err()

expect parse_pidfile_text("123").is_err()

expect parse_pidfile_text("123\n") == Ok("123")

expect ["", "12x", "123\n"].map(startup_pid_state) == [PendingPid, InvalidPid("expected one positive process ID, received \"12x\""), ReadyPid("123")]

expect first_ready_startup_pid(["", "12x", "123\n"]) == Ok("123")

expect HarnessText.combine_output("stdout", "stderr") == "stdout\nstderr"

expect signal_decision(Bool.False, Bool.False) == AlreadyExited

expect signal_decision(Bool.True, Bool.False) == RefuseUnowned

expect signal_decision(Bool.True, Bool.True) == SignalOwned

expect distinct_port(20_000, 20_000) == 20_001

## Both service watchdogs wait for a pidfile written after installation and
## validate private-directory ownership before signaling. Redis uses exact INFO
## process_id and lets an already-installed dependent watchdog run first. The
## web process binds readiness to a nonce-bearing HTTP response, while each
## later signal requires a fresh response so PID reuse cannot inherit trust.
expect redis_watchdog_script.contains("$CLEANUP_REQUEST") and redis_watchdog_script.contains("context_is_owned")

expect redis_watchdog_script.contains("limit=300") and redis_watchdog_script.contains("IFS= read -r child")

expect redis_watchdog_script.contains("wait_for_dependent_watchdog") and redis_watchdog_script.contains("while [ \"$attempt\" -lt ${dependent_completion_attempts.to_str()} ]") and redis_watchdog_script.contains("$DEPENDENT_CLEANUP_SAFE") and !(redis_watchdog_script.contains("$DEPENDENT_WATCHDOG_PIDFILE"))

expect redis_watchdog_script.split_on("redis_is_owner \"$child\"").len() == 4

expect redis_watchdog_script.contains("preserve=1") and redis_watchdog_script.contains("&& redis_endpoint_absent; then preserve=0")

expect web_watchdog_script.contains("while [ \"$attempt\" -lt ${web_watchdog_pid_attempts.to_str()} ]") and web_watchdog_script.contains("while [ \"$attempt\" -lt ${web_watchdog_owner_attempts.to_str()} ]") and web_watchdog_script.contains("$IDENTITY_URL")

expect web_watchdog_script.contains("$IDENTITY_TARGET") and web_watchdog_script.contains("$IDENTITY_PIDFILE")

expect web_watchdog_script.split_on("web_is_owner \"$child\"").len() == 4

expect !(web_watchdog_script.contains("attested_identity"))

expect web_watchdog_script.contains("preserve=1") and web_watchdog_script.contains("! kill -0 \"$child\" 2>/dev/null && web_endpoint_absent; then preserve=0") and !(web_watchdog_script.contains("preserve=0; if safe_pid"))

expect web_watchdog_script.contains("[ \"$status\" -eq 7 ]") and web_watchdog_script.split_on("web_endpoint_absent").len() == 3

expect web_launch_script.contains("printf \"%s\\n\" \"$$\" >\"$WEB_PIDFILE\"")

expect dependent_completion_attempts * watchdog_poll_millis > web_watchdog_cleanup_bound_millis

expect web_watchdog_pid_attempts * watchdog_poll_millis > shell_launch_timeout_seconds_value * 1_000

expect web_watchdog_cleanup_bound_millis == 100_050

expect redis_watchdog_script.contains("[ \"$dependent_safe\" -eq 1 ] || exit 0") and web_watchdog_script.contains("printf 'safe\\n' >\"$CLEANUP_SAFE\"")

expect redis_watchdog_script.contains("printf 'pending\\n' >\"$PENDING_ACK\"") and web_watchdog_script.contains("printf 'pending\\n' >\"$PENDING_ACK\"")
