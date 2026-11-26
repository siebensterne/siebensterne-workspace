#!/usr/bin/env bash
# Build deterministic review packages for the three independent repositories.
# Only Git-tracked files are included. Raw captures, credentials, build output and
# local .local/ evidence are excluded. No provider contact and no collector runs.
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
OUT="${2:-$ROOT/../siebensterne-review-packages}"
LABEL="${3:-$(date -u +%Y-%m-%d)}"

ROOT="$(cd "$ROOT" && pwd)"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

package_repo() {
  local name="$1" dir="$2"
  local stage="$OUT/.stage-$name"
  rm -rf "$stage"
  mkdir -p "$stage/$name/git" "$stage/$name/source"

  if [[ -n "$(git -C "$dir" status --porcelain)" ]]; then
    printf 'ERROR: %s working tree is dirty; no package built.\n' "$name" >&2
    git -C "$dir" status --short >&2
    return 1
  fi

  local head branch origin ci
  head="$(git -C "$dir" rev-parse HEAD)"
  branch="$(git -C "$dir" branch --show-current)"
  origin="$(git -C "$dir" config --get remote.origin.url || printf 'none')"
  ci="$(gh run list --repo "siebensterne/$name" --branch main --workflow CI --limit 1 \
        --json databaseId,headSha,conclusion \
        --jq '.[] | "\(.databaseId) \(.headSha) \(.conclusion)"' 2>/dev/null || printf 'unavailable')"

  git -C "$dir" -c pack.threads=1 bundle create "$stage/$name/git/$name-refs.bundle" --all >/dev/null 2>&1
  git bundle verify "$stage/$name/git/$name-refs.bundle" >/dev/null 2>&1

  # Review scope is Indian and global securities. Venue-specific live captures,
  # venue latency measurements and prediction-market fixtures are excluded from
  # the review package. Source code and documentation remain fully included.
  local -a excluded_patterns=('target/doc/*.md')
  case "$name" in
    fieldbook)
      excluded_patterns=(
        'measurements/live/*'
        'measurements/polymarket-*'
        'measurements/remediation/*polymarket*'
        'fixtures/polymarket/*'
      )
      ;;
  esac
  local excluded_list="$stage/.$name-excluded"
  : > "$excluded_list"
  while IFS= read -r -d '' file; do
    local skip=0
    if [[ ${#excluded_patterns[@]} -gt 0 ]]; then
      for pattern in "${excluded_patterns[@]}"; do
        if [[ "$file" == $pattern ]]; then skip=1; break; fi
      done
    fi
    if [[ "$skip" -eq 1 ]]; then
      printf '%s\n' "$file" >> "$excluded_list"
      continue
    fi
    mkdir -p "$stage/$name/source/$(dirname "$file")"
    cp -p "$dir/$file" "$stage/$name/source/$file"
  done < <(git -C "$dir" ls-files -z)

  python3 - "$stage/$name" "$excluded_list" "${excluded_patterns[*]-}" \
          "$name" "$head" "$branch" "$origin" "$ci" "$LABEL" <<'PY'
import hashlib, json, pathlib, sys
root = pathlib.Path(sys.argv[1])
excluded_path = pathlib.Path(sys.argv[2])
patterns = [p for p in sys.argv[3].split() if p]
name, head, branch, origin, ci, label = sys.argv[4:]
excluded = sorted(x.strip() for x in excluded_path.read_text(encoding="utf-8").splitlines() if x.strip())
excluded_path.unlink()
files = []
for path in sorted(p for p in root.rglob("*") if p.is_file() and p.name != "MANIFEST.json"):
    rel = path.relative_to(root).as_posix()
    data = path.read_bytes()
    files.append({"path": rel, "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)})
manifest = {
    "schema": 2,
    "repository": name,
    "generated_utc_date": label,
    "head": head,
    "branch": branch,
    "origin": origin,
    "latest_ci": ci,
    "tracked_files": len([f for f in files if f["path"].startswith("source/")]),
    "excluded_files": excluded,
    "exclusion_patterns": patterns,
    "files": files,
    "total_bytes": sum(f["bytes"] for f in files),
}
(root / "MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
PY

  local zip="$OUT/siebensterne-$name-review-$LABEL.zip"
  python3 - "$stage/$name" "$zip" <<'PY'
import pathlib, sys, zipfile
root = pathlib.Path(sys.argv[1]); out = pathlib.Path(sys.argv[2])
paths = sorted(p for p in root.rglob("*") if p.is_file())
epoch = (1980, 1, 1, 0, 0, 0)
with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for p in paths:
        info = zipfile.ZipInfo(p.relative_to(root).as_posix(), date_time=epoch)
        info.external_attr = 0o644 << 16
        zf.writestr(info, p.read_bytes())
PY
  local sha
  sha="$(shasum -a 256 "$zip" | awk '{print $1}')"
  printf '%s  %s\n' "$sha" "$(basename "$zip")" > "$zip.sha256"
  printf 'PACKED %-12s files=%-4s bytes=%-9s sha256=%s\n' \
    "$name" "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["tracked_files"])' "$stage/$name/MANIFEST.json")" \
    "$(stat -f%z "$zip")" "$sha"
  rm -rf "$stage"
}

package_repo fieldbook "$ROOT/fieldbook"
package_repo nirnay "$ROOT/nirnay"
package_repo workspace "$ROOT"

# Combined bundle for a single hand-off.
STAGE="$OUT/.stage-combined"
rm -rf "$STAGE"; mkdir -p "$STAGE"
cp "$OUT"/siebensterne-*-review-"$LABEL".zip "$STAGE/"
cp "$OUT"/siebensterne-*-review-"$LABEL".zip.sha256 "$STAGE/"
python3 - "$STAGE" "$OUT/siebensterne-review-bundle-$LABEL.zip" <<'PY'
import hashlib, json, pathlib, sys, zipfile
root = pathlib.Path(sys.argv[1]); out = pathlib.Path(sys.argv[2])
paths = sorted(p for p in root.rglob("*") if p.is_file())
epoch = (1980, 1, 1, 0, 0, 0)
with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for p in paths:
        info = zipfile.ZipInfo(p.relative_to(root).as_posix(), date_time=epoch)
        info.external_attr = 0o644 << 16
        zf.writestr(info, p.read_bytes())
(root / "BUNDLE-MANIFEST.json").write_text(json.dumps({
    "schema": 1,
    "members": [{"name": p.relative_to(root).as_posix(),
                 "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
                 "bytes": p.stat().st_size} for p in paths],
}, indent=2) + "\n", encoding="utf-8")
PY
sha="$(shasum -a 256 "$OUT/siebensterne-review-bundle-$LABEL.zip" | awk '{print $1}')"
printf '%s  %s\n' "$sha" "$(basename "$OUT/siebensterne-review-bundle-$LABEL.zip")" > "$OUT/siebensterne-review-bundle-$LABEL.zip.sha256"
rm -rf "$STAGE"
printf 'BUNDLE %s bytes=%s sha256=%s\n' "$(basename "$OUT/siebensterne-review-bundle-$LABEL.zip")" "$(stat -f%z "$OUT/siebensterne-review-bundle-$LABEL.zip")" "$sha"
