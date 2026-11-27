#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# M8 deterministic workspace-orchestrated end-to-end paper path.
#
# This gate composes two exact-source builds and two neutral fixtures into one
# evidence document. It is a REQUIRED gate: there is no SKIP, no simulated
# producer output and no fabricated adapter result. If a check fails, the gate
# emits a FAIL (or BLOCKED) JSON and exits non-zero.
#
# Invariants enforced here:
#   * Fieldbook and Nirnay heads come from CURRENT-STATE.json only; the exact
#     checkouts used for the builds must be at those heads and have clean trees.
#   * The producer, verifier and paper engine are built from those commits with
#     an isolated CARGO_TARGET_DIR; their bytes are hashed. A supplied binary is
#     a local diagnostic override and needs a provenance sidecar.
#   * The NDC fixture is abstract and non-market. The verifier must refuse it at
#     stage 6 with typed REJECT_RIGHTS_EVIDENCE, with no admission receipt and
#     no rights grant. A pass is interoperability plus correct refusal.
#   * The paper replay uses a neutral abstract fixture only. It must be replay
#     deterministic, must show the typed risk verdict and OMS/account effect in
#     the account journal, and must never create a real order or admission.
#   * A Fieldbook -> Nirnay neutral adapter is REQUIRED for a cross-repository
#     claim. The committed workspace adapter converts a rights-refused NDC
#     release into opaque, sequence-only events.jsonl bytes. A linked adapter
#     supports ONLY a neutral, rights-refused fixture claim; the market-shaped
#     standalone paper replay is reported separately and is never relabelled as
#     cross-repository evidence. No adapter means a recorded blocker.
#   * Deployment qualification is machine-readable. Static checks and temporary
#     directory-only, fail-closed drills (restart/kill, fault refusals, backup
#     restore) run here; no deployment occurs. Q5 operator readiness and G9 stay
#     BLOCKED because no production authorization exists.
#
# No provider contact, collection, experiment, holdout, market-shaped data,
# live execution, freeze change or rights grant occurs. No secret is read.

# shellcheck shell=bash
set -euo pipefail

die() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Usage: scripts/e2e_paper_path.sh [--out RESULT_JSON] [--work WORK_DIR]
       scripts/e2e_paper_path.sh --self-test

Optional environment:
  E2E_WORKSPACE_ROOT    workspace root (default: parent of this script)
  E2E_CURRENT_STATE     authority JSON (default: <root>/CURRENT-STATE.json)
  E2E_FIELDBOOK_DIR     Fieldbook checkout (default: <root>/fieldbook)
  E2E_NIRNAY_DIR        Nirnay checkout (default: <root>/nirnay)
  E2E_PRODUCER_BIN      diagnostic producer override + <path>.paper-provenance.json
  E2E_VERIFIER_BIN      diagnostic verifier override + <path>.paper-provenance.json
  E2E_PAPER_BIN         diagnostic paper engine override + provenance sidecar
  E2E_PAPER_ADAPTER_BIN diagnostic NDC->paper adapter override + provenance sidecar
  E2E_RUN_ID            explicit run id for the result document (diagnostic use)
  FIELDBOOK_SHA         expected head; must equal CURRENT-STATE.json
  NIRNAY_SHA            expected head; must equal CURRENT-STATE.json

A provenance sidecar is JSON with schema_version=1, source_repository,
source_head and binary_sha256. Overrides are recorded in the result and replace
the exact-source build only for local diagnostics; they never relax a check.

Exit codes: 0 is reserved for a fully qualified PASS (not reachable while G9
is BLOCKED), 3 BLOCKED (fail-closed evidence emitted; adapter absent or
operator readiness unavailable), 1 FAIL (an assertion failed). All diagnostics
go to stderr; stdout is one JSON.
USAGE
}

ROOT="${E2E_WORKSPACE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CURRENT_STATE="${E2E_CURRENT_STATE:-$ROOT/CURRENT-STATE.json}"
FIELDBOOK_DIR="${E2E_FIELDBOOK_DIR:-$ROOT/fieldbook}"
NIRNAY_DIR="${E2E_NIRNAY_DIR:-$ROOT/nirnay}"
WORK=""
RESULT_JSON=""

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

run_logged() {
  local log="$1"
  shift
  "$@" >"$log" 2>&1
}

git_head() {
  git -C "$1" rev-parse HEAD 2>/dev/null
}

require_exact_head() {
  local dir="$1" expected="$2" label="$3"
  [[ -d "$dir/.git" || -f "$dir/.git" ]] || die "$label checkout is missing: $dir"
  local actual
  actual="$(git_head "$dir")" || die "$label has no resolvable HEAD"
  [[ "$actual" == "$expected" ]] \
    || die "$label head disagreement: actual=$actual expected=$expected"
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
  local sidecar="${binary}.paper-provenance.json"
  [[ -f "$sidecar" && -s "$sidecar" ]] \
    || die "$label prebuilt binary has no verified source provenance: $sidecar"
  python3 - "$sidecar" "$repository" "$head" "$binary" "$label" <<'PYPROV' \
    || die "$label binary source provenance did not verify"
import hashlib
import json
import sys
sidecar, repository, head, binary, label = sys.argv[1:6]
try:
    data = json.load(open(sidecar, encoding="utf-8"))
except Exception as error:
    raise SystemExit(f"{label}: unreadable provenance: {error}")
for name, actual, wanted in (
    ("schema_version", data.get("schema_version"), 1),
    ("source_repository", data.get("source_repository"), repository),
    ("source_head", data.get("source_head"), head),
):
    if actual != wanted:
        raise SystemExit(f"{label}: provenance {name} is {actual!r}, expected {wanted!r}")
with open(binary, "rb") as stream:
    digest = hashlib.sha256(stream.read()).hexdigest()
if data.get("binary_sha256") != digest:
    raise SystemExit(f"{label}: provenance digest does not match executed bytes")
PYPROV
  printf '%s\n' "$sidecar"
}

require_adapter_provenance() {
  local binary="$1" head="$2"
  local sidecar="${binary}.paper-provenance.json"
  [[ -f "$sidecar" && -s "$sidecar" ]] \
    || die "paper adapter has no verified source provenance: $sidecar"
  python3 - "$sidecar" "$head" "$binary" <<'PYADAPT' \
    || die "paper adapter source provenance did not verify"
import hashlib
import json
import sys
sidecar, head, binary = sys.argv[1:4]
try:
    data = json.load(open(sidecar, encoding="utf-8"))
except Exception as error:
    raise SystemExit(f"unreadable adapter provenance: {error}")
if data.get("schema_version") != 1:
    raise SystemExit("adapter provenance schema_version must be 1")
if data.get("source_repository") not in ("fieldbook", "nirnay", "workspace"):
    raise SystemExit("adapter provenance has an unknown source_repository")
if data.get("source_head") not in (head, "workspace-authority"):
    raise SystemExit("adapter provenance source_head is not an authority head")
with open(binary, "rb") as stream:
    digest = hashlib.sha256(stream.read()).hexdigest()
if data.get("binary_sha256") != digest:
    raise SystemExit("adapter provenance digest does not match executed bytes")
PYADAPT
  printf '%s\n' "$sidecar"
}

assert_verifier_diagnostic() {
  local file="$1" label="$2" outcome="$3" stage="$4" code="$5"
  [[ -f "$file" ]] || die "$label: verifier wrote no diagnostic"
  python3 - "$file" "$label" "$outcome" "$stage" "$code" <<'PYASSERT'
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
PYASSERT
}

assert_rights_diagnostic() {
  local file="$1"
  assert_verifier_diagnostic "$file" "rights typed refusal" \
    "RIGHTS_ADMISSION_REFUSED" 6 "REJECT_RIGHTS_EVIDENCE"
  python3 - "$file" <<'PYRIGHTS'
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
PYRIGHTS
}

# Parse the neutral paper run's NRJ journal into a typed summary. Body frames
# are length-prefixed big-endian JSON; only the documented envelope/body shape
# is accepted. No hash implementation is duplicated here: the binary's own
# verification report is recorded separately as the integrity evidence.
parse_journal() {
  local journal_dir="$1" out="$2"
  python3 - "$journal_dir" "$out" <<'PYJOURNAL'
import hashlib
import json
import struct
import sys
from pathlib import Path

root = Path(sys.argv[1])
out = Path(sys.argv[2])
segments = sorted(root.rglob("*.nrj")) if root.is_dir() else []
if not segments:
    raise SystemExit("paper journal has no NRJ segment")
events = []
body_digest = hashlib.sha256()
expected = 1
for segment in segments:
    data = segment.read_bytes()
    offset = 0
    while offset < len(data):
        if data[offset:offset + 4] != b"NRJ1":
            raise SystemExit("paper journal frame has no NRJ1 signature")
        version, flags = struct.unpack_from(">HH", data, offset + 4)
        length = struct.unpack_from(">I", data, offset + 8)[0]
        sequence = struct.unpack_from(">Q", data, offset + 12)[0]
        if version != 1 or flags != 0 or length == 0:
            raise SystemExit("paper journal frame header is invalid")
        end = offset + 84 + length
        if end > len(data):
            raise SystemExit("paper journal frame body is truncated")
        body = data[offset + 84:end]
        if sequence != expected:
            raise SystemExit("paper journal sequence is not contiguous")
        record = json.loads(body.decode("utf-8"))
        envelope = record.get("envelope") or {}
        payload = record.get("payload") or {}
        if not envelope.get("event_id") or len(payload) != 1:
            raise SystemExit("paper journal body is not a typed event")
        kind = next(iter(payload))
        events.append({"sequence": sequence, "kind": kind, "body": payload[kind]})
        body_digest.update(sequence.to_bytes(8, "big"))
        body_digest.update(body)
        expected += 1
        offset = end
content_digest = hashlib.sha256()
for segment in segments:
    content_digest.update(segment.read_bytes())
summary = {
    "segments": [p.name for p in segments],
    "record_count": len(events),
    "body_chain_sha256": body_digest.hexdigest(),
    "content_sha256": content_digest.hexdigest(),
    "events": events,
}
out.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PYJOURNAL
}

check_owner_paths() {
  python3 - "$FIELDBOOK_DIR" "$NIRNAY_DIR" "$CURRENT_STATE" "$ROOT" <<'PYOWNER'
import json
import subprocess
import sys
from pathlib import Path

fb, nr, state, workspace_root = sys.argv[1:5]
data = json.load(open(state, encoding="utf-8"))
heads = data["source_heads_at_record_time"]
authority_root = Path(workspace_root).resolve()
declared_root = Path(workspace_root).absolute()
failures = []
for label, directory in (("fieldbook", fb), ("nirnay", nr)):
    path = Path(directory)
    resolved = path.resolve()
    if path.name != label:
        failures.append(f"{label}: directory name is {path.name!r}")
    try:
        relative = resolved.relative_to(authority_root)
    except ValueError:
        failures.append(f"{label}: path is not derived from the workspace authority root")
        relative = None
    if relative is not None:
        # Components between the declared root and the checkout must not be
        # symlinks; OS aliases above the root (/var -> /private/var) are out
        # of scope and are resolved by relative_to above.
        candidate = declared_root / relative
        current = candidate
        while current != declared_root and current != current.parent:
            if current.is_symlink():
                failures.append(f"{label}: checkout path contains a symlink component")
                break
            current = current.parent
    top = subprocess.run(["git", "-C", str(path), "rev-parse", "--show-toplevel"],
                         capture_output=True, text=True)
    if top.returncode != 0 or Path(top.stdout.strip()).resolve() != resolved:
        failures.append(f"{label}: git toplevel is not the owner-derived path")
    changes = subprocess.run(["git", "-C", str(path), "status", "--porcelain"],
                             capture_output=True, text=True)
    if changes.returncode != 0 or changes.stdout.strip():
        failures.append(f"{label}: checkout is not clean")
    head = subprocess.run(["git", "-C", str(path), "rev-parse", "HEAD"],
                          capture_output=True, text=True)
    if head.returncode != 0 or head.stdout.strip() != heads[label]:
        failures.append(f"{label}: head does not match the recorded authority head")
for failure in failures:
    print(f"FAIL {failure}", file=sys.stderr)
raise SystemExit(1 if failures else 0)
PYOWNER
}

check_sentinel_policy() {
  python3 - "$NIRNAY_DIR/crates/risk-authority/src/authority.rs" <<'PYSENTINEL'
import re
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text(encoding="utf-8")
start = source.find("pub struct AuthorityOwnership")
end = source.find("impl Drop for AuthorityOwnership")
if start < 0 or end <= start:
    raise SystemExit("AuthorityOwnership declaration was not found")
block = source[start:end]
failures = []
if "create_new(true)" not in block:
    failures.append("stale sentinel is not refused with create_new")
if re.search(r"(?i)\bpid\b|process::id|kill\s*\(|age_ns", block):
    failures.append("sentinel acquisition contains PID or age based clearing")
if "a stale M4 sentinel is refused" not in source:
    failures.append("stale sentinel refusal test is absent")
for failure in failures:
    print(f"FAIL {failure}", file=sys.stderr)
raise SystemExit(1 if failures else 0)
PYSENTINEL
}

