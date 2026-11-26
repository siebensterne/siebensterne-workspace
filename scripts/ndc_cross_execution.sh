#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Required NDC producer/verifier cross-repository integration gate.
#
# This is the deterministic local implementation used by
# .github/workflows/ndc-required-integration.yml. It is deliberately not an
# optional developer harness: the producer is REQUIRED. There is no SKIP path,
# no simulated producer output and no fallback fixture release. If the producer
# binary is missing or invalid, if the recorded source heads disagree with the
# checkouts, or if any verifier assertion fails, the gate emits a FAIL JSON and
# exits non-zero.
#
# Invariants enforced here:
#   * Fieldbook and Nirnay heads come from CURRENT-STATE.json only and are
#     checked against the exact checkouts used for the builds.
#   * The producer is the real Fieldbook `ndc-conformance-producer` binary run
#     on an abstract, non-market spec derived from the committed fixture by
#     aligning only TEST_ONLY registry identity bindings. Release bytes are
#     never synthesized; both spec digests are recorded.
#   * The verifier is the real Nirnay `ndc-conformance-verifier` binary built
#     from the recorded Nirnay head. Its bytes are hashed.
#   * Rights stay UNKNOWN. A pass is the verifier's typed refusal at the rights
#     boundary (stage 6, REJECT_RIGHTS_EVIDENCE) with no receipt and no private
#     snapshot. No admission and no rights grant are simulated.
#   * One-byte mutations of the real producer output must produce typed
#     refusals at the expected earlier stages.
#   * The result JSON is part of success: it must be written, exist, parse,
#     describe this exact run id and match the recorded heads and digests.
#     A successful build with unwritable or unverifiable evidence is a FAIL.
#   * Exact-source builds require clean checkouts. A supplied prebuilt binary
#     is a local diagnostic override and needs a verified source-provenance
#     sidecar; its provenance is recorded explicitly in the result JSON.
#
# No provider contact, data collection, experiment, holdout, market-shaped
# data, live execution or freeze change occurs. Only GITHUB_TOKEN-equivalent
# local credentials are used; no secrets are read by this script.

# shellcheck shell=bash
set -euo pipefail

die() {
  REASON="$1"
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Usage: scripts/ndc_cross_execution.sh [--out RESULT_JSON] [--work WORK_DIR]
       scripts/ndc_cross_execution.sh --self-test

Optional environment:
  NDC_WORKSPACE_ROOT   workspace root (default: parent of this script)
  NDC_CURRENT_STATE    authority JSON (default: <root>/CURRENT-STATE.json)
  NDC_FIELDBOOK_DIR    Fieldbook checkout (default: <root>/fieldbook)
  NDC_NIRNAY_DIR       Nirnay checkout (default: <root>/nirnay)
  NDC_PRODUCER_BIN     local diagnostic override; needs <path>.ndc-provenance.json
  NDC_VERIFIER_BIN     local diagnostic override; needs <path>.ndc-provenance.json
  NDC_RUN_ID           explicit run id for the result document (diagnostic use)
  FIELDBOOK_SHA        expected head; must equal CURRENT-STATE.json
  NIRNAY_SHA           expected head; must equal CURRENT-STATE.json

A provenance sidecar is JSON with schema_version=1, source_repository,
source_head and binary_sha256; the gate checks all four against the exact
recorded checkout and the bytes it runs. Overrides never relax the gate.

All diagnostics go to stderr. The only stdout output is one JSON document.
USAGE
}

ROOT="${NDC_WORKSPACE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CURRENT_STATE="${NDC_CURRENT_STATE:-$ROOT/CURRENT-STATE.json}"
FIELDBOOK_DIR="${NDC_FIELDBOOK_DIR:-$ROOT/fieldbook}"
NIRNAY_DIR="${NDC_NIRNAY_DIR:-$ROOT/nirnay}"
WORK=""
RESULT_JSON=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      RESULT_JSON="${2:?--out needs a path}"
      shift 2
      ;;
    --work)
      WORK="${2:?--work needs a path}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --self-test)
      shift
      exec python3 - "$0" "$@" <<'PY'
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

# Deterministic fail-closed probes for this gate. Every probe builds its own
# throwaway checkouts, binaries and result paths under a temporary root; it
# never touches CURRENT-STATE.json, WORKSPACE.lock.json or a real checkout.
if len(sys.argv) > 2:
    print("usage: ndc_cross_execution.sh --self-test", file=sys.stderr)
    raise SystemExit(2)

script = Path(sys.argv[1]).resolve()
root = Path(tempfile.mkdtemp(prefix="ndc-evidence-probes-"))
print(f"probe root: {root}")

failures = []

def check(label, condition, detail=""):
    print(f"{'PASS' if condition else 'FAIL'} {label}" + ("" if condition else f" :: {detail}"))
    if not condition:
        failures.append(label)

def run(command, env=None, check_setup=True):
    result = subprocess.run(command, env=env, text=True, capture_output=True)
    if check_setup and result.returncode != 0:
        raise SystemExit(f"setup failed: {command}\n{result.stdout}\n{result.stderr}")
    return result

def git(directory, *args):
    return run(["git", "-C", str(directory), *args])

def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def init_repo(directory, fixture):
    directory.mkdir(parents=True, exist_ok=True)
    git(directory, "init", "-q")
    git(directory, "config", "user.email", "probe@example.invalid")
    git(directory, "config", "user.name", "probe")
    path = directory / fixture
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('{"schema_version":1,"artifacts":[],"evidence":{}}\n', encoding="utf-8")
    (directory / "README.src").write_text("probe source file\n", encoding="utf-8")
    (directory / ".gitignore").write_text("target/\n", encoding="utf-8")
    git(directory, "add", ".")
    git(directory, "commit", "-q", "-m", "probe fixture")
    return git(directory, "rev-parse", "HEAD").stdout.strip()

fieldbook = root / "fieldbook"
nirnay = root / "nirnay"
fb_sha = init_repo(fieldbook, "tests/fixtures/ndc/producer-spec-example.json")
nr_sha = init_repo(nirnay, "README.src")
dirty_path = fieldbook / "README.src"
dirty_bytes = dirty_path.read_bytes()
(root / "CURRENT-STATE.json").write_text(json.dumps({
    "schema_version": 3,
    "source_heads_at_record_time": {"fieldbook": fb_sha, "nirnay": nr_sha},
}, indent=2) + "\n", encoding="utf-8")

