package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"net"
	"os"
	"runtime"
	"runtime/debug"
	"strconv"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
)

const (
	schema           = "roc-redis-benchmark/v2"
	implementation   = "go"
	maxIterations    = uint64(1_000_000_000)
	maxSamples       = uint64(1_000)
	maxPipelineBatch = uint64(65_536)
	maxTimeoutMS     = uint64(300_000)
	keyTTL           = 24*time.Hour + time.Millisecond
)

var binaryPayload = []byte{
	0, 13, 10, 255, 128, 82, 111, 99,
	45, 82, 101, 100, 105, 115, 0, 1,
	2, 3, 10, 13, 127, 128, 254, 255,
	65, 66, 67, 120, 121, 122, 0, 255,
}

type config struct {
	host            string
	port            uint64
	iterations      uint64
	warmup          uint64
	samples         uint64
	pipelineBatch   uint64
	timeoutMS       uint64
	keyPrefix       string
	redisVersion    string
	clientVersion   string
	nixSourceID     string
	buildMode       string
	nixSystem       string
	os              string
	arch            string
	orderRotation   uint64
	subjectPosition uint64
}

type result struct {
	Schema          string `json:"schema"`
	Implementation  string `json:"implementation"`
	Client          string `json:"client"`
	ClientVersion   string `json:"client_version"`
	RuntimeVersion  string `json:"runtime_version"`
	RedisVersion    string `json:"redis_version"`
	Timer           string `json:"timer"`
	Workload        string `json:"workload"`
	Sample          uint64 `json:"sample"`
	Samples         uint64 `json:"samples"`
	Iterations      uint64 `json:"iterations"`
	Warmup          uint64 `json:"warmup"`
	PipelineBatch   uint64 `json:"pipeline_batch"`
	OperationCount  uint64 `json:"operation_count"`
	CommandCount    uint64 `json:"command_count"`
	RoundTripCount  uint64 `json:"round_trip_count"`
	ElapsedNS       uint64 `json:"elapsed_ns"`
	Validated       bool   `json:"validated"`
	NixSourceID     string `json:"nix_source_id"`
	BuildMode       string `json:"build_mode"`
	NixSystem       string `json:"nix_system"`
	OS              string `json:"os"`
	Arch            string `json:"arch"`
	OrderRotation   uint64 `json:"order_rotation"`
	SubjectPosition uint64 `json:"subject_position"`
}

