## Run each validated memory probe in a separate process under the host's
## maximum-resident-set-size tool. RSS includes process/runtime startup; the idle
## case is reported as evidence, never subtracted as an inferred heap size.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
}

import pf.Cmd
import pf.Env
import pf.OsStr
import pf.Stdout

Config : { suite : [Full, Smoke], samples : U64 }

Case : { id : Str, arguments : List(Str) }

Timer : {
	host_os : Str,
	program : Str,
	leading_arguments : List(Str),
	metric_label : Str,
	style : [Gnu, Mac],
}

ProbeRecord : {
	schema : Str,
	case_name : Str,
	size : U64,
	chunk_size : U64,
	count : U64,
	checksum : U64,
	validated : Bool,
	compiler : Str,
	build_mode : Str,
	source : Str,
}

ProfileRecord : {
	schema : Str,
	suite : Str,
	sample : U64,
	samples : U64,
	run_index : U64,
	case_id : Str,
	arguments : List(Str),
	probe_schema : Str,
	probe_case_name : Str,
	probe_size : U64,
	probe_chunk_size : U64,
	probe_count : U64,
	probe_checksum : U64,
	probe_compiler : Str,
	probe_build_mode : Str,
	probe_source : Str,
	rss_bytes : U64,
	host_os : Str,
	metric_label : Str,
}

Metric : { bytes : U64, label : Str }

usage : Str
usage = "usage: profile-memory [smoke|full] [samples]; defaults to smoke with one sample; samples must be 1..3"

probe_timeout : Str
probe_timeout = "180s"

main! = |raw_args| {
	args = os_args_to_str(raw_args.drop_first(1)) ? |message| ProfileFailed(message)
	if args.contains("--help") or args.contains("-h") {
		Stdout.line!(usage)?
		return Ok({})
	}
	config = parse_config(args) ? |message| ProfileFailed("${message}; ${usage}")
	probe = required_env!("ROC_REDIS_MEMORY_PROBE")?
	expected_build_mode = required_env!("ROC_REDIS_BUILD_MODE")?
	expected_source = required_env!("ROC_REDIS_NIX_SOURCE_ID")?
	timer = host_timer!({})?
	validate_commands!(probe, timer)?
	cases = match config.suite {
		Smoke => smoke_cases
		Full => full_cases({})
	}
	suite_name = if config.suite == Smoke "smoke" else "full"
	var $sample = 1.U64
	var $run_index = 1.U64
	while $sample <= config.samples {
		for planned in cases {
			measurement = run_case!(probe, timer, planned, expected_build_mode, expected_source)?
			record : ProfileRecord
			record = {
				schema: "roc-redis-memory-profile/v1",
				suite: suite_name,
				sample: $sample,
				samples: config.samples,
				run_index: $run_index,
				case_id: planned.id,
				arguments: planned.arguments,
				probe_schema: measurement.probe.schema,
				probe_case_name: measurement.probe.case_name,
				probe_size: measurement.probe.size,
				probe_chunk_size: measurement.probe.chunk_size,
				probe_count: measurement.probe.count,
				probe_checksum: measurement.probe.checksum,
				probe_compiler: measurement.probe.compiler,
				probe_build_mode: measurement.probe.build_mode,
				probe_source: measurement.probe.source,
				rss_bytes: measurement.metric.bytes,
				host_os: timer.host_os,
				metric_label: measurement.metric.label,
			}
			Stdout.line!(Json.to_str(record))?
			$run_index = $run_index + 1
		}
		$sample = $sample + 1
	}
	Ok({})
}

parse_config : List(Str) -> Try(Config, Str)
parse_config = |args|
	match args {
		[] => Ok({ suite: Smoke, samples: 1 })
		[mode] => Ok({ suite: parse_suite(mode)?, samples: 1 })
		[mode, samples] => Ok({ suite: parse_suite(mode)?, samples: parse_samples(samples)? })
		_ => Err("too many arguments")
	}