producer_stub = r'''#!/usr/bin/env bash
set -euo pipefail
spec="" out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec) spec="${2:?}"; shift 2 ;;
    --out) out="${2:?}"; shift 2 ;;
    *) printf 'stub producer: unexpected argument %s\n' "$1" >&2; exit 2 ;;
  esac
done
[[ -n "$spec" && -f "$spec" && -n "$out" ]] || { printf 'stub producer: bad arguments\n' >&2; exit 2; }
tag="${NDC_TEST_TAG:-probe}"
dest="$out/publisher-example/dataset-example/release-$tag"
mkdir -p "$dest/artifacts"
printf '{"schema_version":1,"publication_identity":{"publisher_identity":"publisher-example"},"source_scope":{"dataset_id":"dataset-example"},"release_identity":{"release_id":"release-%s"}}\n' "$tag" > "$dest/manifest.json"
printf '{"signature":"test-only"}\n' > "$dest/signature.json"
printf 'artifact-bytes\n' > "$dest/artifacts/artifact.bin"
'''

verifier_stub = r'''#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path

args = sys.argv[1:]
release = out = None
while args:
    flag = args.pop(0)
    if flag == "--release":
        release = args.pop(0)
    elif flag == "--out":
        out = args.pop(0)
    else:
        raise SystemExit(f"stub verifier: unexpected argument {flag}")
if not release or not out:
    raise SystemExit("stub verifier: bad arguments")
if "/mutations/one-byte-manifest/" in release:
    outcome, stage, code, rc = "PREFLIGHT_REFUSED", 1, "REJECT_SCHEMA_ENVELOPE", 1
elif "/mutations/one-byte-sidecar/" in release:
    outcome, stage, code, rc = "RIGHTS_ADMISSION_REFUSED", 3, "REJECT_SIGNATURE_INTEGRITY", 1
elif "/mutations/one-byte-stored-artifact/" in release:
    outcome, stage, code, rc = "RIGHTS_ADMISSION_REFUSED", 5, "REJECT_ARTIFACT_DIGESTS", 1
else:
    outcome, stage, code, rc = "RIGHTS_ADMISSION_REFUSED", 6, "REJECT_RIGHTS_EVIDENCE", 0
label = Path(out).name
if os.environ.get("NDC_TEST_MISSING_CASE") == label:
    raise SystemExit(rc)
Path(out).parent.mkdir(parents=True, exist_ok=True)
if os.environ.get("NDC_TEST_MALFORMED_CASE") == label:
    Path(out).write_text("{not-json", encoding="utf-8")
    raise SystemExit(rc)
report = {
    "outcome": outcome,
    "refusal": {"stage": stage, "code": code},
    "admission_receipt": None,
    "receipt_written": False,
    "private_snapshot_survives": False,
    "rights_state": "UNKNOWN",
    "dataset_accepted": False,
    "collection_enabled": False,
    "live_execution_enabled": False,
    "stages": [{"status": "PASS"} for _ in range(5)] + [{"status": "NOT_RUN"}] * 2,
    "cleanup": {"cleanup_succeeded": True, "cleanup_pending": False},
}
Path(out).write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
raise SystemExit(rc)
'''

producer = root / "stubs" / "producer"
verifier = root / "stubs" / "verifier"
producer.parent.mkdir(parents=True)
for path, body in ((producer, producer_stub), (verifier, verifier_stub)):
    path.write_text(body, encoding="utf-8")
    path.chmod(0o755)

def write_sidecar(binary, repository, head, digest=None):
    sidecar = Path(str(binary) + ".ndc-provenance.json")
    sidecar.write_text(json.dumps({
        "schema_version": 1,
        "source_repository": repository,
        "source_head": head,
        "binary_sha256": digest or sha256(binary),
    }, indent=2) + "\n", encoding="utf-8")
    return sidecar

producer_sidecar = write_sidecar(producer, "fieldbook", fb_sha)
verifier_sidecar = write_sidecar(verifier, "nirnay", nr_sha)

fakebin = root / "fakebin"
fakebin.mkdir()
cargo_stub = fakebin / "cargo"
cargo_stub.write_text(r'''#!/usr/bin/env bash
set -euo pipefail
name=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bin) name="${2:?}"; shift 2 ;;
    *) shift ;;
  esac
done
case "$name" in
  ndc-conformance-producer) source="${NDC_TEST_STUB_PRODUCER:?}" ;;
  ndc-conformance-verifier) source="${NDC_TEST_STUB_VERIFIER:?}" ;;
  *) printf 'fake cargo: unexpected bin %s\n' "$name" >&2; exit 2 ;;
esac
mkdir -p target/release
cp "$source" "target/release/$name"
chmod +x "target/release/$name"
''', encoding="utf-8")
cargo_stub.chmod(0o755)

def load_json(path):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception:
        return None

def probe(name, env_extra=None, setup=None, expect_zero=True, omit_overrides=False):
    case_root = root / "cases" / name
    work = case_root / "work"
    out = case_root / "result.json"
    work.mkdir(parents=True, exist_ok=True)
    out.parent.mkdir(parents=True, exist_ok=True)
    if setup is not None:
        setup(out)
    env = os.environ.copy()
    for key in list(env):
        if key.startswith("NDC_TEST_") or key in {
            "NDC_WORKSPACE_ROOT", "NDC_CURRENT_STATE", "NDC_FIELDBOOK_DIR",
            "NDC_NIRNAY_DIR", "NDC_PRODUCER_BIN", "NDC_VERIFIER_BIN",
            "NDC_RUN_ID", "NIRNAY_B15_PRODUCER_REQUIRED",
        }:
            env.pop(key, None)
    env.update({
        "NDC_WORKSPACE_ROOT": str(root),
        "NDC_CURRENT_STATE": str(root / "CURRENT-STATE.json"),
        "NDC_FIELDBOOK_DIR": str(fieldbook),
        "NDC_NIRNAY_DIR": str(nirnay),
        "NDC_PRODUCER_BIN": str(producer),
        "NDC_VERIFIER_BIN": str(verifier),
        "NDC_RUN_ID": f"probe-{name}",
        "NIRNAY_B15_PRODUCER_REQUIRED": "1",
    })
    env.update(env_extra or {})
    if omit_overrides:
        for key in ("NDC_CURRENT_STATE", "NDC_FIELDBOOK_DIR", "NDC_NIRNAY_DIR",
                    "NDC_PRODUCER_BIN", "NDC_VERIFIER_BIN"):
            env.pop(key, None)
    result = run(["bash", str(script), "--out", str(out), "--work", str(work)], env=env,
                 check_setup=False)
    check(f"{name}: exit status", (result.returncode == 0) == expect_zero,
          f"rc={result.returncode} stderr={result.stderr.strip()[-300:]}")
    return result, out

