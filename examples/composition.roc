## Pure custom decoding and heterogeneous composition; no Redis service needed.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	redis: "../package/main.roc",
}

import pf.Stdout
import redis.Batch
import redis.Command
import redis.Reply
import redis.Request
import redis.Resp

# Custom decoders can map one complete reply into application semantics.
count_request = Request.new(Command.new("DBSIZE", []), Reply.integer)

text_request = Request.new(Command.echo("hello".to_utf8()), decode_text)

decode_text : Resp.Resp -> Try(Str, [WrongShape(Reply.Error), InvalidText])
decode_text = |reply| {
	bytes = Reply.bulk(reply) ? |error| WrongShape(error)
	Reply.utf8(bytes).map_err(|_| InvalidText)
}

plan = Batch.map2(Batch.one(count_request), Batch.one(text_request), |count, text| { count, text })

# Execute.batch!(config, plan, transport) would send both commands in one
# exchange. Here we supply replies directly to demonstrate the pure API.
main! = |_args| {
	Stdout.line!(summarize(plan.decode([Resp.Integer(3), Resp.bulk_utf8("hello")])))?
	Stdout.line!(summarize(plan.decode([Resp.Integer(3), Resp.error_utf8("ERR denied")])))?
	Ok({})
}

# Compact retained errors deliberately; don't retain/print an arbitrarily large
# unexpected reply just to classify it. map2 preserves left/right provenance.
summarize = |outcome| match outcome {
	Ok({ count, text }) => "${count.to_str()} keys; echoed ${text}"
	Err(BatchDecodeFailure(LeftFailure(ServerError(_)))) => "DBSIZE rejected by Redis"
	Err(BatchDecodeFailure(RightFailure(ServerError(_)))) => "ECHO rejected by Redis"
	Err(BatchDecodeFailure(LeftFailure(ReplyDecodeFailure(_)))) => "DBSIZE reply had the wrong shape"
	Err(BatchDecodeFailure(RightFailure(ReplyDecodeFailure(_)))) => "ECHO reply could not be decoded as text"
	Err(_) => "reply count/composition contract failed"
}

expect summarize(plan.decode([Resp.Integer(3), Resp.bulk_utf8("hello")])) == "3 keys; echoed hello"
expect summarize(plan.decode([Resp.Integer(3), Resp.error_utf8("ERR denied")])) == "ECHO rejected by Redis"
expect summarize(plan.decode([Resp.Integer(3), Resp.BulkString([255])])) == "ECHO reply could not be decoded as text"
expect {
	# each preserves all outcomes instead of returning the first semantic error.
	Batch.each([count_request, count_request]).decode([Resp.Integer(3), Resp.error_utf8("ERR denied")])
		== Ok([Ok(3), Err(ServerError("ERR denied"))])
}
