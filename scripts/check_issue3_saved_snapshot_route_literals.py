#!/usr/bin/env python3

"""Check literal path contracts for the issue #3 saved-snapshot helper chain."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


EXPECTATIONS: tuple[tuple[str, str, str], ...] = (
    (
        "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "scripts/linux/restore_saved_browser_snapshot.sh|--sync-helper-surface|",
        "saved-snapshot surface checker keeps the lowercase restore-helper path literal",
    ),
    (
        "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Sync helper surface:|",
        "saved-snapshot surface checker keeps the lowercase route-printer path literal",
    ),
    (
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "saved-snapshot route printer still points back to the dedicated surface checker",
    ),
    (
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "scripts/linux/restore_saved_browser_snapshot.sh",
        "saved-snapshot route printer still points at the lowercase restore-helper path",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check issue #3 saved-browser-snapshot helpers for literal path drift "
            "that would create false-negative route-surface failures."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def collect_results(repo_root: Path) -> dict[str, object]:
    checks: list[dict[str, object]] = []
    for relative_path, snippet, purpose in EXPECTATIONS:
        path = repo_root / relative_path
        exists = path.is_file()
        snippet_present = exists and snippet in path.read_text(encoding="utf-8")
        checks.append(
            {
                "path": relative_path,
                "snippet": snippet,
                "purpose": purpose,
                "file_exists": exists,
                "snippet_present": snippet_present,
            }
        )
    ok = all(item["file_exists"] and item["snippet_present"] for item in checks)
    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "checks": checks,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print("Literal path checks:")
    for item in result["checks"]:
        if item["file_exists"] and item["snippet_present"]:
            status = "PASS"
        elif not item["file_exists"]:
            status = "FAIL"
        else:
            status = "FAIL"
        print(f"  [{status}] {item['path']}")
        print(f"         {item['purpose']}")
    if result["ok"]:
        print("\nIssue #3 saved-snapshot literal contract check passed.")
    else:
        print("\nIssue #3 saved-snapshot literal contract check failed.", file=sys.stderr)


class LiteralContractTests(unittest.TestCase):
    def test_passes_when_expected_literals_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            for relative_path, snippet, _purpose in EXPECTATIONS:
                path = root / relative_path
                path.parent.mkdir(parents=True, exist_ok=True)
                text = path.read_text(encoding="utf-8") if path.exists() else ""
                if snippet not in text:
                    text += snippet + "\n"
                path.write_text(text, encoding="utf-8")

            result = collect_results(root)
            self.assertTrue(result["ok"])

    def test_fails_on_uppercase_browser_drift(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            surface = root / "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"
            route = root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
            surface.parent.mkdir(parents=True, exist_ok=True)
            route.parent.mkdir(parents=True, exist_ok=True)
            surface.write_text(
                "scripts/linux/restore_saved_BROWSER_snapshot.sh|--sync-helper-surface|\n"
                "scripts/linux/show_issue3_saved_BROWSER_snapshot_route.sh|Sync helper surface:|\n",
                encoding="utf-8",
            )
            route.write_text(
                "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh\n"
                "scripts/linux/restore_saved_browser_snapshot.sh\n",
                encoding="utf-8",
            )

            result = collect_results(root)
            self.assertFalse(result["ok"])
            failing = [item for item in result["checks"] if not item["snippet_present"]]
            self.assertEqual(len(failing), 2)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(LiteralContractTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(json.dumps({"profile": "issue3-saved-snapshot-route-literals", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
