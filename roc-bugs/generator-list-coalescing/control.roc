## Frozen candidate from the generator readability pass.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.22.2/9zUBxb1LtXYVc4eR4hAtd1WQDwBYDhM6HQdZz1UFCm2m.tar.zst",
}
import pf.Stdout

main! = |args| {
	var $index = 0.U64
	while $index < 10000 + args.len() {
		actual = concat_expressions(["[key]", "[value]", "options", "[count]", "[other]"])
		if actual != "[key, value].concat(options).concat([count, other])" {
			crash "wrong concatenation"
		}
		$index = $index + 1
	}
	Stdout.line!("passed")?
	Ok({})
}

concat_expressions : List(Str) -> Str
concat_expressions = |expressions| {
	# Keep the pending segment separate from the completed list. Reading last()
	# and replacing that same list triggers pinned-compiler heap corruption;
	# see roc-bugs/generator-list-coalescing.
	var $completed = []
	var $pending = ""
	for expression in expressions {
		if $pending.is_empty() {
			$pending = expression
		} else {
			match (simple_list_elements($pending), simple_list_elements(expression)) {
				(Ok(left), Ok(right)) => {
					separator = if left.is_empty() or right.is_empty() "" else ", "
					$pending = "[${left}${separator}${right}]"
				}
				_ => {
					$completed = $completed.append($pending)
					$pending = expression
				}
			}
		}
	}
	segments = if $pending.is_empty() $completed else $completed.append($pending)
	match segments {
		[] => "[]"
		[first, .. as rest] => rest.fold(first, |result, expression| "${result}.concat(${expression})")
	}
}

## Only combine lists of bare generated variable names. This is not a Roc
## expression parser: tokens, nested lists, calls, and arbitrary grammar
## expressions keep their original rendering and evaluation order.
simple_list_elements : Str -> Try(Str, [NotSimpleList])
simple_list_elements = |expression| {
	if !expression.starts_with("[") or !expression.ends_with("]") {
		return Err(NotSimpleList)
	}
	inner = expression.drop_prefix("[").drop_suffix("]")
	if inner.is_empty() {
		return Ok("")
	}
	for name in inner.split_on(", ") {
		bytes = name.to_utf8()
		first = bytes.first() ?? 0
		if !((first >= 'a' and first <= 'z') or first == '_') {
			return Err(NotSimpleList)
		}
		if !bytes.all(|byte| (byte >= 'a' and byte <= 'z') or (byte >= '0' and byte <= '9') or byte == '_') {
			return Err(NotSimpleList)
		}
	}
	Ok(inner)
}

expect concat_expressions(["[key]", "[value]"]) == "[key, value]"
expect concat_expressions(["[key]", "options", "[value]", "[count]"]) == "[key].concat(options).concat([value, count])"
expect concat_expressions(["[]", "[key]"]) == "[key]"
expect concat_expressions(["[key]", "[value].map(f)"]) == "[key].concat([value].map(f))"
expect simple_list_elements("[['X']]").is_err()
expect simple_list_elements("[key].concat([value])").is_err()
