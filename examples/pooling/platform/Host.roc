Host :: [].{
	create! : U16, U64 => U64
	acquire! : U64, U64 => U64
	finish! : U64, Bool => Bool
	read! : U64, U64, U64 => { bytes : List(U8), code : U8 }
	write! : U64, List(U8), U64 => U8
	close! : U64 => Bool
}
