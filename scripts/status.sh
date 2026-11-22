#!/usr/bin/env bash
# Read-only status for both independent repositories.
set -euo pipefail
ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

show_repo() {
  local name="$1" expected="$2" dir="$ROOT/$1"
  printf '\n[%s]\n' "$name"
  if [[ ! -d "$dir/.git" ]]; then
    printf 'MISSING: %s\n' "$dir"
    return 0
  fi
  printf 'remote: %s\n' "$(git -C "$dir" config --get remote.origin.url || printf 'unset')"
  printf 'branch: %s\n' "$(git -C "$dir" branch --show-current)"
  printf 'head:   %s\n' "$(git -C "$dir" rev-parse HEAD)"
  printf 'pinned: %s\n' "$expected"
  if [[ "$(git -C "$dir" rev-parse HEAD)" == "$expected" ]]; then
    printf 'baseline: exact\n'
  elif git -C "$dir" merge-base --is-ancestor "$expected" HEAD 2>/dev/null; then
    printf 'baseline: ancestor (work has advanced)\n'
  else
    printf 'baseline: diverged or not an ancestor\n'
  fi
  if [[ -z "$(git -C "$dir" status --porcelain)" ]]; then
    printf 'working tree: clean\n'
  else
    printf 'working tree: dirty\n'
    git -C "$dir" status --short
  fi
}

show_repo fieldbook 28eb8779ea2aab67ce471d9d3e9f222faf8f7327
show_repo nirnay 437179a8fdd0b1935420d1467f9a5c8a60da824d
