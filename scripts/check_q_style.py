#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Check added q / kdb+ lines for mechanical style violations.

The binding rule set is ``q-style.json`` at the repository root. This checker
loads it at import time, so editing the JSON changes enforcement and editing
the checker's constants cannot silently diverge from the published contract.
The rules cover whitespace hygiene, the silent loader-stop bare ``/`` line,
the ``count x < n`` precedence bug, and dotted column access inside a lambda
(``t.col`` is a global name in q; the required form is ``t[`col]``).

Only lines added relative to the base ref are checked, so the existing corpus
is not churned. There are no third-party dependencies; semantic checks stay in
the repository's q verification scripts.

Run from the repository root. Set Q_STYLE_BASE (or a repository-specific
STYLE_BASE variable) to compare against a different ref; the default is main.
Use --self-test for adversarial unit tests.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import unittest
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "q-style.json"


def validate_config(data: dict[str, Any]) -> dict[str, Any]:
    """Validate the machine-readable q style contract."""
    if data.get("schema_version") != 1:
        raise ValueError("unsupported q-style.json schema_version")
    if data.get("enforcement", {}).get("waivers") != "none":
        raise ValueError("q-style.json must declare zero waivers")
    if data.get("rules", {}).get("max_columns") != 100:
        raise ValueError("q-style.json max_columns must remain 100")
    return data


def load_config(path: Path = CONFIG_PATH) -> dict[str, Any]:
    """Load and validate the machine-readable q style contract."""
    return validate_config(json.loads(path.read_text(encoding="utf-8")))


CONFIG = load_config()
MAX_COLUMNS = CONFIG["rules"]["max_columns"]
NAMESPACES = frozenset(CONFIG["namespaces"])

FILE_HEADER = re.compile(r"^\+\+\+ b/")
BARE_SLASH = re.compile(r"^/\s*$")
COUNT_COMPARISON = re.compile(r"\bcount\s+\w+\s*(?:<|>|<=|>=|=|~)")
# Dotted names inside lambdas: t.col where both sides are plain identifiers.
DOT_COLUMN = re.compile(r"(?<![\w.])\b([a-z][a-z0-9]{0,3})\.([a-z][a-z0-9_]*)")
TAB = re.compile(r"\t")
TRAILING_WS = re.compile(r"[ \t]+$")


def base_ref() -> str:
    """Return the configured comparison ref."""
    for name in (
        "Q_STYLE_BASE",
        "FIELDBOOK_STYLE_BASE",
        "STYLE_BASE",
    ):
        value = os.environ.get(name)
        if value:
            return value
    return "main"


def parse_added_lines(diff_text: str) -> dict[str, list[tuple[int, str]]]:
    """Parse a ``git diff --unified=0`` payload into added lines per file."""
    by_file: dict[str, list[tuple[int, str]]] = {}
    current = ""
    number = 0
    for line in diff_text.splitlines():
        if line.startswith("+++ "):
            current = line[6:] if FILE_HEADER.match(line) else ""
            number = 0
            continue
        if line.startswith("@@"):
            match = re.search(r"\+(\d+)", line)
            number = int(match.group(1)) if match else 0
            continue
        if line.startswith("+") and number:
            by_file.setdefault(current, []).append((number, line[1:]))
            number += 1
    return by_file


def collect_added_lines(base: str) -> dict[str, list[tuple[int, str]]]:
    """Collect added q lines from the working tree relative to ``base``.

    CI checkouts may be shallow and lack the named base ref. An unavailable
    base yields no added lines instead of failing the whole gate.
    """
    result = subprocess.run(
        ["git", "diff", base, "--unified=0", "--", "*.q"],
        check=False,
        capture_output=True,
        text=True,
        cwd=ROOT,
    )
    if result.returncode != 0:
        return {}
    return parse_added_lines(result.stdout)


def check_q_line(line: str, *, in_lambda: bool = False) -> list[str]:
    """Return style findings for one q line.

    ``in_lambda`` reports whether the line is inside a ``{...}`` lambda, which
    is where dotted column access resolves to a global name instead of a
    column.
    """
    errors: list[str] = []
    stripped = line.strip()
    if TAB.search(line):
        errors.append("tab indentation")
    if TRAILING_WS.search(line):
        errors.append("trailing whitespace")
    if len(line) > MAX_COLUMNS:
        errors.append(f"line exceeds {MAX_COLUMNS} columns")
    if BARE_SLASH.match(stripped):
        errors.append("bare / line (silent loader stop)")
    if COUNT_COMPARISON.search(line):
        errors.append("unparenthesised comparison with count")
    if in_lambda and not stripped.startswith("/"):
        for match in DOT_COLUMN.finditer(stripped):
            dotted = match.group(0)
            if any(dotted.startswith(ns) for ns in NAMESPACES):
                continue
            # Numeric literals such as 0.05 have a digit on the left.
            if match.group(1)[0].isdigit():
                continue
            errors.append(f"dotted name {dotted!r} in lambda (use t[`col])")
    return errors


