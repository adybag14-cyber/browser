#!/usr/bin/env python3

"""Check alignment between saved-memory and restored-checkout helper surfaces."""

from __future__ import annotations

import argparse
import ast
import json
import pathlib
import re
import tempfile
import textwrap
import unittest


SAVED_MEMORY_PATTERN = re.compile(
    r"REQUIRED_RESTORED_HELPER_FILES:\s*tuple\[tuple\[str, str\], \.\.\.\]\s*=\s*\(",
    re.S,
)
RESTORED_CHECKOUT_PATTERN = re.compile(
    r"HELPER_SURFACE_PATHS:\s*tuple\[tuple\[str, str\], \.\.\.\]\s*=\s*\(",
    re.S,
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that saved-memory and restored-checkout issue #3 helper "
            "surfaces still require the same branch paths."
        )
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of plain text")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


def extract_tuple_entries(text: str, pattern: re.Pattern[str], label: str) -> list[str]:
    match = pattern.search(text)
    if match is None:
        raise ValueError(f"Could not find {label} in source text")

    start = text.find("(", match.start())
    depth = 0
    end = -1
    for index in range(start, len(text)):
        char = text[index]
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                end = index + 1
                break
    if end == -1:
        raise ValueError(f"Could not parse tuple body for {label}")

    tuple_value = ast.literal_eval(text[start:end])
    return [path for path, _desc in tuple_value]


def build_report(repo_root: pathlib.Path) -> dict[str, object]:
    saved_memory_path = repo_root / "scripts/check_issue3_saved_memory_inputs.py"
    restored_checkout_path = repo_root / "scripts/check_issue3_restored_checkout.py"

    missing_sources: list[str] = []
    if not saved_memory_path.is_file():
        missing_sources.append(str(saved_memory_path))
    if not restored_checkout_path.is_file():
        missing_sources.append(str(restored_checkout_path))
    if missing_sources:
        return {
            "status": "failed",
            "repo_root": str(repo_root),
            "missing_sources": missing_sources,
            "saved_memory_only": [],
            "restored_checkout_only": [],
            "shared_path_count": 0,
            "failures": ["missing alignment source files"],
        }

    saved_memory_paths = extract_tuple_entries(
        saved_memory_path.read_text(encoding="utf-8"),
        SAVED_MEMORY_PATTERN,
        "REQUIRED_RESTORED_HELPER_FILES",
    )
    restored_checkout_paths = extract_tuple_entries(
        restored_checkout_path.read_text(encoding="utf-8"),
        RESTORED_CHECKOUT_PATTERN,
        "HELPER_SURFACE_PATHS",
    )

    saved_memory_only = sorted(set(saved_memory_paths) - set(restored_checkout_paths))
    restored_checkout_only = sorted(set(restored_checkout_paths) - set(saved_memory_paths))
    failures: list[str] = []
    if saved_memory_only:
        failures.append("saved-memory helper requires paths missing from restored-checkout helper surface")
    if restored_checkout_only:
        failures.append("restored-checkout helper requires paths missing from saved-memory helper surface")

    return {
        "status": "failed" if failures else "passed",
        "repo_root": str(repo_root),
        "missing_sources": [],
        "saved_memory_only": saved_memory_only,
        "restored_checkout_only": restored_checkout_only,
        "shared_path_count": len(set(saved_memory_paths) & set(restored_checkout_paths)),
        "failures": failures,
    }


class SavedMemoryHelperSurfaceAlignmentTests(unittest.TestCase):
    def test_extract_tuple_entries_handles_annotated_python_tuple(self) -> None:
        text = textwrap.dedent(
            """
            REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
                ("docs/A.md", "A"),
                ("scripts/B.py", "B"),
            )
            """
        )
        self.assertEqual(
            extract_tuple_entries(text, SAVED_MEMORY_PATTERN, "saved-memory"),
            ["docs/A.md", "scripts/B.py"],
        )

    def test_build_report_detects_bidirectional_drift(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = pathlib.Path(tmpdir)
            scripts_root = repo_root / "scripts"
            scripts_root.mkdir(parents=True, exist_ok=True)
            (scripts_root / "check_issue3_saved_memory_inputs.py").write_text(
                textwrap.dedent(
                    """
                    REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
                        ("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "tracker"),
                        ("scripts/linux/show_issue3_saved_memory_inputs_route.sh", "saved-memory route"),
                    )
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )
            (scripts_root / "check_issue3_restored_checkout.py").write_text(
                textwrap.dedent(
                    """
                    HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
                        ("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "tracker"),
                        ("scripts/linux/show_issue3_windows_runtime_handoff_route.sh", "handoff route"),
                    )
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )

            report = build_report(repo_root)

            self.assertEqual(report["status"], "failed")
            self.assertEqual(
                report["saved_memory_only"],
                ["scripts/linux/show_issue3_saved_memory_inputs_route.sh"],
            )
            self.assertEqual(
                report["restored_checkout_only"],
                ["scripts/linux/show_issue3_windows_runtime_handoff_route.sh"],
            )

    def test_build_report_passes_when_helper_surfaces_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = pathlib.Path(tmpdir)
            scripts_root = repo_root / "scripts"
            scripts_root.mkdir(parents=True, exist_ok=True)
            shared_text = textwrap.dedent(
                """
                (
                    ("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "tracker"),
                    ("scripts/linux/show_issue3_saved_memory_inputs_route.sh", "saved-memory route"),
                )
                """
            ).strip()
            (scripts_root / "check_issue3_saved_memory_inputs.py").write_text(
                "REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = "
                + shared_text
                + "\n",
                encoding="utf-8",
            )
            (scripts_root / "check_issue3_restored_checkout.py").write_text(
                "HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = "
                + shared_text
                + "\n",
                encoding="utf-8",
            )

            report = build_report(repo_root)

            self.assertEqual(report["status"], "passed")
            self.assertEqual(report["saved_memory_only"], [])
            self.assertEqual(report["restored_checkout_only"], [])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedMemoryHelperSurfaceAlignmentTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    report = build_report(repo_root)

    if args.json:
        print(json.dumps(report, indent=2))
        return 1 if report["failures"] else 0

    print("Issue #3 saved-memory helper-surface alignment check")
    print()
    print(f"Repo root: {repo_root}")
    print(f"Shared paths: {report['shared_path_count']}")

    if report["missing_sources"]:
        print()
        print("Missing source files:")
        for path in report["missing_sources"]:
            print(f"  - {path}")

    if report["saved_memory_only"]:
        print()
        print("Saved-memory-only paths:")
        for path in report["saved_memory_only"]:
            print(f"  - {path}")

    if report["restored_checkout_only"]:
        print()
        print("Restored-checkout-only paths:")
        for path in report["restored_checkout_only"]:
            print(f"  - {path}")

    if report["failures"]:
        print()
        print("Alignment check failed.")
        return 1

    print()
    print("Alignment check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
