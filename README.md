# Security boundary demos

I built these four small examples for this repository. Each one puts an unsafe shortcut beside a safer implementation. The tests show the difference.

Everything in the examples is invented. That includes the hosts and account identifiers. The transactions, records, files, and secrets are synthetic too.

The unsafe functions are included only for comparison and shouldn't be copied into a real system.

## The four demos

- [URL trust boundaries](url-boundary): a trusted-looking string prefix isn't the same as a validated destination
- [Object authorization](object-authorization): knowing a record identifier doesn't prove that the current account owns it
- [Authentication-proof binding](auth-proof-binding): a proof needs to be bound to the action and exact transaction
- [File handling](file-handling): a trusted-looking extension isn't enough to accept a file

## Run the tests

You need a current Node.js release. From the repository root:

```sh
npm test
```

The suite exercises the unsafe behaviour and the corrected path. A passing run means these examples behave as documented.