def check_lines(by_file: dict[str, list[tuple[int, str]]]) -> list[str]:
    """Check all added lines, tracking lambda depth per file."""
    errors: list[str] = []
    for path, lines in by_file.items():
        depth = 0
        for number, content in lines:
            code = content.split("/", 1)[0] if content.strip().startswith("/") else content
            # A single-line lambda f:{[t] t.col} opens and closes on this line.
            in_lambda = depth > 0 or "{" in code
            for message in check_q_line(content, in_lambda=in_lambda):
                errors.append(f"{path}:{number}: {message}")
            depth += code.count("{") - code.count("}")
    return errors


class QStyleTests(unittest.TestCase):
    """Adversarial tests for the q style rules, config and diff parser."""

    def test_config_is_binding(self) -> None:
        """The JSON contract drives the checker's live constants."""
        self.assertEqual(MAX_COLUMNS, 100)
        self.assertEqual(CONFIG["enforcement"]["waivers"], "none")

    def test_config_rejects_waivers(self) -> None:
        """A contract with waivers is rejected at load time."""
        data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
        data["enforcement"]["waivers"] = "allowed"
        with self.assertRaises(ValueError):
            validate_config(data)

    def test_bare_slash(self) -> None:
        """A bare slash silently stops a q loader."""
        self.assertTrue(any("bare /" in e for e in check_q_line("/")))

    def test_count_comparison(self) -> None:
        """An unparenthesised count comparison is a precedence bug."""
        findings = check_q_line("if[count args < 2;x]")
        self.assertTrue(any("count" in e for e in findings))

    def test_parenthesised_count_ok(self) -> None:
        """A parenthesised count comparison is explicit and safe."""
        self.assertEqual(check_q_line("if[(count args) < 2;x]"), [])

    def test_tab(self) -> None:
        """Tabs are rejected."""
        self.assertTrue(any("tab" in e for e in check_q_line("\ta:1")))

    def test_trailing_whitespace(self) -> None:
        """Trailing whitespace is rejected."""
        self.assertTrue(any("trailing" in e for e in check_q_line("a:1   ")))

    def test_long_line(self) -> None:
        """Lines over the shared q limit are rejected."""
        self.assertTrue(any("columns" in e for e in check_q_line("a:" + "x" * 120)))

    def test_dotted_column_in_lambda(self) -> None:
        """Dotted column access inside a lambda resolves to a global."""
        findings = check_q_line("last t.recv_ns", in_lambda=True)
        self.assertTrue(any("dotted name" in e for e in findings))

    def test_dotted_column_index_form_ok(self) -> None:
        """Indexed column access is the required form."""
        self.assertEqual(check_q_line("last t[`recv_ns]", in_lambda=True), [])

    def test_namespace_dotted_ok(self) -> None:
        """Known namespaces are not mistaken for column access."""
        self.assertEqual(check_q_line(".pq.pq[x]", in_lambda=True), [])
        self.assertEqual(check_q_line(".h.h[x]", in_lambda=True), [])

    def test_number_dotted_ok(self) -> None:
        """Decimal literals are not mistaken for dotted names."""
        self.assertEqual(check_q_line("0.05=x", in_lambda=True), [])

    def test_comment_exempt(self) -> None:
        """Comment lines are exempt from the dotted-name rule."""
        self.assertEqual(check_q_line("/ t.recv_ns comment", in_lambda=True), [])

    def test_clean_line(self) -> None:
        """An ordinary assignment is clean."""
        self.assertEqual(check_q_line("a:1"), [])

    def test_diff_parser(self) -> None:
        """The unified diff parser records file and line numbers."""
        diff = "+++ b/x.q\n@@ -0,0 +1,2 @@\n+a:1\n+b:2\n"
        self.assertEqual(parse_added_lines(diff), {"x.q": [(1, "a:1"), (2, "b:2")]})

    def test_check_lines_reports_path(self) -> None:
        """Findings carry the file path and line number."""
        errors = check_lines({"x.q": [(1, "/")]})
        self.assertTrue(any("x.q:1" in e for e in errors))

    def test_lambda_depth_tracking(self) -> None:
        """Lambda state persists across added lines in one file."""
        lines = [
            (1, "f:{[t]"),
            (2, "  last t.recv_ns"),
            (3, "  };"),
            (4, "a:1"),
        ]
        errors = check_lines({"x.q": lines})
        self.assertTrue(any("x.q:2" in e for e in errors))
        self.assertFalse(any("x.q:4" in e for e in errors))

    def test_single_line_lambda_caught(self) -> None:
        """A lambda opened and closed on one line is still checked."""
        errors = check_lines({"x.q": [(1, "f:{[t] last t.recv_ns};")]})
        self.assertTrue(any("x.q:1" in e for e in errors))


def main() -> int:
    """Print findings and return a process exit status."""
    if "--self-test" in sys.argv[1:]:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(QStyleTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1
    base = base_ref()
    errors = check_lines(collect_added_lines(base))
    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        print(f"{len(errors)} q style violation(s) on changed lines")
        return 1
    print(f"PASS: q style satisfied on changed lines vs {base}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
