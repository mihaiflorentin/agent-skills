#!/usr/bin/env bash
# Commit exactly the named paths, even while another agent has staged work in the same checkout.
#   commit-only.sh "message" path [path...]
set -eu
msg=${1:?usage: commit-only.sh MESSAGE PATH...}; shift
[ $# -gt 0 ] || { echo "no paths" >&2; exit 2; }
git add -- "$@"
git commit -q -m "$msg" -- "$@"
git log --oneline -1
