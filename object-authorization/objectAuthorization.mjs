// Demonstrates owner-bound authorization for object access.

const RECORDS = [
  { id: 'record-100', ownerId: 'account-a', status: 'ready' },
  { id: 'record-200', ownerId: 'account-b', status: 'pending' }
];

export function getRecordUnsafe(recordId) {
  return RECORDS.find((record) => record.id === recordId) || null;
}

export function getRecordForOwner(recordId, ownerId) {
  const record = RECORDS.find((val) => val.id === recordId);

  if (!record) {
    throw new Error('Failed to authorize record access: record was not found.');
  }

  if (record.ownerId !== ownerId) {
    throw new Error('Failed to authorize record access: owner does not match.');
  }

  return { ...record };
}

