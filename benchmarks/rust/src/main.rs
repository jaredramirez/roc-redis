use redis::{Connection, IntoConnectionInfo};
use serde_json::json;
use std::collections::BTreeMap;
use std::error::Error;
use std::io::Write;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

type Result<T> = std::result::Result<T, Box<dyn Error>>;
const CLIENT_VERSION: &str = "1.6.0";
const TTL: u64 = 86_400_001;
const PAYLOAD: &[u8] = &[
    0, 13, 10, 255, 128, 82, 111, 99, 45, 82, 101, 100, 105, 115, 0, 1, 2, 3, 10, 13, 127, 128,
    254, 255, 65, 66, 67, 120, 121, 122, 0, 255,
];

#[derive(Debug)]
struct Config {
    text: BTreeMap<String, String>,
    port: u16,
    iterations: u64,
    warmup: u64,
    samples: u64,
    batch: u64,
    timeout: Duration,
    rotation: u64,
    position: u64,
}

fn safe(text: &str, extra: &[u8], max: usize) -> bool {
    !text.is_empty()
        && text.len() <= max
        && text
            .bytes()
            .all(|b| b.is_ascii_alphanumeric() || extra.contains(&b))
}

fn number(text: &str, min: u64, max: u64) -> Result<u64> {
    if text.is_empty() || !text.bytes().all(|b| b.is_ascii_digit()) {
        return Err("expected an unsigned decimal integer".into());
    }
    let value = text.parse::<u64>()?;
    if !(min..=max).contains(&value) {
        return Err("numeric argument out of range".into());
    }
    Ok(value)
}

impl Config {
    fn parse(args: impl IntoIterator<Item = String>) -> Result<Self> {
        let mut text: BTreeMap<String, String> = [
            ("host", "127.0.0.1"),
            ("port", "6379"),
            ("iterations", "10000"),
            ("warmup", "1000"),
            ("samples", "5"),
            ("pipeline-batch", "100"),
            ("timeout-ms", "5000"),
            ("key-prefix", ""),
            ("nix-source-id", "unmanaged"),
            ("build-mode", "unmanaged"),
            ("nix-system", "unmanaged"),
            ("os", "unmanaged"),
            ("arch", "unmanaged"),
            ("order-rotation", "0"),
            ("subject-position", "0"),
        ]
        .into_iter()
        .map(|(k, v)| (k.to_owned(), v.to_owned()))
        .collect();
        let mut args = args.into_iter();
        while let Some(arg) = args.next() {
            let key = arg.strip_prefix("--").ok_or("expected --option value")?;
            if !text.contains_key(key) {
                return Err(format!("unknown option {arg}").into());
            }
            text.insert(key.to_owned(), args.next().ok_or("missing option value")?);
        }
        if text["host"].is_empty()
            || text["host"].len() > 253
            || !text["host"].bytes().all(|b| (33..=126).contains(&b))
        {
            return Err("invalid host".into());
        }
        if text["key-prefix"].is_empty() {
            text.insert(
                "key-prefix".into(),
                format!(
                    "roc-redis-bench:rust:{}:{}",
                    std::process::id(),
                    SystemTime::now().duration_since(UNIX_EPOCH)?.as_nanos()
                ),
            );
        }
        if !safe(&text["key-prefix"], b"._:-", 128) {
            return Err("invalid key prefix".into());
        }
        for key in ["nix-source-id", "build-mode", "nix-system", "os", "arch"] {
            if !safe(&text[key], b"+._:-", 128) {
                return Err(format!("invalid {key}").into());
            }
        }
        Ok(Self {
            port: number(&text["port"], 1, 65535)? as u16,
            iterations: number(&text["iterations"], 1, 1_000_000_000)?,
            warmup: number(&text["warmup"], 0, 1_000_000_000)?,
            samples: number(&text["samples"], 1, 1000)?,
            batch: number(&text["pipeline-batch"], 1, 65536)?,
            timeout: Duration::from_millis(number(&text["timeout-ms"], 1, 300_000)?),
            rotation: number(&text["order-rotation"], 0, 9)?,
            position: number(&text["subject-position"], 0, 5)?,
            text,
        })
    }

