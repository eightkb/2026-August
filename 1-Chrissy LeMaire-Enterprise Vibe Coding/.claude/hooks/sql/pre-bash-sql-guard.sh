#!/usr/bin/env bash
# Reads the whole Bash command before it runs. Destructive or side-channel SQL
# inside a shell command gets stopped here, whatever tool wraps it.
set -euo pipefail

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -n "$command" ] || exit 0

hit=$(grep -oiE 'DROP[[:space:]]+DATABASE|DELETE[[:space:]]+FROM|TRUNCATE[[:space:]]+TABLE|xp_cmdshell|OPENQUERY' <<<"$command" | head -n 1 || true)
if [ -n "$hit" ]; then
  echo "BLOCKED: the command contains \"$hit\". Statements like this run with a human at the keyboard; hand the command to the user instead." >&2
  exit 2
fi
exit 0
