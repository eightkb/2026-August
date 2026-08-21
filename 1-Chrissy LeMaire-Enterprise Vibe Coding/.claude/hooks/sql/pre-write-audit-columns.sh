#!/usr/bin/env bash
# Every table answers "who wrote this row, and when". A CREATE TABLE without
# the four audit columns gets sent back before it exists.
set -euo pipefail

input=$(cat)
tool=$(jq -r '.tool_name // empty' <<<"$input")
file=$(jq -r '.tool_input.file_path // empty' <<<"$input")
file=${file//\\//}

case "$file" in
  *.sql|*.SQL) ;;
  *) exit 0 ;;
esac

# Judge the whole prospective file, so a small Edit is never read out of context.
if [ "$tool" = "Write" ]; then
  content=$(jq -r '.tool_input.content // empty' <<<"$input")
else
  old=$(jq -r '.tool_input.old_string // empty' <<<"$input")
  new=$(jq -r '.tool_input.new_string // empty' <<<"$input")
  content=""
  [ -f "$file" ] && content=$(cat "$file")
  if [ -n "$old" ]; then content="${content//"$old"/"$new"}"; else content="$content$new"; fi
fi

grep -qiE 'CREATE[[:space:]]+TABLE' <<<"$content" || exit 0

missing=""
for col in CreatedUtc CreatedBy ModifiedUtc ModifiedBy; do
  grep -qi "$col" <<<"$content" || missing="$missing $col"
done

if [ -n "$missing" ]; then
  echo "BLOCKED: CREATE TABLE without audit columns:$missing. Every table carries CreatedUtc, CreatedBy, ModifiedUtc, ModifiedBy." >&2
  exit 2
fi
exit 0