def stale_setup(out):
    out.write_text(json.dumps({"result": "PASS", "run_id": "stale-run",
                               "source_heads": {}}, indent=2) + "\n", encoding="utf-8")

def blocked_setup(out):
    out.parent.mkdir(parents=True, exist_ok=True)
    out.parent.chmod(0o500)

result, out = probe("valid")
data = load_json(out)
check("valid: result JSON emitted", data is not None)
if data:
    check("valid: result PASS", data.get("result") == "PASS", str(data.get("result")))
    check("valid: run id is current", data.get("run_id") == "probe-valid", str(data.get("run_id")))
    heads = data.get("source_heads") or {}
    check("valid: source heads match", heads.get("fieldbook") == fb_sha
          and heads.get("nirnay") == nr_sha, str(heads))
    binaries = data.get("binaries") or {}
    check("valid: binary digests match",
          (binaries.get("producer") or {}).get("sha256") == sha256(producer)
          and (binaries.get("verifier") or {}).get("sha256") == sha256(verifier), str(binaries))
    cases = data.get("cases") or {}
    check("valid: all diagnostics PASS",
          len(cases) == 4 and all(c.get("status") == "PASS" for c in cases.values()), str(cases))
    overrides = data.get("diagnostic_overrides") or []
    check("valid: provenance labels overrides",
          "NDC_PRODUCER_BIN" in overrides and "NDC_VERIFIER_BIN" in overrides
          and (data.get("source_provenance") or {}).get("mode") == "local-diagnostic-overrides",
          str({"overrides": overrides, "provenance": data.get("source_provenance")}))

result, out = probe("emit_failure", setup=blocked_setup, expect_zero=False)
out.parent.chmod(0o700)
check("emit_failure: no PASS document on stdout", '"result": "PASS"' not in result.stdout)
check("emit_failure: result failure reported",
      "result" in result.stderr.lower() and "verif" in result.stderr.lower(),
      result.stderr.strip()[-300:])

result, out = probe("stale_result", env_extra={"NDC_TEST_MISSING_CASE": "rights.json"},
                    setup=stale_setup, expect_zero=False)
data = load_json(out)
check("stale_result: stale run id replaced", data is not None
      and data.get("run_id") == "probe-stale_result", str(data and data.get("run_id")))
check("stale_result: not a PASS result", data is not None and data.get("result") == "FAIL",
      str(data and data.get("result")))
result, out = probe("stale_result_valid", setup=stale_setup)
data = load_json(out)
check("stale_result_valid: fresh run id", data is not None
      and data.get("run_id") == "probe-stale_result_valid", str(data and data.get("run_id")))

probe("missing_diagnostic", env_extra={"NDC_TEST_MISSING_CASE": "rights.json"}, expect_zero=False)
probe("malformed_diagnostic", env_extra={"NDC_TEST_MALFORMED_CASE": "rights.json"}, expect_zero=False)

def dirty_setup(_out):
    dirty_path.write_bytes(dirty_bytes + b"local edit\n")

try:
    result, _ = probe("dirty_checkout", setup=dirty_setup, expect_zero=False)
    check("dirty_checkout: clean-tree refusal reported",
          "clean" in result.stderr.lower() or "modif" in result.stderr.lower(),
          result.stderr.strip()[-300:])
finally:
    dirty_path.write_bytes(dirty_bytes)

sidecar_body = producer_sidecar.read_bytes()
producer_sidecar.unlink()
try:
    result, _ = probe("prebuilt_no_provenance", expect_zero=False)
    check("prebuilt_no_provenance: provenance refusal reported",
          "provenance" in result.stderr.lower(), result.stderr.strip()[-300:])
finally:
    producer_sidecar.write_bytes(sidecar_body)

verifier_body = verifier_sidecar.read_bytes()
verifier_sidecar.unlink()
try:
    probe("verifier_no_provenance", expect_zero=False)
finally:
    verifier_sidecar.write_bytes(verifier_body)

producer_sidecar.write_text(json.dumps({
    "schema_version": 1,
    "source_repository": "fieldbook",
    "source_head": fb_sha,
    "binary_sha256": "00" * 32,
}, indent=2) + "\n", encoding="utf-8")
try:
    probe("provenance_digest_mismatch", expect_zero=False)
finally:
    producer_sidecar.write_bytes(sidecar_body)

result, out = probe("exact_source_build", env_extra={
    "PATH": f"{fakebin}:{os.environ.get('PATH', '')}",
    "NDC_TEST_STUB_PRODUCER": str(producer),
    "NDC_TEST_STUB_VERIFIER": str(verifier),
}, omit_overrides=True)
data = load_json(out)
check("exact_source_build: exact-source mode", data is not None
      and (data.get("source_provenance") or {}).get("mode") == "exact-source-build",
      str(data and data.get("source_provenance")))
check("exact_source_build: binaries built from recorded commit", data is not None
      and (data.get("result") == "PASS")
      and (data.get("binaries") or {}).get("producer", {}).get("source") == "built-from-recorded-commit"
      and (data.get("binaries") or {}).get("verifier", {}).get("source") == "built-from-recorded-commit",
      str(data and data.get("binaries")))

print(f"\n{'SELF-TEST FAILED' if failures else 'SELF-TEST OK'}: "
      f"{len(failures)} failing check(s): {failures}")
raise SystemExit(1 if failures else 0)
PY
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$WORK" ]]; then
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/ndc-cross-execution.XXXXXX")"
fi
mkdir -p "$WORK"
if [[ -z "$RESULT_JSON" ]]; then
  RESULT_JSON="$WORK/ndc-cross-execution.json"
fi
mkdir -p "$(dirname "$RESULT_JSON")" "$WORK/diagnostics" "$WORK/logs"

# A result from an earlier invocation is never evidence for this invocation.
if [[ -e "$RESULT_JSON" || -L "$RESULT_JSON" ]]; then
  rm -f -- "$RESULT_JSON" || die "cannot remove stale result JSON: $RESULT_JSON"
fi
[[ ! -e "$RESULT_JSON" && ! -L "$RESULT_JSON" ]] \
  || die "stale result JSON could not be removed: $RESULT_JSON"

RUN_ID="${NDC_RUN_ID:-}"
if [[ -z "$RUN_ID" ]]; then
  RUN_ID="$(python3 -c 'import uuid; print(uuid.uuid4().hex)')" \
    || die "cannot generate a run id for the result document"
