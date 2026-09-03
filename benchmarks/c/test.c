#define BENCHMARK_TEST
#include "benchmark.c"
#include <assert.h>

int main(void) {
  uint64_t value;
  assert(decimal("18446744073709551615", 0, UINT64_MAX, &value) &&
         value == UINT64_MAX);
  const char *invalid[] = {"",    "+1",   "-1",
                           "1_0", "0x10", "18446744073709551616"};
  for (size_t i = 0; i < sizeof(invalid) / sizeof(invalid[0]); ++i)
    assert(!decimal(invalid[i], 0, UINT64_MAX, &value));
  assert(!decimal("0", 1, 5, &value));
  assert(!decimal("6", 1, 5, &value));
  assert(safe("prefix:123", ":", 128));
  assert(!safe("unsafe/123", ":", 128));
  Config config;
  char *args[] = {"benchmark", "--order-rotation", "9", "--subject-position",
                  "5",         "--warmup",         "0"};
  assert(parse(7, args, &config));
  assert(config.rotation == 9 && config.position == 5 && config.warmup == 0);
  redisReply reply = {.type = REDIS_REPLY_STRING,
                      .str = (char *)payload,
                      .len = sizeof(payload)};
  assert(text_reply(&reply, REDIS_REPLY_STRING, payload, sizeof(payload)));
  assert(!text_reply(&reply, REDIS_REPLY_STATUS, payload, sizeof(payload)));
  assert(!text_reply(NULL, REDIS_REPLY_STRING, payload, sizeof(payload)));
  return 0;
}
