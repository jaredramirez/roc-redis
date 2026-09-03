## Verify that every active compiler bug still has its documented failure
## shape and that fixed regressions remain fixed on the pinned nightly.
##
## Run this from the repository root. The Nix development shell supplies GNU
## `timeout`. Homebrew's `gtimeout` is also accepted so the checker remains
## useful on macOS outside Nix. Refusing to run without either executable keeps
## a wedged compiler from making this verification hang indefinitely.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
}

import HarnessText
import pf.Cmd
import pf.Env
import pf.OsStr
import pf.Path
import pf.Random
import pf.Stderr
import pf.Stdout

inferred_u8_repro : Str
inferred_u8_repro = "roc-bugs/inferred-u8-helper/main.roc"

backend_test_repro : Str
backend_test_repro = "roc-bugs/interpreter-streaming-decoder/main.roc"

recursive_json_control : Str
recursive_json_control = "roc-bugs/recursive-nominal-json-parser/control/main.roc"

recursive_json_repro : Str
recursive_json_repro = "roc-bugs/recursive-nominal-json-parser/repro/main.roc"

generated_json_control : Str
generated_json_control = "roc-bugs/generated-json-optional-field-postcheck/control/main.roc"

generated_json_repro : Str
generated_json_repro = "roc-bugs/generated-json-optional-field-postcheck/repro/main.roc"

generated_json_failure : Str
generated_json_failure = "postcheck invariant violated: checked generated codec contract was missing required method call parse_record_field (subject: present)"

broken_docs_repro : Str
broken_docs_repro = "roc-bugs/docs-broken-link-double-report/main.roc"

signal_exit_wrapper : Str
signal_exit_wrapper = "\"$@\"; status=$?; exit \"$status\""

fmt_directory_repro : Str
fmt_directory_repro = "roc-bugs/fmt-directory-reporting/repro.roc"

command_timeout : Str
command_timeout = "120s"

recursive_json_timeout : Str
recursive_json_timeout = "10s"

