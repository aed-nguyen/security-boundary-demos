// Runs the Vortex 16 MD5 similarity search on Apple's Metal interface.

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct __attribute__((aligned(16))) {
  uint32_t target[4];
  uint64_t start;
  uint32_t threshold;
  uint32_t padding;
} SearchParameters;

static const NSUInteger BATCH_SIZE = 1 << 24;
static const uint64_t SEARCH_SIZE = 17878103347812890625ULL;

static int hexNibble(char character);
static BOOL parseTarget(const char *text, uint8_t output[16]);
static BOOL parseThreshold(const char *text, uint32_t *output);
static uint32_t littleEndianWord(const uint8_t bytes[16], int offset);
static void printCandidate(uint64_t candidateNumber);

int
main(int argc, const char *argv[])
{
  @autoreleasepool {
    uint8_t targetBytes[16];
    uint32_t threshold = 100;
    if (argc < 2 || !parseTarget(argv[1], targetBytes) ||
        (argc >= 3 && !parseThreshold(argv[2], &threshold))) {
      fprintf(stderr, "usage: vortex16-gpu TARGET_MD5_HEX [THRESHOLD] [KERNEL_PATH]\n");
      return 2;
    }

    const char *kernelPath = argc >= 4 ? argv[3] : "kernel.metal";
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (device == nil) {
      fprintf(stderr, "Failed to start Metal search: no Metal device is available\n");
      return 1;
    }

    NSError *error = nil;
    NSString *path = [NSString stringWithUTF8String:kernelPath];
    NSString *source = [NSString stringWithContentsOfFile:path
                                                 encoding:NSUTF8StringEncoding
                                                    error:&error];
    if (source == nil) {
      fprintf(stderr, "Failed to read Metal kernel: %s\n", error.localizedDescription.UTF8String);
      return 1;
    }

    id<MTLLibrary> library = [device newLibraryWithSource:source options:nil error:&error];
    if (library == nil) {
      fprintf(stderr, "Failed to compile Metal kernel: %s\n", error.localizedDescription.UTF8String);
      return 1;
    }

    id<MTLFunction> function = [library newFunctionWithName:@"searchHashes"];
    if (function == nil) {
      fprintf(stderr, "Failed to load Metal kernel: searchHashes was not found\n");
      return 1;
    }

    id<MTLComputePipelineState> pipeline =
      [device newComputePipelineStateWithFunction:function error:&error];
    id<MTLCommandQueue> queue = [device newCommandQueue];
    if (pipeline == nil || queue == nil) {
      fprintf(stderr, "Failed to prepare Metal search: %s\n", error.localizedDescription.UTF8String);
      return 1;
    }

    SearchParameters parameters = {0};
    for (int wordIndex = 0; wordIndex < 4; wordIndex++) {
      parameters.target[wordIndex] = littleEndianWord(targetBytes, wordIndex * 4);
    }
    parameters.threshold = threshold;

    const NSUInteger maxThreadCount = pipeline.maxTotalThreadsPerThreadgroup;
    const NSUInteger groupSize = maxThreadCount < 256 ? maxThreadCount : 256;
    uint64_t testedCount = 0;
    CFAbsoluteTime startedAt = CFAbsoluteTimeGetCurrent();

    while (testedCount < SEARCH_SIZE) {
      parameters.start = testedCount;
      uint64_t remainingCount = SEARCH_SIZE - testedCount;
      NSUInteger batchCount = remainingCount < BATCH_SIZE
        ? (NSUInteger)remainingCount
        : BATCH_SIZE;
      uint32_t emptyIndex = UINT32_MAX;

      id<MTLBuffer> parameterBuffer = [device newBufferWithBytes:&parameters
                                                          length:sizeof(parameters)
                                                         options:MTLResourceStorageModeShared];
      id<MTLBuffer> resultBuffer = [device newBufferWithBytes:&emptyIndex
                                                       length:sizeof(emptyIndex)
                                                      options:MTLResourceStorageModeShared];
      if (parameterBuffer == nil || resultBuffer == nil) {
        fprintf(stderr, "Failed to allocate Metal buffers\n");
        return 1;
      }

      id<MTLCommandBuffer> commandBuffer = [queue commandBuffer];
      id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
      [encoder setComputePipelineState:pipeline];
      [encoder setBuffer:parameterBuffer offset:0 atIndex:0];
      [encoder setBuffer:resultBuffer offset:0 atIndex:1];
      [encoder dispatchThreads:MTLSizeMake(batchCount, 1, 1)
         threadsPerThreadgroup:MTLSizeMake(groupSize, 1, 1)];
      [encoder endEncoding];
      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      if (commandBuffer.error != nil) {
        fprintf(stderr, "Failed to run Metal search: %s\n",
                commandBuffer.error.localizedDescription.UTF8String);
        return 1;
      }

      uint32_t foundIndex = *(uint32_t *)resultBuffer.contents;
      if (foundIndex != UINT32_MAX) {
        printCandidate(testedCount + foundIndex);
        return 0;
      }

      testedCount += batchCount;
      double elapsed = CFAbsoluteTimeGetCurrent() - startedAt;
      fprintf(stderr, "tested=%llu rate=%.1f Mhash/s\n",
              (unsigned long long)testedCount,
              testedCount / elapsed / 1000000.0);
    }

    fprintf(stderr, "No candidate met the requested threshold\n");
    return 1;
  }
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

static BOOL
parseTarget(const char *text, uint8_t output[16])
{
  if (strlen(text) != 32) {
    return NO;
  }

  for (int index = 0; index < 16; index++) {
    int high = hexNibble(text[index * 2]);
    int low = hexNibble(text[index * 2 + 1]);
    if (high < 0 || low < 0) {
      return NO;
    }
    output[index] = (uint8_t)((high << 4) | low);
  }
  return YES;
}

static BOOL
parseThreshold(const char *text, uint32_t *output)
{
  char *end = NULL;
  unsigned long value = strtoul(text, &end, 10);
  if (*text == '\0' || *end != '\0' || value > 128) {
    return NO;
  }
  *output = (uint32_t)value;
  return YES;
}

static uint32_t
littleEndianWord(const uint8_t bytes[16], int offset)
{
  return (uint32_t)bytes[offset]
    | ((uint32_t)bytes[offset + 1] << 8)
    | ((uint32_t)bytes[offset + 2] << 16)
    | ((uint32_t)bytes[offset + 3] << 24);
}

static void
printCandidate(uint64_t candidateNumber)
{
  uint8_t candidate[16];
  for (int index = 0; index < 8; index++) {
    candidate[index] = (uint8_t)((candidateNumber % 255) + 1);
    candidateNumber /= 255;
  }
  memcpy(candidate + 8, "VORTEX16", 8);

  for (int index = 0; index < 16; index++) {
    printf("%02x", candidate[index]);
  }
  printf("\n");
}