fi
[[ "$RUN_ID" =~ ^[A-Za-z0-9._-]{1,128}$ ]] || die "invalid run id: $RUN_ID"

DIAGNOSTIC_OVERRIDES=()
for name in NDC_WORKSPACE_ROOT NDC_CURRENT_STATE NDC_FIELDBOOK_DIR \
            NDC_NIRNAY_DIR NDC_PRODUCER_BIN NDC_VERIFIER_BIN NDC_RUN_ID; do
  if [[ -n "${!name:-}" ]]; then
    DIAGNOSTIC_OVERRIDES+=("$name")
  fi
done
OVERRIDES_CSV="$(IFS=,; printf '%s' "${DIAGNOSTIC_OVERRIDES[*]:-}")"
SOURCE_PROVENANCE_MODE="exact-source-build"
if [[ -n "${NDC_CURRENT_STATE:-}" || -n "${NDC_FIELDBOOK_DIR:-}" \
      || -n "${NDC_NIRNAY_DIR:-}" || -n "${NDC_PRODUCER_BIN:-}" \
      || -n "${NDC_VERIFIER_BIN:-}" ]]; then
  SOURCE_PROVENANCE_MODE="local-diagnostic-overrides"
fi

STATUS="FAIL"
REASON="gate did not complete"
FB_SHA=""
NR_SHA=""
FB_HEAD=""
NR_HEAD=""
PRODUCER_BIN=""
PRODUCER_SHA=""
PRODUCER_SOURCE=""
PRODUCER_PROVENANCE=""
VERIFIER_BIN=""
VERIFIER_SHA=""
VERIFIER_SOURCE=""
VERIFIER_PROVENANCE=""
SPEC_SHA=""
BASE_SPEC_SHA=""
RELEASE_DIR=""
EXPECTED_MUTATIONS=""
CLEAN_TREE_CHECKED="no"

sha256_file() {
  local path="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$path" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | awk '{print $1}'
  else
    printf 'no SHA-256 command available\n' >&2
    return 1
  fi
}

