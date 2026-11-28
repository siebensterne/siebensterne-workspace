#!/usr/bin/env python3
"""Deterministic stdlib-only self-test for scripts/package_review.sh.

Guards the hosted-CI repository mapping: the workspace repository must be
siebensterne/siebensterne-workspace, and a deliberately wrong mapping must
fail closed instead of silently querying a non-canonical repository. No
network, no packaging and no writes are performed by this test. It prints one
JSON object and exits non-zero if any case fails.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent / "package_review.sh"
BEGIN = "# ---- BEGIN canonical CI repository mapping (tested by scripts/test_package_review.py) ----"
END = "# ---- END canonical CI repository mapping ----"
WRONG_WORKSPACE_SLUG = "siebensterne/workspace"
CANONICAL = {
    "fieldbook": "siebensterne/fieldbook",
    "nirnay": "siebensterne/nirnay",
    "workspace": "siebensterne/siebensterne-workspace",
}
WORKSPACE_LINE = "    workspace) printf '%s\\n' 'siebensterne/siebensterne-workspace' ;;"


def mapping_block(source: str) -> str:
    """Extract the self-contained mapping block from the shell source."""
    if BEGIN not in source or END not in source:
        raise RuntimeError("canonical repository mapping block markers are missing")
    head, rest = source.split(BEGIN, 1)
    block, tail = rest.split(END, 1)
    del head, tail
    return BEGIN + block + END


def run_bash(block: str, command: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", "-c", f"{block}\n{command}"],
        capture_output=True,
        text=True,
        timeout=30,
        check=False,
    )


def self_test() -> dict:
    cases: list[dict] = []
    source = SCRIPT.read_text(encoding="utf-8")
    block = mapping_block(source)

    for name, expected in CANONICAL.items():
        proc = run_bash(block, f'repo_slug "{name}"')
        cases.append({
            "id": f"MAP-{name}",
            "expect": expected,
            "ok": proc.returncode == 0 and proc.stdout.strip() == expected and proc.stderr == "",
            "detail": f"exit={proc.returncode} stdout={proc.stdout.strip()!r} stderr={proc.stderr.strip()!r}",
        })

    proc = run_bash(block, 'repo_slug "not-a-repository"')
    cases.append({
        "id": "MAP-UNKNOWN-FAILS-CLOSED",
        "expect": "non-zero exit, no slug emitted",
        "ok": (
            proc.returncode != 0
            and proc.stdout.strip() == ""
            and "no canonical CI repository mapping" in proc.stderr
        ),
        "detail": f"exit={proc.returncode} stdout={proc.stdout.strip()!r} stderr={proc.stderr.strip()!r}",
    })

    # Deliberate regression: inject the historical wrong workspace slug into
    # the mapping only. The independent verification pin must reject it.
    if block.count(WORKSPACE_LINE) != 1:
        raise RuntimeError("workspace mapping line is not uniquely identifiable")
    mutated = block.replace(
        WORKSPACE_LINE,
        WORKSPACE_LINE.replace("siebensterne/siebensterne-workspace", WRONG_WORKSPACE_SLUG),
    )
    proc = run_bash(mutated, "verify_repo_mapping")
    cases.append({
        "id": "MAP-WRONG-FAILS-CLOSED",
        "expect": "verify_repo_mapping rejects the wrong workspace slug",
        "ok": (
            proc.returncode != 0
            and f"workspace is {WRONG_WORKSPACE_SLUG}" in proc.stderr
            and f"expected {CANONICAL['workspace']}" in proc.stderr
            and proc.stdout.strip() == ""
        ),
        "detail": f"exit={proc.returncode} stderr={proc.stderr.strip()!r}",
    })

    # The packaging script must actually use the mapping and verify it before
    # building anything; a hard-coded "siebensterne/$name" is the regression.
    wiring = {
        "CI query uses repo_slug": '--repo "$(repo_slug "$name")"' in source,
        "no hard-coded repo prefix": '--repo "siebensterne/$name"' not in source,
        "mapping verified before packaging": "if ! verify_repo_mapping; then" in source,
    }
    for label, ok in wiring.items():
        cases.append({"id": f"MAP-WIRING/{label}", "expect": "present", "ok": ok, "detail": label})

    passed = sum(case["ok"] for case in cases)
    return {
        "tool": "test_package_review",
        "mode": "self-test",
        "ok": passed == len(cases),
        "passed": passed,
        "total": len(cases),
        "cases": cases,
    }


def main() -> int:
    result = self_test()
    print(json.dumps(result, sort_keys=True, separators=(",", ":")))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
