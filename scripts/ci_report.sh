#!/usr/bin/env bash
# Report the latest hosted CI run for both repositories. Read-only.
set -euo pipefail
ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

for name in fieldbook nirnay; do
  printf '\n[%s]\n' "$name"
  if ! command -v gh >/dev/null 2>&1; then
    printf 'gh unavailable; CI run not reported\n'
    continue
  fi
  gh run list --repo "siebensterne/$name" --branch main --workflow CI --limit 1 \
    --json databaseId,headSha,status,conclusion \
    --jq '.[] | "run=\(.databaseId) head=\(.headSha) status=\(.status) conclusion=\(.conclusion)"' \
    2>/dev/null || printf 'CI run unavailable (offline or unauthenticated)\n'
done