main! : List(OsStr) => Try({}, [CheckFailed(Str), Exit(I32), ..])
main! = |_args| {
	timeout_program = find_timeout!({})?
	artifact_seed = Random.seed_u64!() ? |error| CheckFailed("could not choose temporary compiler-bug artifact names: ${Str.inspect(error)}")

	# The frozen candidate aborts on tested Darwin dev/speed. Require its portable
	# workaround to execute successfully; do not assume another host's abort code.
	require_success!(timeout_program, "generator coalescing runtime control", "roc", ["--opt=dev", "--no-cache", "roc-bugs/generator-list-coalescing/control.roc"], Fragment("passed"))?

	# Cached duplicate-URL imports can abort; keep the uncached control passing.
	require_success!(timeout_program, "cached package alias uncached control", "roc", ["test", "--opt=dev", "--no-cache", "roc-bugs/cached-package-alias-duplicate/main.roc"], Fragment("All (1) tests passed"))?
	require_expected_timeout!(timeout_program, "effectful record JSON inference", "roc", ["check", "--no-cache", "roc-bugs/effectful-record-json-inference/repro.roc"], "5s")?
	require_success!(timeout_program, "effectful record JSON annotated control", "roc", ["check", "--no-cache", "roc-bugs/effectful-record-json-inference/control.roc"], NoFragment)?

	# These are API contracts, not compiler bugs: invalid literals/configuration
	# and attempts to bypass the opaque constructor must fail compilation.
	for (fixture, diagnostic) in [
		("zero-positive", "expected a positive integer"),
		("empty-command", "expected non-empty bytes"),
		("invalid-config", "non exhaustive destructure"),
		("opaque-command", "cannot use opaque nominal type"),
	] {
		require_known_failure!(timeout_program, "API compile rejection: ${fixture}", "roc", ["check", "integration/compile_fail/${fixture}.roc", "--no-cache"], [diagnostic], [])?
	}
	for (directory, entry, diagnostic) in [
		("constant-destructure-in-expect", "repro.roc", "non exhaustive destructure"),
		("absolute-import-pattern", "main.roc", "undeclared"),
		("nested-alias-type-constructor", "repro.roc", "not exposed"),
	] {
		require_known_failure!(timeout_program, directory, "roc", ["check", "roc-bugs/${directory}/${entry}", "--no-cache"], [diagnostic], [])?
		require_success!(timeout_program, "${directory} control", "roc", ["test", "--opt=dev", "roc-bugs/${directory}/control.roc", "--no-cache"], NoFragment)?
	}
	require_known_failure!(timeout_program, "type-error expectation diagnostic recovery", "roc", ["test", "--opt=dev", "roc-bugs/type-error-expect-diagnostic-recovery/repro.roc", "--no-cache"], ["type mismatch", "runtime error", "0 compiler errors"], [])?
	require_success!(timeout_program, "type-error expectation control", "roc", ["test", "--opt=dev", "roc-bugs/type-error-expect-diagnostic-recovery/control.roc", "--no-cache"], NoFragment)?
	require_known_failure!(timeout_program, "invalid string literal diagnostic", "roc", ["check", "roc-bugs/invalid-string-literal-diagnostic/Literal.roc", "--no-cache"], ["string literal intentionally rejected", "invalid numeric literal"], [])?
	require_success!(timeout_program, "valid string literal control", "roc", ["test", "--opt=dev", "roc-bugs/invalid-string-literal-diagnostic/Accepted.roc", "--no-cache"], NoFragment)?
	# The frozen allocation repro deliberately aborts; verify its working
	# control here. Keep the aborting repro opt-in to avoid CI memory exhaustion.
	require_success!(timeout_program, "decoder allocation control", "roc", ["test", "--opt=dev", "roc-bugs/decoder-expect-allocation/control.roc", "--no-cache"], NoFragment)?

	require_success!(
		timeout_program,
		"inferred-U8 repro check",
		"roc",
		["check", inferred_u8_repro, "--no-cache"],
		NoFragment,
	)?
	require_success!(
		timeout_program,
		"fixed inferred-U8-helper regression",
		"roc",
		["test", "--opt=dev", inferred_u8_repro, "--no-cache"],
		Fragment("All (2) tests passed"),
	)?

	require_success!(
		timeout_program,
		"backend recursion repro check",
		"roc",
		["check", backend_test_repro, "--no-cache"],
		NoFragment,
	)?
	require_success!(
		timeout_program,
		"backend recursion dev control",
		"roc",
		["test", "--opt=dev", backend_test_repro, "--no-cache"],
		Fragment("All (3) tests passed"),
	)?
	require_known_failure!(
		timeout_program,
		"interpreter streaming-decoder miscompilation",
		"roc",
		["test", "--opt=interpreter", backend_test_repro, "--no-cache"],
		[
			"interpreter-streaming-decoder/Decoder.roc:532:1",
			"interpreter-streaming-decoder/Decoder.roc:535:1",
			"interpreter-streaming-decoder/Decoder.roc:557:1",
			"retain [1] instead of [120]",
			"Ran 3 tests",
			"0 passed",
			"3 failed",
			"0 compiler errors",
		],
		[],
	)?

	require_success_with_timeout!(
		timeout_program,
		"non-recursive nominal-list JSON parser control",
		"roc",
		["check", recursive_json_control, "--no-cache"],
		NoFragment,
		recursive_json_timeout,
	)?
	require_expected_timeout!(
		timeout_program,
		"recursive nominal JSON parser derivation",
		"roc",
		["check", recursive_json_repro, "--no-cache"],
		recursive_json_timeout,
	)?

	generated_json_control_output = Env.temp_dir!().join("roc-redis-json-postcheck-control-${artifact_seed.to_str()}")
	require_build_success_with_cleanup!(
		timeout_program,
		"generated JSON optional-field control",
		generated_json_control,
		generated_json_control_output,
	)?
	generated_json_repro_output = Env.temp_dir!().join("roc-redis-json-postcheck-repro-${artifact_seed.to_str()}")
	require_build_failure_with_cleanup!(
		timeout_program,
		"generated JSON optional-field postcheck panic",
		generated_json_repro,
		generated_json_repro_output,
		134,
		[generated_json_failure],
		[],
	)?

	broken_docs_output = Env.temp_dir!().join("roc-redis-broken-doc-links-${artifact_seed.to_str()}")
	require_docs_failure_with_cleanup!(
		timeout_program,
		"broken documentation link double-report",
		broken_docs_repro,
		broken_docs_output,
	)?

	require_known_failure!(
		timeout_program,
		"formatter directory reporting",
		"roc",
		["--opt=dev", fmt_directory_repro],
		[
			"failed `roc fmt --check`:",
			"Alpha.ro\n    Alpha.roc",
			"You can fix this with `roc fmt FILENAME.roc`",
		],
		["Beta.roc"],
	)?

	Stdout.line!("Roc compiler bug checks matched their documented status.")
		.map_err(|error| CheckFailed("could not write success message: ${Str.inspect(error)}"))?
	Ok({})
}

