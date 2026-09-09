import Host

## Loopback-only TCP pools. IDs are opaque to applications, and every checkout
## has a fresh generation so aliases cannot access a later borrower's socket.
Tcp :: [].{
	Error : [PoolUnavailable, AcquireFailed, InvalidLease, TimedOut, IoFailed, InvalidLimit]
	Disposition(value) : [Reuse(value), Discard(value)]

	Pool :: { id : U64 }.{
		new! : { port : U16, max_connections : U64 } => Try(Pool, Error)
		new! = |settings| {
			id = Host.create!(settings.port, settings.max_connections)
			if id == 0 Err(PoolUnavailable) else Ok(Pool.{ id })
		}

		## Cleanup runs on both callback success and callback error. A crash
		## terminates this demo process; the OS then closes all its sockets.
		with_connection! : Pool, U64, (Stream => Try(Disposition(value), error)) => Try(value, [PoolError(Error), CallbackError(error)])
		with_connection! = |pool, timeout_ms, use!| {
			id = Host.acquire!(pool.id, timeout_ms)
			if id == 0 {
				Err(PoolError(AcquireFailed))
			} else {
				outcome = use!(Stream.{ id })
				match outcome {
					Ok(Reuse(value)) => {
						if Host.finish!(id, True) Ok(value) else Err(PoolError(InvalidLease))
					}
					Ok(Discard(value)) => {
						_ = Host.finish!(id, False)
						Ok(value)
					}
					Err(error) => {
						_ = Host.finish!(id, False)
						Err(CallbackError(error))
					}
				}
			}
		}

		## Close idle sockets and invalidate active leases. Repeated closes
		## fail; this demo never recycles pool IDs.
		close! : Pool => Bool
		close! = |pool| Host.close!(pool.id)
	}

	Stream :: { id : U64 }.{
		read_up_to! : Stream, U64, U64 => Try(List(U8), Error)
		read_up_to! = |stream, max_bytes, timeout_ms| {
			result = Host.read!(stream.id, max_bytes, timeout_ms)
			if result.code == 0 Ok(result.bytes) else Err(decode_error(result.code))
		}

		write! : Stream, List(U8), U64 => Try({}, Error)
		write! = |stream, bytes, timeout_ms| {
			code = Host.write!(stream.id, bytes, timeout_ms)
			if code == 0 Ok({}) else Err(decode_error(code))
		}
	}
}

decode_error : U8 -> Tcp.Error
decode_error = |code| match code {
	1 => InvalidLease
	2 => TimedOut
	4 => InvalidLimit
	_ => IoFailed
}
