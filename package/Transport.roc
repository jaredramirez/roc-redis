import Execute

## Constructors for the two-effect byte transport that execution drives. The
## transport type itself is `Execute.Transport`; these helpers save every
## platform integration from re-deriving the same read/write wiring by hand.
##
## The transport is the only thing a platform must supply: exclusive, ordered
## `read!` and `write_all!` over one connection. Connection creation, TLS,
## deadlines, retries, and pooling remain the platform's concern.
Transport :: [].{

	## Wrap `read!`/`write_all!` that already speak the `Data`/`End` read
	## protocol. Use this when the platform distinguishes a genuine end of stream
	## from a short read itself.
	new : { read! : U64 => Try(Execute.Read, read_err), write_all! : List(U8) => Try({}, write_err) } -> Execute.Transport(read_err, write_err)
	new = |transport| transport

	## Adapt a raw byte reader (returns the bytes read, empty on EOF) plus a
	## writer into a transport, folding the empty-bytes-is-`End` convention that
	## every integration otherwise repeats by hand. This convention is only
	## correct where the platform returns `Err` on timeout/would-block and
	## reserves `[]` for a genuine end of stream; otherwise use `new` with an
	## explicit `Data`/`End` mapping.
	from_bytes_io : { read_bytes! : U64 => Try(List(U8), read_err), write_all! : List(U8) => Try({}, write_err) } -> Execute.Transport(read_err, write_err)
	from_bytes_io = |io| {
		{ read_bytes!, write_all! } = io
		{
			read!: |max_bytes| read_bytes!(max_bytes).map_ok(|bytes| if bytes.is_empty() End else Data(bytes)),
			write_all!: write_all!,
		}
	}
}
