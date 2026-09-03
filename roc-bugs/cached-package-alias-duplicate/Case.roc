import first.Method as First
import second.Method as Second

Case := {}.{
	same = First.is_eq(GET, GET) and Second.is_eq(GET, GET)
}

expect Case.same
