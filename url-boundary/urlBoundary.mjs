// Demonstrates canonical URL validation at a trust boundary.

export function isTrustedUrlUnsafe(val) {
  return val.startsWith('https://trusted.example');
}

export function ensureTrustedUrl(val) {
  let parsedUrl;

  try {
    parsedUrl = new URL(val);
  } catch (error) {
    throw new Error('Failed to validate trusted URL: URL is invalid.');
  }

  const isAllowed = parsedUrl.protocol === 'https:'
    && parsedUrl.hostname === 'trusted.example'
    && parsedUrl.port === '';

  if (!isAllowed) {
    throw new Error('Failed to validate trusted URL: destination is outside the allowed origin.');
  }

  return parsedUrl.toString();
}

