#!/usr/bin/env python3
"""Check the WP-5 NDC v2 workspace vector package.

<!-- SPDX-License-Identifier: Apache-2.0 -->

This is workspace evidence tooling. It is not a producer, a verifier, a shared validator,
a connector or a runtime component. It hashes the vector files against the index, scans the
index for secret material and rooted or upward path literals, and checks that every test
token cited by the index or the acceptance matrix exists in the named exact-head source file
when the corresponding local clone is present.
"""

from __future__ import annotations

import hashlib
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VECTOR_DIR = ROOT / "engineering" / "conformance" / "ndc-v2-conformance-vectors"
INDEX = VECTOR_DIR / "VECTORS.md"
MATRIX = ROOT / "engineering" / "conformance" / "ndc-v2-acceptance-matrix.md"

EXPECTED_HEADS = {
    "fieldbook": "2ef88a955f74a7c88e4573683267446e331465e9",
    "nirnay": "2dad4962b584c557237d219c1c5356fc58bc4b69",
}

SECRET_PATTERNS = [
    re.compile(r"9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60", re.I),
    re.compile(r"(?i)secret[ _-]?seed"),
    re.compile(r"(?i)private[ _-]?key"),
    re.compile(r"(?i)BEGIN [A-Z ]*PRIVATE KEY"),
    re.compile(r"0x9d\s*,\s*0x61\s*,\s*0xb1\s*,\s*0x9d"),
    re.compile(r"(?i)seed\s*[:=]\s*[\"']?[0-9a-f]{32,}"),
]

PATH_PATTERNS = [
    re.compile(r"(?:^|[\s`\"'(])/[A-Za-z0-9_]"),
    re.compile(r"(?:^|[\s`\"'(])[A-Za-z]:[\\/]"),
    re.compile(r"\.\.(?:[\\/]|$)"),
    re.compile(r"%2e%2e", re.I),
]

TEST_TOKEN = re.compile(r"`((?:fieldbook|nirnay):[A-Za-z0-9_./-]+\.rs::[A-Za-z0-9_]+)`")
SHA256 = re.compile(r"[0-9a-f]{64}\Z")


class Report:
    def __init__(self) -> None:
        self.pass_count = 0
        self.fail_count = 0
        self.skip_count = 0

    def ok(self, label: str, detail: str = "") -> None:
        self.pass_count += 1
        suffix = f" — {detail}" if detail else ""
        print(f"PASS {label}{suffix}")

    def bad(self, label: str, detail: str) -> None:
        self.fail_count += 1
        print(f"FAIL {label} — {detail}")

    def skip(self, label: str, detail: str) -> None:
        self.skip_count += 1
        print(f"SKIP {label} — {detail}")


def parse_index(text: str) -> list[tuple[str, str]]:
    entries: list[tuple[str, str]] = []
    for line in text.splitlines():
        if not line.strip().startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) < 2:
            continue
        name = cells[0].strip("` ")
        digest = cells[1].strip("` ").lower()
        if SHA256.fullmatch(digest):
            entries.append((name, digest))
    return entries


def check_digests(report: Report, text: str) -> None:
    entries = parse_index(text)
    if not entries:
        report.bad("vector index", "no vector digest rows were found")
        return
    listed = {name for name, _ in entries}
    for name, expected in entries:
        path = VECTOR_DIR / name
        if Path(name).name != name or not path.is_file():
            report.bad(f"vector {name}", "file is absent from the vector directory")
            continue
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual == expected:
            report.ok(f"vector {name}", actual)
        else:
            report.bad(f"vector {name}", f"index={expected} actual={actual}")
    for path in sorted(VECTOR_DIR.glob("*.json")):
        if path.name not in listed:
            report.bad(f"vector {path.name}", "JSON vector file is not listed in the index")


def check_index_literals(report: Report, text: str) -> None:
    secret_hits = sorted({match.group(0) for pattern in SECRET_PATTERNS for match in pattern.finditer(text)})
    if secret_hits:
        report.bad("index secret scan", "matched: " + ", ".join(secret_hits))
    else:
        report.ok("index secret scan", "no secret material matched")

    path_hits = sorted({match.group(0) for pattern in PATH_PATTERNS for match in pattern.finditer(text)})
    if path_hits:
        report.bad("index path scan", "matched: " + ", ".join(repr(hit) for hit in path_hits))
    else:
        report.ok("index path scan", "no rooted or upward path literal matched")


def check_vector_files_for_secrets(report: Report) -> None:
    hits: list[str] = []
    for path in sorted(VECTOR_DIR.glob("*.json")):
        text = path.read_text(encoding="utf-8")
        for pattern in SECRET_PATTERNS:
            for match in pattern.finditer(text):
                hits.append(f"{path.name}:{match.group(0)}")
    if hits:
        report.bad("vector file secret scan", "matched: " + ", ".join(sorted(set(hits))))
    else:
        report.ok("vector file secret scan", "no secret material matched")


def collect_test_tokens() -> list[str]:
    tokens: set[str] = set()
    for path in (INDEX, MATRIX):
        if path.is_file():
            tokens.update(TEST_TOKEN.findall(path.read_text(encoding="utf-8")))
    return sorted(tokens)


def check_test_tokens(report: Report) -> None:
    tokens = collect_test_tokens()
    if not tokens:
        report.bad("test tokens", "no producer or verifier test tokens were found")
        return
    skipped_repos: set[str] = set()
    for token in tokens:
        repo, remainder = token.split(":", 1)
        rel_path, test_name = remainder.split("::", 1)
        clone = ROOT / repo
        if not clone.is_dir():
            if repo not in skipped_repos:
                report.skip(f"clone {repo}", f"{clone} is absent; test-name checks skipped")
                skipped_repos.add(repo)
            continue
        head = subprocess.run(
            ["git", "-C", str(clone), "rev-parse", "HEAD"],
            capture_output=True,
            text=True,
            check=False,
        )
        actual_head = head.stdout.strip() if head.returncode == 0 else ""
        if actual_head != EXPECTED_HEADS[repo]:
            report.skip(
                f"test {token}",
                f"clone head {actual_head or 'unreadable'} is not the recorded head; check skipped",
            )
            continue
        source = clone / rel_path
        if not source.is_file():
            report.bad(f"test {token}", f"source file {rel_path} is absent at the recorded head")
            continue
        finder = re.compile(r"\bfn\s+" + re.escape(test_name) + r"\s*\(")
        if finder.search(source.read_text(encoding="utf-8")):
            report.ok(f"test {token}", "found at recorded head")
        else:
            report.bad(f"test {token}", f"fn {test_name} was not found in {rel_path}")


def main() -> int:
    report = Report()
    if not INDEX.is_file():
        report.bad("vector index", f"{INDEX} is absent")
        return 1
    text = INDEX.read_text(encoding="utf-8")
    check_digests(report, text)
    check_index_literals(report, text)
    check_vector_files_for_secrets(report)
    check_test_tokens(report)
    print(f"\nSummary: {report.pass_count} passed, {report.fail_count} failed, {report.skip_count} skipped")
    return 1 if report.fail_count else 0


if __name__ == "__main__":
    sys.exit(main())