emit_json() {
  python3 - \
    "$RESULT_JSON" "$STATUS" "$REASON" "$WORK" \
    "$FB_SHA" "$NR_SHA" "$FB_HEAD" "$NR_HEAD" \
    "$PRODUCER_BIN" "$PRODUCER_SHA" "$PRODUCER_SOURCE" \
    "$VERIFIER_BIN" "$VERIFIER_SHA" "$VERIFIER_SOURCE" \
    "$SPEC_SHA" "$BASE_SPEC_SHA" "$RELEASE_DIR" "$EXPECTED_MUTATIONS" \
    "$RUN_ID" "$OVERRIDES_CSV" "$SOURCE_PROVENANCE_MODE" \
    "$PRODUCER_PROVENANCE" "$VERIFIER_PROVENANCE" "$CLEAN_TREE_CHECKED" <<'PY'
import json
import os
import sys
from pathlib import Path

(out, status, reason, work, fb_sha, nr_sha, fb_head, nr_head,
 producer, producer_sha, producer_source, verifier, verifier_sha,
 verifier_source, spec_sha, base_spec_sha, release_dir, expected,
 run_id, overrides_csv, mode, producer_provenance, verifier_provenance,
 clean_checked) = sys.argv[1:25]

def relative(path):
    if not path:
        return None
    try:
        return Path(path).resolve().relative_to(Path(work).resolve()).as_posix()
    except (ValueError, OSError):
        return path

def case(name, path, expected_outcome=None, expected_stage=None, expected_code=None):
    p = Path(path) if path else None
    if p is None or not p.is_file():
        return {"status": "MISSING", "diagnostic": None, "expected": {
            "outcome": expected_outcome, "refusal_stage": expected_stage,
            "refusal_code": expected_code}}
    report = json.loads(p.read_text(encoding="utf-8"))
    refusal = report.get("refusal") or {}
    entry = {
        "status": "PASS",
        "expected": {"outcome": expected_outcome, "refusal_stage": expected_stage,
                     "refusal_code": expected_code},
        "diagnostic": relative(p),
        "outcome": report.get("outcome"),
        "refusal_stage": refusal.get("stage"),
        "refusal_code": refusal.get("code"),
        "admission_receipt": report.get("admission_receipt"),
        "receipt_written": report.get("receipt_written"),
        "private_snapshot_survives": report.get("private_snapshot_survives"),
        "rights_state": report.get("rights_state"),
        "cleanup": report.get("cleanup"),
    }
    expected_values = (expected_outcome, expected_stage, expected_code)
    actual_values = (report.get("outcome"), refusal.get("stage"), refusal.get("code"))
    if any(want is not None and got != want
           for want, got in zip(expected_values, actual_values)):
        entry["status"] = "FAIL"
    return entry

record = {
    "schema_version": 1,
    "gate": "ndc-required-cross-repository-integration",
    "run_id": run_id,
    "result": status.upper(),
    "failure_reason": None if status == "PASS" else reason,
    "producer_required": True,
    "nirnay_b15_producer_required": "1",
    "source_heads": {"fieldbook": fb_sha or None, "nirnay": nr_sha or None},
    "checked_out_heads": {"fieldbook": fb_head or None, "nirnay": nr_head or None},
    "binaries": {
        "producer": {"path": producer or None, "sha256": producer_sha or None,
                     "source": producer_source or None,
                     "provenance": relative(producer_provenance)},
        "verifier": {"path": verifier or None, "sha256": verifier_sha or None,
                     "source": verifier_source or None,
                     "provenance": relative(verifier_provenance)},
    },
    "diagnostic_overrides": overrides_csv.split(",") if overrides_csv else [],
    "source_provenance": {
        "mode": mode,
        "clean_tree_checked": clean_checked == "yes",
        "note": (
            "Local diagnostic overrides are recorded here and require a verified "
            "source-provenance sidecar; they do not replace the hosted exact-source build."
        ),
        "fieldbook": {"head": fb_head or None, "clean": clean_checked == "yes",
                      "binary_provenance": relative(producer_provenance)},
        "nirnay": {"head": nr_head or None, "clean": clean_checked == "yes",
                   "binary_provenance": relative(verifier_provenance)},
    },
    "producer_output": {
        "base_spec_sha256": base_spec_sha or None,
        "spec_sha256": spec_sha or None,
        "spec_source": "derived-from-committed-abstract-fixture",
        "spec_derivation": (
            "TEST_ONLY identity bindings aligned to the verifier binary's in-tree "
            "conformance registry: event_type=event-type-example, "
            "schema_id=payload-example, schema_version=1, "
            "structural schema digest recomputed, record scalar kinds set to string. "
            "All scalars remain abstract non-market values."
        ),
        "release": relative(release_dir),
        "fabricated": False,
        "method": "fieldbook::distribution::ndc_release::build_release via ndc-conformance-producer",
    },
    "cases": {
        "rights_typed_refusal": case("rights_typed_refusal",
            os.path.join(work, "diagnostics", "rights.json"),
            "RIGHTS_ADMISSION_REFUSED", 6, "REJECT_RIGHTS_EVIDENCE"),
        "one_byte_manifest": case("one_byte_manifest",
            os.path.join(work, "diagnostics", "one-byte-manifest.json"),
            "PREFLIGHT_REFUSED", 1, "REJECT_SCHEMA_ENVELOPE"),
        "one_byte_sidecar": case("one_byte_sidecar",
            os.path.join(work, "diagnostics", "one-byte-sidecar.json"),
            "RIGHTS_ADMISSION_REFUSED", 3, "REJECT_SIGNATURE_INTEGRITY"),
        "one_byte_stored_artifact": case("one_byte_stored_artifact",
            os.path.join(work, "diagnostics", "one-byte-stored-artifact.json"),
            "RIGHTS_ADMISSION_REFUSED", 5, "REJECT_ARTIFACT_DIGESTS"),
    },
    "rights": {
        "state": "UNKNOWN",
        "admission_receipt": None,
        "admission_simulated": False,
        "rights_grant_simulated": False,
    },
    "boundaries": {
        "provider_contact": False,
        "data_collection": False,
        "experiment": False,
        "holdout": False,
        "d11_market_shaped_data": False,
        "live_execution": False,
        "freeze_changed": False,
    },
    "evidence": {"work_dir": work, "expected_mutations": expected.split(",") if expected else []},
}
Path(out).write_text(json.dumps(record, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
}

verify_result_json() {
  python3 - \
    "$RESULT_JSON" "$RUN_ID" "$STATUS" "$REASON" "$WORK" \
    "$FB_SHA" "$NR_SHA" "$FB_HEAD" "$NR_HEAD" \
    "$PRODUCER_SHA" "$VERIFIER_SHA" "$SPEC_SHA" "$BASE_SPEC_SHA" \
    "$EXPECTED_MUTATIONS" "$OVERRIDES_CSV" "$SOURCE_PROVENANCE_MODE" <<'PY'
import json
import sys
from pathlib import Path

(out, run_id, status, reason, work, fb_sha, nr_sha, fb_head, nr_head,
 producer_sha, verifier_sha, spec_sha, base_spec_sha, expected,
 overrides_csv, mode) = sys.argv[1:17]

def fail(message):
    raise SystemExit(f"result verification failed: {message}")

def equal(label, actual, wanted):
    if actual != wanted:
        fail(f"{label}: got {actual!r}, expected {wanted!r}")

def no_duplicate_keys(pairs):
    record = {}
    for key, value in pairs:
        if key in record:
            raise ValueError(f"duplicate key {key!r}")
        record[key] = value
    return record

path = Path(out)
if not path.is_file() or path.stat().st_size == 0:
    fail(f"result file is missing or empty: {out}")
try:
    data = json.loads(path.read_text(encoding="utf-8"),
                      object_pairs_hook=no_duplicate_keys)
except Exception as error:
    fail(f"result file is not valid JSON: {error}")
if not isinstance(data, dict):
    fail("result document is not a JSON object")

equal("run_id", data.get("run_id"), run_id)
equal("schema_version", data.get("schema_version"), 1)
equal("gate", data.get("gate"), "ndc-required-cross-repository-integration")
equal("result", data.get("result"), status.upper())
equal("failure_reason", data.get("failure_reason"), None if status == "PASS" else reason)
equal("producer_required", data.get("producer_required"), True)
equal("nirnay_b15_producer_required", data.get("nirnay_b15_producer_required"), "1")

heads = data.get("source_heads") or {}
equal("source_heads.fieldbook", heads.get("fieldbook"), fb_sha or None)
equal("source_heads.nirnay", heads.get("nirnay"), nr_sha or None)
checked = data.get("checked_out_heads") or {}
equal("checked_out_heads.fieldbook", checked.get("fieldbook"), fb_head or None)
equal("checked_out_heads.nirnay", checked.get("nirnay"), nr_head or None)

binaries = data.get("binaries") or {}
for label, digest in (("producer", producer_sha), ("verifier", verifier_sha)):
    entry = binaries.get(label) or {}
    equal(f"binaries.{label}.sha256", entry.get("sha256"), digest or None)

producer_output = data.get("producer_output") or {}
equal("producer_output.base_spec_sha256",
      producer_output.get("base_spec_sha256"), base_spec_sha or None)
equal("producer_output.spec_sha256",
      producer_output.get("spec_sha256"), spec_sha or None)

evidence = data.get("evidence") or {}
equal("evidence.work_dir", evidence.get("work_dir"), work)
equal("evidence.expected_mutations", evidence.get("expected_mutations"),
      expected.split(",") if expected else [])

equal("diagnostic_overrides", data.get("diagnostic_overrides"),
      overrides_csv.split(",") if overrides_csv else [])
provenance = data.get("source_provenance") or {}
equal("source_provenance.mode", provenance.get("mode"), mode)
equal("rights.state", (data.get("rights") or {}).get("state"), "UNKNOWN")

cases = data.get("cases") or {}
expected_cases = {"rights_typed_refusal", "one_byte_manifest",
                  "one_byte_sidecar", "one_byte_stored_artifact"}
if status == "PASS":
    equal("source_provenance.clean_tree_checked",
          provenance.get("clean_tree_checked"), True)
    equal("cases", set(cases), expected_cases)
    for name, entry in cases.items():
        if not isinstance(entry, dict) or entry.get("status") != "PASS":
            fail(f"case {name} is not PASS")
        diagnostic = entry.get("diagnostic")
        if not diagnostic:
            fail(f"case {name} has no diagnostic path")
        target = Path(diagnostic)
        if not target.is_absolute():
            target = Path(work) / target
        if not target.is_file():
            fail(f"case {name} diagnostic is missing: {target}")
PY
}

on_exit() {
  local code=$?
  trap - EXIT
  if [[ "$code" -ne 0 ]]; then
    STATUS="FAIL"
    if [[ -z "$REASON" || "$REASON" == "gate did not complete" ]]; then
      REASON="script exited with status $code before completion"
    fi
  fi
  if ! emit_json >"$WORK/logs/emit.log" 2>&1; then
    printf 'could not write result JSON: %s\n' "$WORK/logs/emit.log" >&2
  fi
  if ! verify_result_json >&2; then
    printf 'result JSON does not describe this run; refusing to report success\n' >&2
    rm -f -- "$RESULT_JSON" || true
    if [[ "$code" -eq 0 ]]; then
      code=1
    fi
  fi
  if [[ -f "$RESULT_JSON" ]]; then
    cat "$RESULT_JSON"
  fi
  exit "$code"
}
trap on_exit EXIT

# Required-mode semantics: the upstream Nirnay harness still supports an
# optional SKIP, but this gate never does. Any value other than 1 is refused.
if [[ "${NIRNAY_B15_PRODUCER_REQUIRED:-1}" != "1" ]]; then
  die "NIRNAY_B15_PRODUCER_REQUIRED must be 1 for the required gate"
fi
export NIRNAY_B15_PRODUCER_REQUIRED=1

run_logged() {
  # Run a child with stdout/stderr captured; never let child stdout reach our
  # stdout, which is reserved for the single result JSON document.
  local log="$1"
  shift
  "$@" >"$log" 2>&1
}

git_head() {
  local dir="$1"
  git -C "$dir" rev-parse HEAD 2>/dev/null
}

require_exact_head() {
  local dir="$1" expected="$2" label="$3"
  [[ -d "$dir/.git" || -f "$dir/.git" ]] || die "$label checkout is missing: $dir"
  local actual
  actual="$(git_head "$dir")" || die "$label has no resolvable HEAD"
  [[ "$actual" == "$expected" ]] || die "$label head disagreement: actual=$actual expected=$expected"
  printf '%s\n' "$actual"
}

require_clean_tree() {
  local dir="$1" label="$2"
  local changes
  changes="$(git -C "$dir" status --porcelain 2>/dev/null)" \
    || die "$label working-tree status could not be read: $dir"
  [[ -z "$changes" ]] \
    || die "$label checkout is not clean; exact-source builds require no local changes: $dir"
}

require_binary_provenance() {
  local binary="$1" repository="$2" head="$3" label="$4"
  local sidecar="${binary}.ndc-provenance.json"
  [[ -f "$sidecar" && -s "$sidecar" ]] \
    || die "$label prebuilt binary has no verified source provenance: $sidecar"
  python3 - "$sidecar" "$repository" "$head" "$binary" <<'PY' \
    || die "$label binary source provenance did not verify"
import hashlib
import json
import sys

sidecar, repository, head, binary = sys.argv[1:5]
try:
    data = json.load(open(sidecar, encoding="utf-8"))
except Exception as error:
    raise SystemExit(f"unreadable provenance: {error}")
def equal(name, actual, wanted):
    if actual != wanted:
        raise SystemExit(f"provenance {name} is {actual!r}, expected {wanted!r}")
equal("schema_version", data.get("schema_version"), 1)
equal("source_repository", data.get("source_repository"), repository)
equal("source_head", data.get("source_head"), head)
with open(binary, "rb") as stream:
    digest = hashlib.sha256(stream.read()).hexdigest()
equal("binary_sha256", data.get("binary_sha256"), digest)
PY
  printf '%s\n' "$sidecar"
}

assert_diagnostic() {
  local file="$1" label="$2" outcome="$3" stage="$4" code="$5"
  [[ -f "$file" ]] || die "$label: verifier wrote no diagnostic"
  python3 - "$file" "$label" "$outcome" "$stage" "$code" <<'PY'
import json
import sys
path, label, outcome, stage, code = sys.argv[1:6]
try:
    report = json.load(open(path, encoding="utf-8"))
except Exception as error:
    raise SystemExit(f"{label}: unreadable diagnostic: {error}")
refusal = report.get("refusal") or {}
checks = [
    ("outcome", report.get("outcome"), outcome),
    ("refusal stage", refusal.get("stage"), int(stage)),
    ("refusal code", refusal.get("code"), code),
    ("admission receipt", report.get("admission_receipt"), None),
    ("receipt_written", report.get("receipt_written"), False),
    ("private_snapshot_survives", report.get("private_snapshot_survives"), False),
    ("rights_state", report.get("rights_state"), "UNKNOWN"),
    ("dataset_accepted", report.get("dataset_accepted"), False),
    ("collection_enabled", report.get("collection_enabled"), False),
    ("live_execution_enabled", report.get("live_execution_enabled"), False),
]
for name, actual, expected in checks:
    if actual != expected:
        raise SystemExit(f"{label}: {name} is {actual!r}, expected {expected!r}")
PY
}

assert_rights_diagnostic() {
  local file="$1"
  assert_diagnostic "$file" "rights typed refusal" \
    "RIGHTS_ADMISSION_REFUSED" 6 "REJECT_RIGHTS_EVIDENCE"
  python3 - "$file" <<'PY'
import json
import sys
report = json.load(open(sys.argv[1], encoding="utf-8"))
stages = report.get("stages") or []
for index in range(5):
    if index >= len(stages) or stages[index].get("status") != "PASS":
        raise SystemExit(f"rights refusal: stage {index + 1} did not pass")
if len(stages) < 7 or stages[6].get("status") != "NOT_RUN":
    raise SystemExit("rights refusal: later stages must not run")
cleanup = report.get("cleanup") or {}
if cleanup.get("cleanup_succeeded") is not True or cleanup.get("cleanup_pending") is not False:
    raise SystemExit("rights refusal: cleanup did not complete")
PY
}

run_verifier() {
  local release="$1" out="$2" label="$3" expect_success="$4"
  local log="$WORK/logs/$label.log"
  local code=0
  set +e
  run_logged "$log" "$VERIFIER_BIN" --release "$release" --out "$out"
  code=$?
  set -e
  printf '%s verifier exit=%s\n' "$label" "$code" >&2
  [[ -f "$out" ]] || die "$label: verifier produced no diagnostic (exit $code): $log"
  if [[ "$expect_success" == "yes" && "$code" -ne 0 ]]; then
    die "$label: verifier rejected the conforming release (exit $code): $log"
  fi
  if [[ "$expect_success" == "no" && "$code" -eq 0 ]]; then
    die "$label: verifier accepted a case that must be refused: $log"
  fi
}

mutate_release() {
  local label="$1" relative_target="$2"
  local dir="$WORK/mutations/$label"
  local staged="$dir/tree/$pub_id/$ds_id/$rel_id"
  rm -rf "$dir"
  mkdir -p "$(dirname "$staged")"
  cp -R "$RELEASE_DIR" "$staged"
  python3 - "$staged/$relative_target" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
if not path.is_file():
    raise SystemExit(f"mutation target is not a file: {path}")
data = bytearray(path.read_bytes())
if not data:
    raise SystemExit(f"empty file cannot be mutated: {path}")
data[0] ^= 0x01
path.write_bytes(data)
PY
  printf '%s\n' "$staged"
}

# 1. Authority: read both exact heads from CURRENT-STATE.json.
[[ -f "$CURRENT_STATE" ]] || die "CURRENT-STATE.json is missing: $CURRENT_STATE"
head_output="$(python3 - "$CURRENT_STATE" <<'PY'
import json
import re
import sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
source = data["source_heads_at_record_time"]
values = [source["fieldbook"], source["nirnay"]]
for value in values:
    if not isinstance(value, str) or not re.fullmatch(r"[0-9a-f]{40}", value):
        raise SystemExit(f"invalid recorded commit SHA: {value!r}")
print(values[0])
print(values[1])
PY
)" || die "cannot read exact heads from CURRENT-STATE.json"
FB_SHA="$(printf '%s\n' "$head_output" | sed -n '1p')"
NR_SHA="$(printf '%s\n' "$head_output" | sed -n '2p')"
[[ -n "$FB_SHA" && -n "$NR_SHA" ]] || die "CURRENT-STATE.json did not yield two exact heads"

# An explicit override is allowed only when it agrees with the authority.
if [[ -n "${FIELDBOOK_SHA:-}" && "$FIELDBOOK_SHA" != "$FB_SHA" ]]; then
  die "Fieldbook SHA disagreement: supplied=$FIELDBOOK_SHA recorded=$FB_SHA"
fi
if [[ -n "${NIRNAY_SHA:-}" && "$NIRNAY_SHA" != "$NR_SHA" ]]; then
  die "Nirnay SHA disagreement: supplied=$NIRNAY_SHA recorded=$NR_SHA"
fi

# 2. Both builds must use the exact recorded checkouts.
FB_HEAD="$(require_exact_head "$FIELDBOOK_DIR" "$FB_SHA" "Fieldbook")" \
  || die "Fieldbook checkout failed the exact-head check"
NR_HEAD="$(require_exact_head "$NIRNAY_DIR" "$NR_SHA" "Nirnay")" \
  || die "Nirnay checkout failed the exact-head check"
require_clean_tree "$FIELDBOOK_DIR" "Fieldbook" \
  || die "Fieldbook checkout failed the clean-tree check"
require_clean_tree "$NIRNAY_DIR" "Nirnay" \
  || die "Nirnay checkout failed the clean-tree check"
CLEAN_TREE_CHECKED="yes"

# 3. Producer is required. A supplied path is a local diagnostic override:
#    it is accepted only with a provenance sidecar that binds the exact source
#    head to the bytes actually executed; otherwise the committed source is
#    built from the exact clean head.
if [[ -n "${NDC_PRODUCER_BIN:-}" ]]; then
  PRODUCER_BIN="$NDC_PRODUCER_BIN"
  PRODUCER_SOURCE="supplied-executable-with-verified-source-provenance"
else
  run_logged "$WORK/logs/producer-build.log" \
    bash -c 'cd "$1" && cargo build --release --locked --bin ndc-conformance-producer' \
    _ "$FIELDBOOK_DIR" || die "Fieldbook producer build failed: $WORK/logs/producer-build.log"
  PRODUCER_BIN="$FIELDBOOK_DIR/target/release/ndc-conformance-producer"
  PRODUCER_SOURCE="built-from-recorded-commit"
fi
[[ -f "$PRODUCER_BIN" && -s "$PRODUCER_BIN" && -x "$PRODUCER_BIN" ]] \
  || die "required producer binary missing, empty or not executable: $PRODUCER_BIN"
PRODUCER_SHA="$(sha256_file "$PRODUCER_BIN")" || die "cannot hash producer binary"
if [[ -n "${NDC_PRODUCER_BIN:-}" ]]; then
  PRODUCER_PROVENANCE="$(require_binary_provenance "$PRODUCER_BIN" fieldbook "$FB_SHA" producer)" \
    || die "producer provenance check failed"
fi

# Export the Nirnay harness contract. The binary has been proven to exist, so
# the optional SKIP path can never be reached from this gate.
export NIRNAY_B15_PRODUCER_BIN="$PRODUCER_BIN"
export NIRNAY_B15_PRODUCER_COMMIT="$FB_SHA"

# 4. Verifier is built from the recorded Nirnay head.
if [[ -n "${NDC_VERIFIER_BIN:-}" ]]; then
  VERIFIER_BIN="$NDC_VERIFIER_BIN"
  VERIFIER_SOURCE="supplied-executable-with-verified-source-provenance"
else
  run_logged "$WORK/logs/verifier-build.log" \
    bash -c 'cd "$1" && cargo build --release --locked --bin ndc-conformance-verifier' \
    _ "$NIRNAY_DIR" || die "Nirnay verifier build failed: $WORK/logs/verifier-build.log"
  VERIFIER_BIN="$NIRNAY_DIR/target/release/ndc-conformance-verifier"
  VERIFIER_SOURCE="built-from-recorded-commit"
fi
[[ -f "$VERIFIER_BIN" && -s "$VERIFIER_BIN" && -x "$VERIFIER_BIN" ]] \
  || die "required verifier binary missing, empty or not executable: $VERIFIER_BIN"
VERIFIER_SHA="$(sha256_file "$VERIFIER_BIN")" || die "cannot hash verifier binary"
if [[ -n "${NDC_VERIFIER_BIN:-}" ]]; then
  VERIFIER_PROVENANCE="$(require_binary_provenance "$VERIFIER_BIN" nirnay "$NR_SHA" verifier)" \
    || die "verifier provenance check failed"
fi

# 5. Run the real producer on an abstract, non-market spec. The committed
# Fieldbook fixture is the base. The standalone Nirnay verifier binary is bound
# to its own TEST_ONLY structural schema registry, so only the TEST_ONLY
# identity bindings are aligned here: event type, schema id/version, the
# recomputed structural schema digest and record scalar kinds. Every scalar
# remains abstract. No release byte is written by this script; the real
# producer builds the release through the Fieldbook production core.
BASE_SPEC="$FIELDBOOK_DIR/tests/fixtures/ndc/producer-spec-example.json"
[[ -f "$BASE_SPEC" ]] || die "producer spec fixture is missing: $BASE_SPEC"
BASE_SPEC_SHA="$(sha256_file "$BASE_SPEC")" || die "cannot hash base producer spec"
mkdir -p "$WORK/producer"
SPEC="$WORK/producer/derived-spec.json"
python3 - "$BASE_SPEC" "$SPEC" <<'PY'
import hashlib
import json
import sys

source, destination = sys.argv[1], sys.argv[2]
spec = json.load(open(source, encoding="utf-8"))

# Constants mirror the TEST_ONLY registry in Nirnay's
# crates/release-verifier/src/bin/ndc-conformance-verifier.rs.
event_type = "event-type-example"
schema_id = "payload-example"
schema_version = "1"
field_name = "abstract-field"
field_kind = "string"
schema_format = "nirnay-structural-payload-v1"

def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"),
                      ensure_ascii=False).encode("utf-8")

