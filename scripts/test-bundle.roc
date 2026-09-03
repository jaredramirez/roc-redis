## Verify the distributable package from the perspective of a fresh downstream
## consumer.
##
## Run this application from the repository root. All orchestration and
## validation lives in Roc. This harness retains its qualified fixed shell
## bridge to launch and supervise the Roc/basic-webserver fixture while the
## platform's newer native resource APIs are evaluated separately. Values cross that
## boundary only through environment variables, and the launch itself is bounded.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
}

import HarnessText
import pf.Cmd
import pf.Env
import pf.OsStr exposing [OsStr]
import pf.Path
import pf.Random
import pf.Sleep
import pf.Stdout
import pf.Tcp

package_url_placeholder : Str
package_url_placeholder = "__ROC_REDIS_BUNDLE_URL__"

command_timeout : Str
command_timeout = "180s"

server_attempts : U64
server_attempts = 8

server_probe_attempts : U64
server_probe_attempts = 40

server_probe_delay_ms : U64
server_probe_delay_ms = 50

shell_launch_timeout : Str
shell_launch_timeout = "5s"

launch_server_script : Str
launch_server_script =
	\\set -eu
	\\server_pid=
	\\watchdog_pid=
	\\stop_pid() {
	\\  target=$1
	\\  if kill -0 "$target" 2>/dev/null; then
	\\    kill -TERM "$target" 2>/dev/null || true
	\\    attempt=0
	\\    while kill -0 "$target" 2>/dev/null && [ "$attempt" -lt 40 ]; do sleep 0.05; attempt=$((attempt + 1)); done
	\\    if kill -0 "$target" 2>/dev/null; then
	\\      kill -KILL "$target" 2>/dev/null || true
	\\      attempt=0
	\\      while kill -0 "$target" 2>/dev/null && [ "$attempt" -lt 40 ]; do sleep 0.05; attempt=$((attempt + 1)); done
	\\    fi
	\\  fi
	\\}
	\\cleanup_launch() {
	\\  if [ -n "$watchdog_pid" ]; then stop_pid "$watchdog_pid"; fi
	\\  if [ -n "$server_pid" ]; then stop_pid "$server_pid"; fi
	\\}
	\\trap cleanup_launch 0 HUP INT TERM
	\\"$ROC_BUNDLE_SERVER_BINARY" >"$ROC_BUNDLE_HTTP_LOG" 2>&1 &
	\\server_pid=$!
	\\printf '%s\n' "$server_pid" >"$SERVER_PIDFILE"
	\\(
	\\  while kill -0 "$HARNESS_PID" 2>/dev/null && kill -0 "$server_pid" 2>/dev/null; do sleep 0.1; done
	\\  if ! kill -0 "$HARNESS_PID" 2>/dev/null; then
	\\    stop_pid "$server_pid"
	\\    owner=
	\\    if [ -f "$OWNER_FILE" ]; then IFS= read -r owner <"$OWNER_FILE" || owner=; fi
	\\    case "$TEMP_ROOT" in
	\\      "$TEMP_PARENT"/roc-redis-bundle-test-*)
	\\        if [ "$owner" = "$HARNESS_PID" ] && ! kill -0 "$server_pid" 2>/dev/null; then rm -rf -- "$TEMP_ROOT"; fi
	\\        ;;
	\\    esac
	\\  fi
	\\) </dev/null >/dev/null 2>&1 &
	\\watchdog_pid=$!
	\\printf '%s\n' "$watchdog_pid" >"$WATCHDOG_PIDFILE"
	\\printf '%s\n' "$server_pid"
	\\trap - 0 HUP INT TERM

main! : List(OsStr) => Try({}, [BundleTestFailed(Str), Exit(I32), ..])
main! = |_args| {
	backend = widen_for_main(test_backend!({}))?
	{} = widen_for_main(require_supported_host!({}))?
	roc_program = widen_for_main(roc_program!({}))?
	timeout_program = widen_for_main(timeout_program!({}))?
	{} = widen_for_main(require_available!(roc_program))?
	{} = widen_for_main(require_available!("sh"))?
	{} = widen_for_main(require_available!("kill"))?
	{} = widen_for_main(require_available!("sleep"))?
	{} = widen_for_main(require_available!("rm"))?
	{} = widen_for_main(require_available!("chmod"))?

	root_result = Env.cwd!().map_err(|error| BundleTestFailed("determine repository root: ${Str.inspect(error)}"))
	root = widen_for_main(root_result)?
	{} = widen_for_main(require_repo_root!(root))?
	harness_pid = widen_for_main(capture_harness_pid!({}))?
	temp_parent = Env.temp_dir!()
	temp_root = widen_for_main(create_temp_dir!(temp_parent, 8))?
	owner_path = temp_root.join("harness.owner")

	test_result = run_bundle_test!(root, temp_root, temp_parent, owner_path, harness_pid, roc_program, timeout_program, backend)
	cleanup_result =
		Path.delete_all!(temp_root)
			.map_err(|error| BundleTestFailed("remove temporary directory ${Path.to_inspect(temp_root)}: ${Str.inspect(error)}"))

	{} = widen_for_main(combine_results(test_result, cleanup_result))?
	write_result = Stdout.line!("Bundle consumer check passed (subject_backend=${backend}).")
		.map_err(|error| BundleTestFailed("write success message: ${Str.inspect(error)}"))
	{} = widen_for_main(write_result)?
	Ok({})
}

