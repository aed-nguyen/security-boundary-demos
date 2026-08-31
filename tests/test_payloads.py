"""Tests the parameterized Manpage payload builders."""

from __future__ import annotations

import struct
import unittest

from manpage.payloads import buildStackPayload, buildWumpusPayload


class PayloadTests(unittest.TestCase):
  def testBuildsStackPayload(self) -> None:
    payload = buildStackPayload(8, 0x11223344, b'\x90\xcc')

    self.assertEqual(payload, b'A' * 8 + struct.pack('<I', 0x11223344) + b'\x90\xcc')

  def testPlacesControlBytesInsideWumpusSpray(self) -> None:
    payload = buildWumpusPayload(20, 10, 0x11223344, b'\x90\xcc', b'B')

    self.assertEqual(len(payload), 20)
    self.assertEqual(payload[:10], b'B' * 10)
    self.assertEqual(payload[10:14], struct.pack('<I', 0x11223344))
    self.assertEqual(payload[14:16], b'\x90\xcc')
    self.assertEqual(payload[16:], b'B' * 4)

  def testRejectsControlBytesPastSpray(self) -> None:
    with self.assertRaisesRegex(ValueError, 'control bytes exceed'):
      buildWumpusPayload(8, 4, 0x11223344, b'\x90')

  def testRejectsOutOfRangeGadget(self) -> None:
    with self.assertRaisesRegex(ValueError, 'fit in 32 bits'):
      buildStackPayload(4, 0x100000000, b'\x90')


if __name__ == '__main__':
  unittest.main()

