#!/usr/bin/env python3
"""Deterministic, stdlib-only checker for the v1 workspace contracts.

Normal mode emits exactly one JSON object and exits 0 only when every check
passes. --self-test builds temporary fixtures (including two tiny Git
repositories) and exercises positive and negative cases.
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
    pattern = sv["schema_version_constant_pattern"]
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


def verify(root: Path) -> dict:
    results: list[dict] = []
    verify_contracts(results, root)
    verify_freeze(results, root)
    verify_sources(results, root)
    failed = [r for r in results if r["status"] != "PASS"]
    return {
        "tool": "check_contracts",
        "mode": "verify",
        "ok": not failed,
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
        specs = fixture_specs()
        for name, spec in specs.items():
            (root / "contracts" / f"{name}.json").write_text(
                json.dumps(spec, sort_keys=True, separators=(",", ":")), encoding="utf-8"
            )

        def fresh_index() -> dict:
            return {
                "schema_version": 1,
                "specs": {
                    name: {
                        "path": f"contracts/{name}.json",
                        "schema_version": 1,
                        "sha256": sha256_file(root / "contracts" / f"{name}.json"),
                        "status": SPEC_STATUS[name],
                    }
                    for name in SPEC_NAMES
                },
            }

        def write_state(state: dict) -> None:
            state_path.write_text(json.dumps(state, sort_keys=True, separators=(",", ":")), encoding="utf-8")

        def write_index(index: dict) -> None:
            index_path.write_text(json.dumps(index, sort_keys=True, separators=(",", ":")), encoding="utf-8")

        heads = {repo: write_fixture_repo(root / repo) for repo in ("fieldbook", "nirnay")}
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
        missing_head = write_fixture_repo(root / "nirnay", with_tokens=False)
        broken = json.loads(json.dumps(base_state))
        broken["source_heads_at_record_time"]["nirnay"] = missing_head
        write_state(broken)
        cases.append({"id": "SELF-006", "expect": "FAIL:TOKENS", "result": verify(root)})

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
    args = parser.parse_args()
    root = Path(args.root).resolve() if args.root else Path(__file__).resolve().parent.parent
    result = self_test() if args.self_test else verify(root)
    print(json.dumps(result, sort_keys=True, separators=(",", ":")))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
