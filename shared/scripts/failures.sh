#!/usr/bin/env bash
# Print the exit line and the failure lines of a test/build log, capped, so the agent never reads the whole log.
#   failures.sh LOG [MAX_LINES]
log=${1:?usage: failures.sh LOG [MAX_LINES]}; max=${2:-40}
tail -1 "$log"
grep -nE '^(--- FAIL|FAIL|panic:)|DATA RACE|^\s*(×|✘)|Error( |:)|\*\*\* \[|FAILED|AssertionError|Timeout' "$log" \
  | grep -vE '^\S*:\s*ok ' | head -n "$max"
