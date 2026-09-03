## Shared portable check/expect/runtime runner. Live services, compiler repros,
## fuzz campaigns, and backend qualification remain explicit separate commands.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
}

import pf.Cmd
import pf.Env
import pf.OsStr exposing [OsStr]
import pf.Path
import pf.Random
import pf.Stdout
import TestSuite

main! : List(OsStr) => Try({}, [SuiteFailed(Str), Exit(I32), ..])
main! = |args| {
	var $arguments = []
	for arg in args.drop_first(1) {
		text = OsStr.to_str_try(arg) ? |_| SuiteFailed("argument is not valid UTF-8")
		$arguments = $arguments.append(text)
	}
	mode = parse_mode($arguments) ? |message| SuiteFailed(message)
	match mode {
		Check => {
			for root in TestSuite.format_roots {
				format_tree!(Path.utf8(root))?
			}
			run!("roc", ["--opt=dev", "scripts/command-catalog.roc", "--", "check"])?
			for entry in TestSuite.entries {
				run!("roc", ["check", entry.source])?
			}
		}
		Test => {
			for entry in TestSuite.entries {
				if entry.expectations {
					# Match clean CI evaluation everywhere. In particular, aliased HTTP
					# dependencies need --no-cache on the pinned nightly.
					run!("roc", ["test", "--opt=dev", "--no-cache", entry.source])?
				}
			}
			temp = create_temp!(8)?
			result = runtime_tests!(temp)
			cleanup = temp.delete_all!().map_err(|error| SuiteFailed("remove suite binaries: ${Str.inspect(error)}"))
			match (result, cleanup) {
				(Err(SuiteFailed(primary)), Err(SuiteFailed(secondary))) => return Err(SuiteFailed("${primary}; cleanup also failed: ${secondary}"))
				(Err(error), _) => return Err(error)
				(_, Err(error)) => return Err(error)
				_ => {}
			}
		}
	}
	Ok({})
}

parse_mode : List(Str) -> Try([Check, Test], Str)
parse_mode = |args| match args {
	["check"] => Ok(Check)
	["test"] => Ok(Test)
	_ => Err("usage: roc scripts/test.roc -- check|test (run from repository root)")
}

run! : Str, List(Str) => Try({}, [SuiteFailed(Str), ..])
run! = |program, arguments| {
	Stdout.line!("suite | ${program} ${Str.join_with(arguments, " ")}") ? |error| SuiteFailed(Str.inspect(error))
	status = Cmd.new_str("timeout").args_str(["--signal=TERM", "--kill-after=5s", "300", program].concat(arguments)).exec_exit_code!()
		? |error| SuiteFailed("launch ${program}: ${Str.inspect(error)}")
	if status == 0 {
		Ok({})
	} else {
		Err(SuiteFailed("${program} ${Str.join_with(arguments, " ")} exited ${status.to_str()}"))
	}
}

format_tree! : Path.Path => Try({}, [SuiteFailed(Str), ..])
format_tree! = |root| {
	entries = root.list!() ? |error| SuiteFailed("list ${root.display()}: ${Str.inspect(error)}")
	var $sources = []
	for path in entries {
		kind = path.type!() ? |error| SuiteFailed("inspect ${path.display()}: ${Str.inspect(error)}")
		match kind {
			IsDir => {
				# Build products and result archives are not source directories.
				filename = path.filename() ? |error| SuiteFailed(Str.inspect(error))
				name = filename.to_str() ? |error| SuiteFailed(Str.inspect(error))
				if name != "target" and name != "results" {
					format_tree!(path)?
				}
			}
			IsFile => {
				if path.display().ends_with(".roc") {
					$sources = $sources.append(path.display())
				}
			}
			_ => {}
		}
	}
	if !$sources.is_empty() {
		run!("roc", ["fmt", "--check"].concat($sources))?
	}
	Ok({})
}

create_temp! : U8 => Try(Path.Path, [SuiteFailed(Str), ..])
create_temp! = |attempts| {
	if attempts == 0 {
		return Err(SuiteFailed("could not create unique suite directory"))
	}
	seed = Random.seed_u64!() ? |error| SuiteFailed(Str.inspect(error))
	path = Env.temp_dir!().join("roc-redis-suite-${seed.to_str()}")
	match path.create_dir!() {
		Ok({}) => Ok(path)
		Err(PathErr(AlreadyExists, _)) => create_temp!(attempts - 1)
		Err(error) => Err(SuiteFailed(Str.inspect(error)))
	}
}

runtime_tests! : Path.Path => Try({}, [SuiteFailed(Str), ..])
runtime_tests! = |temp| {
	for source in TestSuite.build_only_subjects {
		_ = build_subject!(temp, source)?
	}
	for source in TestSuite.runtime_subjects {
		binary = build_subject!(temp, source)?
		run!(binary, [])?
	}
	Ok({})
}

build_subject! : Path.Path, Str => Try(Str, [SuiteFailed(Str), ..])
build_subject! = |temp, source| {
	# A distinct output per source prevents a missing build product from being
	# mistaken for a previously built subject. The directory starts empty.
	path = temp.join(Str.join_with(source.split_on("/"), "-").drop_suffix(".roc"))
	binary = path.display()
	run!("roc", ["build", "--opt=dev", "--no-cache", "--output=${binary}", source])?
	executable = path.is_executable!() ? |error| SuiteFailed(Str.inspect(error))
	if executable {
		Ok(binary)
	} else {
		Err(SuiteFailed("compiler did not produce executable ${binary}"))
	}
}

expect parse_mode(["check"]) == Ok(Check)
expect parse_mode(["test"]) == Ok(Test)
expect parse_mode(["unknown"]).is_err()
