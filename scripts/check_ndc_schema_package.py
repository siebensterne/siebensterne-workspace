#!/usr/bin/env python3
"""Verify the canonical NDC v2 Profile 1 schema package.

<!-- SPDX-License-Identifier: Apache-2.0 -->

Workspace evidence tooling only. This script is not a producer, a verifier, a shared
validator, a serializer, a connector or a runtime component. It verifies the digest index,
JSON parseability, strict object structure of every schema, absence of secret or
external-observation tokens in vector files, and prints one reproducible package digest.
"""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = ROOT / "engineering" / "conformance" / "ndc-v2-schema-profile-1"
INDEX = PACKAGE / "VECTORS.md"

DOMAIN_PREFIX = "NDC-V2-PROFILE-1-SCHEMA-PACKAGE-DIGEST-V1"
SHA256_RE = re.compile(r"[0-9a-f]{64}\Z")

SECRET_PATTERNS = [
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
    re.compile(r"\b(?:private|secret)[_\s-]?(?:key|seed)\b", re.I),
    re.compile(r"\bseed\s*[:=]\s*[\"']?[0-9a-f]{32,}", re.I),
    re.compile(
        r"\b9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60\b", re.I
    ),
]

EXTERNAL_OBSERVATION_PATTERNS = [
    re.compile(
        r"\b(?:price|prices|quote|quotes|traded?|trades|tick|ticks|ohlc|orderbook|"
        r"order_book|bid|ask|spread|isin|nse|bse|inr|rupee|equity|futures|options?|"
        r"spot|forex)\b",
        re.I,
    ),
    re.compile(r"\bmarket[\s_-]?data\b", re.I),
    re.compile(r"\bprovider[\s_-]?contact\b", re.I),
]

SCHEMA_CONTAINER_KEYS = {
    "properties": ("$defs",),
    "$defs": (),
    "definitions": (),
}
SCHEMA_SINGLE_KEYS = ("items", "not", "contains", "if", "then", "else", "additionalProperties")
SCHEMA_LIST_KEYS = ("oneOf", "anyOf", "allOf", "prefixItems")


class Report:
    def __init__(self) -> None:
        self.passed = 0
        self.failed = 0

    def ok(self, label: str, detail: str = "") -> None:
        self.passed += 1
        suffix = f" — {detail}" if detail else ""
        print(f"PASS {label}{suffix}")

    def bad(self, label: str, detail: str) -> None:
        self.failed += 1
        print(f"FAIL {label} — {detail}")


def parse_index(text: str) -> list[tuple[str, str]]:
    entries: list[tuple[str, str]] = []
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue
        cells = [cell.strip() for cell in stripped.strip("|").split("|")]
        if len(cells) < 2:
            continue
        name = cells[0].strip("` ")
        digest = cells[1].strip("` ").lower()
        if SHA256_RE.fullmatch(digest):
            entries.append((name, digest))
    return entries


def check_index(report: Report, entries: list[tuple[str, str]]) -> dict[str, str]:
    seen: dict[str, str] = {}
    for rel, expected in entries:
        if not rel or Path(rel).is_absolute() or ".." in Path(rel).parts:
            report.bad(f"index path {rel!r}", "path is empty, rooted or upward")
            continue
        if rel in seen:
            report.bad(f"index path {rel}", "duplicate entry")
            continue
        seen[rel] = expected
        path = PACKAGE / rel
        if not path.is_file():
            report.bad(f"indexed file {rel}", "file is absent")
            continue
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual == expected:
            report.ok(f"digest {rel}", actual)
        else:
            report.bad(f"digest {rel}", f"index={expected} actual={actual}")

    all_files = {
        str(p.relative_to(PACKAGE))
        for p in PACKAGE.rglob("*")
        if p.is_file() and p.name != "VECTORS.md"
    }
    for rel in sorted(all_files - set(seen)):
        report.bad(f"unindexed file {rel}", "package file has no SHA-256 row in VECTORS.md")
    if not entries:
        report.bad("index", "no digest rows were found")
    return seen


def no_duplicate_members(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON member {key!r}")
        result[key] = value
    return result


def check_json(report: Report, entries: dict[str, str]) -> None:
    for rel in sorted(entries):
        if not rel.endswith(".json"):
            continue
        path = PACKAGE / rel
        if not path.is_file():
            continue
        try:
            json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=no_duplicate_members)
        except (ValueError, UnicodeDecodeError) as exc:
            report.bad(f"json parse {rel}", str(exc))
        else:
            report.ok(f"json parse {rel}", "valid, no duplicate members")


