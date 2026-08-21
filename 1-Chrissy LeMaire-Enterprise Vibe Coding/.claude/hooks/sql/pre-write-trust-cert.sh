#!/usr/bin/env bash
# TrustServerCertificate = true never ships. It turns off certificate
# validation, which is the half of encryption that stops interception.
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

if grep -qiE 'TrustServerCertificate\s*=\s*\$?(true|1|yes)' <<<"$content"; then
  echo "BLOCKED: TrustServerCertificate=true skips certificate validation and leaves the connection open to interception. Point the client at a certificate it can validate." >&2
  exit 2
fi
exit 0
