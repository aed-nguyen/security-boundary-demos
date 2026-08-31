# Security boundary demos

I built four small examples that put an unsafe shortcut beside a safer implementation. The tests show the difference.

The examples use invented hosts, account identifiers, transactions, records, files, and secrets.

The unsafe functions are included only for comparison and shouldn't be copied into a real system.

## Demos

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