test_backend! : {} => Try(Str, [BundleTestFailed(Str)])
test_backend! = |_| match Env.var_str!(OsStr.from_str("ROC_REDIS_TEST_BACKEND")) {
	Ok("dev") => Ok("dev")
	Ok("speed") => Ok("speed")
	Ok("size") => Ok("size")
	Ok(value) => Err(BundleTestFailed("ROC_REDIS_TEST_BACKEND must be dev, speed, or size; received ${Str.inspect(value)}"))
	Err(VarNotFound(_)) => Ok("dev")
	Err(error) => Err(BundleTestFailed("read ROC_REDIS_TEST_BACKEND: ${Str.inspect(error)}"))
}

capture_harness_pid! : {} => Try(Str, [BundleTestFailed(Str)])
capture_harness_pid! = |_| {
	# This tiny shell is spawned directly, so its PPID is the Roc harness. The
	# longer-lived server/watchdog launch is separately bounded by GNU timeout.
	match Cmd.new_str("sh").args_str(["-c", "printf '%s\\n' \"$PPID\""]).exec_output!() {
		Ok({ stdout_utf8, .. }) => HarnessText.parse_pid_text(stdout_utf8).map_err(|message| BundleTestFailed("capture harness PID: ${message}"))
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) =>
			Err(BundleTestFailed("capture harness PID exited ${exit_code.to_str()}: ${HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy).trim()}"))
		Err(error) => Err(BundleTestFailed("capture harness PID: ${Str.inspect(error)}"))
	}
}

require_supported_host! : {} => Try({}, [BundleTestFailed(Str)])
require_supported_host! = |_| {
	match Env.platform!().os {
		LINUX => Ok({})
		MACOS => Ok({})
		_ => Err(BundleTestFailed("the bundle test currently requires a Unix host with sh and process signals"))
	}
}

roc_program! : {} => Try(Str, [BundleTestFailed(Str)])
roc_program! = |_| {
	match Env.var_str!(OsStr.from_str("ROC")) {
		Ok("") => Err(BundleTestFailed("ROC must name one executable, but it was empty"))
		Ok(program) => Ok(program)
		Err(VarNotFound(_)) => Ok("roc")
		Err(error) => Err(BundleTestFailed("read ROC environment variable: ${Str.inspect(error)}"))
	}
}

timeout_program! : {} => Try(Str, [BundleTestFailed(Str)])
timeout_program! = |_| {
	if Cmd.check_available!("timeout") {
		Ok("timeout")
	} else if Cmd.check_available!("gtimeout") {
		Ok("gtimeout")
	} else {
		Err(BundleTestFailed("GNU timeout is required; enter the Nix development shell (or install coreutils so gtimeout is available on macOS)"))
	}
}

require_available! : Str => Try({}, [BundleTestFailed(Str)])
require_available! = |program| {
	if Cmd.check_available!(program) {
		Ok({})
	} else {
		Err(BundleTestFailed("required executable is unavailable: ${Str.inspect(program)}"))
	}
}

require_repo_root! : Path.Path => Try({}, [BundleTestFailed(Str)])
require_repo_root! = |root| {
	package_main = root.join("package").join("main.roc")
	template_main = root.join("integration").join("bundle_consumer").join("main.roc")
	template_consumer = root.join("integration").join("bundle_consumer").join("Consumer.roc")
	bundle_server = root.join("integration").join("bundle_server.roc")

	package_exists = package_main.is_file!() ? |error| BundleTestFailed("inspect ${Path.to_inspect(package_main)}: ${Str.inspect(error)}")
	main_exists = template_main.is_file!() ? |error| BundleTestFailed("inspect ${Path.to_inspect(template_main)}: ${Str.inspect(error)}")
	consumer_exists = template_consumer.is_file!() ? |error| BundleTestFailed("inspect ${Path.to_inspect(template_consumer)}: ${Str.inspect(error)}")
	server_exists = bundle_server.is_file!() ? |error| BundleTestFailed("inspect ${Path.to_inspect(bundle_server)}: ${Str.inspect(error)}")

	if package_exists and main_exists and consumer_exists and server_exists {
		Ok({})
	} else {
		Err(BundleTestFailed("run scripts/test-bundle.roc from the roc-redis repository root"))
	}
}

