#!/usr/bin/env bash
# Run a long command into a log that always ends in "EXIT <code>", then print only the failure lines.
# Use it under the Bash tool's run_in_background and wait for the completion notice; never tail -f the log.
#   run-logged.sh LOG -- make check
set -u
log=${1:?usage: run-logged.sh LOG -- command...}; shift
[ "${1:-}" = "--" ] && shift
[ $# -gt 0 ] || { echo "usage: run-logged.sh LOG -- command..." >&2; exit 2; }
mkdir -p "$(dirname "$log")"
"$@" >"$log" 2>&1
code=$?
echo "EXIT $code" >>"$log"
"$(dirname "$0")/failures.sh" "$log"
exit $code
