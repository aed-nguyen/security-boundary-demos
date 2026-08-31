// Demonstrates validating upload paths and metadata together.

import path from 'node:path';

const CONFIG = {
  maxSizeBytes: 2 * 1024 * 1024,
  allowedTypes: new Map([
    ['image/jpeg', '.jpg'],
    ['image/png', '.png']
  ])
};

export function isImageUnsafe(fileName) {
  return /\.(jpg|jpeg|png)$/i.test(fileName);
}

export function ensureSafeUpload(upload) {
  const normalizedName = path.basename(upload.fileName);

  if (normalizedName !== upload.fileName) {
    throw new Error('Failed to validate upload: file name contains a path.');
  }

  if (!Number.isInteger(upload.sizeBytes) || upload.sizeBytes < 1) {
    throw new Error('Failed to validate upload: size is invalid.');
  }

  if (upload.sizeBytes > CONFIG.maxSizeBytes) {
    throw new Error('Failed to validate upload: file is too large.');
  }

  const expectedExtension = CONFIG.allowedTypes.get(upload.contentType);

  if (!expectedExtension) {
    throw new Error('Failed to validate upload: media type is not allowed.');
  }

  const actualExtension = path.extname(normalizedName).toLowerCase();
  const isJpegAlias = upload.contentType === 'image/jpeg'
    && actualExtension === '.jpeg';

  if (actualExtension !== expectedExtension && !isJpegAlias) {
    throw new Error('Failed to validate upload: extension does not match media type.');
  }

  return {
    ok: true,
    fileName: normalizedName,
    contentType: upload.contentType,
    sizeBytes: upload.sizeBytes
  };
}