    fn connect(&self) -> Result<Connection> {
        // The tuple creates a TCP address directly, avoiding URL interpretation
        // of host bytes. The explicit protocol query is unnecessary: this
        // connection info's default is RESP2. The pre-timing handshake in run
        // explicitly requests RESP2 and verifies an array reply.
        let info = (self.text["host"].as_str(), self.port).into_connection_info()?;
        let client = redis::Client::open(info)?;
        let connection = client.get_connection_with_timeout(self.timeout)?;
        connection.set_read_timeout(Some(self.timeout))?;
        connection.set_write_timeout(Some(self.timeout))?;
        Ok(connection)
    }
}

fn set(connection: &mut Connection, key: &str, value: &[u8], nx: bool) -> Result<bool> {
    let mut cmd = redis::cmd("SET");
    cmd.arg(key).arg(value).arg("PX").arg(TTL);
    if nx {
        cmd.arg("NX");
    }
    let result: Option<String> = cmd.query(connection)?;
    match result.as_deref() {
        Some("OK") => Ok(true),
        None if nx => Ok(false),
        _ => Err("invalid SET reply".into()),
    }
}

fn workload(
    connection: &mut Connection,
    name: &str,
    count: u64,
    batch: u64,
    set_key: &str,
    incr_key: &str,
    mset_keys: &[String],
    hash_key: &str,
    sg_pipe_key: &str,
) -> Result<()> {
    match name {
        "ping_sequential" => {
            for _ in 0..count {
                let value: String = redis::cmd("PING").query(connection)?;
                if value != "PONG" {
                    return Err("PING mismatch".into());
                }
            }
        }
        "set_get_sequential" => {
            for _ in 0..count {
                set(connection, set_key, PAYLOAD, false)?;
                let value: Vec<u8> = redis::cmd("GET").arg(set_key).query(connection)?;
                if value != PAYLOAD {
                    return Err("binary GET mismatch".into());
                }
            }
        }
        "incr_sequential" => {
            for expected in 1..=count {
                let value: i64 = redis::cmd("INCR").arg(incr_key).query(connection)?;
                if value != expected as i64 {
                    return Err("INCR mismatch".into());
                }
            }
        }
        "ping_pipeline" => {
            let mut completed = 0;
            while completed < count {
                let current = batch.min(count - completed);
                let mut pipeline = redis::pipe();
                for _ in 0..current {
                    pipeline.cmd("PING");
                }
                let values: Vec<String> = pipeline.query(connection)?;
                if values.len() != current as usize || values.iter().any(|v| v != "PONG") {
                    return Err("pipeline count or value mismatch".into());
                }
                completed += current;
            }
        }
        "mset_mget_sequential" => {
            for _ in 0..count {
                let mut mset = redis::cmd("MSET");
                for key in mset_keys {
                    mset.arg(key).arg(PAYLOAD);
                }
                let stored: String = mset.query(connection)?;
                if stored != "OK" {
                    return Err("MSET reply mismatch".into());
                }
                let mut mget = redis::cmd("MGET");
                for key in mset_keys {
                    mget.arg(key);
                }
                let values: Vec<Vec<u8>> = mget.query(connection)?;
                if values.len() != mset_keys.len() || values.iter().any(|v| v != PAYLOAD) {
                    return Err("MGET mismatch".into());
                }
            }
        }
        "hash_roundtrip_sequential" => {
            for _ in 0..count {
                let written: i64 = redis::cmd("HSET")
                    .arg(hash_key)
                    .arg("field:0")
                    .arg(PAYLOAD)
                    .arg("field:1")
                    .arg(PAYLOAD)
                    .arg("field:2")
                    .arg(PAYLOAD)
                    .query(connection)?;
                if written < 0 {
                    return Err("HSET reply mismatch".into());
                }
                let fields: BTreeMap<String, Vec<u8>> =
                    redis::cmd("HGETALL").arg(hash_key).query(connection)?;
                for field in ["field:0", "field:1", "field:2"] {
                    match fields.get(field) {
                        Some(value) if value.as_slice() == PAYLOAD => {}
                        _ => return Err("HGETALL mismatch".into()),
                    }
                }
            }
        }
        "set_get_pipeline" => {
            let mut completed = 0;
            while completed < count {
                let current = batch.min(count - completed);
                let mut pipeline = redis::pipe();
                for _ in 0..current {
                    pipeline
                        .cmd("SET")
                        .arg(sg_pipe_key)
                        .arg(PAYLOAD)
                        .arg("PX")
                        .arg(TTL)
                        .cmd("GET")
                        .arg(sg_pipe_key);
                }
                let values: Vec<(String, Vec<u8>)> = pipeline.query(connection)?;
                if values.len() != current as usize
                    || values.iter().any(|(ok, value)| ok != "OK" || value != PAYLOAD)
                {
                    return Err("pipeline SET/GET mismatch".into());
                }
                completed += current;
            }
        }
        _ => return Err("unknown workload".into()),
    }
    Ok(())
}

