# Vortex 5

`md5Search.c` searches the complete five-character alphanumeric space. It implements the single-block MD5 compression directly and divides the keyspace across POSIX threads.

```sh
cc -std=c11 -O3 -pthread md5Search.c -o md5-search
./md5-search TARGET_MD5_HEX 10
```

The second argument is the thread count. The program exits with status 1 when the target isn't in the search space.

