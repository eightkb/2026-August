#!/usr/bin/env bash
# A scripts/*.ps1 change without a test is a claim with no way to check it.
# The matching test has to exist before the script can be touched; the Stop
# hook (stop-run-tests.sh) then runs it to prove the change.
set -euo pipefail

input=$(cat)
file=$(jq -r '.tool_input.file_path // empty' <<<"$input")
file=${file//\\//}

case "$file" in
  scripts/*.ps1|*/scripts/*.ps1) ;;
  *) exit 0 ;;
esac

base=$(basename "$file")
case "$base" in
  test-*.ps1) exit 0 ;;
esac

dir=$(dirname "$file")
if [ ! -f "$dir/test-$base" ]; then
  echo "BLOCKED: scripts/$base has no matching scripts/test-$base. Write the test first; the Stop hook runs it to prove this change." >&2
  exit 2
fi
exit 0
