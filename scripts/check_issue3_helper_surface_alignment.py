#!/usr/bin/env python3

"""Check whether the issue #3 helper-surface inventories still agree.

This helper compares the helper-surface path inventories embedded in:
- scripts/linux/restore_saved_browser_snapshot.sh
- scripts/check_issue3_saved_memory_inputs.py
- scripts/check_issue3_restored_checkout.py

It is intended as a small regression guard for the saved-snapshot restore route.
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


RESTORE_SCRIPT_RELATIVE_PATH = "scripts/linux/restore_saved_browser_snapshot.sh"
SAVED_MEMORY_INPUTS_RELATIVE_PATH = "scripts/check_issue3_saved_memory_inputs.py"
RESTORED_CHECKOUT_RELATIVE_PATH = "scripts/check_issue3_restored_checkout.py"

RESTORE_ARRAY_NAME = "HELPER_SURFACE_PATHS"
SAVED_MEMORY_TUPLE_NAME = "REQUIRED_RESTORED_HELPER_FILES"
RESTORED_CHECKOUT_TUPLE_NAME = "HELPER_SURFACE_PATHS"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the issue #3 saved-snapshot helper-surface "
            "inventories still match across the restore and follow-up helpers."
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


def parse_restore_helper_surface_paths(script_path: Path) -> list[str]:
    text = script_path.read_text(encoding="utf-8")
    match = re.search(
        r"declare -a\s+HELPER_SURFACE_PATHS=\(\n(?P<body>.*?)\n\)",
        text,
        flags=re.DOTALL,
    )
    if match is None:
        raise ValueError(
            f"Could not find {RESTORE_ARRAY_NAME} in {script_path}"
        )

    paths: list[str] = []
    for raw_line in match.group("body").splitlines():
        stripped = raw_line.strip()
        if not stripped:
            continue
        if not (stripped.startswith('"') and stripped.endswith('"')):
            continue
        paths.append(stripped[1:-1])
    return paths


def parse_python_tuple_paths(script_path: Path, variable_name: str) -> list[str]:
    module = ast.parse(script_path.read_text(encoding="utf-8"), filename=str(script_path))
    for node in module.body:
        if not isinstance(node, ast.Assign):
            continue
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id == variable_name:
                return extract_paths_from_tuple(node.value, script_path, variable_name)
        if isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name) and node.target.id == variable_name:
            return extract_paths_from_tuple(node.value, script_path, variable_name)
    raise ValueError(f"Could not find {variable_name} in {script_path}")


def extract_paths_from_tuple(value: ast.AST | None, script_path: Path, variable_name: str) -> list[str]:
    if value is None or not isinstance(value, (ast.Tuple, ast.List)):
        raise ValueError(f"{variable_name} in {script_path} is not a tuple/list literal")
    paths: list[str] = []
    for element in value.elts:
        if not isinstance(element, (ast.Tuple, ast.List)) or not element.elts:
            raise ValueError(f"{variable_name} in {script_path} contains a non-pair entry")
        first = element.elts[0]
        if not isinstance(first, ast.Constant) or not isinstance(first.value, str):
            raise ValueError(f"{variable_name} in {script_path} contains a non-string path")
        paths.append(first.value)
    return paths


def duplicate_paths(paths: list[str]) -> list[str]:
    seen: set[str] = set()
    duplicates: list[str] = []
    for path in paths:
        if path in seen and path not in duplicates:
            duplicates.append(path)
        seen.add(path)
    return duplicates


def diff_paths(source_paths: list[str], expected_paths: list[str]) -> dict[str, list[str]]:
    source_set = set(source_paths)
    expected_set = set(expected_paths)
    return {
        "missing": sorted(expected_set - source_set),
        "extra": sorted(source_set - expected_set),
    }


def collect_results(repo_root: Path) -> dict[str, object]:
    repo_root = repo_root.resolve()
    restore_script_path = repo_root / RESTORE_SCRIPT_RELATIVE_PATH
    saved_memory_inputs_path = repo_root / SAVED_MEMORY_INPUTS_RELATIVE_PATH
    restored_checkout_path = repo_root / RESTORED_CHECKOUT_RELATIVE_PATH

    files = {
        "restore_script": str(restore_script_path),
        "saved_memory_inputs": str(saved_memory_inputs_path),
        "restored_checkout": str(restored_checkout_path),
    }
    missing_files = [
        path for path in files.values() if not Path(path).is_file()
    ]
    if missing_files:
        return {
            "ok": False,
            "repo_root": str(repo_root),
            "missing_files": missing_files,
            "files": files,
            "inventories": {},
            "alignment": {},
        }

    restore_paths = parse_restore_helper_surface_paths(restore_script_path)
    saved_memory_paths = parse_python_tuple_paths(
        saved_memory_inputs_path, SAVED_MEMORY_TUPLE_NAME
    )
    restored_checkout_paths = parse_python_tuple_paths(
        restored_checkout_path, RESTORED_CHECKOUT_TUPLE_NAME
    )

    inventories = {
        "restore_script": {
            "count": len(restore_paths),
            "duplicates": duplicate_paths(restore_paths),
            "paths": restore_paths,
        },
        "saved_memory_inputs": {
            "count": len(saved_memory_paths),
            "duplicates": duplicate_paths(saved_memory_paths),
            "paths": saved_memory_paths,
        },
        "restored_checkout": {
            "count": len(restored_checkout_paths),
            "duplicates": duplicate_paths(restored_checkout_paths),
            "paths": restored_checkout_paths,
        },
    }

    alignment = {
        "restore_vs_saved_memory_inputs": diff_paths(restore_paths, saved_memory_paths),
        "restore_vs_restored_checkout": diff_paths(restore_paths, restored_checkout_paths),
        "saved_memory_inputs_vs_restored_checkout": diff_paths(saved_memory_paths, restored_checkout_paths),
    }

    ok = (
        not inventories["restore_script"]["duplicates"]
        and not inventories["saved_memory_inputs"]["duplicates"]
        and not inventories["restored_checkout"]["duplicates"]
        and not alignment["restore_vs_saved_memory_inputs"]["missing"]
        and not alignment["restore_vs_saved_memory_inputs"]["extra"]
        and not alignment["restore_vs_restored_checkout"]["missing"]
        and not alignment["restore_vs_restored_checkout"]["extra"]
        and not alignment["saved_memory_inputs_vs_restored_checkout"]["missing"]
        and not alignment["saved_memory_inputs_vs_restored_checkout"]["extra"]
    )

    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "missing_files": [],
        "files": files,
        "inventories": inventories,
        "alignment": alignment,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    if result["missing_files"]:
        print("Status: FAIL")
        for path in result["missing_files"]:
            print(f"  missing source file: {path}")
        return

    inventories = result["inventories"]
    alignment = result["alignment"]

    print(f"Restore script paths: {inventories['restore_script']['count']}")
    print(f"Saved-memory helper paths: {inventories['saved_memory_inputs']['count']}")
    print(f"Restored-checkout helper paths: {inventories['restored_checkout']['count']}")

    for inventory_name, inventory in inventories.items():
        duplicates = inventory["duplicates"]
        status = "PASS" if not duplicates else "FAIL"
        print(f"{inventory_name}: [{status}] duplicates={len(duplicates)}")
        for duplicate in duplicates:
            print(f"  duplicate path: {duplicate}")

    for comparison_name, comparison in alignment.items():
        status = "PASS" if not comparison["missing"] and not comparison["extra"] else "FAIL"
        print(f"{comparison_name}: [{status}]")
        for missing_path in comparison["missing"]:
            print(f"  missing: {missing_path}")
        for extra_path in comparison["extra"]:
            print(f"  extra: {extra_path}")

    print("\nHelper-surface alignment check passed." if result["ok"] else "\nHelper-surface alignment check failed.")


class HelperSurfaceAlignmentTests(unittest.TestCase):
    def write_fixture(self, root: Path, relative_path: str, content: str) -> None:
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(textwrap.dedent(content).lstrip(), encoding="utf-8")

    def test_collect_results_passes_when_inventories_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            self.write_fixture(
                root,
                RESTORE_SCRIPT_RELATIVE_PATH,
                """
                declare -a HELPER_SURFACE_PATHS=(
                    "docs/a.md"
                    "scripts/b.py"
                )
                """,
            )
            self.write_fixture(
                root,
                SAVED_MEMORY_INPUTS_RELATIVE_PATH,
                """
                REQUIRED_RESTORED_HELPER_FILES = (
                    ("docs/a.md", "a"),
                    ("scripts/b.py", "b"),
                )
                """,
            )
            self.write_fixture(
                root,
                RESTORED_CHECKOUT_RELATIVE_PATH,
                """
                HELPER_SURFACE_PATHS = (
                    ("docs/a.md", "a"),
                    ("scripts/b.py", "b"),
                )
                """,
            )

            result = collect_results(root)
            self.assertTrue(result["ok"])

    def test_collect_results_reports_missing_restore_entries(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            self.write_fixture(
                root,
                RESTORE_SCRIPT_RELATIVE_PATH,
                """
                declare -a HELPER_SURFACE_PATHS=(
                    "docs/a.md"
                )
                """,
            )
            self.write_fixture(
                root,
                SAVED_MEMORY_INPUTS_RELATIVE_PATH,
                """
                REQUIRED_RESTORED_HELPER_FILES = (
                    ("docs/a.md", "a"),
                    ("scripts/b.py", "b"),
                )
                """,
            )
            self.write_fixture(
                root,
                RESTORED_CHECKOUT_RELATIVE_PATH,
                """
                HELPER_SURFACE_PATHS = (
                    ("docs/a.md", "a"),
                    ("scripts/b.py", "b"),
                )
                """,
            )

            result = collect_results(root)
            self.assertFalse(result["ok"])
            self.assertEqual(
                result["alignment"]["restore_vs_saved_memory_inputs"]["missing"],
                ["scripts/b.py"],
            )

    def test_collect_results_reports_duplicate_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            self.write_fixture(
                root,
                RESTORE_SCRIPT_RELATIVE_PATH,
                """
                declare -a HELPER_SURFACE_PATHS=(
                    "docs/a.md"
                    "docs/a.md"
                )
                """,
            )
            self.write_fixture(
                root,
                SAVED_MEMORY_INPUTS_RELATIVE_PATH,
                """
                REQUIRED_RESTORED_HELPER_FILES = (
                    ("docs/a.md", "a"),
                )
                """,
            )
            self.write_fixture(
                root,
                RESTORED_CHECKOUT_RELATIVE_PATH,
                """
                HELPER_SURFACE_PATHS = (
                    ("docs/a.md", "a"),
                )
                """,
            )

            result = collect_results(root)
            self.assertFalse(result["ok"])
            self.assertEqual(
                result["inventories"]["restore_script"]["duplicates"],
                ["docs/a.md"],
            )

    def test_collect_results_reports_attached_page_sync_drift(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            self.write_fixture(
                root,
                RESTORE_SCRIPT_RELATIVE_PATH,
                """
                declare -a HELPER_SURFACE_PATHS=(
                    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
                    "scripts/check_issue3_saved_memory_inputs.py"
                )
                """,
            )
            self.write_fixture(
                root,
                SAVED_MEMORY_INPUTS_RELATIVE_PATH,
                """
                REQUIRED_RESTORED_HELPER_FILES = (
                    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime"),
                    ("scripts/check_issue3_saved_memory_inputs.py", "preflight"),
                    ("tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py", "catalog"),
                )
                """,
            )
            self.write_fixture(
                root,
                RESTORED_CHECKOUT_RELATIVE_PATH,
                """
                HELPER_SURFACE_PATHS = (
                    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime"),
                    ("scripts/check_issue3_saved_memory_inputs.py", "preflight"),
                    ("tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py", "catalog"),
                )
                """,
            )

            result = collect_results(root)
            self.assertFalse(result["ok"])
            self.assertEqual(
                result["alignment"]["restore_vs_saved_memory_inputs"]["missing"],
                ["tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"],
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            HelperSurfaceAlignmentTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    result = collect_results(Path(args.repo_root))
    if args.json:
        print(json.dumps({"profile": "issue3-helper-surface-alignment", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