func parseConfig(arguments []string) (config, error) {
	values := config{}
	var portText, iterationsText, warmupText, samplesText, pipelineBatchText, timeoutMSText string
	var orderRotationText, subjectPositionText string
	flags := flag.NewFlagSet("go-redis-benchmark", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	flags.StringVar(&values.host, "host", "127.0.0.1", "Redis host")
	flags.StringVar(&portText, "port", "6379", "Redis port")
	flags.StringVar(&iterationsText, "iterations", "10000", "measured operations per sample")
	flags.StringVar(&warmupText, "warmup", "1000", "unmeasured operations before each sample")
	flags.StringVar(&samplesText, "samples", "5", "samples per workload")
	flags.StringVar(&pipelineBatchText, "pipeline-batch", "100", "PING commands per pipeline")
	flags.StringVar(&timeoutMSText, "timeout-ms", "5000", "connect/read/write timeout")
	flags.StringVar(&values.keyPrefix, "key-prefix", "", "exclusive safe-ASCII Redis key prefix")
	flags.StringVar(&values.nixSourceID, "nix-source-id", "unmanaged", "content-derived Nix source identifier")
	flags.StringVar(&values.buildMode, "build-mode", "unmanaged", "benchmark build mode")
	flags.StringVar(&values.nixSystem, "nix-system", "unmanaged", "Nix system identifier")
	flags.StringVar(&values.os, "os", "unmanaged", "operating-system identifier")
	flags.StringVar(&values.arch, "arch", "unmanaged", "architecture identifier")
	flags.StringVar(&orderRotationText, "order-rotation", "0", "controller subject-order permutation")
	flags.StringVar(&subjectPositionText, "subject-position", "0", "one-based position assigned by the controller")
	if err := flags.Parse(arguments); err != nil {
		return config{}, err
	}
	if flags.NArg() != 0 {
		return config{}, fmt.Errorf("unexpected positional arguments: %s", strings.Join(flags.Args(), " "))
	}
	var err error
	if values.port, err = parseBoundedDecimal("port", portText, 1, 65_535); err != nil {
		return config{}, err
	}
	if values.iterations, err = parseBoundedDecimal("iterations", iterationsText, 1, maxIterations); err != nil {
		return config{}, err
	}
	if values.warmup, err = parseBoundedDecimal("warmup", warmupText, 0, maxIterations); err != nil {
		return config{}, err
	}
	if values.samples, err = parseBoundedDecimal("samples", samplesText, 1, maxSamples); err != nil {
		return config{}, err
	}
	if values.pipelineBatch, err = parseBoundedDecimal("pipeline-batch", pipelineBatchText, 1, maxPipelineBatch); err != nil {
		return config{}, err
	}
	if values.timeoutMS, err = parseBoundedDecimal("timeout-ms", timeoutMSText, 1, maxTimeoutMS); err != nil {
		return config{}, err
	}
	if values.orderRotation, err = parseBoundedDecimal("order-rotation", orderRotationText, 0, 9); err != nil {
		return config{}, err
	}
	if values.subjectPosition, err = parseBoundedDecimal("subject-position", subjectPositionText, 0, 5); err != nil {
		return config{}, err
	}
	if !isSafeHost(values.host) {
		return config{}, errors.New("host must contain 1 through 253 printable non-space ASCII characters")
	}
	if values.keyPrefix == "" {
		values.keyPrefix = fmt.Sprintf("roc-redis-bench:go:%d:%d", os.Getpid(), time.Now().UnixNano())
	} else if !isSafePrefix(values.keyPrefix) {
		return config{}, errors.New("key-prefix must contain 1 through 128 ASCII letters, digits, '.', '_', ':', or '-'")
	}
	metadata := []struct {
		name  string
		value string
	}{
		{name: "nix-source-id", value: values.nixSourceID},
		{name: "build-mode", value: values.buildMode},
		{name: "nix-system", value: values.nixSystem},
		{name: "os", value: values.os},
		{name: "arch", value: values.arch},
	}
	for _, field := range metadata {
		if !isSafeMetadata(field.value) {
			return config{}, fmt.Errorf("%s must contain 1 through 128 safe ASCII characters", field.name)
		}
	}
	return values, nil
}

func parseBoundedDecimal(name, text string, minimum, maximum uint64) (uint64, error) {
	if text == "" {
		return 0, fmt.Errorf("%s must be a decimal integer", name)
	}
	for _, character := range []byte(text) {
		if character < '0' || character > '9' {
			return 0, fmt.Errorf("%s must be a decimal integer", name)
		}
	}
	value, err := strconv.ParseUint(text, 10, 64)
	if err != nil {
		return 0, fmt.Errorf("%s must be from %d through %d", name, minimum, maximum)
	}
	if value < minimum || value > maximum {
		return 0, fmt.Errorf("%s must be from %d through %d", name, minimum, maximum)
	}
	return value, nil
}

func isSafeHost(value string) bool {
	if len(value) < 1 || len(value) > 253 {
		return false
	}
	for _, character := range []byte(value) {
		if character < 33 || character > 126 {
			return false
		}
	}
	return true
}

func isSafePrefix(value string) bool {
	if len(value) < 1 || len(value) > 128 {
		return false
	}
	for _, character := range []byte(value) {
		if !((character >= 'A' && character <= 'Z') ||
			(character >= 'a' && character <= 'z') ||
			(character >= '0' && character <= '9') ||
			character == '.' || character == '_' || character == ':' || character == '-') {
			return false
		}
	}
	return true
}

func isSafeMetadata(value string) bool {
	if len(value) < 1 || len(value) > 128 {
		return false
	}
	for _, character := range []byte(value) {
		if !((character >= 'A' && character <= 'Z') ||
			(character >= 'a' && character <= 'z') ||
			(character >= '0' && character <= '9') ||
			character == '+' || character == '.' || character == '_' ||
			character == ':' || character == '-') {
			return false
		}
	}
	return true
}

func readGoRedisClientVersion() (string, error) {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		return "", errors.New("Go build information is unavailable")
	}
	for _, dependency := range info.Deps {
		if dependency.Path == "github.com/redis/go-redis/v9" {
			if dependency.Replace != nil {
				return "", errors.New("go-redis build dependency has an untracked replacement")
			}
			if !isSafeVersion(dependency.Version) {
				return "", fmt.Errorf("Go build information returned invalid go-redis version %q", dependency.Version)
			}
			return dependency.Version, nil
		}
	}
	return "", errors.New("Go build information omitted github.com/redis/go-redis/v9")
}

