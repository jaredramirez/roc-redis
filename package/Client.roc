import Bytes
import Config
import Connection
import Execute
import Positive
import Reply
import /Commands/Session as Session

## A reusable client: validated Config plus optional session policy (auth and
## database selection). It mints connections from the bare stream primitives.
##
##   `attach`     pure  — bind a live transport into a Connection (no I/O).
##   `handshake!` effect — run the session setup (AUTH, SELECT) a fresh socket
##                         needs; run once per socket.
##   `connect!`   effect — attach then handshake!, the batteries-included path.
##
## A pool runs `handshake!` once when it dials a fresh socket and only `attach`
## on each subsequent reuse. The client owns Redis session identity; the
## platform owns the socket, its lifecycle, deadlines, and TLS.
Client := {
	config : Config.Config,
	auth : Reply.Optional(Session.Credentials),
	select_db : Reply.Optional(Positive.Positive),
}.{

	## A client with no authentication and the default database (db 0).
	new : Config.Config -> Client
	new = |config| Client.{ config, auth: Absent, select_db: Absent }

	## Authenticate every fresh connection with these credentials.
	with_auth : Client, Session.Credentials -> Client
	with_auth = |client, credentials| { ..client, auth: Present(credentials) }

	## Select a non-default database on every fresh connection. Database 0 is the
	## default, so represent it by leaving this unset: a positive index excludes
	## 0, which means `with_db(0)` is a compile-time error by design.
	with_db : Client, Positive.Positive -> Client
	with_db = |client, index| { ..client, select_db: Present(index) }

	## Bind a live transport into a Connection. Pure: no I/O and no handshake.
	## Use for a reused socket whose session is already established, or when you
	## will run `handshake!` yourself.
	attach : Client, Execute.Transport(read_err, write_err) -> Connection.Connection(read_err, write_err)
	attach = |client, transport| Connection.open(client.config, transport)

	## Run the session handshake (AUTH then SELECT, as configured) over an
	## already-attached connection. Run once per fresh socket. On any error the
	## caller MUST discard the socket: `Rejected` means a clean frame but an
	## unusable session (usually permanent, e.g. a bad password); `ExchangeFailed`
	## means the transport failed mid-handshake and framing is ambiguous.
	handshake! : Client, Connection.Connection(read_err, write_err) => Try({}, HandshakeError(read_err, write_err))
	handshake! = |client, connection| {
		_ = match client.auth {
			Present(credentials) => connection.request!(Session.auth(credentials)) ? |error| auth_error(error)
			Absent => {}
		}
		_ = match client.select_db {
			Present(index) => connection.request!(Session.select(index.to_u64())) ? |error| select_error(error)
			Absent => {}
		}
		Ok({})
	}

	## `attach` then `handshake!`. The one obvious path for a single, fresh
	## connection; pooling code drops to `attach`/`handshake!` directly.
	connect! : Client, Execute.Transport(read_err, write_err) => Try(Connection.Connection(read_err, write_err), HandshakeError(read_err, write_err))
	connect! = |client, transport| {
		connection = client.attach(transport)
		client.handshake!(connection)?
		Ok(connection)
	}

	## A failed handshake always requires discarding the socket, whatever the
	## cause: the session was never fully established.
	disposition : HandshakeError(read_err, write_err) -> Execute.Disposition
	disposition = |_error| Discard
}

## Why a fresh connection could not be initialized.
##   `Rejected`      — the server refused a handshake command; framing is intact
##                     but the session is unusable (usually permanent).
##   `ExchangeFailed`— a transport failure during the handshake; framing is
##                     ambiguous (possibly transient).
##   `Unexpected`    — a handshake command was rejected client-side or its reply
##                     was undecodable; not expected for these fixed commands.
HandshakeError(read_err, write_err) : [
	Rejected([Auth(Bytes.Bytes), Select(Bytes.Bytes)]),
	ExchangeFailed(Execute.ExchangeError(read_err, write_err)),
	Unexpected([Auth, Select]),
]

auth_error : Execute.Error(read_err, write_err, decode_err) -> HandshakeError(read_err, write_err)
auth_error = |error| match error {
	ExchangeFailed(details) => ExchangeFailed(details)
	ServerError(bytes) => Rejected(Auth(bytes))
	RequestRejected(_) => Unexpected(Auth)
	ReplyDecodeFailure(_) => Unexpected(Auth)
}

select_error : Execute.Error(read_err, write_err, decode_err) -> HandshakeError(read_err, write_err)
select_error = |error| match error {
	ExchangeFailed(details) => ExchangeFailed(details)
	ServerError(bytes) => Rejected(Select(bytes))
	RequestRejected(_) => Unexpected(Select)
	ReplyDecodeFailure(_) => Unexpected(Select)
}

expect auth_error(ServerError(Bytes.from_str("WRONGPASS"))) == Rejected(Auth(Bytes.from_str("WRONGPASS")))
expect select_error(ServerError(Bytes.from_str("ERR DB index is out of range"))) == Rejected(Select(Bytes.from_str("ERR DB index is out of range")))
expect auth_error(ExchangeFailed(EmptyData)) == ExchangeFailed(EmptyData)
expect select_error(RequestRejected(RequestByteLimitExceeded({ limit: 16 }))) == Unexpected(Select)
