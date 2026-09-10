import Bytes
import NonEmptyBytes

## A binary-safe Redis command.
##
## Redis clients send commands as non-empty RESP arrays whose elements are
## bulk strings. The first element is the command name and the remaining
## elements are arguments. No quoting, escaping, or UTF-8 conversion is
## performed by the byte-oriented constructor.
Command :: { parts : List(List(U8)) }.{
	is_eq : _

	Error : [EmptyCommandName]

	## Construct using a name whose non-empty invariant is already established.
	new : NonEmptyBytes.NonEmptyBytes, List(Bytes.Bytes) -> Command
	new = |name, arguments| Command.{ parts: [name.to_bytes().to_list()].concat(arguments.map(Bytes.to_list)) }

	## Read-only wire arguments, including the validated nonempty command name.
	to_parts : Command -> List(List(U8))
	to_parts = |command| command.parts

	## Construct a command from a byte-valued name and arguments.
	from_bytes : List(U8), List(List(U8)) -> Try(Command, Error)
	from_bytes = |name, arguments|
		if name.is_empty() {
			Err(EmptyCommandName)
		} else {
			Ok(Command.{ parts: [name].concat(arguments) })
		}

	## Construct a command whose byte-valued name is non-empty by construction.
	##
	## Quoted names are validated by NonEmptyBytes.from_quote at compile time.
	from_nonempty_bytes : NonEmptyBytes.NonEmptyBytes, List(List(U8)) -> Command
	from_nonempty_bytes = |name, arguments| {
		Command.{ parts: [name.to_bytes().to_list()].concat(arguments) }
	}

	## Construct a command from UTF-8 text.
	from_utf8 : Str, List(Str) -> Try(Command, Error)
	from_utf8 = |name, arguments|
		Command.from_bytes(name.to_utf8(), arguments.map(Str.to_utf8))

	## Construct `PING`.
	ping : () -> Command
	ping = || Command.from_nonempty_bytes("PING", [])

	## Construct `PING message`, preserving arbitrary message bytes.
	ping_with_message : List(U8) -> Command
	ping_with_message = |message| Command.from_nonempty_bytes("PING", [message])

	## Construct binary-safe `ECHO message`.
	echo : List(U8) -> Command
	echo = |message| Command.from_nonempty_bytes("ECHO", [message])

	## Encode one command using the Redis client wire format.
	encode : Command -> List(U8)
	encode = |command| {
		parts = command.parts
		prefix = Str.to_utf8("*${parts.len().to_str()}\r\n")
		prefix.concat(parts.join_map(encode_bulk))
	}

	## Encode commands back-to-back for Redis pipelining.
	encode_pipeline : List(Command) -> List(U8)
	encode_pipeline = |commands|
		commands.join_map(Command.encode)

	## Measure before allocating the outbound buffer. Subtract from a remaining
	## budget so even a sum exceeding U64 cannot overflow.
	pipeline_size : List(Command), U64 -> Try(U64, [RequestByteLimitExceeded({ limit : U64 })])
	pipeline_size = |commands, limit| {
		var $remaining = limit
		for command in commands {
			$remaining = consume_size($remaining, decimal_digits(command.parts.len()) + 3, limit)?
			for part in command.parts {
				$remaining = consume_size($remaining, decimal_digits(part.len()) + 5, limit)?
				$remaining = consume_size($remaining, part.len(), limit)?
			}
		}
		Ok(limit - $remaining)
	}

	## Encode into one reserved buffer after the complete size check succeeds.
	encode_bounded : List(Command), U64 -> Try(List(U8), [RequestByteLimitExceeded({ limit : U64 })])
	encode_bounded = |commands, limit| {
		size = Command.pipeline_size(commands, limit)?
		var $output = List.with_capacity(size)
		for command in commands {
			$output = append_decimal($output.append('*'), command.parts.len()).append('\r').append('\n')
			for part in command.parts {
				$output = append_decimal($output.append('$'), part.len()).append('\r').append('\n').concat(part).append('\r').append('\n')
			}
		}
		Ok($output)
	}
}

## Write decimal digits directly into the already reserved wire buffer.
## The division guard ensures multiplying the divisor cannot overflow U64.
append_decimal : List(U8), U64 -> List(U8)
append_decimal = |output, value| {
	var $divisor = 1.U64
	while value / $divisor >= 10 {
		$divisor = $divisor * 10
	}
	var $output = output
	while $divisor > 0 {
		$output = $output.append('0' + ((value / $divisor) % 10).to_u8_wrap())
		$divisor = $divisor / 10
	}
	$output
}

