// Verifies that knowing an object identifier does not grant access to it.

import assert from 'node:assert/strict';
import test from 'node:test';

import { getRecordForOwner, getRecordUnsafe } from './objectAuthorization.mjs';

test('returns an owned record', () => {
  const record = getRecordForOwner('record-100', 'account-a');

  assert.equal(record.id, 'record-100');
  assert.equal(record.ownerId, 'account-a');
});

test('shows why identifier-only lookup is unsafe', () => {
  const record = getRecordUnsafe('record-200');

  assert.equal(record.ownerId, 'account-b');
});

test('rejects access to a record owned by another account', () => {
  assert.throws(
    () => getRecordForOwner('record-200', 'account-a'),
    /owner does not match/
  );
});