require_build_success_with_cleanup! : Str, Str, Str, Path.Path => Try({}, [CheckFailed(Str), ..])
require_build_success_with_cleanup! = |timeout_program, label, source, output_path| {
	result = require_success!(timeout_program, label, "roc", ["build", "--opt=dev", "--no-cache", "--output=${output_path.display()}", source], NoFragment)
	cleanup = delete_if_present!(output_path)
	combine_check_and_cleanup(result, cleanup)
}

require_docs_failure_with_cleanup! : Str, Str, Str, Path.Path => Try({}, [CheckFailed(Str), ..])
require_docs_failure_with_cleanup! = |timeout_program, label, source, output_path| {
	# `roc docs` writes a partial site before validating links. Clear a remotely
	# possible random-name collision first, then remove the tree on every normal
	# return path, including a changed diagnostic or a timeout.
	delete_tree_if_present!(output_path)?
	result = require_known_failure_with_exit!(
		timeout_program,
		label,
		"roc",
		["docs", "--no-cache", "--output=${output_path.display()}", source],
		1,
		[
			"Error: 1 doc reference(s) point at non-existent anchors:",
			"[Resp.Resp] -> #Resp.Resp",
			"unreported error",
			"The compiler stopped with the error BrokenDocLinks but did not say why.",
			"This is a bug in the compiler:",
		],
		[],
	)
	cleanup = delete_tree_if_present!(output_path)
	combine_check_and_cleanup(result, cleanup)
}

require_build_failure_with_cleanup! : Str, Str, Str, Path.Path, I32, List(Str), List(Str) => Try({}, [CheckFailed(Str), ..])
require_build_failure_with_cleanup! = |timeout_program, label, source, output_path, expected_exit, required_fragments, absent_fragments| {
	result = require_known_failure_with_exit!(
		timeout_program,
		label,
		"sh",
		["-c", signal_exit_wrapper, "roc-known-bug-signal-wrapper", "roc", "build", "--opt=dev", "--no-cache", "--output=${output_path.display()}", source],
		expected_exit,
		required_fragments,
		absent_fragments,
	)
	cleanup = delete_if_present!(output_path)
	combine_check_and_cleanup(result, cleanup)
}

require_expected_timeout! : Str, Str, Str, List(Str), Str => Try({}, [CheckFailed(Str), ..])
require_expected_timeout! = |timeout_program, label, program, arguments, duration| {
	outcome = run_with_timeout!(timeout_program, duration, program, arguments)?
	if outcome.exit_code == 124 {
		Ok({})
	} else if outcome.exit_code == 0 {
		fail_with_output!("${label} appears fixed; remove its workaround/repro", outcome.output)
	} else {
		fail_with_output!("${label} failure shape changed; expected GNU timeout status 124 after ${duration}, received ${outcome.exit_code.to_str()}", outcome.output)
	}
}

find_timeout! : {} => Try(Str, [CheckFailed(Str), ..])
find_timeout! = |_| {
	if Cmd.check_available!("timeout") {
		Ok("timeout")
	} else if Cmd.check_available!("gtimeout") {
		Ok("gtimeout")
	} else {
		Err(CheckFailed("GNU timeout is required; enter the Nix development shell (or install coreutils so `gtimeout` is available on macOS)"))
	}
}

require_success! : Str, Str, Str, List(Str), [Fragment(Str), NoFragment] => Try({}, [CheckFailed(Str), ..])
require_success! = |timeout_program, label, program, arguments, expected_fragment| {
	require_success_with_timeout!(timeout_program, label, program, arguments, expected_fragment, command_timeout)
}

require_success_with_timeout! : Str, Str, Str, List(Str), [Fragment(Str), NoFragment], Str => Try({}, [CheckFailed(Str), ..])
require_success_with_timeout! = |timeout_program, label, program, arguments, expected_fragment, duration| {
	outcome = run_with_timeout!(timeout_program, duration, program, arguments)?

	if outcome.exit_code == 124 or outcome.exit_code == 137 {
		fail_with_output!("${label} exceeded ${duration}", outcome.output)
	} else if outcome.exit_code == 125 {
		fail_with_output!("GNU timeout could not run ${program}", outcome.output)
	} else if outcome.exit_code == 126 or outcome.exit_code == 127 {
		fail_with_output!("could not invoke ${program} through GNU timeout", outcome.output)
	} else {
		require_successful_outcome!(label, outcome, expected_fragment)
	}
}

