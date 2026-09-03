import redis.Batch
import redis.Bytes
import redis.Command
import redis.Commands
import redis.Config
import redis.Execute
import redis.NonEmpty
import redis.Reply
import redis.Request
import redis.Resp

## Live semantic contracts on the one random key already owned by basic_cli.
## Type replacement and TTL installation commit atomically in MULTI/EXEC.
TypedCases :: [].{
	run! : Bytes.Bytes, Config.Config, Execute.Transport(read_error, write_error) => Try({}, Str)
	run! = |key, config, transport| {
		members = NonEmpty.new(Bytes.from_str("a"), ["b"])
		replace!(key, Commands.Sets.sadd(key, members).map(|_| {}), config, transport)?
		assert_reply!(Commands.Sets.smis_member(key, NonEmpty.new(Bytes.from_str("a"), ["missing"])), [True, False], config, transport)?
		assert_reply!(Commands.Sets.scard(key), 2, config, transport)?

		replace!(key, Commands.Lists.rpush(key, members).map(|_| {}), config, transport)?
		assert_reply!(Commands.Lists.lpop(key, Many(3)), Many(Present([Bytes.from_str("a"), "b"])), config, transport)?
		assert_reply!(Commands.Lists.lpop(key, Many(3)), Many(Absent), config, transport)?
		assert_reply!(Commands.Lists.lpop(key, One), One(Absent), config, transport)?

		fields = NonEmpty.new({ field: Bytes.from_str("a"), value: Bytes.from_str("one") }, [{ field: "b", value: "two" }])
		replace!(key, Commands.Hashes.hset(key, fields).map(|_| {}), config, transport)?
		assert_reply!(Commands.Hashes.hmget(key, NonEmpty.new(Bytes.from_str("b"), ["missing", "a"])), [Present(Bytes.from_str("two")), Absent, Present(Bytes.from_str("one"))], config, transport)?
		if available!("HPEXPIRE", config, transport)? {
			assert_reply!(Commands.Hashes.hpexpire(key, 60_000, Always, members), [ExpirationSet, ExpirationSet], config, transport)?
		}

		scored = NonEmpty.new({ member: Bytes.from_str("a"), score: Bytes.from_str("1") }, [{ member: "b", score: "2" }])
		replace!(key, Commands.SortedSets.zadd(key, Add(scored), { condition: Always }).map(|_| {}), config, transport)?
		assert_reply!(Commands.SortedSets.zrange(key, Ranks({ start: 0, end: -1 }), False, WithScores), WithScores(scored.to_list()), config, transport)?
		assert_reply!(Commands.SortedSets.zrev_range_by_score(key, NegativeInfinity, PositiveInfinity, Absent, Members), Members([Bytes.from_str("b"), "a"]), config, transport)?
		assert_reply!(Commands.SortedSets.zmscore(key, NonEmpty.new(Bytes.from_str("a"), ["missing"])), [Present(Bytes.from_str("1")), Absent], config, transport)?

		point = { coordinates: { longitude: Bytes.from_str("0"), latitude: Bytes.from_str("0") }, member: Bytes.from_str("origin") }
		replace!(key, Commands.Geo.geo_add(key, NonEmpty.new(point, []), { condition: Always }).map(|_| {}), config, transport)?
		assert_reply!(Commands.Geo.geo_pos(key, ["missing"]), [Absent], config, transport)?
		assert_reply!(Commands.Geo.geo_hash(key, ["missing"]), [Absent], config, transport)?
		_ = Execute.request!(config, Commands.Geo.geo_search(key, Member("origin"), Radius({ radius: "1", unit: Kilometers }), { order: Ascending }, { distance: True, hash: True, coordinates: True }), transport).map_err(Str.inspect)?

		replace!(key, Commands.HyperLogLog.pf_add(key, ["a", "b"]).map(|_| {}), config, transport)?
		assert_reply!(Commands.HyperLogLog.pf_count(NonEmpty.new(key, [])), 2, config, transport)?
		replace!(key, Commands.Bitmaps.set_bit(key, 0, True).map(|_| {}), config, transport)?
		assert_reply!(Commands.Bitmaps.get_bit(key, 0), True, config, transport)?

		if available!("ARSET", config, transport)? {
			replace!(key, Commands.Arrays.arset(key, 2, NonEmpty.new(Bytes.from_str("x"), ["3"])).map(|_| {}), config, transport)?
			assert_reply!(Commands.Arrays.arget_range(key, { start: 1, end: 3 }), [Absent, Present(Bytes.from_str("x")), Present(Bytes.from_str("3"))], config, transport)?
			assert_reply!(Commands.Arrays.arscan(key, { start: 0, end: 9 }, Absent), [{ index: 2, value: Bytes.from_str("x") }, { index: 3, value: "3" }], config, transport)?
			assert_reply!(Commands.Arrays.argrep(key, First, Last, NonEmpty.new(Exact(Bytes.from_str("x")), []), { combine: All }, WithValues), WithValues([{ index: 2, value: Bytes.from_str("x") }]), config, transport)?
			assert_reply!(Commands.Arrays.arop(key, { start: 0, end: 9 }, Sum), Decimal(Present(Bytes.from_str("3"))), config, transport)?
		}
		if available!("VADD", config, transport)? {
			replace!(key, Commands.VectorSets.vadd(key, Values(NonEmpty.new(Bytes.from_str("1"), ["0"])), "a", { quantization: None }).map(|_| {}), config, transport)?
			assert_reply!(Commands.VectorSets.vis_member(key, "a"), True, config, transport)?
			assert_reply!(Commands.VectorSets.vemb(key, "missing", Values), Values(Absent), config, transport)?
			_ = Execute.request!(config, Commands.VectorSets.vemb(key, "a", Raw), transport).map_err(Str.inspect)?
			_ = Execute.request!(config, Commands.VectorSets.vsim(key, Element("a"), { scores: True, attributes: True }), transport).map_err(Str.inspect)?
		}

		replace!(key, Commands.Streams.xadd(key, "1-0", fields, { no_create: False }).map(|_| {}), config, transport)?
		assert_reply!(Commands.Streams.xlen(key), 1, config, transport)?
		assert_reply!(Commands.Streams.xrange(key, "-", "+", Absent), [{ id: Bytes.from_str("1-0"), fields: Present(fields.to_list()), claimed: Absent }], config, transport)?
		assert_reply!(Commands.Streams.xgroup_create(key, "group", "0", { create_stream: False }), {}, config, transport)?
		assert_reply!(Commands.Streams.xpending(key, "group", Summary), Summary({ count: 0, first: Absent, last: Absent, consumers: Absent }), config, transport)?
		_ = Execute.request!(config, Commands.Streams.xread_group("group", "consumer", NonEmpty.new({ key, id: Bytes.from_str(">") }, []), { no_ack: False }), transport).map_err(Str.inspect)?
		assert_reply!(Commands.Streams.xack(key, "group", NonEmpty.new(Bytes.from_str("1-0"), [])), 1, config, transport)?
		assert_reply!(Commands.Scripting.eval("return {ARGV[1], false}", [], ["binary"], Reply.array), [Resp.bulk_utf8("binary"), Resp.NullBulkString], config, transport)?
		_ = Execute.request!(config, Commands.Server.time({}), transport).map_err(Str.inspect)?
		_ = Execute.request!(config, Commands.Server.config_get(NonEmpty.new(Bytes.from_str("port"), [])), transport).map_err(Str.inspect)?
		assert_reply!(Commands.PubSub.pubsub_num_sub(["roc-redis-unsubscribed"]), [{ channel: Bytes.from_str("roc-redis-unsubscribed"), count: 0 }], config, transport)?
		Ok({})
	}
}

