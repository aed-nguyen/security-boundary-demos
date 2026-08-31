// Verifies that upload acceptance uses path, media type, extension, and size.

import assert from 'node:assert/strict';
import test from 'node:test';

import { ensureSafeUpload, isImageUnsafe } from './fileHandling.mjs';

test('accepts a bounded PNG upload', () => {
  const upload = {
    fileName: 'scan.png',
    contentType: 'image/png',
    sizeBytes: 240_000
  };
  const result = ensureSafeUpload(upload);

  assert.equal(result.ok, true);
  assert.equal(result.fileName, 'scan.png');
});

test('shows why a trusted-looking extension is not enough', () => {
  const upload = {
    fileName: 'scan.png',
    contentType: 'text/html',
    sizeBytes: 12_000
  };

  assert.equal(isImageUnsafe(upload.fileName), true);
  assert.throws(
    () => ensureSafeUpload(upload),
    /media type is not allowed/
  );
});

test('rejects a path disguised as a file name', () => {
  const upload = {
    fileName: '../scan.png',
    contentType: 'image/png',
    sizeBytes: 12_000
  };

  assert.throws(
    () => ensureSafeUpload(upload),
    /file name contains a path/
  );
});

test('rejects an oversized file', () => {
  const upload = {
    fileName: 'scan.jpg',
    contentType: 'image/jpeg',
    sizeBytes: 3 * 1024 * 1024
  };

  assert.throws(
    () => ensureSafeUpload(upload),
    /file is too large/
  );
});

