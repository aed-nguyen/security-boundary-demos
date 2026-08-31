# Manpage

`payloads.py` builds two parameterized 32-bit payload layouts used in solved levels. Offsets, return addresses, filler bytes, and shellcode are passed as arguments so the same builders can be tested against different layouts.

`ldAuditTrigger.sh` reproduces the verified environment-parsing trigger for Manpage 5.

## Payload builder

```sh
python3 payloads.py stack OFFSET GADGET SHELLCODE_HEX > payload.bin
python3 payloads.py wumpus SPRAY_LENGTH RETURN_OFFSET GADGET SHELLCODE_HEX > payload.bin
```

## Trigger

```sh
printf 'id\n' | ./ldAuditTrigger.sh /path/to/manpage5
```
