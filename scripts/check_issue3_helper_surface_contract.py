#!/usr/bin/env python3

"""Check that the issue #11 helper-surface lists stay in sync.

This helper compares the restore helper, the saved-memory preflight, the
restored-checkout readiness helper, and the saved-browser-snapshot
archive-surface helper so future Linux or WSL re-entry runs can catch helper
surface drift before trusting those routes.
"""

from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path
import re
import sys
import tempfile
import textwrap
import unittest


PYTHON_LIST_TARGETS = (
    ("scripts/check_issue3_saved_memory_inputs.py", "REQUIRED_RESTORED_HELPER_FILES"),
    ("scripts/check_issue3_restored_checkout.py", "HELPER_SURFACE_PATHS"),
    ("scripts/check_issue3_saved_browser_snapshot_archive_surface.py", "REQUIRED_PATHS"),
)
RESTORE_SCRIPT_PATH = "scripts/linux/restore_saved_browser_snapshot.sh"
RESTORE_ARRAY_NAME = "HELPER_SURFACE_PATHS"
ARCHIVE_SENTINEL_PATHS = {"build.zig.zon"}


def extract_python_path_list(path: Path, variable_name: str) -> list[str]:
    module = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    for node in module.body:
        if isinstance(node, ast.Assign):
            targets = node.targets
        elif isinstance(node, ast.AnnAssign):
            targets = [node.target]
        else:
            continue
        for target in targets:
            if isinstance(target, ast.Name) and target.id == variable_name:
                value = ast.literal_eval(node.value)
                return [entry[0] for entry in value]
    raise ValueError(f"Could not find {variable_name} in {path}")


def extract_bash_array(path: Path, array_name: str) -> list[str]:
    text = path.read_text(encoding="utf-8")
    pattern = re.compile(
        rf'declare\s+-a\s+{re.escape(array_name)}=\(\n(?P<body>.*?)\n\)',
        re.DOTALL,
    )
    match = pattern.search(text)
    if match is None:
        raise ValueError(f"Could not find bash array {array_name} in {path}")
    return re.findall(r'"([^"]+)"', match.group("body"))


def duplicate_entries(paths: list[str]) -> list[str]:
    seen: set[str] = set()
    duplicates: list[str] = []
    for path in paths:
        if path in seen and path not in duplicates:
            duplicates.append(path)
        seen.add(path)
    return duplicates


def compare_sets(baseline: list[str], candidate: list[str]) -> dict[str, list[str]]:
    baseline_set = set(baseline)
    candidate_set = set(candidate)
    return {
        "missing_from_candidate": sorted(baseline_set - candidate_set),
        "extra_in_candidate": sorted(candidate_set - baseline_set),
    }


def collect_results(repo_root: Path) -> dict[str, object]:
    source_lists: dict[str, list[str]] = {}
    for relative_path, variable_name in PYTHON_LIST_TARGETS:
        paths = extract_python_path_list(
            repo_root / relative_path, variable_name
        )
        if relative_path.endswith("check_issue3_saved_browser_snapshot_archive_surface.py"):
            paths = [path for path in paths if path not in ARCHIVE_SENTINEL_PATHS]
        source_lists[relative_path] = paths
    source_lists[RESTORE_SCRIPT_PATH] = extract_bash_array(
        repo_root / RESTORE_SCRIPT_PATH, RESTORE_ARRAY_NAME
    )

    restored_checkout_paths = source_lists["scripts/check_issue3_restored_checkout.py"]
    restore_script_paths = source_lists[RESTORE_SCRIPT_PATH]
    saved_memory_paths = source_lists["scripts/check_issue3_saved_memory_inputs.py"]
    archive_surface_paths = source_lists[
        "scripts/check_issue3_saved_browser_snapshot_archive_surface.py"
    ]

    comparisons = {
        "saved_memory_vs_restored_checkout": compare_sets(
            restored_checkout_paths, saved_memory_paths
        ),
        "saved_memory_vs_restore_script": compare_sets(
            restore_script_paths, saved_memory_paths
        ),
        "restored_checkout_vs_restore_script": compare_sets(
            restore_script_paths, restored_checkout_paths
        ),
        "saved_memory_vs_archive_surface": compare_sets(
            archive_surface_paths, saved_memory_paths
        ),
        "restored_checkout_vs_archive_surface": compare_sets(
            archive_surface_paths, restored_checkout_paths
        ),
        "restore_script_vs_archive_surface": compare_sets(
            archive_surface_paths, restore_script_paths
        ),
    }
    duplicates = {
        relative_path: duplicate_entries(paths)
        for relative_path, paths in source_lists.items()
    }

    ok = (
        all(not delta for comparison in comparisons.values() for delta in comparison.values())
        and all(not items for items in duplicates.values())
    )

    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "sources": {
            relative_path: {
                "count": len(paths),
                "duplicates": duplicates[relative_path],
            }
            for relative_path, paths in source_lists.items()
        },
        "archive_surface_sentinel_paths": sorted(ARCHIVE_SENTINEL_PATHS),
        "comparisons": comparisons,
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #11 helper-surface contract")
    print()
    print(f"Repo root: {result['repo_root']}")
    for relative_path, details in result["sources"].items():
        print(f"{relative_path}: {details['count']} paths")
        if details["duplicates"]:
            print(f"  duplicate entries: {', '.join(details['duplicates'])}")
    print(
        "archive-surface sentinel paths: "
        + ", ".join(result["archive_surface_sentinel_paths"])
    )

    print()
    for name, comparison in result["comparisons"].items():
        missing = comparison["missing_from_candidate"]
        extra = comparison["extra_in_candidate"]
        print(f"{name}:")
        if not missing and not extra:
            print("  in sync")
            continue
        if missing:
            print("  missing from candidate:")
            for entry in missing:
                print(f"    - {entry}")
        if extra:
            print("  extra in candidate:")
            for entry in extra:
                print(f"    - {entry}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Check that the issue #11 helper-surface lists stay in sync."
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser repo root (default: current directory)",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON output")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


