#define _POSIX_C_SOURCE 200809L
#include <errno.h>
#include <hiredis/hiredis.h>
#include <inttypes.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>

#ifndef ROC_REDIS_C_VERSION
#define ROC_REDIS_C_VERSION "unmanaged"
#endif
#define STRINGIFY_INNER(value) #value
#define STRINGIFY(value) STRINGIFY_INNER(value)
#ifndef ROC_REDIS_HIREDIS_VERSION
#define ROC_REDIS_HIREDIS_VERSION                                              \
  STRINGIFY(HIREDIS_MAJOR)                                                     \
  "." STRINGIFY(HIREDIS_MINOR) "." STRINGIFY(HIREDIS_PATCH)
#endif

static const unsigned char payload[] = {
    0, 13, 10, 255, 128, 82,  111, 99,  45, 82, 101, 100, 105, 115, 0, 1,
    2, 3,  10, 13,  127, 128, 254, 255, 65, 66, 67,  120, 121, 122, 0, 255};
typedef struct {
  const char *host, *prefix, *source, *mode, *system, *os, *arch;
  uint64_t port, iterations, warmup, samples, batch, timeout, rotation,
      position;
} Config;

static int failure(const char *message) {
  fprintf(stderr, "benchmark failed: %s\n", message);
  return 0;
}

static int decimal(const char *text, uint64_t min, uint64_t max,
                   uint64_t *out) {
  if (!*text)
    return 0;
  uint64_t value = 0;
  for (const unsigned char *p = (const unsigned char *)text; *p; ++p) {
    if (*p < '0' || *p > '9')
      return 0;
    unsigned digit = *p - '0';
    if (value > (UINT64_MAX - digit) / 10)
      return 0;
    value = value * 10 + digit;
  }
  if (value < min || value > max)
    return 0;
  *out = value;
  return 1;
}

static int safe(const char *text, const char *extra, size_t max) {
  size_t size = strlen(text);
  if (!size || size > max)
    return 0;
  for (const unsigned char *p = (const unsigned char *)text; *p; ++p)
    if (!((*p >= 'a' && *p <= 'z') || (*p >= 'A' && *p <= 'Z') ||
          (*p >= '0' && *p <= '9') || strchr(extra, *p)))
      return 0;
  return 1;
}

static int parse(int argc, char **argv, Config *c) {
  *c = (Config){.host = "127.0.0.1",
                .prefix = "",
                .source = "unmanaged",
                .mode = "unmanaged",
                .system = "unmanaged",
                .os = "unmanaged",
                .arch = "unmanaged",
                .port = 6379,
                .iterations = 10000,
                .warmup = 1000,
                .samples = 5,
                .batch = 100,
                .timeout = 5000};
  if (argc % 2 != 1)
    return failure("expected --option value pairs");
  for (int i = 1; i < argc; i += 2) {
    const char *key = argv[i], *value = argv[i + 1];
    struct {
      const char *name;
      const char **target;
    } texts[] = {{"--host", &c->host},
                 {"--key-prefix", &c->prefix},
                 {"--nix-source-id", &c->source},
                 {"--build-mode", &c->mode},
                 {"--nix-system", &c->system},
                 {"--os", &c->os},
                 {"--arch", &c->arch}};
    struct {
      const char *name;
      uint64_t *target, min, max;
    } nums[] = {{"--port", &c->port, 1, 65535},
                {"--iterations", &c->iterations, 1, 1000000000},
                {"--warmup", &c->warmup, 0, 1000000000},
                {"--samples", &c->samples, 1, 1000},
                {"--pipeline-batch", &c->batch, 1, 65536},
                {"--timeout-ms", &c->timeout, 1, 300000},
                {"--order-rotation", &c->rotation, 0, 9},
                {"--subject-position", &c->position, 0, 5}};
    int found = 0;
    for (size_t j = 0; j < sizeof(texts) / sizeof(texts[0]); ++j)
      if (!strcmp(key, texts[j].name)) {
        *texts[j].target = value;
        found = 1;
        break;
      }
    for (size_t j = 0; !found && j < sizeof(nums) / sizeof(nums[0]); ++j)
      if (!strcmp(key, nums[j].name)) {
        if (!decimal(value, nums[j].min, nums[j].max, nums[j].target))
          return failure("invalid numeric option");
        found = 1;
      }
    if (!found)
      return failure("unknown option");
  }
  size_t hostlen = strlen(c->host);
  if (!hostlen || hostlen > 253)
    return failure("invalid host");
  for (size_t i = 0; i < hostlen; ++i)
    if ((unsigned char)c->host[i] < 33 || (unsigned char)c->host[i] > 126)
      return failure("invalid host");
  if (*c->prefix && !safe(c->prefix, "._:-", 128))
    return failure("invalid key prefix");
  const char *metadata[] = {c->source, c->mode, c->system, c->os, c->arch};
  for (size_t i = 0; i < sizeof(metadata) / sizeof(metadata[0]); ++i)
    if (!safe(metadata[i], "+._:-", 128))
      return failure("invalid metadata");
  return 1;
}

