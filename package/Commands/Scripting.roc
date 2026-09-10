import /Bytes
import /Command
import /Commands/Decode
import /NonEmpty
import /Reply
import /Request
import /Resp

## Script/function results are application-defined. Supply their semantic
## decoder explicitly; key counts are derived and server errors stay separate.
Scripting :: [].{
	FlushMode : [Default, Sync, Async]
	ListOptions := { pattern : Reply.Optional(Bytes.Bytes) ?? Absent, with_code : Bool ?? False }

	eval : Bytes.Bytes, List(Bytes.Bytes), List(Bytes.Bytes), (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	eval = |program, keys, arguments, decoder| Request.new(Command.new("EVAL", [program, Bytes.from_str(keys.len().to_str())].concat(keys).concat(arguments)), decoder)

	eval_ro : Bytes.Bytes, List(Bytes.Bytes), List(Bytes.Bytes), (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	eval_ro = |program, keys, arguments, decoder| Request.new(Command.new("EVAL_RO", [program, Bytes.from_str(keys.len().to_str())].concat(keys).concat(arguments)), decoder)

	eval_sha : Bytes.Bytes, List(Bytes.Bytes), List(Bytes.Bytes), (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	eval_sha = |program, keys, arguments, decoder| Request.new(Command.new("EVALSHA", [program, Bytes.from_str(keys.len().to_str())].concat(keys).concat(arguments)), decoder)

	eval_sha_ro : Bytes.Bytes, List(Bytes.Bytes), List(Bytes.Bytes), (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	eval_sha_ro = |program, keys, arguments, decoder| Request.new(Command.new("EVALSHA_RO", [program, Bytes.from_str(keys.len().to_str())].concat(keys).concat(arguments)), decoder)

	fcall : Bytes.Bytes, List(Bytes.Bytes), List(Bytes.Bytes), (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	fcall = |program, keys, arguments, decoder| Request.new(Command.new("FCALL", [program, Bytes.from_str(keys.len().to_str())].concat(keys).concat(arguments)), decoder)

	fcall_ro : Bytes.Bytes, List(Bytes.Bytes), List(Bytes.Bytes), (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	fcall_ro = |program, keys, arguments, decoder| Request.new(Command.new("FCALL_RO", [program, Bytes.from_str(keys.len().to_str())].concat(keys).concat(arguments)), decoder)

	function_delete : Bytes.Bytes -> Request.Request({}, Reply.Error)
	function_delete = |name| Request.new(Command.new("FUNCTION", ["DELETE", name]), Reply.okay)

	function_dump : () -> Request.Request(Bytes.Bytes, Reply.Error)
	function_dump = || Request.new(Command.new("FUNCTION", ["DUMP"]), Decode.bytes)

	function_flush : FlushMode -> Request.Request({}, Reply.Error)
	function_flush = |mode| Request.new(Command.new("FUNCTION", [Bytes.from_str("FLUSH")].concat(flush_args(mode))), Reply.okay)

	function_kill : () -> Request.Request({}, Reply.Error)
	function_kill = || Request.new(Command.new("FUNCTION", ["KILL"]), Reply.okay)

	## Introspection structures can change with Redis versions; callers choose
	## the semantic structure they need rather than losing unknown fields.
	function_list : ListOptions, (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	function_list = |options, decoder| {
		pattern = match options.pattern {
			Absent => []
			Present(value) => [Bytes.from_str("LIBRARYNAME"), value]
		}
		code = if options.with_code {
			[Bytes.from_str("WITHCODE")]
		} else {
			[]
		}
		Request.new(Command.new("FUNCTION", [Bytes.from_str("LIST")].concat(pattern).concat(code)), decoder)
	}

	function_load : Bytes.Bytes, Bool -> Request.Request(Bytes.Bytes, Reply.Error)
	function_load = |code, replace| Request.new(
		Command.new(
			"FUNCTION",
			[Bytes.from_str("LOAD")].concat(
				if replace {
					[Bytes.from_str("REPLACE")]
				} else {
					[]
				},
			).append(code),
		),
		Decode.bytes,
	)

	function_restore : Bytes.Bytes, [Append, Flush, Replace] -> Request.Request({}, Reply.Error)
	function_restore = |payload, mode| Request.new(
		Command.new(
			"FUNCTION",
			[
				"RESTORE",
				payload,
				match mode {
					Append => Bytes.from_str("APPEND")
					Flush => Bytes.from_str("FLUSH")
					Replace => Bytes.from_str("REPLACE")
				},
			],
		),
		Reply.okay,
	)

	function_stats : (Resp.Resp -> Try(value, error)) -> Request.Request(value, error)
	function_stats = |decoder| Request.new(Command.new("FUNCTION", ["STATS"]), decoder)

	## Encoding-only: enabling the Lua debugger changes subsequent execution
	## into a debugger interaction, not ordinary RESP2 request/reply behavior.
	script_debug : [Yes, Sync, No] -> Command.Command
	script_debug = |mode| Command.new(
		"SCRIPT",
		[
			"DEBUG",
			match mode {
				Yes => Bytes.from_str("YES")
				Sync => Bytes.from_str("SYNC")
				No => Bytes.from_str("NO")
			},
		],
	)

	script_exists : NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(List(Bool), Reply.Error)
	script_exists = |digests| Request.new(Command.new("SCRIPT", [Bytes.from_str("EXISTS")].concat(digests.to_list())), |reply| Decode.counted(reply, digests.len(), Reply.integer_boolean))

	script_flush : FlushMode -> Request.Request({}, Reply.Error)
	script_flush = |mode| Request.new(Command.new("SCRIPT", [Bytes.from_str("FLUSH")].concat(flush_args(mode))), Reply.okay)

	script_kill : () -> Request.Request({}, Reply.Error)
	script_kill = || Request.new(Command.new("SCRIPT", ["KILL"]), Reply.okay)

	script_load : Bytes.Bytes -> Request.Request(Bytes.Bytes, Reply.Error)
	script_load = |code| Request.new(Command.new("SCRIPT", ["LOAD", code]), Decode.bytes)
}

flush_args : Scripting.FlushMode -> List(Bytes.Bytes)
flush_args = |mode| match mode {
	Default => []
	Sync => ["SYNC"]
	Async => ["ASYNC"]
}

expect Scripting.eval("return 1", [], [], Reply.integer).command() == Command.new("EVAL", ["return 1", "0"])
expect Scripting.eval("return 1", [], [], Reply.integer).decode(Resp.Integer(1)) == Ok(1)
expect Scripting.eval_sha_ro("digest", ["key"], ["value"], Reply.raw).command() == Command.new("EVALSHA_RO", ["digest", "1", "key", "value"])
expect Scripting.script_exists(NonEmpty.new(Bytes.from_str("digest"), [])).decode(Resp.Array([])).is_err()
expect Scripting.function_restore(Bytes.from_list([0, 255]), Replace).command() == Command.new("FUNCTION", ["RESTORE", Bytes.from_list([0, 255]), "REPLACE"])
expect Scripting.function_load("code", True).command() == Command.new("FUNCTION", ["LOAD", "REPLACE", "code"])
