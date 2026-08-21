---
name: fix-ci
description: Investigate and fix failing GitHub Actions CI.
---

# Fix CI

1. Find failures: `gh run list --limit 10`
2. Get logs: `gh run view <run-id> --log-failed`
3. Diagnose the root cause.
4. Fix it. Never disable the test.
