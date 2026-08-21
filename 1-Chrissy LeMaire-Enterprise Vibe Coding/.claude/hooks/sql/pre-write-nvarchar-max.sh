#!/usr/bin/env bash
# NVARCHAR tops out at 4000 characters. A bigger number is a syntax error that
# reads like a design decision, so it gets caught here instead of at deploy.
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

while read -r size; do
  [ -n "$size" ] || continue
  if [ "$size" -gt 4000 ]; then
    echo "BLOCKED: NVARCHAR($size) does not exist; 4000 is the ceiling. Size the column at 4000 or below, or use NVARCHAR(MAX) for genuinely unbounded text." >&2
    exit 2
  fi
done < <(grep -oiE 'NVARCHAR[[:space:]]*\([[:space:]]*[0-9]+' <<<"$content" | grep -oE '[0-9]+')
exit 0
