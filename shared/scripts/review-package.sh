#!/usr/bin/env bash
# Write a scoped review package: the non-test, non-generated code diff plus a stat of the changed tests.
# Reviewers read this instead of re-deriving the diff, and generated files never cost review tokens.
#   review-package.sh BASE [HEAD] [OUT_DIR] [-- extra :!pathspec ...]
# Set EXCLUDES to override the default generated-file pathspecs (space-separated).
set -eu
base=${1:?usage: review-package.sh BASE [HEAD] [OUT_DIR]}; head=${2:-HEAD}; out=${3:-./review-package}
shift $(( $# < 3 ? $# : 3 )); [ "${1:-}" = "--" ] && shift
mkdir -p "$out"
default_ex=':!testdata :!*_test.go :!*.test.ts :!*.test.tsx :!**/e2e/** :!**/__screenshots__/** :!*.gen.ts :!**/*.lock :!package-lock.json :!docs/plans :!docs/specs :!docs/**/plans/**'
read -r -a ex <<<"${EXCLUDES:-$default_ex}"
git diff -U5 "$base" "$head" -- . "${ex[@]}" "$@" >"$out/code.diff"
git diff --stat "$base" "$head" -- '*_test.go' '*.test.ts' '*.test.tsx' '**/e2e/**' >"$out/tests.stat"
git log --oneline "$base..$head" >"$out/commits.txt"
echo "$out/code.diff: $(wc -l <"$out/code.diff") lines; $(wc -l <"$out/commits.txt") commits; tests: $(tail -1 "$out/tests.stat")"
