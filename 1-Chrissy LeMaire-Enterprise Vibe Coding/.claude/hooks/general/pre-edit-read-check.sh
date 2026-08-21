#!/usr/bin/env bash
# No fresh Read, no edit. An edit made against a remembered version of a file
# corrupts the parts memory got wrong, so the file has to have been Read this
# session (post-read-track.sh keeps the ledger; compact and resume clear it).
set -euo pipefail

input=$(cat)
tool=$(jq -r '.tool_name // empty' <<<"$input")
[ "$tool" = "Edit" ] || exit 0

sid=$(jq -r '.session_id // "default"' <<<"$input")
file=$(jq -r '.tool_input.file_path // empty' <<<"$input")
[ -n "$file" ] || exit 0

# A file that does not exist yet has nothing to read.
winfile=${file//\//\\}
[ -f "$file" ] || [ -f "$winfile" ] || exit 0

norm=$(tr '\\' '/' <<<"$file" | tr '[:upper:]' '[:lower:]')
track="${TMPDIR:-/tmp}/claude-reads-$sid"

if [ ! -f "$track" ] || ! grep -Fxq "$norm" "$track"; then
  echo "BLOCKED: no fresh Read of $file this session. Read the file, then make the edit against what is actually there." >&2
  exit 2
fi
exit 0