func newClient(values config) *redis.Client {
	timeout := time.Duration(values.timeoutMS) * time.Millisecond
	return redis.NewClient(&redis.Options{
		Addr:            net.JoinHostPort(values.host, strconv.FormatUint(values.port, 10)),
		Protocol:        2,
		DialTimeout:     timeout,
		ReadTimeout:     timeout,
		WriteTimeout:    timeout,
		PoolSize:        1,
		MaxRetries:      -1,
		MinRetryBackoff: -1,
		MaxRetryBackoff: -1,
	})
}

func readRedisVersion(ctx context.Context, client *redis.Client) (string, error) {
	info, err := client.Info(ctx, "server").Result()
	if err != nil {
		return "", fmt.Errorf("read INFO server: %w", err)
	}
	for _, rawLine := range strings.Split(info, "\n") {
		line := strings.TrimSpace(rawLine)
		if strings.HasPrefix(line, "redis_version:") {
			version := strings.TrimSpace(strings.TrimPrefix(line, "redis_version:"))
			if isSafeVersion(version) {
				return version, nil
			}
			return "", fmt.Errorf("INFO server returned invalid redis_version %q", version)
		}
	}
	return "", errors.New("INFO server omitted redis_version")
}

func isSafeVersion(value string) bool {
	if len(value) < 1 || len(value) > 128 {
		return false
	}
	for _, character := range []byte(value) {
		if !((character >= 'A' && character <= 'Z') ||
			(character >= 'a' && character <= 'z') ||
			(character >= '0' && character <= '9') ||
			character == '+' || character == '.' || character == '_' || character == '-') {
			return false
		}
	}
	return true
}

func requireSharedClientID(directID, pipelineID int64) error {
	if directID != pipelineID {
		return fmt.Errorf(
			"go-redis direct and pipeline commands did not share one TCP connection: CLIENT ID %d != %d",
			directID,
			pipelineID,
		)
	}
	return nil
}

func verifySharedConnection(ctx context.Context, client *redis.Client) error {
	directID, err := client.ClientID(ctx).Result()
	if err != nil {
		return fmt.Errorf("read direct CLIENT ID: %w", err)
	}
	pipeline := client.Pipeline()
	pipelinedID := pipeline.Do(ctx, "CLIENT", "ID")
	if _, err = pipeline.Exec(ctx); err != nil {
		return fmt.Errorf("read pipeline CLIENT ID: %w", err)
	}
	pipelineID, err := pipelinedID.Int64()
	if err != nil {
		return fmt.Errorf("decode pipeline CLIENT ID: %w", err)
	}
	return requireSharedClientID(directID, pipelineID)
}

func pingSequential(ctx context.Context, client *redis.Client, count uint64) error {
	for index := uint64(0); index < count; index++ {
		actual, err := client.Ping(ctx).Result()
		if err != nil {
			return fmt.Errorf("PING %d: %w", index+1, err)
		}
		if actual != "PONG" {
			return fmt.Errorf("PING %d returned %q, expected PONG", index+1, actual)
		}
	}
	return nil
}

func setGetSequential(ctx context.Context, client *redis.Client, key string, count uint64) error {
	for index := uint64(0); index < count; index++ {
		actual, err := client.Set(ctx, key, binaryPayload, keyTTL).Result()
		if err != nil {
			return fmt.Errorf("SET %d: %w", index+1, err)
		}
		if actual != "OK" {
			return fmt.Errorf("SET %d returned %q, expected OK", index+1, actual)
		}
		bytesValue, err := client.Get(ctx, key).Bytes()
		if err != nil {
			return fmt.Errorf("GET %d: %w", index+1, err)
		}
		if !bytes.Equal(bytesValue, binaryPayload) {
			return fmt.Errorf("GET %d returned %x, expected %x", index+1, bytesValue, binaryPayload)
		}
	}
	return nil
}

