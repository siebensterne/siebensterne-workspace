#!/usr/bin/env bash
# Read-only cross-repository consistency audit.
# Verifies version pins, canonical file presence and lock-head skew.
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

printf '\n[canonical root files]\n'
for repo in "$FB" "$NR"; do
  name="$(basename "$repo")"
  for file in README.md STYLES.md AGENTS.md CONTRIBUTING.md SECURITY.md \
              NOTICE ORIGIN.md LICENSE quality-contract.json rust-toolchain.toml \
              clippy.toml; do
    if [[ -f "$repo/$file" ]]; then
      printf 'PASS %-34s %s\n' "$name/$file" present
    else
      printf 'FAIL %-34s missing\n' "$name/$file"
      fail=1
    fi
  done
done

printf '\n[byte-identical shared files]\n'
for file in LICENSE NOTICE ORIGIN.md quality-contract.json \
            scripts/check_prose_unified.py requirements-dev.txt; do
  if [[ -f "$FB/$file" && -f "$NR/$file" ]] && cmp -s "$FB/$file" "$NR/$file"; then
    printf 'PASS %-34s identical\n' "$file"
  else
    printf 'INFO %-34s repo-local or missing\n' "$file"
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

printf '\n[ADR ids]\n'
if [[ -f "$ROOT/ADR-REGISTRY.md" && -f "$ROOT/NDC-REGISTRY.md" ]]; then
  printf 'PASS %-34s present\n' 'workspace registries'
else
  printf 'FAIL %-34s missing\n' 'workspace registries'
  fail=1
fi

printf '\n[documentation budgets]\n'
for repo in "$ROOT" "$FB" "$NR"; do
  name="$(basename "$repo")"
  if [[ ! -f "$repo/README.md" || ! -f "$repo/AGENTS.md" ]]; then
    printf 'FAIL %-34s missing README or AGENTS\n' "$name"
    fail=1
    continue
  fi
  readme_lines="$(wc -l < "$repo/README.md" | tr -d ' ')"
  agents_bytes="$(wc -c < "$repo/AGENTS.md" | tr -d ' ')"
  if [[ "$readme_lines" -gt 100 ]]; then
    printf 'FAIL %-34s README lines=%s\n' "$name" "$readme_lines"
    fail=1
  else
    printf 'PASS %-34s README lines=%s\n' "$name" "$readme_lines"
  fi
  if [[ "$agents_bytes" -gt 2048 ]]; then
    printf 'FAIL %-34s AGENTS bytes=%s\n' "$name" "$agents_bytes"
    fail=1
  else
    printf 'PASS %-34s AGENTS bytes=%s\n' "$name" "$agents_bytes"
  fi
done

state_bytes="$(wc -c < "$ROOT/CURRENT-STATE.json" | tr -d ' ')"
if [[ "$state_bytes" -gt 16384 ]]; then
  printf 'FAIL %-34s bytes=%s\n' 'CURRENT-STATE.json' "$state_bytes"
  fail=1
else
  printf 'PASS %-34s bytes=%s\n' 'CURRENT-STATE.json' "$state_bytes"
fi

if grep -Eq '<!--[[:space:]]*CURRENT-STATE' "$NR/README.md"; then
  printf 'FAIL %-34s local status snapshot found\n' 'nirnay status authority'
  fail=1
else
  printf 'PASS %-34s no local snapshot\n' 'nirnay status authority'
fi

if [[ "$fail" -ne 0 ]]; then
  printf '\nCONSISTENCY FAILED\n' >&2
  exit 1
fi
printf '\nCONSISTENCY OK\n'
