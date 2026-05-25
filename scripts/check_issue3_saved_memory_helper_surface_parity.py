#!/usr/bin/env python3

"""Check issue #3 helper-surface parity across restore and preflight helpers."""

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


DEFAULT_SAVED_MEMORY_HELPER = "scripts/check_issue3_saved_memory_inputs.py"
DEFAULT_RESTORE_HELPER = "scripts/linux/restore_saved_browser_snapshot.sh"
DEFAULT_RESTORED_CHECKOUT_HELPER = "scripts/check_issue3_restored_checkout.py"
HELPER_SURFACE_LINE_RE = re.compile(r'^\s*"([^"]+)"\s*$')


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the saved-memory preflight helper covers the current "
            "issue #3 synced helper surface from the restore and restored-checkout "
            "routes."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--saved-memory-helper",
        default=DEFAULT_SAVED_MEMORY_HELPER,
        help="Relative path to the saved-memory preflight helper",
    )
    parser.add_argument(
        "--restore-helper",
        default=DEFAULT_RESTORE_HELPER,
        help="Relative path to the saved-browser-snapshot restore helper",
    )
    parser.add_argument(
        "--restored-checkout-helper",
        default=DEFAULT_RESTORED_CHECKOUT_HELPER,
        help="Relative path to the restored-checkout readiness helper",
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


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def extract_python_tuple_paths(source: str, constant_name: str) -> list[str]:
    module = ast.parse(source)
    for node in module.body:
        if not isinstance(node, ast.Assign):
            continue
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id == constant_name:
                value = ast.literal_eval(node.value)
                return [entry[0] for entry in value]
    raise ValueError(f"Could not find {constant_name} in Python source")


def extract_shell_array_paths(source: str, marker: str) -> list[str]:
    in_block = False
    paths: list[str] = []
    for line in source.splitlines():
        stripped = line.strip()
        if not in_block:
            if stripped == marker:
                in_block = True
            continue
        if stripped == ")":
            break
        match = HELPER_SURFACE_LINE_RE.match(line)
        if match is not None:
            paths.append(match.group(1))
    if not in_block:
        raise ValueError(f"Could not find shell array marker: {marker}")
    if not paths:
        raise ValueError(f"Shell array {marker} did not contain any paths")
    return paths


def collect_results(
    *,
    repo_root: Path,
    saved_memory_helper: Path,
    restore_helper: Path,
    restored_checkout_helper: Path,
) -> dict[str, object]:
    saved_memory_paths = extract_python_tuple_paths(
        read_text(saved_memory_helper), "REQUIRED_RESTORED_HELPER_FILES"
    )
    restore_paths = extract_shell_array_paths(
        read_text(restore_helper), 'declare -a HELPER_SURFACE_PATHS=('
    )
    restored_checkout_paths = extract_python_tuple_paths(
        read_text(restored_checkout_helper), "HELPER_SURFACE_PATHS"
    )

    saved_memory_set = set(saved_memory_paths)
    restore_set = set(restore_paths)
    restored_checkout_set = set(restored_checkout_paths)
    union_surface = restore_set | restored_checkout_set

    missing_from_saved_memory = sorted(union_surface - saved_memory_set)
    restore_only = sorted(restore_set - saved_memory_set)
    restored_checkout_only = sorted(restored_checkout_set - saved_memory_set)
    extra_in_saved_memory = sorted(saved_memory_set - union_surface)

    return {
        "ok": not missing_from_saved_memory,
        "repo_root": str(repo_root),
        "saved_memory_helper": str(saved_memory_helper),
        "restore_helper": str(restore_helper),
        "restored_checkout_helper": str(restored_checkout_helper),
        "saved_memory_count": len(saved_memory_paths),
        "restore_count": len(restore_paths),
        "restored_checkout_count": len(restored_checkout_paths),
        "missing_from_saved_memory": missing_from_saved_memory,
        "missing_from_saved_memory_restore_only": restore_only,
        "missing_from_saved_memory_restored_checkout_only": restored_checkout_only,
        "extra_in_saved_memory": extra_in_saved_memory,
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #3 saved-memory helper-surface parity")
    print()
    print(f"Repo root: {result['repo_root']}")
    print(f"Saved-memory helper: {result['saved_memory_helper']}")
    print(f"Restore helper: {result['restore_helper']}")
    print(f"Restored-checkout helper: {result['restored_checkout_helper']}")
    print(
        "Counts: "
        f"saved-memory={result['saved_memory_count']}, "
        f"restore={result['restore_count']}, "
        f"restored-checkout={result['restored_checkout_count']}"
    )
    print()
    if result["missing_from_saved_memory"]:
        print("Missing from saved-memory helper surface:")
        for path in result["missing_from_saved_memory"]:
            print(f"  - {path}")
    else:
        print("Saved-memory helper surface covers the current restore and restored-checkout surfaces.")
    if result["extra_in_saved_memory"]:
        print()
        print("Saved-memory-only paths:")
        for path in result["extra_in_saved_memory"]:
            print(f"  - {path}")


class SavedMemoryHelperSurfaceParityTests(unittest.TestCase):
    def test_extract_python_tuple_paths(self) -> None:
        source = textwrap.dedent(
            """
            REQUIRED_RESTORED_HELPER_FILES = (
                ("docs/a.md", "A"),
                ("scripts/b.py", "B"),
            )
            """
        )
        self.assertEqual(
            extract_python_tuple_paths(source, "REQUIRED_RESTORED_HELPER_FILES"),
            ["docs/a.md", "scripts/b.py"],
        )

    def test_extract_shell_array_paths(self) -> None:
        source = textwrap.dedent(
            """
            declare -a HELPER_SURFACE_PATHS=(
                "docs/a.md"
                "scripts/b.py"
            )
            """
        )
        self.assertEqual(
            extract_shell_array_paths(source, 'declare -a HELPER_SURFACE_PATHS=('),
            ["docs/a.md", "scripts/b.py"],
        )

    def test_collect_results_reports_missing_surface_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            saved_memory_helper = repo_root / "saved.py"
            restore_helper = repo_root / "restore.sh"
            restored_checkout_helper = repo_root / "restored.py"

            saved_memory_helper.write_text(
                textwrap.dedent(
                    """
                    REQUIRED_RESTORED_HELPER_FILES = (
                        ("docs/a.md", "A"),
                    )
                    """
                ),
                encoding="utf-8",
            )
            restore_helper.write_text(
                textwrap.dedent(
                    """
                    declare -a HELPER_SURFACE_PATHS=(
                        "docs/a.md"
                        "scripts/missing_from_saved_memory.py"
                    )
                    """
                ),
                encoding="utf-8",
            )
            restored_checkout_helper.write_text(
                textwrap.dedent(
                    """
                    HELPER_SURFACE_PATHS = (
                        ("docs/a.md", "A"),
                        ("scripts/also_missing.py", "B"),
                    )
                    """
                ),
                encoding="utf-8",
            )

            result = collect_results(
                repo_root=repo_root,
                saved_memory_helper=saved_memory_helper,
                restore_helper=restore_helper,
                restored_checkout_helper=restored_checkout_helper,
            )

            self.assertFalse(result["ok"])
            self.assertEqual(
                result["missing_from_saved_memory"],
                [
                    "scripts/also_missing.py",
                    "scripts/missing_from_saved_memory.py",
                ],
            )

    def test_collect_results_passes_when_surfaces_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            saved_memory_helper = repo_root / "saved.py"
            restore_helper = repo_root / "restore.sh"
            restored_checkout_helper = repo_root / "restored.py"

            saved_memory_helper.write_text(
                textwrap.dedent(
                    """
                    REQUIRED_RESTORED_HELPER_FILES = (
                        ("docs/a.md", "A"),
                        ("scripts/b.py", "B"),
                    )
                    """
                ),
                encoding="utf-8",
            )
            restore_helper.write_text(
                textwrap.dedent(
                    """
                    declare -a HELPER_SURFACE_PATHS=(
                        "docs/a.md"
                        "scripts/b.py"
                    )
                    """
                ),
                encoding="utf-8",
            )
            restored_checkout_helper.write_text(
                textwrap.dedent(
                    """
                    HELPER_SURFACE_PATHS = (
                        ("docs/a.md", "A"),
                        ("scripts/b.py", "B"),
                    )
                    """
                ),
                encoding="utf-8",
            )

            result = collect_results(
                repo_root=repo_root,
                saved_memory_helper=saved_memory_helper,
                restore_helper=restore_helper,
                restored_checkout_helper=restored_checkout_helper,
            )

            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_from_saved_memory"], [])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedMemoryHelperSurfaceParityTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(
        repo_root=repo_root,
        saved_memory_helper=(repo_root / args.saved_memory_helper).resolve(),
        restore_helper=(repo_root / args.restore_helper).resolve(),
        restored_checkout_helper=(repo_root / args.restored_checkout_helper).resolve(),
    )
    if args.json:
        print(
            json.dumps(
                {"profile": "issue3-saved-memory-helper-surface-parity", **result},
                indent=2,
            )
        )
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
