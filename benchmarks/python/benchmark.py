"""Validated redis-py subject for the roc-redis cross-client benchmark."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from collections.abc import Callable
from dataclasses import dataclass, replace
from typing import Final

import redis
from redis.backoff import NoBackoff
from redis.retry import Retry

SCHEMA: Final = "roc-redis-benchmark/v2"
IMPLEMENTATION: Final = "python"
MAX_ITERATIONS: Final = 1_000_000_000
MAX_SAMPLES: Final = 1_000
MAX_PIPELINE_BATCH: Final = 65_536
MAX_TIMEOUT_MS: Final = 300_000
KEY_TTL_MS: Final = 86_400_001
SAFE_HOST: Final = re.compile(r"^[!-~]{1,253}$")
SAFE_PREFIX: Final = re.compile(r"^[A-Za-z0-9._:-]{1,128}$")
SAFE_VERSION: Final = re.compile(r"^[A-Za-z0-9+._-]{1,128}$")
SAFE_METADATA: Final = re.compile(r"^[A-Za-z0-9+._:-]{1,128}$")
BINARY_PAYLOAD: Final = bytes.fromhex(
    "000d0aff80526f632d5265646973000102030a0d7f80feff41424378797a00ff"
)


@dataclass(frozen=True)
class Config:
    host: str
    port: int
    iterations: int
    warmup: int
    samples: int
    pipeline_batch: int
    timeout_ms: int
    key_prefix: str
    redis_version: str
    nix_source_id: str
    build_mode: str
    nix_system: str
    os: str
    arch: str
    order_rotation: int
    subject_position: int


class BenchmarkError(RuntimeError):
    """A connection, command, or validation failure."""


def bounded_int(name: str, minimum: int, maximum: int) -> Callable[[str], int]:
    def parse(text: str) -> int:
        if not text or not text.isascii() or not text.isdecimal():
            raise argparse.ArgumentTypeError(f"{name} must be a decimal integer")
        value = int(text, 10)
        if not minimum <= value <= maximum:
            raise argparse.ArgumentTypeError(
                f"{name} must be from {minimum} through {maximum}"
            )
        return value

    return parse


def safe_host(text: str) -> str:
    if SAFE_HOST.fullmatch(text) is None:
        raise argparse.ArgumentTypeError(
            "host must contain 1 through 253 printable non-space ASCII characters"
        )
    return text


def safe_prefix(text: str) -> str:
    if SAFE_PREFIX.fullmatch(text) is None:
        raise argparse.ArgumentTypeError(
            "key-prefix must contain 1 through 128 ASCII letters, digits, '.', '_', ':', or '-'"
        )
    return text


def safe_metadata(text: str) -> str:
    if SAFE_METADATA.fullmatch(text) is None:
        raise argparse.ArgumentTypeError(
            "benchmark metadata must contain 1 through 128 safe ASCII characters"
        )
    return text


def parse_args(argv: list[str]) -> Config:
    parser = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    parser.add_argument("--host", type=safe_host, default="127.0.0.1")
    parser.add_argument("--port", type=bounded_int("port", 1, 65_535), default=6_379)
    parser.add_argument(
        "--iterations",
        type=bounded_int("iterations", 1, MAX_ITERATIONS),
        default=10_000,
    )
    parser.add_argument(
        "--warmup", type=bounded_int("warmup", 0, MAX_ITERATIONS), default=1_000
    )
    parser.add_argument(
        "--samples", type=bounded_int("samples", 1, MAX_SAMPLES), default=5
    )
    parser.add_argument(
        "--pipeline-batch",
        type=bounded_int("pipeline-batch", 1, MAX_PIPELINE_BATCH),
        default=100,
    )
    parser.add_argument(
        "--timeout-ms",
        type=bounded_int("timeout-ms", 1, MAX_TIMEOUT_MS),
        default=5_000,
    )
    parser.add_argument("--key-prefix", type=safe_prefix)
    parser.add_argument("--nix-source-id", type=safe_metadata, default="unmanaged")
    parser.add_argument("--build-mode", type=safe_metadata, default="unmanaged")
    parser.add_argument("--nix-system", type=safe_metadata, default="unmanaged")
    parser.add_argument("--os", type=safe_metadata, default="unmanaged")
    parser.add_argument("--arch", type=safe_metadata, default="unmanaged")
    parser.add_argument(
        "--order-rotation", type=bounded_int("order-rotation", 0, 9), default=0
    )
    parser.add_argument(
        "--subject-position", type=bounded_int("subject-position", 0, 5), default=0
    )
    values = parser.parse_args(argv)
    prefix = values.key_prefix
    if prefix is None:
        prefix = f"roc-redis-bench:python:{os.getpid()}:{time.time_ns()}"
    return Config(
        host=values.host,
        port=values.port,
        iterations=values.iterations,
        warmup=values.warmup,
        samples=values.samples,
        pipeline_batch=values.pipeline_batch,
        timeout_ms=values.timeout_ms,
        key_prefix=prefix,
        redis_version="",
        nix_source_id=values.nix_source_id,
        build_mode=values.build_mode,
        nix_system=values.nix_system,
        os=values.os,
        arch=values.arch,
        order_rotation=values.order_rotation,
        subject_position=values.subject_position,
    )


def new_client(config: Config) -> redis.Redis:
    timeout_seconds = config.timeout_ms / 1_000
    return redis.Redis(
        host=config.host,
        port=config.port,
        protocol=2,
        decode_responses=False,
        socket_connect_timeout=timeout_seconds,
        socket_timeout=timeout_seconds,
        health_check_interval=0,
        retry=Retry(NoBackoff(), 0),
        retry_on_error=[],
        # Regular commands and Pipeline both borrow from this one-entry pool.
        # The INFO probe opens the socket before any measured workload, and the
        # pool keeps that same socket available for both execution paths.
        max_connections=1,
    )


def verify_shared_connection(client: redis.Redis) -> None:
    """Prove direct commands and Pipeline use the same already-open socket."""
    direct_id = client.client_id()
    with client.pipeline(transaction=False) as pipeline:
        pipeline.client_id()
        replies = pipeline.execute(raise_on_error=True)
    require(
        replies == [direct_id],
        "redis-py direct and pipeline commands did not share one TCP connection",
    )


def require(condition: bool, message: str) -> None:
    if not condition:
        raise BenchmarkError(message)


def read_redis_version(client: redis.Redis) -> str:
    value = client.info(section="server").get("redis_version")
    if not isinstance(value, str) or SAFE_VERSION.fullmatch(value) is None:
        raise BenchmarkError(f"INFO server returned invalid redis_version {value!r}")
    return value


def ping_sequential(client: redis.Redis, count: int) -> None:
    for index in range(count):
        require(client.ping() is True, f"PING {index + 1} returned a non-PONG reply")


def set_get_sequential(client: redis.Redis, key: bytes, count: int) -> None:
    for index in range(count):
        require(
            client.set(key, BINARY_PAYLOAD, px=KEY_TTL_MS) is True,
            f"SET {index + 1} returned a non-OK reply",
        )
        actual = client.get(key)
        require(
            actual == BINARY_PAYLOAD,
            f"GET {index + 1} returned {actual!r}, expected the binary payload",
        )


def incr_sequential(client: redis.Redis, key: bytes, count: int) -> None:
    for expected in range(1, count + 1):
        # redis-py aliases `incr()` to its INCRBY helper. Use the ordinary raw
        # command entrypoint so this subject sends INCR, matching Roc and Go.
        actual = client.execute_command("INCR", key)  # type: ignore[no-untyped-call]
        require(actual == expected, f"INCR returned {actual!r}, expected {expected}")


def ping_pipeline(client: redis.Redis, count: int, batch_size: int) -> None:
    completed = 0
    while completed < count:
        current_batch = min(batch_size, count - completed)
        with client.pipeline(transaction=False) as pipeline:
            for _ in range(current_batch):
                pipeline.ping()
            replies = pipeline.execute(raise_on_error=True)
        require(
            len(replies) == current_batch,
            f"pipeline returned {len(replies)} replies, expected {current_batch}",
        )
        for offset, reply in enumerate(replies):
            require(
                reply is True,
                f"pipelined PING {completed + offset + 1} returned a non-PONG reply",
            )
        completed += current_batch


def emit_result(
    config: Config,
    workload: str,
    sample: int,
    operation_count: int,
    command_count: int,
    round_trip_count: int,
    elapsed_ns: int,
) -> None:
    record = {
        "arch": config.arch,
        "build_mode": config.build_mode,
        "client": "redis-py",
        "client_version": redis.__version__,
        "command_count": command_count,
        "elapsed_ns": elapsed_ns,
        "implementation": IMPLEMENTATION,
        "iterations": config.iterations,
        "nix_source_id": config.nix_source_id,
        "nix_system": config.nix_system,
        "operation_count": operation_count,
        "order_rotation": config.order_rotation,
        "os": config.os,
        "pipeline_batch": config.pipeline_batch,
        "round_trip_count": round_trip_count,
        "redis_version": config.redis_version,
        "runtime_version": sys.version.split()[0],
        "sample": sample,
        "samples": config.samples,
        "schema": SCHEMA,
        "subject_position": config.subject_position,
        "timer": "monotonic",
        "validated": True,
        "warmup": config.warmup,
        "workload": workload,
    }
    print(json.dumps(record, sort_keys=True, separators=(",", ":")), flush=True)


def measure(action: Callable[[], None]) -> int:
    start = time.perf_counter_ns()
    action()
    elapsed = time.perf_counter_ns() - start
    require(elapsed >= 0, "monotonic clock returned a negative duration")
    return elapsed


def prepare_counter(client: redis.Redis, key: bytes) -> None:
    require(
        client.set(key, b"0", px=KEY_TTL_MS) is True,
        "counter SET returned a non-OK reply",
    )


def run(config: Config, client: redis.Redis, set_key: bytes, incr_key: bytes) -> None:
    verify_shared_connection(client)
    require(client.ping() is True, "initial PING returned a non-PONG reply")

    for sample in range(1, config.samples + 1):
        ping_sequential(client, config.warmup)
        elapsed = measure(lambda: ping_sequential(client, config.iterations))
        emit_result(
            config,
            "ping_sequential",
            sample,
            config.iterations,
            config.iterations,
            config.iterations,
            elapsed,
        )

    for sample in range(1, config.samples + 1):
        set_get_sequential(client, set_key, config.warmup)
        elapsed = measure(
            lambda: set_get_sequential(client, set_key, config.iterations)
        )
        emit_result(
            config,
            "set_get_sequential",
            sample,
            config.iterations,
            2 * config.iterations,
            2 * config.iterations,
            elapsed,
        )

    for sample in range(1, config.samples + 1):
        prepare_counter(client, incr_key)
        incr_sequential(client, incr_key, config.warmup)
        prepare_counter(client, incr_key)
        elapsed = measure(lambda: incr_sequential(client, incr_key, config.iterations))
        emit_result(
            config,
            "incr_sequential",
            sample,
            config.iterations,
            config.iterations,
            config.iterations,
            elapsed,
        )

    pipeline_round_trips = (
        config.iterations + config.pipeline_batch - 1
    ) // config.pipeline_batch
    for sample in range(1, config.samples + 1):
        ping_pipeline(client, config.warmup, config.pipeline_batch)
        elapsed = measure(
            lambda: ping_pipeline(client, config.iterations, config.pipeline_batch)
        )
        emit_result(
            config,
            "ping_pipeline",
            sample,
            config.iterations,
            config.iterations,
            pipeline_round_trips,
            elapsed,
        )


def cleanup(config: Config, keys: tuple[bytes, ...]) -> None:
    cleanup_client = new_client(config)
    try:
        deleted = cleanup_client.delete(*keys)
        require(
            0 <= deleted <= len(keys),
            f"cleanup DEL returned {deleted!r}, expected 0 through {len(keys)}",
        )
    finally:
        cleanup_client.close()


def main(argv: list[str]) -> int:
    config = parse_args(argv)
    marker_key = f"{config.key_prefix}:lease".encode("ascii")
    set_key = f"{config.key_prefix}:set-get".encode("ascii")
    incr_key = f"{config.key_prefix}:incr".encode("ascii")
    all_keys = (marker_key, set_key, incr_key)
    client = new_client(config)
    owns_lease = False
    primary_error: BaseException | None = None
    close_error: BaseException | None = None
    try:
        config = replace(config, redis_version=read_redis_version(client))
        owns_lease = bool(
            client.set(marker_key, b"benchmark-lease", nx=True, px=KEY_TTL_MS)
        )
        require(
            owns_lease,
            "key-prefix lease already exists; supply an exclusive --key-prefix",
        )
        run(config, client, set_key, incr_key)
    # Preserve cleanup even for cancellation and interpreter-exit signals.
    except BaseException as error:  # noqa: BLE001
        primary_error = error
    finally:
        try:
            client.close()
        except BaseException as error:  # noqa: BLE001
            close_error = error

    if primary_error is None and close_error is not None:
        primary_error = BenchmarkError(f"close benchmark connection: {close_error}")
    elif primary_error is not None and close_error is not None:
        primary_error = BenchmarkError(
            f"benchmark failed: {primary_error}; closing its connection also failed: {close_error}"
        )

    cleanup_error: BaseException | None = None
    if owns_lease:
        try:
            cleanup(config, all_keys)
        except BaseException as error:  # noqa: BLE001
            cleanup_error = error

    if primary_error is not None:
        if cleanup_error is not None:
            raise BenchmarkError(
                f"benchmark failed: {primary_error}; cleanup also failed: {cleanup_error}"
            ) from primary_error
        raise primary_error
    if cleanup_error is not None:
        raise BenchmarkError(f"benchmark succeeded but cleanup failed: {cleanup_error}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (BenchmarkError, redis.RedisError, OSError) as error:
        print(f"benchmark failed: {error}", file=sys.stderr)
        raise SystemExit(1) from error
