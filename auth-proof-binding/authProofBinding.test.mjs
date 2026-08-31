// Verifies that authentication proof cannot be reused for another transaction.

import assert from 'node:assert/strict';
import test from 'node:test';

import {
  issueBoundProof,
  issueUnboundProof,
  verifyBoundProof,
  verifyUnboundProof
} from './authProofBinding.mjs';

const SECRET = 'synthetic-test-secret';
const NOW_MS = 1_800_000_000_000;

test('shows that an account-only proof can be reused across transactions', () => {
  const proof = issueUnboundProof(SECRET, 'account-a');

  assert.equal(verifyUnboundProof(SECRET, 'account-a', proof), true);
  assert.equal(verifyUnboundProof(SECRET, 'account-a', proof), true);
});

test('accepts a proof bound to the expected transaction', () => {
  const claim = {
    accountId: 'account-a',
    action: 'approve-report',
    transactionId: 'transaction-100',
    expiresAt: NOW_MS + 60_000
  };
  const token = issueBoundProof(SECRET, claim);
  const result = verifyBoundProof(SECRET, claim, token, NOW_MS);

  assert.equal(result.ok, true);
  assert.deepEqual(result.claim, claim);
});

test('rejects reuse for another transaction', () => {
  const claim = {
    accountId: 'account-a',
    action: 'approve-report',
    transactionId: 'transaction-100',
    expiresAt: NOW_MS + 60_000
  };
  const token = issueBoundProof(SECRET, claim);
  const otherTransaction = {
    ...claim,
    transactionId: 'transaction-200'
  };

  assert.throws(
    () => verifyBoundProof(SECRET, otherTransaction, token, NOW_MS),
    /claim is not bound to this transaction/
  );
});

test('rejects an expired proof', () => {
  const claim = {
    accountId: 'account-a',
    action: 'approve-report',
    transactionId: 'transaction-100',
    expiresAt: NOW_MS - 1
  };
  const token = issueBoundProof(SECRET, claim);

  assert.throws(
    () => verifyBoundProof(SECRET, claim, token, NOW_MS),
    /claim has expired/
  );
});