schema_bytes = canonical({
    "format": schema_format,
    "event_type": event_type,
    "required_fields": [{"field_name": field_name, "kind": field_kind}],
})
schema_digest = hashlib.sha256(schema_bytes).hexdigest()

# One registry entry: the verifier's local registry has one binding and the
# Fieldbook builder refuses duplicate event types.
spec["evidence"]["payload_schemas"] = [{
    "event_type": event_type,
    "schema_id": schema_id,
    "schema_version": schema_version,
    "digest_sha256": schema_digest,
}]
for artifact in spec["artifacts"]:
    for record in artifact["records"]:
        payload_record = json.loads(record["bytes"])
        payload_record["event_type"] = event_type
        for field in payload_record["payload"]["fields"]:
            field["kind"] = field_kind
            if not isinstance(field["value"], str):
                field["value"] = (str(field["value"]).lower()
                                  if isinstance(field["value"], bool)
                                  else str(field["value"]))
        record["bytes"] = canonical(payload_record).decode("utf-8")

with open(destination, "w", encoding="utf-8") as stream:
    stream.write(json.dumps(spec, indent=2, sort_keys=True) + "\n")
PY
[[ -f "$SPEC" ]] || die "derived producer spec was not written"
SPEC_SHA="$(sha256_file "$SPEC")" || die "cannot hash derived producer spec"
run_logged "$WORK/logs/producer-run.log" \
  "$PRODUCER_BIN" --spec "$SPEC" --out "$WORK/producer/release-root" \
  || die "producer run failed: $WORK/logs/producer-run.log"