class HelperSurfaceContractTests(unittest.TestCase):
    def write_fixture(self, root: Path, relative_path: str, content: str) -> None:
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(textwrap.dedent(content).lstrip(), encoding="utf-8")

    def seed_repo(self, root: Path, saved_memory_extra: str = "") -> None:
        self.write_fixture(
            root,
            "scripts/check_issue3_saved_memory_inputs.py",
            f"""
            REQUIRED_RESTORED_HELPER_FILES = (
                ("docs/A.md", "A"),
                ("scripts/B.py", "B"),
                {saved_memory_extra}
            )
            """,
        )
        self.write_fixture(
            root,
            "scripts/check_issue3_restored_checkout.py",
            """
            HELPER_SURFACE_PATHS = (
                ("docs/A.md", "A"),
                ("scripts/B.py", "B"),
                ("scripts/C.py", "C"),
            )
            """,
        )
        self.write_fixture(
            root,
            "scripts/linux/restore_saved_browser_snapshot.sh",
            """
            declare -a HELPER_SURFACE_PATHS=(
                "docs/A.md"
                "scripts/B.py"
                "scripts/C.py"
            )
            """,
        )
        self.write_fixture(
            root,
            "scripts/check_issue3_saved_browser_snapshot_archive_surface.py",
            """
            REQUIRED_PATHS = (
                ("build.zig.zon", "manifest"),
                ("docs/A.md", "A"),
                ("scripts/B.py", "B"),
                ("scripts/C.py", "C"),
            )
            """,
        )

    def test_collect_results_reports_missing_saved_memory_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            self.seed_repo(root)
            result = collect_results(root)
            self.assertFalse(result["ok"])
            self.assertEqual(
                result["comparisons"]["saved_memory_vs_restore_script"]["missing_from_candidate"],
                ["scripts/C.py"],
            )
            self.assertEqual(
                result["comparisons"]["restored_checkout_vs_restore_script"]["missing_from_candidate"],
                [],
            )
            self.assertEqual(
                result["comparisons"]["saved_memory_vs_archive_surface"]["missing_from_candidate"],
                ["scripts/C.py"],
            )

    def test_collect_results_passes_when_all_sources_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            self.seed_repo(root, '("scripts/C.py", "C"),')
            self.write_fixture(
                root,
                "scripts/check_issue3_saved_browser_snapshot_archive_surface.py",
                """
                REQUIRED_PATHS = (
                    ("build.zig.zon", "manifest"),
                    ("docs/A.md", "A"),
                    ("scripts/B.py", "B"),
                    ("scripts/C.py", "C"),
                )
                """,
            )
            result = collect_results(root)
            self.assertTrue(result["ok"])

    def test_collect_results_flags_duplicate_entries(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            self.seed_repo(root, '("scripts/C.py", "C"),')
            self.write_fixture(
                root,
                "scripts/linux/restore_saved_browser_snapshot.sh",
                """
                declare -a HELPER_SURFACE_PATHS=(
                    "docs/A.md"
                    "scripts/B.py"
                    "scripts/C.py"
                    "scripts/C.py"
                )
                """,
            )
            result = collect_results(root)
            self.assertFalse(result["ok"])
            self.assertEqual(
                result["sources"]["scripts/linux/restore_saved_browser_snapshot.sh"]["duplicates"],
                ["scripts/C.py"],
            )

    def test_collect_results_flags_restored_checkout_drift(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            self.seed_repo(root, '("scripts/C.py", "C"),')
            self.write_fixture(
                root,
                "scripts/check_issue3_restored_checkout.py",
                """
                HELPER_SURFACE_PATHS = (
                    ("docs/A.md", "A"),
                    ("scripts/B.py", "B"),
                )
                """,
            )
            self.write_fixture(
                root,
                "scripts/check_issue3_saved_browser_snapshot_archive_surface.py",
                """
                REQUIRED_PATHS = (
                    ("build.zig.zon", "manifest"),
                    ("docs/A.md", "A"),
                    ("scripts/B.py", "B"),
                    ("scripts/C.py", "C"),
                )
                """,
            )
            result = collect_results(root)
            self.assertFalse(result["ok"])
            self.assertEqual(
                result["comparisons"]["restored_checkout_vs_restore_script"]["extra_in_candidate"],
                [],
            )
            self.assertEqual(
                result["comparisons"]["restored_checkout_vs_restore_script"]["missing_from_candidate"],
                ["scripts/C.py"],
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(HelperSurfaceContractTests)
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