static redisContext *connect_redis(const Config *config) {
  struct timeval timeout = {.tv_sec = (time_t)(config->timeout / 1000),
                            .tv_usec =
                                (suseconds_t)((config->timeout % 1000) * 1000)};
  redisContext *c =
      redisConnectWithTimeout(config->host, (int)config->port, timeout);
  if (!c) {
    failure("connection allocation failed");
    return NULL;
  }
  if (c->err || redisSetTimeout(c, timeout) != REDIS_OK) {
    failure("connect or socket timeout setup failed");
    redisFree(c);
    return NULL;
  }
  return c;
}

static int text_reply(const redisReply *reply, int type, const void *value,
                      size_t length) {
  return reply && reply->type == type && reply->str && reply->len == length &&
         !memcmp(reply->str, value, length);
}

static redisReply *command(redisContext *c, int argc, const char **argv) {
  return redisCommandArgv(c, argc, argv, NULL);
}

static int set_key(redisContext *c, const char *key, const void *value,
                   size_t size, int nx) {
  const char *args[] = {"SET", key, value, "PX", "86400001", "NX"};
  size_t lengths[] = {3, strlen(key), size, 2, 8, 2};
  redisReply *reply = redisCommandArgv(c, nx ? 6 : 5, args, lengths);
  int okay = text_reply(reply, REDIS_REPLY_STATUS, "OK", 2);
  freeReplyObject(reply);
  return okay;
}

