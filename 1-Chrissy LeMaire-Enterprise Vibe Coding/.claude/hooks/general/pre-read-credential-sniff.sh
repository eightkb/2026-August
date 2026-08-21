#!/usr/bin/env bash
# Session transcripts leave the machine. A Read, Grep, Glob, or Bash call
# aimed at credential-shaped files puts secret material into that transcript,
# so the call is stopped before the tool runs.
set -euo pipefail

input=$(cat)
target=$(jq -r '[.tool_input.file_path, .tool_input.path, .tool_input.pattern, .tool_input.command] | map(select(. != null)) | join(" ")' <<<"$input")
[ -n "$target" ] || exit 0
target=${target//\\//}

# .env.example and friends hold placeholders, never secrets.
scrubbed=$(sed -E 's/\.env\.(example|sample|template)//gi' <<<"$target")

hit=$(grep -oiE '[^ "'"'"']*(\.env\b|\.pem\b|\.key\b|id_rsa|secrets?\.[a-z]+|credentials\.[a-z]+)[^ "'"'"']*' <<<"$scrubbed" | head -n 1 || true)
if [ -n "$hit" ]; then
  echo "BLOCKED: \"$hit\" looks like credential material, and everything a tool returns lands in the transcript. Ask the user for the one value you need." >&2
  exit 2
fi
exit 0