expect append_decimal([], 0) == ['0']
expect append_decimal([], 10) == ['1', '0']
expect append_decimal([], 18_446_744_073_709_551_615) == "18446744073709551615".to_utf8()

expect {
	var $value = 0.U64
	var $okay = True
	while $value <= 1000 {
		$okay = $okay and append_decimal([255, 0], $value) == [255, 0].concat($value.to_str().to_utf8())
		$value = $value + 1
	}
	$okay
}

expect {
	var $okay = True
	for length in [0.U64, 9, 10, 99, 100, 999, 1000] {
		command = Command.echo(List.repeat(255, length))
		wire = Command.encode(command)
		$okay = $okay and Command.encode_bounded([command], wire.len()) == Ok(wire)
		$okay = $okay and Command.encode_bounded([command], wire.len() - 1) == Err(RequestByteLimitExceeded({ limit: wire.len() - 1 }))
	}
	$okay
}

consume_size : U64, U64, U64 -> Try(U64, [RequestByteLimitExceeded({ limit : U64 })])
consume_size = |remaining, size, limit|
	if size > remaining {
		Err(RequestByteLimitExceeded({ limit: limit }))
	} else {
		Ok(remaining - size)
	}

decimal_digits : U64 -> U64
decimal_digits = |value| {
	var $number = value
	var $digits = 1
	while $number >= 10 {
		$number = $number / 10
		$digits = $digits + 1
	}
	$digits
}

encode_bulk : List(U8) -> List(U8)
encode_bulk = |bytes|
	Str.to_utf8("$${bytes.len().to_str()}\r\n")
		.concat(bytes)
		.concat([13, 10])

## The Redis protocol specification's `LLEN mylist` example.
expect {
	command = Command.from_utf8("LLEN", ["mylist"])?
	Command.encode(command) == Str.to_utf8("*2\r\n$4\r\nLLEN\r\n$6\r\nmylist\r\n")
}

## Arguments are binary-safe, including NUL, CRLF, and invalid UTF-8.
expect {
	command = Command.from_bytes(Str.to_utf8("SET"), [Str.to_utf8("key"), [0, 13, 10, 255]])?
	Command.encode(command) == Str.to_utf8("*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$4\r\n").concat([0, 13, 10, 255, 13, 10])
}

## An empty command name is rejected, while empty arguments are valid.
expect Command.from_bytes([], []) == Err(EmptyCommandName)

expect {
	command = Command.from_nonempty_bytes("GET", [[0, 255]])
	Command.encode(command) == Str.to_utf8("*2\r\n$3\r\nGET\r\n$2\r\n").concat([0, 255, 13, 10])
}

expect {
	command = Command.from_bytes(Str.to_utf8("ECHO"), [[]])?
	Command.encode(command) == Str.to_utf8("*2\r\n$4\r\nECHO\r\n$0\r\n\r\n")
}

expect Command.encode(Command.echo([0, 13, 10, 255])) == Str.to_utf8("*2\r\n$4\r\nECHO\r\n$4\r\n").concat([0, 13, 10, 255, 13, 10])

expect Command.encode(Command.ping_with_message([0, 255])) == Str.to_utf8("*2\r\n$4\r\nPING\r\n$2\r\n").concat([0, 255, 13, 10])

## Text lengths are UTF-8 byte lengths, not Unicode scalar counts.
expect {
	command = Command.from_utf8("SET", ["café", "🦀"])?
	Command.encode(command) == Str.to_utf8("*3\r\n$3\r\nSET\r\n$5\r\ncafé\r\n$4\r\n🦀\r\n")
}

## A pipeline has no separator beyond each command's own RESP framing.
expect {
	ping = Command.ping()
	echo = Command.from_utf8("ECHO", ["hi"])?
	Command.encode_pipeline([ping, echo]) == Command.encode(ping).concat(Command.encode(echo))
}

expect Command.encode_pipeline([]).is_empty()

expect Command.encode_bounded([Command.ping()], 14) == Ok(Command.encode(Command.ping()))

expect Command.encode_bounded([Command.ping()], 13) == Err(RequestByteLimitExceeded({ limit: 13 }))

expect Command.encode_bounded([], 0) == Ok([])

expect {
	commands = [Command.ping(), Command.echo([0, 255, '\r', '\n']), Command.echo([])]
	expected = Command.encode_pipeline(commands)
	Command.pipeline_size(commands, expected.len()) == Ok(expected.len()) and Command.encode_bounded(commands, expected.len()) == Ok(expected)
}