static int workload(redisContext *c, unsigned kind, uint64_t count,
                    uint64_t batch, const char *setkey, const char *incrkey,
                    const char *const *msetkeys, const char *hashkey,
                    const char *sgpipekey) {
  const char *ping[] = {"PING"};
  for (uint64_t done = 0; done < count;) {
    uint64_t current = (kind == 3 || kind == 6)
                           ? (batch < count - done ? batch : count - done)
                           : 1;
    if (kind == 3) {
      for (uint64_t i = 0; i < current; ++i)
        if (redisAppendCommandArgv(c, 1, ping, NULL) != REDIS_OK)
          return failure("pipeline append failed");
    } else if (kind == 6) {
      const char *setargs[] = {"SET", sgpipekey, (const char *)payload, "PX",
                               "86400001"};
      size_t setlens[] = {3, strlen(sgpipekey), sizeof(payload), 2, 8};
      const char *getargs[] = {"GET", sgpipekey};
      size_t getlens[] = {3, strlen(sgpipekey)};
      for (uint64_t i = 0; i < current; ++i)
        if (redisAppendCommandArgv(c, 5, setargs, setlens) != REDIS_OK ||
            redisAppendCommandArgv(c, 2, getargs, getlens) != REDIS_OK)
          return failure("pipeline append failed");
    }
    for (uint64_t i = 0; i < current; ++i) {
      redisReply *reply = NULL;
      int okay = 0;
      if (kind == 0) {
        reply = command(c, 1, ping);
        okay = text_reply(reply, REDIS_REPLY_STATUS, "PONG", 4);
      } else if (kind == 1) {
        if (!set_key(c, setkey, payload, sizeof(payload), 0))
          return failure("SET mismatch");
        const char *args[] = {"GET", setkey};
        reply = command(c, 2, args);
        okay = text_reply(reply, REDIS_REPLY_STRING, payload, sizeof(payload));
      } else if (kind == 2) {
        const char *args[] = {"INCR", incrkey};
        reply = command(c, 2, args);
        okay = reply && reply->type == REDIS_REPLY_INTEGER &&
               reply->integer == (long long)(done + 1);
      } else if (kind == 3) {
        void *received = NULL;
        if (redisGetReply(c, &received) != REDIS_OK)
          return failure("pipeline read failed");
        reply = received;
        okay = text_reply(reply, REDIS_REPLY_STATUS, "PONG", 4);
      } else if (kind == 4) {
        const char *msetargs[9] = {"MSET"};
        size_t msetlens[9] = {4};
        for (int k = 0; k < 4; ++k) {
          msetargs[1 + 2 * k] = msetkeys[k];
          msetlens[1 + 2 * k] = strlen(msetkeys[k]);
          msetargs[2 + 2 * k] = (const char *)payload;
          msetlens[2 + 2 * k] = sizeof(payload);
        }
        redisReply *mset = redisCommandArgv(c, 9, msetargs, msetlens);
        int mset_okay = text_reply(mset, REDIS_REPLY_STATUS, "OK", 2);
        freeReplyObject(mset);
        const char *mgetargs[5] = {"MGET"};
        size_t mgetlens[5] = {4};
        for (int k = 0; k < 4; ++k) {
          mgetargs[1 + k] = msetkeys[k];
          mgetlens[1 + k] = strlen(msetkeys[k]);
        }
        reply = redisCommandArgv(c, 5, mgetargs, mgetlens);
        okay = mset_okay && reply && reply->type == REDIS_REPLY_ARRAY &&
               reply->elements == 4;
        for (size_t k = 0; okay && k < 4; ++k)
          okay = text_reply(reply->element[k], REDIS_REPLY_STRING, payload,
                            sizeof(payload));
      } else if (kind == 5) {
        const char *hsetargs[] = {"HSET",    hashkey,
                                  "field:0", (const char *)payload,
                                  "field:1", (const char *)payload,
                                  "field:2", (const char *)payload};
        size_t hsetlens[] = {4, strlen(hashkey),  7, sizeof(payload),
                             7, sizeof(payload),   7, sizeof(payload)};
        redisReply *hset = redisCommandArgv(c, 8, hsetargs, hsetlens);
        int hset_okay =
            hset && hset->type == REDIS_REPLY_INTEGER && hset->integer >= 0;
        freeReplyObject(hset);
        const char *hgetargs[] = {"HGETALL", hashkey};
        size_t hgetlens[] = {7, strlen(hashkey)};
        reply = redisCommandArgv(c, 2, hgetargs, hgetlens);
        okay = hset_okay && reply && reply->type == REDIS_REPLY_ARRAY &&
               reply->elements == 6;
        for (size_t k = 1; okay && k < 6; k += 2)
          okay = text_reply(reply->element[k], REDIS_REPLY_STRING, payload,
                            sizeof(payload));
      } else {
        void *set_received = NULL;
        if (redisGetReply(c, &set_received) != REDIS_OK)
          return failure("pipeline read failed");
        redisReply *set_reply = set_received;
        int set_okay = text_reply(set_reply, REDIS_REPLY_STATUS, "OK", 2);
        freeReplyObject(set_reply);
        void *get_received = NULL;
        if (redisGetReply(c, &get_received) != REDIS_OK)
          return failure("pipeline read failed");
        reply = get_received;
        okay = set_okay &&
               text_reply(reply, REDIS_REPLY_STRING, payload, sizeof(payload));
      }
      freeReplyObject(reply);
      if (!okay)
        return failure("workload reply mismatch or transport failure");
    }
    done += current;
  }
  return 1;
}

static int now_ns(uint64_t *out) {
  struct timespec time;
  if (clock_gettime(CLOCK_MONOTONIC, &time) != 0 || time.tv_sec < 0 ||
      (uint64_t)time.tv_sec > UINT64_MAX / 1000000000)
    return failure("monotonic clock failed");
  *out = (uint64_t)time.tv_sec * 1000000000 + (uint64_t)time.tv_nsec;
  return 1;
}

