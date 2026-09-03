import /Batch
import /Bytes
import /Command
import /NonEmpty
import /Reply
import /Request
import /Resp

## Transaction commands require exclusive ownership of the same connection
## across the entire transaction, not merely each Execute call. A timeout after
## EXEC leaves the commit outcome uncertain; this module never retries.
Transactions :: [].{
	multi : {} -> Request.Request({}, Reply.Error)
	multi = |_| Request.new(Command.new("MULTI", []), Reply.okay)

	discard : {} -> Request.Request({}, Reply.Error)
	discard = |_| Request.new(Command.new("DISCARD", []), Reply.okay)

	watch : NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request({}, Reply.Error)
	watch = |keys| Request.new(Command.new("WATCH", keys.to_list()), Reply.okay)

	unwatch : {} -> Request.Request({}, Reply.Error)
	unwatch = |_| Request.new(Command.new("UNWATCH", []), Reply.okay)

	## Redis replies QUEUED while in MULTI; the original request's decoder is
	## only applicable later to its element in EXEC. Queueing can still fail.
	queued : Request.Request(value, error) -> Request.Request({}, Reply.Error)
	queued = |request| Request.new(
		request.command(),
		|response| match response {
			SimpleString(['Q', 'U', 'E', 'U', 'E', 'D']) => Ok({})
			_ => Err(UnexpectedReply({ actual: response, expected: SimpleReply }))
		},
	)

	## Preserve errors inside EXEC's array; these represent committed commands
	## that failed individually, not an aborted transaction. NullArray is WATCH
	## cancellation. NullBulkString is never a valid cancellation reply.
	exec : {} -> Request.Request(Reply.Optional(List(Resp.Resp)), Reply.Error)
	exec = |_| Request.new(Command.new("EXEC", []), Reply.array_or_null)

	## Reuse a batch's semantic decoder for the EXEC array, without resending its
	## commands. The caller must have queued exactly this plan, in this order.
	exec_batch : Batch.Batch(value, error) -> Request.Request(Reply.Optional(value), [InvalidExecReply(Reply.Error), BatchDecodeFailure(error), ReplyCountMismatch({ expected : U64, actual : U64 })])
	exec_batch = |batch| Request.new(
		Command.new("EXEC", []),
		|response| {
			replies = Reply.array_or_null(response).map_err(|error| InvalidExecReply(error))?
			match replies {
				Absent => Ok(Absent)
				Present(values) => batch.decode(values).map_ok(|value| Present(value)).map_err(
					|error| match error {
						BatchDecodeFailure(details) => BatchDecodeFailure(details)
						ReplyCountMismatch(details) => ReplyCountMismatch(details)
					},
				)
			}
		},
	)
}

expect Transactions.watch(NonEmpty.new(Bytes.from_str("a"), ["b"])).command() == Command.new("WATCH", ["a", "b"])
expect Transactions.exec({}).decode(Resp.NullArray) == Ok(Absent)
expect Transactions.exec({}).decode(Resp.NullBulkString).is_err()
expect Transactions.exec({}).decode(Resp.Array([Resp.error_utf8("ERR failed")])) == Ok(Present([Resp.error_utf8("ERR failed")]))
expect {
	request = Request.new(Command.ping({}), Reply.simple)
	Transactions.queued(request).decode(Resp.simple_utf8("QUEUED")) == Ok({})
		and Transactions.queued(request).decode(Resp.simple_utf8("OK")).is_err()
}
expect {
	batch = Batch.each([Request.new(Command.ping({}), Reply.integer)])
	Transactions.exec_batch(batch).decode(Resp.Array([Resp.Integer(2)])) == Ok(Present([Ok(2)]))
		and Transactions.exec_batch(batch).decode(Resp.NullArray) == Ok(Absent)
			and Transactions.exec_batch(batch).decode(Resp.Array([])).is_err()
}