require_successful_outcome! : Str, { exit_code : I32, output : Str }, [Fragment(Str), NoFragment] => Try({}, [CheckFailed(Str), ..])
require_successful_outcome! = |label, outcome, expected_fragment| {

	fragment_found =
		match expected_fragment {
			NoFragment => Bool.True
			Fragment(fragment) => outcome.output.contains(fragment)
		}

	if outcome.exit_code == 0 and fragment_found {
		Ok({})
	} else {
		fail_with_output!("${label} did not succeed as expected", outcome.output)
	}
}

require_known_failure! : Str, Str, Str, List(Str), List(Str), List(Str) => Try({}, [CheckFailed(Str), ..])
require_known_failure! = |timeout_program, label, program, arguments, required_fragments, absent_fragments| {
	outcome = run_bounded!(timeout_program, program, arguments)?

	if outcome.exit_code == 0 {
		fail_with_output!("${label} appears fixed; remove its workaround/repro", outcome.output)
	} else {
		missing = required_fragments.keep_if(|fragment| !outcome.output.contains(fragment))
		unexpected = absent_fragments.keep_if(|fragment| outcome.output.contains(fragment))

		if !missing.is_empty() {
			fail_with_output!("${label} failure shape changed; missing: ${Str.inspect(missing)}", outcome.output)
		} else if !unexpected.is_empty() {
			fail_with_output!("${label} failure shape changed; unexpectedly present: ${Str.inspect(unexpected)}", outcome.output)
		} else {
			Ok({})
		}
	}
}

KnownFailureShape : [MatchedKnownFailure, MissingFragments(List(Str)), UnexpectedFragments(List(Str)), UnexpectedSuccess, WrongExit({ actual : I32, expected : I32 })]

known_failure_shape : I32, I32, Str, List(Str), List(Str) -> KnownFailureShape
known_failure_shape = |actual_exit, expected_exit, output, required_fragments, absent_fragments| {
	if actual_exit == 0 {
		UnexpectedSuccess
	} else if actual_exit != expected_exit {
		WrongExit({ actual: actual_exit, expected: expected_exit })
	} else {
		missing = required_fragments.keep_if(|fragment| !output.contains(fragment))
		unexpected = absent_fragments.keep_if(|fragment| output.contains(fragment))
		if !missing.is_empty() {
			MissingFragments(missing)
		} else if !unexpected.is_empty() {
			UnexpectedFragments(unexpected)
		} else {
			MatchedKnownFailure
		}
	}
}

require_known_failure_with_exit! : Str, Str, Str, List(Str), I32, List(Str), List(Str) => Try({}, [CheckFailed(Str), ..])
require_known_failure_with_exit! = |timeout_program, label, program, arguments, expected_exit, required_fragments, absent_fragments| {
	outcome = run_bounded!(timeout_program, program, arguments)?
	match known_failure_shape(outcome.exit_code, expected_exit, outcome.output, required_fragments, absent_fragments) {
		MatchedKnownFailure => Ok({})
		UnexpectedSuccess => fail_with_output!("${label} appears fixed; remove its workaround/repro", outcome.output)
		WrongExit({ actual, expected }) => fail_with_output!("${label} failure shape changed; expected exit ${expected.to_str()}, received ${actual.to_str()}", outcome.output)
		MissingFragments(missing) => fail_with_output!("${label} failure shape changed; missing: ${Str.inspect(missing)}", outcome.output)
		UnexpectedFragments(unexpected) => fail_with_output!("${label} failure shape changed; unexpectedly present: ${Str.inspect(unexpected)}", outcome.output)
	}
}

run_bounded! : Str, Str, List(Str) => Try({ exit_code : I32, output : Str }, [CheckFailed(Str), ..])
run_bounded! = |timeout_program, program, arguments| {
	outcome = run_with_timeout!(timeout_program, command_timeout, program, arguments)?
	if outcome.exit_code == 124 or outcome.exit_code == 137 {
		fail_with_output!("command exceeded ${command_timeout}: ${program} ${Str.join_with(arguments, " ")}", outcome.output)
	} else if outcome.exit_code == 125 {
		fail_with_output!("GNU timeout could not run ${program}", outcome.output)
	} else if outcome.exit_code == 126 or outcome.exit_code == 127 {
		fail_with_output!("could not invoke ${program} through GNU timeout", outcome.output)
	} else {
		Ok(outcome)
	}
}