func incrSequential(ctx context.Context, client *redis.Client, key string, count uint64) error {
	for expected := uint64(1); expected <= count; expected++ {
		actual, err := client.Incr(ctx, key).Result()
		if err != nil {
			return fmt.Errorf("INCR %d: %w", expected, err)
		}
		if actual != int64(expected) {
			return fmt.Errorf("INCR returned %d, expected %d", actual, expected)
		}
	}
	return nil
}

func pingPipeline(ctx context.Context, client *redis.Client, count, batchSize uint64) error {
	completed := uint64(0)
	for completed < count {
		currentBatch := min(batchSize, count-completed)
		pipeline := client.Pipeline()
		commands := make([]*redis.StatusCmd, 0, currentBatch)
		for index := uint64(0); index < currentBatch; index++ {
			commands = append(commands, pipeline.Ping(ctx))
		}
		_, execErr := pipeline.Exec(ctx)
		if execErr != nil {
			return fmt.Errorf("execute PING pipeline after %d commands: %w", completed, execErr)
		}
		for offset, command := range commands {
			actual, err := command.Result()
			if err != nil {
				return fmt.Errorf("pipelined PING %d: %w", completed+uint64(offset)+1, err)
			}
			if actual != "PONG" {
				return fmt.Errorf("pipelined PING %d returned %q, expected PONG", completed+uint64(offset)+1, actual)
			}
		}
		completed += currentBatch
	}
	return nil
}

func msetMgetSequential(ctx context.Context, client *redis.Client, keys []string, count uint64) error {
	setArgs := make([]interface{}, 0, len(keys)*2)
	for _, key := range keys {
		setArgs = append(setArgs, key, binaryPayload)
	}
	for index := uint64(0); index < count; index++ {
		actual, err := client.MSet(ctx, setArgs...).Result()
		if err != nil {
			return fmt.Errorf("MSET %d: %w", index+1, err)
		}
		if actual != "OK" {
			return fmt.Errorf("MSET %d returned %q, expected OK", index+1, actual)
		}
		values, err := client.MGet(ctx, keys...).Result()
		if err != nil {
			return fmt.Errorf("MGET %d: %w", index+1, err)
		}
		if len(values) != len(keys) {
			return fmt.Errorf("MGET %d returned %d values, expected %d", index+1, len(values), len(keys))
		}
		for offset, value := range values {
			text, ok := value.(string)
			if !ok {
				return fmt.Errorf("MGET %d value %d returned %T, expected string", index+1, offset+1, value)
			}
			if !bytes.Equal([]byte(text), binaryPayload) {
				return fmt.Errorf("MGET %d value %d returned %x, expected %x", index+1, offset+1, []byte(text), binaryPayload)
			}
		}
	}
	return nil
}

func hashRoundtripSequential(ctx context.Context, client *redis.Client, key string, count uint64) error {
	fields := []string{"field:0", "field:1", "field:2"}
	setArgs := make([]interface{}, 0, len(fields)*2)
	for _, field := range fields {
		setArgs = append(setArgs, field, binaryPayload)
	}
	for index := uint64(0); index < count; index++ {
		added, err := client.HSet(ctx, key, setArgs...).Result()
		if err != nil {
			return fmt.Errorf("HSET %d: %w", index+1, err)
		}
		if added < 0 {
			return fmt.Errorf("HSET %d returned %d, expected a non-negative count", index+1, added)
		}
		stored, err := client.HGetAll(ctx, key).Result()
		if err != nil {
			return fmt.Errorf("HGETALL %d: %w", index+1, err)
		}
		if len(stored) != len(fields) {
			return fmt.Errorf("HGETALL %d returned %d fields, expected %d", index+1, len(stored), len(fields))
		}
		for _, field := range fields {
			text, ok := stored[field]
			if !ok {
				return fmt.Errorf("HGETALL %d omitted field %q", index+1, field)
			}
			if !bytes.Equal([]byte(text), binaryPayload) {
				return fmt.Errorf("HGETALL %d field %q returned %x, expected %x", index+1, field, []byte(text), binaryPayload)
			}
		}
	}
	return nil
}

