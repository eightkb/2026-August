#!/usr/bin/env bash
# The other half of the tdd-gate: when a scripts/*.ps1 script changed this
# session, its matching scripts/test-*.ps1 has to pass before the turn may end.
# scripts/ is git-ignored here, so change detection compares file times against
# a per-session stamp instead of a git diff. The first stop of a session lays
# the stamp down as the baseline; after that, only a red run leaves the stamp
# untouched so the next stop re-tests.
set -uo pipefail

input=$(cat)
sid=$(jq -r '.session_id // "default"' <<<"$input")

[ -d tools ] || exit 0
command -v pwsh >/dev/null 2>&1 || {
  jq -n '{systemMessage: "stop-run-tests: pwsh not found; tools tests did NOT run this turn."}'
  exit 0
}

stamp="${TMPDIR:-/tmp}/claude-toolstest-stamp-$sid"
if [ ! -f "$stamp" ]; then
  touch "$stamp"
  exit 0
fi

changed=$(find tools -maxdepth 1 -name '*.ps1' -newer "$stamp")
[ -n "$changed" ] || exit 0

# Each changed script answers to its own test, the same pairing the tdd-gate
# enforces on the way in.
tests=$(while IFS= read -r f; do
  base=$(basename "$f")
  case "$base" in
    test-*) echo "scripts/$base" ;;
    *) echo "scripts/test-$base" ;;
  esac
done <<<"$changed" | sort -u)

failures=""
while IFS= read -r t; do
  [ -f "$t" ] || continue
  if ! out=$(pwsh -NoProfile -File "$t" 2>&1); then
    failures="$failures
$t failed:
$(tail -n 15 <<<"$out")"
  fi
done <<<"$tests"

if [ -n "$failures" ]; then
  jq -n --arg r "tools tests failed; the turn does not end on red:$failures" \
    '{decision: "block", reason: $r}'
  exit 0
fi

touch "$stamp"
exit 0
