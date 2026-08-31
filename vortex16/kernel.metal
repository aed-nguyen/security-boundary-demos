// Searches 16-byte candidates for an MD5 digest close to the recovered target.

#include <metal_stdlib>
using namespace metal;

struct SearchParameters {
  uint4 target;
  ulong start;
  uint threshold;
  uint padding;
};

constant uint SHIFTS[64] = {
  7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
  5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
  4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
  6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
};

constant uint CONSTANTS[64] = {
  0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
  0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
  0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
  0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
  0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
  0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
  0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
  0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
  0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
  0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
  0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
  0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
  0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
  0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
  0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
  0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
};

inline uint rotateLeft(uint value, uint amount) {
  return (value << amount) | (value >> (32 - amount));
}

kernel void searchHashes(
  constant SearchParameters &parameters [[buffer(0)]],
  device atomic_uint &foundIndex [[buffer(1)]],
  uint gridIndex [[thread_position_in_grid]]
) {
  ulong candidateNumber = parameters.start + ulong(gridIndex);
  uchar bytes[16];
  for (uint index = 0; index < 8; index++) {
    bytes[index] = uchar((candidateNumber % 255) + 1);
    candidateNumber /= 255;
  }
  bytes[8] = 'V';
  bytes[9] = 'O';
  bytes[10] = 'R';
  bytes[11] = 'T';
  bytes[12] = 'E';
  bytes[13] = 'X';
  bytes[14] = '1';
  bytes[15] = '6';

  uint message[16] = {0};
  for (uint wordIndex = 0; wordIndex < 4; wordIndex++) {
    uint byteIndex = wordIndex * 4;
    message[wordIndex] = uint(bytes[byteIndex])
      | (uint(bytes[byteIndex + 1]) << 8)
      | (uint(bytes[byteIndex + 2]) << 16)
      | (uint(bytes[byteIndex + 3]) << 24);
  }
  message[4] = 0x80;
  message[14] = 128;

  uint initialA = 0x67452301;
  uint initialB = 0xefcdab89;
  uint initialC = 0x98badcfe;
  uint initialD = 0x10325476;
  uint a = initialA;
  uint b = initialB;
  uint c = initialC;
  uint d = initialD;

  for (uint roundIndex = 0; roundIndex < 64; roundIndex++) {
    uint functionValue;
    uint messageIndex;
    if (roundIndex < 16) {
      functionValue = (b & c) | ((~b) & d);
      messageIndex = roundIndex;
    } else if (roundIndex < 32) {
      functionValue = (d & b) | ((~d) & c);
      messageIndex = (5 * roundIndex + 1) % 16;
    } else if (roundIndex < 48) {
      functionValue = b ^ c ^ d;
      messageIndex = (3 * roundIndex + 5) % 16;
    } else {
      functionValue = c ^ (b | (~d));
      messageIndex = (7 * roundIndex) % 16;
    }

    uint mixed = a + functionValue + CONSTANTS[roundIndex] + message[messageIndex];
    uint previousD = d;
    d = c;
    c = b;
    b = b + rotateLeft(mixed, SHIFTS[roundIndex]);
    a = previousD;
  }

  uint4 digest = uint4(a + initialA, b + initialB, c + initialC, d + initialD);
  uint differentBitCount = popcount(digest.x ^ parameters.target.x)
    + popcount(digest.y ^ parameters.target.y)
    + popcount(digest.z ^ parameters.target.z)
    + popcount(digest.w ^ parameters.target.w);
  if (128 - differentBitCount >= parameters.threshold) {
    uint expected = 0xffffffffu;
    atomic_compare_exchange_weak_explicit(
      &foundIndex,
      &expected,
      gridIndex,
      memory_order_relaxed,
      memory_order_relaxed
    );
  }
}