static int run(const Config *config, redisContext *c, const char *version,
               const char *setkey, const char *incrkey,
               const char *const *msetkeys, const char *hashkey,
               const char *sgpipekey) {
  const char *hello[] = {"HELLO", "2"};
  redisReply *hello_reply = command(c, 2, hello);
  int resp2 = hello_reply && hello_reply->type == REDIS_REPLY_ARRAY;
  freeReplyObject(hello_reply);
  if (!resp2)
    return failure("RESP2 handshake failed");
  const char *id_args[] = {"CLIENT", "ID"};
  redisReply *direct = command(c, 2, id_args);
  if (!direct || direct->type != REDIS_REPLY_INTEGER) {
    freeReplyObject(direct);
    return failure("CLIENT ID failed");
  }
  long long id = direct->integer;
  freeReplyObject(direct);
  if (redisAppendCommandArgv(c, 2, id_args, NULL) != REDIS_OK)
    return failure("CLIENT ID append failed");
  void *received = NULL;
  if (redisGetReply(c, &received) != REDIS_OK)
    return failure("CLIENT ID pipeline failed");
  redisReply *pipelined = received;
  int same = pipelined && pipelined->type == REDIS_REPLY_INTEGER &&
             pipelined->integer == id;
  freeReplyObject(pipelined);
  if (!same)
    return failure("pipeline changed connection");
  const char *names[] = {"ping_sequential",       "set_get_sequential",
                         "incr_sequential",       "ping_pipeline",
                         "mset_mget_sequential",  "hash_roundtrip_sequential",
                         "set_get_pipeline"};
  for (unsigned kind = 0; kind < 7; ++kind) {
    for (uint64_t sample = 1; sample <= config->samples; ++sample) {
      if (kind == 2 && !set_key(c, incrkey, "0", 1, 0))
        return failure("counter initialization failed");
      if (!workload(c, kind, config->warmup, config->batch, setkey, incrkey,
                    msetkeys, hashkey, sgpipekey))
        return 0;
      if (kind == 2 && !set_key(c, incrkey, "0", 1, 0))
        return failure("counter reset failed");
      uint64_t start, end;
      if (!now_ns(&start) ||
          !workload(c, kind, config->iterations, config->batch, setkey, incrkey,
                    msetkeys, hashkey, sgpipekey) ||
          !now_ns(&end))
        return 0;
      if (end < start)
        return failure("monotonic clock moved backwards");
      uint64_t commands =
          config->iterations *
          ((kind == 1 || kind == 4 || kind == 5 || kind == 6) ? 2 : 1);
      uint64_t trips =
          (kind == 3 || kind == 6)
              ? (config->iterations + config->batch - 1) / config->batch
              : commands;
      // Every interpolated string has been restricted to safe ASCII;
      // no payload or arbitrary server text enters this JSON emitter.
      if (printf(
              "{\"schema\":\"roc-redis-benchmark/"
              "v2\",\"implementation\":\"c\",\"client\":\"hiredis\","
              "\"client_version\":\"%s\",\"runtime_version\":\"%s\",\"redis_"
              "version\":\"%s\","
              "\"timer\":\"monotonic\",\"workload\":\"%s\",\"sample\":%" PRIu64
              ",\"samples\":%" PRIu64 ","
              "\"iterations\":%" PRIu64 ",\"warmup\":%" PRIu64
              ",\"pipeline_batch\":%" PRIu64 ","
              "\"operation_count\":%" PRIu64 ",\"command_count\":%" PRIu64
              ",\"round_trip_count\":%" PRIu64 ","
              "\"elapsed_ns\":%" PRIu64 ",\"validated\":true,\"nix_source_id\":"
                                        "\"%s\",\"build_mode\":\"%s\","
              "\"nix_system\":\"%s\",\"os\":\"%s\",\"arch\":\"%s\",\"order_"
              "rotation\":%" PRIu64 ",\"subject_position\":%" PRIu64 "}\n",
              ROC_REDIS_HIREDIS_VERSION, ROC_REDIS_C_VERSION, version,
              names[kind], sample, config->samples, config->iterations,
              config->warmup, config->batch, config->iterations, commands,
              trips, end - start, config->source, config->mode, config->system,
              config->os, config->arch, config->rotation,
              config->position) < 0 ||
          fflush(stdout) != 0)
        return failure("result output failed");
    }
  }
  return 1;
}

