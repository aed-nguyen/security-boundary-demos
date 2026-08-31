# URL trust boundaries

The unsafe example checks whether a URL starts with a trusted-looking string. That accepts destinations where the same text is user information or the beginning of a different hostname.

The corrected version parses the URL before making a trust decision. It requires HTTPS and the exact allowed hostname. A custom port is rejected.

The tests use the exact allowed origin and two outside destinations that fool the string check.
