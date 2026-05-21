#!/usr/bin/env python3
"""Validate headed startup target diagnostics for attached-page browse routes.

This helper keeps the expected startup classification for key attached-page and
localhost launch shapes in one place. It can either print the current matrix or
check a captured startup log against one expected case.

Examples:
  python tmp-browser-smoke/attached-pages/verify_browse_startup_target_matrix.py
  python tmp-browser-smoke/attached-pages/verify_browse_startup_target_matrix.py --case dotted-bare-local-html
  python tmp-browser-smoke/attached-pages/verify_browse_startup_target_matrix.py --case dotted-bare-local-html --log browse.log
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

EXPECTED_CASES = (
    {
        "label": "bare-attached-html",
        "url": "attached-page.html",
        "target_scheme": "path",
        "target_scope": "local_path",
        "target_host": "(none)",
        "target_port": "(none)",
        "why": "Direct saved-page launches should stay on the local path route.",
    },
    {
        "label": "dotted-bare-local-html",
        "url": "report.v1.html",
        "target_scheme": "path",
        "target_scope": "local_path",
        "target_host": "(none)",
        "target_port": "(none)",
        "why": "Dotted bare local HTML names should not be mistaken for remote hosts.",
    },
    {
        "label": "dotted-bare-local-xhtml-fragment",
        "url": "report.v1.xhtml#focus-probe",
        "target_scheme": "path",
        "target_scope": "local_path",
        "target_host": "(none)",
        "target_port": "(none)",
        "why": "Fragment-bearing local XHTML launches should stay on the attached-page route.",
    },
    {
        "label": "windows-attached-path",
        "url": r"user_files\\attached-page.xhtml",
        "target_scheme": "path",
        "target_scope": "local_path",
        "target_host": "(none)",
        "target_port": "(none)",
        "why": "Windows-style relative attached-page paths should classify as local paths.",
    },
    {
        "label": "scheme-less-loopback",
        "url": "localhost:8123/attached-page.html?case=1",
        "target_scheme": "implicit_http",
        "target_scope": "loopback",
        "target_host": "localhost",
        "target_port": "8123",
        "why": "Loopback replay should stay on the implicit localhost route.",
    },
    {
        "label": "scheme-less-remote",
        "url": "example.com/attached-page.html",
        "target_scheme": "implicit_http",
        "target_scope": "remote",
        "target_host": "example.com",
        "target_port": "(default)",
        "why": "Real remote hosts should keep the implicit remote path.",
    },
)

FIELD_NAMES = ("target_scheme", "target_scope", "target_host", "target_port")
FIELD_PATTERNS = {
    key: (
        re.compile(rf"{key}=(?:\"([^\"]+)\"|(\S+))"),
        re.compile(rf"\.{key}\s*=\s*\"([^\"]+)\""),
        re.compile(rf"\.{key}\s*=\s*([^,\s]+)"),
    )
    for key in FIELD_NAMES
}


def find_case(case_label: str | None) -> dict[str, str] | None:
    if case_label is None:
        return None
    for case in EXPECTED_CASES:
        if case["label"] == case_label:
            return case
    raise KeyError(case_label)


def parse_fields(text: str) -> dict[str, str]:
    parsed: dict[str, str] = {}
    for key, patterns in FIELD_PATTERNS.items():
        for pattern in patterns:
            match = pattern.search(text)
            if not match:
                continue
            parsed[key] = next(group for group in match.groups() if group is not None)
            break
    return parsed


def print_matrix(case_label: str | None) -> int:
    selected = find_case(case_label)
    cases = (selected,) if selected else EXPECTED_CASES
    for case in cases:
        print(f"[{case['label']}] {case['url']}")
        print(f"  target_scheme: {case['target_scheme']}")
        print(f"  target_scope:  {case['target_scope']}")
        print(f"  target_host:   {case['target_host']}")
        print(f"  target_port:   {case['target_port']}")
        print(f"  why:           {case['why']}")
        print()
    return 0


def validate_log(log_path: Path, case_label: str) -> int:
    case = find_case(case_label)
    assert case is not None
    parsed = parse_fields(log_path.read_text(encoding="utf-8"))

    missing = [name for name in FIELD_NAMES if name not in parsed]
    if missing:
        print(
            f"missing startup fields in {log_path}: {', '.join(missing)}",
            file=sys.stderr,
        )
        return 2

    mismatches = []
    for name in FIELD_NAMES:
        actual = parsed[name]
        expected = case[name]
        if actual != expected:
            mismatches.append((name, expected, actual))

    if mismatches:
        print(f"startup target mismatch for case '{case_label}' ({case['url']}):", file=sys.stderr)
        for name, expected, actual in mismatches:
            print(f"  {name}: expected {expected!r}, got {actual!r}", file=sys.stderr)
        return 1

    print(f"startup target matched case '{case_label}' ({case['url']})")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--case",
        choices=[case["label"] for case in EXPECTED_CASES],
        help="Only print or validate one named expectation case.",
    )
    parser.add_argument(
        "--log",
        type=Path,
        help="Path to a captured startup log to validate against the selected case.",
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()
    if args.log is None:
        return print_matrix(args.case)
    if args.case is None:
        print("--log requires --case so one expected route can be checked", file=sys.stderr)
        return 2
    return validate_log(args.log, args.case)


if __name__ == "__main__":
    raise SystemExit(main())
