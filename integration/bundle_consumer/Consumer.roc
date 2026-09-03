import redis.Arrays as RawArrays
import redis.Bitmaps as RawBitmaps
import redis.Batch
import redis.Bytes
import redis.Cluster as RawCluster
import redis.Command
import redis.Commands
import redis.Config
import redis.Connection as RawConnection
import redis.Decoder
import redis.Geo as RawGeo
import redis.Hashes as RawHashes
import redis.HyperLogLog as RawHyperLogLog
import redis.Keyspace as RawKeyspace
import redis.Lists as RawLists
import redis.NonEmptyBytes
import redis.NonEmpty
import redis.PubSub as RawPubSub
import redis.Reply
import redis.Request
import redis.Resp
import redis.Scripting as RawScripting
import redis.Server as RawServer
import redis.Sets as RawSets
import redis.SortedSets as RawSortedSets
import redis.Streams as RawStreams
import redis.Strings as RawStrings
import redis.Transactions as RawTransactions
import redis.VectorSets as RawVectorSets

## A minimal downstream consumer which exercises every public module from the
## packaged archive. Package dependencies fetched by URL do not run their own
## expectations, so these checks intentionally live in the consumer.
Consumer := [].{}

Ok(configured) = Config.default |> Config.with_read_size(32_768) |> Config.build

expect configured.read_size() == 32_768

expect {
	request = Commands.Strings.set("key", "value", { condition: IfMissing, expiration: Milliseconds(60_000) })
	request.command() == Command.new("SET", ["key", "value", "NX", "PX", "60000"])
		and request.decode(Resp.NullBulkString) == Ok(NotApplied)
}

expect {
	request = Commands.Strings.incr_ex("counter", Integer({ by: 1 }), Unchanged)
	request.decode(Resp.Array([Resp.Integer(2), Resp.Integer(1)])) == Ok(Integers({ value: 2, applied: 1 }))
}

expect Commands.Strings.lcs("first", "second", Length).decode(Resp.Integer(4)) == Ok(Length(4))

expect {
	name : NonEmptyBytes.NonEmptyBytes
	name = "ECHO"
	value : Bytes.Bytes
	value = "hello"
	command = Command.new(name, [value])
	Command.encode(command) == "*2\r\n$4\r\nECHO\r\n$5\r\nhello\r\n".to_utf8()
}

expect {
	request = Request.new(
		Command.ping({}),
		|response| match response {
			Resp.Integer(value) => Ok(value)
			_ => Err(CustomDecoderError)
		},
	)
	Batch.each([request, request]).decode([Resp.Integer(1), Resp.NullArray]) == Ok([Ok(1), Err(ReplyDecodeFailure(CustomDecoderError))])
}

expect {
	command = Command.from_utf8("ECHO", ["hello"])?
	Command.encode(command) == Str.to_utf8("*2\r\n$4\r\nECHO\r\n$5\r\nhello\r\n")
}

expect {
	match Decoder.feed(Decoder.init({}), Str.to_utf8("*2\r\n+OK\r\n:1\r\n")) {
		Progress({ decoder, values: [response] }) =>
			Decoder.finish(decoder) == Ok({}) and response == Resp.Array([Resp.simple_utf8("OK"), Resp.Integer(1)])
		_ => False
	}
}

expect {
	match Config.default |> Config.with_read_size(0) |> Config.build {
		Err(ZeroLimit(ReadSize)) => True
		_ => False
	}
}

expect {
	key = Str.to_utf8("key")
	commands = [
		RawArrays.arcount(key),
		RawBitmaps.getbit(key, Str.to_utf8("0")),
		RawCluster.cluster_info({}),
		RawConnection.select(Str.to_utf8("0")),
		RawGeo.geopos(key, []),
		RawHashes.hgetall(key),
		RawHyperLogLog.pfcount(key, []),
		RawKeyspace.exists(key, []),
		RawLists.lindex(key, Str.to_utf8("0")),
		RawPubSub.publish(Str.to_utf8("channel"), Str.to_utf8("message")),
		RawScripting.eval(Str.to_utf8("return 1"), [], []),
		RawServer.dbsize({}),
		RawSets.scard(key),
		RawSortedSets.zcard(key),
		RawStreams.xdel(key, Str.to_utf8("0-1"), []),
		RawStrings.get(key),
		RawTransactions.multi({}),
		RawVectorSets.vcard(key),
	]

	commands.len() == 18 and commands.join_map(Command.encode).len() > 0
}

expect {
	Commands.Strings.get("key").decode(Resp.NullBulkString) == Ok(Absent)
}

expect {
	key = Bytes.from_str("key")
	commands = [
		Commands.Arrays.arcount(key).command(),
		Commands.Bitmaps.get_bit(key, 0).command(),
		Commands.Cluster.info({}).command(),
		Commands.Connection.select(0).command(),
		Commands.Geo.geo_pos(key, []).command(),
		Commands.Hashes.hget_all(key).command(),
		Commands.HyperLogLog.pf_count(NonEmpty.new(key, [])).command(),
		Commands.Keyspace.exists(NonEmpty.new(key, [])).command(),
		Commands.Lists.lindex(key, 0).command(),
		Commands.PubSub.publish("channel", "message").command(),
		Commands.Scripting.eval("return 1", [], [], Reply.integer).command(),
		Commands.Server.dbsize({}).command(),
		Commands.Sets.scard(key).command(),
		Commands.SortedSets.zcard(key).command(),
		Commands.Streams.xdel(key, NonEmpty.new(Bytes.from_str("0-1"), [])).command(),
		Commands.Strings.get(key).command(),
		Commands.Transactions.multi({}).command(),
		Commands.VectorSets.vcard(key).command(),
	]
	commands.len() == 18 and commands.join_map(Command.encode).len() > 0
}

## Dependent vector input grammar remains usable across the package boundary;
## VALUES is non-empty and its count is derived instead of caller-supplied.
expect {
	command = RawVectorSets.vadd(
		Str.to_utf8("vectors"),
		[],
		Values({ first: Str.to_utf8("1.25"), rest: [Str.to_utf8("-2.5")] }),
		Str.to_utf8("item"),
		[],
	)

	Command.encode(command) == Str.to_utf8("*7\r\n$4\r\nVADD\r\n$7\r\nvectors\r\n$6\r\nVALUES\r\n$1\r\n2\r\n$4\r\n1.25\r\n$4\r\n-2.5\r\n$4\r\nitem\r\n")
}
