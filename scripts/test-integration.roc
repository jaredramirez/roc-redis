## Start an isolated Redis daemon, run the basic-cli adapter against it, and
## tear the daemon down. The orchestration is Roc and normal child commands
## receive argument vectors directly. A fixed shell fragment supplies the one
## qualified parent-death watchdog for the daemon. The CLI platform's newer
## native resource APIs can be adopted in a separate lifecycle refactor.
## Dynamic values cross that fixed shell boundary only through environment
## variables, and the shell launch itself is bounded.
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

command_timeout_seconds : Str
command_timeout_seconds = "120"

first_random_port : U16
first_random_port = 20_000

random_port_count : U64
random_port_count = 30_000

port_attempts : U8
port_attempts = 20

readiness_attempts : U8
readiness_attempts = 100

shell_launch_timeout_seconds : Str
shell_launch_timeout_seconds = "5"

watchdog_script : Str
watchdog_script = Str.join_with(
	[
		"set -eu;",
		"watchdog=;",
		"cleanup_launch() { if [ -n \"$watchdog\" ];",
		"then kill -TERM \"$watchdog\" 2>/dev/null || true;",
		"fi;",
		"};",
		"trap cleanup_launch 0 HUP INT TERM;",
		"safe_pid() { case \"$1\" in ''|*[!0-9]*) return 1;;",
		"esac;",
		"[ \"$1\" -gt 1 ] 2>/dev/null;",
		"};",
		"context_is_owned() { case \"$TEMP_DIR\" in \"$TEMP_PARENT\"/roc-redis-integration-*) ;;",
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
		"info=$(\"$TIMEOUT_PROGRAM\" --signal=TERM --kill-after=1s 1s \"$REDIS_CLI\" --raw -t 0.5 -h 127.0.0.1 -p \"$REDIS_PORT\" INFO server 2>/dev/null) || return 1;",
		"info=$(printf '%s' \"$info\" | tr -d '\\r');",
		"nl='\n';",
		"case \"$nl$info$nl\" in *\"$nl\"\"process_id:$candidate\"\"$nl\"*) return 0;;",
		"*) return 1;;",
		"esac;",
		"};",
		"redis_endpoint_absent() { status=0;",
		"\"$TIMEOUT_PROGRAM\" --signal=TERM --kill-after=1s 1s \"$REDIS_CLI\" --raw -t 0.5 -h 127.0.0.1 -p \"$REDIS_PORT\" PING >/dev/null 2>&1 || status=$?;",
		"[ \"$status\" -eq 1 ] || return 1;",
		"sleep 0.05;",
		"status=0;",
		"\"$TIMEOUT_PROGRAM\" --signal=TERM --kill-after=1s 1s \"$REDIS_CLI\" --raw -t 0.5 -h 127.0.0.1 -p \"$REDIS_PORT\" PING >/dev/null 2>&1 || status=$?;",
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
		"then rm -f -- \"$REDIS_PIDFILE\" \"$TEMP_DIR/redis.log\" \"$WATCHDOG_PIDFILE\" \"$OWNER_FILE\" \"$CLEANUP_REQUEST\" \"$PENDING_ACK\";",
		"rmdir -- \"$TEMP_DIR\" 2>/dev/null || true;",
		"fi) </dev/null >/dev/null 2>&1 &",
		"watchdog=$!;",
		"printf '%s\\n' \"$watchdog\" >\"$WATCHDOG_PIDFILE\";",
		"printf '%s\\n' \"$watchdog\";",
		"trap - 0 HUP INT TERM",
	],
	" ",
)