parse_suite : Str -> Try([Full, Smoke], Str)
parse_suite = |text|
	match text {
		"smoke" => Ok(Smoke)
		"full" => Ok(Full)
		_ => Err("suite must be smoke or full")
	}

parse_samples : Str -> Try(U64, Str)
parse_samples = |text| {
	value = parse_decimal("samples", text)?
	if value < 1 or value > 3 {
		Err("samples must be 1..3")
	} else {
		Ok(value)
	}
}

os_args_to_str : List(OsStr) -> Try(List(Str), Str)
os_args_to_str = |args| {
	var $values = List.with_capacity(args.len())
	for arg in args {
		value = OsStr.to_str_try(arg) ? |_| "command-line argument is not valid UTF-8"
		$values = $values.append(value)
	}
	Ok($values)
}

required_env! : Str => Try(Str, [ProfileFailed(Str), ..])
required_env! = |name|
	match Env.var_str!(OsStr.from_str(name)) {
		Ok("") => Err(ProfileFailed("${name} must not be empty"))
		Ok(value) => Ok(value)
		Err(error) => Err(ProfileFailed("read ${name}: ${Str.inspect(error)}"))
	}

host_timer! : {} => Try(Timer, [ProfileFailed(Str), ..])
host_timer! = |_| {
	host_platform = Env.platform!()
	match host_platform.os {
		MACOS => Ok({
			host_os: "macos",
			program: "/usr/bin/time",
			leading_arguments: ["-l"],
			metric_label: "maximum resident set size",
			style: Mac,
		})
		LINUX => Ok({
			host_os: "linux",
			program: "time",
			leading_arguments: ["-v"],
			metric_label: "Maximum resident set size (kbytes)",
			style: Gnu,
		})
		other => Err(ProfileFailed("memory profiling supports macOS and Linux, not ${Str.inspect(other)}"))
	}
}

validate_commands! : Str, Timer => Try({}, [ProfileFailed(Str), ..])
validate_commands! = |probe, timer| {
	if !Cmd.check_available!(probe) {
		return Err(ProfileFailed("ROC_REDIS_MEMORY_PROBE is not executable: ${probe}"))
	}
	if !Cmd.check_available!("timeout") {
		return Err(ProfileFailed("GNU timeout is required"))
	}
	if !Cmd.check_available!(timer.program) {
		return Err(ProfileFailed("RSS tool is not executable: ${timer.program}"))
	}
	version = Cmd.new_str("timeout").args_str(["--version"]).exec_output!() ? |error| ProfileFailed("inspect timeout: ${Str.inspect(error)}")
	if !version.stdout_utf8.starts_with("timeout (GNU coreutils)") {
		return Err(ProfileFailed("timeout must be GNU coreutils"))
	}
	Ok({})
}

run_case! : Str, Timer, Case, Str, Str => Try({ metric : Metric, probe : ProbeRecord }, [ProfileFailed(Str), ..])
run_case! = |probe_program, timer, planned, expected_build_mode, expected_source| {
	timed_arguments = timer.leading_arguments.concat([probe_program]).concat(planned.arguments)
	arguments = ["--signal=TERM", "--kill-after=5s", probe_timeout, timer.program].concat(timed_arguments)
	output = match Cmd.new_str("timeout").args_str(arguments).exec_output!() {
		Ok({ stdout_utf8, stderr_utf8_lossy }) => Ok({ stdout: stdout_utf8, stderr: stderr_utf8_lossy })
		Err(NonZeroExitCode({ exit_code, .. })) if exit_code == 124 or exit_code == 137 => Err(ProfileFailed("${planned.id} exceeded ${probe_timeout}"))
		Err(NonZeroExitCode({ exit_code, stdout_utf8_lossy, stderr_utf8_lossy, .. })) => Err(ProfileFailed("${planned.id} exited ${exit_code.to_str()}: ${combine_output(stdout_utf8_lossy, stderr_utf8_lossy)}"))
		Err(error) => Err(ProfileFailed("run ${planned.id}: ${Str.inspect(error)}"))
	}?
	probe = parse_probe_record(output.stdout) ? |ProfileFailed(message)| ProfileFailed(message)
	if !probe.validated or probe.schema != "roc-redis-memory/v1" {
		return Err(ProfileFailed("${planned.id} returned an invalid probe record"))
	}
	if probe.build_mode != expected_build_mode or probe.source != expected_source {
		return Err(ProfileFailed("${planned.id} provenance differs from the controller environment"))
	}
	if probe.compiler.is_empty() or probe.case_name.is_empty() {
		return Err(ProfileFailed("${planned.id} omitted compiler or case metadata"))
	}
	metric = parse_metric(timer, output.stderr) ? |ProfileFailed(message)| ProfileFailed(message)
	Ok({ probe, metric })
}

