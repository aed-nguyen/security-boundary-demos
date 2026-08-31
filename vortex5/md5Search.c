// Searches the five-character alphanumeric space with a threaded MD5 implementation.

#include <errno.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ROTATE_LEFT(value, shift) (((value) << (shift)) | ((value) >> (32 - (shift))))
#define ROUND_F(x, y, z) (((x) & (y)) | (~(x) & (z)))
#define ROUND_G(x, y, z) (((x) & (z)) | ((y) & ~(z)))
#define ROUND_H(x, y, z) ((x) ^ (y) ^ (z))
#define ROUND_I(x, y, z) ((y) ^ ((x) | ~(z)))
#define STEP(function, a, b, c, d, x, constant, shift) \
  (a) += function((b), (c), (d)) + (x) + (constant); \
  (a) = ROTATE_LEFT((a), (shift)) + (b)

static const char ALPHABET[] =
  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
static const uint64_t SEARCH_SIZE = 916132832ULL;
static atomic_bool hasResult = false;
static char result[6];
static uint32_t targetWords[4];

typedef struct {
  uint32_t threadId;
  uint32_t threadCount;
} ThreadData;

static int hexNibble(char character);
static bool parseTarget(const char *text);
static bool parseThreadCount(const char *text, uint32_t *output);
static bool matchesTarget(const char candidate[5]);
static void *search(void *rawData);

int
main(int argc, char *argv[])
{
  uint32_t threadCount = 10;
  if (argc < 2 || !parseTarget(argv[1]) ||
      (argc >= 3 && !parseThreadCount(argv[2], &threadCount))) {
    fprintf(stderr, "usage: md5-search TARGET_MD5_HEX [THREAD_COUNT]\n");
    return 2;
  }

  pthread_t *threads = calloc(threadCount, sizeof(*threads));
  ThreadData *data = calloc(threadCount, sizeof(*data));
  if (threads == NULL || data == NULL) {
    fprintf(stderr, "Failed to allocate thread state\n");
    free(threads);
    free(data);
    return 2;
  }

  uint32_t createdCount = 0;
  for (uint32_t index = 0; index < threadCount; index++) {
    data[index] = (ThreadData){.threadId = index, .threadCount = threadCount};
    int resultCode = pthread_create(&threads[index], NULL, search, &data[index]);
    if (resultCode != 0) {
      fprintf(stderr, "Failed to create search thread %u: %s\n",
              index, strerror(resultCode));
      atomic_store_explicit(&hasResult, true, memory_order_release);
      break;
    }
    createdCount++;
  }

  bool hasJoinError = false;
  for (uint32_t index = 0; index < createdCount; index++) {
    int resultCode = pthread_join(threads[index], NULL);
    if (resultCode != 0) {
      fprintf(stderr, "Failed to join search thread %u: %s\n",
              index, strerror(resultCode));
      hasJoinError = true;
    }
  }

  free(threads);
  free(data);
  if (createdCount != threadCount || hasJoinError) {
    return 2;
  }
  if (!atomic_load_explicit(&hasResult, memory_order_acquire)) {
    return 1;
  }

  puts(result);
  return 0;
}

static int
hexNibble(char character)
{
  if (character >= '0' && character <= '9') {
    return character - '0';
  }
  if (character >= 'a' && character <= 'f') {
    return character - 'a' + 10;
  }
  if (character >= 'A' && character <= 'F') {
    return character - 'A' + 10;
  }
  return -1;
}

static bool
parseTarget(const char *text)
{
  if (strlen(text) != 32) {
    return false;
  }

  uint8_t bytes[16];
  for (int index = 0; index < 16; index++) {
    int high = hexNibble(text[index * 2]);
    int low = hexNibble(text[index * 2 + 1]);
    if (high < 0 || low < 0) {
      return false;
    }
    bytes[index] = (uint8_t)((high << 4) | low);
  }

  for (int index = 0; index < 4; index++) {
    int offset = index * 4;
    targetWords[index] = (uint32_t)bytes[offset]
      | ((uint32_t)bytes[offset + 1] << 8)
      | ((uint32_t)bytes[offset + 2] << 16)
      | ((uint32_t)bytes[offset + 3] << 24);
  }
  return true;
}

