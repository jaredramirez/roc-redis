import /Bytes
import /Command
import /NonEmpty
import /Reply
import /Request
import /Resp

## Cardinality estimates, not exact set counts. Redis validates key encodings.
HyperLogLog :: [].{

	## True means the internal representation changed, not that the estimated
	## cardinality necessarily increased. An empty list can create an empty HLL.
	pf_add : Bytes.Bytes, List(Bytes.Bytes) -> Request.Request(Bool, Reply.Error)
	pf_add = |key, elements| Request.new(Command.new("PFADD", [key].concat(elements)), Reply.integer_boolean)

	pf_count : NonEmpty.NonEmpty(Bytes.Bytes) -> Request.Request(I64, Reply.Error)
	pf_count = |keys| Request.new(Command.new("PFCOUNT", keys.to_list()), Reply.integer)

	## Redis permits no source keys; the existing destination participates.
	pf_merge : Bytes.Bytes, List(Bytes.Bytes) -> Request.Request({}, Reply.Error)
	pf_merge = |destination, sources| Request.new(Command.new("PFMERGE", [destination].concat(sources)), Reply.okay)
}

expect HyperLogLog.pf_add("hll", []).command() == Command.new("PFADD", ["hll"])
expect HyperLogLog.pf_add("hll", ["a", "b"]).decode(Resp.Integer(1)) == Ok(True)
expect HyperLogLog.pf_add("hll", []).decode(Resp.Integer(2)).is_err()
expect HyperLogLog.pf_count(NonEmpty.new(Bytes.from_str("a"), ["b"])).command() == Command.new("PFCOUNT", ["a", "b"])
expect HyperLogLog.pf_merge("hll", []).decode(Resp.simple_utf8("OK")) == Ok({})