create_temp_dir! : Path.Path, U64 => Try(Path.Path, [BundleTestFailed(Str)])
create_temp_dir! = |parent, attempts_left| {
	if attempts_left == 0 {
		Err(BundleTestFailed("could not allocate a unique temporary directory after 8 attempts"))
	} else {
		seed = Random.seed_u64!() ? |error| BundleTestFailed("generate temporary-directory name: ${Str.inspect(error)}")
		candidate = parent.join("roc-redis-bundle-test-${seed.to_str()}")

		match candidate.create_dir!() {
			Ok({}) => {
				privacy_result = make_directory_private!(candidate)
				match privacy_result {
					Ok({}) => Ok(candidate)
					Err(BundleTestFailed(message)) => {
						delete_result = candidate.delete_all!().map_err(|delete_error| BundleTestFailed("remove insecure temporary directory ${candidate.display()}: ${Str.inspect(delete_error)}"))
						fail_after_cleanup(message, delete_result)
					}
				}
			}
			Err(PathErr(AlreadyExists, _)) => create_temp_dir!(parent, attempts_left - 1)
			Err(error) => Err(BundleTestFailed("create temporary directory ${Path.to_inspect(candidate)}: ${Str.inspect(error)}"))
		}
	}
}

make_directory_private! : Path.Path => Try({}, [BundleTestFailed(Str)])
make_directory_private! = |path| {
	exit_code = Cmd.new_str("chmod")
		.arg_str("700")
		.arg(path.to_os_str())
		.exec_exit_code!()
		.map_err(|error| BundleTestFailed("make temporary directory private: ${Str.inspect(error)}"))?
	if exit_code == 0 {
		Ok({})
	} else {
		Err(BundleTestFailed("chmod 700 ${path.display()} exited ${exit_code.to_str()}"))
	}
}

run_bundle_test! : Path.Path, Path.Path, Path.Path, Path.Path, Str, Str, Str, Str => Try({}, [BundleTestFailed(Str)])
run_bundle_test! = |root, temp_root, temp_parent, owner_path, harness_pid, roc_program, timeout_program, backend| {
	{} = owner_path.write_utf8!("${harness_pid}\n") ? |error| BundleTestFailed("write harness ownership marker: ${Str.inspect(error)}")
	package_copy = temp_root.join("package-source")
	bundle_dir = temp_root.join("bundle")
	consumer_dir = temp_root.join("consumer")
	server_log = temp_root.join("http-server.log")
	# `roc bundle` currently needs a writable working directory even when an output
	# directory is supplied. Keep its input and working directory private so the
	# harness works from an immutable Nix-store snapshot and never mutates checkout.
	{} = copy_tree!(root.join("package"), package_copy)?
	{} = bundle_dir.create_dir!() ? |error| BundleTestFailed("create bundle output directory: ${Str.inspect(error)}")
	server_binary = build_bundle_server!(root, temp_root, roc_program, timeout_program, backend)?

	{} = Env.set_cwd!(temp_root) ? |error| BundleTestFailed("enter writable bundle working directory: ${Str.inspect(error)}")
	bundle_result = run_bounded!(
		timeout_program,
		roc_program,
		[
			OsStr.from_str("bundle"),
			Path.to_os_str(package_copy.join("main.roc")),
			Path.to_os_str(package_copy.join("LICENSE")),
			Path.to_os_str(package_copy.join("NOTICE")),
			OsStr.from_str("--output-dir"),
			Path.to_os_str(bundle_dir),
		],
		"bundle package",
	)
	restore_result =
		Env.set_cwd!(root)
			.map_err(|error| BundleTestFailed("restore repository working directory after bundling: ${Str.inspect(error)}"))
	{} = combine_results(bundle_result, restore_result)?

	archive = find_one_archive!(bundle_dir)?
	archive_name = archive.filename().map_err(|error| BundleTestFailed("read bundle archive filename: ${Str.inspect(error)}"))?
	archive_name_str = archive_name.to_str().map_err(|error| BundleTestFailed("bundle archive filename is not valid text: ${Str.inspect(error)}"))?
	health_seed = Random.seed_u64!() ? |error| BundleTestFailed("generate HTTP health token: ${Str.inspect(error)}")
	health_name = "roc-redis-bundle-health-${health_seed.to_str()}"
	health_body = "roc-redis-bundle-health-${health_seed.to_str()}"

	server = start_server!({ temp_root, temp_parent, owner_path, bundle_dir, server_binary, server_log, archive_name: archive_name_str, health_name, health_body, harness_pid, timeout_program }, server_attempts)?
	package_url = "http://127.0.0.1:${server.port.to_str()}/${percent_encode_path_segment(archive_name_str)}"

	test_result = prepare_and_test_consumer!(root, consumer_dir, package_url, roc_program, timeout_program, backend)
	server_stop_result = stop_process!(server.pid, "HTTP bundle server")
	watchdog_stop_result = stop_process!(server.watchdog_pid, "HTTP bundle server parent-death watchdog")
	stop_result = combine_results(server_stop_result, watchdog_stop_result)

	combine_results(test_result, stop_result)
}

