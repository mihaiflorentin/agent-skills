#!/usr/bin/env bash
# Fail when a Go package imports across a forbidden layer boundary (hexagonal architecture).
#   check-layers.sh [RULES_FILE]   (default: ./layers.rules; run from the module root)
# RULES_FILE lines: "<from-prefix> <must-not-import-prefix>", prefixes relative to the module path; # comments allowed.
# An allow line "allow <from-prefix> <import-prefix>" exempts matching imports from every rule (e.g. allow domain infrastructure/logging).
set -eu
rules=${1:-layers.rules}
[ -f "$rules" ] || { echo "no rules file: $rules" >&2; exit 2; }
mod=$(go list -m)
bad=0
allows=$(awk '$1=="allow"{sub(/\/$/,"",$2); sub(/\/$/,"",$3); print $2" "$3}' "$rules")
allowed() { # pkg imp
  local f t
  while read -r f t; do
    [ -n "$f" ] || continue
    [[ ( "$1" == "$mod/$f" || "$1" == "$mod/$f/"* ) && ( "$2" == "$mod/$t" || "$2" == "$mod/$t/"* ) ]] && return 0
  done <<<"$allows"
  return 1
}
deps=$(go list -f '{{.ImportPath}} {{join .Imports " "}}' ./... 2>/dev/null)
while read -r from to; do
  case "$from" in ''|\#*|allow) continue;; esac
  from=${from%/}; to=${to%/}
  while read -r pkg imports; do
    [[ "$pkg" == "$mod/$from" || "$pkg" == "$mod/$from/"* ]] || continue
    for imp in $imports; do
      if [[ "$imp" == "$mod/$to" || "$imp" == "$mod/$to/"* ]] && ! allowed "$pkg" "$imp"; then
        echo "VIOLATION: ${pkg#$mod/} imports ${imp#$mod/}   (rule: $from must not import $to)"
        bad=1
      fi
    done
  done <<<"$deps"
done <"$rules"
[ $bad -eq 0 ] && echo "layers ok ($(grep -cvE '^\s*(#|$|allow)' "$rules") rules, $(grep -c '^allow' "$rules") allows)"
exit $bad
