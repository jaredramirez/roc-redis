from __future__ import annotations

import contextlib
import io
import unittest
from typing import Self

import benchmark


class ConfigTests(unittest.TestCase):
    def test_parse_config(self) -> None:
        values = benchmark.parse_args(
            [
                "--host",
                "localhost",
                "--port",
                "6380",
                "--iterations",
                "20",
                "--warmup",
                "0",
                "--samples",
                "2",
                "--pipeline-batch",
                "7",
                "--timeout-ms",
                "20",
                "--key-prefix",
                "roc-redis-bench:test",
            ]
        )
        self.assertEqual(
            values,
            benchmark.Config(
                host="localhost",
                port=6380,
                iterations=20,
                warmup=0,
                samples=2,
                pipeline_batch=7,
                timeout_ms=20,
                key_prefix="roc-redis-bench:test",
                redis_version="",
                nix_source_id="unmanaged",
                build_mode="unmanaged",
                nix_system="unmanaged",
                os="unmanaged",
                arch="unmanaged",
                order_rotation=0,
                subject_position=0,
            ),
        )

    def test_rejects_non_decimal_and_unsafe_values(self) -> None:
        invalid = [
            ["--iterations", "+1"],
            ["--warmup", "-1"],
            ["--samples", "1_0"],
            ["--port", "0"],
            ["--key-prefix", "bad/prefix"],
            ["--nix-source-id", "bad/source"],
            ["--order-rotation", "10"],
            ["--subject-position", "6"],
            ["unexpected"],
        ]
        for arguments in invalid:
            with (
                self.subTest(arguments=arguments),
                contextlib.redirect_stderr(io.StringIO()),
                self.assertRaises(SystemExit),
            ):
                benchmark.parse_args(arguments)

    def test_binary_payload(self) -> None:
        self.assertEqual(
            benchmark.BINARY_PAYLOAD.hex(),
            "000d0aff80526f632d5265646973000102030a0d7f80feff41424378797a00ff",
        )

    def test_increment_workload_sends_incr_not_incrby(self) -> None:
        class FakeClient:
            def __init__(self) -> None:
                self.commands: list[tuple[str, bytes]] = []

            def execute_command(self, command: str, key: bytes) -> int:
                self.commands.append((command, key))
                return len(self.commands)

        client = FakeClient()
        benchmark.incr_sequential(client, b"key", 3)  # type: ignore[arg-type]
        self.assertEqual(client.commands, [("INCR", b"key")] * 3)

    def test_direct_and_pipeline_paths_share_one_connection_pool(self) -> None:
        config = benchmark.parse_args([])
        client = benchmark.new_client(config)
        try:
            self.assertIsNone(client.connection)
            self.assertEqual(client.connection_pool.max_connections, 1)
            with client.pipeline(transaction=False) as pipeline:
                self.assertIs(pipeline.connection_pool, client.connection_pool)
        finally:
            client.close()

    def test_shared_connection_verification_checks_client_id(self) -> None:
        class FakePipeline:
            def __init__(self) -> None:
                self.raise_on_error = False

            def __enter__(self) -> Self:
                return self

            def __exit__(self, *_args: object) -> None:
                return None

            def client_id(self) -> FakePipeline:
                return self

            def execute(self, *, raise_on_error: bool) -> list[int]:
                self.raise_on_error = raise_on_error
                return [42]

        class FakeClient:
            def __init__(self) -> None:
                self.pipeline_value = FakePipeline()
                self.transaction = True

            def client_id(self) -> int:
                return 42

            def pipeline(self, *, transaction: bool) -> FakePipeline:
                self.transaction = transaction
                return self.pipeline_value

        client = FakeClient()
        benchmark.verify_shared_connection(client)  # type: ignore[arg-type]
        self.assertFalse(client.transaction)
        self.assertTrue(client.pipeline_value.raise_on_error)

    def test_shared_connection_verification_rejects_a_second_socket(self) -> None:
        class FakePipeline:
            def __enter__(self) -> Self:
                return self

            def __exit__(self, *_args: object) -> None:
                return None

            def client_id(self) -> FakePipeline:
                return self

            def execute(self, *, raise_on_error: bool) -> list[int]:
                del raise_on_error
                return [43]

        class FakeClient:
            def client_id(self) -> int:
                return 42

            def pipeline(self, *, transaction: bool) -> FakePipeline:
                del transaction
                return FakePipeline()

        with self.assertRaisesRegex(
            benchmark.BenchmarkError, "share one TCP connection"
        ):
            benchmark.verify_shared_connection(FakeClient())  # type: ignore[arg-type]

    def test_reads_and_validates_redis_version(self) -> None:
        class FakeClient:
            def info(self, *, section: str) -> dict[str, object]:
                self.section = section
                return {"redis_version": "8.10.1"}

        client = FakeClient()
        self.assertEqual(
            benchmark.read_redis_version(client),  # type: ignore[arg-type]
            "8.10.1",
        )
        self.assertEqual(client.section, "server")


if __name__ == "__main__":
    unittest.main()
