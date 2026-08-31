# Security Lab Code

## Lab tooling

- [`vortex16/`](vortex16): digest recovery from similarity scores and a Metal MD5 search
- [`vortex5/`](vortex5): threaded five-character MD5 search in C
- [`manpage/`](manpage): parameterized 32-bit payload builders and the verified `LD_AUDIT` trigger
- [`malware-analysis-lab/`](malware-analysis-lab): UPX unpacking, a Python PE/indicator extractor, YARA and Sigma rules, and an Atomic Red Team service-installation test

The Vortex and Manpage targets came from [OverTheWire](https://overthewire.org/).

## Boundary demos

- [`url-boundary/`](url-boundary): parsed URL validation
- [`object-authorization/`](object-authorization): owner-bound record access
- [`auth-proof-binding/`](auth-proof-binding): transaction-bound authentication proofs
- [`file-handling/`](file-handling): upload path, media type, extension, and size checks

## Tests

```sh
npm test
python3 -m pip install -r requirements.txt
python3 -m unittest discover -s tests
cc -std=c11 -O3 -pthread vortex5/md5Search.c -o /tmp/md5-search
/tmp/md5-search 594f803b380a41396ed63dca39503542 2
```
