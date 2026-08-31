# Object authorization

The unsafe example returns a record when its identifier is known. It never checks whether the current account owns that record.

The corrected version includes ownership in the lookup and rejects a record belonging to another account.

The tests read a record owned by the current account. They then repeat the request with an identifier belonging to a different account and show the corrected path rejecting it.

