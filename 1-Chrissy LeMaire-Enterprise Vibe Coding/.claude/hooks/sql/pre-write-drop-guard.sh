#!/usr/bin/env bash
# DROP and TRUNCATE erase data with no undo. They stay out of .sql files the
# agent writes; a human runs them deliberately, by hand.
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

hit=$(grep -oiE '(^|[[:space:];])(DROP[[:space:]]+(TABLE|DATABASE|VIEW|INDEX|PROC(EDURE)?|TRIGGER|FUNCTION)|TRUNCATE[[:space:]]+TABLE)' <<<"$content" | head -n 1 | sed 's/^[[:space:];]*//' || true)
if [ -n "$hit" ]; then
  echo "BLOCKED: this file contains \"$hit\". Destructive statements are a human's call; hand the statement to the user to run themselves." >&2
  exit 2
fi
exit 0
