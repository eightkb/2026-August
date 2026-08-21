#!/usr/bin/env bash
# Advisory, never a block: past 400 lines a file stops fitting in one read.
# The write has already landed; exit 2 is simply the only PostToolUse channel
# that puts a message in front of the model.
set -euo pipefail

input=$(cat)
file=$(jq -r '.tool_input.file_path // empty' <<<"$input")
file=${file//\\//}
[ -n "$file" ] || exit 0

# The deck and its export are one deliberately long file each; archive/ is
# history. Everything else answers for its length.
case "$file" in
  *index.html|*export.html|*/archive/*|archive/*) exit 0 ;;
esac

[ -f "$file" ] || exit 0
lines=$(wc -l < "$file" | tr -d ' ')
[ "$lines" -gt 400 ] || exit 0

echo "ADVISORY: $file is $lines lines, past the 400-line mark. Split out what does not have to live there." >&2
exit 2
