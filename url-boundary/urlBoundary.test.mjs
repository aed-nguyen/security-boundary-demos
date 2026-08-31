// Verifies that URL trust uses the parsed destination instead of a string prefix.

import assert from 'node:assert/strict';
import test from 'node:test';

import { ensureTrustedUrl, isTrustedUrlUnsafe } from './urlBoundary.mjs';

test('accepts the exact trusted origin', () => {
  const val = 'https://trusted.example/reports/record-100';

  assert.equal(isTrustedUrlUnsafe(val), true);
  assert.equal(ensureTrustedUrl(val), val);
});

test('rejects a user-information prefix that fools the unsafe check', () => {
  const val = 'https://trusted.example@external.example/reports/record-100';

  assert.equal(isTrustedUrlUnsafe(val), true);
  assert.throws(
    () => ensureTrustedUrl(val),
    /destination is outside the allowed origin/
  );
});

test('rejects a subdomain that only begins with the trusted name', () => {
  const val = 'https://trusted.example.external.example/reports/record-100';

  assert.equal(isTrustedUrlUnsafe(val), true);
  assert.throws(
    () => ensureTrustedUrl(val),
    /destination is outside the allowed origin/
  );
});

