#!/usr/bin/env bash
# Read-only cross-repository consistency audit.
# Verifies tool pins, legal files, lock-head skew and the one-Markdown rule.
set -euo pipefail
ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
FB="$ROOT/fieldbook"
NR="$ROOT/nirnay"
fail=0

check() {
  local label="$1" value="$2" expected="$3"
  if [[ "$value" == "$expected" ]]; then
    printf 'PASS %-34s %s\n' "$label" "$value"
  else
    printf 'FAIL %-34s got=%s expected=%s\n' "$label" "$value" "$expected"
    fail=1
  fi
}

printf '[tool pins]\n'
for repo in "$FB" "$NR"; do
  name="$(basename "$repo")"
  check "$name rust" \
    "$(sed -n 's/^channel *= *"\([^"]*\)".*/\1/p' "$repo/rust-toolchain.toml" | head -1)" \
    '1.99.1'
  check "$name ruff" \
    "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["ruff"]["required_version"].lstrip("="))' "$repo/quality-contract.json")" \
    '0.17.5'
  check "$name clang-format" \
    "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["tools"]["clang_format"])' "$repo/quality-contract.json")" \
    '21.1.8'
done

printf '\n[legal and control files]\n'
for repo in "$ROOT" "$FB" "$NR"; do
  name="$(basename "$repo")"
  files=(TODO.md)
  if [[ "$repo" != "$ROOT" ]]; then files+=(LICENSE NOTICE); fi
  for file in "${files[@]}"; do
    if [[ -s "$repo/$file" ]]; then
      printf 'PASS %-34s %s\n' "$name/$file" present
    else
      printf 'FAIL %-34s missing or empty\n' "$name/$file"
      fail=1
    fi
  done
done
for repo in "$FB" "$NR"; do
  name="$(basename "$repo")"
  for file in quality-contract.json rust-toolchain.toml clippy.toml git-policy.json; do
    if [[ -s "$repo/$file" ]]; then
      printf 'PASS %-34s %s\n' "$name/$file" present
    else
      printf 'FAIL %-34s missing or empty\n' "$name/$file"
      fail=1
    fi
  done
done

printf '\n[byte-identical shared files]\n'
for file in LICENSE NOTICE quality-contract.json q.toml scripts/check_q_style.py; do
  if [[ -s "$FB/$file" && -s "$NR/$file" ]] && cmp -s "$FB/$file" "$NR/$file"; then
    printf 'PASS %-34s identical\n' "$file"
  else
    printf 'FAIL %-34s diverged\n' "$file"
    fail=1
  fi
done

printf '\n[lock skew]\n'
python3 - "$ROOT/WORKSPACE.lock.json" "$FB" "$NR" <<'PY'
import json, subprocess, sys
lock, fb, nr = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.load(open(lock, encoding="utf-8"))
for repo in data["repositories"]:
    path = {"fieldbook": fb, "nirnay": nr}[repo["name"]]
    head = subprocess.check_output(["git", "-C", path, "rev-parse", "HEAD"], text=True).strip()
    pin = repo["baseline_commit"]
    exact = head == pin
    ancestor = subprocess.run(
        ["git", "-C", path, "merge-base", "--is-ancestor", pin, "HEAD"],
        capture_output=True).returncode == 0
    state = "exact" if exact else ("ancestor" if ancestor else "DIVERGED")
    print(f"{'PASS' if exact or ancestor else 'FAIL'} {repo['name']:<26} {state} {head[:12]}")
    if not (exact or ancestor):
        raise SystemExit(1)
PY

printf '\n[no-Markdown rule]\n'
python3 - "$ROOT" "$FB" "$NR" <<'PY'
import re
import subprocess
import sys

markdown = re.compile(r"\.(?:md|markdown|mdown|mkd|mdx)$", re.IGNORECASE)
generated = "target/doc/"
allowed = "TODO.md"
failed = False
for root in sys.argv[1:]:
    tracked = subprocess.check_output(
        ["git", "-C", root, "ls-files", "-z"], text=True
    ).split("\0")
    extra_args = []
    if root == sys.argv[1]:
        extra_args = [":(exclude)fieldbook/**", ":(exclude)nirnay/**"]
    others = subprocess.check_output(
        ["git", "-C", root, "ls-files", "--others", "-z", "--", *extra_args],
        text=True,
    ).split("\0")
    bad = sorted(
        p
        for p in set(tracked + others)
        if p and p != allowed and not p.startswith(generated) and markdown.search(p)
    )
    name = root.rsplit("/", 1)[-1] or "workspace"
    if bad:
        failed = True
        print(f"FAIL {name:<28} {len(bad)} Markdown file(s): {bad[:5]}")
    else:
        print(f"PASS {name:<28} only {allowed}")
if failed:
    raise SystemExit(1)
PY

state_bytes="$(wc -c < "$ROOT/CURRENT-STATE.json" | tr -d ' ')"
if [[ "$state_bytes" -gt 16384 ]]; then
  printf 'FAIL %-34s bytes=%s\n' 'CURRENT-STATE.json' "$state_bytes"
  fail=1
else
  printf 'PASS %-34s bytes=%s\n' 'CURRENT-STATE.json' "$state_bytes"
fi

if [[ "$fail" -ne 0 ]]; then
  printf '\nCONSISTENCY FAILED\n' >&2
  exit 1
fi
printf '\nCONSISTENCY OK\n'