fn run(
    config: &Config,
    connection: &mut Connection,
    version: &str,
    set_key: &str,
    incr_key: &str,
    mset_keys: &[String],
    hash_key: &str,
    sg_pipe_key: &str,
) -> Result<()> {
    // One synchronous connection, including pipelines. Prove the identity
    // outside timing; do not use a pool, transaction, or automatic retry loop.
    let direct: i64 = redis::cmd("CLIENT").arg("ID").query(connection)?;
    let pipelined: Vec<i64> = redis::pipe().cmd("CLIENT").arg("ID").query(connection)?;
    if pipelined != [direct] {
        return Err("pipeline changed connection".into());
    }
    let hello: redis::Value = redis::cmd("HELLO").arg(2).query(connection)?;
    if !matches!(hello, redis::Value::Array(_)) {
        return Err("RESP2 handshake failed".into());
    }
    for name in [
        "ping_sequential",
        "set_get_sequential",
        "incr_sequential",
        "ping_pipeline",
        "mset_mget_sequential",
        "hash_roundtrip_sequential",
        "set_get_pipeline",
    ] {
        for sample in 1..=config.samples {
            if name == "incr_sequential" {
                set(connection, incr_key, b"0", false)?;
            }
            workload(
                connection,
                name,
                config.warmup,
                config.batch,
                set_key,
                incr_key,
                mset_keys,
                hash_key,
                sg_pipe_key,
            )?;
            if name == "incr_sequential" {
                set(connection, incr_key, b"0", false)?;
            }
            let start = Instant::now();
            workload(
                connection,
                name,
                config.iterations,
                config.batch,
                set_key,
                incr_key,
                mset_keys,
                hash_key,
                sg_pipe_key,
            )?;
            let elapsed: u64 = start.elapsed().as_nanos().try_into()?;
            let commands = config.iterations
                * match name {
                    "set_get_sequential"
                    | "mset_mget_sequential"
                    | "hash_roundtrip_sequential"
                    | "set_get_pipeline" => 2,
                    _ => 1,
                };
            let trips = if name == "ping_pipeline" || name == "set_get_pipeline" {
                config.iterations.div_ceil(config.batch)
            } else {
                commands
            };
            let result = json!({
                "schema": "roc-redis-benchmark/v2", "implementation": "rust", "client": "redis-rs",
                "client_version": CLIENT_VERSION, "runtime_version": option_env!("ROC_REDIS_RUST_VERSION").unwrap_or("unmanaged"),
                "redis_version": version, "timer": "monotonic", "workload": name,
                "sample": sample, "samples": config.samples, "iterations": config.iterations,
                "warmup": config.warmup, "pipeline_batch": config.batch, "operation_count": config.iterations,
                "command_count": commands, "round_trip_count": trips, "elapsed_ns": elapsed, "validated": true,
                "nix_source_id": config.text["nix-source-id"], "build_mode": config.text["build-mode"],
                "nix_system": config.text["nix-system"], "os": config.text["os"], "arch": config.text["arch"],
                "order_rotation": config.rotation, "subject_position": config.position,
            });
            writeln!(std::io::stdout().lock(), "{result}")?;
        }
    }
    Ok(())
}

