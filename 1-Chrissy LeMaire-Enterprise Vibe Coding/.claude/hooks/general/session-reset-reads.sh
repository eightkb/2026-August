#!/usr/bin/env bash
# After a compact or resume the transcript is summarized: the model's memory
# of file contents is now secondhand. Clearing the read tracker makes
# pre-edit-read-check demand fresh Reads before any further edits.
set -euo pipefail

input=$(cat)
sid=$(jq -r '.session_id // "default"' <<<"$input")
rm -f "${TMPDIR:-/tmp}/claude-reads-$sid"
exit 0