static int redis_version(redisContext *c, char version[129]) {
  const char *args[] = {"INFO", "server"};
  redisReply *reply = command(c, 2, args);
  int okay = 0;
  if (reply && reply->type == REDIS_REPLY_STRING && reply->str) {
    // INFO is textual, but use its explicit length, not a search beyond it.
    const char prefix[] = "redis_version:";
    for (size_t i = 0; i + sizeof(prefix) - 1 <= reply->len; ++i) {
      if ((i == 0 || reply->str[i - 1] == '\n') &&
          !memcmp(reply->str + i, prefix, sizeof(prefix) - 1)) {
        size_t start = i + sizeof(prefix) - 1, end = start;
        while (end < reply->len && reply->str[end] != '\r' &&
               reply->str[end] != '\n')
          ++end;
        if (end - start > 0 && end - start <= 128) {
          memcpy(version, reply->str + start, end - start);
          version[end - start] = '\0';
          okay = safe(version, "+._-", 128);
        }
        break;
      }
    }
  }
  freeReplyObject(reply);
  return okay;
}

#ifndef BENCHMARK_TEST
int main(int argc, char **argv) {
  Config config;
  if (!parse(argc, argv, &config))
    return 2;
  char generated[129];
  if (!*config.prefix) {
    uint64_t time;
    if (!now_ns(&time))
      return 1;
    snprintf(generated, sizeof(generated), "roc-redis-bench:c:%ld:%" PRIu64,
             (long)getpid(), time);
    config.prefix = generated;
  }
  char lease[160], setkey[160], incrkey[160], version[129];
  char mset0[160], mset1[160], mset2[160], mset3[160], hashkey[160],
      sgpipekey[160];
  snprintf(lease, sizeof(lease), "%s:lease", config.prefix);
  snprintf(setkey, sizeof(setkey), "%s:set-get", config.prefix);
  snprintf(incrkey, sizeof(incrkey), "%s:incr", config.prefix);
  snprintf(mset0, sizeof(mset0), "%s:mset:0", config.prefix);
  snprintf(mset1, sizeof(mset1), "%s:mset:1", config.prefix);
  snprintf(mset2, sizeof(mset2), "%s:mset:2", config.prefix);
  snprintf(mset3, sizeof(mset3), "%s:mset:3", config.prefix);
  snprintf(hashkey, sizeof(hashkey), "%s:hash", config.prefix);
  snprintf(sgpipekey, sizeof(sgpipekey), "%s:sg-pipe", config.prefix);
  const char *msetkeys[4] = {mset0, mset1, mset2, mset3};
  redisContext *c = connect_redis(&config);
  if (!c)
    return 1;
  if (!redis_version(c, version) ||
      !set_key(c, lease, "benchmark-lease", 15, 1)) {
    failure("version lookup or exclusive lease acquisition failed; no workload "
            "keys changed");
    redisFree(c);
    return 1;
  }
  int okay =
      run(&config, c, version, setkey, incrkey, msetkeys, hashkey, sgpipekey);
  redisFree(c);
  c = connect_redis(&config);
  if (!c)
    return 1;
  const char *args[] = {"DEL",  setkey, incrkey,   lease,     mset0,
                        mset1,  mset2,  mset3,     hashkey,   sgpipekey};
  redisReply *reply = command(c, 10, args);
  if (!reply || reply->type != REDIS_REPLY_INTEGER || reply->integer < 0 ||
      reply->integer > 9) {
    failure("cleanup failed; leased keys retain their expiry");
    okay = 0;
  }
  freeReplyObject(reply);
  redisFree(c);
  return okay ? 0 : 1;
}
#endif
