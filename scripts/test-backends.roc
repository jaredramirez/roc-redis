## Qualify one or more compiler backends against the production package and
## platform boundaries. This controller is intentionally dev-built; the selected
## backend applies only to the package and application subjects it launches.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
}

import HarnessText
import pf.Cmd
import pf.Env
import pf.OsStr exposing [OsStr]
import pf.Path
import pf.Random
import pf.Stdout

command_timeout : Str
command_timeout = "300s"

main! : List(OsStr) => Try({}, [BackendQualificationFailed(Str), Exit(I32), ..])
main! = |args| {
	backends = widen_for_main(parse_backends(args))?
	timeout_program = widen_for_main(find_timeout!({}))?
	{} = widen_for_main(require_command!("roc"))?
	{} = widen_for_main(require_repo_root!({}))?

	for backend in backends {
		{} = widen_for_main(qualify_backend!(backend, timeout_program))?
		write_result = Stdout.line!("backend qualification | controller_backend=dev | subject_backend=${backend} | result=passed")
			.map_err(|error| BackendQualificationFailed("write success message: ${Str.inspect(error)}"))
		{} = widen_for_main(write_result)?
	}
	Ok({})
}

parse_backends : List(OsStr) -> Try(List(Str), [BackendQualificationFailed(Str)])
parse_backends = |args| {
	requested = args.drop_first(1)
	if requested.is_empty() {
		Ok(["dev"])
	} else {
		var $backends = []
		for argument in requested {
			backend = OsStr.to_str_try(argument) ? |_| BackendQualificationFailed("backend argument is not valid UTF-8")
			$backends = $backends.append(validate_backend(backend)?)
		}
		Ok($backends)
	}
}

validate_backend : Str -> Try(Str, [BackendQualificationFailed(Str)])
validate_backend = |backend|
	match backend {
		"dev" => Ok("dev")
		"speed" => Ok("speed")
		"size" => Ok("size")
		_ => Err(BackendQualificationFailed("backend must be dev, speed, or size; received ${Str.inspect(backend)}"))
	}

find_timeout! : {} => Try(Str, [BackendQualificationFailed(Str)])
find_timeout! = |_| {
	if Cmd.check_available!("timeout") {
		Ok("timeout")
	} else if Cmd.check_available!("gtimeout") {
		Ok("gtimeout")
	} else {
		Err(BackendQualificationFailed("GNU timeout is required; enter the Nix development shell (or install coreutils so gtimeout is available on macOS)"))
	}
}

require_command! : Str => Try({}, [BackendQualificationFailed(Str)])
require_command! = |program|
	if Cmd.check_available!(program) {
		Ok({})
	} else {
		Err(BackendQualificationFailed("required executable is unavailable: ${Str.inspect(program)}"))
	}

require_repo_root! : {} => Try({}, [BackendQualificationFailed(Str)])
require_repo_root! = |_| {
	required = [
		"package/main.roc",
		"integration/client_contract.roc",
		"integration/transport_properties.roc",
		"scripts/test-integration.roc",
		"scripts/test-basic-webserver.roc",
		"scripts/test-bundle.roc",
	]
	var $missing = []
	for name in required {
		is_file = Path.utf8(name).is_file!() ? |error| BackendQualificationFailed("inspect ${name}: ${Str.inspect(error)}")
		if !is_file {
			$missing = $missing.append(name)
		}
	}
	if $missing.is_empty() {
		Ok({})
	} else {
		Err(BackendQualificationFailed("run from the roc-redis repository root; missing: ${Str.join_with($missing, ", ")}"))
	}
}

qualify_backend! : Str, Str => Try({}, [BackendQualificationFailed(Str)])
qualify_backend! = |backend, timeout_program| {
	temp_dir = create_temp_dir!(backend, 8)?
	result = qualify_backend_in!(backend, timeout_program, temp_dir)
	cleanup = temp_dir.delete_all!().map_err(|error| BackendQualificationFailed("remove temporary backend qualification directory ${temp_dir.display()}: ${Str.inspect(error)}"))
	combine_results(result, cleanup)
}

create_temp_dir! : Str, U8 => Try(Path.Path, [BackendQualificationFailed(Str)])
create_temp_dir! = |backend, attempts_left| {
	if attempts_left == 0 {
		Err(BackendQualificationFailed("could not allocate a unique temporary backend qualification directory"))
	} else {
		seed = Random.seed_u64!() ? |error| BackendQualificationFailed("choose temporary-directory name: ${Str.inspect(error)}")
		candidate = Env.temp_dir!().join("roc-redis-backend-${backend}-${seed.to_str()}")
		match candidate.create_dir!() {
			Ok({}) => Ok(candidate)
			Err(PathErr(AlreadyExists, _)) => create_temp_dir!(backend, attempts_left - 1)
			Err(error) => Err(BackendQualificationFailed("create temporary directory ${candidate.display()}: ${Str.inspect(error)}"))
		}
	}
}