# Q2: a neutral process is started in a temporary directory, killed with SIGKILL
# after it has fsynced one opaque checkpoint, then restarted to extend the same
# journal. Only durable bytes and monotonically increasing sequences are read.
# No deployment, broker, order or live process is involved.
check_restart_kill() {
  local work="$1" case_dir
  case_dir="$(mktemp -d "$work/qualification/q2.XXXXXX")" \
    || die "cannot create restart/kill drill directory"
  Q2_CASE="$case_dir"
  python3 - "$work" "$case_dir" <<'PYQ2'
import hashlib
import json
import os
import signal
import subprocess
import sys
import time
from pathlib import Path

work, case_dir = map(Path, sys.argv[1:3])
summary = work / "qualification" / "q2.json"
state = case_dir / "state.jsonl"
account = case_dir / "account.json"
ready = case_dir / "ready"
child = case_dir / "neutral_paper_process.py"
child.write_text(r'''import hashlib, json, os, struct, sys, time
from pathlib import Path
state, ready, mode = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
def append(sequence):
    opaque = hashlib.sha256(f"m8-q2-opaque:{sequence}".encode()).hexdigest()
    row = json.dumps({"sequence": sequence, "kind": "OPAQUE_CHECKPOINT",
                      "opaque_bytes": opaque}, sort_keys=True, separators=(",", ":"))
    with state.open("a", encoding="utf-8") as stream:
        stream.write(row + "\n")
        stream.flush()
        os.fsync(stream.fileno())
if mode == "first":
    append(1)
    account = state.parent / "account.json"
    data = json.dumps({"account": "abstract-neutral", "sequence": 1,
                       "state_digest": hashlib.sha256(state.read_bytes()).hexdigest()},
                      sort_keys=True, separators=(",", ":"))
    account.write_text(data + "\n", encoding="utf-8")
    ready.write_text("ready\n", encoding="utf-8")
    while True:
        time.sleep(0.05)
else:
    rows = [json.loads(line) for line in state.read_text(encoding="utf-8").splitlines()]
    last = rows[-1]["sequence"]
    for sequence in range(last + 1, last + 3):
        append(sequence)
''', encoding="utf-8")

def parsed():
    rows = [json.loads(line) for line in state.read_text(encoding="utf-8").splitlines()]
    for index, row in enumerate(rows, 1):
        if row.get("sequence") != index or row.get("kind") != "OPAQUE_CHECKPOINT":
            raise SystemExit(f"Q2: durable state is not contiguous and opaque at {index}")
        if len(row.get("opaque_bytes", "")) != 64:
            raise SystemExit(f"Q2: opaque checkpoint bytes are malformed at {index}")
    return rows, hashlib.sha256(state.read_bytes()).hexdigest()

environment = dict(os.environ)
process = subprocess.Popen([sys.executable, str(child), str(state), str(ready), "first"],
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=environment)
deadline = time.monotonic() + 15
while not ready.is_file() and time.monotonic() < deadline:
    if process.poll() is not None:
        raise SystemExit("Q2: neutral process exited before its durable checkpoint")
    time.sleep(0.02)
if not ready.is_file():
    process.kill()
    raise SystemExit("Q2: neutral process never published its durable checkpoint")
os.kill(process.pid, signal.SIGKILL)
_, errors = process.communicate(timeout=10)
if process.returncode != -signal.SIGKILL:
    raise SystemExit(f"Q2: process was not terminated by SIGKILL: {process.returncode}")
if os.path.exists(f"/proc/{process.pid}") or subprocess.run(
        ["kill", "-0", str(process.pid)], capture_output=True).returncode == 0:
    raise SystemExit("Q2: process survived termination")
before, digest_before = parsed()
if len(before) != 1 or not account.is_file():
    raise SystemExit("Q2: durable journal/account state is missing after termination")
if os.environ.get("E2E_TEST_DRILL_RESTART_FAIL") == "1":
    summary.write_text(json.dumps({"id": "Q2", "status": "FAIL",
                                   "reason": "injected restart drill failure"},
                                  sort_keys=True) + "\n", encoding="utf-8")
    raise SystemExit(1)
restart = subprocess.run([sys.executable, str(child), str(state), str(ready), "restart"],
                         capture_output=True, text=True, env=environment)
if restart.returncode != 0:
    raise SystemExit(f"Q2: restart failed: {restart.stderr.strip()}")
after, digest_after = parsed()
if len(after) != 3 or [row["sequence"] for row in after] != [1, 2, 3]:
    raise SystemExit("Q2: restarted process did not extend the journal monotonically")
if after[0] != before[0] or digest_after == digest_before:
    raise SystemExit("Q2: durable state changed across restart")
summary.write_text(json.dumps({
    "id": "Q2", "status": "PASS",
    "method": "SIGKILL of a temporary-directory neutral process; durable bytes read after termination and after restart",
    "termination_signal": "SIGKILL",
    "records_after_termination": len(before),
    "digest_after_termination": digest_before,
    "records_after_restart": len(after),
    "digest_after_restart": digest_after,
    "sequence_monotonic": True,
    "deployment_executed": False,
}, sort_keys=True, indent=2) + "\n", encoding="utf-8")
PYQ2
}

# Q3: fail-closed refusals are probed only inside temporary directories. Disk
# full is a simulated capacity limit, not host disk exhaustion; permissions,
# symlinks and path replacement are injected on probe-owned temp paths.
check_fault_refusals() {
  local work="$1" case_dir
  case_dir="$(mktemp -d "$work/qualification/q3.XXXXXX")" \
    || die "cannot create fault-refusal drill directory"
  python3 - "$work" "$case_dir" <<'PYQ3'
import json
import os
import subprocess
import sys
from pathlib import Path

work, case_dir = map(Path, sys.argv[1:3])
summary = work / "qualification" / "q3.json"
probe = case_dir / "fail_closed_probe.py"
probe.write_text(r'''import json, os, stat, sys
from pathlib import Path
mode, root_text, target_text = sys.argv[1:4]
root = Path(root_text).resolve()
target = Path(target_text)
capacity = int(os.environ.get("NDC_PROBE_CAPACITY_BYTES", "1024"))

def refuse(code):
    print(json.dumps({"status": "REFUSED", "code": code}), file=sys.stderr)
    raise SystemExit(2)

if target.is_absolute() or ".." in target.parts:
    refuse("REFUSE_PATH_ESCAPE")
resolved_parent = (root / target.parent).resolve()
if not resolved_parent.is_relative_to(root):
    refuse("REFUSE_PATH_ESCAPE")
candidate = root / target
component = root
for part in target.parts:
    component = component / part
    if component.is_symlink():
        refuse("REFUSE_SYMLINK")
payload = b"m8-neutral-fault-probe-payload"
if len(payload) > capacity:
    refuse("REFUSE_DISK_FULL")
if not resolved_parent.is_dir() or not os.access(resolved_parent, os.W_OK) \
        or not (resolved_parent.stat().st_mode & stat.S_IWUSR):
    refuse("REFUSE_PERMISSION")
if candidate.exists() and candidate.is_symlink():
    refuse("REFUSE_SYMLINK")
if mode == "simulate-replacement":
    outside = root / "replacement-target"
    outside.write_bytes(b"original-outside-bytes")
    candidate.parent.mkdir(parents=True, exist_ok=True)
    if candidate.exists() or candidate.is_symlink():
        candidate.unlink()
    candidate.symlink_to(outside)
    if not candidate.is_symlink() or candidate.resolve() != outside.resolve():
        refuse("REFUSE_PATH_REPLACEMENT")
    refuse("REFUSE_PATH_REPLACEMENT")
candidate.parent.mkdir(parents=True, exist_ok=True)
candidate.write_bytes(payload)
print(json.dumps({"status": "ACCEPTED", "bytes": len(payload)}))
''', encoding="utf-8")

results = []
for case in ("disk_full", "permission", "symlink", "path_replacement"):
    directory = case_dir / case
    directory.mkdir()
    target = directory / "opaque.bin"
    mode = "simulate-replacement" if case == "path_replacement" else "normal"
    capacity = "4" if case == "disk_full" else "1024"
    if case == "symlink":
        outside = directory / "outside.bin"
        outside.write_bytes(b"unchanged-outside-bytes")
        target.symlink_to(outside)
    environment = dict(os.environ, NDC_PROBE_CAPACITY_BYTES=capacity)
    if case == "permission":
        directory.chmod(0o500)
    try:
        run = subprocess.run([sys.executable, str(probe), mode, str(directory), target.name],
                             capture_output=True, text=True, env=environment)
    finally:
        if case == "permission":
            directory.chmod(0o700)
    if run.returncode == 0:
        raise SystemExit(f"Q3: {case} probe accepted an unsafe write")
    try:
        refusal = json.loads(run.stderr.strip().splitlines()[-1])
    except Exception as error:
        raise SystemExit(f"Q3: {case} probe emitted no typed refusal: {error}")
    expected = {"disk_full": "REFUSE_DISK_FULL", "permission": "REFUSE_PERMISSION",
                "symlink": "REFUSE_SYMLINK",
                "path_replacement": "REFUSE_PATH_REPLACEMENT"}[case]
    if refusal.get("status") != "REFUSED" or refusal.get("code") != expected:
        raise SystemExit(f"Q3: {case} refusal was {refusal}, expected {expected}")
    if case == "symlink":
        if (directory / "outside.bin").read_bytes() != b"unchanged-outside-bytes":
            raise SystemExit("Q3: symlink target was modified")
    elif case == "path_replacement":
        if target.is_symlink() and target.resolve().read_bytes() != b"original-outside-bytes":
            raise SystemExit("Q3: replaced path target was modified")
    elif target.exists():
        raise SystemExit(f"Q3: {case} probe wrote an output file")
    results.append({"case": case, "status": "PASS", "refusal": expected})
if os.environ.get("E2E_TEST_DRILL_FAULT_FAIL") == "1":
    summary.write_text(json.dumps({"id": "Q3", "status": "FAIL",
                                   "reason": "injected fault drill failure"},
                                  sort_keys=True) + "\n", encoding="utf-8")
    raise SystemExit(1)
summary.write_text(json.dumps({
    "id": "Q3", "status": "PASS", "scope": "temporary-directory fail-closed probes only",
    "simulated_disk_full": True, "host_disk_exhausted": False,
    "cases": results, "deployment_executed": False,
}, sort_keys=True, indent=2) + "\n", encoding="utf-8")
PYQ3
}

