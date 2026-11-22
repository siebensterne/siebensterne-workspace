#!/usr/bin/env bash
# Canonical gate surface for the two independent repositories.
# Local gates only. No provider contact and no market-data collection.
set -euo pipefail

TASK="${1:?usage: gates.sh fieldbook-static|nirnay-static|nirnay|all WORKSPACE_ROOT}"
ROOT="${2:-$(cd "$(dirname "$0")/.." && pwd)}"

run() {
  local label="$1" dir="$2"
  shift 2
  printf '\n[%s] %s\n' "$label" "$*"
  ( cd "$dir" && "$@" )
}

case "$TASK" in
  fieldbook-static|fieldbook-check-static)
    # Fieldbook's fixture/e2e suite stays excluded until its market-shaped
    # fixture inventory has been reviewed against the owner no-synthetic policy.
    run fieldbook "$ROOT/fieldbook" make check-static
    ;;
  nirnay-static|nirnay-check-static)
    run nirnay "$ROOT/nirnay" make check-static
    ;;
  nirnay)
    run nirnay "$ROOT/nirnay" make check
    ;;
  all)
    # Both static surfaces share the same command name and meaning.
    run fieldbook "$ROOT/fieldbook" make check-static
    run nirnay "$ROOT/nirnay" make check-static
    printf '\nAll static gates passed. Full Nirnay suite: make check-nirnay.\n'
    ;;
  *)
    printf 'Unknown gate task: %s\n' "$TASK" >&2
    printf 'Known tasks: fieldbook-static nirnay-static nirnay all\n' >&2
    exit 2
    ;;
esac