build_bundle_server! : Path.Path, Path.Path, Str, Str, Str => Try(Path.Path, [BundleTestFailed(Str)])
build_bundle_server! = |root, temp_root, roc_program, timeout_program, backend| {
	source = root.join("integration").join("bundle_server.roc")
	binary = temp_root.join("bundle-server")
	{} = run_bounded!(
		timeout_program,
		roc_program,
		[
			OsStr.from_str("build"),
			OsStr.from_str("--opt=${backend}"),
			OsStr.from_str("--output=${binary.display()}"),
			source.to_os_str(),
		],
		"build Roc bundle server",
	)?

	is_executable = binary.is_executable!() ? |error| BundleTestFailed("inspect built bundle server: ${Str.inspect(error)}")
	if is_executable {
		Ok(binary)
	} else {
		Err(BundleTestFailed("roc build succeeded without creating an executable at ${binary.display()}"))
	}
}

run_bounded! : Str, Str, List(OsStr), Str => Try({}, [BundleTestFailed(Str)])
run_bounded! = |timeout_program, program, arguments, label| {
	wrapped_arguments =
		[
			OsStr.from_str("--signal=TERM"),
			OsStr.from_str("--kill-after=5s"),
			OsStr.from_str(command_timeout),
			OsStr.from_str(program),
		].concat(arguments)

	exit_code =
		Cmd.new_str(timeout_program)
			.args(wrapped_arguments)
			.exec_exit_code!()
			.map_err(|error| BundleTestFailed("execute ${label}: ${Str.inspect(error)}"))?

	if exit_code == 0 {
		Ok({})
	} else if exit_code == 124 or exit_code == 137 {
		Err(BundleTestFailed("${label} exceeded ${command_timeout}"))
	} else {
		Err(BundleTestFailed("${label} exited with status ${exit_code.to_str()}"))
	}
}

find_one_archive! : Path.Path => Try(Path.Path, [BundleTestFailed(Str)])
find_one_archive! = |bundle_dir| {
	entries = bundle_dir.list!() ? |error| BundleTestFailed("list bundle output directory: ${Str.inspect(error)}")
	archives = collect_archives!(entries, [])?

	match archives {
		[archive] => Ok(archive)
		_ => {
			names = archives.map(Path.display)
			description = if names.is_empty() "none" else Str.join_with(names, ", ")
			Err(BundleTestFailed("expected exactly one regular .tar.zst bundle archive, found: ${description}"))
		}
	}
}

collect_archives! : List(Path.Path), List(Path.Path) => Try(List(Path.Path), [BundleTestFailed(Str)])
collect_archives! = |remaining, archives| {
	match remaining {
		[] => Ok(archives)
		[path, .. as rest] => {
			filename = path.filename().map_err(|error| BundleTestFailed("read bundle output filename: ${Str.inspect(error)}"))?
			filename_str = filename.to_str().map_err(|error| BundleTestFailed("bundle output filename is not valid text: ${Str.inspect(error)}"))?
			is_file = path.is_file!() ? |error| BundleTestFailed("inspect bundle output ${Path.to_inspect(path)}: ${Str.inspect(error)}")
			next = if is_file and filename_str.ends_with(".tar.zst") archives.append(path) else archives
			collect_archives!(rest, next)
		}
	}
}

prepare_and_test_consumer! : Path.Path, Path.Path, Str, Str, Str, Str => Try({}, [BundleTestFailed(Str)])
prepare_and_test_consumer! = |root, consumer_dir, package_url, roc_program, timeout_program, backend| {
	template_dir = root.join("integration").join("bundle_consumer")
	{} = copy_tree!(template_dir, consumer_dir)?

	consumer_main = consumer_dir.join("main.roc")
	source = consumer_main.read_utf8!() ? |error| BundleTestFailed("read downstream package template: ${Str.inspect(error)}")
	placeholder_count = count_occurrences(source, package_url_placeholder)
	if placeholder_count != 1 {
		return Err(BundleTestFailed("expected exactly one ${package_url_placeholder} in ${Path.display(consumer_main)}, found ${placeholder_count.to_str()}"))
	}

	{} = consumer_main.write_utf8!(source.replace_each(package_url_placeholder, package_url)) ? |error| BundleTestFailed("write downstream package manifest: ${Str.inspect(error)}")

	{} = Env.set_cwd!(consumer_dir) ? |error| BundleTestFailed("enter downstream consumer directory: ${Str.inspect(error)}")
	test_result = run_consumer_commands!(roc_program, timeout_program, backend)
	restore_result =
		Env.set_cwd!(root)
			.map_err(|error| BundleTestFailed("restore repository working directory: ${Str.inspect(error)}"))

	combine_results(test_result, restore_result)
}