parse_probe_record : Str -> Try(ProbeRecord, [ProfileFailed(Str)])
parse_probe_record = |stdout| {
	lines = stdout.trim().split_on("\n")
	if lines.len() != 1 or lines == [""] {
		return Err(ProfileFailed("memory probe must emit exactly one JSON line"))
	}
	line = lines.first() ? |_| ProfileFailed("memory probe emitted no record")
	Json.parse(line).map_err(|error| ProfileFailed("parse memory probe JSON: ${Str.inspect(error)}"))
}

parse_metric : Timer, Str -> Try(Metric, [ProfileFailed(Str)])
parse_metric = |timer, stderr| {
	var $matches = []
	for line in stderr.split_on("\n") {
		parsed = match timer.style {
			Mac => parse_mac_line(line)
			Gnu => parse_gnu_line(line)
		}
		match parsed {
			MetricValue(value) => {
				$matches = $matches.append(value)
			}
			NotMetric => {}
		}
	}
	value = match $matches {
		[only] => only
		[] => return Err(ProfileFailed("RSS output omitted exact metric label ${Str.inspect(timer.metric_label)}"))
		_ => return Err(ProfileFailed("RSS output repeated exact metric label ${Str.inspect(timer.metric_label)}"))
	}
	bytes = match timer.style {
		Mac => value
		Gnu => {
			if value > 18_446_744_073_709_551_615 / 1024 {
				return Err(ProfileFailed("GNU maximum RSS overflows bytes"))
			}
			value * 1024
		}
	}
	Ok({ bytes, label: timer.metric_label })
}

parse_mac_line : Str -> [MetricValue(U64), NotMetric]
parse_mac_line = |line| {
	tokens = line.trim().split_on(" ").keep_if(|token| !token.is_empty())
	match tokens {
		[value, "maximum", "resident", "set", "size"] => match U64.from_str(value) {
			Ok(parsed) => MetricValue(parsed)
			Err(_) => NotMetric
		}
		_ => NotMetric
	}
}

parse_gnu_line : Str -> [MetricValue(U64), NotMetric]
parse_gnu_line = |line|
	match line.trim().split_on(":") {
		["Maximum resident set size (kbytes)", value] => match U64.from_str(value.trim()) {
			Ok(parsed) => MetricValue(parsed)
			Err(_) => NotMetric
		}
		_ => NotMetric
	}

parse_decimal : Str, Str -> Try(U64, Str)
parse_decimal = |name, text| {
	if text.is_empty() or !text.to_utf8().all(|byte| byte >= '0' and byte <= '9') {
		return Err("${name} must be an unsigned decimal integer")
	}
	U64.from_str(text).map_err(|_| "${name} overflows U64")
}

case : Str, List(Str) -> Case
case = |id, arguments| { id, arguments }

smoke_cases : List(Case)
smoke_cases = [
	case("idle", ["idle"]),
	case("bulk-64k-whole", ["bulk", "65536", "whole"]),
	case("bulk-64k-31", ["bulk", "65536", "31"]),
	case("line-simple-64k-31", ["line", "simple", "65536", "31"]),
	case("array-1024-whole", ["array", "1024", "whole"]),
	case("mget-1024", ["mget", "1024"]),
	case("batch-flat-256", ["batch", "flat", "256"]),
	case("batch-deep-256", ["batch", "deep", "256"]),
	case("repeat-100-32", ["repeat", "100", "32"]),
	case("error-held-64k-2", ["error", "held", "65536", "2"]),
	case("error-compact-64k-2", ["error", "compact", "65536", "2"]),
	case("advertised-u64-max", ["advertised-header", "18446744073709551615"]),
]

