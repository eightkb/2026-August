---
name: build
description: Validate the EightKB deck. Use after editing index.html, deck.css, or deck.js to confirm the deck still passes every check, or when asked whether the deck builds.
---

# Build

The deck is static HTML; there is no compile step. "Builds" here means every
check passes.

## Steps

1. Run the structural check:

   ```
   pwsh -NoProfile scripts/check-deck.ps1
   ```

   It verifies that every local src/href resolves to a file on disk, that
   slide copy carries no em dash, en dash, or double hyphen used as a dash,
   that every slide has a data-section and at least one data-reveal, and that
   element ids are unique.

2. Run the content tests, one file at a time:

   ```
   pwsh -NoProfile -File scripts/test-<name>.ps1
   ```

   for every scripts/test-*.ps1. Each pins the copy of a slide or section the
   deck has committed to.

## What passing looks like

check-deck.ps1 ends with one line, `OK  <n> slides, no problems`, and exits 0.
A failure prints one `FAIL  <problem>` line per finding and exits 1; fix the
finding it names, in index.html, and run the check again. The change is done
when every script exits 0.
