#!/usr/bin/env python3
"""Deterministic, stdlib-only checker for the v1 workspace contracts.

Normal mode emits exactly one JSON object. --self-test builds temporary
fixtures (including two tiny Git repositories) and exercises positive and
negative cases. --behaviour additionally runs the golden fixtures as
`cargo test --test contract_conformance` in both local source checkouts,
with CARGO_TARGET_DIR outside both repositories, and only succeeds when both
runs exit 0. All modes print exactly one JSON object to stdout.

Conformance fixtures are evidence about the wire/identity envelope only. No
fixture, digest or test result admits data, grants rights, authorizes
collection, permits market data or enables live execution.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

SPEC_NAMES = (
    "source-event-envelope-v1",
    "research-governance-v1",
    "continuous-paper-architecture-v1",
)
SPEC_STATUS = {
    "source-event-envelope-v1": "SPECIFIED_AND_IMPLEMENTED_INDEPENDENTLY",
    "research-governance-v1": "SPECIFIED_ONLY",
    "continuous-paper-architecture-v1": "SPECIFIED_ONLY",
}
ENVELOPE_FIELDS = (
    "schema_version",
    "source_id",
    "source_product_ref",
    "session_ref",
    "decoder_version",
    "reference_data_revision",
    "rights_evidence_ref",
    "connection_epoch",
    "capture_sequence",
    "canonical_sequence",
    "provider_sequence",
    "source_timestamp_ns",
    "receive_utc_ns",
    "receive_monotonic_ns",
    "raw_frame_digest",
    "envelope_digest",
    "quality_state",
    "continuity_state",
)
LIFECYCLE_ORDER = (
    "capture",
    "validate",
    "NDC publication",
    "admission/replay",
    "strategy",
    "risk",
    "OMS",
    "paper execution",
    "fees/accounting",
    "reconciliation",
    "checkpoint/recovery",
)
FC_IDS = tuple(f"FC-{i:03d}" for i in range(1, 10))
RG_IDS = tuple(f"RG-{i:03d}" for i in range(1, 7))
BASE_FIXTURE_IDS = ("VAL-001", "VAL-002") + tuple(f"NEG-{i:03d}" for i in range(1, 13))
P13_ENUM_FIXTURE_IDS = (
    "P13-ENUM-QUALITY-UNKNOWN",
    "P13-ENUM-CONTINUITY-UNKNOWN",
    "P13-ENUM-QUALITY-TYPES",
    "P13-ENUM-CONTINUITY-TYPES",
)
P13_INTEGER_FIXTURE_IDS = (
    "P13-INT-SCHEMA",
    "P13-INT-CAPTURE",
    "P13-INT-CANONICAL",
    "P13-INT-RECEIVE-UTC",
    "P13-INT-RECEIVE-MONOTONIC",
    "P13-INT-CONNECTION-EPOCH",
    "P13-INT-PROVIDER",
    "P13-INT-SOURCE-TIMESTAMP",
    "P13-INT-EXPONENT",
)
P13_LEDGER_FIXTURE_IDS = ("P13-LEDGER-QUARANTINE",)
P13_CANONICALISATION_FIXTURE_IDS = (
    "P13-CANON-ESCAPED-UNICODE",
    "P13-CANON-DUPLICATE",
)
P13_FIXTURE_IDS = (
    P13_ENUM_FIXTURE_IDS
    + P13_INTEGER_FIXTURE_IDS
    + P13_LEDGER_FIXTURE_IDS
    + P13_CANONICALISATION_FIXTURE_IDS
)
FIXTURE_REQUIRED_IDS = BASE_FIXTURE_IDS + P13_FIXTURE_IDS
FIXTURE_COPY_DIR = Path("tests") / "contract_fixtures"
FIXTURE_STATUS_PENDING = "FIXTURES_DEFINED_BEHAVIOURAL_RESULTS_PENDING"
FIXTURE_STATUS_VERIFIED = "BEHAVIOUR_VERIFIED"
FIXTURE_STATUS_P13 = "P13_FIXTURES_DEFINED_BEHAVIOUR_PENDING"
FIXTURE_STATUSES = (FIXTURE_STATUS_PENDING, FIXTURE_STATUS_VERIFIED, FIXTURE_STATUS_P13)
BEHAVIOUR_COMMAND = ("cargo", "test", "--test", "contract_conformance")
CONFORMANCE_TEST_PATHS = {
    "fieldbook": "tests/contract_conformance.rs",
    "nirnay": "crates/release-verifier/tests/contract_conformance.rs",
}

EXPECTED_FREEZE = {
    "incremental_data_budget_inr": 0,
    "provider_rights": "21 UNKNOWN",
    "dataset_acceptance": "BLOCKED",
    "provider_collection": "DISABLED",
    "market_data": "BLOCKED",
    "experiment_registration": "BLOCKED",
    "m4_holdout": "NOT_DEFINED",
    "synthetic_market_shaped_tests": "RETIRED_UNDER_D11",
    "live_execution": "DISABLED",
    "rights_or_permission_from_url_token_or_checksum": "NEVER",
}
EXPECTED_HOLDOUT_DISPOSITION = "CONSUMED_ONCE_POST_SELECTION_DO_NOT_REUSE"
REQUIRED_LINEAGE = (
    "decision_id",
    "schema_version",
    "owner_decision_ref",
    "rights_evidence_ref",
    "dataset_digest",
    "source_heads",
    "code_digest",
    "experiment_id",
    "holdout_disposition",
    "selection_rule_digest",
    "result_digest",
    "recorded_utc_date",
)


def check(results: list[dict], ok: bool, code: str, detail: str) -> bool:
    results.append({"code": code, "status": "PASS" if ok else "FAIL", "detail": detail})
    return ok


def load_json(path: Path) -> tuple[object | None, str | None]:
    try:
        raw = path.read_bytes()
    except OSError as exc:
        return None, f"read failed: {exc.__class__.__name__}"
    try:
        return json.loads(raw.decode("utf-8")), None
    except (UnicodeDecodeError, ValueError) as exc:
        return None, f"parse failed: {exc.__class__.__name__}"


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git(repo: Path, *args: str) -> tuple[int, str]:
    try:
        proc = subprocess.run(
            ["git", "-C", str(repo), *args],
            capture_output=True,
            text=True,
            timeout=120,
            check=False,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        return 1, f"git error: {exc.__class__.__name__}"
    return proc.returncode, proc.stdout.strip()


def validate_spec(results: list[dict], name: str, spec: object) -> None:
    valid = isinstance(spec, dict)
    check(results, valid, f"spec/{name}/object", "top-level JSON object" if valid else "not an object")
    if not valid:
        return
    assert isinstance(spec, dict)
    check(
        results,
        spec.get("name") == name,
        f"spec/{name}/name",
        f"name={spec.get('name')!r}",
    )
    check(
        results,
        spec.get("schema_version") == 1 and isinstance(spec.get("schema_version"), int),
        f"spec/{name}/schema_version",
        f"schema_version={spec.get('schema_version')!r}",
    )
    if name == "source-event-envelope-v1":
        fields = spec.get("fields")
        names = [f.get("name") for f in fields if isinstance(f, dict)] if isinstance(fields, list) else []
        check(
            results,
            tuple(names) == ENVELOPE_FIELDS,
            "spec/envelope/field_order",
            f"fields={len(names)} exact_order={tuple(names) == ENVELOPE_FIELDS}",
        )
        complete = isinstance(fields, list) and all(
            isinstance(f, dict)
            and f.get("ordinal") == i
            and isinstance(f.get("type") or f.get("semantic_type"), str)
            and isinstance(f.get("rules"), list)
            and f.get("rules")
            and f.get("required") is True
            for i, f in enumerate(fields, 1)
        )
        check(results, complete, "spec/envelope/field_types_and_rules", f"complete={complete}")
        codes = {entry.get("code") for entry in spec.get("rejection_reason_codes", []) if isinstance(entry, dict)}
        neg = spec.get("negative_cases")
        neg_ok = (
            isinstance(neg, list)
            and len(neg) >= 10
            and all(
                isinstance(c, dict)
                and c.get("id")
                and c.get("case")
                and c.get("expected_rejection") in codes
                for c in neg
            )
        )
        check(results, neg_ok, "spec/envelope/negative_cases", f"cases={len(neg) if isinstance(neg, list) else 0}")
        sv = spec.get("source_verification")
        sv_ok = (
            isinstance(sv, dict)
            and isinstance(sv.get("schema_version_constant_pattern"), str)
            and sv.get("schema_version_constant_value") == 1
            and sv.get("repositories") == ["fieldbook", "nirnay"]
        )
        check(results, sv_ok, "spec/envelope/source_verification", f"present={sv_ok}")
        admission = spec.get("admission")
        adm_ok = (
            isinstance(admission, dict)
            and admission.get("admissible_quality_states") == ["CAPTURED", "DECODED", "VALIDATED"]
            and admission.get("inadmissible_quality_states") == ["QUARANTINED"]
            and admission.get("fail_closed") is True
        )
        check(results, adm_ok, "spec/envelope/admission", f"fail_closed={adm_ok}")
    elif name == "research-governance-v1":
        rules = {r.get("id"): r for r in spec.get("rules", []) if isinstance(r, dict)}
        expected = {
            "RG-001": "CONSUMED_ONCE_POST_SELECTION_DO_NOT_REUSE",
            "RG-002": "BLOCKED",
            "RG-003": "FRESH_HOLDOUT_REQUIRED_BEFORE_ANY_FUTURE_RESEARCH",
            "RG-004": "RIGHTS_APPROVED_DATASET_REQUIRED",
            "RG-005": "NO_ALPHA_CLAIM_FROM_SYNTHETIC_EVIDENCE",
            "RG-006": "LINEAGE_REQUIRED",
        }
        rules_ok = all(rules.get(k, {}).get("required_value") == v for k, v in expected.items())
        check(results, rules_ok, "spec/research/rules", f"rules={sorted(rules)}")
        reg = spec.get("experiment_register", {}).get("EXP-M4-0001", {})
        reg_ok = (
            reg.get("holdout_disposition") == EXPECTED_HOLDOUT_DISPOSITION
            and reg.get("holdout_may_be_reused") is False
            and reg.get("holdout_may_be_relabelled_untouched") is False
            and reg.get("counts_as_fresh_holdout") is False
            and reg.get("supports_alpha_claim") is False
        )
        check(results, reg_ok, "spec/research/exp-m4-0001", f"disposition={reg.get('holdout_disposition')!r}")
        lineage = spec.get("decision_record_required_lineage")
        check(
            results,
            isinstance(lineage, list) and set(lineage) >= set(REQUIRED_LINEAGE),
            "spec/research/lineage",
            f"fields={len(lineage) if isinstance(lineage, list) else 0}",
        )
        neg = spec.get("negative_cases")
        neg_ok = isinstance(neg, list) and all(
            isinstance(c, dict) and c.get("expected_rejection") in RG_IDS for c in neg
        )
        check(results, neg_ok, "spec/research/negative_cases", f"cases={len(neg) if isinstance(neg, list) else 0}")
    elif name == "continuous-paper-architecture-v1":
        order = spec.get("lifecycle_order_contract", {}).get("exact_order")
        check(results, tuple(order or ()) == LIFECYCLE_ORDER, "spec/arch/lifecycle_order", f"stages={len(order or [])}")
        stages = spec.get("lifecycle_stages")
        stage_ok = isinstance(stages, list) and tuple(s.get("name") for s in stages if isinstance(s, dict)) == LIFECYCLE_ORDER
        check(results, stage_ok, "spec/arch/lifecycle_stages", f"complete={stage_ok}")
        fcs = {c.get("id") for c in spec.get("fail_closed_conditions", []) if isinstance(c, dict)}
        check(results, set(FC_IDS) <= fcs, "spec/arch/fail_closed", f"missing={sorted(set(FC_IDS) - fcs)}")
        nbw = spec.get("no_broker_writes")
        nbw_ok = (
            isinstance(nbw, dict)
            and nbw.get("enabled") is False
            and nbw.get("fail_closed_on_attempt") is True
            and "NO_BROKER_WRITES" in str(nbw.get("statement", ""))
        )
        check(results, nbw_ok, "spec/arch/no_broker_writes", f"explicit={nbw_ok}")
        son = spec.get("specification_only")
        son_ok = (
            isinstance(son, dict)
            and son.get("is_implemented_service") is False
            and son.get("is_live_execution_path") is False
            and "SPECIFICATION_ONLY_NOT_AN_IMPLEMENTED_SERVICE" in str(son.get("statement", ""))
        )
        check(results, son_ok, "spec/arch/specification_only", f"explicit={son_ok}")
        neg = spec.get("negative_cases")
        neg_ok = isinstance(neg, list) and all(isinstance(c, dict) and c.get("expected_rejection") for c in neg)
        check(results, neg_ok, "spec/arch/negative_cases", f"cases={len(neg) if isinstance(neg, list) else 0}")


def verify_contracts(results: list[dict], root: Path) -> None:
    state, err = load_json(root / "CURRENT-STATE.json")
    check(results, err is None and isinstance(state, dict), "state/parse", err or "parsed")
    if err is not None or not isinstance(state, dict):
        return
    assert isinstance(state, dict)
    check(
        results,
        "contracts" not in state,
        "state/contracts_absent",
        "contracts references live in contracts/contract-index.json",
    )
    index, index_err = load_json(root / "contracts" / "contract-index.json")
    check(results, index_err is None and isinstance(index, dict), "index/parse", index_err or "parsed")
    if index_err is not None or not isinstance(index, dict):
        return
    assert isinstance(index, dict)
    ok = index.get("schema_version") == 1
    check(results, ok, "index/schema_version", f"schema_version={index.get('schema_version')!r}")
    if not ok:
        return
    specs = index.get("specs")
    if not isinstance(specs, dict):
        check(results, False, "index/specs", "missing specs object")
        return
    blocked = index.get("blocked_research")
    check(
        results,
        isinstance(blocked, dict) and blocked.get("status") == "BLOCKED",
        "index/blocked_research",
        "point-in-time research over frozen crates/india-reference",
    )
    for name in SPEC_NAMES:
        entry = specs.get(name)
        entry_ok = (
            isinstance(entry, dict)
            and entry.get("path") == f"contracts/{name}.json"
            and entry.get("schema_version") == 1
        )
        check(results, entry_ok, f"index/{name}/path_and_version", f"path={(entry or {}).get('path')!r}")
        if not entry_ok:
            continue
        assert isinstance(entry, dict)
        check(
            results,
            entry.get("status") == SPEC_STATUS[name],
            f"index/{name}/status",
            f"status={entry.get('status')!r}",
        )
        if name == "source-event-envelope-v1":
            heads = state.get("source_heads_at_record_time", {})
            binding = entry.get("verification")
            bound_ok = (
                isinstance(binding, dict)
                and binding.get("status") == "VERIFIED_AT_EXACT_HEADS"
                and binding.get("fieldbook") == heads.get("fieldbook")
                and binding.get("nirnay") == heads.get("nirnay")
            )
            check(
                results,
                bound_ok,
                "index/source-event-envelope-v1/verification_heads",
                f"fieldbook={str((binding or {}).get('fieldbook'))[:12]} nirnay={str((binding or {}).get('nirnay'))[:12]}",
            )
        spec_path = root / entry["path"]
        spec, spec_err = load_json(spec_path)
        check(results, spec_err is None, f"spec/{name}/parse", spec_err or "parsed")
        if spec_err is None:
            validate_spec(results, name, spec)
        digest_ok = spec_path.is_file() and sha256_file(spec_path) == entry.get("sha256")
        check(
            results,
            digest_ok,
            f"index/{name}/sha256",
            f"recorded={str(entry.get('sha256'))[:12]} actual={sha256_file(spec_path)[:12] if spec_path.is_file() else 'missing'}",
        )


def verify_freeze(results: list[dict], root: Path) -> None:
    state, err = load_json(root / "CURRENT-STATE.json")
    if err is not None or not isinstance(state, dict):
        check(results, False, "freeze/parse", err or "state not an object")
        return
    assert isinstance(state, dict)
    freeze = state.get("freeze")
    if not isinstance(freeze, dict):
        check(results, False, "freeze/object", "missing freeze object")
        return
    assert isinstance(freeze, dict)
    for key, expected in EXPECTED_FREEZE.items():
        actual = freeze.get(key)
        check(results, actual == expected, f"freeze/{key}", f"actual={actual!r} expected={expected!r}")
    m4 = freeze.get("m4", {}).get("EXP-M4-0001", {})
    check(
        results,
        m4.get("synthetic_holdout") == EXPECTED_HOLDOUT_DISPOSITION,
        "freeze/m4/EXP-M4-0001",
        f"disposition={m4.get('synthetic_holdout')!r}",
    )
    caps = state.get("capabilities", {})
    check(
        results,
        caps.get("operational_qualification") == "BLOCKED",
        "freeze/production_readiness",
        f"operational_qualification={caps.get('operational_qualification')!r}",
    )
    gates = state.get("release_gates", {}).get("overall", {})
    check(
        results,
        gates.get("status") == "BLOCKED",
        "freeze/release_gates_overall",
        f"status={gates.get('status')!r}",
    )


def verify_sources(results: list[dict], root: Path) -> None:
    state, err = load_json(root / "CURRENT-STATE.json")
    if err is not None or not isinstance(state, dict):
        check(results, False, "source/state_parse", err or "state not an object")
        return
    assert isinstance(state, dict)
    heads = state.get("source_heads_at_record_time")
    if not isinstance(heads, dict):
        check(results, False, "source/heads", "missing source_heads_at_record_time")
        return
    assert isinstance(heads, dict)
    spec, spec_err = load_json(root / "contracts" / "source-event-envelope-v1.json")
    if spec_err is not None or not isinstance(spec, dict):
        check(results, False, "source/spec_parse", spec_err or "spec not an object")
        return
    assert isinstance(spec, dict)
    sv = spec.get("source_verification")
    if not isinstance(sv, dict):
        check(results, False, "source/spec_instruction", "missing source_verification")
        return
    assert isinstance(sv, dict)
    # The spec records the canonical token; independent implementations may use
    # their own equivalent constant names (Fieldbook SOURCE_EVENT_SCHEMA_VERSION,
    # Nirnay V1_SCHEMA_VERSION). Accept both spellings, still require value 1.
    spec_pattern = sv["schema_version_constant_pattern"]
    pattern = (
        f"({spec_pattern}|SOURCE[_-]?EVENT[_-]?SCHEMA[_-]?VERSION"
        f"|V1[_-]?SCHEMA[_-]?VERSION)"
    )
    value = int(sv["schema_version_constant_value"])
    for repo in ("fieldbook", "nirnay"):
        path = root / repo
        code, head = git(path, "rev-parse", "HEAD")
        recorded = heads.get(repo)
        head_ok = code == 0 and re.fullmatch(r"[0-9a-f]{40}", head or "") and head == recorded
        check(results, head_ok, f"source/{repo}/head", f"actual={(head or '')[:12]} recorded={str(recorded)[:12]}")
        code, dirty = git(path, "status", "--porcelain")
        check(results, code == 0 and dirty == "", f"source/{repo}/clean", f"dirty_lines={len(dirty.splitlines())}")
        if not head_ok:
            check(results, False, f"source/{repo}/implementation", "SKIPPED: head mismatch fails closed")
            continue
        code, constant_lines = git(
            path, "grep", "-I", "-i", "-h", "-E",
            f"{pattern}.{{0,60}}(=|:)[[:space:]]*{value}", "HEAD", "--",
        )
        const_ok = code in (0, 1) and bool(constant_lines.strip())
        check(results, const_ok, f"source/{repo}/schema_version_constant", f"matches={len(constant_lines.splitlines())}")
        token_re = "|".join(ENVELOPE_FIELDS)
        code, token_lines = git(path, "grep", "-I", "-h", "-E", token_re, "HEAD", "--")
        missing = [t for t in ENVELOPE_FIELDS if t not in token_lines]
        check(results, code in (0, 1) and not missing, f"source/{repo}/field_tokens", f"missing={missing}")
        check(
            results,
            const_ok and not missing and head_ok and code in (0, 1),
            f"source/{repo}/implementation",
            f"verified={const_ok and not missing}",
        )


class DuplicateMember(ValueError):
    """Raised when strict JSON parsing sees a repeated object member."""

    def __init__(self, member: str) -> None:
        super().__init__(member)
        self.member = member


def canonical_envelope_digest(envelope: dict) -> str:
    payload = {key: value for key, value in envelope.items() if key != "envelope_digest"}
    encoded = json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def strict_object_pairs(pairs: list[tuple[str, object]]) -> dict:
    obj: dict = {}
    for key, value in pairs:
        if key in obj:
            raise DuplicateMember(key)
        obj[key] = value
    return obj


def parse_strict_json(text: str) -> dict:
    return json.loads(text, object_pairs_hook=strict_object_pairs)


def expectation_code(expect: list, index: int) -> str | None:
    if not isinstance(expect, list) or index >= len(expect) or not isinstance(expect[index], dict):
        return None
    code = expect[index].get("rejected_code")
    return code if isinstance(code, str) else None


def find_fixture_copy_dirs(repo: Path) -> list[Path]:
    """Accept tests/contract_fixtures at repo root or inside a crate."""
    found: list[Path] = []
    for current, dirs, _ in os.walk(repo):
        dirs[:] = sorted(d for d in dirs if d not in (".git", "target"))
        path = Path(current)
        if path.name == FIXTURE_COPY_DIR.name and path.parent.name == FIXTURE_COPY_DIR.parent.name:
            found.append(path)
    return sorted(found)


# Names such as P1.5-..., P15-... or PHASE-... are called out explicitly in the
# allowlist detail. They are rejected like any other unlisted file.
PHASE_LABELLED_NAME = re.compile(r"(?:^|[-_])(?:P\d+(?:[._-]\d+)*|PHASE)(?:[-_]|$)", re.IGNORECASE)


def tracked_fixture_files(repo: Path, copy_dir: Path) -> tuple[list[str], str]:
    """Return tracked paths inside a copied fixture directory, relative to it.

    Git is authoritative: an untracked stray file is not packaging evidence,
    but any tracked file beyond the canonical manifest list plus manifest.json
    is an unapproved fixture amendment and must fail closed. Nested paths are
    preserved verbatim so a file in a subdirectory cannot hide behind a name.
    """
    try:
        rel_dir = copy_dir.resolve().relative_to(repo.resolve())
    except ValueError:
        return [], "copy directory is outside the repository"
    code, output = git(repo, "ls-files", "-z", "--", rel_dir.as_posix())
    if code != 0:
        return [], f"git ls-files failed: {output}"
    files = sorted(
        Path(item).relative_to(rel_dir).as_posix() for item in output.split("\0") if item
    )
    return files, ""


def fixture_ledger_consistency(items: list, expect: list) -> bool:
    """Accepted events must be strictly increasing per (source_id, session_ref).

    A rejected event never reaches the ledger, so non-integer or missing
    sequence members on a rejected boundary case are not ledger violations.
    Accepted events still require both sequences to be integers.
    """
    ledgers: dict[tuple, tuple[int, int]] = {}
    for index, item in enumerate(items):
        if not isinstance(item, dict):
            return False
        if not isinstance(expect, list) or index >= len(expect) or not isinstance(expect[index], dict):
            return False
        accepted = expect[index].get("accepted") is True
        capture = item.get("capture_sequence")
        canonical = item.get("canonical_sequence")
        if accepted and (
            not isinstance(capture, int) or not isinstance(canonical, int)
        ):
            return False
        if not accepted:
            continue
        key = (item.get("source_id"), item.get("session_ref"))
        previous = ledgers.get(key)
        if previous and (capture <= previous[0] or canonical <= previous[1]):
            return False
        ledgers[key] = (capture, canonical)
    return True


def verify_fixture_semantics(
    results: list[dict], root: Path, files: list[dict], codes: set
) -> None:
    for meta in files:
        fid = meta.get("id", "UNKNOWN")
        path = root / str(meta.get("path", ""))
        digest_ok = path.is_file() and sha256_file(path) == meta.get("sha256")
        check(results, digest_ok, f"fixture/file/{fid}/sha256", f"path={meta.get('path')!r}")
        fixture, err = load_json(path)
        mode = fixture.get("mode") if isinstance(fixture, dict) else None
        members = set(fixture) if isinstance(fixture, dict) else set()
        expected_members = {"id", "mode", "events" if mode == "events" else "raw_events", "expect"}
        shape_ok = (
            err is None
            and isinstance(fixture, dict)
            and fixture.get("id") == fid
            and mode in ("events", "raw")
            and members == expected_members
            and isinstance(fixture.get("expect"), list)
            and isinstance(fixture.get("events" if mode == "events" else "raw_events"), list)
        )
        check(results, shape_ok, f"fixture/file/{fid}/shape", f"mode={mode!r} members={sorted(members)}")
        if not shape_ok:
            continue
        assert isinstance(fixture, dict)
        expect = fixture["expect"]
        items = fixture["events" if mode == "events" else "raw_events"]
        expect_ok = expect == meta.get("expectations") and len(expect) == len(items) and all(
            isinstance(entry, dict)
            and (
                (set(entry) == {"accepted"} and entry["accepted"] is True)
                or (
                    set(entry) == {"rejected_code"}
                    and isinstance(entry["rejected_code"], str)
                    and entry["rejected_code"] in codes
                )
            )
            for entry in expect
        )
        check(results, expect_ok, f"fixture/file/{fid}/expectations", f"entries={len(expect)}")
        if mode == "events":
            check(
                results,
                fixture_ledger_consistency(items, expect),
                f"fixture/file/{fid}/ledger_consistency",
                "accepted events strictly increasing per (source_id, session_ref)",
            )
        digests_ok = True
        for index, item in enumerate(items):
            code = expectation_code(expect, index)
            expect_mismatch = code == "ENVELOPE_DIGEST_MISMATCH"
            structural = code == "UNKNOWN_OR_MISSING_MEMBER"
            duplicate = None
            obj = item
            if mode == "raw":
                if not isinstance(item, str):
                    digests_ok = False
                    continue
                try:
                    obj = parse_strict_json(item)
                except DuplicateMember as exc:
                    duplicate = exc.member
                    obj = None
                except ValueError:
                    obj = None
                if duplicate is not None:
                    # A duplicate is the sole defect: the recorded digest must
                    # still be the digest of the equivalent unique-member object.
                    unique_digest = None
                    try:
                        resolved = json.loads(item)
                        if isinstance(resolved, dict):
                            unique_digest = canonical_envelope_digest(resolved)
                    except ValueError:
                        pass
                    digests_ok = digests_ok and (
                        duplicate in ENVELOPE_FIELDS
                        and structural
                        and unique_digest is not None
                        and unique_digest == resolved.get("envelope_digest")
                    )
                    continue
            if not isinstance(obj, dict):
                digests_ok = False
                continue
            member_set = tuple(sorted(obj))
            if member_set != tuple(sorted(ENVELOPE_FIELDS)):
                # Required-member absence is a structural rejection, not a
                # digest mismatch: verify the digest over the members present.
                payload = {key: value for key, value in obj.items() if key != "envelope_digest"}
                encoded = json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
                recomputed = hashlib.sha256(encoded.encode("utf-8")).hexdigest()
                digests_ok = digests_ok and (
                    structural
                    and set(obj).issubset(ENVELOPE_FIELDS)
                    and recomputed == obj.get("envelope_digest")
                )
                continue
            matches = canonical_envelope_digest(obj) == obj.get("envelope_digest")
            digests_ok = digests_ok and (matches != expect_mismatch)
        check(results, digests_ok, f"fixture/file/{fid}/envelope_digests", "v1 canonical digest rule")


def verify_fixtures(results: list[dict], root: Path) -> str:
    """Verify the golden fixtures and owner copies; return the actual manifest digest."""
    index, index_err = load_json(root / "contracts" / "contract-index.json")
    entry = index.get("fixtures") if isinstance(index, dict) else None
    note = str(entry.get("note", "")) if isinstance(entry, dict) else ""
    entry_ok = (
        isinstance(entry, dict)
        and entry.get("path") == "contracts/fixtures/manifest.json"
        and entry.get("schema_version") == 1
        and entry.get("conformance_status") in FIXTURE_STATUSES
        and "conformance evidence only" in note.lower()
        and "not data admission" in note.lower()
    )
    check(results, entry_ok, "fixture/index/entry", f"status={(entry or {}).get('conformance_status')!r}")
    if not entry_ok:
        check(results, False, "fixture/manifest/parse", "SKIPPED: invalid index fixture entry")
        return ""
    if entry["conformance_status"] == FIXTURE_STATUS_VERIFIED:
        state, state_err = load_json(root / "CURRENT-STATE.json")
        recorded_heads = state.get("source_heads_at_record_time", {}) if isinstance(state, dict) else {}
        observed = entry.get("observed_heads")
        counts = entry.get("test_counts")
        evidence_ok = (
            state_err is None
            and isinstance(observed, dict)
            and all(observed.get(repo) == recorded_heads.get(repo) for repo in ("fieldbook", "nirnay"))
            and isinstance(counts, dict)
            and all(isinstance(counts.get(repo), int) and counts[repo] > 0 for repo in ("fieldbook", "nirnay"))
        )
        check(
            results,
            evidence_ok,
            "fixture/index/behaviour_evidence",
            f"heads={observed} test_counts={counts}",
        )

    manifest_path = root / entry["path"]
    manifest_digest = sha256_file(manifest_path) if manifest_path.is_file() else ""
    check(
        results,
        manifest_path.is_file() and manifest_digest == entry.get("sha256"),
        "fixture/manifest/sha256",
        f"recorded={str(entry.get('sha256'))[:12]} actual={manifest_digest[:12]}",
    )
    manifest, err = load_json(manifest_path)
    check(results, err is None and isinstance(manifest, dict), "fixture/manifest/parse", err or "parsed")
    if err is not None or not isinstance(manifest, dict):
        return manifest_digest
    assert isinstance(manifest, dict)

    check(
        results,
        manifest.get("schema_version") == 1,
        "fixture/manifest/schema_version",
        f"schema_version={manifest.get('schema_version')!r}",
    )
    fmt = manifest.get("fixture_format")
    format_keys = (
        "top_level_members", "id", "mode", "events", "raw_events", "expect",
        "rejection_code_authority", "envelope_digest_rule", "events_mode_ledgers",
        "raw_mode_duplicate_rule", "neutral_scope",
    )
    format_ok = isinstance(fmt, dict) and all(k in fmt for k in format_keys)
    check(results, format_ok, "fixture/manifest/format", f"documented_keys={len(format_keys)}")

    p13_format_keys = (
        "p13_integer_boundaries", "p13_enum_types", "p13_ledger_admission",
        "p13_canonicalisation", "p13_behaviour_full_set", "p13_fixture_groups",
    )
    groups = fmt.get("p13_fixture_groups") if isinstance(fmt, dict) else None
    grouped_ids = (
        [fid for group in groups.values() for fid in group]
        if isinstance(groups, dict)
        and all(isinstance(group, list) and all(isinstance(fid, str) for fid in group) for group in groups.values())
        else []
    )
    p13_format_ok = (
        isinstance(fmt, dict)
        and all(isinstance(fmt.get(key), str) and fmt[key] for key in p13_format_keys[:-1])
        and len(grouped_ids) == len(P13_FIXTURE_IDS)
        and tuple(sorted(grouped_ids)) == tuple(sorted(P13_FIXTURE_IDS))
    )
    check(
        results,
        p13_format_ok,
        "fixture/manifest/p13_documentation",
        f"documented_keys={len(p13_format_keys)} grouped_ids={len(grouped_ids)}",
    )

    files = manifest.get("files")
    ids = [f.get("id") for f in files if isinstance(f, dict)] if isinstance(files, list) else []
    files_ok = (
        isinstance(files, list)
        and len(files) == len(FIXTURE_REQUIRED_IDS)
        and tuple(ids) == FIXTURE_REQUIRED_IDS
        and all(
            isinstance(f, dict)
            and f.get("path") == f"contracts/fixtures/{f.get('id')}.json"
            and isinstance(f.get("sha256"), str)
            and re.fullmatch(r"[0-9a-f]{64}", f["sha256"])
            and isinstance(f.get("expectations"), list)
            for f in files
        )
    )
    check(results, files_ok, "fixture/manifest/files", f"ids={ids}")

    for fid in P13_FIXTURE_IDS:
        check(
            results,
            ids.count(fid) == 1,
            f"fixture/coverage/{fid}",
            f"occurrences={ids.count(fid)}",
        )
    p13_meta = [f for f in files if isinstance(f, dict) and f.get("id") in P13_FIXTURE_IDS] if isinstance(files, list) else []
    p13_digest_ok = len(p13_meta) == len(P13_FIXTURE_IDS) and all(
        meta.get("path") == f"contracts/fixtures/{meta.get('id')}.json"
        and (root / str(meta.get("path"))).is_file()
        and sha256_file(root / str(meta.get("path"))) == meta.get("sha256")
        for meta in p13_meta
    )
    check(
        results,
        p13_digest_ok,
        "fixture/coverage/p13_file_digests",
        f"files={len(p13_meta)} expected={len(P13_FIXTURE_IDS)}",
    )
    all_digest_ok = isinstance(files, list) and all(
        isinstance(meta, dict)
        and (root / str(meta.get("path"))).is_file()
        and sha256_file(root / str(meta.get("path"))) == meta.get("sha256")
        for meta in files
    )
    check(
        results,
        all_digest_ok,
        "fixture/coverage/all_file_digests",
        f"files={len(files) if isinstance(files, list) else 0}",
    )

    spec, spec_err = load_json(root / "contracts" / "source-event-envelope-v1.json")
    codes = (
        {c.get("code") for c in spec.get("rejection_reason_codes", []) if isinstance(c, dict)}
        if spec_err is None and isinstance(spec, dict) else set()
    )
    check(results, bool(codes), "fixture/spec/rejection_codes", f"codes={len(codes)}")
    if not files_ok or not codes:
        return manifest_digest
    assert isinstance(files, list)
    verify_fixture_semantics(results, root, files, codes)

    for repo in ("fieldbook", "nirnay"):
        copy_dirs = find_fixture_copy_dirs((root / repo).resolve())
        check(
            results,
            bool(copy_dirs),
            f"fixture/copies/{repo}/directory",
            f"found={[str(p) for p in copy_dirs]}",
        )
        copy_dir = next(
            (
                path for path in copy_dirs
                if (path / "manifest.json").is_file()
                and sha256_file(path / "manifest.json") == manifest_digest
            ),
            None,
        )
        check(
            results,
            copy_dir is not None,
            f"fixture/copies/{repo}/manifest",
            f"matched={str(copy_dir) if copy_dir else 'none'} expected={manifest_digest[:12]}",
        )
        missing: list[str] = []
        mismatched: list[str] = []
        for meta in files:
            name = Path(meta["path"]).name
            target = (copy_dir / name) if copy_dir else None
            if target is None or not target.is_file():
                missing.append(name)
            elif sha256_file(target) != meta["sha256"]:
                mismatched.append(name)
        check(
            results,
            copy_dir is not None and not missing and not mismatched,
            f"fixture/copies/{repo}/files",
            f"dir={str(copy_dir) if copy_dir else 'none'} missing={missing} mismatched={mismatched}",
        )

        # Exact allowlist: the tracked file set of each copied fixture directory
        # must equal the canonical manifest file list plus manifest.json. Any
        # extra tracked file (especially a phase-labelled one) fails closed.
        expected_tracked = sorted({Path(meta["path"]).name for meta in files} | {"manifest.json"})
        if copy_dir is None:
            tracked: list[str] = []
            track_err = "no fixture copy directory matched the canonical manifest"
        else:
            tracked, track_err = tracked_fixture_files((root / repo).resolve(), copy_dir)
        extra = sorted(set(tracked) - set(expected_tracked))
        missing_tracked = sorted(set(expected_tracked) - set(tracked))
        phase_labelled = sorted(
            name for name in extra if PHASE_LABELLED_NAME.search(Path(name).name)
        )
        allowlist_ok = track_err == "" and not extra and not missing_tracked
        detail = (
            f"dir={str(copy_dir) if copy_dir else 'none'} "
            f"tracked={len(tracked)} expected={len(expected_tracked)} "
            f"extra={extra} missing={missing_tracked}"
        )
        if phase_labelled:
            detail += f" phase_labelled={phase_labelled}"
        if track_err:
            detail += f" error={track_err}"
        check(
            results,
            allowlist_ok,
            f"fixture/copies/{repo}/tracked_allowlist",
            detail,
        )
    return manifest_digest


def default_cargo_runner(command: tuple[str, ...], cwd: Path, env: dict) -> dict:
    try:
        proc = subprocess.run(
            list(command), cwd=str(cwd), env=env, capture_output=True, text=True, timeout=1800, check=False
        )
    except subprocess.TimeoutExpired:
        return {"exit_code": None, "stdout": "", "stderr": "TIMEOUT after 1800s"}
    except OSError as exc:
        return {"exit_code": None, "stdout": "", "stderr": f"cargo error: {exc.__class__.__name__}"}
    return {"exit_code": proc.returncode, "stdout": proc.stdout, "stderr": proc.stderr}


def verify_behaviour(
    results: list[dict],
    root: Path,
    manifest_digest: str,
    runner=None,
    forced_target_dir: str | None = None,
) -> dict:
    """Run the same fixture test in both repos; exit 0 in both is mandatory."""
    state, _ = load_json(root / "CURRENT-STATE.json")
    heads = state.get("source_heads_at_record_time", {}) if isinstance(state, dict) else {}
    target_raw = forced_target_dir if forced_target_dir is not None else os.environ.get("CONTRACT_CONFORMANCE_TARGET_DIR")
    target = (
        Path(target_raw).expanduser().resolve()
        if target_raw
        else Path(tempfile.mkdtemp(prefix="contract-conformance-target-")).resolve()
    )
    repo_paths = {repo: (root / repo).resolve() for repo in ("fieldbook", "nirnay")}
    outside = all(
        target != path and path not in target.parents for path in repo_paths.values()
    )
    check(results, outside, "behaviour/target_dir_outside_repos", f"target={target}")
    if outside:
        try:
            target.mkdir(parents=True, exist_ok=True)
        except OSError:
            check(results, False, "behaviour/target_dir_created", f"target={target}")
            outside = False

    reports: dict[str, dict] = {}
    for repo, repo_path in repo_paths.items():
        code, head = git(repo_path, "rev-parse", "HEAD")
        _, dirty = git(repo_path, "status", "--porcelain")
        recorded = heads.get(repo) if isinstance(heads, dict) else None
        head_ok = code == 0 and re.fullmatch(r"[0-9a-f]{40}", head or "") and head == recorded
        clean = dirty == ""
        check(
            results,
            head_ok and clean,
            f"behaviour/{repo}/exact_head",
            f"head={head[:12]} recorded={str(recorded)[:12]} dirty={not clean}",
        )
        entry_ok = head_ok and clean and outside
        if entry_ok:
            env = dict(os.environ)
            env["CARGO_TARGET_DIR"] = str(target)
            run = (runner or default_cargo_runner)(BEHAVIOUR_COMMAND, repo_path, env)
            exit_code = run.get("exit_code")
            stdout = str(run.get("stdout", ""))
            stderr = str(run.get("stderr", ""))
        else:
            exit_code = None
            stdout = ""
            stderr = "SKIPPED: head mismatch, dirty checkout or unsafe CARGO_TARGET_DIR"
        tests_passed = sum(
            int(count)
            for count in re.findall(r"test result: ok\. (\d+) passed;", stdout + "\n" + stderr)
        )
        tests_ok = exit_code == 0 and tests_passed > 0
        check(
            results,
            exit_code == 0,
            f"behaviour/{repo}/cargo_test",
            f"command={' '.join(BEHAVIOUR_COMMAND)} exit_code={exit_code}",
        )
        check(
            results,
            tests_ok,
            f"behaviour/{repo}/tests_run",
            f"passed={tests_passed} exit_code={exit_code}",
        )
        fixture_count = len(FIXTURE_REQUIRED_IDS)
        source_code, source_text = git(repo_path, "show", f"HEAD:{CONFORMANCE_TEST_PATHS[repo]}")
        source_available = source_code == 0 and bool(source_text.strip())
        if source_available:
            full_set_ok = (
                str(fixture_count) in source_text
                and "assert_eq!" in source_text
                and "len()" in source_text
                and ("for " in source_text and "files" in source_text)
            )
            detail = (
                f"source={CONFORMANCE_TEST_PATHS[repo]} count={fixture_count}"
                f" assertion_and_iteration={full_set_ok}"
            )
        else:
            # Synthetic self-test repositories have no Rust suite; their
            # runner must report the full fixture count explicitly.
            full_set_ok = tests_passed >= fixture_count
            detail = (
                f"no Rust suite at {CONFORMANCE_TEST_PATHS[repo]};"
                f" stub_passed={tests_passed} expected={fixture_count}"
            )
        check(
            results,
            full_set_ok,
            f"behaviour/{repo}/full_fixture_set",
            detail,
        )
        passed = tests_ok and full_set_ok
        reports[repo] = {
            "head": head if code == 0 else None,
            "recorded_head": recorded,
            "head_matches_record": head_ok,
            "clean_checkout": clean,
            "command": " ".join(BEHAVIOUR_COMMAND),
            "exit_code": exit_code,
            "status": "PASS" if passed else "FAIL",
            "tests_passed": tests_passed,
            "stdout_sha256": hashlib.sha256(stdout.encode("utf-8")).hexdigest(),
            "stderr_sha256": hashlib.sha256(stderr.encode("utf-8")).hexdigest(),
            "stderr_tail": stderr[-1000:],
            "cargo_target_dir": str(target),
            "cargo_target_dir_outside_repos": outside,
        }
    behaviour_ok = all(r["status"] == "PASS" for r in reports.values()) and outside
    return {
        "status": "PASS" if behaviour_ok else "FAIL",
        "required_exit_code": 0,
        "command": " ".join(BEHAVIOUR_COMMAND),
        "cargo_target_dir": str(target),
        "cargo_target_dir_outside_repos": outside,
        "fixture_manifest_digest": manifest_digest,
        "repos": reports,
    }


def verify(
    root: Path,
    behaviour: bool = False,
    runner=None,
    forced_target_dir: str | None = None,
) -> dict:
    results: list[dict] = []
    verify_contracts(results, root)
    verify_freeze(results, root)
    verify_sources(results, root)
    structural = list(results)
    manifest_digest = verify_fixtures(results, root)
    behaviour_result = (
        verify_behaviour(results, root, manifest_digest, runner=runner, forced_target_dir=forced_target_dir)
        if behaviour else None
    )
    failed = [r for r in results if r["status"] != "PASS"]
    structural_failed = [r for r in structural if r["status"] != "PASS"]
    return {
        "tool": "check_contracts",
        "mode": "behaviour" if behaviour else "verify",
        "ok": not failed,
        "structural": {
            "ok": not structural_failed,
            "total": len(structural),
            "passed": len(structural) - len(structural_failed),
            "failed": len(structural_failed),
            "failure_codes": [r["code"] for r in structural_failed],
        },
        "fixture_manifest_digest": manifest_digest,
        "behaviour": behaviour_result if behaviour_result is not None else {"status": "PENDING_NOT_RUN_IN_NORMAL_MODE"},
        "checks": results,
        "passed": len(results) - len(failed),
        "failed": len(failed),
        "failure_codes": [r["code"] for r in failed],
    }


def fixture_specs() -> dict[str, dict]:
    envelope = {
        "name": "source-event-envelope-v1",
        "schema_version": 1,
        "fields": [
            {"ordinal": i, "name": n, "type": "string", "rules": ["non-empty"], "required": True}
            for i, n in enumerate(ENVELOPE_FIELDS, 1)
        ],
        "rejection_reason_codes": [{"code": f"RC-{i:03d}"} for i in range(1, 11)],
        "negative_cases": [
            {"id": f"NEG-{i:03d}", "case": "bad", "expected_rejection": f"RC-{i:03d}"}
            for i in range(1, 11)
        ],
        "admission": {
            "admissible_quality_states": ["CAPTURED", "DECODED", "VALIDATED"],
            "inadmissible_quality_states": ["QUARANTINED"],
            "fail_closed": True,
        },
        "source_verification": {
            "schema_version_constant_pattern": "SOURCE[_-]?EVENT[_-]?ENVELOPE[_-]?(V1[_-]?)?SCHEMA[_-]?VERSION",
            "schema_version_constant_value": 1,
            "repositories": ["fieldbook", "nirnay"],
        },
    }
    research = {
        "name": "research-governance-v1",
        "schema_version": 1,
        "rules": [
            {"id": rid, "required_value": val}
            for rid, val in (
                ("RG-001", "CONSUMED_ONCE_POST_SELECTION_DO_NOT_REUSE"),
                ("RG-002", "BLOCKED"),
                ("RG-003", "FRESH_HOLDOUT_REQUIRED_BEFORE_ANY_FUTURE_RESEARCH"),
                ("RG-004", "RIGHTS_APPROVED_DATASET_REQUIRED"),
                ("RG-005", "NO_ALPHA_CLAIM_FROM_SYNTHETIC_EVIDENCE"),
                ("RG-006", "LINEAGE_REQUIRED"),
            )
        ],
        "experiment_register": {
            "EXP-M4-0001": {
                "holdout_disposition": EXPECTED_HOLDOUT_DISPOSITION,
                "holdout_may_be_reused": False,
                "holdout_may_be_relabelled_untouched": False,
                "counts_as_fresh_holdout": False,
                "supports_alpha_claim": False,
            }
        },
        "decision_record_required_lineage": list(REQUIRED_LINEAGE),
        "negative_cases": [{"id": f"N{i}", "expected_rejection": f"RG-00{i}"} for i in range(1, 7)],
    }
    arch = {
        "name": "continuous-paper-architecture-v1",
        "schema_version": 1,
        "lifecycle_order_contract": {"exact_order": list(LIFECYCLE_ORDER)},
        "lifecycle_stages": [{"name": n} for n in LIFECYCLE_ORDER],
        "fail_closed_conditions": [{"id": fid} for fid in FC_IDS],
        "no_broker_writes": {
            "enabled": False,
            "fail_closed_on_attempt": True,
            "statement": "NO_BROKER_WRITES. Local paper simulation only.",
        },
        "specification_only": {
            "is_implemented_service": False,
            "is_live_execution_path": False,
            "statement": "SPECIFICATION_ONLY_NOT_AN_IMPLEMENTED_SERVICE",
        },
        "negative_cases": [{"id": f"N{i}", "expected_rejection": f"FC-{i:03d}"} for i in range(1, 10)],
    }
    return {
        "source-event-envelope-v1": envelope,
        "research-governance-v1": research,
        "continuous-paper-architecture-v1": arch,
    }


def write_fixture_repo(path: Path, with_tokens: bool = True) -> str:
    path.mkdir(parents=True, exist_ok=True)
    lines = ["SOURCE_EVENT_ENVELOPE_SCHEMA_VERSION: u32 = 1"]
    if with_tokens:
        lines.extend(f"{name} = 1" for name in ENVELOPE_FIELDS)
    (path / "envelope.rs").write_text("\n".join(lines) + "\n", encoding="utf-8")
    env = dict(os.environ)
    env.update(
        GIT_AUTHOR_NAME="fixture",
        GIT_AUTHOR_EMAIL="fixture@example.invalid",
        GIT_COMMITTER_NAME="fixture",
        GIT_COMMITTER_EMAIL="fixture@example.invalid",
        GIT_AUTHOR_DATE="2026-01-01T00:00:00Z",
        GIT_COMMITTER_DATE="2026-01-01T00:00:00Z",
    )
    for args in (("init", "-q"), ("add", "envelope.rs"), ("commit", "-q", "-m", "fixture")):
        proc = subprocess.run(["git", "-C", str(path), *args], capture_output=True, text=True, env=env, check=False)
        if proc.returncode != 0:
            raise RuntimeError(f"fixture git {args[0]} failed: {proc.stderr.strip()}")
    code, head = git(path, "rev-parse", "HEAD")
    if code != 0:
        raise RuntimeError("fixture head unavailable")
    return head


def self_test() -> dict:
    cases: list[dict] = []
    with tempfile.TemporaryDirectory(prefix="check-contracts-selftest-") as tmp:
        root = Path(tmp)
        (root / "contracts").mkdir()
        state_path = root / "CURRENT-STATE.json"
        index_path = root / "contracts" / "contract-index.json"
        fixture_source_dir = Path(__file__).resolve().parent.parent / "contracts" / "fixtures"
        fixture_bytes = {p.name: p.read_bytes() for p in sorted(fixture_source_dir.glob("*.json"))}
        if not fixture_bytes or "manifest.json" not in fixture_bytes:
            raise RuntimeError("golden fixture files are unavailable for --self-test")
        real_spec, real_spec_err = load_json(fixture_source_dir.parent / "source-event-envelope-v1.json")
        if real_spec_err is not None or not isinstance(real_spec, dict):
            raise RuntimeError("v1 spec is unavailable for --self-test fixture codes")
        fixture_digest = hashlib.sha256(fixture_bytes["manifest.json"]).hexdigest()
        specs = fixture_specs()
        normative_codes = real_spec["rejection_reason_codes"]
        specs["source-event-envelope-v1"]["rejection_reason_codes"] = normative_codes
        specs["source-event-envelope-v1"]["negative_cases"] = [
            {"id": f"NEG-{i:03d}", "case": "bad", "expected_rejection": entry["code"]}
            for i, entry in enumerate(normative_codes, 1)
        ]
        for name, spec in specs.items():
            (root / "contracts" / f"{name}.json").write_text(
                json.dumps(spec, sort_keys=True, separators=(",", ":")), encoding="utf-8"
            )

        def fresh_index() -> dict:
            entries = {
                name: {
                    "path": f"contracts/{name}.json",
                    "schema_version": 1,
                    "sha256": sha256_file(root / "contracts" / f"{name}.json"),
                    "status": SPEC_STATUS[name],
                }
                for name in SPEC_NAMES
            }
            entries["source-event-envelope-v1"]["verification"] = {
                "status": "VERIFIED_AT_EXACT_HEADS",
                "fieldbook": heads["fieldbook"],
                "nirnay": heads["nirnay"],
            }
            return {
                "schema_version": 1,
                "specs": entries,
                "fixtures": {
                    "path": "contracts/fixtures/manifest.json",
                    "schema_version": 1,
                    "sha256": fixture_digest,
                    "conformance_status": FIXTURE_STATUS_PENDING,
                    "note": "Conformance evidence only; not data admission, rights grant, collection or live execution.",
                },
                "blocked_research": {"status": "BLOCKED"},
            }

        def write_state(state: dict) -> None:
            state_path.write_text(json.dumps(state, sort_keys=True, separators=(",", ":")), encoding="utf-8")

        def write_index(index: dict) -> None:
            index_path.write_text(json.dumps(index, sort_keys=True, separators=(",", ":")), encoding="utf-8")

        heads = {repo: write_fixture_repo(root / repo) for repo in ("fieldbook", "nirnay")}
        (root / "contracts" / "fixtures").mkdir()
        for name, data in fixture_bytes.items():
            (root / "contracts" / "fixtures" / name).write_bytes(data)

        def write_copies() -> None:
            for repo in ("fieldbook", "nirnay"):
                copy_dir = root / repo / FIXTURE_COPY_DIR
                copy_dir.mkdir(parents=True, exist_ok=True)
                for name, data in fixture_bytes.items():
                    (copy_dir / name).write_bytes(data)

        def commit_copies() -> None:
            env = dict(os.environ)
            env.update(
                GIT_AUTHOR_NAME="fixture",
                GIT_AUTHOR_EMAIL="fixture@example.invalid",
                GIT_COMMITTER_NAME="fixture",
                GIT_COMMITTER_EMAIL="fixture@example.invalid",
                GIT_AUTHOR_DATE="2026-01-02T00:00:00Z",
                GIT_COMMITTER_DATE="2026-01-02T00:00:00Z",
            )
            for repo in ("fieldbook", "nirnay"):
                repo_path = root / repo
                proc = subprocess.run(
                    ["git", "-C", str(repo_path), "add", str(FIXTURE_COPY_DIR)],
                    capture_output=True, text=True, env=env, check=False,
                )
                if proc.returncode != 0:
                    raise RuntimeError(f"fixture copy git add failed: {proc.stderr.strip()}")
                code, _ = git(repo_path, "diff", "--cached", "--quiet")
                if code == 0:
                    continue
                proc = subprocess.run(
                    ["git", "-C", str(repo_path), "commit", "-q", "-m", "fixture copies"],
                    capture_output=True, text=True, env=env, check=False,
                )
                if proc.returncode != 0:
                    raise RuntimeError(f"fixture copy git commit failed: {proc.stderr.strip()}")

        write_copies()
        commit_copies()
        for repo in ("fieldbook", "nirnay"):
            _, committed_head = git(root / repo, "rev-parse", "HEAD")
            heads[repo] = committed_head

        def restore_fixtures() -> None:
            for name, data in fixture_bytes.items():
                (root / "contracts" / "fixtures" / name).write_bytes(data)
            write_copies()

        freeze = dict(EXPECTED_FREEZE)
        freeze["m4"] = {"EXP-M4-0001": {"synthetic_holdout": EXPECTED_HOLDOUT_DISPOSITION}}
        base_state = {
            "source_heads_at_record_time": heads,
            "freeze": freeze,
            "capabilities": {"operational_qualification": "BLOCKED"},
            "release_gates": {"overall": {"status": "BLOCKED"}},
        }
        write_state(base_state)
        write_index(fresh_index())
        cases.append({"id": "SELF-001", "expect": "PASS", "result": verify(root)})

        broken_index = fresh_index()
        broken_index["specs"]["research-governance-v1"]["sha256"] = "0" * 64
        write_index(broken_index)
        cases.append({"id": "SELF-002", "expect": "FAIL:DIGEST", "result": verify(root)})
        write_index(fresh_index())

        broken = json.loads(json.dumps(base_state))
        broken["freeze"]["dataset_acceptance"] = "ACCEPTED"
        write_state(broken)
        cases.append({"id": "SELF-003", "expect": "FAIL:FREEZE", "result": verify(root)})

        broken = json.loads(json.dumps(base_state))
        broken["source_heads_at_record_time"]["nirnay"] = "0" * 40
        write_state(broken)
        cases.append({"id": "SELF-004", "expect": "FAIL:HEAD", "result": verify(root)})

        write_state(base_state)
        broken_spec = json.loads(json.dumps(specs["source-event-envelope-v1"]))
        broken_spec["schema_version"] = 2
        (root / "contracts" / "source-event-envelope-v1.json").write_text(
            json.dumps(broken_spec, sort_keys=True, separators=(",", ":")), encoding="utf-8"
        )
        write_index(fresh_index())
        cases.append({"id": "SELF-005", "expect": "FAIL:SPEC", "result": verify(root)})

        (root / "contracts" / "source-event-envelope-v1.json").write_text(
            json.dumps(specs["source-event-envelope-v1"], sort_keys=True, separators=(",", ":")), encoding="utf-8"
        )
        write_state(base_state)
        write_index(fresh_index())
        # Remove fixture copies from the Nirnay token scan so the missing-token
        # negative case is not masked by field names inside the JSON fixtures.
        removed = subprocess.run(
            ["git", "-C", str(root / "nirnay"), "rm", "-r", "-q", str(FIXTURE_COPY_DIR)],
            capture_output=True, text=True, check=False,
        )
        if removed.returncode != 0:
            raise RuntimeError(f"fixture copy removal failed: {removed.stderr.strip()}")
        missing_head = write_fixture_repo(root / "nirnay", with_tokens=False)
        broken = json.loads(json.dumps(base_state))
        broken["source_heads_at_record_time"]["nirnay"] = missing_head
        write_state(broken)
        cases.append({"id": "SELF-006", "expect": "FAIL:TOKENS", "result": verify(root)})

        write_copies()
        commit_copies()
        for repo in ("fieldbook", "nirnay"):
            _, committed_head = git(root / repo, "rev-parse", "HEAD")
            heads[repo] = committed_head
        base_state = json.loads(json.dumps(base_state))
        base_state["source_heads_at_record_time"]["nirnay"] = heads["nirnay"]
        write_state(base_state)
        write_index(fresh_index())
        restore_fixtures()
        fieldbook_copies = root / "fieldbook" / FIXTURE_COPY_DIR
        for item in fieldbook_copies.iterdir():
            item.unlink()
        fieldbook_copies.rmdir()
        cases.append({"id": "SELF-007", "expect": "FAIL:COPIES", "result": verify(root)})
        write_copies()

        nirnay_copy = root / "nirnay" / FIXTURE_COPY_DIR / "VAL-001.json"
        nirnay_copy.write_bytes(nirnay_copy.read_bytes() + b"\n")
        cases.append({"id": "SELF-008", "expect": "FAIL:COPY_DIGEST", "result": verify(root)})
        restore_fixtures()

        broken_index = fresh_index()
        broken_index["fixtures"]["sha256"] = "0" * 64
        write_index(broken_index)
        cases.append({"id": "SELF-009", "expect": "FAIL:FIXTURE_INDEX", "result": verify(root)})
        write_index(fresh_index())

        def stub_runner(command: tuple[str, ...], cwd: Path, env: dict, fail: bool = True) -> dict:
            count = len(json.loads((root / "contracts" / "fixtures" / "manifest.json").read_text(
                encoding="utf-8"))["files"])
            exit_code = 1 if fail and Path(cwd).name == "nirnay" else 0
            return {
                "exit_code": exit_code,
                "stdout": f"test result: ok. {count} passed; 0 failed; 0 ignored\n",
                "stderr": "determin-stub",
            }

        cases.append({
            "id": "SELF-010",
            "expect": "FAIL:BEHAVIOUR",
            "result": verify(
                root,
                behaviour=True,
                runner=stub_runner,
                forced_target_dir=str(root / "cargo-target-selftest"),
            ),
        })
        cases.append({
            "id": "SELF-011",
            "expect": "FAIL:TARGET",
            "result": verify(
                root,
                behaviour=True,
                runner=stub_runner,
                forced_target_dir=str(root / "fieldbook" / "target"),
            ),
        })

        fixture_path = root / "contracts" / "fixtures" / "VAL-001.json"
        mutated_fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
        mutated_fixture["expect"] = [{"rejected_code": "BOGUS_CODE"}]
        fixture_path.write_text(
            json.dumps(mutated_fixture, sort_keys=True, separators=(",", ":")), encoding="utf-8"
        )
        manifest_path = root / "contracts" / "fixtures" / "manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        for entry in manifest["files"]:
            if entry["id"] == "VAL-001":
                entry["sha256"] = sha256_file(fixture_path)
        manifest_path.write_text(
            json.dumps(manifest, sort_keys=True, separators=(",", ":")), encoding="utf-8"
        )
        repaired_index = fresh_index()
        repaired_index["fixtures"]["sha256"] = sha256_file(manifest_path)
        write_index(repaired_index)
        cases.append({"id": "SELF-012", "expect": "FAIL:FIXTURE_SEMANTICS", "result": verify(root)})
        write_index(fresh_index())
        restore_fixtures()

        verified_index = fresh_index()
        verified_index["fixtures"]["conformance_status"] = FIXTURE_STATUS_VERIFIED
        verified_index["fixtures"]["observed_heads"] = dict(heads)
        verified_index["fixtures"]["test_counts"] = {"fieldbook": 14, "nirnay": 14}
        write_index(verified_index)
        cases.append({"id": "SELF-013", "expect": "PASS", "result": verify(root)})
        wrong_heads = json.loads(json.dumps(verified_index))
        wrong_heads["fixtures"]["observed_heads"]["nirnay"] = "0" * 40
        write_index(wrong_heads)
        cases.append({"id": "SELF-014", "expect": "FAIL:OBSERVED_HEAD", "result": verify(root)})
        write_index(fresh_index())

        def passing_runner(command: tuple[str, ...], cwd: Path, env: dict) -> dict:
            return stub_runner(command, cwd, env, fail=False)

        cases.append({
            "id": "SELF-015",
            "expect": "PASS",
            "result": verify(
                root,
                behaviour=True,
                runner=passing_runner,
                forced_target_dir=str(root / "cargo-target-selftest-pass"),
            ),
        })

        coverage_manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        coverage_manifest["files"] = [
            entry for entry in coverage_manifest["files"]
            if entry["id"] != "P13-INT-SCHEMA"
        ]
        manifest_path.write_text(
            json.dumps(coverage_manifest, sort_keys=True, separators=(",", ":")), encoding="utf-8"
        )
        coverage_index = fresh_index()
        coverage_index["fixtures"]["sha256"] = sha256_file(manifest_path)
        write_index(coverage_index)
        cases.append({"id": "SELF-016", "expect": "FAIL:P13_COVERAGE", "result": verify(root)})
        write_index(fresh_index())
        restore_fixtures()

        # Exact allowlist negative cases: one extra TRACKED file per repo must
        # fail closed, including phase-labelled names that imply an unapproved
        # fixture amendment. Rebind heads after each commit so no other check
        # is affected and the allowlist code is the sole failure.
        def commit_extra(repo_name: str, filename: str, remove: bool = False) -> None:
            rel = (FIXTURE_COPY_DIR / filename).as_posix()
            env = dict(os.environ)
            env.update(
                GIT_AUTHOR_NAME="fixture",
                GIT_AUTHOR_EMAIL="fixture@example.invalid",
                GIT_COMMITTER_NAME="fixture",
                GIT_COMMITTER_EMAIL="fixture@example.invalid",
                GIT_AUTHOR_DATE="2026-01-03T00:00:00Z",
                GIT_COMMITTER_DATE="2026-01-03T00:00:00Z",
            )
            if not remove:
                (root / repo_name / rel).write_text("{}\n", encoding="utf-8")
            args = ("rm", "-q", "--", rel) if remove else ("add", "--", rel)
            for step in (args, ("commit", "-q", "-m", f"{'remove' if remove else 'inject'} {filename}")):
                proc = subprocess.run(
                    ["git", "-C", str(root / repo_name), *step],
                    capture_output=True, text=True, env=env, check=False,
                )
                if proc.returncode != 0:
                    raise RuntimeError(f"fixture extra {step[0]} failed: {proc.stderr.strip()}")
            _, new_head = git(root / repo_name, "rev-parse", "HEAD")
            heads[repo_name] = new_head
            base_state["source_heads_at_record_time"][repo_name] = new_head
            write_state(base_state)
            write_index(fresh_index())

        extra_fieldbook = "P1.5-PHASE-EXTRA.json"
        extra_nirnay = "P15-UNLISTED.json"
        commit_extra("fieldbook", extra_fieldbook)
        cases.append({
            "id": "SELF-017",
            "expect": "FAIL:EXTRA_FIXTURE",
            "expect_detail_contains": extra_fieldbook,
            "result": verify(root),
        })
        commit_extra("nirnay", extra_nirnay)
        cases.append({
            "id": "SELF-018",
            "expect": "FAIL:EXTRA_FIXTURE",
            "expect_detail_contains": extra_nirnay,
            "result": verify(root),
        })
        commit_extra("fieldbook", extra_fieldbook, remove=True)
        commit_extra("nirnay", extra_nirnay, remove=True)
        restore_fixtures()
        cases.append({"id": "SELF-019", "expect": "PASS", "result": verify(root)})

    def classify(case: dict) -> bool:
        expect = case["expect"]
        result = case["result"]
        if expect == "PASS":
            return bool(result["ok"])
        codes = set(result["failure_codes"])
        if expect == "FAIL:DIGEST":
            return not result["ok"] and any("sha256" in c for c in codes)
        if expect == "FAIL:FREEZE":
            return not result["ok"] and any(c.startswith("freeze/") for c in codes)
        if expect == "FAIL:HEAD":
            return not result["ok"] and "source/nirnay/head" in codes
        if expect == "FAIL:SPEC":
            return not result["ok"] and any(c.endswith("/schema_version") and "envelope" in c for c in codes)
        if expect == "FAIL:TOKENS":
            return not result["ok"] and "source/nirnay/field_tokens" in codes
        if expect == "FAIL:COPIES":
            return not result["ok"] and any(c.startswith("fixture/copies/fieldbook/") for c in codes)
        if expect == "FAIL:COPY_DIGEST":
            return not result["ok"] and "fixture/copies/nirnay/files" in codes
        if expect == "FAIL:FIXTURE_INDEX":
            return not result["ok"] and "fixture/manifest/sha256" in codes
        if expect == "FAIL:BEHAVIOUR":
            return (
                not result["ok"]
                and "behaviour/nirnay/cargo_test" in codes
                and result["behaviour"]["repos"]["nirnay"]["exit_code"] == 1
                and result["behaviour"]["repos"]["fieldbook"]["exit_code"] == 0
            )
        if expect == "FAIL:TARGET":
            return not result["ok"] and "behaviour/target_dir_outside_repos" in codes
        if expect == "FAIL:FIXTURE_SEMANTICS":
            return not result["ok"] and "fixture/file/VAL-001/expectations" in codes
        if expect == "FAIL:OBSERVED_HEAD":
            return not result["ok"] and "fixture/index/behaviour_evidence" in codes
        if expect == "FAIL:P13_COVERAGE":
            return (
                not result["ok"]
                and "fixture/manifest/files" in codes
                and "fixture/coverage/P13-INT-SCHEMA" in codes
            )
        if expect == "FAIL:EXTRA_FIXTURE":
            allowlist_failed = any(
                c["status"] == "FAIL"
                and c["code"].startswith("fixture/copies/")
                and c["code"].endswith("/tracked_allowlist")
                for c in result["checks"]
            )
            if not (not result["ok"] and allowlist_failed):
                return False
            needle = case.get("expect_detail_contains")
            return not needle or any(
                c["status"] == "FAIL"
                and c["code"].endswith("/tracked_allowlist")
                and needle in c["detail"]
                for c in result["checks"]
            )
        return False

    passed = sum(classify(c) for c in cases)
    return {
        "tool": "check_contracts",
        "mode": "self-test",
        "ok": passed == len(cases),
        "passed": passed,
        "total": len(cases),
        "cases": [
            {
                "id": c["id"],
                "expect": c["expect"],
                "passed": classify(c),
                "failure_codes": c["result"]["failure_codes"],
            }
            for c in cases
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true", help="run deterministic fixture tests")
    parser.add_argument("--root", default=None, help="workspace root (default: parent of scripts/)")
    parser.add_argument(
        "--behaviour",
        action="store_true",
        help="run cargo test --test contract_conformance in both repos; both must exit 0",
    )
    parser.add_argument("--out", default=None, help="also write the JSON result to this path")
    args = parser.parse_args()
    root = Path(args.root).resolve() if args.root else Path(__file__).resolve().parent.parent
    result = self_test() if args.self_test else verify(root, behaviour=args.behaviour)
    payload = json.dumps(result, sort_keys=True, separators=(",", ":"))
    if args.out:
        Path(args.out).write_text(payload + "\n", encoding="utf-8")
    print(payload)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
