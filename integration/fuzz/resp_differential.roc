app [target] {
	fuzz: platform "https://github.com/lukewilliamboswell/roc-fuzz/releases/download/0.4.0-rc1/9k2cfuAWoBfcRBRiVbriXFf1dHktoRBbieifYN7NmTHc.tar.zst",
	roc: "nightly-2026-09-07-14d9829",
	redis: "../../package/main.roc",
}

import fuzz.Fuzz
import RespOracle

input_generator = {
	wire: Fuzz.list(Fuzz.u8, 512),
	chunks: Fuzz.list(Fuzz.u8, 64),
}.Fuzz

test = |input| {
	reference = RespOracle.reference(input.wire)
	whole = RespOracle.observe(input.wire)
	fragmented = RespOracle.observe_chunks(input.wire, input.chunks)
	single = RespOracle.observe_single_bytes(input.wire)

	if fragmented != whole or single != whole {
		crash "RESP2 result or exact failure changed under arbitrary chunking"
	}

	if RespOracle.agrees(reference, whole) {
		Fuzz.keep
	} else {
		crash "production RESP2 result differs from the independent reference grammar"
	}
}

target = Fuzz.target_with({
	name: "resp2-differential",
	generator: input_generator,
	test,
	show: |input| Str.inspect(input),
})
