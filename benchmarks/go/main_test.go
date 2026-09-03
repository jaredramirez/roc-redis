package main

import (
	"bytes"
	"errors"
	"flag"
	"testing"
)

func TestParseConfig(t *testing.T) {
	values, err := parseConfig([]string{
		"--host", "localhost",
		"--port", "6380",
		"--iterations", "20",
		"--warmup", "0",
		"--samples", "2",
		"--pipeline-batch", "7",
		"--timeout-ms", "20",
		"--key-prefix", "roc-redis-bench:test",
	})
	if err != nil {
		t.Fatalf("parseConfig returned an error: %v", err)
	}
	if values.host != "localhost" || values.port != 6380 || values.iterations != 20 ||
		values.warmup != 0 || values.samples != 2 || values.pipelineBatch != 7 ||
		values.timeoutMS != 20 || values.keyPrefix != "roc-redis-bench:test" || values.redisVersion != "" ||
		values.clientVersion != "" || values.nixSourceID != "unmanaged" || values.buildMode != "unmanaged" ||
		values.nixSystem != "unmanaged" || values.os != "unmanaged" || values.arch != "unmanaged" ||
		values.orderRotation != 0 || values.subjectPosition != 0 {
		t.Fatalf("parseConfig returned unexpected values: %#v", values)
	}
}

func TestRedisVersionValidation(t *testing.T) {
	for _, version := range []string{"8.10.1", "8.10.1-rc1", "redis_8+dev"} {
		if !isSafeVersion(version) {
			t.Errorf("isSafeVersion(%q) unexpectedly returned false", version)
		}
	}
	for _, version := range []string{"", "bad version", "8.10.1\nother"} {
		if isSafeVersion(version) {
			t.Errorf("isSafeVersion(%q) unexpectedly returned true", version)
		}
	}
}

func TestParseConfigHelp(t *testing.T) {
	if _, err := parseConfig([]string{"--help"}); !errors.Is(err, flag.ErrHelp) {
		t.Fatalf("parseConfig help returned %v, expected flag.ErrHelp", err)
	}
}

func TestParseConfigRejectsNonDecimalAndUnsafePrefix(t *testing.T) {
	for _, arguments := range [][]string{
		{"--iterations", "+1"},
		{"--warmup", "-1"},
		{"--samples", "1_0"},
		{"--port", "0"},
		{"--key-prefix", "bad/prefix"},
		{"--nix-source-id", "bad/source"},
		{"--order-rotation", "10"},
		{"--subject-position", "6"},
		{"unexpected"},
	} {
		if _, err := parseConfig(arguments); err == nil {
			t.Errorf("parseConfig(%q) unexpectedly succeeded", arguments)
		}
	}
}

func TestGoRedisVersionComesFromBuildInfo(t *testing.T) {
	version, err := readGoRedisClientVersion()
	if err != nil {
		t.Fatalf("readGoRedisClientVersion returned an error: %v", err)
	}
	if version != "v9.22.0" {
		t.Fatalf("readGoRedisClientVersion returned %q, expected v9.22.0", version)
	}
}

func TestSharedClientIDInvariant(t *testing.T) {
	if err := requireSharedClientID(42, 42); err != nil {
		t.Fatalf("matching client IDs returned an error: %v", err)
	}
	if err := requireSharedClientID(42, 43); err == nil {
		t.Fatal("different client IDs unexpectedly passed")
	}
}

func TestBinaryPayload(t *testing.T) {
	expected := []byte{
		0, 13, 10, 255, 128, 82, 111, 99,
		45, 82, 101, 100, 105, 115, 0, 1,
		2, 3, 10, 13, 127, 128, 254, 255,
		65, 66, 67, 120, 121, 122, 0, 255,
	}
	if !bytes.Equal(binaryPayload, expected) {
		t.Fatalf("binary payload is %x, expected %x", binaryPayload, expected)
	}
}