static bool
parseThreadCount(const char *text, uint32_t *output)
{
  char *end = NULL;
  errno = 0;
  unsigned long value = strtoul(text, &end, 10);
  if (errno != 0 || *text == '\0' || *end != '\0' || value < 1 || value > 256) {
    return false;
  }
  *output = (uint32_t)value;
  return true;
}

static void *
search(void *rawData)
{
  ThreadData *data = rawData;

  for (uint64_t index = data->threadId;
       index < SEARCH_SIZE && !atomic_load_explicit(&hasResult, memory_order_relaxed);
       index += data->threadCount) {
    uint64_t value = index;
    char candidate[5];

    for (int position = 4; position >= 0; position--) {
      candidate[position] = ALPHABET[value % 62];
      value /= 62;
    }

    if (matchesTarget(candidate)) {
      bool expected = false;
      if (atomic_compare_exchange_strong_explicit(
            &hasResult,
            &expected,
            true,
            memory_order_acq_rel,
            memory_order_relaxed)) {
        memcpy(result, candidate, 5);
        result[5] = '\0';
      }
      break;
    }
  }

  return NULL;
}

static bool
matchesTarget(const char candidate[5])
{
  uint32_t words[16] = {0};
  uint32_t a = 0x67452301;
  uint32_t b = 0xefcdab89;
  uint32_t c = 0x98badcfe;
  uint32_t d = 0x10325476;
  uint32_t savedA = a;
  uint32_t savedB = b;
  uint32_t savedC = c;
  uint32_t savedD = d;

  memcpy(words, candidate, 5);
  ((unsigned char *)words)[5] = 0x80;
  words[14] = 40;

  STEP(ROUND_F, a, b, c, d, words[0], 0xd76aa478, 7);
  STEP(ROUND_F, d, a, b, c, words[1], 0xe8c7b756, 12);
  STEP(ROUND_F, c, d, a, b, words[2], 0x242070db, 17);
  STEP(ROUND_F, b, c, d, a, words[3], 0xc1bdceee, 22);
  STEP(ROUND_F, a, b, c, d, words[4], 0xf57c0faf, 7);
  STEP(ROUND_F, d, a, b, c, words[5], 0x4787c62a, 12);
  STEP(ROUND_F, c, d, a, b, words[6], 0xa8304613, 17);
  STEP(ROUND_F, b, c, d, a, words[7], 0xfd469501, 22);
  STEP(ROUND_F, a, b, c, d, words[8], 0x698098d8, 7);
  STEP(ROUND_F, d, a, b, c, words[9], 0x8b44f7af, 12);
  STEP(ROUND_F, c, d, a, b, words[10], 0xffff5bb1, 17);
  STEP(ROUND_F, b, c, d, a, words[11], 0x895cd7be, 22);
  STEP(ROUND_F, a, b, c, d, words[12], 0x6b901122, 7);
  STEP(ROUND_F, d, a, b, c, words[13], 0xfd987193, 12);
  STEP(ROUND_F, c, d, a, b, words[14], 0xa679438e, 17);
  STEP(ROUND_F, b, c, d, a, words[15], 0x49b40821, 22);

  STEP(ROUND_G, a, b, c, d, words[1], 0xf61e2562, 5);
  STEP(ROUND_G, d, a, b, c, words[6], 0xc040b340, 9);
  STEP(ROUND_G, c, d, a, b, words[11], 0x265e5a51, 14);
  STEP(ROUND_G, b, c, d, a, words[0], 0xe9b6c7aa, 20);
  STEP(ROUND_G, a, b, c, d, words[5], 0xd62f105d, 5);
  STEP(ROUND_G, d, a, b, c, words[10], 0x02441453, 9);
  STEP(ROUND_G, c, d, a, b, words[15], 0xd8a1e681, 14);
  STEP(ROUND_G, b, c, d, a, words[4], 0xe7d3fbc8, 20);
  STEP(ROUND_G, a, b, c, d, words[9], 0x21e1cde6, 5);
  STEP(ROUND_G, d, a, b, c, words[14], 0xc33707d6, 9);
  STEP(ROUND_G, c, d, a, b, words[3], 0xf4d50d87, 14);
  STEP(ROUND_G, b, c, d, a, words[8], 0x455a14ed, 20);
  STEP(ROUND_G, a, b, c, d, words[13], 0xa9e3e905, 5);
  STEP(ROUND_G, d, a, b, c, words[2], 0xfcefa3f8, 9);
  STEP(ROUND_G, c, d, a, b, words[7], 0x676f02d9, 14);
  STEP(ROUND_G, b, c, d, a, words[12], 0x8d2a4c8a, 20);

  STEP(ROUND_H, a, b, c, d, words[5], 0xfffa3942, 4);
  STEP(ROUND_H, d, a, b, c, words[8], 0x8771f681, 11);
  STEP(ROUND_H, c, d, a, b, words[11], 0x6d9d6122, 16);
  STEP(ROUND_H, b, c, d, a, words[14], 0xfde5380c, 23);
  STEP(ROUND_H, a, b, c, d, words[1], 0xa4beea44, 4);
  STEP(ROUND_H, d, a, b, c, words[4], 0x4bdecfa9, 11);
  STEP(ROUND_H, c, d, a, b, words[7], 0xf6bb4b60, 16);
  STEP(ROUND_H, b, c, d, a, words[10], 0xbebfbc70, 23);
  STEP(ROUND_H, a, b, c, d, words[13], 0x289b7ec6, 4);
  STEP(ROUND_H, d, a, b, c, words[0], 0xeaa127fa, 11);
  STEP(ROUND_H, c, d, a, b, words[3], 0xd4ef3085, 16);
  STEP(ROUND_H, b, c, d, a, words[6], 0x04881d05, 23);
  STEP(ROUND_H, a, b, c, d, words[9], 0xd9d4d039, 4);
  STEP(ROUND_H, d, a, b, c, words[12], 0xe6db99e5, 11);
  STEP(ROUND_H, c, d, a, b, words[15], 0x1fa27cf8, 16);
  STEP(ROUND_H, b, c, d, a, words[2], 0xc4ac5665, 23);

  STEP(ROUND_I, a, b, c, d, words[0], 0xf4292244, 6);
  STEP(ROUND_I, d, a, b, c, words[7], 0x432aff97, 10);
  STEP(ROUND_I, c, d, a, b, words[14], 0xab9423a7, 15);
  STEP(ROUND_I, b, c, d, a, words[5], 0xfc93a039, 21);
  STEP(ROUND_I, a, b, c, d, words[12], 0x655b59c3, 6);
  STEP(ROUND_I, d, a, b, c, words[3], 0x8f0ccc92, 10);
  STEP(ROUND_I, c, d, a, b, words[10], 0xffeff47d, 15);
  STEP(ROUND_I, b, c, d, a, words[1], 0x85845dd1, 21);
  STEP(ROUND_I, a, b, c, d, words[8], 0x6fa87e4f, 6);
  STEP(ROUND_I, d, a, b, c, words[15], 0xfe2ce6e0, 10);
  STEP(ROUND_I, c, d, a, b, words[6], 0xa3014314, 15);
  STEP(ROUND_I, b, c, d, a, words[13], 0x4e0811a1, 21);
  STEP(ROUND_I, a, b, c, d, words[4], 0xf7537e82, 6);
  STEP(ROUND_I, d, a, b, c, words[11], 0xbd3af235, 10);
  STEP(ROUND_I, c, d, a, b, words[2], 0x2ad7d2bb, 15);
  STEP(ROUND_I, b, c, d, a, words[9], 0xeb86d391, 21);

  return a + savedA == targetWords[0]
    && b + savedB == targetWords[1]
    && c + savedC == targetWords[2]
    && d + savedD == targetWords[3];
}
