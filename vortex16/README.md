# Vortex 16

The target process scores a 16-byte candidate by the number of bits its MD5 digest shares with a hidden digest.

`oracle.py` turns those scores into a linear system. It recovers all 128 target bits, checks every training equation, then confirms the result against fresh queries that weren't used to solve the system.

`kernel.metal` performs MD5 inside a Metal compute kernel and compares each digest with the recovered target. `gpu.m` batches the search, reports the measured rate, and prints the first candidate that meets the requested threshold.

## Oracle

```sh
python3 oracle.py --target /path/to/oracle --queries 160 --holdouts 8
```

The script prints the recovered digest, then accepts candidate bytes as hexadecimal lines on standard input.

## GPU search

```sh
clang -fobjc-arc -framework Foundation -framework Metal \
  gpu.m -o vortex16-gpu

./vortex16-gpu TARGET_MD5_HEX 100 kernel.metal
```

The candidate format matches the solved level: eight nonzero bytes followed by `VORTEX16`.

