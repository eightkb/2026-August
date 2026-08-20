#!/usr/bin/env bash
# NEWID() defaults on a GUID key scatter inserts across random pages and
# fragment the index. NEWSEQUENTIALID() keeps inserts appending.
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

if grep -qiE 'UNIQUEIDENTIFIER[^,]*DEFAULT[[:space:]]*\(*[[:space:]]*NEWID[[:space:]]*\(' <<<"$content"; then
  echo "BLOCKED: NEWID() as a GUID column default writes to random pages and fragments the clustered index. Default the column to NEWSEQUENTIALID()." >&2
  exit 2
fi
exit 0