while IFS= read -r -d '' candidate; do
  if [[ -f "$candidate/manifest.json" && -f "$candidate/signature.json" && -d "$candidate/artifacts" ]]; then
    RELEASE_DIR="$candidate"
    break
  fi
done < <(find "$WORK/producer/release-root" -mindepth 1 -maxdepth 4 -type d -print0 2>/dev/null)
[[ -n "$RELEASE_DIR" ]] || die "producer emitted no complete release directory; no output was fabricated"

# The verifier resolves the trusted root from a release path shaped
# <root>/<publisher>/<dataset>/<release>. Place the real producer bytes at that
# shape; this relocates output only and never rewrites or fabricates it.
release_identity="$(python3 - "$RELEASE_DIR/manifest.json" <<'PY'
import json
import sys
manifest = json.load(open(sys.argv[1], encoding="utf-8"))
publisher = manifest["publication_identity"]["publisher_identity"]
dataset = manifest["source_scope"]["dataset_id"]
release = manifest["release_identity"]["release_id"]
for value in (publisher, dataset, release):
    if not isinstance(value, str) or not value or "/" in value or value in (".", ".."):
        raise SystemExit(f"unsafe release identity component: {value!r}")
print(publisher, dataset, release)
PY
)" || die "cannot read release identity from producer manifest"
read -r pub_id ds_id rel_id <<< "$release_identity"
[[ -n "${pub_id:-}" && -n "${ds_id:-}" && -n "${rel_id:-}" ]] \
  || die "producer manifest has an incomplete release identity"
