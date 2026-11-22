#!/usr/bin/env bash
# Clone or verify the two independent source repositories.
# This script never contacts a market-data provider and never runs a collector.
set -euo pipefail

ROOT="${1:-$HOME/Developer/siebensterne-workspace}"
mkdir -p "$ROOT"
ROOT="$(cd "$ROOT" && pwd)"

LOCK="$ROOT/WORKSPACE.lock.json"

remote_for() {
  python3 - "$LOCK" "$1" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
name = sys.argv[2]
print(next(r["remote"] for r in data["repositories"] if r["name"] == name))
PY
}

pin_for() {
  python3 - "$LOCK" "$1" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
name = sys.argv[2]
print(next(r["baseline_commit"] for r in data["repositories"] if r["name"] == name))
PY
}

verify_repo() {
  local name="$1" remote="$2" expected="$3"
  local dest="$ROOT/$name"

  if [[ -e "$dest" && ! -d "$dest/.git" ]]; then
    printf 'ERROR: %s exists but is not a normal Git clone: %s\n' "$name" "$dest" >&2
    return 1
  fi

  if [[ ! -d "$dest/.git" ]]; then
    printf 'CLONE %s\n' "$remote"
    git clone "$remote" "$dest"
  fi

  # Use the raw configured URL. `git remote get-url` applies global insteadOf
  # rules and can report SSH for an HTTPS remote, which broke earlier versions.
  local actual_remote
  actual_remote="$(git -C "$dest" config --get remote.origin.url || true)"
  if [[ "$actual_remote" != "$remote" && "$actual_remote" != "${remote%.git}" ]]; then
    printf 'ERROR: %s origin mismatch: %s (expected %s)\n' \
      "$name" "$actual_remote" "$remote" >&2
    return 1
  fi

  git -C "$dest" fetch --no-tags origin main
  if ! git -C "$dest" cat-file -e "${expected}^{commit}" 2>/dev/null; then
    git -C "$dest" fetch --no-tags origin "$expected"
  fi
  git -C "$dest" cat-file -e "${expected}^{commit}"

  local branch head dirty
  branch="$(git -C "$dest" branch --show-current)"
  head="$(git -C "$dest" rev-parse HEAD)"
  dirty="$(git -C "$dest" status --porcelain)"

  if [[ -n "$dirty" ]]; then
    printf 'ERROR: %s working tree is dirty; no files were changed.\n' "$name" >&2
    git -C "$dest" status --short >&2
    return 1
  fi

  if [[ "$branch" != "main" ]]; then
    printf 'ERROR: %s is on branch %s, not main; no checkout was performed.\n' \
      "$name" "$branch" >&2
    return 1
  fi

  if [[ "$head" == "$expected" ]]; then
    printf 'VERIFIED %-10s %s (exact pin)\n' "$name" "$head"
  elif git -C "$dest" merge-base --is-ancestor "$expected" HEAD 2>/dev/null; then
    printf 'VERIFIED %-10s %s (pin %s is an ancestor; work has advanced)\n' \
      "$name" "$head" "$expected"
  else
    printf 'ERROR: %s head %s has diverged from pin %s.\n' "$name" "$head" "$expected" >&2
    return 1
  fi
}

for name in fieldbook nirnay; do
  verify_repo "$name" "$(remote_for "$name")" "$(pin_for "$name")"
done

printf '\nWorkspace ready: %s\n' "$ROOT"
printf 'No provider, market-data API, collector or experiment was used.\n'
