#!/usr/bin/env bash
# SQL built by concatenating strings with variables is injection waiting for
# input. Parameterized SQL through sp_executesql is the only form that ships.
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

if grep -qE "'[^']*'[[:space:]]*\+[[:space:]]*@[A-Za-z_]|@[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\+[[:space:]]*'" <<<"$content"; then
  echo "BLOCKED: this SQL splices a variable into a string. Pass values as typed parameters through sp_executesql, so input can never become code." >&2
  exit 2
fi
exit 0
