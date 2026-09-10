## Read-only proof against a disposable local Redis. The host supplies the port.
app [main!] {
	pf: platform "platform/main.roc",
	redis: "../../package/main.roc",
}

import pf.Tcp
import redis.Commands
import redis.Connection
import redis.Client
import redis.Transport
import redis.Execute

client = Client.{}

transport_for : Tcp.Stream -> Execute.Transport(Tcp.Error, Tcp.Error)
transport_for = |stream| Transport.from_bytes_io({
	read_bytes!: |max_bytes| stream.read_up_to!(max_bytes, 2_000),
	write_all!: |bytes| stream.write!(bytes, 2_000),
})

## A Connection over the leased stream. This demo's client carries no session
## policy, so binding is a pure `attach`. A client with auth or database
## selection would additionally run `client.handshake!` once on a freshly dialed
## socket (and only `attach` on reuse) — the seam a production pool signals to
## the callback.
connection : Tcp.Stream -> Connection(Tcp.Error, Tcp.Error)
connection = |stream| client.attach(transport_for(stream))

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
			conn = connection(stream)
			id = conn.request!(Commands.Session.client_id()) ? |_| Failed
			Ok(Reuse({ id, stale: stream }))
		},
	) ? |_| Failed

	second = pool.with_connection!(
		2_000,
		|stream| {
			conn = connection(stream)
			id = conn.request!(Commands.Session.client_id()) ? |_| Failed
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
			pong = conn.request!(Commands.Session.ping()) ? |_| Failed
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
			id = connection(stream).request!(Commands.Session.client_id()) ? |_| Failed
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
			id = connection(stream).request!(Commands.Session.client_id()) ? |_| Failed
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
			id = connection(stream).request!(Commands.Session.client_id()) ? |_| Failed
			if id == fourth {
				return Err(Failed)
			}
			Ok(Reuse({}))
		},
	) ? |_| Failed

	# A semantic server error (SELECT out of range) leaves the wire framing
	# intact. Execute.disposition classifies it as Reuse, so the socket returns
	# to the pool instead of being dropped by an "any error discards" rule.
	recovered = pool.with_connection!(
		2_000,
		|stream| {
			conn = connection(stream)
			before = conn.request!(Commands.Session.client_id()) ? |_| Failed
			match conn.request!(Commands.Session.select(9_999)) {
				Ok(_) => Err(Failed)
				Err(error) => match Execute.disposition(error) {
					Reuse => Ok(Reuse(before))
					Discard => Err(Failed)
				}
			}
		},
	) ? |_| Failed

	# The same socket must come back: the server error did not poison it.
	pool.with_connection!(
		2_000,
		|stream| {
			id = connection(stream).request!(Commands.Session.client_id()) ? |_| Failed
			if id != recovered {
				return Err(Failed)
			}
			Ok(Reuse({}))
		},
	) ? |_| Failed
	Ok({})
}
