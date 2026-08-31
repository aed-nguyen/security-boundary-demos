# Authentication-proof binding

A proof that signs only an account identifier can be reused for another transaction involving that account.

`issueBoundProof()` signs the account, permitted action, transaction, and expiry. `verifyBoundProof()` checks those values against the expected claim. The tests reproduce the reuse problem, accept the expected transaction, and reject a different transaction and an expired proof.
