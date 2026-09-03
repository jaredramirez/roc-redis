import Resp

## A reply decoder.
##
## This deliberately uses the invalid reference [Resp.Resp].
Reply := [].{
	raw : Resp.Resp -> Resp.Resp
	raw = |value| value
}