run_consumer_commands! : Str, Str, Str => Try({}, [BundleTestFailed(Str)])
run_consumer_commands! = |roc_program, timeout_program, backend| {
	{} = run_bounded!(
		timeout_program,
		roc_program,
		[OsStr.from_str("check"), OsStr.from_str("main.roc"), OsStr.from_str("--no-cache")],
		"check downstream bundle consumer",
	)?

	run_bounded!(
		timeout_program,
		roc_program,
		[
			OsStr.from_str("test"),
			OsStr.from_str("--opt=${backend}"),
			OsStr.from_str("main.roc"),
			OsStr.from_str("--no-cache"),
		],
		"test downstream bundle consumer",
	)
}

copy_tree! : Path.Path, Path.Path => Try({}, [BundleTestFailed(Str)])
copy_tree! = |source, destination| {
	{} = destination.create_dir!() ? |error| BundleTestFailed("create copied directory ${Path.to_inspect(destination)}: ${Str.inspect(error)}")
	entries = source.list!() ? |error| BundleTestFailed("list template directory ${Path.to_inspect(source)}: ${Str.inspect(error)}")
	copy_entries!(entries, destination)
}

copy_entries! : List(Path.Path), Path.Path => Try({}, [BundleTestFailed(Str)])
copy_entries! = |remaining, destination| {
	match remaining {
		[] => Ok({})
		[source, .. as rest] => {
			filename = source.filename().map_err(|error| BundleTestFailed("read template entry filename: ${Str.inspect(error)}"))?
			filename_str = filename.to_str().map_err(|error| BundleTestFailed("template entry filename is not valid text: ${Str.inspect(error)}"))?
			target = destination.join(filename_str)
			path_type = source.type!() ? |error| BundleTestFailed("inspect template entry ${Path.to_inspect(source)}: ${Str.inspect(error)}")

			{} =
				match path_type {
					IsDir => copy_tree!(source, target)
					IsFile => {
						bytes = source.read_bytes!() ? |error| BundleTestFailed("read template file ${Path.to_inspect(source)}: ${Str.inspect(error)}")
						{} = target.write_bytes!(bytes) ? |error| BundleTestFailed("write copied template file ${Path.to_inspect(target)}: ${Str.inspect(error)}")
						Ok({})
					}
					IsSymLink => Err(BundleTestFailed("downstream template contains unsupported symbolic link: ${Path.to_inspect(source)}"))
					IsOther => Err(BundleTestFailed("downstream template contains unsupported special file: ${Path.to_inspect(source)}"))
				}?

			copy_entries!(rest, destination)
		}
	}
}

## Immutable launch settings; retries change only the remaining attempt count.
BundleLaunch : {
	temp_root : Path.Path,
	temp_parent : Path.Path,
	owner_path : Path.Path,
	bundle_dir : Path.Path,
	server_binary : Path.Path,
	server_log : Path.Path,
	archive_name : Str,
	health_name : Str,
	health_body : Str,
	harness_pid : Str,
	timeout_program : Str,
}

