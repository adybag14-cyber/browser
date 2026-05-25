#!/usr/bin/env python3
"""Check drift between restore-synced helper files and saved-memory preflight expectations."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys
import textwrap
import unittest

RESTORE_LIST_RE = re.compile(r"declare -a HELPER_SURFACE_PATHS=\((.*?)\n\)", re.S)
PYTHON_LIST_RE = re.compile(
    r"REQUIRED_RESTORED_HELPER_FILES:\s*tuple\[tuple\[str, str\], \.\.\.\]\s*=\s*\((.*?)\n\)",
    re.S,
)
SHELL_PATH_RE = re.compile(r'"([^"]+)"')
PYTHON_TUPLE_RE = re.compile(r'\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)')


def parse_restore_paths(text: str) -> list[str]:
    match = RESTORE_LIST_RE.search(text)
    if match is None:
        raise ValueError("Could not find HELPER_SURFACE_PATHS in restore_saved_browser_snapshot.sh")
    return SHELL_PATH_RE.findall(match.group(1))


def parse_required_paths(text: str) -> list[str]:
    match = PYTHON_LIST_RE.search(text)
    if match is None:
        raise ValueError("Could not find REQUIRED_RESTORED_HELPER_FILES in check_issue3_saved_memory_inputs.py")
    return [path for path, _label in PYTHON_TUPLE_RE.findall(match.group(1))]


def build_report(restore_paths: list[str], required_paths: list[str]) -> dict[str, object]:
    restore_only = sorted(set(restore_paths) - set(required_paths))
    required_only = sorted(set(required_paths) - set(restore_paths))
    return {
        "ok": not restore_only and not required_only,
        "restore_count": len(restore_paths),
        "required_count": len(required_paths),
        "restore_only": restore_only,
        "required_only": required_only,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the restore helper's synced helper surface still matches "
            "the saved-memory preflight helper's restored-checkout expectations."
        )
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of text")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


class SurfaceAlignmentTests(unittest.TestCase):
    def test_parse_restore_paths(self) -> None:
        text = textwrap.dedent(
            '''\\
            declare -a HELPER_SURFACE_PATHS=(
                "docs/A.md"
                "scripts/B.py"
            )
            '''
        )
        self.assertEqual(parse_restore_paths(text), ["docs/A.md", "scripts/B.py"])

    def test_parse_required_paths(self) -> None:
        text = textwrap.dedent(
            '''\\
            REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
                ("docs/A.md", "a"),
                ("scripts/B.py", "b"),
            )
            '''
        )
        self.assertEqual(parse_required_paths(text), ["docs/A.md", "scripts/B.py"])

    def test_build_report_surfaces_bidirectional_drift(self) -> None:
        report = build_report(["docs/A.md", "scripts/B.py"], ["docs/A.md", "scripts/C.py"])
        self.assertFalse(report["ok"])
        self.assertEqual(report["restore_only"], ["scripts/B.py"])
        self.assertEqual(report["required_only"], ["scripts/C.py"])


def emit_text(report: dict[str, object], repo_root: Path) -> None:
    print(f"Repo root: {repo_root}")
    print(f"Restore helper entries: {report['restore_count']}")
    print(f"Saved-memory helper entries: {report['required_count']}")
    if report["ok"]:
        print("Restore helper surface alignment check passed.")
        return
    print("Restore helper surface alignment check failed.", file=sys.stderr)
    restore_only = report["restore_only"]
    required_only = report["required_only"]
    if restore_only:
        print("Missing from saved-memory helper expectations:", file=sys.stderr)
        for path in restore_only:
            print(f"  - {path}", file=sys.stderr)
    if required_only:
        print("Missing from restore helper sync surface:", file=sys.stderr)
        for path in required_only:
            print(f"  - {path}", file=sys.stderr)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SurfaceAlignmentTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    restore_script = repo_root / "scripts" / "linux" / "restore_saved_browser_snapshot.sh"
    saved_memory_helper = repo_root / "scripts" / "check_issue3_saved_memory_inputs.py"
    restore_paths = parse_restore_paths(restore_script.read_text(encoding="utf-8"))
    required_paths = parse_required_paths(saved_memory_helper.read_text(encoding="utf-8"))
    report = {
        "profile": "issue3-restored-helper-surface-alignment",
        "repo_root": str(repo_root),
        **build_report(restore_paths, required_paths),
    }
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report, repo_root)
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
