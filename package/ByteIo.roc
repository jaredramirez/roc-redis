import Execute

## Constructors for the two-effect byte stream that execution drives. The type
## itself is `Execute.ByteIo`; these helpers save every platform integration
## from re-deriving the same read/write wiring by hand.
##
## A `ByteIo` is an already-open, exclusive, ordered duplex byte stream, and it
## is the only thing a platform must supply. It owns no lifecycle: connection
## creation, TLS, deadlines, retries, and pooling remain the platform's concern.
ByteIo :: [].{

	## Wrap `read!`/`write_all!` that already speak the `Data`/`End` read
	## protocol. Use this when the platform distinguishes a genuine end of stream
	## from a short read itself.
	new : { read! : U64 => Try(Execute.Read, read_err), write_all! : List(U8) => Try({}, write_err) } -> Execute.ByteIo(read_err, write_err)
	new = |byte_io| byte_io

	## Adapt a raw byte reader whose empty result means end of stream, folding a
	## convention that every integration otherwise repeats by hand. The name
	## states the requirement: this is correct only where the platform returns
	## `Err` on timeout/would-block and reserves `[]` for a genuine end of
	## stream. Otherwise use `new` with an explicit `Data`/`End` mapping.
	from_empty_eof : { read_bytes! : U64 => Try(List(U8), read_err), write_all! : List(U8) => Try({}, write_err) } -> Execute.ByteIo(read_err, write_err)
	from_empty_eof = |io| {
		{ read_bytes!, write_all! } = io
		{
			read!: |max_bytes| read_bytes!(max_bytes).map_ok(|bytes| if bytes.is_empty() End else Data(bytes)),
			write_all!: write_all!,
		}
	}
}
