## Minimal executable reproduction for the directory formatter diagnostic bug.
## Run from the roc-redis repository root with:
##
##     roc --opt=dev roc-bugs/fmt-directory-reporting/repro.roc
##
## The formatter failure is intentional. This app copies the two unformatted
## fixtures into a unique temporary directory, runs `roc fmt --check` on that
## directory, and removes it before returning the observed non-zero status.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.22.2/9zUBxb1LtXYVc4eR4hAtd1WQDwBYDhM6HQdZz1UFCm2m.tar.zst",
}

import pf.Cmd
import pf.Env
import pf.OsStr
import pf.Path
import pf.Random

fixture_dir : Path.Path
fixture_dir = Path.utf8("roc-bugs/fmt-directory-reporting")

main! : List(OsStr) => Try({}, [FormatterFailureObserved(I32), ReproFailed(Str), Exit(I32), ..])
main! = |args| {
	match args.drop_first(1) {
		[] => {}
		_ => return Err(ReproFailed("usage: roc --opt=dev roc-bugs/fmt-directory-reporting/repro.roc"))
	}

	temp_dir = create_temp_dir!() ? |error| ReproFailed("create formatter repro directory: ${Str.inspect(error)}")
	result = run_repro!(temp_dir)
	cleanup_result = temp_dir.delete_all!()

	match (result, cleanup_result) {
		(Ok(exit_code), Ok({})) =>
			if exit_code == 0 {
				Err(ReproFailed("roc fmt --check unexpectedly accepted both unformatted fixtures"))
			} else {
				Err(FormatterFailureObserved(exit_code))
			}
		(Err(error), Ok({})) => Err(error)
		(Ok(_), Err(error)) => Err(ReproFailed("remove formatter repro directory: ${Str.inspect(error)}"))
		(Err(error), Err(cleanup_error)) =>
			Err(ReproFailed("${describe_error(error)}; also failed to remove formatter repro directory: ${Str.inspect(cleanup_error)}"))
		}
}

create_temp_dir! : () => Try(Path.Path, _)
create_temp_dir! = || create_temp_dir_with_attempts!(8)

create_temp_dir_with_attempts! : U8 => Try(Path.Path, _)
create_temp_dir_with_attempts! = |attempts_remaining| {
	if attempts_remaining == 0 {
		Err(UniqueDirectoryUnavailable)
	} else {
		seed = Random.seed_u64!()?
		candidate = Env.temp_dir!().join("roc-fmt-directory-reporting-${seed.to_str()}")
		match candidate.create_dir!() {
			Ok({}) => Ok(candidate)
			Err(PathErr(AlreadyExists, _)) => create_temp_dir_with_attempts!(attempts_remaining - 1)
			Err(error) => Err(error)
		}
	}
}

run_repro! : Path.Path => Try(I32, [ReproFailed(Str), ..])
run_repro! = |temp_dir| {
	copy_fixture!("Alpha.roc.txt", temp_dir.join("Alpha.roc"))?
	copy_fixture!("Beta.roc.txt", temp_dir.join("Beta.roc"))?

	Cmd.new_str("roc")
		.args_str(["fmt", "--check"])
		.arg(temp_dir.to_os_str())
		.exec_exit_code!()
		.map_err(|error| ReproFailed("run roc fmt --check: ${Str.inspect(error)}"))
}

copy_fixture! : Str, Path.Path => Try({}, [ReproFailed(Str), ..])
copy_fixture! = |name, destination| {
	source = fixture_dir.join(name)
	bytes = source.read_bytes!() ? |error| ReproFailed("read ${source.display()}: ${Str.inspect(error)}")
	destination.write_bytes!(bytes)
		.map_err(|error| ReproFailed("write ${destination.display()}: ${Str.inspect(error)}"))
}

describe_error : [ReproFailed(Str), ..] -> Str
describe_error = |error|
	match error {
		ReproFailed(message) => message
		other => Str.inspect(other)
	}
