import /Bytes
import /Command
import /Commands/Decode
import /NonEmpty
import /Reply
import /Request
import /Resp

## Publishing and introspection use ordinary request/reply execution on a
## command-mode connection. Subscription changes are encoding-only: each may
## yield several acknowledgments and then unsolicited messages. A streaming
## adapter must own that connection; Execute.request! cannot manage it.
PubSub :: [].{
	Subscribers : { channel : Bytes.Bytes, count : I64 }
	publish : Bytes.Bytes, Bytes.Bytes -> Request.Request(I64, Reply.Error)
	publish = |channel, message| Request.new(Command.new("PUBLISH", [channel, message]), Reply.integer)

	spublish : Bytes.Bytes, Bytes.Bytes -> Request.Request(I64, Reply.Error)
	spublish = |channel, message| Request.new(Command.new("SPUBLISH", [channel, message]), Reply.integer)

	pubsub_channels : Reply.Optional(Bytes.Bytes) -> Request.Request(List(Bytes.Bytes), Reply.Error)
	pubsub_channels = |pattern| Request.new(Command.new("PUBSUB", [Bytes.from_str("CHANNELS")].concat(pattern_args(pattern))), Decode.bytes_list)

	pubsub_shard_channels : Reply.Optional(Bytes.Bytes) -> Request.Request(List(Bytes.Bytes), Reply.Error)
	pubsub_shard_channels = |pattern| Request.new(Command.new("PUBSUB", [Bytes.from_str("SHARDCHANNELS")].concat(pattern_args(pattern))), Decode.bytes_list)

	pubsub_num_pat : () -> Request.Request(I64, Reply.Error)
	pubsub_num_pat = || Request.new(Command.new("PUBSUB", ["NUMPAT"]), Reply.integer)

	pubsub_num_sub : List(Bytes.Bytes) -> Request.Request(List(Subscribers), Reply.Error)
	pubsub_num_sub = |channels| Request.new(Command.new("PUBSUB", [Bytes.from_str("NUMSUB")].concat(channels)), |reply| subscribers(reply, channels))

	pubsub_shard_num_sub : List(Bytes.Bytes) -> Request.Request(List(Subscribers), Reply.Error)
	pubsub_shard_num_sub = |channels| Request.new(Command.new("PUBSUB", [Bytes.from_str("SHARDNUMSUB")].concat(channels)), |reply| subscribers(reply, channels))

	subscribe : NonEmpty.NonEmpty(Bytes.Bytes) -> Command.Command
	subscribe = |channels| Command.new("SUBSCRIBE", channels.to_list())

	psubscribe : NonEmpty.NonEmpty(Bytes.Bytes) -> Command.Command
	psubscribe = |patterns| Command.new("PSUBSCRIBE", patterns.to_list())

	ssubscribe : NonEmpty.NonEmpty(Bytes.Bytes) -> Command.Command
	ssubscribe = |channels| Command.new("SSUBSCRIBE", channels.to_list())

	## Empty lists mean unsubscribe from all channels/patterns of this kind.
	unsubscribe : List(Bytes.Bytes) -> Command.Command
	unsubscribe = |channels| Command.new("UNSUBSCRIBE", channels)

	punsubscribe : List(Bytes.Bytes) -> Command.Command
	punsubscribe = |patterns| Command.new("PUNSUBSCRIBE", patterns)

	sunsubscribe : List(Bytes.Bytes) -> Command.Command
	sunsubscribe = |channels| Command.new("SUNSUBSCRIBE", channels)
}

pattern_args : Reply.Optional(Bytes.Bytes) -> List(Bytes.Bytes)
pattern_args = |pattern| match pattern {
	Absent => []
	Present(value) => [value]
}

subscribers : Resp.Resp, List(Bytes.Bytes) -> Try(List(PubSub.Subscribers), Reply.Error)
subscribers = |reply, channels| {
	items = Reply.array(reply)?
	if items.len() % 2 != 0 or items.len() / 2 != channels.len() {
		return Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
	}
	var $remaining = items
	var $values = List.with_capacity(channels.len())
	for expected_channel in channels {
		match $remaining {
			[channel_reply, count_reply, .. as rest] => {
				channel = Decode.bytes(channel_reply)?
				count = Reply.integer(count_reply)?
				if channel != expected_channel or count < 0 {
					return Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
				}
				$values = $values.append({ channel, count })
				$remaining = rest
			}
			_ => {
				return Err(UnexpectedReply({ actual: reply, expected: ArrayReply }))
			}
		}
	}
	Ok($values)
}

expect PubSub.pubsub_num_sub(["channel"]).decode(Resp.Array([Resp.bulk_utf8("channel"), Resp.Integer(2)])) == Ok([{ channel: Bytes.from_str("channel"), count: 2 }])
expect PubSub.pubsub_num_sub(["channel"]).decode(Resp.Array([Resp.bulk_utf8("wrong"), Resp.Integer(2)])).is_err()
expect PubSub.pubsub_num_sub([]).decode(Resp.Array([])) == Ok([])
expect PubSub.subscribe(NonEmpty.new(Bytes.from_str("a"), ["b"])) == Command.new("SUBSCRIBE", ["a", "b"])
expect PubSub.unsubscribe([]) == Command.new("UNSUBSCRIBE", [])
