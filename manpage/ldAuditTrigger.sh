#!/bin/sh
# Reproduces the environment parser trigger verified for Manpage 5.

set -u

target=${1:-/manpage/manpage5}
delay=${MANPAGE_COMMAND_DELAY:-1}
magic=$(printf '\357\276\255\336')

{
  sleep "$delay"
  cat
} | env "LD_AUDIT=    ${magic}" "$target"