# Q4: digest-equivalent backup/restore of the neutral journal/account state
# produced by Q2. All copies stay inside temporary directories.
check_backup_restore() {
  local work="$1" source_case="$2" case_dir
  case_dir="$(mktemp -d "$work/qualification/q4.XXXXXX")" \
    || die "cannot create backup/restore drill directory"
  python3 - "$work" "$source_case" "$case_dir" <<'PYQ4'
import hashlib
import json
import os
import shutil
import sys
from pathlib import Path

work, source, case_dir = map(Path, sys.argv[1:4])
summary = work / "qualification" / "q4.json"
names = ("state.jsonl", "account.json")
originals = {name: source / name for name in names}
if not all(path.is_file() for path in originals.values()):
    raise SystemExit("Q4: neutral journal/account state is missing")

def digest_map(root):
    return {name: hashlib.sha256((root / name).read_bytes()).hexdigest() for name in names}

def combined(mapping):
    preimage = json.dumps(mapping, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(preimage).hexdigest()

before = digest_map(source)
backup = case_dir / "backup"
backup.mkdir()
for name in names:
    shutil.copyfile(originals[name], backup / name)
manifest = {"schema_version": 1, "files": [
    {"name": name, "sha256": before[name], "bytes": (backup / name).stat().st_size}
    for name in names]}
(backup / "backup-manifest.json").write_text(
    json.dumps(manifest, sort_keys=True, indent=2) + "\n", encoding="utf-8")
restored = case_dir / "restored"
restored.mkdir()
for entry in manifest["files"]:
    source_file = backup / entry["name"]
    if hashlib.sha256(source_file.read_bytes()).hexdigest() != entry["sha256"]:
        raise SystemExit(f"Q4: backup digest drift for {entry['name']}")
    shutil.copyfile(source_file, restored / entry["name"])
after = digest_map(restored)
if after != before or combined(after) != combined(before):
    raise SystemExit("Q4: restored state is not digest-equivalent")
for name in names:
    if (restored / name).read_bytes() != (source / name).read_bytes():
        raise SystemExit(f"Q4: restored bytes differ for {name}")
if os.environ.get("E2E_TEST_DRILL_BACKUP_FAIL") == "1":
    summary.write_text(json.dumps({"id": "Q4", "status": "FAIL",
                                   "reason": "injected backup drill failure"},
                                  sort_keys=True) + "\n", encoding="utf-8")
    raise SystemExit(1)
summary.write_text(json.dumps({
    "id": "Q4", "status": "PASS", "scope": "temporary-directory backup/restore of neutral journal/account bytes",
    "files": list(names), "file_count": len(names),
    "digest_before": combined(before), "digest_after": combined(after),
    "digest_equivalent": True, "deployment_executed": False,
}, sort_keys=True, indent=2) + "\n", encoding="utf-8")
PYQ4
}

# Result evidence is written and re-verified: a build with unwritable, stale or
# inconsistent evidence is never reported as a pass.
emit_json() {
  E2E_EVID_STATUS="${STATUS:-FAIL}" \
  E2E_EVID_REASON="${REASON:-}" \
  E2E_EVID_RUN_ID="${RUN_ID:-}" \
  E2E_EVID_WORK="${WORK:-}" \
  E2E_EVID_FB_SHA="${FB_SHA:-}" \
  E2E_EVID_NR_SHA="${NR_SHA:-}" \
  E2E_EVID_FB_HEAD="${FB_HEAD:-}" \
  E2E_EVID_NR_HEAD="${NR_HEAD:-}" \
  E2E_EVID_PRODUCER="${PRODUCER_BIN:-}" \
  E2E_EVID_PRODUCER_SHA="${PRODUCER_SHA:-}" \
  E2E_EVID_PRODUCER_SOURCE="${PRODUCER_SOURCE:-}" \
  E2E_EVID_PRODUCER_PROV="${PRODUCER_PROVENANCE:-}" \
  E2E_EVID_VERIFIER="${VERIFIER_BIN:-}" \
  E2E_EVID_VERIFIER_SHA="${VERIFIER_SHA:-}" \
  E2E_EVID_VERIFIER_SOURCE="${VERIFIER_SOURCE:-}" \
  E2E_EVID_VERIFIER_PROV="${VERIFIER_PROVENANCE:-}" \
  E2E_EVID_PAPER="${PAPER_BIN:-}" \
  E2E_EVID_PAPER_SHA="${PAPER_SHA:-}" \
  E2E_EVID_PAPER_SOURCE="${PAPER_SOURCE:-}" \
  E2E_EVID_SPEC_SHA="${SPEC_SHA:-}" \
  E2E_EVID_BASE_SPEC_SHA="${BASE_SPEC_SHA:-}" \
  E2E_EVID_RELEASE="${RELEASE_DIR:-}" \
  E2E_EVID_OVERRIDES="${OVERRIDES_CSV:-}" \
  E2E_EVID_MODE="${SOURCE_PROVENANCE_MODE:-}" \
  E2E_EVID_CLEAN="${CLEAN_TREE_CHECKED:-}" \
  E2E_EVID_ADAPTER_STATUS="${ADAPTER_STATUS:-}" \
  E2E_EVID_ADAPTER_SOURCE="${ADAPTER_SOURCE:-}" \
  E2E_EVID_ADAPTER_SHA="${ADAPTER_SHA:-}" \
  E2E_EVID_ADAPTER_CANDIDATES="${ADAPTER_CANDIDATES_CSV:-}" \
  E2E_EVID_ADAPTER_NEUTRAL_SHA="${ADAPTER_NEUTRAL_SHA:-}" \
  E2E_EVID_ADAPTER_DETERMINISM="${ADAPTER_DETERMINISM:-}" \
  E2E_EVID_ADAPTER_SCOPE="${ADAPTER_SCOPE:-}" \
  E2E_EVID_DATASET_SHA="${DATASET_SHA:-}" \
  E2E_EVID_DATASET_SOURCE="${DATASET_SOURCE:-}" \
  E2E_EVID_PAPER_SPEC_SHA="${PAPER_SPEC_SHA:-}" \
  E2E_EVID_REPLAY_DIGEST="${REPLAY_DIGEST:-}" \
  E2E_EVID_RISK_BASELINE_SUMMARY="${RISK_BASELINE_SUMMARY:-}" \
  E2E_EVID_RISK_TIGHT_SUMMARY="${RISK_TIGHT_SUMMARY:-}" \
  E2E_EVID_QUAL_OWNER="${QUAL_OWNER_STATUS:-}" \
  E2E_EVID_QUAL_SENTINEL="${QUAL_SENTINEL_STATUS:-}" \
  E2E_EVID_QUAL_RESTART="${QUAL_RESTART_STATUS:-}" \
  E2E_EVID_QUAL_FAULT="${QUAL_FAULT_STATUS:-}" \
  E2E_EVID_QUAL_BACKUP="${QUAL_BACKUP_STATUS:-}" \
  python3 - "$RESULT_JSON" <<'PYEMIT'
import json
import os
import sys
from pathlib import Path

out = Path(sys.argv[1])
env = os.environ

def value(name):
    return env.get(f"E2E_EVID_{name}", "") or None

def object_value(name):
    raw = value(name)
    if not raw:
        return None
    try:
        return json.loads(raw)
    except Exception:
        return raw

def relative(path):
    if not path:
        return None
    try:
        return Path(path).resolve().relative_to(Path(value("WORK")).resolve()).as_posix()
    except (ValueError, OSError):
        return path

def diagnostic(name):
    path = Path(value("WORK")) / "diagnostics" / name
    return relative(str(path)) if path.is_file() else None

def refused(path, outcome, stage, code):
    target = Path(value("WORK")) / "diagnostics" / path
    if not target.is_file():
        return {"status": "MISSING", "diagnostic": None}
    report = json.loads(target.read_text(encoding="utf-8"))
    refusal = report.get("refusal") or {}
    actual = (report.get("outcome"), refusal.get("stage"), refusal.get("code"))
    expected = (outcome, stage, code)
    return {
        "status": "PASS" if actual == expected else "FAIL",
        "diagnostic": relative(str(target)),
        "expected": {"outcome": outcome, "stage": stage, "code": code},
        "actual": {"outcome": actual[0], "stage": actual[1], "code": actual[2]},
        "receipt_written": report.get("receipt_written"),
        "rights_state": report.get("rights_state"),
    }

status = value("STATUS")
def flag(status_text):
    return status_text == "PASS"

def check(identifier, name, status, implemented_by, evidence, reason=None):
    item = {"id": identifier, "name": name, "status": status or "FAIL",
            "implemented_by": implemented_by, "evidence": evidence}
    if reason:
        item["reason"] = reason
    return item

qualification = [
    check("Q0", "owner_path_derivation", value("QUAL_OWNER"),
          "scripts/e2e_paper_path.sh:check_owner_paths",
          "e2e-paper-path.json:qualification.checks.Q0"),
    check("Q1", "stale_sentinel_runbook_no_pid_or_age_clearing", value("QUAL_SENTINEL"),
          "scripts/e2e_paper_path.sh:check_sentinel_policy",
          "nirnay/crates/risk-authority/src/authority.rs:AuthorityOwnership; "
          "e2e-paper-path.json:qualification.checks.Q1"),
    check("Q2", "restart_kill", value("QUAL_RESTART"),
          "scripts/e2e_paper_path.sh:check_restart_kill",
          "qualification/q2.json; temporary-directory neutral process only"),
    check("Q3", "disk_full_permission_symlink_path_replacement", value("QUAL_FAULT"),
          "scripts/e2e_paper_path.sh:check_fault_refusals",
          "qualification/q3.json; simulated capacity and temporary-directory probes only"),
    check("Q4", "backup_restore", value("QUAL_BACKUP"),
          "scripts/e2e_paper_path.sh:check_backup_restore",
          "qualification/q4.json; temporary-directory neutral journal/account state only"),
    check("Q5", "operator_readiness", "BLOCKED",
          "not automatable: requires written owner authorization",
          "CURRENT-STATE.json:open_owner_decisions",
          "No operator authorization or production readiness exists; this check cannot be automated."),
]

gates = {
    "G0": "PASS" if value("CLEAN") == "yes" and value("FB_SHA") and value("NR_SHA") else "FAIL",
    "G1": "PASS" if value("PRODUCER_SHA") and value("VERIFIER_SHA") and value("PAPER_SHA") else "FAIL",
    "G2": "PASS" if relative(value("RELEASE")) and refused("rights.json", "RIGHTS_ADMISSION_REFUSED", 6, "REJECT_RIGHTS_EVIDENCE")["status"] == "PASS" else "FAIL",
    "G3": "PASS" if refused("rights.json", "RIGHTS_ADMISSION_REFUSED", 6, "REJECT_RIGHTS_EVIDENCE")["status"] == "PASS" else "FAIL",
    "G4": "PASS" if value("REPLAY_DIGEST") and value("DATASET_SHA") else "FAIL",
    "G5": "PASS" if value("RISK_BASELINE_SUMMARY") and value("RISK_TIGHT_SUMMARY") else "FAIL",
    "G6": "PASS" if value("ADAPTER_STATUS") == "linked" else "BLOCKED",
    "G7": (value("QUAL_OWNER") or "FAIL"),
    "G8": (value("QUAL_SENTINEL") or "FAIL"),
    "G9": "BLOCKED",
    "G10": "EXTERNAL",
}

gate_explanations = {
    "G6": ("Neutral adapter linked for the rights-refused NDC fixture only; "
           "no market data or production paper execution is admitted."
           if value("ADAPTER_STATUS") == "linked" else
           "No verified neutral adapter links the Fieldbook release to a paper dataset."),
    "G9": ("Q2/Q3/Q4 temporary-directory drills are executable evidence, but "
           "Q5 operator readiness/authorization is BLOCKED; no deployment, "
           "D1+ durability, power-loss or production readiness is claimed."),
}

record = {
    "schema_version": 1,
    "gate": "m8-e2e-paper-path",
    "run_id": value("RUN_ID"),
    "result": (status or "FAIL").upper(),
    "failure_reason": None if status == "PASS" else value("REASON"),
    "source_heads": {"fieldbook": value("FB_SHA"), "nirnay": value("NR_SHA")},
    "checked_out_heads": {"fieldbook": value("FB_HEAD"), "nirnay": value("NR_HEAD")},
    "source_provenance": {
        "mode": value("MODE"),
        "clean_tree_checked": value("CLEAN") == "yes",
        "diagnostic_overrides": value("OVERRIDES").split(",") if value("OVERRIDES") else [],
    },
    "binaries": {
        "producer": {"path": value("PRODUCER"), "sha256": value("PRODUCER_SHA"),
                     "source": value("PRODUCER_SOURCE"), "provenance": relative(value("PRODUCER_PROV"))},
        "verifier": {"path": value("VERIFIER"), "sha256": value("VERIFIER_SHA"),
                     "source": value("VERIFIER_SOURCE"), "provenance": relative(value("VERIFIER_PROV"))},
        "paper_engine": {"path": value("PAPER"), "sha256": value("PAPER_SHA"),
                         "source": value("PAPER_SOURCE")},
    },
    "neutral_fixture": {
        "base_spec_sha256": value("BASE_SPEC_SHA"),
        "derived_spec_sha256": value("SPEC_SHA"),
        "spec_source": "committed-abstract-fieldbook-fixture-with-test-only-identity-bindings",
        "release": relative(value("RELEASE")),
        "paper_dataset_sha256": value("DATASET_SHA"),
        "paper_dataset_source": value("DATASET_SOURCE"),
        "paper_spec_sha256": value("PAPER_SPEC_SHA"),
        "adapted_neutral_dataset_sha256": value("ADAPTER_NEUTRAL_SHA"),
        "adapted_dataset_determinism": value("ADAPTER_DETERMINISM"),
        "market_data_admitted": False,
        "fabricated_release": False,
    },
    "rights": {
        "state": "UNKNOWN",
        "state_at_boundary": value("REASON"),
        "receipt": None,
        "admission_simulated": False,
        "rights_grant_simulated": False,
        "case": refused("rights.json", "RIGHTS_ADMISSION_REFUSED", 6, "REJECT_RIGHTS_EVIDENCE"),
        "mutation_sentinel": refused("one-byte-manifest.json", "PREFLIGHT_REFUSED", 1, "REJECT_SCHEMA_ENVELOPE"),
    },
    "paper_path": {
        "adapter": {
            "status": value("ADAPTER_STATUS"),
            "source": value("ADAPTER_SOURCE"),
            "binary_sha256": value("ADAPTER_SHA"),
            "candidates_checked": value("ADAPTER_CANDIDATES").split(",") if value("ADAPTER_CANDIDATES") else [],
            "cross_repository_claim": value("ADAPTER_STATUS") == "linked",
            "claim_scope": value("ADAPTER_SCOPE"),
            "rights_refused_only": value("ADAPTER_STATUS") == "linked",
            "neutral_dataset_sha256": value("ADAPTER_NEUTRAL_SHA"),
            "determinism": value("ADAPTER_DETERMINISM"),
            "claim_text": ("Fieldbook NDC release manifest/digests were converted, under a typed "
                           "stage 6 REJECT_RIGHTS_EVIDENCE refusal, into deterministic opaque "
                           "sequence-only events.jsonl bytes. No rights admission, instrument, "
                           "price, quote, trade, strategy, market data, receipt or live execution "
                           "is claimed. The standalone market-shaped paper replay is a separate "
                           "workspace fixture and is not cross-repository evidence."
                           if value("ADAPTER_STATUS") == "linked" else
                           "No cross-repository claim; adapter absent or unverified."),
        },
        "replay_digest": value("REPLAY_DIGEST"),
        "risk_baseline": object_value("RISK_BASELINE_SUMMARY"),
        "risk_tight": object_value("RISK_TIGHT_SUMMARY"),
        "journals": {
            "baseline": relative(str(Path(value("WORK")) / "paper" / "baseline" / "journal-summary.json")),
            "baseline_replay": relative(str(Path(value("WORK")) / "paper" / "baseline-replay" / "journal-summary.json")),
            "tight": relative(str(Path(value("WORK")) / "paper" / "tight" / "journal-summary.json")),
        },
        "reports": {
            "baseline": relative(str(Path(value("WORK")) / "paper" / "baseline" / "run-report.json")),
            "baseline_replay": relative(str(Path(value("WORK")) / "paper" / "baseline-replay" / "run-report.json")),
            "tight": relative(str(Path(value("WORK")) / "paper" / "tight" / "run-report.json")),
        },
    },
    "qualification": {
        "mode": "machine-readable static checks plus temporary-directory-only fail-closed drills; no deployment",
        "checks": qualification,
    },
    "gates": gates,
    "gate_explanations": gate_explanations,
    "boundaries": {
        "provider_contact": False,
        "data_collection": False,
        "experiment": False,
        "holdout": False,
        "market_data_admitted": False,
        "live_execution": False,
        "freeze_changed": False,
        "rights_granted": False,
        "deployment_executed": False,
    },
}
out.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PYEMIT
}

verify_result_json() {
  E2E_EVID_STATUS="${STATUS:-FAIL}" \
  E2E_EVID_RUN_ID="${RUN_ID:-}" \
  E2E_EVID_FB_SHA="${FB_SHA:-}" \
  E2E_EVID_NR_SHA="${NR_SHA:-}" \
  E2E_EVID_PRODUCER_SHA="${PRODUCER_SHA:-}" \
  E2E_EVID_VERIFIER_SHA="${VERIFIER_SHA:-}" \
  E2E_EVID_PAPER_SHA="${PAPER_SHA:-}" \
  E2E_EVID_REPLAY_DIGEST="${REPLAY_DIGEST:-}" \
  E2E_EVID_ADAPTER_STATUS="${ADAPTER_STATUS:-}" \
  E2E_EVID_ADAPTER_NEUTRAL_SHA="${ADAPTER_NEUTRAL_SHA:-}" \
  E2E_EVID_ADAPTER_DETERMINISM="${ADAPTER_DETERMINISM:-}" \
  E2E_EVID_QUAL_OWNER="${QUAL_OWNER_STATUS:-}" \
  E2E_EVID_QUAL_SENTINEL="${QUAL_SENTINEL_STATUS:-}" \
  E2E_EVID_QUAL_RESTART="${QUAL_RESTART_STATUS:-}" \
  E2E_EVID_QUAL_FAULT="${QUAL_FAULT_STATUS:-}" \
  E2E_EVID_QUAL_BACKUP="${QUAL_BACKUP_STATUS:-}" \
  python3 - "$RESULT_JSON" "$RUN_ID" <<'PYVERIFY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.is_file() or path.stat().st_size == 0:
    raise SystemExit("result verification failed: evidence file is missing or empty")
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except Exception as error:
    raise SystemExit(f"result verification failed: invalid JSON: {error}")

def equal(label, actual, wanted):
    if actual != wanted:
        raise SystemExit(f"result verification failed: {label} is {actual!r}, expected {wanted!r}")

import os
equal("run_id", data.get("run_id"), os.environ.get("E2E_EVID_RUN_ID"))
equal("schema_version", data.get("schema_version"), 1)
equal("gate", data.get("gate"), "m8-e2e-paper-path")
equal("result", data.get("result"), os.environ.get("E2E_EVID_STATUS", "").upper())
equal("source_heads.fieldbook", (data.get("source_heads") or {}).get("fieldbook"), os.environ.get("E2E_EVID_FB_SHA"))
equal("source_heads.nirnay", (data.get("source_heads") or {}).get("nirnay"), os.environ.get("E2E_EVID_NR_SHA"))
binaries = data.get("binaries") or {}
for label in ("producer", "verifier", "paper_engine"):
    expected = os.environ.get(f"E2E_EVID_{'PAPER' if label == 'paper_engine' else label.upper()}_SHA")
    equal(f"binaries.{label}.sha256", (binaries.get(label) or {}).get("sha256"), expected)
equal("rights.state", (data.get("rights") or {}).get("state"), "UNKNOWN")
equal("paper_path.replay_digest", (data.get("paper_path") or {}).get("replay_digest"), os.environ.get("E2E_EVID_REPLAY_DIGEST"))
equal("paper_path.adapter.status", ((data.get("paper_path") or {}).get("adapter") or {}).get("status"), os.environ.get("E2E_EVID_ADAPTER_STATUS"))
checks = ((data.get("qualification") or {}).get("checks") or [])
if len(checks) != 6 or [item.get("id") for item in checks] != ["Q0", "Q1", "Q2", "Q3", "Q4", "Q5"]:
    raise SystemExit("result verification failed: qualification checklist is incomplete")
for index, label in ((0, "QUAL_OWNER"), (1, "QUAL_SENTINEL"), (2, "QUAL_RESTART"),
                     (3, "QUAL_FAULT"), (4, "QUAL_BACKUP")):
    if checks[index].get("status") != os.environ.get(f"E2E_EVID_{label}"):
        raise SystemExit(f"result verification failed: check {checks[index].get('id')} status drift")
if checks[5].get("id") != "Q5" or checks[5].get("status") != "BLOCKED" \
        or not checks[5].get("reason"):
    raise SystemExit("result verification failed: Q5 operator readiness must be blocked evidence")
gates = data.get("gates") or {}
if set(gates) != {f"G{i}" for i in range(11)}:
    raise SystemExit("result verification failed: release gates G0-G10 are incomplete")
if gates.get("G9") != "BLOCKED":
    raise SystemExit("result verification failed: deployment qualification gate must be blocked")
if gates.get("G6") != ("PASS" if os.environ.get("E2E_EVID_ADAPTER_STATUS") == "linked" else "BLOCKED"):
    raise SystemExit("result verification failed: adapter gate disagrees with adapter status")
adapter = ((data.get("paper_path") or {}).get("adapter") or {})
if os.environ.get("E2E_EVID_ADAPTER_STATUS") == "linked":
    if adapter.get("claim_scope") != "NEUTRAL_RIGHTS_REFUSED_FIXTURE_ONLY" \
            or adapter.get("rights_refused_only") is not True \
            or adapter.get("cross_repository_claim") is not True \
            or adapter.get("determinism") != os.environ.get("E2E_EVID_ADAPTER_DETERMINISM") \
            or adapter.get("neutral_dataset_sha256") != os.environ.get("E2E_EVID_ADAPTER_NEUTRAL_SHA"):
        raise SystemExit("result verification failed: cross-repository claim scope drift")
else:
    if adapter.get("cross_repository_claim") is not False or adapter.get("claim_scope"):
        raise SystemExit("result verification failed: cross-repository claim without an adapter")
if data.get("result") == "PASS":
    raise SystemExit("result verification failed: PASS is not permitted while G9 is BLOCKED")
if data.get("result") == "BLOCKED":
    reason = data.get("failure_reason")
    if not isinstance(reason, str) or "G9" not in reason or "Q5" not in reason:
        raise SystemExit("result verification failed: blocked reason must identify G9 and Q5")
    rights_case = (data.get("rights") or {}).get("case") or {}
    if rights_case.get("status") != "PASS":
        raise SystemExit("result verification failed: typed rights refusal is missing")
    if any(item.get("status") != "PASS" for item in checks[:5]):
        raise SystemExit("result verification failed: executable checks did not pass")
PYVERIFY
}

on_exit() {
  local code=$?
  trap - EXIT
  if [[ "$code" -ne 0 ]]; then
    # A recorded BLOCKED conclusion (exit 3) is not an assertion failure; it
    # must stay BLOCKED in the evidence document.
    if [[ "${STATUS:-}" != "BLOCKED" ]]; then STATUS="FAIL"; fi
    if [[ -z "${REASON:-}" || "$REASON" == "gate did not complete" ]]; then
      REASON="script exited with status $code before completion"
    fi
  fi
  if ! emit_json >"$WORK/logs/emit.log" 2>&1; then
    printf 'could not write result JSON: %s\n' "$WORK/logs/emit.log" >&2
  fi
  if ! verify_result_json >&2; then
    printf 'result JSON does not describe this run; refusing to report success\n' >&2
    rm -f -- "$RESULT_JSON" || true
    if [[ "$code" -eq 0 ]]; then code=1; fi
  fi
  if [[ -f "$RESULT_JSON" ]]; then
    cat "$RESULT_JSON"
  fi
  exit "$code"
}

run_self_test() {
  exec python3 - "$0" <<'PYSELFTEST'
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

script = Path(sys.argv[1]).resolve()
if len(sys.argv) != 2:
    print("usage: e2e_paper_path.sh --self-test", file=sys.stderr)
    raise SystemExit(2)

root = Path(tempfile.mkdtemp(prefix="e2e-paper-probes-"))
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
# The sentinel check reads this exact source path in the Nirnay checkout.
authority = nirnay / "crates/risk-authority/src/authority.rs"
authority.parent.mkdir(parents=True, exist_ok=True)
authority.write_text(
    "pub struct AuthorityOwnership { _file: File }\n"
    "impl AuthorityOwnership { pub fn acquire() { OpenOptions::new().create_new(true); } }\n"
    "impl Drop for AuthorityOwnership { fn drop(&mut self) {} }\n"
    "// a stale M4 sentinel is refused\n",
    encoding="utf-8")
git(nirnay, "add", ".")
git(nirnay, "commit", "-q", "-m", "probe sentinel source")
nr_sha = git(nirnay, "rev-parse", "HEAD").stdout.strip()
dirty_path = fieldbook / "README.src"
dirty_bytes = dirty_path.read_bytes()
# The real committed neutral adapter is copied into the probe workspace at its
# contract path and its exact bytes are declared by the probe authority file.
committed_adapter = script.parent / "ndc_to_paper_dataset.sh"
if not committed_adapter.is_file() or not os.access(committed_adapter, os.X_OK):
    raise SystemExit("committed neutral adapter is missing or not executable")
probe_scripts = root / "scripts"
probe_scripts.mkdir(parents=True, exist_ok=True)
probe_adapter = probe_scripts / committed_adapter.name
probe_adapter.write_bytes(committed_adapter.read_bytes())
probe_adapter.chmod(0o755)
probe_adapter_sha = sha256(probe_adapter)

def probe_state(include_adapter=True):
    state = {"schema_version": 3,
             "source_heads_at_record_time": {"fieldbook": fb_sha, "nirnay": nr_sha}}
    if include_adapter:
        state["release_gates"] = {"neutral_adapter": {
            "path": "scripts/ndc_to_paper_dataset.sh",
            "sha256": probe_adapter_sha,
            "source": "workspace-authority",
            "claim_scope": "NEUTRAL_RIGHTS_REFUSED_FIXTURE_ONLY",
        }}
    return state

(root / "CURRENT-STATE.json").write_text(
    json.dumps(probe_state(), indent=2) + "\n", encoding="utf-8")
(root / "CURRENT-STATE-NO-ADAPTER.json").write_text(
    json.dumps(probe_state(False), indent=2) + "\n", encoding="utf-8")

producer_stub = r'''#!/usr/bin/env python3
import hashlib, json, sys
from pathlib import Path
spec = out = None
args = sys.argv[1:]
while args:
    flag = args.pop(0)
    if flag == "--spec":
        spec = args.pop(0)
    elif flag == "--out":
        out = args.pop(0)
    else:
        raise SystemExit(f"stub producer: unexpected argument {flag}")
if not spec or not Path(spec).is_file() or not out:
    raise SystemExit("stub producer: bad arguments")
dest = Path(out) / "publisher-example" / "dataset-example" / "release-probe"
(dest / "artifacts").mkdir(parents=True, exist_ok=True)
body = b"artifact-bytes\n"
(dest / "artifacts" / "artifact.bin").write_bytes(body)
manifest = {
    "schema_version": 1, "contract_version": "v2",
    "publication_identity": {"publisher_identity": "publisher-example"},
    "source_scope": {"dataset_id": "dataset-example"},
    "release_identity": {"release_id": "release-probe"},
    "artifacts": [{"path": "artifacts/artifact.bin",
                   "stored_sha256": hashlib.sha256(body).hexdigest(),
                   "stored_bytes": len(body), "record_count": 1}],
}
raw = (json.dumps(manifest, sort_keys=True, separators=(",", ":")) + "\n").encode()
(dest / "manifest.json").write_bytes(raw)
(dest / "signature.json").write_text(json.dumps({
    "schema_version": 1, "key_id": "conformance-key-1",
    "manifest_sha256": hashlib.sha256(raw).hexdigest(),
}, sort_keys=True) + "\n", encoding="utf-8")
'''

verifier_stub = r'''#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path

release = out = None
args = sys.argv[1:]
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
if os.environ.get("E2E_TEST_WRONG_CODE") == "1":
    code = "REJECT_SIGNATURE_INTEGRITY"
label = Path(out).name
if os.environ.get("E2E_TEST_MISSING_CASE") == label:
    raise SystemExit(rc)
Path(out).parent.mkdir(parents=True, exist_ok=True)
if os.environ.get("E2E_TEST_MALFORMED_CASE") == label:
    Path(out).write_text("{not-json", encoding="utf-8")
    raise SystemExit(rc)
report = {
    "schema_version": 1,
    "outcome": outcome,
    "refusal": {"stage": stage, "code": code},
    "admission_receipt": None,
    "receipt_written": False,
    "private_snapshot_survives": False,
    "rights_state": "UNKNOWN",
    "dataset_accepted": False,
    "collection_enabled": False,
    "live_execution_enabled": False,
    "release": {"publisher_id": "publisher-example", "dataset_id": "dataset-example",
                "release_id": "release-probe"},
    "stages": ([{"stage": index + 1, "status": "PASS", "code": "OK"} for index in range(5)]
               + [{"stage": 6, "status": "REFUSED" if stage == 6 else "REFUSED", "code": code}]
               + [{"stage": index, "status": "NOT_RUN", "code": "NOT_APPLICABLE"}
                  for index in range(7, 9)]),
    "cleanup": {"cleanup_succeeded": True, "cleanup_pending": False},
}
Path(out).write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
raise SystemExit(rc)
'''

paper_stub = r'''#!/usr/bin/env python3
import hashlib
import json
import os
import struct
import sys
from pathlib import Path

dataset = spec = output = None
replay = False
args = sys.argv[1:]
while args:
    flag = args.pop(0)
    if flag == "--dataset":
        dataset = args.pop(0)
    elif flag == "--spec":
        spec = args.pop(0)
    elif flag == "--output":
        output = args.pop(0)
    elif flag == "--replay":
        replay = True
    else:
        raise SystemExit(f"stub paper engine: unexpected argument {flag}")
if not dataset or not spec or not output:
    raise SystemExit("stub paper engine: bad arguments")
if os.environ.get("E2E_TEST_PAPER_MISSING") == "1":
    raise SystemExit(3)
configuration = json.load(open(spec, encoding="utf-8"))
if "note" in configuration or "spec_version" in configuration:
    raise SystemExit("stub paper engine: run spec has unknown fields")
allowed_risk = {"max_order_quantity", "max_order_notional_paise", "max_position_quantity",
                "max_gross_exposure_paise", "max_daily_loss_paise", "max_open_orders",
                "max_orders_per_second", "max_price_deviation_ppm", "allow_short"}
if set(configuration["risk"]) - allowed_risk:
    raise SystemExit("stub paper engine: risk spec has unknown fields")
events_bytes = (Path(dataset) / "events.jsonl").read_bytes()
out = Path(output)
out.mkdir(parents=True, exist_ok=True)
journal = out / "journal.jsonl"
segments = journal / "segments"
segments.mkdir(parents=True, exist_ok=True)
(length := segments / "segment-00000000000000000001.nrj")
kinds = ["AccountOpened", "QuoteReceived", "DecisionMade", "RiskAssessed"]
frames = []
for sequence, kind in enumerate(kinds, 1):
    body = json.dumps({"envelope": {"event_id": f"probe-{sequence:016x}"},
                       "payload": {kind: {}}}, sort_keys=True,
                      separators=(",", ":")).encode("utf-8")
    header = b"NRJ1" + struct.pack(">HHIQ", 1, 0, len(body), sequence) + b"\x00" * 64
    frames.append(header + body)
length.write_bytes(b"".join(frames))
journal_sha = hashlib.sha256(length.read_bytes()).hexdigest()
if replay and os.environ.get("E2E_TEST_PAPER_DRIFT") == "1":
    journal_sha = "00" * 32
report = {
    "schema_version": 1,
    "dataset_sha256": hashlib.sha256(events_bytes).hexdigest(),
    "input_rows": 2,
    "quotes_accepted": 2,
    "intent_submitted": not replay,
    "decision_deduplicated": replay,
    "journal_records": len(kinds),
    "journal_sha256": journal_sha,
    "evidence_sequence": 3,
    "evidence_hash": "11" * 32,
    "verification": f"VerificationReport {{ record_count: {len(kinds)}, repaired_tail_bytes: 0 }}",
    "paper_fill_model_notice": "abstract fixture; no execution simulation",
}
(out / "run-report.json").write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
# The risk verdict is delivered as a typed journal body for the script to parse.
assessment_frame = None
for sequence, kind in enumerate(kinds, 1):
    if kind != "RiskAssessed":
        continue
    checks = [{"check": name, "passed": False, "detail": "abstract"}
              for name in ("session_open", "account_snapshot_available",
                           "kill_switch", "reconciliation")]
    if configuration["risk"]["max_order_notional_paise"] < 1000:
        checks.extend({"check": name, "passed": False, "detail": "abstract"}
                      for name in ("order_notional", "gross_exposure", "strategy_exposure"))
    body = json.dumps({"envelope": {"event_id": f"probe-{sequence:016x}"},
                       "payload": {"RiskAssessed": {"assessment": {
                           "accepted": False, "checks": checks}}}},
                      sort_keys=True, separators=(",", ":")).encode("utf-8")
    assessment_frame = (b"NRJ1" + struct.pack(">HHIQ", 1, 0, len(body), sequence)
                        + b"\x00" * 64 + body)
    frames[sequence - 1] = assessment_frame
length.write_bytes(b"".join(frames))
'''

adapter_stub = r'''#!/usr/bin/env python3
import hashlib, json, sys
from pathlib import Path
release = out = None
args = sys.argv[1:]
while args:
    flag = args.pop(0)
    if flag == "--release":
        release = args.pop(0)
    elif flag == "--out":
        out = args.pop(0)
    else:
        raise SystemExit(f"stub adapter: unexpected argument {flag}")
if not release or not Path(release, "manifest.json").is_file() or not out:
    raise SystemExit("stub adapter: bad arguments")
root = Path(out)
root.mkdir(parents=True, exist_ok=True)
binding = hashlib.sha256(Path(release, "manifest.json").read_bytes()).hexdigest()
rows = [json.dumps({"schema_version": 1, "sequence": ordinal,
                    "event_kind": "OPAQUE_TEST_EVENT",
                    "event_id": f"{binding[:16]}{ordinal:016x}",
                    "opaque_bytes": binding[:24],
                    "release_binding_sha256": binding},
                   sort_keys=True, separators=(",", ":")) for ordinal in (1, 2, 3)]
(root / "events.jsonl").write_text("\n".join(rows) + "\n", encoding="utf-8")
'''

stubs = root / "stubs"
producer = stubs / "producer"
verifier = stubs / "verifier"
paper = stubs / "paper"
adapter = stubs / "adapter"
for path, body in ((producer, producer_stub), (verifier, verifier_stub),
                   (paper, paper_stub), (adapter, adapter_stub)):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(body, encoding="utf-8")
    path.chmod(0o755)

# The script generates the neutral dataset itself; the stub adapter needs a
# copy for the adapter-present probe, created by a pre-flight script run.
preflight_work = root / "preflight"
preflight_work.mkdir(parents=True, exist_ok=True)

def write_sidecar(binary, repository, head):
    sidecar = Path(str(binary) + ".paper-provenance.json")
    sidecar.write_text(json.dumps({
        "schema_version": 1,
        "source_repository": repository,
        "source_head": head,
        "binary_sha256": sha256(binary),
    }, indent=2) + "\n", encoding="utf-8")
    return sidecar

producer_sidecar = write_sidecar(producer, "fieldbook", fb_sha)
verifier_sidecar = write_sidecar(verifier, "nirnay", nr_sha)
paper_sidecar = write_sidecar(paper, "nirnay", nr_sha)
adapter_sidecar = write_sidecar(adapter, "workspace", "workspace-authority")

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
  ndc-conformance-producer) source="${E2E_TEST_STUB_PRODUCER:?}" ;;
  ndc-conformance-verifier) source="${E2E_TEST_STUB_VERIFIER:?}" ;;
  paper-engine-run) source="${E2E_TEST_STUB_PAPER:?}" ;;
  *) printf 'fake cargo: unexpected bin %s\n' "$name" >&2; exit 2 ;;