full_cases : {} -> List(Case)
full_cases = |_| {
	var $cases = [case("idle", ["idle"])]
	for size in ["65536", "1048576", "8388608"] {
		for chunk in ["whole", "16384", "31", "1"] {
			$cases = $cases.append(case("bulk-${size}-${chunk}", ["bulk", size, chunk]))
		}
	}
	for kind in ["simple", "error"] {
		for chunk in ["whole", "31", "1"] {
			$cases = $cases.append(case("line-${kind}-65536-${chunk}", ["line", kind, "65536", chunk]))
		}
	}
	for count in ["1024", "16384", "65536"] {
		for chunk in ["whole", "31"] {
			$cases = $cases.append(case("array-${count}-${chunk}", ["array", count, chunk]))
		}
		$cases = $cases.append(case("mget-${count}", ["mget", count]))
	}
	for count in ["16", "256", "1024", "4096"] {
		for shape in ["flat", "deep"] {
			$cases = $cases.append(case("batch-${shape}-${count}", ["batch", shape, count]))
		}
	}
	$cases = $cases.concat([
		case("repeat-100-32", ["repeat", "100", "32"]),
		case("repeat-10000-32", ["repeat", "10000", "32"]),
		case("error-held-1m-16", ["error", "held", "1048576", "16"]),
		case("error-compact-1m-16", ["error", "compact", "1048576", "16"]),
		case("advertised-8m", ["advertised-header", "8388608"]),
		case("advertised-u64-max", ["advertised-header", "18446744073709551615"]),
	])
	$cases
}

combine_output : Str, Str -> Str
combine_output = |stdout, stderr| {
	trimmed_stdout = stdout.trim()
	trimmed_stderr = stderr.trim()
	if trimmed_stdout.is_empty() {
		trimmed_stderr
	} else if trimmed_stderr.is_empty() {
		trimmed_stdout
	} else {
		"${trimmed_stdout}\n${trimmed_stderr}"
	}
}

expect parse_config([]) == Ok({ suite: Smoke, samples: 1 })
expect parse_config(["full", "3"]) == Ok({ suite: Full, samples: 3 })
expect parse_config(["full", "0"]).is_err()
expect parse_config(["unknown"]).is_err()
expect parse_mac_line("  12345  maximum resident set size") == MetricValue(12_345)
expect parse_mac_line("12345 maximum resident size") == NotMetric
expect parse_gnu_line("\tMaximum resident set size (kbytes): 6789") == MetricValue(6789)
expect parse_gnu_line("Maximum resident set size (bytes): 6789") == NotMetric
mac_test_timer : Timer
mac_test_timer = { host_os: "macos", program: "/usr/bin/time", leading_arguments: ["-l"], metric_label: "maximum resident set size", style: Mac }

gnu_test_timer : Timer
gnu_test_timer = { host_os: "linux", program: "time", leading_arguments: ["-v"], metric_label: "Maximum resident set size (kbytes)", style: Gnu }
expect parse_metric(mac_test_timer, "0.00 real\n  12345 maximum resident set size\n").map_ok(|metric| metric.bytes) == Ok(12_345)
expect parse_metric(gnu_test_timer, "Maximum resident set size (kbytes): 6789\n").map_ok(|metric| metric.bytes) == Ok(6_951_936)
expect parse_metric(mac_test_timer, "123 maximum resident set size\n456 maximum resident set size\n").is_err()
expect parse_metric(gnu_test_timer, "User time (seconds): 0.00\n").is_err()
expect smoke_cases.len() == 12
expect full_cases({}).len() == 42
