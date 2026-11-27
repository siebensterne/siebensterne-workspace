#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Neutral Fieldbook NDC release -> neutral opaque paper dataset adapter.
#
# Contract: <adapter> --release <release-dir> --out <out-dir>
# The only emitted file is <out-dir>/events.jsonl. Rows contain opaque bytes and
# monotonically increasing test sequence values derived from the release digest;
# they contain no instrument, price, quote, depth, trade, strategy or any other
# market-shaped value. No admission receipt is emitted and no rights grant is
# made. Rights admission is checked from the typed verifier refusal supplied in
# NDC_TO_PAPER_RIGHTS_EVIDENCE (or a rights-evidence.json inside the release).
# All validation happens before any output is created; every refusal is
# non-zero and writes no events.jsonl.

set -euo pipefail

fail() {
  printf 'FAIL neutral adapter: %s\n' "$1" >&2
  exit 1
}

release=""
out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --release)
      [[ $# -ge 2 ]] || fail "--release needs a path"
      release="$2"
      shift 2
      ;;
    --out)
      [[ $# -ge 2 ]] || fail "--out needs a path"
      out="$2"
      shift 2
      ;;
    *)
      fail "unexpected argument: $1"
      ;;
  esac
done

[[ -n "$release" && -d "$release" && -f "$release/manifest.json" ]] \
  || fail "--release must name a directory containing manifest.json"
[[ -n "$out" ]] || fail "--out needs a path"

NDC_TO_PAPER_RELEASE="$release" \
NDC_TO_PAPER_OUT="$out" \
python3 - <<'PYADAPTER' || exit $?
import hashlib
import json
import os
import re
import sys
from pathlib import Path

release = Path(os.environ["NDC_TO_PAPER_RELEASE"])
out = Path(os.environ["NDC_TO_PAPER_OUT"])

def fail(message):
    print(f"FAIL neutral adapter: {message}", file=sys.stderr)
    raise SystemExit(1)

def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def canonical(value) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"),
                      ensure_ascii=False).encode("utf-8")

def load_object(path, label):
    if path.is_symlink() or not path.is_file() or not path.stat().st_size:
        fail(f"{label} is missing, empty or a symlink: {path}")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as error:
        fail(f"{label} is malformed: {error}")
    if not isinstance(data, dict):
        fail(f"{label} is not a JSON object")
    return data

manifest_path = release / "manifest.json"
raw_manifest = manifest_path.read_bytes()
manifest = load_object(manifest_path, "release manifest")
manifest_sha256 = digest(raw_manifest)
if manifest.get("schema_version") != 1 or manifest.get("contract_version") != "v2":
    fail("release manifest is not NDC v2 schema_version 1")

identities = (
    ((manifest.get("publication_identity") or {}).get("publisher_identity")),
    ((manifest.get("source_scope") or {}).get("dataset_id")),
    ((manifest.get("release_identity") or {}).get("release_id")),
)
for label, value in zip(("publisher", "dataset", "release"), identities):
    if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9._-]{1,64}", value) \
            or value in (".", ".."):
        fail(f"unsafe or missing {label} identity in release manifest")

signature = load_object(release / "signature.json", "release signature sidecar")
if signature.get("schema_version") != 1:
    fail("signature sidecar schema_version is not 1")
if signature.get("manifest_sha256") != manifest_sha256:
    fail("signature sidecar does not bind the exact release manifest bytes")
if not isinstance(signature.get("key_id"), str) or not signature["key_id"]:
    fail("signature sidecar has no key identity")

artifacts = manifest.get("artifacts")
if not isinstance(artifacts, list) or not artifacts:
    fail("release manifest declares no artifacts")
bindings = []
seen = set()
for artifact in artifacts:
    if not isinstance(artifact, dict):
        fail("release manifest artifact is not an object")
    relative = artifact.get("path")
    if not isinstance(relative, str) or not re.fullmatch(r"artifacts/[A-Za-z0-9._-]{1,128}", relative) \
            or relative in seen:
        fail("release manifest artifact path is unsafe or duplicated")
    seen.add(relative)
    target = release / relative
    if target.is_symlink() or not target.is_file():
        fail(f"declared artifact is missing or a symlink: {relative}")
    body = target.read_bytes()
    if artifact.get("stored_sha256") != digest(body) or artifact.get("stored_bytes") != len(body):
        fail(f"declared artifact digest or length mismatch: {relative}")
    bindings.append({"path": relative, "stored_sha256": artifact["stored_sha256"],
                     "stored_bytes": artifact["stored_bytes"]})

rights_env = os.environ.get("NDC_TO_PAPER_RIGHTS_EVIDENCE", "").strip()
rights_path = Path(rights_env) if rights_env else release / "rights-evidence.json"
rights = load_object(rights_path, "rights refusal evidence")
checks = (
    ("outcome", rights.get("outcome"), "RIGHTS_ADMISSION_REFUSED"),
    ("refusal stage", (rights.get("refusal") or {}).get("stage"), 6),
    ("refusal code", (rights.get("refusal") or {}).get("code"), "REJECT_RIGHTS_EVIDENCE"),
    ("rights_state", rights.get("rights_state"), "UNKNOWN"),
    ("admission_receipt", rights.get("admission_receipt"), None),
    ("receipt_written", rights.get("receipt_written"), False),
    ("private_snapshot_survives", rights.get("private_snapshot_survives"), False),
    ("dataset_accepted", rights.get("dataset_accepted"), False),
    ("collection_enabled", rights.get("collection_enabled"), False),
    ("live_execution_enabled", rights.get("live_execution_enabled"), False),
)
for label, actual, expected in checks:
    if actual != expected:
        fail(f"rights evidence {label} is {actual!r}; expected {expected!r}")
stages = rights.get("stages")
if not isinstance(stages, list) or len(stages) < 7:
    fail("rights evidence has no complete stage record")
stage_six = stages[5]
if not isinstance(stage_six, dict) or stage_six.get("stage") != 6 \
        or stage_six.get("status") != "REFUSED" \
        or stage_six.get("code") != "REJECT_RIGHTS_EVIDENCE":
    fail("stage 6 is not a typed REJECT_RIGHTS_EVIDENCE refusal")
rights_release = rights.get("release") or {}
if rights_release and [rights_release.get("publisher_id"), rights_release.get("dataset_id"),
                       rights_release.get("release_id")] != list(identities):
    fail("rights refusal evidence describes a different release")
if any(stage.get("status") == "PASS" and stage.get("stage", 0) > 6 for stage in stages):
    fail("rights refusal was followed by admitted later stages")

binding = digest(canonical({
    "adapter_contract": "m8-neutral-paper-adapter-v1",
    "manifest_sha256": manifest_sha256,
    "signature_manifest_sha256": signature["manifest_sha256"],
    "artifacts": bindings,
    "rights_refusal": {"stage": 6, "code": "REJECT_RIGHTS_EVIDENCE"},
}))
rows = []
for sequence in range(1, 4):
    opaque = binding[(sequence * 8) % 32:(sequence * 8) % 32 + 24]
    rows.append(json.dumps({
        "schema_version": 1,
        "sequence": sequence,
        "event_id": f"{binding[:16]}{sequence:016x}",
        "event_kind": "OPAQUE_TEST_EVENT",
        "opaque_bytes": opaque,
        "release_binding_sha256": binding,
    }, sort_keys=True, separators=(",", ":")))

out.mkdir(parents=True, exist_ok=True)
target = out / "events.jsonl"
target.write_text("\n".join(rows) + "\n", encoding="utf-8")
print(f"ADAPTER_OK binding={binding} events={len(rows)}")
PYADAPTER
