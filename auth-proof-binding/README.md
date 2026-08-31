# Authentication-proof binding

The unsafe example signs only an account identifier. The same proof can be reused for another transaction involving that account.

The corrected version signs the permitted action and exact transaction with the account. It includes an expiry. Verification checks the signature against the claim that the caller expects.

The tests show the unsafe proof being reused. The corrected path accepts the expected transaction, then rejects a different transaction and an expired proof.

