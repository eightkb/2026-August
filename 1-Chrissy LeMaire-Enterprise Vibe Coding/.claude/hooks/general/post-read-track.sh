#!/usr/bin/env bash
# Records every file the session has Read, so pre-edit-read-check can tell a
# grounded edit from a guess. One tracker file per session, cleared on
# compact and resume by session-reset-reads.sh.
set -euo pipefail

input=$(cat)
sid=$(jq -r '.session_id // "default"' <<<"$input")
file=$(jq -r '.tool_input.file_path // empty' <<<"$input")
[ -n "$file" ] || exit 0

# Windows paths arrive with either slash and any casing; store one form.
norm=$(tr '\\' '/' <<<"$file" | tr '[:upper:]' '[:lower:]')
printf '%s\n' "$norm" >> "${TMPDIR:-/tmp}/claude-reads-$sid"
exit 0
