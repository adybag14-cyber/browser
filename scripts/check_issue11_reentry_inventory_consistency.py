#!/usr/bin/env python3

"""Check whether issue #11 re-entry helpers agree on the newer helper surface.

This helper is intentionally narrow. It lets Linux/WSL headed-mode recovery
runs answer whether the reusable helper inventories already require the newer
issue #11 tracker surface and matching-Zig rerun helper, or whether the branch
still carries stale helper-surface contracts.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


EXPECTED_PATHS: tuple[str, ...] = (
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
    "scripts/check_issue3_helper_surface_source.py",
    "scripts/check_issue11_progress_tracker_surface.py",
    "scripts/show_issue11_matching_zig_readiness_command.py",
)

TARGET_FILES: tuple[str, ...] = (
    "scripts/check_issue3_saved_memory_inputs.py",
    "scripts/check_issue3_restored_checkout.py",
    "scripts/check_issue3_helper_surface_source.py",
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the reusable issue #3 or issue #11 Linux/WSL helper "
            "inventories include the newer issue #11 surface entries."
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
    file_results: list[dict[str, object]] = []
    missing_by_file: dict[str, list[str]] = {}

    for relative_path in TARGET_FILES:
        target = repo_root / relative_path
        exists = target.is_file()
        missing_paths: list[str] = []

        if exists:
            text = target.read_text(encoding="utf-8")
            for expected_path in EXPECTED_PATHS:
                if expected_path not in text:
                    missing_paths.append(expected_path)
        else:
            missing_paths = list(EXPECTED_PATHS)

        if missing_paths:
            missing_by_file[relative_path] = missing_paths

        file_results.append(
            {
                "path": relative_path,
                "exists": exists,
                "missing_expected_paths": missing_paths,
            }
        )

    return {
        "ok": not missing_by_file,
        "repo_root": str(repo_root),
        "expected_path_count": len(EXPECTED_PATHS),
        "target_file_count": len(TARGET_FILES),
        "expected_paths": list(EXPECTED_PATHS),
        "targets": file_results,
        "missing_by_file": missing_by_file,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Expected issue #11 surface paths: {result['expected_path_count']}")
    print(f"Target helper inventories: {result['target_file_count']}")
    print("Inventory status:")

    for entry in result["targets"]:
        if not entry["exists"]:
            status = "FAIL"
        elif entry["missing_expected_paths"]:
            status = "FAIL"
        else:
            status = "PASS"
        print(f"  [{status}] {entry['path']}")
        for missing_path in entry["missing_expected_paths"]:
            print(f"         missing: {missing_path}")

    if result["ok"]:
        print("\nIssue #11 helper inventory consistency check passed.")
        return

    print("\nIssue #11 helper inventory consistency check failed.", file=sys.stderr)
    print(
        "Suggested next step: update the listed helper inventories so restored "
        "checkouts and helper-surface sync flows require the current issue #11 "
        "progress-tracker and matching-Zig helper set.",
        file=sys.stderr,
    )


class Issue11InventoryConsistencyTests(unittest.TestCase):
    def test_passes_when_all_expected_paths_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()

            for relative_path in TARGET_FILES:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                body = "\n".join(EXPECTED_PATHS)
                target.write_text(body, encoding="utf-8")

            result = collect_results(repo_root)

            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_by_file"], {})

    def test_flags_missing_expected_path(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()

            for index, relative_path in enumerate(TARGET_FILES):
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                body_lines = list(EXPECTED_PATHS)
                if index == 1:
                    body_lines.remove("scripts/check_issue11_progress_tracker_surface.py")
                target.write_text("\n".join(body_lines), encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/check_issue3_restored_checkout.py",
                result["missing_by_file"],
            )
            self.assertIn(
                "scripts/check_issue11_progress_tracker_surface.py",
                result["missing_by_file"]["scripts/check_issue3_restored_checkout.py"],
            )

    def test_flags_missing_target_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()

            for relative_path in TARGET_FILES[1:]:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("\n".join(EXPECTED_PATHS), encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/check_issue3_saved_memory_inputs.py",
                result["missing_by_file"],
            )
            self.assertEqual(
                result["missing_by_file"]["scripts/check_issue3_saved_memory_inputs.py"],
                list(EXPECTED_PATHS),
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            Issue11InventoryConsistencyTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