run_with_timeout! : Str, Str, Str, List(Str) => Try({ exit_code : I32, output : Str }, [CheckFailed(Str), ..])
run_with_timeout! = |timeout_program, duration, program, arguments| {
	wrapped_arguments = ["--signal=TERM", "--kill-after=5s", duration, program].concat(arguments)
	command = Cmd.new_str(timeout_program).args_str(wrapped_arguments)

	match command.exec_output!() {
		Ok({ stdout_utf8, stderr_utf8_lossy }) =>
			Ok({ exit_code: 0, output: HarnessText.combine_output(stdout_utf8, stderr_utf8_lossy) })

		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) =>
			Ok({ exit_code, output: HarnessText.combine_output(stdout_utf8_lossy, stderr_utf8_lossy) })

		Err(error) =>
			Err(CheckFailed("could not execute ${program}: ${Str.inspect(error)}"))
		}
}

delete_if_present! : Path.Path => Try({}, [CheckFailed(Str), ..])
delete_if_present! = |path| {
	exists = path.exists!() ? |error| CheckFailed("could not inspect temporary build artifact ${path.display()}: ${Str.inspect(error)}")
	if exists {
		path.delete!().map_err(|error| CheckFailed("could not remove temporary build artifact ${path.display()}: ${Str.inspect(error)}"))
	} else {
		Ok({})
	}
}

delete_tree_if_present! : Path.Path => Try({}, [CheckFailed(Str), ..])
delete_tree_if_present! = |path| {
	exists = path.exists!() ? |error| CheckFailed("could not inspect temporary documentation tree ${path.display()}: ${Str.inspect(error)}")
	if exists {
		Cmd.new_str("rm")
			.args_str(["-rf", "--", path.display()])
			.exec_cmd!()
			.map_err(|error| CheckFailed("could not remove temporary documentation tree ${path.display()}: ${Str.inspect(error)}"))?

		still_exists = path.exists!() ? |error| CheckFailed("could not verify removal of temporary documentation tree ${path.display()}: ${Str.inspect(error)}")
		if still_exists {
			Err(CheckFailed("temporary documentation tree still exists after cleanup: ${path.display()}"))
		} else {
			Ok({})
		}
	} else {
		Ok({})
	}
}

combine_check_and_cleanup : Try({}, [CheckFailed(Str), ..]), Try({}, [CheckFailed(Str), ..]) -> Try({}, [CheckFailed(Str), ..])
combine_check_and_cleanup = |check_result, cleanup_result|
	match (check_result, cleanup_result) {
		(Ok({}), Ok({})) => Ok({})
		(Err(error), Ok({})) => Err(CheckFailed(describe_check_error(error)))
		(Ok({}), Err(error)) => Err(CheckFailed(describe_check_error(error)))
		(Err(error), Err(cleanup_error)) => Err(CheckFailed("${describe_check_error(error)}; cleanup also failed: ${describe_check_error(cleanup_error)}"))
	}

describe_check_error : [CheckFailed(Str), ..] -> Str
describe_check_error = |error|
	match error {
		CheckFailed(message) => message
		other => Str.inspect(other)
	}

fail_with_output! : Str, Str => Try(a, [CheckFailed(Str), ..])
fail_with_output! = |message, output| {
	if !output.is_empty() {
		Stderr.write!(output)
			.map_err(|error| CheckFailed("could not write command output: ${Str.inspect(error)}"))?
	}

	Err(CheckFailed(message))
}

expect HarnessText.combine_output("", "") == ""

expect HarnessText.combine_output("stdout\n", "") == "stdout\n"

expect HarnessText.combine_output("", "stderr\n") == "stderr\n"

expect HarnessText.combine_output("stdout", "stderr") == "stdout\nstderr"

expect signal_exit_wrapper == "\"$@\"; status=$?; exit \"$status\""

expect known_failure_shape(134, 134, "prefix required suffix", ["required"], ["forbidden"]) == MatchedKnownFailure

expect known_failure_shape(0, 134, "required", ["required"], []) == UnexpectedSuccess

expect known_failure_shape(1, 134, "required", ["required"], []) == WrongExit({ actual: 1, expected: 134 })

expect known_failure_shape(134, 134, "other", ["required"], []) == MissingFragments(["required"])

expect known_failure_shape(134, 134, "required forbidden", ["required"], ["forbidden"]) == UnexpectedFragments(["forbidden"])

expect known_failure_shape(1, 1, "BrokenDocLinks unreported error", ["BrokenDocLinks", "unreported error"], []) == MatchedKnownFailure
