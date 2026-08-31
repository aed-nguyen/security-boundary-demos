"""Tests the Vortex 16 score-system recovery."""

from __future__ import annotations

import hashlib
import unittest

from vortex16.oracle import digestSigns, matchingBitCount, recoverTarget, signsToBytes


class OracleTests(unittest.TestCase):
  def testRoundTripDigestSigns(self) -> None:
    digest = bytes.fromhex('00112233445566778899aabbccddeeff')

    self.assertEqual(signsToBytes(digestSigns(digest)), digest)

  def testMatchingBitCount(self) -> None:
    left = bytes.fromhex('00ff')
    right = bytes.fromhex('0ff0')

    self.assertEqual(matchingBitCount(left, right), 8)

  def testRecoversTargetFromIndependentScores(self) -> None:
    target = bytes.fromhex('00112233445566778899aabbccddeeff')
    rows = []
    scores = []

    for index in range(160):
      digest = hashlib.md5(f'probe-{index}'.encode('ascii')).digest()
      rows.append(digestSigns(digest))
      scores.append(matchingBitCount(digest, target))

    self.assertEqual(recoverTarget(rows, scores), target)

  def testRejectsRankDeficientEquations(self) -> None:
    row = digestSigns(bytes(16))

    with self.assertRaisesRegex(RuntimeError, 'matrix rank'):
      recoverTarget([row] * 128, [128] * 128)


if __name__ == '__main__':
  unittest.main()