start_server! : BundleLaunch, U64 => Try({ pid : Str, port : U16, watchdog_pid : Str }, [BundleTestFailed(Str)])
start_server! = |settings, attempts_left| {
	{ temp_root, temp_parent, owner_path, bundle_dir, server_binary, server_log, archive_name, health_name, health_body, harness_pid, timeout_program } = settings
	if attempts_left == 0 {
		log = read_server_log!(server_log)
		Err(BundleTestFailed("could not start loopback bundle server after ${server_attempts.to_str()} attempts; last server log:\n${log}"))
	} else {
		seed = Random.seed_u64!() ? |error| BundleTestFailed("choose HTTP server port: ${Str.inspect(error)}")
		port = U64.to_u16_wrap(30_000 + seed % 20_000)
		port_text = port.to_str()
		server_pid_path = temp_root.join("http-server.pid")
		watchdog_pid_path = temp_root.join("http-watchdog.pid")
		{} = delete_if_present!(server_pid_path)?
		{} = delete_if_present!(watchdog_pid_path)?

		launch =
			Cmd.new_str(timeout_program)
				.args_str(["--signal=TERM", "--kill-after=5s", shell_launch_timeout, "sh", "-c", launch_server_script])
				.env_str("HARNESS_PID", harness_pid)
				.env(OsStr.from_str("ROC_BUNDLE_SERVER_BINARY"), server_binary.to_os_str())
				.env_str("ROC_BUNDLE_HTTP_PORT", port_text)
				.env(OsStr.from_str("ROC_BUNDLE_HTTP_DIR"), Path.to_os_str(bundle_dir))
				.env_str("ROC_BUNDLE_HTTP_ARCHIVE_NAME", archive_name)
				.env_str("ROC_BUNDLE_HTTP_HEALTH_TARGET", "/${health_name}")
				.env_str("ROC_BUNDLE_HTTP_HEALTH_BODY", health_body)
				.env(OsStr.from_str("ROC_BUNDLE_HTTP_LOG"), Path.to_os_str(server_log))
				.env(OsStr.from_str("SERVER_PIDFILE"), server_pid_path.to_os_str())
				.env(OsStr.from_str("WATCHDOG_PIDFILE"), watchdog_pid_path.to_os_str())
				.env(OsStr.from_str("TEMP_ROOT"), temp_root.to_os_str())
				.env(OsStr.from_str("TEMP_PARENT"), temp_parent.to_os_str())
				.env(OsStr.from_str("OWNER_FILE"), owner_path.to_os_str())

		launch_result = launch.exec_output!()
		match launch_result {
			Ok({ stdout_utf8, stderr_utf8_lossy }) => {
				captured_pid = HarnessText.parse_pid_text(stdout_utf8)
				server_pidfile = read_pid_if_present!(server_pid_path, "HTTP bundle server")
				watchdog_pidfile = read_pid_if_present!(watchdog_pid_path, "HTTP bundle server watchdog")
				match (captured_pid, server_pidfile, watchdog_pidfile) {
					(Ok(pid), Ok(Pid(file_pid)), Ok(Pid(watchdog_pid))) if pid == file_pid => {
						if pid == harness_pid {
							# Never signal a PID which launch identity claims is this harness.
							safe_cleanup = if watchdog_pid == harness_pid Ok({}) else stop_process!(watchdog_pid, "HTTP bundle server watchdog")
							fail_after_cleanup("HTTP bundle server launch reported the harness PID as its server PID", safe_cleanup)
						} else if watchdog_pid == harness_pid {
							cleanup = stop_process!(pid, "HTTP bundle server")
							fail_after_cleanup("HTTP bundle server launch reported the harness PID as its watchdog PID", cleanup)
						} else if watchdog_pid == pid {
							cleanup = stop_process!(pid, "HTTP bundle server with duplicate watchdog PID")
							fail_after_cleanup("HTTP bundle server launch reported the same PID for server and watchdog", cleanup)
						} else if !(process_alive!(watchdog_pid)) {
							cleanup = cleanup_server_launch!(server_pid_path, watchdog_pid_path, stdout_utf8)
							fail_after_cleanup("HTTP bundle server parent-death watchdog exited during launch", cleanup)
						} else if await_server!(pid, port, health_name, health_body, server_probe_attempts) {
							Ok({ pid, port, watchdog_pid })
						} else {
							server_result = stop_process!(pid, "HTTP bundle server candidate")
							watchdog_result = stop_process!(watchdog_pid, "HTTP bundle server candidate watchdog")
							cleanup = combine_results(server_result, watchdog_result)
							match cleanup {
								Ok({}) => start_server!(settings, attempts_left - 1)
								Err(error) => Err(error)
							}
						}
					}
					_ => {
						cleanup = cleanup_server_launch!(server_pid_path, watchdog_pid_path, stdout_utf8)
						message = "invalid HTTP server launch identity: captured=${Str.inspect(captured_pid)}, server pidfile=${Str.inspect(server_pidfile)}, watchdog pidfile=${Str.inspect(watchdog_pidfile)}, stderr=${Str.inspect(stderr_utf8_lossy.trim())}"
						fail_after_cleanup(message, cleanup)
					}
				}
			}
			Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) => {
				cleanup = cleanup_server_launch!(server_pid_path, watchdog_pid_path, stdout_utf8_lossy)
				output = HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy).trim()
				message =
					if exit_code == 124 or exit_code == 137 {
						"HTTP bundle server launch exceeded ${shell_launch_timeout}: ${output}"
					} else {
						"HTTP bundle server launch exited ${exit_code.to_str()}: ${output}"
					}
				fail_after_cleanup(message, cleanup)
			}
			Err(error) => {
				cleanup = cleanup_server_launch!(server_pid_path, watchdog_pid_path, "")
				fail_after_cleanup("launch loopback bundle server: ${Str.inspect(error)}", cleanup)
			}
		}
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

read_pid_if_present! : Path.Path, Str => Try([Pid(Str), NoPid], [BundleTestFailed(Str)])
read_pid_if_present! = |pid_path, label| {
	match pid_path.is_file!() {
		Ok(Bool.False) => Ok(NoPid)
		Ok(Bool.True) => {
			contents = pid_path.read_utf8!() ? |error| BundleTestFailed("read ${label} pidfile: ${Str.inspect(error)}")
			pid = HarnessText.parse_pid_text(contents) ? |message| BundleTestFailed("${label} wrote an invalid pidfile: ${message}")
			Ok(Pid(pid))
		}
		Err(error) => Err(BundleTestFailed("inspect ${label} pidfile: ${Str.inspect(error)}"))
	}
}