assert_reply! = |request, expected, config, transport| {
	actual = Execute.request!(config, request, transport).map_err(|error| "${Str.inspect(request.command())}: ${Str.inspect(error)}")?
	if actual == expected {
		Ok({})
	} else {
		Err("${Str.inspect(request.command())}: expected ${Str.inspect(expected)}, got ${Str.inspect(actual)}")
	}
}

replace! : Bytes.Bytes, Request.Request({}, Reply.Error), Config.Config, Execute.Transport(read_error, write_error) => Try({}, Str)
replace! = |key, initializer, config, transport| {
	requests = [
		Commands.Keyspace.del(NonEmpty.new(key, [])).map(|_| {}),
		initializer,
		Commands.Keyspace.pexpire(key, 60_000, Always).map(|_| {}),
	]
	_ = Execute.request!(config, Commands.Transactions.multi({}), transport).map_err(Str.inspect)?
	_ = Execute.batch!(config, Batch.all(requests.map(Commands.Transactions.queued)), transport).map_err(Str.inspect)?
	result = Execute.request!(config, Commands.Transactions.exec_batch(Batch.all(requests)), transport).map_err(Str.inspect)?
	match result {
		Present([{}, {}, {}]) => Ok({})
		_ => Err("initializer transaction did not commit all three replies")
	}
}

available! : Bytes.Bytes, Config.Config, Execute.Transport(read_error, write_error) => Try(Bool, Str)
available! = |name, config, transport| {
	request = Request.new(
		Command.new("COMMAND", ["INFO", name]),
		|reply| match reply {
			Resp.Array([Resp.NullBulkString]) => Ok(False)
			Resp.Array([Resp.Array(_)]) => Ok(True)
			_ => Err(InvalidCommandInfo)
		},
	)
	Execute.request!(config, request, transport).map_err(Str.inspect)
}
