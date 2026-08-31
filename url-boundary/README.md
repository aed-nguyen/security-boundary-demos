# URL trust boundaries

A raw `startsWith()` check accepts URLs that put the trusted text in user information or at the beginning of a different hostname.

`ensureTrustedUrl()` parses the URL and allows HTTPS to the exact hostname without a custom port. The tests cover the allowed origin and both string-check bypasses.