qualify_backend_in! : Str, Str, Path.Path => Try({}, [BackendQualificationFailed(Str)])
qualify_backend_in! = |backend, timeout_program, temp_dir| {
	opt = "--opt=${backend}"
	run_bounded!(timeout_program, backend, "check package", "roc", ["check", "--no-cache", "package/main.roc"])?
	run_bounded!(timeout_program, backend, "test package expectations", "roc", ["test", opt, "--no-cache", "package/main.roc"])?

	client_binary = temp_dir.join("client-contract")
	run_bounded!(timeout_program, backend, "build runtime client contract", "roc", ["build", opt, "--no-cache", "--output=${client_binary.display()}", "integration/client_contract.roc"])?
	is_executable = client_binary.is_executable!() ? |error| BackendQualificationFailed("inspect built client contract: ${Str.inspect(error)}")
	if !is_executable {
		return Err(BackendQualificationFailed("roc build succeeded without creating an executable at ${client_binary.display()}"))
	}
	run_bounded!(timeout_program, backend, "execute runtime client contract", client_binary.display(), [])?

	properties_binary = temp_dir.join("transport-properties")
	run_bounded!(timeout_program, backend, "build transport property matrix", "roc", ["build", opt, "--no-cache", "--output=${properties_binary.display()}", "integration/transport_properties.roc"])?
	properties_executable = properties_binary.is_executable!() ? |error| BackendQualificationFailed("inspect built transport property matrix: ${Str.inspect(error)}")
	if !properties_executable {
		return Err(BackendQualificationFailed("roc build succeeded without creating an executable at ${properties_binary.display()}"))
	}
	run_bounded!(timeout_program, backend, "execute transport property matrix", properties_binary.display(), [])?

	# The controllers remain dev-built. Each validates the environment before it
	# starts services, then builds only its platform/application subject with opt.
	for (label, source) in [
		("run basic-cli Redis integration", "scripts/test-integration.roc"),
		("run basic-webserver Redis integration", "scripts/test-basic-webserver.roc"),
		("test downstream bundle consumer", "scripts/test-bundle.roc"),
	] {
		run_bounded!(timeout_program, backend, label, "roc", ["--opt=dev", source])?
	}
	Ok({})
}

run_bounded! : Str, Str, Str, Str, List(Str) => Try({}, [BackendQualificationFailed(Str)])
run_bounded! = |timeout_program, backend, label, program, arguments| {
	wrapped = ["--signal=TERM", "--kill-after=5s", command_timeout, program].concat(arguments)
	command = Cmd.new_str(timeout_program)
		.args_str(wrapped)
		.env_str("ROC_REDIS_TEST_BACKEND", backend)
	match command.exec_output!() {
		Ok(_) =>
			Stdout.line!("backend qualification | controller_backend=dev | subject_backend=${backend} | check=${label} | result=passed")
				.map_err(|error| BackendQualificationFailed("write ${label} result: ${Str.inspect(error)}"))
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) => {
			output = HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy).trim()
			suffix = if output.is_empty() "" else ": ${output}"
			if exit_code == 124 or exit_code == 137 {
				Err(BackendQualificationFailed("${backend} ${label} exceeded ${command_timeout}${suffix}"))
			} else {
				Err(BackendQualificationFailed("${backend} ${label} exited ${exit_code.to_str()}${suffix}"))
			}
		}
		Err(error) => Err(BackendQualificationFailed("could not start ${backend} ${label}: ${Str.inspect(error)}"))
	}
}

combine_results : Try({}, [BackendQualificationFailed(Str)]), Try({}, [BackendQualificationFailed(Str)]) -> Try({}, [BackendQualificationFailed(Str)])
combine_results = |primary, cleanup|
	match (primary, cleanup) {
		(Ok({}), Ok({})) => Ok({})
		(Err(error), Ok({})) => Err(error)
		(Ok({}), Err(error)) => Err(error)
		(Err(BackendQualificationFailed(message)), Err(BackendQualificationFailed(cleanup_message))) => Err(BackendQualificationFailed("${message}; cleanup also failed: ${cleanup_message}"))
	}

widen_for_main : Try(a, [BackendQualificationFailed(Str)]) -> Try(a, [BackendQualificationFailed(Str), Exit(I32), ..])
widen_for_main = |result|
	match result {
		Ok(value) => Ok(value)
		Err(BackendQualificationFailed(message)) => Err(BackendQualificationFailed(message))
	}

expect validate_backend("dev") == Ok("dev")

expect validate_backend("speed") == Ok("speed")

expect validate_backend("size") == Ok("size")

expect validate_backend("interpreter").is_err()
