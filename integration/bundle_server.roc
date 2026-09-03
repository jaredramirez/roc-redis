## Minimal loopback-only server used to verify a generated roc-redis bundle.
##
## The archive is exposed through basic-webserver's host-native exact-file
## route. That route streams only the startup-authorized regular file, rejects
## traversal and symlinks, never lists the containing directory, and applies a
## no-store cache policy. The Roc handler owns only a nonce-bearing health URL.
app [Context, program] {
	pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.16.0/42jC1JT3auhHSmv2Ah8mW5F2MXiAakq1UQQ4NQceQjXw.tar.zst",
	http: "https://github.com/roc-lang/http/releases/download/2.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst",
}

import pf.Env
import pf.OsStr exposing [OsStr]
import pf.Path
import pf.Server
import http.Method
import http.Response

Context : {
	health_body : List(U8),
	health_target : Str,
}

program = { init!, respond!, shutdown! }

init! : () => Try(
	{ config : Server.Config, context : Context },
	[ConfigError(Str), Exit(I64), ..],
)
init! = || {
	port = read_port!("ROC_BUNDLE_HTTP_PORT")?
	bundle_dir = read_path!("ROC_BUNDLE_HTTP_DIR")?
	archive_name = read_text!("ROC_BUNDLE_HTTP_ARCHIVE_NAME")?
	health_target = read_text!("ROC_BUNDLE_HTTP_HEALTH_TARGET")?
	health_body = read_text!("ROC_BUNDLE_HTTP_HEALTH_BODY")?.to_utf8()

	if !(valid_archive_name(archive_name)) {
		return Err(ConfigError("ROC_BUNDLE_HTTP_ARCHIVE_NAME must be one safe .tar.zst filename"))
	}
	if !(valid_health_target(health_target)) {
		return Err(ConfigError("ROC_BUNDLE_HTTP_HEALTH_TARGET must be /roc-redis-bundle-health- followed by decimal digits"))
	}
	if health_body.is_empty() or health_body.len() > 1024 {
		return Err(ConfigError("ROC_BUNDLE_HTTP_HEALTH_BODY must contain 1 through 1024 UTF-8 bytes"))
	}

	bundle_dir_is_directory = bundle_dir.is_dir!()
		? |error| ConfigError("inspect ROC_BUNDLE_HTTP_DIR: ${Str.inspect(error)}")
	if !bundle_dir_is_directory {
		return Err(ConfigError("ROC_BUNDLE_HTTP_DIR must name a directory"))
	}

	archive_path = bundle_dir.join(archive_name)
	archive_is_file = archive_path.is_file!()
		? |error| ConfigError("inspect bundle archive: ${Str.inspect(error)}")
	if !archive_is_file {
		return Err(ConfigError("ROC_BUNDLE_HTTP_ARCHIVE_NAME must name a regular file in ROC_BUNDLE_HTTP_DIR"))
	}

	relative_archive = Server.relative_file(archive_name)
		? |_| ConfigError("ROC_BUNDLE_HTTP_ARCHIVE_NAME is not a safe relative file")
	archive_target = "/${archive_name}"
	files = Server.file_root_with_cache({ id: "roc-redis-bundle", path: bundle_dir, cache: Server.no_store })
	file_route = Server.static_file({ at: archive_target, files, relative: relative_archive })

	config =
		Server.default_config
			.with_listen({ host: "127.0.0.1", port })
			.with_file_roots([files])
			.with_native_routes({ files: [file_route], liveness: [], readiness: [] })

	Ok({ config, context: { health_body, health_target } })
}

respond! : Server.Request, Context => Try(Server.Outcome, [ServerErr(Str), ..])
respond! = |request, context| {
	is_health =
		match request.target() {
			Resource({ raw_path, raw_query: Absent }) => raw_path == context.health_target
			_ => Bool.False
		}

	response =
		if is_health and Method.is_eq(request.method(), GET) {
			response_with(200, "text/plain; charset=utf-8", context.health_body, [])
		} else if is_health {
			response_with(405, "text/plain; charset=utf-8", "Method Not Allowed".to_utf8(), [{ name: "Allow", value: "GET" }])
		} else {
			response_with(404, "text/plain; charset=utf-8", "Not Found".to_utf8(), [])
		}

	Ok(Server.respond(response))
}

