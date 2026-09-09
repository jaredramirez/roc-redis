## Read-only proof against a disposable local Redis. The host supplies the port.
app [main!] {
	pf: platform "platform/main.roc",
	redis: "../../package/main.roc",
}

import pf.Tcp
import redis.Commands
import redis.Config
import redis.Connection

Ok(config) = Config.default |> Config.build

connection : Tcp.Stream -> Connection(Tcp.Error, Tcp.Error)
connection = |stream| {
	bound : Connection(_, _)
	bound = {
		config,
		read!: |max_bytes| stream.read_up_to!(max_bytes, 2_000)
			.map_ok(|bytes| if bytes.is_empty() End else Data(bytes)),
		write_all!: |bytes| stream.write!(bytes, 2_000),
	}
	bound
}

main! : U16 => Bool
main! = |port| {
	match Tcp.Pool.new!({ port, max_connections: 1 }) {
		Err(_) => False
		Ok(pool) => {
			result = exercise!(pool)
			closed = pool.close!()
			result.is_ok() and closed
		}
	}
}

exercise! : Tcp.Pool => Try({}, [Failed])
exercise! = |pool| {
	# Returning a stream on purpose demonstrates that escaped aliases become
	# invalid, even when the underlying TCP connection is reused.
	first = pool.with_connection!(
		2_000,
		|stream| {
			client = connection(stream)
			id = client.request!(Commands.Connect.client_id({})) ? |_| Failed
			Ok(Reuse({ id, stale: stream }))
		},
	) ? |_| Failed

	second = pool.with_connection!(
		2_000,
		|stream| {
			client = connection(stream)
			id = client.request!(Commands.Connect.client_id({})) ? |_| Failed
			if id != first.id {
				return Err(Failed)
			}
			match first.stale.write!([], 10) {
				Err(InvalidLease) => {}
				_ => {
					return Err(Failed)
				}
			}
			# With one slot occupied, another checkout must time out.
			nested = pool.with_connection!(1, |_other| Ok(Reuse({})))
			if nested.is_ok() {
				return Err(Failed)
			}
			pong = client.request!(Commands.Connect.ping()) ? |_| Failed
			if pong.to_utf8() != Ok("PONG") {
				return Err(Failed)
			}
			Ok(Discard(id))
		},
	) ? |_| Failed

	# Explicit discard must cause a new Redis connection next time.
	third = pool.with_connection!(
		2_000,
		|stream| {
			id = connection(stream).request!(Commands.Connect.client_id({})) ? |_| Failed
			if id == second {
				return Err(Failed)
			}
			Ok(Reuse(id))
		},
	) ? |_| Failed

	# An early callback error must discard rather than return the socket.
	fail! : Tcp.Stream => Try(Tcp.Disposition({}), [Intentional])
	fail! = |_stream| Err(Intentional)
	failed = pool.with_connection!(2_000, fail!)
	if failed.is_ok() {
		return Err(Failed)
	}
	fourth = pool.with_connection!(
		2_000,
		|stream| {
			id = connection(stream).request!(Commands.Connect.client_id({})) ? |_| Failed
			if id == third {
				return Err(Failed)
			}
			# No reply is pending: a read must time out and poison the lease.
			match stream.read_up_to!(64, 1) {
				Err(TimedOut) => {}
				_ => {
					return Err(Failed)
				}
			}
			Ok(Reuse(id))
		},
	) ? |_| Failed
	pool.with_connection!(
		2_000,
		|stream| {
			id = connection(stream).request!(Commands.Connect.client_id({})) ? |_| Failed
			if id == fourth {
				return Err(Failed)
			}
			Ok(Reuse({}))
		},
	) ? |_| Failed
	Ok({})
}
