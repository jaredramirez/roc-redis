import /Bytes
import /Command
import /NonEmpty
import /Reply
import /Request
import /Resp

## Commands affecting connection state do not create or own a transport.
## Ordinary requests here require RESP2 command mode, replies enabled, and no
## active MULTI. See Transactions.queued for use within a transaction.
Session :: [].{
	Credentials : [Password(Bytes.Bytes), User({ username : Bytes.Bytes, password : Bytes.Bytes })]
	ClientType : [Normal, Master, Slave, Replica, PubSub]
	ListOptions := { kind : Reply.Optional(ClientType) ?? Absent, ids : List(U64) ?? [] }
	KillFilter : [Id(U64), Kind(ClientType), User(Bytes.Bytes), Address(Bytes.Bytes), LocalAddress(Bytes.Bytes), SkipSelf(Bool), MaxAge(U64)]
	KillMode : [Address(Bytes.Bytes), Filters(NonEmpty.NonEmpty(KillFilter))]
	TrackingOptions := {
		redirect : Reply.Optional(U64) ?? Absent,
		mode : [Default, Broadcast(List(Bytes.Bytes)), OptIn, OptOut] ?? Default,
		no_loop : Bool ?? False,
	}
	HelloOptions := { authentication : Reply.Optional({ username : Bytes.Bytes, password : Bytes.Bytes }) ?? Absent, name : Reply.Optional(Bytes.Bytes) ?? Absent }

	auth : Credentials -> Request.Request({}, Reply.Error)
	auth = |credentials| Request.new(
		Command.new(
			"AUTH",
			match credentials {
				Password(password) => [password]
				User(details) => [details.username, details.password]
			},
		),
		Reply.okay,
	)

	ping : () -> Request.Request(Bytes.Bytes, Reply.Error)
	ping = || Request.new(Command.new("PING", []), |reply| Reply.simple(reply).map_ok(Bytes.from_list))

	ping_with_message : Bytes.Bytes -> Request.Request(Bytes.Bytes, Reply.Error)
	ping_with_message = |message| Request.new(Command.new("PING", [message]), bulk)

	echo : Bytes.Bytes -> Request.Request(Bytes.Bytes, Reply.Error)
	echo = |message| Request.new(Command.new("ECHO", [message]), bulk)

	select : U64 -> Request.Request({}, Reply.Error)
	select = |database| Request.new(Command.new("SELECT", [decimal(database)]), Reply.okay)

	client_id : () -> Request.Request(I64, Reply.Error)
	client_id = || Request.new(Command.new("CLIENT", ["ID"]), Reply.integer)

	client_get_redir : () -> Request.Request(I64, Reply.Error)
	client_get_redir = || Request.new(Command.new("CLIENT", ["GETREDIR"]), Reply.integer)

	client_get_name : () -> Request.Request(Reply.Optional(Bytes.Bytes), Reply.Error)
	client_get_name = || Request.new(
		Command.new("CLIENT", ["GETNAME"]),
		|reply| Reply.bulk_or_null(reply).map_ok(
			|value| match value {
				Absent => Absent
				Present(bytes) => Present(Bytes.from_list(bytes))
			},
		),
	)

	client_set_name : Bytes.Bytes -> Request.Request({}, Reply.Error)
	client_set_name = |name| Request.new(Command.new("CLIENT", ["SETNAME", name]), Reply.okay)

	## Keep the extensible, binary-safe CLIENT INFO/LIST payload intact.
	client_info : () -> Request.Request(Bytes.Bytes, Reply.Error)
	client_info = || Request.new(Command.new("CLIENT", ["INFO"]), bulk)

	client_list : ListOptions -> Request.Request(Bytes.Bytes, Reply.Error)
	client_list = |options| {
		kind = match options.kind {
			Absent => []
			Present(value) => [Bytes.from_str("TYPE"), client_type(value)]
		}
		ids = if options.ids.is_empty() {
			[]
		} else {
			[Bytes.from_str("ID")].concat(options.ids.map(decimal))
		}
		Request.new(Command.new("CLIENT", ["LIST"].concat(kind).concat(ids)), bulk)
	}

	client_no_evict : Bool -> Request.Request({}, Reply.Error)
	client_no_evict = |enabled| Request.new(Command.new("CLIENT", ["NO-EVICT", on_off(enabled)]), Reply.okay)

	client_no_touch : Bool -> Request.Request({}, Reply.Error)
	client_no_touch = |enabled| Request.new(Command.new("CLIENT", ["NO-TOUCH", on_off(enabled)]), Reply.okay)

	client_pause : U64, [All, Write] -> Request.Request({}, Reply.Error)
	client_pause = |milliseconds, mode| Request.new(
		Command.new(
			"CLIENT",
			[
				"PAUSE",
				decimal(milliseconds),
				match mode {
					All => Bytes.from_str("ALL")
					Write => Bytes.from_str("WRITE")
				},
			],
		),
		Reply.okay,
	)

	client_unpause : () -> Request.Request({}, Reply.Error)
	client_unpause = || Request.new(Command.new("CLIENT", ["UNPAUSE"]), Reply.okay)

	client_unblock : U64, [Timeout, Error] -> Request.Request(Bool, Reply.Error)
	client_unblock = |id, mode| Request.new(
		Command.new(
			"CLIENT",
			[
				"UNBLOCK",
				decimal(id),
				match mode {
					Timeout => Bytes.from_str("TIMEOUT")
					Error => Bytes.from_str("ERROR")
				},
			],
		),
		Reply.integer_boolean,
	)

	client_set_info : [LibraryName(Bytes.Bytes), LibraryVersion(Bytes.Bytes)] -> Request.Request({}, Reply.Error)
	client_set_info = |attribute| Request.new(
		Command.new(
			"CLIENT",
			["SETINFO"].concat(
				match attribute {
					LibraryName(value) => [Bytes.from_str("LIB-NAME"), value]
					LibraryVersion(value) => [Bytes.from_str("LIB-VER"), value]
				},
			),
		),
		Reply.okay,
	)

	client_caching : Bool -> Request.Request({}, Reply.Error)
	client_caching = |enabled| Request.new(Command.new("CLIENT", ["CACHING", yes_no(enabled)]), Reply.okay)

	## Structured tracking metadata can evolve by Redis version. Preserve its
	## RESP2 alternating key/value array for caller-selected custom decoding.
	client_tracking_info : () -> Request.Request(List(Resp.Resp), Reply.Error)
	client_tracking_info = || Request.new(Command.new("CLIENT", ["TRACKINGINFO"]), Reply.array)

	## Encoding-only: these operations can change protocol/mode or close the
	## connection. They deliberately do not produce Request values. A platform
	## adapter implementing the appropriate lifecycle may use their wire bytes.
	quit : () -> Command.Command
	quit = || Command.new("QUIT", [])

	reset : () -> Command.Command
	reset = || Command.new("RESET", [])

	client_reply : [On, Off, Skip] -> Command.Command
	client_reply = |mode| Command.new(
		"CLIENT",
		[
			"REPLY",
			match mode {
				On => Bytes.from_str("ON")
				Off => Bytes.from_str("OFF")
				Skip => Bytes.from_str("SKIP")
			},
		],
	)

	hello : [Resp2, Resp3], HelloOptions -> Command.Command
	hello = |protocol, options| {
		version = match protocol {
			Resp2 => Bytes.from_str("2")
			Resp3 => Bytes.from_str("3")
		}
		authentication = match options.authentication {
			Absent => []
			Present(value) => [Bytes.from_str("AUTH"), value.username, value.password]
		}
		name = match options.name {
			Absent => []
			Present(value) => [Bytes.from_str("SETNAME"), value]
		}
		Command.new("HELLO", [version].concat(authentication).concat(name))
	}

	client_tracking : [Off, On(TrackingOptions)] -> Command.Command
	client_tracking = |mode| Command.new(
		"CLIENT",
		["TRACKING"].concat(
			match mode {
				Off => [Bytes.from_str("OFF")]
				On(options) => {
					redirect = match options.redirect {
						Absent => []
						Present(value) => [Bytes.from_str("REDIRECT"), decimal(value)]
					}
					tracking_mode = match options.mode {
						Default => []
						OptIn => [Bytes.from_str("OPTIN")]
						OptOut => [Bytes.from_str("OPTOUT")]
						Broadcast(prefixes) => [Bytes.from_str("BCAST")].concat(prefixes.join_map(|prefix| [Bytes.from_str("PREFIX"), prefix]))
					}
					loop_mode = if options.no_loop {
						[Bytes.from_str("NOLOOP")]
					} else {
						[]
					}
					[Bytes.from_str("ON")].concat(redirect).concat(tracking_mode).concat(loop_mode)
				}
			},
		),
	)

	## Encoding-only because filters may target the executing connection itself.
	client_kill : KillMode -> Command.Command
	client_kill = |mode| Command.new(
		"CLIENT",
		["KILL"].concat(
			match mode {
				Address(value) => [value]
				Filters(filters) => filters.to_list().join_map(
					|filter| match filter {
						Id(value) => [Bytes.from_str("ID"), decimal(value)]
						Kind(value) => [Bytes.from_str("TYPE"), client_type(value)]
						User(value) => [Bytes.from_str("USER"), value]
						Address(value) => [Bytes.from_str("ADDR"), value]
						LocalAddress(value) => [Bytes.from_str("LADDR"), value]
						SkipSelf(value) => [Bytes.from_str("SKIPME"), yes_no(value)]
						MaxAge(value) => [Bytes.from_str("MAXAGE"), decimal(value)]
					},
				)
			},
		),
	)
}