fn main_result() -> Result<()> {
    let config = Config::parse(std::env::args().skip(1))?;
    let mut connection = config.connect()?;
    let info: String = redis::cmd("INFO").arg("server").query(&mut connection)?;
    let version = info
        .lines()
        .find_map(|line| line.strip_prefix("redis_version:"))
        .ok_or("missing Redis version")?
        .trim();
    if !safe(version, b"+._-", 128) {
        return Err("invalid Redis version".into());
    }
    let prefix = &config.text["key-prefix"];
    let lease = format!("{prefix}:lease");
    let set_key = format!("{prefix}:set-get");
    let incr_key = format!("{prefix}:incr");
    let mset_keys = [
        format!("{prefix}:mset:0"),
        format!("{prefix}:mset:1"),
        format!("{prefix}:mset:2"),
        format!("{prefix}:mset:3"),
    ];
    let hash_key = format!("{prefix}:hash");
    let sg_pipe_key = format!("{prefix}:sg-pipe");
    if !set(&mut connection, &lease, b"benchmark-lease", true)? {
        return Err("key-prefix lease already exists; no benchmark keys changed".into());
    }
    let outcome = run(
        &config,
        &mut connection,
        version,
        &set_key,
        &incr_key,
        &mset_keys,
        &hash_key,
        &sg_pipe_key,
    );
    drop(connection);
    // A failed connection may have partially transmitted work. Cleanup uses a
    // fresh connection and only the keys protected by this acquired lease.
    let cleanup = (|| -> Result<()> {
        let mut cleanup_connection = config.connect()?;
        let deleted: i64 = redis::cmd("DEL")
            .arg(&[set_key, incr_key, lease, hash_key, sg_pipe_key])
            .arg(&mset_keys)
            .query(&mut cleanup_connection)?;
        if !(0..=9).contains(&deleted) {
            return Err("invalid cleanup DEL result".into());
        }
        Ok(())
    })();
    match (outcome, cleanup) {
        (Err(primary), Err(cleanup)) => {
            Err(format!("{primary}; cleanup also failed: {cleanup}").into())
        }
        (Err(primary), _) => Err(primary),
        (Ok(()), result) => result,
    }
}

fn main() {
    if let Err(error) = main_result() {
        eprintln!("benchmark failed: {error}");
        std::process::exit(1);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn strict_numbers() {
        for invalid in ["", "-1", "+1", "1_0", "0x10", "18446744073709551616"] {
            assert!(number(invalid, 0, u64::MAX).is_err());
        }
        assert_eq!(number("0", 0, 1).unwrap(), 0);
        assert!(number("2", 0, 1).is_err());
    }
    #[test]
    fn validates_before_connecting() {
        for args in [
            vec!["--unknown", "1"],
            vec!["--samples", "0"],
            vec!["--key-prefix", "unsafe/key"],
            vec!["--port"],
        ] {
            assert!(Config::parse(args.into_iter().map(String::from)).is_err());
        }
        let config = Config::parse(
            [
                "--warmup",
                "0",
                "--order-rotation",
                "9",
                "--subject-position",
                "5",
            ]
            .map(String::from),
        )
        .unwrap();
        assert_eq!(config.warmup, 0);
        assert_eq!(config.position, 5);
    }
}
