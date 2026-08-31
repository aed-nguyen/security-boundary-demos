# Object authorization

Identifier-only lookup returns a record without checking who owns it.

`getRecordForOwner()` includes the account in the lookup. The tests read a record belonging to the current account and reject the same request with another account's record identifier.