decimal : U64 -> Bytes.Bytes
decimal = |value| Bytes.from_str(value.to_str())

on_off : Bool -> Bytes.Bytes
on_off = |enabled| if enabled {
	"ON"
} else {
	"OFF"
}

yes_no : Bool -> Bytes.Bytes
yes_no = |enabled| if enabled {
	"YES"
} else {
	"NO"
}

client_type : Session.ClientType -> Bytes.Bytes
client_type = |kind| match kind {
	Normal => "NORMAL"
	Master => "MASTER"
	Slave => "SLAVE"
	Replica => "REPLICA"
	PubSub => "PUBSUB"
}

bulk : Resp.Resp -> Try(Bytes.Bytes, Reply.Error)
bulk = |reply| Reply.bulk(reply).map_ok(Bytes.from_list)

expect Session.auth(User({ username: "user", password: "secret" })).command() == Command.new("AUTH", ["user", "secret"])
expect Session.ping().decode(Resp.simple_utf8("PONG")) == Ok(Bytes.from_str("PONG"))
expect Session.echo(Bytes.from_list([0, 255])).decode(Resp.BulkString([0, 255])) == Ok(Bytes.from_list([0, 255]))
expect Session.client_get_name().decode(Resp.NullBulkString) == Ok(Absent)
expect Session.client_get_name().decode(Resp.NullArray).is_err()
expect Session.client_list(Session.ListOptions.{ kind: Present(Replica), ids: [42, 43] }).command() == Command.new("CLIENT", ["LIST", "TYPE", "REPLICA", "ID", "42", "43"])
expect Session.client_reply(Skip) == Command.new("CLIENT", ["REPLY", "SKIP"])
expect Session.client_tracking(On(Session.TrackingOptions.{ mode: Broadcast(["prefix"]), no_loop: True })) == Command.new("CLIENT", ["TRACKING", "ON", "BCAST", "PREFIX", "prefix", "NOLOOP"])
expect Session.hello(Resp2, Session.HelloOptions.{}) == Command.new("HELLO", ["2"])