func setGetPipeline(ctx context.Context, client *redis.Client, key string, count, batchSize uint64) error {
	completed := uint64(0)
	for completed < count {
		currentBatch := min(batchSize, count-completed)
		pipeline := client.Pipeline()
		setCommands := make([]*redis.StatusCmd, 0, currentBatch)
		getCommands := make([]*redis.StringCmd, 0, currentBatch)
		for index := uint64(0); index < currentBatch; index++ {
			setCommands = append(setCommands, pipeline.Set(ctx, key, binaryPayload, keyTTL))
			getCommands = append(getCommands, pipeline.Get(ctx, key))
		}
		_, execErr := pipeline.Exec(ctx)
		if execErr != nil {
			return fmt.Errorf("execute SET/GET pipeline after %d operations: %w", completed, execErr)
		}
		for offset := range setCommands {
			actual, err := setCommands[offset].Result()
			if err != nil {
				return fmt.Errorf("pipelined SET %d: %w", completed+uint64(offset)+1, err)
			}
			if actual != "OK" {
				return fmt.Errorf("pipelined SET %d returned %q, expected OK", completed+uint64(offset)+1, actual)
			}
			bytesValue, err := getCommands[offset].Bytes()
			if err != nil {
				return fmt.Errorf("pipelined GET %d: %w", completed+uint64(offset)+1, err)
			}
			if !bytes.Equal(bytesValue, binaryPayload) {
				return fmt.Errorf("pipelined GET %d returned %x, expected %x", completed+uint64(offset)+1, bytesValue, binaryPayload)
			}
		}
		completed += currentBatch
	}
	return nil
}

func prepareCounter(ctx context.Context, client *redis.Client, key string) error {
	actual, err := client.Set(ctx, key, "0", keyTTL).Result()
	if err != nil {
		return fmt.Errorf("counter SET: %w", err)
	}
	if actual != "OK" {
		return fmt.Errorf("counter SET returned %q, expected OK", actual)
	}
	return nil
}

func measure(action func() error) (uint64, error) {
	start := time.Now()
	if err := action(); err != nil {
		return 0, err
	}
	elapsed := time.Since(start)
	if elapsed < 0 {
		return 0, errors.New("monotonic clock returned a negative duration")
	}
	return uint64(elapsed.Nanoseconds()), nil
}

func emit(values config, workload string, sample, operations, commands, roundTrips, elapsed uint64) error {
	encoder := json.NewEncoder(os.Stdout)
	encoder.SetEscapeHTML(false)
	return encoder.Encode(result{
		Schema:          schema,
		Implementation:  implementation,
		Client:          "go-redis",
		ClientVersion:   values.clientVersion,
		RuntimeVersion:  runtime.Version(),
		RedisVersion:    values.redisVersion,
		Timer:           "monotonic",
		Workload:        workload,
		Sample:          sample,
		Samples:         values.samples,
		Iterations:      values.iterations,
		Warmup:          values.warmup,
		PipelineBatch:   values.pipelineBatch,
		OperationCount:  operations,
		CommandCount:    commands,
		RoundTripCount:  roundTrips,
		ElapsedNS:       elapsed,
		Validated:       true,
		NixSourceID:     values.nixSourceID,
		BuildMode:       values.buildMode,
		NixSystem:       values.nixSystem,
		OS:              values.os,
		Arch:            values.arch,
		OrderRotation:   values.orderRotation,
		SubjectPosition: values.subjectPosition,
	})
}