STAGED_RELEASE="$WORK/release-tree/$pub_id/$ds_id/$rel_id"
mkdir -p "$(dirname "$STAGED_RELEASE")"
cp -R "$RELEASE_DIR" "$STAGED_RELEASE"
RELEASE_DIR="$STAGED_RELEASE"

ARTIFACT_REL="$(python3 - "$RELEASE_DIR" <<'PY'
import sys
from pathlib import Path
root = Path(sys.argv[1])
files = sorted(p for p in (root / "artifacts").iterdir() if p.is_file())
if not files:
    raise SystemExit("producer release has no artifact file")
print(files[0].relative_to(root).as_posix())
PY
)" || die "cannot identify a stored artifact in the producer output"

# 6. Unmodified release: interoperability plus typed refusal at rights.
run_verifier "$RELEASE_DIR" "$WORK/diagnostics/rights.json" "rights" "yes"
assert_rights_diagnostic "$WORK/diagnostics/rights.json"

# 7. One-byte mutations of the real producer output must stay typed.
EXPECTED_MUTATIONS="one-byte-manifest,one-byte-sidecar,one-byte-stored-artifact"

mutated="$(mutate_release "one-byte-manifest" "manifest.json")" || die "manifest mutation failed"
run_verifier "$mutated" "$WORK/diagnostics/one-byte-manifest.json" "one-byte-manifest" "no"
assert_diagnostic "$WORK/diagnostics/one-byte-manifest.json" "one-byte manifest" \
  "PREFLIGHT_REFUSED" 1 "REJECT_SCHEMA_ENVELOPE"

mutated="$(mutate_release "one-byte-sidecar" "signature.json")" || die "sidecar mutation failed"
run_verifier "$mutated" "$WORK/diagnostics/one-byte-sidecar.json" "one-byte-sidecar" "no"
assert_diagnostic "$WORK/diagnostics/one-byte-sidecar.json" "one-byte sidecar" \
  "RIGHTS_ADMISSION_REFUSED" 3 "REJECT_SIGNATURE_INTEGRITY"

mutated="$(mutate_release "one-byte-stored-artifact" "$ARTIFACT_REL")" || die "artifact mutation failed"
run_verifier "$mutated" "$WORK/diagnostics/one-byte-stored-artifact.json" "one-byte-stored-artifact" "no"
assert_diagnostic "$WORK/diagnostics/one-byte-stored-artifact.json" "one-byte stored artifact" \
  "RIGHTS_ADMISSION_REFUSED" 5 "REJECT_ARTIFACT_DIGESTS"

STATUS="PASS"
REASON=""
exit 0
