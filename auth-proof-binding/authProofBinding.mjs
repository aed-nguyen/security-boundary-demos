// Demonstrates binding authentication proof to an exact account and transaction.

import { createHmac, timingSafeEqual } from 'node:crypto';

export function issueUnboundProof(secret, accountId) {
  return signValue(secret, accountId);
}

export function verifyUnboundProof(secret, accountId, proof) {
  return isMatchingSignature(signValue(secret, accountId), proof);
}

export function issueBoundProof(secret, claim) {
  const payload = encodeClaim(claim);
  const signature = signValue(secret, payload);

  return payload + '.' + signature;
}

export function verifyBoundProof(secret, expectedClaim, token, nowMs) {
  const parts = token.split('.');

  if (parts.length !== 2) {
    throw new Error('Failed to verify authentication proof: token shape is invalid.');
  }

  const payload = parts[0];
  const signature = parts[1];

  if (!isMatchingSignature(signValue(secret, payload), signature)) {
    throw new Error('Failed to verify authentication proof: signature does not match.');
  }

  const claim = decodeClaim(payload);
  const isExpected = claim.accountId === expectedClaim.accountId
    && claim.action === expectedClaim.action
    && claim.transactionId === expectedClaim.transactionId;

  if (!isExpected) {
    throw new Error('Failed to verify authentication proof: claim is not bound to this transaction.');
  }

  if (!Number.isFinite(claim.expiresAt) || claim.expiresAt < nowMs) {
    throw new Error('Failed to verify authentication proof: claim has expired.');
  }

  return { ok: true, claim };
}

function encodeClaim(claim) {
  return Buffer.from(JSON.stringify(claim), 'utf8').toString('base64url');
}

function decodeClaim(payload) {
  try {
    return JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
  } catch (error) {
    throw new Error('Failed to verify authentication proof: payload is invalid.');
  }
}

function signValue(secret, val) {
  return createHmac('sha256', secret).update(val).digest('base64url');
}

function isMatchingSignature(expected, actual) {
  const expectedBuffer = Buffer.from(expected);
  const actualBuffer = Buffer.from(actual);

  return expectedBuffer.length === actualBuffer.length
    && timingSafeEqual(expectedBuffer, actualBuffer);
}

