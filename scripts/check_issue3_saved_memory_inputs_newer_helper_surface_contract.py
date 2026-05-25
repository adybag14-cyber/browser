#!/usr/bin/env python3

"""Fail fast when saved-memory preflight omits newer issue #11 helper-surface files."""

from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path
import tempfile
import textwrap
import unittest


EXPECTED_HELPER_SURFACE_PATHS: tuple[str, ...] = (
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
    "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
    "scripts/linux/show_issue3_progress_tracker_route.sh",
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that scripts/check_issue3_saved_memory_inputs.py requires the "
            "newer issue #11 progress-tracker helper surface."
        )
    )
    parser.add_argument(
        "--target-file",
        default="scripts/check_issue3_saved_memory_inputs.py",
        help="Path to the saved-memory helper to inspect",
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


def extract_required_paths(target_file: Path) -> tuple[str, ...]:
    tree = ast.parse(target_file.read_text(encoding="utf-8"), filename=str(target_file))
    for node in tree.body:
        if not isinstance(node, ast.Assign):
            continue
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id == "REQUIRED_RESTORED_HELPER_FILES":
                value = ast.literal_eval(node.value)
                return tuple(path for path, _label in value)
    raise ValueError(
        "Could not find REQUIRED_RESTORED_HELPER_FILES in "
        f"{target_file}"
    )


def collect_result(target_file: Path) -> dict[str, object]:
    required_paths = extract_required_paths(target_file)
    missing_paths = [
        path for path in EXPECTED_HELPER_SURFACE_PATHS if path not in required_paths
    ]
    return {
        "ok": not missing_paths,
        "target_file": str(target_file),
        "required_path_count": len(required_paths),
        "expected_paths": list(EXPECTED_HELPER_SURFACE_PATHS),
        "missing_expected_paths": missing_paths,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Target file: {result['target_file']}")
    print(f"Required helper-surface paths: {result['required_path_count']}")
    if result["ok"]:
        print("Saved-memory helper surface contract passed.")
        return

    print("Saved-memory helper surface contract failed.")
    print("Missing newer issue #11 helper-surface paths:")
    for path in result["missing_expected_paths"]:
        print(f"  - {path}")
    print(
        "Suggested next step: add the missing progress-tracker note and route "
        "helpers to REQUIRED_RESTORED_HELPER_FILES."
    )


class SavedMemoryInputsNewerHelperSurfaceContractTests(unittest.TestCase):
    def test_collect_result_passes_when_expected_paths_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            target_file = Path(tmpdir) / "check_issue3_saved_memory_inputs.py"
            target_file.write_text(
                textwrap.dedent(
                    """
                    REQUIRED_RESTORED_HELPER_FILES = (
                        ("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "progress tracker"),
                        ("scripts/linux/check_issue3_progress_tracker_route_surface.sh", "surface"),
                        ("scripts/linux/show_issue3_progress_tracker_route.sh", "route"),
                    )
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )

            result = collect_result(target_file)

            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_expected_paths"], [])

    def test_collect_result_reports_missing_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            target_file = Path(tmpdir) / "check_issue3_saved_memory_inputs.py"
            target_file.write_text(
                textwrap.dedent(
                    """
                    REQUIRED_RESTORED_HELPER_FILES = (
                        ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime"),
                    )
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )

            result = collect_result(target_file)

            self.assertFalse(result["ok"])
            self.assertEqual(
                result["missing_expected_paths"],
                list(EXPECTED_HELPER_SURFACE_PATHS),
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedMemoryInputsNewerHelperSurfaceContractTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    target_file = Path(args.target_file).resolve()
    result = collect_result(target_file)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