func run(ctx context.Context, values config, client *redis.Client, setKey, incrKey string, msetKeys []string, hashKey, setGetPipeKey string) error {
	if err := verifySharedConnection(ctx, client); err != nil {
		return err
	}
	if err := pingSequential(ctx, client, 1); err != nil {
		return fmt.Errorf("initial connection check: %w", err)
	}

	for sample := uint64(1); sample <= values.samples; sample++ {
		if err := pingSequential(ctx, client, values.warmup); err != nil {
			return fmt.Errorf("ping_sequential sample %d warmup: %w", sample, err)
		}
		elapsed, err := measure(func() error { return pingSequential(ctx, client, values.iterations) })
		if err != nil {
			return fmt.Errorf("ping_sequential sample %d: %w", sample, err)
		}
		if err := emit(values, "ping_sequential", sample, values.iterations, values.iterations, values.iterations, elapsed); err != nil {
			return fmt.Errorf("write ping_sequential result: %w", err)
		}
	}

	for sample := uint64(1); sample <= values.samples; sample++ {
		if err := setGetSequential(ctx, client, setKey, values.warmup); err != nil {
			return fmt.Errorf("set_get_sequential sample %d warmup: %w", sample, err)
		}
		elapsed, err := measure(func() error { return setGetSequential(ctx, client, setKey, values.iterations) })
		if err != nil {
			return fmt.Errorf("set_get_sequential sample %d: %w", sample, err)
		}
		if err := emit(values, "set_get_sequential", sample, values.iterations, 2*values.iterations, 2*values.iterations, elapsed); err != nil {
			return fmt.Errorf("write set_get_sequential result: %w", err)
		}
	}

	for sample := uint64(1); sample <= values.samples; sample++ {
		if err := prepareCounter(ctx, client, incrKey); err != nil {
			return err
		}
		if err := incrSequential(ctx, client, incrKey, values.warmup); err != nil {
			return fmt.Errorf("incr_sequential sample %d warmup: %w", sample, err)
		}
		if err := prepareCounter(ctx, client, incrKey); err != nil {
			return err
		}
		elapsed, err := measure(func() error { return incrSequential(ctx, client, incrKey, values.iterations) })
		if err != nil {
			return fmt.Errorf("incr_sequential sample %d: %w", sample, err)
		}
		if err := emit(values, "incr_sequential", sample, values.iterations, values.iterations, values.iterations, elapsed); err != nil {
			return fmt.Errorf("write incr_sequential result: %w", err)
		}
	}

	roundTrips := (values.iterations + values.pipelineBatch - 1) / values.pipelineBatch
	for sample := uint64(1); sample <= values.samples; sample++ {
		if err := pingPipeline(ctx, client, values.warmup, values.pipelineBatch); err != nil {
			return fmt.Errorf("ping_pipeline sample %d warmup: %w", sample, err)
		}
		elapsed, err := measure(func() error { return pingPipeline(ctx, client, values.iterations, values.pipelineBatch) })
		if err != nil {
			return fmt.Errorf("ping_pipeline sample %d: %w", sample, err)
		}
		if err := emit(values, "ping_pipeline", sample, values.iterations, values.iterations, roundTrips, elapsed); err != nil {
			return fmt.Errorf("write ping_pipeline result: %w", err)
		}
	}

	for sample := uint64(1); sample <= values.samples; sample++ {
		if err := msetMgetSequential(ctx, client, msetKeys, values.warmup); err != nil {
			return fmt.Errorf("mset_mget_sequential sample %d warmup: %w", sample, err)
		}
		elapsed, err := measure(func() error { return msetMgetSequential(ctx, client, msetKeys, values.iterations) })
		if err != nil {
			return fmt.Errorf("mset_mget_sequential sample %d: %w", sample, err)
		}
		if err := emit(values, "mset_mget_sequential", sample, values.iterations, 2*values.iterations, 2*values.iterations, elapsed); err != nil {
			return fmt.Errorf("write mset_mget_sequential result: %w", err)
		}
	}

	for sample := uint64(1); sample <= values.samples; sample++ {
		if err := hashRoundtripSequential(ctx, client, hashKey, values.warmup); err != nil {
			return fmt.Errorf("hash_roundtrip_sequential sample %d warmup: %w", sample, err)
		}
		elapsed, err := measure(func() error { return hashRoundtripSequential(ctx, client, hashKey, values.iterations) })
		if err != nil {
			return fmt.Errorf("hash_roundtrip_sequential sample %d: %w", sample, err)
		}
		if err := emit(values, "hash_roundtrip_sequential", sample, values.iterations, 2*values.iterations, 2*values.iterations, elapsed); err != nil {
			return fmt.Errorf("write hash_roundtrip_sequential result: %w", err)
		}
	}

	for sample := uint64(1); sample <= values.samples; sample++ {
		if err := setGetPipeline(ctx, client, setGetPipeKey, values.warmup, values.pipelineBatch); err != nil {
			return fmt.Errorf("set_get_pipeline sample %d warmup: %w", sample, err)
		}
		elapsed, err := measure(func() error { return setGetPipeline(ctx, client, setGetPipeKey, values.iterations, values.pipelineBatch) })
		if err != nil {
			return fmt.Errorf("set_get_pipeline sample %d: %w", sample, err)
		}
		if err := emit(values, "set_get_pipeline", sample, values.iterations, 2*values.iterations, roundTrips, elapsed); err != nil {
			return fmt.Errorf("write set_get_pipeline result: %w", err)
		}
	}
	return nil
}