delete_if_present! : Path.Path => Try({}, [BundleTestFailed(Str)])
delete_if_present! = |path| {
	exists = path.exists!() ? |error| BundleTestFailed("inspect ${path.display()}: ${Str.inspect(error)}")
	if exists {
		path.delete!().map_err(|error| BundleTestFailed("delete ${path.display()}: ${Str.inspect(error)}"))
	} else {
		Ok({})
	}
}

cleanup_server_launch! : Path.Path, Path.Path, Str => Try({}, [BundleTestFailed(Str)])
cleanup_server_launch! = |server_pid_path, watchdog_pid_path, captured_output| {
	captured =
		match HarnessText.parse_pid_text(captured_output) {
			Ok(pid) => FoundPid(pid)
			Err(_) => MissingPid
		}
	server_result = read_pid_if_present!(server_pid_path, "HTTP bundle server")
	server =
		match server_result {
			Ok(Pid(pid)) => FoundPid(pid)
			_ => MissingPid
		}
	watchdog_result = read_pid_if_present!(watchdog_pid_path, "HTTP bundle server watchdog")
	watchdog =
		match watchdog_result {
			Ok(Pid(pid)) => FoundPid(pid)
			_ => MissingPid
		}

	captured_cleanup = stop_optional_pid!(captured, "captured HTTP bundle server")
	server_cleanup = stop_optional_pid!(server, "pidfile HTTP bundle server")
	watchdog_cleanup = stop_optional_pid!(watchdog, "pidfile HTTP bundle server watchdog")
	read_server = result_to_unit(server_result)
	read_watchdog = result_to_unit(watchdog_result)
	combine_results(combine_results(combine_results(captured_cleanup, server_cleanup), watchdog_cleanup), combine_results(read_server, read_watchdog))
}

result_to_unit : Try(a, [BundleTestFailed(Str)]) -> Try({}, [BundleTestFailed(Str)])
result_to_unit = |result|
	match result {
		Ok(_) => Ok({})
		Err(error) => Err(error)
	}

stop_optional_pid! : [FoundPid(Str), MissingPid], Str => Try({}, [BundleTestFailed(Str)])
stop_optional_pid! = |pid, label|
	match pid {
		FoundPid(value) => stop_process!(value, label)
		MissingPid => Ok({})
	}

fail_after_cleanup : Str, Try({}, [BundleTestFailed(Str)]) -> Try(a, [BundleTestFailed(Str)])
fail_after_cleanup = |message, cleanup|
	match cleanup {
		Ok({}) => Err(BundleTestFailed(message))
		Err(BundleTestFailed(cleanup_message)) => Err(BundleTestFailed("${message}; cleanup also failed: ${cleanup_message}"))
	}

await_server! : Str, U16, Str, Str, U64 => Bool
await_server! = |pid, port, health_name, health_body, attempts_left| {
	if http_probe!(port, health_name, health_body) {
		Bool.True
	} else if attempts_left == 0 or !process_alive!(pid) {
		Bool.False
	} else {
		Sleep.millis!(server_probe_delay_ms)
		await_server!(pid, port, health_name, health_body, attempts_left - 1)
	}
}

http_probe! : U16, Str, Str => Bool
http_probe! = |port, health_name, health_body| {
	match Tcp.connect!("127.0.0.1", port, 200) {
		Err(_) => Bool.False
		Ok(stream) => {
			request = "GET /${percent_encode_path_segment(health_name)} HTTP/1.0\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n"
			match stream.write_utf8!(request, 200) {
				Err(_) => Bool.False
				Ok({}) => {
					match read_http_response!(stream, []) {
						ReadFailed => Bool.False
						ReadComplete(bytes) => {
							response = Str.from_utf8_lossy(bytes)
							response.starts_with("HTTP/1.0 200 OK\r\n") and response.ends_with("\r\n\r\n${health_body}")
						}
					}
				}
			}
		}
	}
}

read_http_response! : Tcp.Stream, List(U8) => [ReadComplete(List(U8)), ReadFailed]
read_http_response! = |stream, accumulated| {
	if accumulated.len() > 16_384 {
		ReadFailed
	} else {
		match stream.read_up_to!(4_096, 500) {
			Err(_) => ReadFailed
			Ok([]) => ReadComplete(accumulated)
			Ok(chunk) => read_http_response!(stream, accumulated.concat(chunk))
		}
	}
}

process_alive! : Str => Bool
process_alive! = |pid| {
	# Capture output so a normal "already exited" race does not print a noisy
	# diagnostic during teardown.
	match Cmd.new_str("kill").args_str(["-0", pid]).exec_output!() {
		Ok(_) => Bool.True
		_ => Bool.False
	}
}

