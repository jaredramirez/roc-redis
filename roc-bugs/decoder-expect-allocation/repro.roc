app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.22.2/9zUBxb1LtXYVc4eR4hAtd1WQDwBYDhM6HQdZz1UFCm2m.tar.zst",
	redis: "../../package/main.roc",
}

import Decoder
import Resp

main! = |_args| Ok({})

feed_bytes : Decoder.Decoder, List(U8), U64, List(Resp.Resp) -> Bool
feed_bytes = |decoder, wire, index, values|
	if index >= wire.len() {
		values.len() == 1 and Decoder.finish(decoder).is_ok()
	} else {
		match Decoder.feed(decoder, wire.sublist({ start: index, len: 1 })) {
			Failed(_) => False
			Progress({ decoder: next, values: emitted }) => feed_bytes(next, wire, index + 1, values.concat(emitted))
		}
	}

all_splits : List(U8), Resp.Resp, U64 -> Bool
all_splits = |wire, expected, split|
	if split > wire.len() {
		True
	} else {
		match Decoder.feed(Decoder.init({}), wire.take_first(split)) {
			Failed(_) => False
			Progress({ decoder, values }) => match Decoder.feed(decoder, wire.drop_first(split)) {
				Failed(_) => False
				Progress({ decoder: final_decoder, values: following }) =>
					values.concat(following) == [expected] and Decoder.finish(final_decoder).is_ok() and all_splits(wire, expected, split + 1)
				}
		}
	}

expect {
	var $payload = List.with_capacity(256)
	var $byte = 0.U16
	while $byte < 256 {
		$payload = $payload.append($byte.to_u8_wrap())
		$byte = $byte + 1
	}
	wire = "$256\r\n".to_utf8().concat($payload).concat(['\r', '\n'])
	all_splits(wire, Resp.BulkString($payload), 0) and feed_bytes(Decoder.init({}), wire, 0, [])
}