func cleanup(ctx context.Context, values config, keys ...string) error {
	client := newClient(values)
	defer client.Close()
	deleted, err := client.Del(ctx, keys...).Result()
	if err != nil {
		return fmt.Errorf("delete benchmark keys: %w", err)
	}
	if deleted < 0 || deleted > int64(len(keys)) {
		return fmt.Errorf("cleanup DEL returned %d, expected 0 through %d", deleted, len(keys))
	}
	return nil
}

func main() {
	values, err := parseConfig(os.Args[1:])
	if err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return
		}
		fmt.Fprintf(os.Stderr, "benchmark failed: %v\n", err)
		os.Exit(2)
	}

	ctx := context.Background()
	values.clientVersion, err = readGoRedisClientVersion()
	if err != nil {
		fmt.Fprintf(os.Stderr, "benchmark failed: %v\n", err)
		os.Exit(2)
	}
	markerKey := values.keyPrefix + ":lease"
	setKey := values.keyPrefix + ":set-get"
	incrKey := values.keyPrefix + ":incr"
	msetKeys := []string{
		values.keyPrefix + ":mset:0",
		values.keyPrefix + ":mset:1",
		values.keyPrefix + ":mset:2",
		values.keyPrefix + ":mset:3",
	}
	hashKey := values.keyPrefix + ":hash"
	setGetPipeKey := values.keyPrefix + ":sg-pipe"
	client := newClient(values)
	redisVersion, primaryErr := readRedisVersion(ctx, client)
	values.redisVersion = redisVersion
	acquired := false
	if primaryErr == nil {
		acquired, primaryErr = client.SetNX(ctx, markerKey, "benchmark-lease", keyTTL).Result()
	}
	if primaryErr == nil && !acquired {
		primaryErr = errors.New("key-prefix lease already exists; supply an exclusive --key-prefix")
	}
	if primaryErr == nil {
		primaryErr = run(ctx, values, client, setKey, incrKey, msetKeys, hashKey, setGetPipeKey)
	}
	closeErr := client.Close()
	if primaryErr == nil && closeErr != nil {
		primaryErr = fmt.Errorf("close benchmark connection: %w", closeErr)
	}

	var cleanupErr error
	if acquired {
		cleanupKeys := []string{markerKey, setKey, incrKey}
		cleanupKeys = append(cleanupKeys, msetKeys...)
		cleanupKeys = append(cleanupKeys, hashKey, setGetPipeKey)
		cleanupErr = cleanup(ctx, values, cleanupKeys...)
	}
	if primaryErr != nil {
		if cleanupErr != nil {
			fmt.Fprintf(os.Stderr, "benchmark failed: %v; cleanup also failed: %v\n", primaryErr, cleanupErr)
		} else {
			fmt.Fprintf(os.Stderr, "benchmark failed: %v\n", primaryErr)
		}
		os.Exit(1)
	}
	if cleanupErr != nil {
		fmt.Fprintf(os.Stderr, "benchmark failed: benchmark succeeded but cleanup failed: %v\n", cleanupErr)
		os.Exit(1)
	}
}