stop_process! : Str, Str => Try({}, [BundleTestFailed(Str)])
stop_process! = |pid, label| {
	if !(process_alive!(pid)) {
		Ok({})
	} else {
		term_result = signal_pid!(pid, "TERM", label)
		if await_process_exit!(pid, 40) {
			Ok({})
		} else {
			kill_result = signal_pid!(pid, "KILL", label)
			if await_process_exit!(pid, 40) {
				Ok({})
			} else {
				Err(BundleTestFailed("${label} process ${pid} did not exit after SIGKILL; TERM=${describe_signal_result(term_result)}, KILL=${describe_signal_result(kill_result)}"))
			}
		}
	}
}

signal_pid! : Str, Str, Str => Try({}, [BundleTestFailed(Str)])
signal_pid! = |pid, signal, label| {
	exit_code = Cmd.new_str("kill")
		.args_str(["-${signal}", pid])
		.exec_exit_code!()
		.map_err(|error| BundleTestFailed("signal ${label} process ${pid}: ${Str.inspect(error)}"))?
	if exit_code == 0 {
		Ok({})
	} else {
		Err(BundleTestFailed("kill -${signal} ${pid} exited ${exit_code.to_str()} for ${label}"))
	}
}

describe_signal_result : Try({}, [BundleTestFailed(Str)]) -> Str
describe_signal_result = |result|
	match result {
		Ok({}) => "ok"
		Err(BundleTestFailed(message)) => message
	}

await_process_exit! : Str, U64 => Bool
await_process_exit! = |pid, attempts_left| {
	if !process_alive!(pid) {
		Bool.True
	} else if attempts_left == 0 {
		Bool.False
	} else {
		Sleep.millis!(50)
		await_process_exit!(pid, attempts_left - 1)
	}
}

read_server_log! : Path.Path => Str
read_server_log! = |path| {
	match path.read_utf8!() {
		Ok(contents) if !contents.is_empty() => contents
		Ok(_) => "(empty)"
		Err(error) => "(unavailable: ${Str.inspect(error)})"
	}
}

combine_results : Try({}, [BundleTestFailed(Str)]), Try({}, [BundleTestFailed(Str)]) -> Try({}, [BundleTestFailed(Str)])
combine_results = |primary, cleanup| {
	match (primary, cleanup) {
		(Ok({}), Ok({})) => Ok({})
		(Err(BundleTestFailed(message)), Ok({})) => Err(BundleTestFailed(message))
		(Ok({}), Err(BundleTestFailed(message))) => Err(BundleTestFailed(message))
		(Err(BundleTestFailed(primary_message)), Err(BundleTestFailed(cleanup_message))) =>
			Err(BundleTestFailed("${primary_message}\ncleanup also failed: ${cleanup_message}"))
		}
}

widen_for_main : Try(a, [BundleTestFailed(Str)]) -> Try(a, [BundleTestFailed(Str), Exit(I32), ..])
widen_for_main = |result|
	match result {
		Ok(value) => Ok(value)
		Err(BundleTestFailed(message)) => Err(BundleTestFailed(message))
	}

count_occurrences : Str, Str -> U64
count_occurrences = |source, needle| {
	if needle.is_empty() {
		0
	} else {
		source.split_on(needle).len() - 1
	}
}

percent_encode_path_segment : Str -> Str
percent_encode_path_segment = |segment| {
	encoded_bytes =
		segment.to_utf8().fold(
			[],
			|encoded, byte|
				if is_unreserved(byte) {
					encoded.append(byte)
				} else {
					encoded
						.append('%')
						.append(hex_digit(byte // 16))
						.append(hex_digit(byte % 16))
				},
		)

	Str.from_utf8_lossy(encoded_bytes)
}

is_unreserved : U8 -> Bool
is_unreserved = |byte|
	(byte >= 'a' and byte <= 'z') or
		(byte >= 'A' and byte <= 'Z') or
			(byte >= '0' and byte <= '9') or
				byte == '-' or byte == '.' or byte == '_' or byte == '~'

hex_digit : U8 -> U8
hex_digit = |n| if n < 10 48 + n else 55 + n

expect count_occurrences("before TOKEN after", "TOKEN") == 1

expect count_occurrences("TOKEN and TOKEN", "TOKEN") == 2

expect percent_encode_path_segment("roc redis/a.tar.zst") == "roc%20redis%2Fa.tar.zst"

expect HarnessText.parse_pid_text("123\n") == Ok("123")

expect ["", "1", "12 3", "123\n456\n"].all(|text| HarnessText.parse_pid_text(text).is_err())

expect launch_server_script.contains("while kill -0 \"$HARNESS_PID\" 2>/dev/null && kill -0 \"$server_pid\"")

expect launch_server_script.contains("if ! kill -0 \"$HARNESS_PID\"") and launch_server_script.contains("kill -TERM") and launch_server_script.contains("kill -KILL") and launch_server_script.contains("rm -rf -- \"$TEMP_ROOT\"")

expect launch_server_script.contains("\"$ROC_BUNDLE_SERVER_BINARY\"")