main! : List(OsStr) => Try({}, [HarnessFailed(Str), Exit(I32), ..])
main! = |args| {
	backend = test_backend!({})?
	require_commands!(["roc", "redis-server", "redis-cli", "timeout", "sh", "kill", "sleep", "tr", "rm", "chmod"])?
	requested_port = parse_requested_port!(args)?
	harness_pid = capture_harness_pid!({})?
	temp_parent = Env.temp_dir!()
	verify_startup_window_sigkill!(temp_parent)?
	test_dir = create_test_dir!(temp_parent)?

	result = run_in_directory!(test_dir, temp_parent, harness_pid, requested_port, backend)
	cleanup_result = remove_test_directory_if_idle!(test_dir)

	match (result, cleanup_result) {
		(Ok({}), Ok({})) => Ok({})
		(Err(error), Ok({})) => Err(error)
		(Ok({}), Err(error)) => Err(HarnessFailed("remove ${test_dir.display()}: ${Str.inspect(error)}"))
		(Err(error), Err(cleanup_error)) =>
			Err(HarnessFailed("${describe_harness_error(error)}; also failed to remove ${test_dir.display()}: ${Str.inspect(cleanup_error)}"))
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
	redis_active = pidfile_process_is_alive!(test_dir.join("redis.pid"), "Redis")?
	watchdog_active = pidfile_process_is_alive!(test_dir.join("watchdog.pid"), "Redis watchdog")?
	cleanup_requested = test_dir.join("redis-cleanup.request").exists!() ? |error| HarnessFailed("inspect Redis cleanup request: ${Str.inspect(error)}")
	if redis_active or watchdog_active or cleanup_requested {
		Err(HarnessFailed("refusing to remove ${test_dir.display()}: Redis or its watchdog is still active; identity evidence was preserved"))
	} else {
		test_dir.delete_all!().map_err(|error| HarnessFailed("remove ${test_dir.display()}: ${Str.inspect(error)}"))
	}
}

pidfile_process_is_alive! : Path.Path, Str => Try(Bool, [HarnessFailed(Str), ..])
pidfile_process_is_alive! = |pid_path, label|
	match read_pid_if_present!(pid_path, label) {
		Ok(Pid(pid)) => Ok(process_is_alive!(pid))
		Ok(NoPid) => Ok(Bool.False)
		Err(error) => Err(error)
	}

verify_startup_window_sigkill! : Path.Path => Try({}, [HarnessFailed(Str), ..])
verify_startup_window_sigkill! = |temp_parent| {
	test_dir = create_test_dir!(temp_parent)?
	result = run_startup_window_sigkill!(test_dir, temp_parent)
	exists = test_dir.exists!() ? |error| HarnessFailed("inspect startup-window test directory: ${Str.inspect(error)}")
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

run_startup_window_sigkill! : Path.Path, Path.Path => Try({}, [HarnessFailed(Str), ..])
run_startup_window_sigkill! = |test_dir, temp_parent| {
	sentinel_pid = launch_sentinel!({})?
	result = run_startup_window_with_sentinel!(test_dir, temp_parent, sentinel_pid)
	sentinel_cleanup = stop_process!(sentinel_pid, "startup-window sentinel")
	match (result, sentinel_cleanup) {
		(Ok({}), Ok({})) => Ok({})
		(Err(error), Ok({})) => Err(error)
		(Ok({}), Err(error)) => Err(error)
		(Err(error), Err(cleanup_error)) => Err(HarnessFailed("${describe_harness_error(error)}; sentinel cleanup also failed: ${describe_harness_error(cleanup_error)}"))
	}
}

run_startup_window_with_sentinel! : Path.Path, Path.Path, Str => Try({}, [HarnessFailed(Str), ..])
run_startup_window_with_sentinel! = |test_dir, temp_parent, sentinel_pid| {
	owner_path = test_dir.join("harness.owner")
	owner_path.write_utf8!("${sentinel_pid}\n") ? |error| HarnessFailed("write startup-window ownership marker: ${Str.inspect(error)}")
	seed = Random.seed_u64!() ? |error| HarnessFailed("choose startup-window Redis port: ${Str.inspect(error)}")
	port = random_port(seed, 0)
	pid_path = test_dir.join("redis.pid")
	log_path = test_dir.join("redis.log")
	watchdog_pid = launch_watchdog!(test_dir, temp_parent, owner_path, sentinel_pid, pid_path, port)?
	ensure_process_active!(watchdog_pid, "startup-window watchdog")?
	# Force the exact race this watchdog covers: the pidfile is present but
	# empty when its monitored parent dies, and Redis appears only afterward.
	pid_path.write_utf8!("") ? |error| HarnessFailed("write empty startup-window Redis pidfile: ${Str.inspect(error)}")
	{} = signal_pid!(sentinel_pid, "KILL", "startup-window sentinel")?
	_ = wait_for_exit!(sentinel_pid, 40)
	wait_for_marker!(test_dir.join("redis-pid.pending"), "Redis watchdog empty-pidfile acknowledgment", 100)?

	match launch_redis_daemon!(test_dir, pid_path, log_path, port) {
		Err(error) => fail_after_cleanup(describe_harness_error(error), cleanup_failed_candidate!(port, pid_path, test_dir.join("redis-cleanup.request"), watchdog_pid))
		Ok(exit_code) if exit_code != 0 => fail_after_cleanup("startup-window Redis launch exited ${exit_code.to_str()}", cleanup_failed_candidate!(port, pid_path, test_dir.join("redis-cleanup.request"), watchdog_pid))
		Ok(_) => {
			watchdog_stopped = wait_for_exit!(watchdog_pid, 400)
			redis_active = pidfile_process_is_alive!(pid_path, "startup-window Redis")?
			endpoint_absent = redis_endpoint_absent!(port)?
			if watchdog_stopped and !redis_active and endpoint_absent {
				Ok({})
			} else {
				cleanup = cleanup_failed_candidate!(port, pid_path, test_dir.join("redis-cleanup.request"), watchdog_pid)
				fail_after_cleanup("preinstalled watchdog did not clean Redis published after startup-window sentinel SIGKILL", cleanup)
			}
		}
	}
}

launch_sentinel! : {} => Try(Str, [HarnessFailed(Str), ..])
launch_sentinel! = |_| {
	command = Cmd.new_str("timeout")
		.args_str(["--signal=TERM", "--kill-after=1s", shell_launch_timeout_seconds, "sh", "-c", "sleep 30 </dev/null >/dev/null 2>&1 & child=$!; printf '%s\\n' \"$child\""])
	match command.exec_output!() {
		Ok({ stdout_utf8, .. }) => HarnessText.parse_pid_text(stdout_utf8).map_err(|message| HarnessFailed("launch startup-window sentinel: ${message}"))
		Err(error) => Err(HarnessFailed("launch startup-window sentinel: ${Str.inspect(error)}"))
	}
}

wait_for_pid! : Path.Path, U8 => Try(Str, [HarnessFailed(Str), ..])
wait_for_pid! = |pid_path, attempts_remaining|
	match read_pid_if_present!(pid_path, "Redis") {
		Ok(Pid(pid)) => Ok(pid)
		Ok(NoPid) if attempts_remaining > 0 => {
			Sleep.millis!(25)
			wait_for_pid!(pid_path, attempts_remaining - 1)
		}
		Ok(NoPid) => Err(HarnessFailed("startup-window Redis did not write its pidfile"))
		Err(error) => Err(error)
	}

run_in_directory! : Path.Path, Path.Path, Str, [AnyPort, ExactPort(U16)], Str => Try({}, [HarnessFailed(Str), ..])
run_in_directory! = |test_dir, temp_parent, harness_pid, requested_port, backend| {
	owner_path = test_dir.join("harness.owner")
	owner_path.write_utf8!("${harness_pid}\n") ? |error| HarnessFailed("write harness ownership marker: ${Str.inspect(error)}")
	client_binary = build_client!(test_dir, backend)?
	seed = Random.seed_u64!() ? |error| HarnessFailed("choose Redis port: ${Str.inspect(error)}")
	server = start_redis!(test_dir, temp_parent, owner_path, harness_pid, requested_port, seed, 0)?

	test_result = run_client!(client_binary, server.port)
	stop_result = stop_redis!(server)

	match (test_result, stop_result) {
		(Ok({}), Ok({})) => {
			Stdout.line!("Redis integration test passed on isolated port ${server.port.to_str()} (subject_backend=${backend})")
				.map_err(|error| HarnessFailed("write success message: ${Str.inspect(error)}"))
		}
		(Err(error), Ok({})) => Err(error)
		(Ok({}), Err(error)) => Err(error)
		(Err(error), Err(stop_error)) =>
			Err(HarnessFailed("${describe_harness_error(error)}; ${describe_harness_error(stop_error)}"))
		}
}

capture_harness_pid! : {} => Try(Str, [HarnessFailed(Str), ..])
capture_harness_pid! = |_| {
	# This tiny shell is spawned directly, so its PPID is the Roc harness. The
	# longer-lived watchdog launch is separately bounded by GNU timeout.
	match Cmd.new_str("sh").args_str(["-c", "printf '%s\\n' \"$PPID\""]).exec_output!() {
		Ok({ stdout_utf8, .. }) =>
			HarnessText.parse_pid_text(stdout_utf8).map_err(|message| HarnessFailed("capture harness PID: ${message}"))
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) =>
			Err(HarnessFailed("capture harness PID exited ${exit_code.to_str()}: ${HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy).trim()}"))
		Err(error) => Err(HarnessFailed("capture harness PID: ${Str.inspect(error)}"))
	}
}

build_client! : Path.Path, Str => Try(Path.Path, [HarnessFailed(Str), ..])
build_client! = |test_dir, backend| {
	client_binary = test_dir.join("basic-cli-integration")
	source = if transport_profile!({}) {
		"benchmarks/transport.roc"
	} else {
		"integration/basic_cli.roc"
	}
	command =
		Cmd.new_str("timeout")
			.args_str([
				"--signal=TERM",
				"--kill-after=5s",
				command_timeout_seconds,
				"roc",
				"build",
				"--opt=${backend}",
				"--output=${client_binary.display()}",
				source,
			])

	require_bounded_success!("build basic-cli integration", command)?
	is_executable = client_binary.is_executable!() ? |error| HarnessFailed("inspect built basic-cli integration: ${Str.inspect(error)}")
	if is_executable {
		Ok(client_binary)
	} else {
		Err(HarnessFailed("roc build succeeded without creating an executable at ${client_binary.display()}"))
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

parse_requested_port! : List(OsStr) => Try([AnyPort, ExactPort(U16)], [HarnessFailed(Str), ..])
parse_requested_port! = |args|
	match args.drop_first(1) {
		[] =>
			match Env.var_str!(OsStr.from_str("ROC_REDIS_TEST_PORT")) {
				Ok(port_text) => parse_port(port_text).map_ok(|port| ExactPort(port))
				Err(VarNotFound(_)) => Ok(AnyPort)
				Err(error) => Err(HarnessFailed("read ROC_REDIS_TEST_PORT: ${Str.inspect(error)}"))
			}
		[port_arg] => {
			port_text = OsStr.to_str_try(port_arg) ? |_| HarnessFailed("port is not valid UTF-8")
			Ok(ExactPort(parse_port(port_text)?))
		}
		_ => Err(HarnessFailed("usage: roc scripts/test-integration.roc -- [port]"))
	}

parse_port : Str -> Try(U16, [HarnessFailed(Str), ..])
parse_port = |text| {
	invalid = HarnessFailed("port must be a decimal integer from 1 through 65535")
	bytes = text.to_utf8()
	if bytes.is_empty() or bytes.len() > 5 or !(bytes.all(|byte| byte >= 48 and byte <= 57)) {
		Err(invalid)
	} else {
		port = U16.from_str(text) ? |_| invalid
		if port == 0 Err(invalid) else Ok(port)
	}
}

create_test_dir! : Path.Path => Try(Path.Path, [HarnessFailed(Str), ..])
create_test_dir! = |parent| create_test_dir_with_attempts!(parent, 5)

create_test_dir_with_attempts! : Path.Path, U8 => Try(Path.Path, [HarnessFailed(Str), ..])
create_test_dir_with_attempts! = |parent, attempts_remaining| {
	seed = Random.seed_u64!() ? |error| HarnessFailed("choose temporary-directory name: ${Str.inspect(error)}")
	path = parent.join("roc-redis-integration-${seed.to_str()}")
	match path.create_dir!() {
		Ok({}) => {
			privacy_result = make_directory_private!(path)
			match privacy_result {
				Ok({}) => Ok(path)
				Err(error) => {
					delete_result = path.delete_all!().map_err(|delete_error| HarnessFailed("remove insecure temporary directory ${path.display()}: ${Str.inspect(delete_error)}"))
					fail_after_cleanup(describe_harness_error(error), delete_result)
				}
			}
		}
		Err(PathErr(AlreadyExists, _)) if attempts_remaining > 1 =>
			create_test_dir_with_attempts!(parent, attempts_remaining - 1)
		Err(error) => Err(HarnessFailed("create temporary directory ${path.display()}: ${Str.inspect(error)}"))
	}
}

make_directory_private! : Path.Path => Try({}, [HarnessFailed(Str), ..])
make_directory_private! = |path| {
	exit_code = Cmd.new_str("chmod")
		.arg_str("700")
		.arg(path.to_os_str())
		.exec_exit_code!() ? |error| HarnessFailed("make temporary directory private: ${Str.inspect(error)}")
	if exit_code == 0 {
		Ok({})
	} else {
		Err(HarnessFailed("chmod 700 ${path.display()} exited ${exit_code.to_str()}"))
	}
}

start_redis! : Path.Path, Path.Path, Path.Path, Str, [AnyPort, ExactPort(U16)], U64, U8 => Try({ pid : Str, port : U16, watchdog_pid : Str }, [HarnessFailed(Str), ..])
start_redis! = |test_dir, temp_parent, owner_path, harness_pid, requested_port, seed, attempt| {
	if attempt >= port_attempts {
		Err(HarnessFailed("could not start isolated Redis after ${port_attempts.to_str()} port attempts; last log: ${read_log_best_effort!(test_dir)}"))
	} else {
		port =
			match requested_port {
				ExactPort(value) => value
				AnyPort => random_port(seed, attempt)
			}

		match start_candidate!(test_dir, temp_parent, owner_path, harness_pid, port) {
			Ok(Started(server)) => Ok(server)
			Ok(Unavailable) =>
				match requested_port {
					ExactPort(_) => Err(HarnessFailed("could not start isolated Redis on requested port ${port.to_str()}; log: ${read_log_best_effort!(test_dir)}"))
					AnyPort => start_redis!(test_dir, temp_parent, owner_path, harness_pid, requested_port, seed, attempt + 1)
				}
			Err(error) => Err(error)
		}
	}
}

random_port : U64, U8 -> U16
random_port = |seed, attempt| {
	offset = ((seed % random_port_count) + (U8.to_u64(attempt) * 7_919) % random_port_count) % random_port_count
	U64.to_u16_wrap(U16.to_u64(first_random_port) + offset)
}

start_candidate! : Path.Path, Path.Path, Path.Path, Str, U16 => Try([Started({ pid : Str, port : U16, watchdog_pid : Str }), Unavailable], [HarnessFailed(Str), ..])
start_candidate! = |test_dir, temp_parent, owner_path, harness_pid, port| {
	pid_path = test_dir.join("redis.pid")
	log_path = test_dir.join("redis.log")
	cleanup_request_path = test_dir.join("redis-cleanup.request")
	# A failed previous candidate must not leave identity material for this one.
	delete_if_present!(pid_path)?
	delete_if_present!(cleanup_request_path)?
	watchdog_pid = launch_watchdog!(test_dir, temp_parent, owner_path, harness_pid, pid_path, port)?
	ensure_process_active!(watchdog_pid, "Redis parent-death watchdog")?

	exit_result = launch_redis_daemon!(test_dir, pid_path, log_path, port)

	match exit_result {
		Err(error) => fail_after_cleanup!("launch redis-server: ${Str.inspect(error)}", port, pid_path, cleanup_request_path, watchdog_pid)
		Ok(exit_code) => finish_candidate_start!(exit_code, port, pid_path, cleanup_request_path, watchdog_pid)
	}
}

launch_redis_daemon! : Path.Path, Path.Path, Path.Path, U16 => Try(I32, [HarnessFailed(Str), ..])
launch_redis_daemon! = |test_dir, pid_path, log_path, port|
	Cmd.new_str("timeout")
		.args_str([
			"--signal=TERM",
			"--kill-after=2s",
			"10",
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
			test_dir.display(),
			"--pidfile",
			pid_path.display(),
			"--logfile",
			log_path.display(),
			"--loglevel",
			"warning",
		])
		.exec_exit_code!()
		.map_err(|error| HarnessFailed("launch redis-server: ${Str.inspect(error)}"))

finish_candidate_start! : I32, U16, Path.Path, Path.Path, Str => Try([Started({ pid : Str, port : U16, watchdog_pid : Str }), Unavailable], [HarnessFailed(Str), ..])
finish_candidate_start! = |exit_code, port, pid_path, cleanup_request_path, watchdog_pid| {
	if exit_code == 124 or exit_code == 137 {
		fail_after_cleanup!("redis-server launch exceeded 10s", port, pid_path, cleanup_request_path, watchdog_pid)
	} else if exit_code == 125 or exit_code == 126 or exit_code == 127 {
		fail_after_cleanup!("could not invoke redis-server through GNU timeout (exit ${exit_code.to_str()})", port, pid_path, cleanup_request_path, watchdog_pid)
	} else if exit_code != 0 {
		cleanup = cleanup_failed_candidate!(port, pid_path, cleanup_request_path, watchdog_pid)
		match cleanup {
			Ok({}) => Ok(Unavailable)
			Err(error) => Err(error)
		}
	} else {
		match wait_for_owner!(port, pid_path, watchdog_pid, readiness_attempts) {
			Ok(Ready(pid)) => Ok(Started({ pid, port, watchdog_pid }))
			Ok(NotReady) => {
				cleanup = cleanup_failed_candidate!(port, pid_path, cleanup_request_path, watchdog_pid)
				match cleanup {
					Ok({}) => Ok(Unavailable)
					Err(error) => Err(error)
				}
			}
			Err(error) => {
				cleanup = cleanup_failed_candidate!(port, pid_path, cleanup_request_path, watchdog_pid)
				match cleanup {
					Ok({}) => Err(error)
					Err(cleanup_error) => Err(HarnessFailed("${describe_harness_error(error)}; cleanup also failed: ${describe_harness_error(cleanup_error)}"))
				}
			}
		}
	}
}

fail_after_cleanup! : Str, U16, Path.Path, Path.Path, Str => Try(a, [HarnessFailed(Str), ..])
fail_after_cleanup! = |message, port, pid_path, cleanup_request_path, watchdog_pid|
	fail_after_cleanup(message, cleanup_failed_candidate!(port, pid_path, cleanup_request_path, watchdog_pid))

cleanup_failed_candidate! : U16, Path.Path, Path.Path, Str => Try({}, [HarnessFailed(Str), ..])
cleanup_failed_candidate! = |port, pid_path, cleanup_request_path, watchdog_pid| {
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

launch_watchdog! : Path.Path, Path.Path, Path.Path, Str, Path.Path, U16 => Try(Str, [HarnessFailed(Str), ..])
launch_watchdog! = |test_dir, temp_parent, owner_path, harness_pid, redis_pid_path, redis_port| {
	pid_path = test_dir.join("watchdog.pid")
	delete_if_present!(pid_path)?
	pending_ack_path = test_dir.join("redis-pid.pending")
	delete_if_present!(pending_ack_path)?
	command =
		Cmd.new_str("timeout")
			.args_str(["--signal=TERM", "--kill-after=2s", shell_launch_timeout_seconds, "sh", "-c", watchdog_script])
			.env_str("HARNESS_PID", harness_pid)
			.env(OsStr.from_str("TEMP_DIR"), test_dir.to_os_str())
			.env(OsStr.from_str("TEMP_PARENT"), temp_parent.to_os_str())
			.env(OsStr.from_str("OWNER_FILE"), owner_path.to_os_str())
			.env(OsStr.from_str("WATCHDOG_PIDFILE"), pid_path.to_os_str())
			.env(OsStr.from_str("REDIS_PIDFILE"), redis_pid_path.to_os_str())
			.env(OsStr.from_str("CLEANUP_REQUEST"), test_dir.join("redis-cleanup.request").to_os_str())
			.env_str("REDIS_PORT", redis_port.to_str())
			.env_str("REDIS_CLI", "redis-cli")
			.env_str("TIMEOUT_PROGRAM", "timeout")
			.env(OsStr.from_str("PENDING_ACK"), pending_ack_path.to_os_str())

	match command.exec_output!() {
		Ok({ stdout_utf8, stderr_utf8_lossy }) => {
			captured_pid = HarnessText.parse_pid_text(stdout_utf8)
			pidfile_pid = read_pid_if_present!(pid_path, "Redis watchdog")
			match (captured_pid, pidfile_pid) {
				(Ok(pid), Ok(Pid(file_pid))) if pid == file_pid =>
					if pid == harness_pid {
						Err(HarnessFailed("Redis watchdog reported protected PID ${pid}"))
					} else if process_is_alive!(pid) {
						Ok(pid)
					} else {
						Err(HarnessFailed("Redis parent-death watchdog exited during launch"))
					}
				(Ok(pid), Ok(Pid(file_pid))) => {
					# stdout comes directly from `$!` in the fixed launcher. A
					# mismatched pidfile is evidence only, never a signal target.
					cleanup = stop_process!(pid, "captured Redis watchdog")
					fail_after_cleanup("Redis watchdog PID mismatch: captured ${pid}, pidfile ${file_pid}", cleanup)
				}
				(Ok(pid), Ok(NoPid)) => {
					cleanup = stop_process!(pid, "captured Redis watchdog")
					fail_after_cleanup("Redis watchdog returned PID ${pid} without writing its pidfile: ${stderr_utf8_lossy.trim()}", cleanup)
				}
				(Ok(pid), Err(error)) => {
					cleanup = stop_process!(pid, "captured Redis watchdog")
					fail_after_cleanup(describe_harness_error(error), cleanup)
				}
				(Err(message), Ok(Pid(pid))) => {
					Err(HarnessFailed("Redis watchdog ${message}; refusing to signal uncorroborated pidfile PID ${pid}; identity evidence was preserved: ${stderr_utf8_lossy.trim()}"))
				}
				(Err(message), Ok(NoPid)) => Err(HarnessFailed("Redis watchdog ${message}: ${stderr_utf8_lossy.trim()}"))
				(Err(message), Err(error)) => Err(HarnessFailed("Redis watchdog ${message}; ${describe_harness_error(error)}: ${stderr_utf8_lossy.trim()}"))
			}
		}
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) => {
			cleanup = cleanup_launched_process!(pid_path, stdout_utf8_lossy, "Redis watchdog")
			output = HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy).trim()
			message =
				if exit_code == 124 or exit_code == 137 {
					"Redis watchdog launch exceeded ${shell_launch_timeout_seconds}s: ${output}"
				} else {
					"Redis watchdog launch exited ${exit_code.to_str()}: ${output}"
				}
			fail_after_cleanup(message, cleanup)
		}
		Err(error) => {
			cleanup = cleanup_launched_process!(pid_path, "", "Redis watchdog")
			fail_after_cleanup("could not launch Redis watchdog: ${Str.inspect(error)}", cleanup)
		}
	}
}

wait_for_owner! : U16, Path.Path, Str, U8 => Try([Ready(Str), NotReady], [HarnessFailed(Str), ..])
wait_for_owner! = |port, pid_path, watchdog_pid, attempts_remaining| {
	if attempts_remaining == 0 {
		Ok(NotReady)
	} else if !(process_is_alive!(watchdog_pid)) {
		Err(HarnessFailed("Redis parent-death watchdog ${watchdog_pid} exited during startup"))
	} else {
		match read_startup_pid_if_present!(pid_path, "Redis") {
			Ok(Pid(pid)) =>
				if server_is_owner!(port, pid) {
					Ok(Ready(pid))
				} else {
					Sleep.millis!(50)
					wait_for_owner!(port, pid_path, watchdog_pid, attempts_remaining - 1)
				}
			Ok(NoPid) => {
				Sleep.millis!(50)
				wait_for_owner!(port, pid_path, watchdog_pid, attempts_remaining - 1)
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
	if HarnessText.valid_pid(pid) and remaining.all(|line| line.is_empty()) {
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

server_is_owner! : U16, Str => Bool
server_is_owner! = |port, expected_pid| {
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
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) => Err(HarnessFailed("Redis endpoint absence probe exited ${exit_code.to_str()}: ${HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy).trim()}"))
		Err(error) => Err(HarnessFailed("probe Redis endpoint absence: ${Str.inspect(error)}"))
	}

run_client! : Path.Path, U16 => Try({}, [HarnessFailed(Str), ..])
run_client! = |client_binary, port| {
	command =
		Cmd.new_str("timeout")
			.args([
				OsStr.from_str("--signal=TERM"),
				OsStr.from_str("--kill-after=5s"),
				OsStr.from_str(command_timeout_seconds),
				client_binary.to_os_str(),
				OsStr.from_str("127.0.0.1"),
				OsStr.from_str(port.to_str()),
			])

	require_bounded_success!("run basic-cli integration", command)
}

require_bounded_success! : Str, Cmd.Cmd => Try({}, [HarnessFailed(Str), ..])
require_bounded_success! = |label, command| {
	match command.exec_output!() {
		Ok({ stdout_utf8, .. }) => {
			if label == "run basic-cli integration" and transport_profile!({}) {
				Stdout.line!(stdout_utf8.trim()) ? |_| HarnessFailed("could not print transport trace")
			}
			Ok({})
		}
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) => {
			output = HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy).trim()
			suffix = if output.is_empty() "" else ": ${output}"
			if exit_code == 124 or exit_code == 137 {
				Err(HarnessFailed("${label} exceeded ${command_timeout_seconds}s${suffix}"))
			} else {
				Err(HarnessFailed("${label} exited ${exit_code.to_str()}${suffix}"))
			}
		}
		Err(error) => Err(HarnessFailed("${label} could not start: ${Str.inspect(error)}"))
	}
}

transport_profile! : {} => Bool
transport_profile! = |_| match Env.var_str!(OsStr.from_str("ROC_REDIS_TRACE_TRANSPORT")) {
	Ok("1") => True
	_ => False
}

stop_redis! : { pid : Str, port : U16, watchdog_pid : Str } => Try({}, [HarnessFailed(Str), ..])
stop_redis! = |server| {
	redis_result = stop_redis_process!(server.port, server.pid, "Redis")
	match redis_result {
		Err(error) => Err(error)
		Ok({}) => stop_process!(server.watchdog_pid, "Redis parent-death watchdog")
	}
}

SignalDecision : [AlreadyExited, RefuseUnowned, SignalOwned]

signal_decision : Bool, Bool -> SignalDecision
signal_decision = |alive, owns_identity|
	if !alive AlreadyExited else if owns_identity SignalOwned else RefuseUnowned

redis_signal_decision! : U16, Str => SignalDecision
redis_signal_decision! = |port, pid|
	signal_decision(process_is_alive!(pid), server_is_owner!(port, pid))

stop_redis_process! : U16, Str, Str => Try({}, [HarnessFailed(Str), ..])
stop_redis_process! = |port, pid, label| {
	match redis_signal_decision!(port, pid) {
		AlreadyExited => finish_redis_stop!(port, pid)
		RefuseUnowned => Err(HarnessFailed("refusing to signal process ${pid}: exact Redis INFO ownership of port ${port.to_str()} was not established"))
		SignalOwned => {
			term_result = signal_pid!(pid, "TERM", label)
			if wait_for_exit!(pid, 40) {
				finish_redis_stop!(port, pid)
			} else {
				match redis_signal_decision!(port, pid) {
					AlreadyExited => finish_redis_stop!(port, pid)
					RefuseUnowned => Err(HarnessFailed("refusing SIGKILL for process ${pid}: exact Redis INFO ownership of port ${port.to_str()} was lost after SIGTERM; TERM=${describe_signal_result(term_result)}"))
					SignalOwned => {
						kill_result = signal_pid!(pid, "KILL", label)
						if wait_for_exit!(pid, 40) {
							finish_redis_stop!(port, pid)
						} else {
							Err(HarnessFailed("${label} process ${pid} did not exit after identity-guarded SIGKILL; TERM=${describe_signal_result(term_result)}, KILL=${describe_signal_result(kill_result)}"))
						}
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
		(FoundPid(pid), MissingPid) => stop_process!(pid, "captured ${label}")
		(MissingPid, FoundPid(pid)) => Err(HarnessFailed("refusing to signal uncorroborated pidfile ${label} PID ${pid}; identity evidence was preserved"))
		(FoundPid(first_pid), FoundPid(second_pid)) if first_pid == second_pid => stop_process!(first_pid, label)
		(FoundPid(first_pid), FoundPid(second_pid)) => {
			first_result = stop_process!(first_pid, "captured ${label}")
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
fail_after_cleanup = |message, cleanup|
	match cleanup {
		Ok({}) => Err(HarnessFailed(message))
		Err(error) => Err(HarnessFailed("${message}; cleanup also failed: ${describe_harness_error(error)}"))
	}

signal_pid! : Str, Str, Str => Try({}, [HarnessFailed(Str), ..])
signal_pid! = |pid, signal, label| {
	exit_code = Cmd.new_str("kill")
		.args_str(["-${signal}", pid])
		.exec_exit_code!() ? |error| HarnessFailed("signal ${label} process ${pid}: ${Str.inspect(error)}")
	if exit_code == 0 {
		Ok({})
	} else {
		Err(HarnessFailed("kill -${signal} ${pid} exited ${exit_code.to_str()} for ${label}"))
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
	exists = path.is_file!() ? |error| HarnessFailed("inspect ${label}: ${Str.inspect(error)}")
	acknowledged = if exists {
		contents = path.read_utf8!() ? |error| HarnessFailed("read ${label}: ${Str.inspect(error)}")
		contents == "pending\n"
	} else {
		Bool.False
	}
	if acknowledged {
		Ok({})
	} else if attempts_remaining == 0 {
		Err(HarnessFailed("timed out waiting for ${label}"))
	} else {
		Sleep.millis!(25)
		wait_for_marker!(path, label, attempts_remaining - 1)
	}
}

process_is_alive! : Str => Bool
process_is_alive! = |pid| {
	# Capture output so the expected non-zero probe after process exit does not
	# leak `kill: no such process` noise into successful test runs.
	match Cmd.new_str("kill").args_str(["-0", pid]).exec_output!() {
		Ok(_) => Bool.True
		_ => Bool.False
	}
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
read_log_best_effort! = |test_dir| {
	path = test_dir.join("redis.log")
	match path.read_utf8!() {
		Ok(contents) => contents
		Err(error) => "<unavailable: ${Str.inspect(error)}>"
	}
}

describe_harness_error : [HarnessFailed(Str), ..] -> Str
describe_harness_error = |error|
	match error {
		HarnessFailed(message) => message
		other => Str.inspect(other)
	}

expect parse_port("1") == Ok(1)

expect parse_port("65535") == Ok(65535)

expect ["", "0", "+1", "0x10", "1_0", "65536", "18446744073709551617"].all(|text| parse_port(text).is_err())

expect random_port(0, 0) == 20_000

expect random_port(29_999, 0) == 49_999

expect {
	port = random_port(U64.highest, 19)
	port >= 20_000 and port <= 49_999
}

expect HarnessText.valid_pid("2")

expect !(HarnessText.valid_pid(""))

expect !(HarnessText.valid_pid("1"))

expect !(HarnessText.valid_pid("12 3"))

expect HarnessText.parse_pid_text("123\n") == Ok("123")

expect HarnessText.parse_pid_text("123\n456\n").is_err()

expect parse_pidfile_text("123").is_err()

expect parse_pidfile_text("123\n") == Ok("123")

expect ["", "12x", "123\n"].map(startup_pid_state) == [PendingPid, InvalidPid("expected one positive process ID, received \"12x\""), ReadyPid("123")]

expect first_ready_startup_pid(["", "12x", "123\n"]) == Ok("123")

expect signal_decision(Bool.False, Bool.False) == AlreadyExited

expect signal_decision(Bool.True, Bool.False) == RefuseUnowned

expect signal_decision(Bool.True, Bool.True) == SignalOwned

## The watchdog exists before Redis can be launched, waits for the startup
## pidfile after a parent SIGKILL, and rechecks exact INFO ownership separately
## before TERM and KILL.
expect watchdog_script.contains("while kill -0 \"$HARNESS_PID\"") and watchdog_script.contains("$CLEANUP_REQUEST")

expect watchdog_script.contains("limit=300") and watchdog_script.contains("IFS= read -r child")

expect watchdog_script.split_on("redis_is_owner \"$child\"").len() == 4

expect watchdog_script.contains("preserve=1") and watchdog_script.contains("&& redis_endpoint_absent; then preserve=0")

expect !(watchdog_script.contains("preserve=0; if safe_pid"))

expect watchdog_script.contains("printf 'pending\\n' >\"$PENDING_ACK\"")

expect watchdog_script.contains("context_is_owned") and watchdog_script.contains("process_id:$candidate") and watchdog_script.contains("rm -f -- \"$REDIS_PIDFILE\"")
