#define BENCHMARK_TEST
#include "benchmark.c"

typedef struct {
  unsigned char payload[32];
  char encoded[128], response[64];
  size_t encoded_len, response_len;
} Fixture;

static int codec_run(int encode, uint64_t count, const Fixture *fixtures) {
  for (uint64_t i = 0; i < count; ++i) {
    const Fixture *f = &fixtures[i % 256];
    if (encode) {
      const char *args[] = {"SET", "key", (const char *)f->payload};
      const size_t lengths[] = {3, 3, 32};
      char *wire = NULL;
      long long length = redisFormatCommandArgv(&wire, 3, args, lengths);
      int okay = length >= 0 && (size_t)length == f->encoded_len &&
                 memcmp(wire, f->encoded, f->encoded_len) == 0;
      redisFreeCommand(wire);
      if (!okay)
        return failure("codec encoding mismatch");
    } else {
      redisReader *reader = redisReaderCreate();
      if (!reader)
        return failure("codec reader allocation");
      redisReply *reply = NULL;
      int okay =
          redisReaderFeed(reader, f->response, f->response_len) == REDIS_OK &&
          redisReaderGetReply(reader, (void **)&reply) == REDIS_OK &&
          text_reply(reply, REDIS_REPLY_STRING, f->payload, 32);
      freeReplyObject(reply);
      redisReaderFree(reader);
      if (!okay)
        return failure("codec decoding mismatch");
    }
  }
  return 1;
}

int main(int argc, char **argv) {
  uint64_t iterations, sample, position, seed;
  if (argc != 6 || !decimal(argv[1], 1, 1000000, &iterations) ||
      !decimal(argv[2], 1, 10, &sample) || !decimal(argv[3], 1, 2, &position) ||
      !safe(argv[4], "+._:-", 128) || !decimal(argv[5], 0, 255, &seed))
    return 1;
  Fixture fixtures[256];
  const char *prefix = "*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$32\r\n";
  for (size_t i = 0; i < 256; ++i) {
    Fixture *f = &fixtures[i];
    memcpy(f->payload, payload, 32);
    f->payload[31] = (unsigned char)(i + seed);
    size_t n = strlen(prefix);
    memcpy(f->encoded, prefix, n);
    memcpy(f->encoded + n, f->payload, 32);
    memcpy(f->encoded + n + 32, "\r\n", 2);
    f->encoded_len = n + 34;
    memcpy(f->response, "$32\r\n", 5);
    memcpy(f->response + 5, f->payload, 32);
    memcpy(f->response + 37, "\r\n", 2);
    f->response_len = 39;
  }
  for (int encode = 1; encode >= 0; --encode) {
    uint64_t start, end;
    if (!codec_run(encode, 1000, fixtures) || !now_ns(&start) ||
        !codec_run(encode, iterations, fixtures) || !now_ns(&end) ||
        end <= start)
      return 1;
    if (printf(
            "{\"schema\":\"roc-redis-codec/v1\",\"implementation\":\"hiredis\","
            "\"runtime\":\"%s/"
            "hiredis-%s\",\"timer\":\"monotonic\",\"source\":\"%s\","
            "\"workload\":\"%s\",\"sample\":%" PRIu64 ",\"position\":%" PRIu64
            ",\"iterations\":%" PRIu64
            ",\"warmup\":1000,\"elapsed_ns\":%" PRIu64 ",\"validated\":true}\n",
            ROC_REDIS_C_VERSION, ROC_REDIS_HIREDIS_VERSION, argv[4],
            encode ? "encode_set" : "decode_bulk", sample, position, iterations,
            end - start) < 0)
      return 1;
  }
  return fflush(stdout) == 0 ? 0 : 1;
}
