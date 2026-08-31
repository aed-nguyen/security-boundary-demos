# Manpage

`payloads.py` builds two parameterized 32-bit payload layouts used in solved levels. It keeps offsets, return addresses, filler bytes, and shellcode outside the source so the byte layout can be tested without publishing a working address-specific payload.

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

