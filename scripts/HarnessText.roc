## Pure harness text helpers. These do not establish process ownership or
## authorize signaling; the service-specific harness must still do both.
HarnessText :: [].{
	combine_output : Str, Str -> Str
	combine_output = |stdout, stderr|
		if stdout.is_empty() {
			stderr
		} else if stderr.is_empty() {
			stdout
		} else {
			"${stdout}\n${stderr}"
		}

	first_line : Str -> Str
	first_line = |text|
		match text.split_on("\n") {
			[line, ..] => line
			[] => ""
		}

	valid_pid : Str -> Bool
	valid_pid = |pid| {
		bytes = pid.to_utf8()
		if bytes.is_empty() or !(bytes.all(|byte| byte >= '0' and byte <= '9')) {
			Bool.False
		} else {
			match U64.from_str(pid) {
				Ok(number) => number > 1
				Err(_) => Bool.False
			}
		}
	}

	parse_pid_text : Str -> Try(Str, Str)
	parse_pid_text = |text| {
		pid = HarnessText.first_line(text)
		remaining = text.split_on("\n").drop_first(1)
		if HarnessText.valid_pid(pid) and remaining.all(|line| line.is_empty()) {
			Ok(pid)
		} else {
			Err("expected one positive process ID, received ${Str.inspect(text)}")
		}
	}

	redis_info_field : Str, Str -> Try(Str, [NotFound])
	redis_info_field = |info, field| {
		prefix = "${field}:"
		match info.split_on("\n").find_first(|line| line.trim().starts_with(prefix)) {
			Ok(line) => Ok(line.trim().drop_prefix(prefix).trim())
			Err(_) => Err(NotFound)
		}
	}

}

expect HarnessText.parse_pid_text("42\n") == Ok("42")
expect HarnessText.parse_pid_text("1\n").is_err()
expect HarnessText.parse_pid_text("42\n43\n").is_err()
expect HarnessText.parse_pid_text("18446744073709551616").is_err()
expect HarnessText.combine_output("a\n", "b") == "a\n\nb"
expect HarnessText.redis_info_field("process_id:42\r\n", "process_id") == Ok("42")