response_with : U16, Str, List(U8), List({ name : Str, value : Str }) -> Response.Response
response_with = |status, content_type, body, extra_headers|
	Response.from_status(status)
		.with_headers(
			[
				{ name: "Content-Type", value: content_type },
				{ name: "Cache-Control", value: "no-store" },
			].concat(extra_headers),
		)
		.with_body(body)

shutdown! : Server.ShutdownReason, Context => Try({}, [Exit(I64), ..])
shutdown! = |_reason, _context| Ok({})

read_text! : Str => Try(Str, [ConfigError(Str), ..])
read_text! = |name|
	Env.var_str!(OsStr.from_str(name))
		.map_err(|error| ConfigError("${name}: ${Str.inspect(error)}"))

read_path! : Str => Try(Path.Path, [ConfigError(Str), ..])
read_path! = |name|
	Env.var!(OsStr.from_str(name))
		.map_ok(Path.from_os_str)
		.map_err(|error| ConfigError("${name}: ${Str.inspect(error)}"))

read_port! : Str => Try(U16, [ConfigError(Str), ..])
read_port! = |name| {
	text = read_text!(name)?
	parse_port(text).map_err(|message| ConfigError("${name} ${message}"))
}

parse_port : Str -> Try(U16, Str)
parse_port = |text| {
	invalid = "must be a decimal integer from 1 through 65535"
	bytes = text.to_utf8()
	if bytes.is_empty() or bytes.len() > 5 or !(bytes.all(is_ascii_digit)) {
		Err(invalid)
	} else {
		port = U16.from_str(text) ? |_| invalid
		if port == 0 Err(invalid) else Ok(port)
	}
}

valid_archive_name : Str -> Bool
valid_archive_name = |name| {
	bytes = name.to_utf8()
	!bytes.is_empty()
		and bytes.len() <= 255
			and name.ends_with(".tar.zst")
				and match bytes {
					['.', ..] => Bool.False
					_ => bytes.all(is_safe_filename_byte)
				}
}

is_safe_filename_byte : U8 -> Bool
is_safe_filename_byte = |byte|
	is_ascii_alphanumeric(byte) or byte == '-' or byte == '_' or byte == '.'

is_ascii_alphanumeric : U8 -> Bool
is_ascii_alphanumeric = |byte|
	is_ascii_digit(byte)
		or (byte >= 'a' and byte <= 'z')
			or (byte >= 'A' and byte <= 'Z')

is_ascii_digit : U8 -> Bool
is_ascii_digit = |byte| byte >= '0' and byte <= '9'

valid_health_target : Str -> Bool
valid_health_target = |target| {
	prefix = "/roc-redis-bundle-health-"
	if target.starts_with(prefix) {
		bytes = target.to_utf8().drop_first(prefix.to_utf8().len())
		!bytes.is_empty() and bytes.len() <= 20 and bytes.all(is_ascii_digit)
	} else {
		Bool.False
	}
}

expect parse_port("1") == Ok(1)

expect parse_port("65535") == Ok(65535)

expect ["", "0", "+1", "1_0", "65536"].all(|text| parse_port(text).is_err())

expect valid_archive_name("2QLfQfRCchjHJgeAtpZYbdbYKSBzcF6a1wz2VEPwz8iz.tar.zst")

expect ["", ".hidden.tar.zst", "../escape.tar.zst", "nested/file.tar.zst", "bundle.tar"].all(|name| !valid_archive_name(name))

expect valid_health_target("/roc-redis-bundle-health-18446744073709551615")

expect ["/roc-redis-bundle-health-", "/roc-redis-bundle-health-a", "/other-1", "/roc-redis-bundle-health-184467440737095516150"].all(|target| !valid_health_target(target))
