#!/usr/bin/env python3
"""Recover a hidden MD5 digest from bit-similarity scores."""

from __future__ import annotations

import argparse
import hashlib
import subprocess
import sys
from collections.abc import Iterable, Sequence

import numpy as np


def main() -> None:
  parser = argparse.ArgumentParser()
  parser.add_argument('--target', required=True)
  parser.add_argument('--queries', type=int, default=160)
  parser.add_argument('--holdouts', type=int, default=8)
  args = parser.parse_args()

  if args.queries < 128:
    raise ValueError('Failed to recover digest: at least 128 queries are required')
  if args.holdouts < 1:
    raise ValueError('Failed to recover digest: at least one holdout is required')

  challenge = subprocess.Popen(
    [args.target],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
  )

  try:
    rows = []
    scores = []
    for index in range(args.queries):
      candidate = buildProbe(index)
      score = queryScore(challenge, candidate)
      rows.append(digestSigns(hashlib.md5(candidate).digest()))
      scores.append(score)

    target = recoverTarget(rows, scores)
    ensureHoldouts(challenge, target, args.queries, args.holdouts)

    print(f'TARGET {target.hex()} holdouts={args.holdouts}', flush=True)
    for line in sys.stdin:
      candidate = bytes.fromhex(line.strip())
      if len(candidate) != 16 or 0 in candidate:
        print('REJECT candidate requirements', flush=True)
        continue

      result = queryRaw(challenge, candidate)
      if result == b'WON!':
        print('ACCEPTED', flush=True)
        return
      if len(result) != 4:
        raise RuntimeError('Failed to query score oracle: response has the wrong length')
      print(f'SCORE {int.from_bytes(result, "little", signed=True)}', flush=True)
  finally:
    if challenge.poll() is None:
      challenge.terminate()
      try:
        challenge.wait(timeout=5)
      except subprocess.TimeoutExpired:
        challenge.kill()
        challenge.wait(timeout=5)


def recoverTarget(rows: Sequence[Sequence[int]], scores: Sequence[int]) -> bytes:
  if len(rows) != len(scores) or not rows:
    raise ValueError('Failed to recover digest: equations are missing or unpaired')

  matrix = np.asarray(rows, dtype=float)
  values = np.asarray([2 * score - 128 for score in scores], dtype=float)
  solution, _, rank, _ = np.linalg.lstsq(matrix, values, rcond=None)

  if rank != 128:
    raise RuntimeError(f'Failed to recover digest: matrix rank was {rank}')

  targetSigns = np.where(solution >= 0, 1, -1)
  for row, expected in zip(matrix, values):
    if int(np.dot(row, targetSigns)) != int(expected):
      raise RuntimeError('Failed to recover digest: an equation did not verify')

  return signsToBytes(targetSigns)


def ensureHoldouts(
  challenge: subprocess.Popen[bytes],
  target: bytes,
  firstIndex: int,
  holdoutCount: int,
) -> None:
  for index in range(firstIndex, firstIndex + holdoutCount):
    candidate = buildProbe(index)
    actual = queryScore(challenge, candidate)
    expected = matchingBitCount(hashlib.md5(candidate).digest(), target)
    if actual != expected:
      raise RuntimeError(f'Failed to verify digest: holdout {index} did not match')


def queryScore(challenge: subprocess.Popen[bytes], candidate: bytes) -> int:
  result = queryRaw(challenge, candidate)
  if len(result) != 4:
    raise RuntimeError('Failed to query score oracle: response has the wrong length')

  score = int.from_bytes(result, 'little', signed=True)
  if not 0 <= score <= 128:
    raise RuntimeError(f'Failed to query score oracle: score {score} is outside 0 to 128')
  return score


def queryRaw(challenge: subprocess.Popen[bytes], candidate: bytes) -> bytes:
  if challenge.stdin is None or challenge.stdout is None:
    raise RuntimeError('Failed to query score oracle: process pipes are unavailable')

  challenge.stdin.write(candidate)
  challenge.stdin.flush()
  return readExact(challenge.stdout, 4)


def readExact(stream, byteCount: int) -> bytes:
  output = bytearray()
  while len(output) < byteCount:
    chunk = stream.read(byteCount - len(output))
    if not chunk:
      break
    output.extend(chunk)
  return bytes(output)


def buildProbe(index: int) -> bytes:
  candidate = f'{index:016x}'.encode('ascii')
  if len(candidate) != 16:
    raise ValueError('Failed to build probe: index exceeds the 16-byte format')
  return candidate


def digestSigns(digest: bytes) -> list[int]:
  if len(digest) != 16:
    raise ValueError('Failed to convert digest: MD5 digest must be 16 bytes')
  return [
    1 if digest[bit // 8] & (1 << (bit % 8)) else -1
    for bit in range(128)
  ]


def signsToBytes(signs: Iterable[int]) -> bytes:
  signList = list(signs)
  if len(signList) != 128 or any(value not in (-1, 1) for value in signList):
    raise ValueError('Failed to convert signs: expected 128 values of -1 or 1')

  output = bytearray(16)
  for bit, value in enumerate(signList):
    if value == 1:
      output[bit // 8] |= 1 << (bit % 8)
  return bytes(output)


def matchingBitCount(left: bytes, right: bytes) -> int:
  if len(left) != len(right):
    raise ValueError('Failed to compare digests: lengths do not match')
  return len(left) * 8 - sum(
    (leftByte ^ rightByte).bit_count()
    for leftByte, rightByte in zip(left, right)
  )


if __name__ == '__main__':
  main()
