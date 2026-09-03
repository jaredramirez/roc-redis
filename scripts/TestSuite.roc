## The portable suite inventory. Nix/Just/CI choose the environment, not tests.
## Checking, evaluating expectations, and executing compiled subjects are distinct.
TestSuite :: [].{
	Entry : { source : Str, expectations : Bool }
	entries : List(Entry)
	entries = [
		{ source: "package/main.roc", expectations: True },
		{ source: "benchmarks/roc.roc", expectations: True },
		{ source: "benchmarks/codec.roc", expectations: True },
		{ source: "benchmarks/stages.roc", expectations: True },
		{ source: "benchmarks/transport.roc", expectations: True },
		{ source: "benchmarks/decode.roc", expectations: True },
		{ source: "benchmarks/memory.roc", expectations: True },
		{ source: "integration/basic_cli.roc", expectations: True },
		{ source: "integration/bundle_server.roc", expectations: True },
		{ source: "integration/basic_webserver.roc", expectations: True },
		{ source: "integration/client_contract.roc", expectations: False },
		{ source: "integration/transport_properties.roc", expectations: False },
		{ source: "scripts/test-backends.roc", expectations: True },
		{ source: "scripts/profile-memory.roc", expectations: True },
		{ source: "scripts/check-known-bug.roc", expectations: True },
		{ source: "scripts/benchmark.roc", expectations: True },
		{ source: "scripts/command-catalog.roc", expectations: True },
		{ source: "scripts/test-bundle.roc", expectations: True },
		{ source: "scripts/test-integration.roc", expectations: True },
		{ source: "scripts/test-basic-webserver.roc", expectations: True },
		{ source: "scripts/test.roc", expectations: True },
		{ source: "examples/cli.roc", expectations: False },
		{ source: "examples/read_modify_write.roc", expectations: False },
		{ source: "examples/composition.roc", expectations: True },
		{ source: "examples/webserver.roc", expectations: False },
	]

	## These must run as built binaries, not just pass `roc check` or `roc test`.
	runtime_subjects : List(Str)
	runtime_subjects = ["integration/client_contract.roc", "integration/transport_properties.roc", "examples/composition.roc"]

	## Examples require a user-started service, so compile without launching them.
	build_only_subjects : List(Str)
	build_only_subjects = ["examples/cli.roc", "examples/read_modify_write.roc", "examples/webserver.roc"]

	## Recursion includes helpers and frozen compile-failure/bug fixtures, but
	## only formatting runs on those fixtures. Never discover tests by filename.
	format_roots : List(Str)
	format_roots = ["package", "integration", "benchmarks", "scripts", "roc-bugs", "examples"]
}

expect TestSuite.entries.any(|entry| entry.source == "scripts/test.roc" and entry.expectations)
expect TestSuite.runtime_subjects.all(|source| TestSuite.entries.any(|entry| entry.source == source))