def check_schema_node(node: Any, where: str, report: Report) -> None:
    if isinstance(node, list):
        for index, item in enumerate(node):
            check_schema_node(item, f"{where}[{index}]", report)
        return
    if not isinstance(node, dict):
        return

    is_object_level = node.get("type") == "object" or "properties" in node
    if is_object_level:
        if node.get("additionalProperties") is not False:
            report.bad(f"strict object {where}", "additionalProperties is not false")
        required = node.get("required")
        if not isinstance(required, list) or not all(
            isinstance(name, str) and name for name in required
        ):
            report.bad(f"strict object {where}", "required is not an explicit array of names")
        elif len(set(required)) != len(required):
            report.bad(f"strict object {where}", "required contains a duplicate name")
        elif "properties" in node:
            properties = node["properties"]
            if not isinstance(properties, dict):
                report.bad(f"strict object {where}", "properties is not an object")
            else:
                if not required:
                    report.bad(f"strict object {where}", "required array is empty")
                for name in required:
                    if name not in properties:
                        report.bad(f"strict object {where}", f"required name {name!r} is undeclared")

    for key, value in node.items():
        if key in SCHEMA_CONTAINER_KEYS:
            if isinstance(value, dict):
                for name, child in value.items():
                    check_schema_node(child, f"{where}/{key}/{name}", report)
        elif key in SCHEMA_LIST_KEYS:
            check_schema_node(value, f"{where}/{key}", report)
        elif key in SCHEMA_SINGLE_KEYS:
            check_schema_node(value, f"{where}/{key}", report)


def check_schemas(report: Report, entries: dict[str, str]) -> None:
    schema_files = [rel for rel in entries if rel.endswith(".schema.json")]
    if not schema_files:
        report.bad("schemas", "no schema files are indexed")
        return
    for rel in sorted(schema_files):
        path = PACKAGE / rel
        if not path.is_file():
            continue
        try:
            document = json.loads(path.read_text(encoding="utf-8"))
        except ValueError:
            continue
        if document.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
            report.bad(f"schema dialect {rel}", "draft 2020-12 $schema is missing or wrong")
        if "$defs" not in document or "$ref" not in document:
            report.bad(f"schema root {rel}", "$defs or $ref is missing")
        check_schema_node(document, rel, report)
        report.ok(f"schema structure {rel}", "strict object levels and required arrays present")


def check_vector_patterns(report: Report, entries: dict[str, str]) -> None:
    vector_files = [rel for rel in entries if rel.startswith("vectors/") and rel.endswith(".json")]
    if not vector_files:
        report.bad("vectors", "no vector files are indexed")
        return
    hits: list[str] = []
    for rel in sorted(vector_files):
        path = PACKAGE / rel
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for pattern in SECRET_PATTERNS + EXTERNAL_OBSERVATION_PATTERNS:
            for match in pattern.finditer(text):
                hits.append(f"{rel}:{match.group(0)}")
    if hits:
        report.bad("vector pattern scan", "matched: " + ", ".join(sorted(set(hits))))
    else:
        report.ok("vector pattern scan", f"{len(vector_files)} vector files, no forbidden token")


def print_package_digest(entries: dict[str, str]) -> None:
    lines = [DOMAIN_PREFIX]
    for rel in sorted(entries):
        lines.append(f"{rel} {entries[rel]}")
    payload = "\n".join(lines) + "\n"
    digest = hashlib.sha256(payload.encode("utf-8")).hexdigest()
    print(f"PACKAGE-FILE-COUNT {len(entries)}")
    print(f"SCHEMA-PACKAGE-DIGEST {digest}")


def main() -> int:
    report = Report()
    if not INDEX.is_file():
        report.bad("index", f"{INDEX} is absent")
        print(f"Summary: {report.passed} passed, {report.failed} failed")
        return 1
    entries = check_index(report, parse_index(INDEX.read_text(encoding="utf-8")))
    check_json(report, entries)
    check_schemas(report, entries)
    check_vector_patterns(report, entries)
    print(f"Summary: {report.passed} passed, {report.failed} failed")
    print_package_digest(entries)
    return 1 if report.failed else 0


if __name__ == "__main__":
    sys.exit(main())