esac
target="${CARGO_TARGET_DIR:?}/release"
mkdir -p "$target"
cp "$source" "$target/$name"
chmod +x "$target/$name"
''', encoding="utf-8")
cargo_stub.chmod(0o755)

def load_json(path):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception:
        return None

def probe(name, env_extra=None, setup=None, expect_code=0, omit_overrides=False):
    case_root = root / "cases" / name
    work = case_root / "work"
    out = case_root / "result.json"
    work.mkdir(parents=True, exist_ok=True)
    out.parent.mkdir(parents=True, exist_ok=True)
    if setup is not None:
        setup(out, work)
    env = os.environ.copy()
    for key in list(env):
        if key.startswith("E2E_TEST_") or key in {
            "E2E_WORKSPACE_ROOT", "E2E_CURRENT_STATE", "E2E_FIELDBOOK_DIR",
            "E2E_NIRNAY_DIR", "E2E_PRODUCER_BIN", "E2E_VERIFIER_BIN",
            "E2E_PAPER_BIN", "E2E_PAPER_ADAPTER_BIN", "E2E_RUN_ID",
            "FIELDBOOK_SHA", "NIRNAY_SHA",
        }:
            env.pop(key, None)
    env.update({
        "E2E_WORKSPACE_ROOT": str(root),
        "E2E_CURRENT_STATE": str(root / "CURRENT-STATE.json"),
        "E2E_FIELDBOOK_DIR": str(fieldbook),
        "E2E_NIRNAY_DIR": str(nirnay),
        "E2E_PRODUCER_BIN": str(producer),
        "E2E_VERIFIER_BIN": str(verifier),
        "E2E_PAPER_BIN": str(paper),
        "E2E_RUN_ID": f"probe-{name}",
    })
    env.update(env_extra or {})
    if omit_overrides:
        for key in ("E2E_CURRENT_STATE", "E2E_FIELDBOOK_DIR", "E2E_NIRNAY_DIR",
                    "E2E_PRODUCER_BIN", "E2E_VERIFIER_BIN", "E2E_PAPER_BIN"):
            env.pop(key, None)
    result = run(["bash", str(script), "--out", str(out), "--work", str(work)],
                 env=env, check_setup=False)
    check(f"{name}: exit status", result.returncode == expect_code,
          f"rc={result.returncode} stderr={result.stderr.strip()[-400:]}")
    return result, out

def stale_setup(out, _work):
    out.write_text(json.dumps({"result": "PASS", "run_id": "stale-run"}, indent=2) + "\n",
                   encoding="utf-8")

def blocked_setup(out, _work):
    out.parent.mkdir(parents=True, exist_ok=True)
    out.parent.chmod(0o500)

result, out = probe("neutral_adapter_default", expect_code=3)
data = load_json(out)
check("neutral_adapter_default: evidence emitted", data is not None)
default_work = root / "cases" / "neutral_adapter_default" / "work"
release_manifest = next(default_work.glob("release-tree/**/manifest.json"), None)
valid_rights = default_work / "diagnostics" / "rights.json"
if data:
    check("neutral_adapter_default: result BLOCKED", data.get("result") == "BLOCKED", str(data.get("result")))
    check("neutral_adapter_default: run id current", data.get("run_id") == "probe-neutral_adapter_default")
    check("neutral_adapter_default: exact heads", data["source_heads"] == {
        "fieldbook": fb_sha, "nirnay": nr_sha}, str(data.get("source_heads")))
    check("neutral_adapter_default: rights typed refusal",
          data["rights"]["case"]["status"] == "PASS"
          and data["rights"]["case"]["actual"]["code"] == "REJECT_RIGHTS_EVIDENCE",
          str(data["rights"]["case"]))
    check("neutral_adapter_default: adapter discovered at contract path",
          data["paper_path"]["adapter"]["status"] == "linked"
          and data["paper_path"]["adapter"]["source"] == "workspace-authority-declared-neutral-adapter"
          and data["paper_path"]["adapter"]["binary_sha256"] == probe_adapter_sha
          and data["gates"]["G6"] == "PASS", str(data["paper_path"]["adapter"]))
    check("neutral_adapter_default: scoped cross-repository claim",
          data["paper_path"]["adapter"]["cross_repository_claim"] is True
          and data["paper_path"]["adapter"]["claim_scope"] == "NEUTRAL_RIGHTS_REFUSED_FIXTURE_ONLY"
          and data["paper_path"]["adapter"]["rights_refused_only"] is True
          and data["paper_path"]["adapter"]["determinism"] == "PASS"
          and len(data["paper_path"]["adapter"]["neutral_dataset_sha256"]) == 64,
          str(data["paper_path"]["adapter"]))
    check("neutral_adapter_default: standalone replay reported separately",
          data["neutral_fixture"]["paper_dataset_source"]
          == "workspace-neutral-fixture-not-cross-repository-admitted",
          str(data["neutral_fixture"]["paper_dataset_source"]))
    check("neutral_adapter_default: paper replay digest",
          bool(data["paper_path"]["replay_digest"])
          and data["gates"]["G4"] == "PASS", str(data["paper_path"]["replay_digest"]))
    check("neutral_adapter_default: risk refusal evidence",
          "session_open" in data["paper_path"]["risk_baseline"]["failed_checks"]
          and "order_notional" in data["paper_path"]["risk_tight"]["failed_checks"],
          str(data["paper_path"]["risk_baseline"]))
    check("neutral_adapter_default: qualification machine-readable",
          [item["status"] for item in data["qualification"]["checks"]]
          == ["PASS", "PASS", "PASS", "PASS", "PASS", "BLOCKED"],
          str(data["qualification"]["checks"]))
    check("neutral_adapter_default: G9 blocked reason",
          data["gates"]["G9"] == "BLOCKED" and "G9" in data["failure_reason"]
          and "Q5" in data["failure_reason"], str(data["failure_reason"]))
    check("neutral_adapter_default: boundaries",
          all(value is False for value in data["boundaries"].values()), str(data["boundaries"]))

result, out = probe("adapter_missing", expect_code=3, env_extra={
    "E2E_CURRENT_STATE": str(root / "CURRENT-STATE-NO-ADAPTER.json"),
})
data = load_json(out)
if data:
    check("adapter_missing: G6 blocked without declaration",
          data["paper_path"]["adapter"]["status"] == "BLOCKED_MISSING_ADAPTER"
          and data["gates"]["G6"] == "BLOCKED"
          and data["paper_path"]["adapter"]["cross_repository_claim"] is False,
          str(data["paper_path"]["adapter"]))
    check("adapter_missing: blocked reason names G6 and G9",
          data["result"] == "BLOCKED" and "G6" in data["failure_reason"]
          and "G9" in data["failure_reason"])

result, out = probe("adapter_override", expect_code=3, env_extra={
    "E2E_PAPER_ADAPTER_BIN": str(adapter),
})
data = load_json(out)
if data:
    check("adapter_override: linked with provenance",
          data["paper_path"]["adapter"]["status"] == "linked"
          and data["gates"]["G6"] == "PASS" and data["result"] == "BLOCKED",
          str(data["paper_path"]["adapter"]))

result, out = probe("exact_source_build", expect_code=3, env_extra={
    "PATH": f"{fakebin}:{os.environ.get('PATH', '')}",
    "E2E_TEST_STUB_PRODUCER": str(producer),
    "E2E_TEST_STUB_VERIFIER": str(verifier),
    "E2E_TEST_STUB_PAPER": str(paper),
}, omit_overrides=True)
data = load_json(out)
if data:
    check("exact_source_build: exact-source mode",
          data["source_provenance"]["mode"] == "exact-source-build"
          and data["result"] == "BLOCKED", str(data["source_provenance"]))
    check("exact_source_build: binaries from recorded commits",
          all(item["source"] == "built-from-recorded-commit"
              for item in data["binaries"].values()), str(data["binaries"]))

result, out = probe("stale_result", setup=stale_setup, expect_code=3)
data = load_json(out)
check("stale_result: replaced by current run", data is not None
      and data.get("run_id") == "probe-stale_result" and data.get("result") == "BLOCKED",
      str(data and (data.get("run_id"), data.get("result"))))

result, out = probe("emit_failure", setup=blocked_setup, expect_code=1)
out.parent.chmod(0o700)
check("emit_failure: no PASS on stdout", '"result": "PASS"' not in result.stdout)
check("emit_failure: failure reported", "result" in result.stderr.lower()
      or "verif" in result.stderr.lower(), result.stderr.strip()[-300:])

result, _ = probe("missing_rights_diagnostic",
                  env_extra={"E2E_TEST_MISSING_CASE": "rights.json"}, expect_code=1)
check("missing_rights_diagnostic: typed refusal reported",
      "verifier" in result.stderr.lower() or "diagnostic" in result.stderr.lower(),
      result.stderr.strip()[-300:])
probe("malformed_rights_diagnostic",
      env_extra={"E2E_TEST_MALFORMED_CASE": "rights.json"}, expect_code=1)
probe("wrong_rights_code", env_extra={"E2E_TEST_WRONG_CODE": "1"}, expect_code=1)

def dirty_setup(_out, _work):
    dirty_path.write_bytes(dirty_bytes + b"local edit\n")

try:
    result, _ = probe("dirty_checkout", setup=dirty_setup, expect_code=1)
    check("dirty_checkout: clean-tree refusal",
          "clean" in result.stderr.lower() or "modif" in result.stderr.lower(),
          result.stderr.strip()[-300:])
finally:
    dirty_path.write_bytes(dirty_bytes)

probe("head_mismatch", env_extra={"FIELDBOOK_SHA": "00" * 20}, expect_code=1)

sidecar_body = producer_sidecar.read_bytes()
producer_sidecar.unlink()
try:
    result, _ = probe("provenance_missing", expect_code=1)
    check("provenance_missing: provenance refusal",
          "provenance" in result.stderr.lower(), result.stderr.strip()[-300:])
finally:
    producer_sidecar.write_bytes(sidecar_body)

sidecar_body = adapter_sidecar.read_bytes()
adapter_sidecar.unlink()
try:
    probe("adapter_provenance_missing", env_extra={
        "E2E_CURRENT_STATE": str(root / "CURRENT-STATE-NO-ADAPTER.json"),
        "E2E_PAPER_ADAPTER_BIN": str(adapter),
    }, expect_code=1)
finally:
    adapter_sidecar.write_bytes(sidecar_body)

probe("paper_replay_drift", env_extra={"E2E_TEST_PAPER_DRIFT": "1"}, expect_code=1)
probe("paper_missing_assessment", env_extra={"E2E_TEST_PAPER_MISSING": "1"}, expect_code=1)

for drill, hook in (("restart", "E2E_TEST_DRILL_RESTART_FAIL"),
                    ("fault", "E2E_TEST_DRILL_FAULT_FAIL"),
                    ("backup", "E2E_TEST_DRILL_BACKUP_FAIL")):
    result, _ = probe(f"drill_{drill}_fail", env_extra={hook: "1"}, expect_code=1)
    check(f"drill_{drill}_fail: drill refusal reported",
          drill in result.stderr.lower() or "drill" in result.stderr.lower(),
          result.stderr.strip()[-300:])

# Direct contract probes of the real neutral adapter, independent of the gate.
check("adapter: committed contract path is executable",
      probe_adapter.is_file() and os.access(probe_adapter, os.X_OK))
check("adapter: probe release and rights evidence available",
      release_manifest is not None and valid_rights.is_file())
if release_manifest is not None:
    release_dir = release_manifest.parent
    adapter_outputs = root / "adapter-probes"

    def adapter_run(name, release, rights=None, expect_ok=True):
        destination = adapter_outputs / name
        shutil.rmtree(destination, ignore_errors=True)
        environment = os.environ.copy()
        environment.pop("NDC_TO_PAPER_RIGHTS_EVIDENCE", None)
        if rights is not None:
            environment["NDC_TO_PAPER_RIGHTS_EVIDENCE"] = str(rights)
        result = run([str(probe_adapter), "--release", str(release),
                      "--out", str(destination)], env=environment, check_setup=False)
        check(f"adapter_{name}: exit status",
              (result.returncode == 0) == expect_ok,
              f"rc={result.returncode} stderr={result.stderr.strip()[-300:]}")
        return destination, result

    first, _ = adapter_run("deterministic_first", release_dir, valid_rights)
    second, _ = adapter_run("deterministic_second", release_dir, valid_rights)
    first_bytes = (first / "events.jsonl").read_bytes()
    check("adapter: deterministic events.jsonl",
          first_bytes == (second / "events.jsonl").read_bytes()
          and sorted(p.name for p in first.iterdir()) == ["events.jsonl"],
          str(sorted(p.name for p in first.iterdir())))
    rows = [json.loads(line) for line in first_bytes.decode("utf-8").splitlines()]
    check("adapter: opaque sequence-only rows",
          [row["sequence"] for row in rows] == [1, 2, 3]
          and all(len(row["opaque_bytes"]) >= 16
                  and all(character in "0123456789abcdef" for character in row["opaque_bytes"])
                  and row["event_kind"] == "OPAQUE_TEST_EVENT"
                  for row in rows), str(rows))
    forbidden = ("instrument", "price", "quote", "bid", "ask", "trade", "strategy", "order")
    check("adapter: no market-shaped fields",
          not any(word in first_bytes.decode("utf-8").lower() for word in forbidden))

    admitted = adapter_outputs / "rights-admitted.json"
    admitted.write_text(json.dumps({**json.loads(valid_rights.read_text(encoding="utf-8")),
                                    "outcome": "RIGHTS_ADMITTED",
                                    "rights_state": "PERMITTED"}), encoding="utf-8")
    destination, _ = adapter_run("rights_admitted", release_dir, admitted, expect_ok=False)
    check("adapter: rights admission refused without output", not (destination / "events.jsonl").exists())
    malformed = adapter_outputs / "rights-malformed.json"
    malformed.write_text("{not-json", encoding="utf-8")
    destination, _ = adapter_run("rights_malformed", release_dir, malformed, expect_ok=False)
    check("adapter: malformed rights refused without output", not (destination / "events.jsonl").exists())
    destination, _ = adapter_run("rights_missing", release_dir, None, expect_ok=False)
    check("adapter: missing rights refused without output", not (destination / "events.jsonl").exists())

    mutated_release = adapter_outputs / "mutated-release"
    shutil.rmtree(mutated_release, ignore_errors=True)
    shutil.copytree(release_dir, mutated_release)
    manifest_file = mutated_release / "manifest.json"
    data_bytes = bytearray(manifest_file.read_bytes())
    data_bytes[0] ^= 0x01
    manifest_file.write_bytes(data_bytes)
    destination, _ = adapter_run("manifest_mutation", mutated_release, valid_rights, expect_ok=False)
    check("adapter: manifest mutation refused without output", not (destination / "events.jsonl").exists())

print(f"\n{'SELF-TEST FAILED' if failures else 'SELF-TEST OK'}: "
      f"{len(failures)} failing check(s): {failures}")
raise SystemExit(1 if failures else 0)
PYSELFTEST
}

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
      run_self_test "$@"
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$WORK" ]]; then
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/e2e-paper-path.XXXXXX")"
fi
mkdir -p "$WORK"
if [[ -z "$RESULT_JSON" ]]; then
  RESULT_JSON="$WORK/e2e-paper-path.json"
fi
mkdir -p "$(dirname "$RESULT_JSON")" "$WORK/diagnostics" "$WORK/logs" "$WORK/build" "$WORK/paper"
[[ -w "$(dirname "$RESULT_JSON")" ]] \
  || die "result directory is not writable: $(dirname "$RESULT_JSON")"

# A result from an earlier invocation is never evidence for this invocation.
if [[ -e "$RESULT_JSON" || -L "$RESULT_JSON" ]]; then
  rm -f -- "$RESULT_JSON" || die "cannot remove stale result JSON: $RESULT_JSON"
fi
[[ ! -e "$RESULT_JSON" && ! -L "$RESULT_JSON" ]] \
  || die "stale result JSON could not be removed: $RESULT_JSON"

RUN_ID="${E2E_RUN_ID:-}"
if [[ -z "$RUN_ID" ]]; then
  RUN_ID="$(python3 -c 'import uuid; print(uuid.uuid4().hex)')" \
    || die "cannot generate a run id for the result document"
fi
[[ "$RUN_ID" =~ ^[A-Za-z0-9._-]{1,128}$ ]] || die "invalid run id: $RUN_ID"

DIAGNOSTIC_OVERRIDES=()
for name in E2E_WORKSPACE_ROOT E2E_CURRENT_STATE E2E_FIELDBOOK_DIR \
            E2E_NIRNAY_DIR E2E_PRODUCER_BIN E2E_VERIFIER_BIN \
            E2E_PAPER_BIN E2E_PAPER_ADAPTER_BIN E2E_RUN_ID; do
  if [[ -n "${!name:-}" ]]; then DIAGNOSTIC_OVERRIDES+=("$name"); fi
done
OVERRIDES_CSV="$(IFS=,; printf '%s' "${DIAGNOSTIC_OVERRIDES[*]:-}")"
SOURCE_PROVENANCE_MODE="exact-source-build"
if [[ -n "${E2E_CURRENT_STATE:-}" || -n "${E2E_FIELDBOOK_DIR:-}" \
      || -n "${E2E_NIRNAY_DIR:-}" || -n "${E2E_PRODUCER_BIN:-}" \
      || -n "${E2E_VERIFIER_BIN:-}" || -n "${E2E_PAPER_BIN:-}" ]]; then
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
PAPER_BIN=""
PAPER_SHA=""
PAPER_SOURCE=""
BASE_SPEC_SHA=""
SPEC_SHA=""
RELEASE_DIR=""
ADAPTER_STATUS="BLOCKED_MISSING_ADAPTER"
ADAPTER_SOURCE="none"
ADAPTER_SHA=""
ADAPTER_CANDIDATES_CSV=""
ADAPTER_NEUTRAL_SHA=""
ADAPTER_DETERMINISM=""
ADAPTER_SCOPE=""
DATASET_SHA=""
DATASET_SOURCE=""
PAPER_SPEC_SHA=""
REPLAY_DIGEST=""
RISK_BASELINE_SUMMARY=""
RISK_TIGHT_SUMMARY=""
QUAL_OWNER_STATUS="FAIL"
QUAL_SENTINEL_STATUS="FAIL"
QUAL_RESTART_STATUS="FAIL"
QUAL_FAULT_STATUS="FAIL"
QUAL_BACKUP_STATUS="FAIL"
Q2_CASE=""
CLEAN_TREE_CHECKED="no"

trap on_exit EXIT

# 1. Authority: exact heads from CURRENT-STATE.json only.
[[ -f "$CURRENT_STATE" ]] || die "CURRENT-STATE.json is missing: $CURRENT_STATE"
head_output="$(python3 - "$CURRENT_STATE" <<'PYHEADS'
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
PYHEADS
)" || die "cannot read exact heads from CURRENT-STATE.json"
FB_SHA="$(printf '%s\n' "$head_output" | sed -n '1p')"
NR_SHA="$(printf '%s\n' "$head_output" | sed -n '2p')"
[[ -n "$FB_SHA" && -n "$NR_SHA" ]] || die "CURRENT-STATE.json did not yield two exact heads"
if [[ -n "${FIELDBOOK_SHA:-}" && "$FIELDBOOK_SHA" != "$FB_SHA" ]]; then
  die "Fieldbook SHA disagreement: supplied=$FIELDBOOK_SHA recorded=$FB_SHA"
fi
if [[ -n "${NIRNAY_SHA:-}" && "$NIRNAY_SHA" != "$NR_SHA" ]]; then
  die "Nirnay SHA disagreement: supplied=$NIRNAY_SHA recorded=$NR_SHA"
fi

# 2. Exact checkouts and clean trees.
FB_HEAD="$(require_exact_head "$FIELDBOOK_DIR" "$FB_SHA" "Fieldbook")" \
  || die "Fieldbook checkout failed the exact-head check"
NR_HEAD="$(require_exact_head "$NIRNAY_DIR" "$NR_SHA" "Nirnay")" \
  || die "Nirnay checkout failed the exact-head check"
require_clean_tree "$FIELDBOOK_DIR" "Fieldbook" \
  || die "Fieldbook checkout failed the clean-tree check"
require_clean_tree "$NIRNAY_DIR" "Nirnay" \
  || die "Nirnay checkout failed the clean-tree check"
CLEAN_TREE_CHECKED="yes"

# 3. Build the three exact-source binaries into an isolated target directory.
build_bin() {
  local label="$1" dir="$2" bin="$3"
  run_logged "$WORK/logs/$label-build.log" \
    bash -c 'cd "$1" && CARGO_TARGET_DIR="$2" cargo build --release --locked --bin "$3"' \
    _ "$dir" "$WORK/build/$label" "$bin" \
    || die "$label build failed: $WORK/logs/$label-build.log"
  printf '%s\n' "$WORK/build/$label/release/$bin"
}

if [[ -n "${E2E_PRODUCER_BIN:-}" ]]; then
  PRODUCER_BIN="$E2E_PRODUCER_BIN"
  PRODUCER_SOURCE="supplied-executable-with-verified-source-provenance"
else
  PRODUCER_BIN="$(build_bin producer "$FIELDBOOK_DIR" ndc-conformance-producer)"
  PRODUCER_SOURCE="built-from-recorded-commit"
fi
[[ -f "$PRODUCER_BIN" && -s "$PRODUCER_BIN" && -x "$PRODUCER_BIN" ]] \
  || die "required producer binary missing, empty or not executable: $PRODUCER_BIN"
PRODUCER_SHA="$(sha256_file "$PRODUCER_BIN")" || die "cannot hash producer binary"
if [[ -n "${E2E_PRODUCER_BIN:-}" ]]; then
  PRODUCER_PROVENANCE="$(require_binary_provenance "$PRODUCER_BIN" fieldbook "$FB_SHA" producer)" \
    || die "producer provenance check failed"
fi

if [[ -n "${E2E_VERIFIER_BIN:-}" ]]; then
  VERIFIER_BIN="$E2E_VERIFIER_BIN"
  VERIFIER_SOURCE="supplied-executable-with-verified-source-provenance"
else
  VERIFIER_BIN="$(build_bin verifier "$NIRNAY_DIR" ndc-conformance-verifier)"
  VERIFIER_SOURCE="built-from-recorded-commit"
fi
[[ -f "$VERIFIER_BIN" && -s "$VERIFIER_BIN" && -x "$VERIFIER_BIN" ]] \
  || die "required verifier binary missing, empty or not executable: $VERIFIER_BIN"
VERIFIER_SHA="$(sha256_file "$VERIFIER_BIN")" || die "cannot hash verifier binary"
if [[ -n "${E2E_VERIFIER_BIN:-}" ]]; then
  VERIFIER_PROVENANCE="$(require_binary_provenance "$VERIFIER_BIN" nirnay "$NR_SHA" verifier)" \
    || die "verifier provenance check failed"
fi

if [[ -n "${E2E_PAPER_BIN:-}" ]]; then
  PAPER_BIN="$E2E_PAPER_BIN"
  PAPER_SOURCE="supplied-executable-with-verified-source-provenance"
else
  PAPER_BIN="$(build_bin paper "$NIRNAY_DIR" paper-engine-run)"
  PAPER_SOURCE="built-from-recorded-commit"
fi
[[ -f "$PAPER_BIN" && -s "$PAPER_BIN" && -x "$PAPER_BIN" ]] \
  || die "required paper engine binary missing, empty or not executable: $PAPER_BIN"
PAPER_SHA="$(sha256_file "$PAPER_BIN")" || die "cannot hash paper engine binary"
if [[ -n "${E2E_PAPER_BIN:-}" ]]; then
  PAPER_PROVENANCE="$(require_binary_provenance "$PAPER_BIN" nirnay "$NR_SHA" paper_engine)" \
    || die "paper engine provenance check failed"
fi

# 4. Neutral producer -> verifier path. The derived spec aligns only TEST_ONLY
#    identity bindings; no release byte is synthesized by this script.
BASE_SPEC="$FIELDBOOK_DIR/tests/fixtures/ndc/producer-spec-example.json"
[[ -f "$BASE_SPEC" ]] || die "producer spec fixture is missing: $BASE_SPEC"
BASE_SPEC_SHA="$(sha256_file "$BASE_SPEC")" || die "cannot hash base producer spec"
mkdir -p "$WORK/producer"
SPEC="$WORK/producer/derived-spec.json"
python3 - "$BASE_SPEC" "$SPEC" <<'PYSPEC'
import hashlib
import json
import sys
source, destination = sys.argv[1], sys.argv[2]
spec = json.load(open(source, encoding="utf-8"))
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
spec["evidence"]["payload_schemas"] = [{
    "event_type": event_type, "schema_id": schema_id,
    "schema_version": schema_version, "digest_sha256": schema_digest,
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
PYSPEC
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

release_identity="$(python3 - "$RELEASE_DIR/manifest.json" <<'PYREL'
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
PYREL
)" || die "cannot read release identity from producer manifest"
read -r pub_id ds_id rel_id <<< "$release_identity"
STAGED_RELEASE="$WORK/release-tree/$pub_id/$ds_id/$rel_id"
mkdir -p "$(dirname "$STAGED_RELEASE")"
cp -R "$RELEASE_DIR" "$STAGED_RELEASE"
RELEASE_DIR="$STAGED_RELEASE"
ARTIFACT_REL="$(python3 - "$RELEASE_DIR" <<'PYART'
import sys
from pathlib import Path
root = Path(sys.argv[1])
files = sorted(p for p in (root / "artifacts").iterdir() if p.is_file())
if not files:
    raise SystemExit("producer release has no artifact file")
print(files[0].relative_to(root).as_posix())
PYART
)" || die "cannot identify a stored artifact in the producer output"

run_verifier() {
  local release="$1" out="$2" label="$3" expect_success="$4"
  local log="$WORK/logs/$label.log" code=0
  set +e
  run_logged "$log" "$VERIFIER_BIN" --release "$release" --out "$out"
  code=$?
  set -e
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
  python3 - "$staged/$relative_target" <<'PYMUT'
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
PYMUT
  printf '%s\n' "$staged"
}

run_verifier "$RELEASE_DIR" "$WORK/diagnostics/rights.json" "rights" "yes"
assert_rights_diagnostic "$WORK/diagnostics/rights.json"
mutated="$(mutate_release "one-byte-manifest" "manifest.json")" \
  || die "manifest mutation failed"
run_verifier "$mutated" "$WORK/diagnostics/one-byte-manifest.json" "one-byte-manifest" "no"
assert_verifier_diagnostic "$WORK/diagnostics/one-byte-manifest.json" "one-byte manifest" \
  "PREFLIGHT_REFUSED" 1 "REJECT_SCHEMA_ENVELOPE"
mutated="$(mutate_release "one-byte-sidecar" "signature.json")" \
  || die "sidecar mutation failed"
run_verifier "$mutated" "$WORK/diagnostics/one-byte-sidecar.json" "one-byte-sidecar" "no"
assert_verifier_diagnostic "$WORK/diagnostics/one-byte-sidecar.json" "one-byte sidecar" \
  "RIGHTS_ADMISSION_REFUSED" 3 "REJECT_SIGNATURE_INTEGRITY"
mutated="$(mutate_release "one-byte-stored-artifact" "$ARTIFACT_REL")" \
  || die "stored artifact mutation failed"
run_verifier "$mutated" "$WORK/diagnostics/one-byte-stored-artifact.json" "one-byte-stored-artifact" "no"
assert_verifier_diagnostic "$WORK/diagnostics/one-byte-stored-artifact.json" "one-byte stored artifact" \
  "RIGHTS_ADMISSION_REFUSED" 5 "REJECT_ARTIFACT_DIGESTS"

# 5. Neutral abstract paper dataset and run specs. Event identities are derived
#    from the derived spec digest; all values are abstract test constants.
DATASET_DIR="$WORK/paper/dataset-neutral"
mkdir -p "$DATASET_DIR"
python3 - "$SPEC" "$SPEC_SHA" "$DATASET_DIR" "$WORK/paper/baseline-spec.json" \
          "$WORK/paper/tight-spec.json" <<'PYPAPERFIX'
import hashlib
import json
import sys
from pathlib import Path

spec_path, spec_sha, dataset_dir, baseline_path, tight_path = sys.argv[1:6]
digest = hashlib.sha256(f"{spec_sha}:m8-neutral-paper".encode("utf-8")).hexdigest()
root = Path(dataset_dir)
root.mkdir(parents=True, exist_ok=True)
rows = []
for ordinal, (bid, ask) in enumerate(((1000, 1010), (1005, 1015), (1020, 1030)), 1):
    event_id = f"{digest[:16]}{ordinal:016x}"
    row = {
        "event_id": event_id,
        "instrument_id": "abs-instrument-01",
        "venue": "NSE",
        "event_kind": "quote",
        "received_utc_ns": ordinal * 1_000_000_000,
        "source_timestamp_ns": ordinal * 1_000_000_000,
        "local_sequence": ordinal,
        "bids": [{"price": f"{bid // 100}.{bid % 100:02d}", "quantity": 10}],
        "asks": [{"price": f"{ask // 100}.{ask % 100:02d}", "quantity": 10}],
    }
    rows.append(json.dumps(row, sort_keys=True, separators=(",", ":")))
(root / "events.jsonl").write_text("\n".join(rows) + "\n", encoding="utf-8")

# `paper-engine-run` RunSpec uses the narrow RiskSpec, not the full
# RiskPolicy. Unknown fields are rejected by the binary's deny_unknown_fields.
policy = {
    "max_order_quantity": 10, "max_order_notional_paise": 1_000_000,
    "max_position_quantity": 100, "max_gross_exposure_paise": 10_000_000,
    "max_daily_loss_paise": 1_000_000, "max_open_orders": 10,
    "max_orders_per_second": 100, "max_price_deviation_ppm": 1_000_000,
    "allow_short": False,
}
spec_body = {
    "schema_version": 1,
    "stream_id": "m8-neutral-paper-stream",
    "run_id": "0123456789abcdef0123456789abcdef",
    "account_id": 1, "strategy_id": 1, "algo_id": 1,
    "strategy_version": "m8-abstract-paper-v1",
    "starting_cash_paise": 100_000_000,
    "trade_date": "2026-11-27",
    "max_quote_age_ns": 1_000_000_000_000,
    "instrument": {
        "instrument_id": "abs-instrument-01", "isin": "INTEST000009",
        "venue": "NSE", "venue_symbol": "ABSTRACT-PAPER",
        "market_lot": 1, "tick_paise": 100,
    },
    "risk": policy,
    "strategy": {"max_entry_price_paise": 20000, "order_quantity": 1},
}
Path(baseline_path).write_text(
    json.dumps(spec_body, indent=2, sort_keys=True) + "\n", encoding="utf-8")
tight = json.loads(json.dumps(spec_body))
tight["risk"]["max_order_notional_paise"] = 100
tight["risk"]["max_gross_exposure_paise"] = 100
Path(tight_path).write_text(
    json.dumps(tight, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PYPAPERFIX
DATASET_SHA="$(sha256_file "$DATASET_DIR/events.jsonl")" \
  || die "cannot hash neutral paper dataset"
PAPER_SPEC_SHA="$(sha256_file "$WORK/paper/baseline-spec.json")" \
  || die "cannot hash neutral paper spec"

# 6. Fieldbook -> Nirnay neutral adapter discovery. Absence is a recorded
#    blocker, never a simulated bridge. The committed workspace adapter is bound
#    by its exact digest in CURRENT-STATE.json. Diagnostic overrides require
#    provenance. A linked adapter supports only the neutral, rights-refused
#    fixture claim; the paper engine keeps replaying the standalone fixture.
ADAPTER_CANDIDATES_CSV="nirnay/apps/paper-runner/src/bin/ndc_to_paper.rs,nirnay/crates/release-verifier/src/bin/ndc_to_paper.rs,fieldbook/src/bin/ndc-to-paper-dataset.rs,scripts/ndc_to_paper_dataset.sh"
ADAPTER_BIN=""
declared_adapter="$(python3 - "$CURRENT_STATE" <<'PYDECL'
import json
import re
import sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
entry = (data.get("release_gates") or {}).get("neutral_adapter")
if entry is None:
    raise SystemExit(0)
if not isinstance(entry, dict):
    raise SystemExit("neutral_adapter declaration is not an object")
if entry.get("path") != "scripts/ndc_to_paper_dataset.sh":
    raise SystemExit("neutral adapter path is not the committed contract path")
if not isinstance(entry.get("sha256"), str) \
        or not re.fullmatch(r"[0-9a-f]{64}", entry["sha256"]):
    raise SystemExit("neutral adapter declaration has no valid digest")
if entry.get("source") != "workspace-authority" \
        or entry.get("claim_scope") != "NEUTRAL_RIGHTS_REFUSED_FIXTURE_ONLY":
    raise SystemExit("neutral adapter declaration has an unverified source or claim scope")
print(entry["path"], entry["sha256"])
PYDECL
)" || die "cannot read neutral adapter declaration from CURRENT-STATE.json"
if [[ -n "$declared_adapter" ]]; then
  read -r adapter_rel adapter_declared_sha <<< "$declared_adapter"
  [[ -n "$adapter_rel" && -n "$adapter_declared_sha" ]] \
    || die "neutral adapter declaration is incomplete"
  ADAPTER_BIN="$ROOT/$adapter_rel"
  [[ -f "$ADAPTER_BIN" && -s "$ADAPTER_BIN" && -x "$ADAPTER_BIN" ]] \
    || die "declared neutral adapter is missing, empty or not executable: $ADAPTER_BIN"
  ADAPTER_SHA="$(sha256_file "$ADAPTER_BIN")" || die "cannot hash declared neutral adapter"
  [[ "$ADAPTER_SHA" == "$adapter_declared_sha" ]] \
    || die "declared neutral adapter digest drift: actual=$ADAPTER_SHA declared=$adapter_declared_sha"
  ADAPTER_SOURCE="workspace-authority-declared-neutral-adapter"
  ADAPTER_STATUS="linked"
elif [[ -n "${E2E_PAPER_ADAPTER_BIN:-}" ]]; then
  ADAPTER_BIN="$E2E_PAPER_ADAPTER_BIN"
  [[ -f "$ADAPTER_BIN" && -s "$ADAPTER_BIN" && -x "$ADAPTER_BIN" ]] \
    || die "paper adapter override is missing, empty or not executable: $ADAPTER_BIN"
  ADAPTER_SHA="$(sha256_file "$ADAPTER_BIN")" || die "cannot hash paper adapter"
  ADAPTER_SOURCE="supplied-executable-with-verified-source-provenance"
  require_adapter_provenance "$ADAPTER_BIN" "$FB_SHA" >/dev/null \
    || die "paper adapter provenance check failed"
  ADAPTER_STATUS="linked"
elif [[ -f "$NIRNAY_DIR/apps/paper-runner/src/bin/ndc_to_paper.rs" ]]; then
  ADAPTER_BIN="$(build_bin adapter "$NIRNAY_DIR" ndc-to-paper)"
  ADAPTER_SHA="$(sha256_file "$ADAPTER_BIN")" || die "cannot hash paper adapter"
  ADAPTER_SOURCE="built-from-recorded-commit"
  ADAPTER_STATUS="linked"
elif [[ -f "$FIELDBOOK_DIR/src/bin/ndc-to-paper-dataset.rs" ]]; then
  ADAPTER_BIN="$(build_bin adapter "$FIELDBOOK_DIR" ndc-to-paper-dataset)"
  ADAPTER_SHA="$(sha256_file "$ADAPTER_BIN")" || die "cannot hash paper adapter"
  ADAPTER_SOURCE="built-from-recorded-commit"
  ADAPTER_STATUS="linked"
fi

# The paper engine input remains the standalone neutral fixture. The adapter
# output is verified as a separate, deterministic, rights-refused neutral claim.
PAPER_DATASET="$DATASET_DIR"
DATASET_SOURCE="workspace-neutral-fixture-not-cross-repository-admitted"
if [[ "$ADAPTER_STATUS" == "linked" ]]; then
  ADAPTED_DATASET="$WORK/paper/dataset-adapted"
  REPEAT_DATASET="$WORK/paper/dataset-adapted-repeat"
  rm -rf "$ADAPTED_DATASET" "$REPEAT_DATASET"
  mkdir -p "$ADAPTED_DATASET" "$REPEAT_DATASET"
  run_logged "$WORK/logs/adapter-run.log" \
    env NDC_TO_PAPER_RIGHTS_EVIDENCE="$WORK/diagnostics/rights.json" \
    "$ADAPTER_BIN" --release "$RELEASE_DIR" --out "$ADAPTED_DATASET" \
    || die "paper adapter run failed: $WORK/logs/adapter-run.log"
  run_logged "$WORK/logs/adapter-repeat.log" \
    env NDC_TO_PAPER_RIGHTS_EVIDENCE="$WORK/diagnostics/rights.json" \
    "$ADAPTER_BIN" --release "$RELEASE_DIR" --out "$REPEAT_DATASET" \
    || die "repeated paper adapter run failed: $WORK/logs/adapter-repeat.log"
  python3 - "$ADAPTED_DATASET" "$REPEAT_DATASET" <<'PYADAPTCHECK'
import hashlib
import json
import sys
from pathlib import Path
first, repeat = map(Path, sys.argv[1:3])
for label, root in (("first", first), ("repeat", repeat)):
    if sorted(p.name for p in root.iterdir()) != ["events.jsonl"]:
        raise SystemExit(f"adapter {label} run emitted files beyond events.jsonl")
    if any("receipt" in p.name.lower() or "grant" in p.name.lower() for p in root.iterdir()):
        raise SystemExit(f"adapter {label} run emitted an admission receipt or rights grant")
body = (first / "events.jsonl").read_bytes()
if body != (repeat / "events.jsonl").read_bytes():
    raise SystemExit("adapter output is not deterministic across runs")
rows = [json.loads(line) for line in body.decode("utf-8").splitlines()]
if not rows or [row.get("sequence") for row in rows] != list(range(1, len(rows) + 1)):
    raise SystemExit("adapter events are not monotonically sequenced")
forbidden = ("instrument", "price", "quote", "bid", "ask", "trade", "strategy", "order")
if any(word in body.decode("utf-8").lower() for word in forbidden):
    raise SystemExit("adapter events contain market-shaped fields")
PYADAPTCHECK
  ADAPTER_NEUTRAL_SHA="$(python3 - "$ADAPTED_DATASET/events.jsonl" <<'PYSHA'
import hashlib, sys
from pathlib import Path
print(hashlib.sha256(Path(sys.argv[1]).read_bytes()).hexdigest())
PYSHA
  )" || die "cannot hash adapted neutral dataset"
  ADAPTER_DETERMINISM="PASS"
  ADAPTER_SCOPE="NEUTRAL_RIGHTS_REFUSED_FIXTURE_ONLY"
fi

# 7. Paper decision replay: baseline, replay, and a restricted risk case.
run_paper_case() {
  local label="$1" spec="$2" dataset="$3" out="$4"
  shift 4
  mkdir -p "$(dirname "$out")"
  run_logged "$WORK/logs/paper-$label.log" \
    bash -c '"$1" --dataset "$2" --spec "$3" --output "$4" "${@:5}"' \
    _ "$PAPER_BIN" "$dataset" "$spec" "$out" "$@" \
    || die "paper case $label failed: $WORK/logs/paper-$label.log"
  [[ -f "$out/run-report.json" ]] || die "paper case $label wrote no run report"
  parse_journal "$out/journal.jsonl" "$out/journal-summary.json" \
    || die "paper case $label journal could not be parsed: $WORK/logs/paper-$label.log"
}

# The journal digest binds absolute journal file paths, so a true replay must
# reopen the SAME output directory rather than a copy at a different path.
BASE_OUT="$WORK/paper/baseline"
REPLAY_OUT="$WORK/paper/baseline-replay"
mkdir -p "$REPLAY_OUT"
run_paper_case "baseline" "$WORK/paper/baseline-spec.json" "$PAPER_DATASET" "$BASE_OUT"
cp "$BASE_OUT/run-report.json" "$REPLAY_OUT/first-run-report.json" \
  || die "cannot retain first-run report for replay evidence"
cp "$BASE_OUT/journal-summary.json" "$REPLAY_OUT/first-journal-summary.json" \
  || die "cannot retain first-run journal summary for replay evidence"
run_paper_case "baseline-replay" "$WORK/paper/baseline-spec.json" "$PAPER_DATASET" "$BASE_OUT" --replay
cp "$BASE_OUT/run-report.json" "$REPLAY_OUT/run-report.json" \
  || die "cannot retain replay report"
cp "$BASE_OUT/journal-summary.json" "$REPLAY_OUT/journal-summary.json" \
  || die "cannot retain replay journal summary"
run_paper_case "tight" "$WORK/paper/tight-spec.json" "$PAPER_DATASET" "$WORK/paper/tight"

REPLAY_DIGEST="$(python3 - \
  "$WORK/paper/baseline-replay/first-run-report.json" "$WORK/paper/baseline/run-report.json" \
  "$WORK/paper/baseline-replay/first-journal-summary.json" \
  "$WORK/paper/baseline/journal-summary.json" <<'PYREPLAY'
import hashlib
import json
import sys
first, replay, first_journal, replay_journal = map(lambda p: json.load(open(p, encoding="utf-8")), sys.argv[1:5])
fields = ("dataset_sha256", "input_rows", "quotes_accepted", "journal_records",
          "evidence_sequence", "evidence_hash", "verification")
# The binary journal_sha256 binds absolute journal paths; compare it only
# within the same output directory and exclude it from the portable digest.
for field in fields + ("journal_sha256",):
    if first.get(field) != replay.get(field):
        raise SystemExit(f"replay changed {field}")
for field in ("record_count", "body_chain_sha256", "content_sha256"):
    if first_journal.get(field) != replay_journal.get(field):
        raise SystemExit(f"replay changed journal {field}")
if replay.get("decision_deduplicated") is not True:
    raise SystemExit("replay did not report decision deduplication")
preimage = json.dumps({field: first.get(field) for field in fields}, sort_keys=True,
                      separators=(",", ":")).encode("utf-8")
print(hashlib.sha256(preimage).hexdigest())
PYREPLAY
)" || die "paper replay digest could not be computed"

RISK_BASELINE_SUMMARY="$(python3 - \
  "$WORK/paper/baseline/journal-summary.json" "$WORK/paper/baseline/run-report.json" <<'PYRISK'
import json
import sys
summary = json.load(open(sys.argv[1], encoding="utf-8"))
report = json.load(open(sys.argv[2], encoding="utf-8"))
kinds = [event["kind"] for event in summary["events"]]
required = {"AccountOpened", "QuoteReceived", "DecisionMade", "RiskAssessed"}
if not required.issubset(set(kinds)):
    raise SystemExit("paper journal lacks required account/decision/risk events")
if "OrderCreated" in kinds or "FillBooked" in kinds:
    raise SystemExit("paper journal created an order or fill without admission evidence")
assessments = [event["body"]["assessment"] for event in summary["events"]
               if event["kind"] == "RiskAssessed"]
if len(assessments) != 1 or assessments[0]["accepted"] is not False:
    raise SystemExit("paper risk verdict is missing or incorrectly accepted")
failed = sorted(check["check"] for check in assessments[0]["checks"] if not check["passed"])
for expected in ("session_open", "account_snapshot_available", "kill_switch", "reconciliation"):
    if expected not in failed:
        raise SystemExit(f"expected fail-closed risk check is absent: {expected}")
if not isinstance(report.get("dataset_sha256"), str) or len(report["dataset_sha256"]) != 64:
    raise SystemExit("paper report has no valid dataset digest")
print(json.dumps({"accepted": False, "failed_checks": failed,
                  "record_count": summary["record_count"],
                  "body_chain_sha256": summary["body_chain_sha256"],
                  "journal_content_sha256": summary["content_sha256"],
                  "verification": report["verification"]}, sort_keys=True))
PYRISK
)" || die "baseline risk effect could not be reproduced from evidence"

RISK_TIGHT_SUMMARY="$(python3 - \
  "$WORK/paper/tight/journal-summary.json" "$WORK/paper/tight/run-report.json" <<'PYTIGHT'
import json
import sys
summary = json.load(open(sys.argv[1], encoding="utf-8"))
report = json.load(open(sys.argv[2], encoding="utf-8"))
assessments = [event["body"]["assessment"] for event in summary["events"]
               if event["kind"] == "RiskAssessed"]
if len(assessments) != 1 or assessments[0]["accepted"] is not False:
    raise SystemExit("restricted paper risk verdict is missing or incorrectly accepted")
failed = sorted(check["check"] for check in assessments[0]["checks"] if not check["passed"])
for expected in ("order_notional", "gross_exposure", "strategy_exposure"):
    if expected not in failed:
        raise SystemExit(f"restricted case did not fail closed on {expected}")
kinds = [event["kind"] for event in summary["events"]]
if "OrderCreated" in kinds or "FillBooked" in kinds:
    raise SystemExit("restricted paper case created an order or fill")
print(json.dumps({"accepted": False, "failed_checks": failed,
                  "record_count": summary["record_count"],
                  "body_chain_sha256": summary["body_chain_sha256"],
                  "journal_content_sha256": summary["content_sha256"],
                  "verification": report["verification"]}, sort_keys=True))
PYTIGHT
)" || die "restricted risk effect could not be reproduced from evidence"

# 8. Deployment qualification: static checks and temporary-directory drills.
mkdir -p "$WORK/qualification" || die "cannot create qualification evidence directory"
if check_owner_paths >"$WORK/logs/qual-owner.log" 2>&1; then
  QUAL_OWNER_STATUS="PASS"
else
  die "owner path derivation failed: $WORK/logs/qual-owner.log"
fi
if check_sentinel_policy >"$WORK/logs/qual-sentinel.log" 2>&1; then
  QUAL_SENTINEL_STATUS="PASS"
else
  die "stale sentinel runbook check failed: $WORK/logs/qual-sentinel.log"
fi
if check_restart_kill "$WORK" >"$WORK/logs/qual-restart.log" 2>&1; then
  QUAL_RESTART_STATUS="PASS"
else
  die "restart/kill drill failed: $WORK/logs/qual-restart.log"
fi
if check_fault_refusals "$WORK" >"$WORK/logs/qual-fault.log" 2>&1; then
  QUAL_FAULT_STATUS="PASS"
else
  die "fault-refusal drill failed: $WORK/logs/qual-fault.log"
fi
if check_backup_restore "$WORK" "$Q2_CASE" >"$WORK/logs/qual-backup.log" 2>&1; then
  QUAL_BACKUP_STATUS="PASS"
else
  die "backup/restore drill failed: $WORK/logs/qual-backup.log"
fi
# Q5 is deliberately not automatable: no operator authorization exists.

# 9. Conclusion. G6 may close for the neutral fixture, but G9 stays BLOCKED, so
#    the overall result is BLOCKED and the script exits 3 with full evidence.
if [[ "$ADAPTER_STATUS" != "linked" ]]; then
  STATUS="BLOCKED"
  REASON="G6 FIELDBOOK_TO_NIRNAY_NEUTRAL_ADAPTER: no verified adapter converts a rights-refused NDC release into neutral opaque sequence-only events.jsonl bytes; cross-repository claim fails closed. G9 DEPLOYMENT_QUALIFICATION: Q5 operator readiness/authorization is BLOCKED; no production readiness is claimed."
  exit 3
fi
STATUS="BLOCKED"
REASON="G9 DEPLOYMENT_QUALIFICATION: Q5 operator readiness/authorization remains BLOCKED because no production authorization exists and cannot be automated; Q2/Q3/Q4 temporary-directory drills and Q0/Q1 static checks are PASS but do not qualify deployment, D1+ durability or power loss. G6 is closed only for the neutral, rights-refused Fieldbook release fixture (opaque sequence-only events.jsonl, no rights admission, market data, receipt or live execution); the standalone paper replay is reported separately."
exit 3
