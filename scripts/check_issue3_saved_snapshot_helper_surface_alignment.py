#!/usr/bin/env python3

"""Check whether the saved-snapshot restore helper syncs the full live helper contract.

This helper compares the helper-surface list mirrored by
`scripts/linux/restore_saved_browser_snapshot.sh` against the helper-surface
contract enforced by `scripts/check_issue3_restored_checkout.py`.

It exists for the Linux/WSL re-entry lane where a restored checkout may look
healthy as a historical repo snapshot but still be missing newer helper files
that follow-up routes now expect after `--sync-helper-surface`.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest


RESTORE_HELPER_PATH = "scripts/linux/restore_saved_browser_snapshot.sh"
RESTORED_CHECKOUT_HELPER_PATH = "scripts/check_issue3_restored_checkout.py"
SHELL_ARRAY_LINE_RE = re.compile(r'^\s*"([^"]+)"\s*$')
PYTHON_TUPLE_LINE_RE = re.compile(r'^\s*\("([^"]+)",\s*"([^"]*)"\),?\s*$')


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether restore_saved_browser_snapshot.sh mirrors every helper "
            "path that check_issue3_restored_checkout.py expects after a synced "
            "saved-snapshot restore."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser repo root (default: current directory)",
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


def extract_shell_array_paths(script_text: str, marker: str) -> list[str]:
    in_block = False
    paths: list[str] = []
    for line in script_text.splitlines():
        stripped = line.strip()
        if not in_block:
            if stripped == marker:
                in_block = True
            continue
        if stripped == ")":
            break
        match = SHELL_ARRAY_LINE_RE.match(line)
        if match is not None:
            paths.append(match.group(1))
    if not in_block:
        raise ValueError(f"Could not find {marker!r}")
    if not paths:
        raise ValueError(f"{marker!r} did not contain any helper paths")
    return paths


def extract_python_helper_surface_paths(script_text: str, marker: str) -> list[str]:
    in_block = False
    saw_open = False
    paths: list[str] = []
    for line in script_text.splitlines():
        stripped = line.strip()
        if not in_block:
            if stripped.startswith(marker):
                in_block = True
                if stripped.endswith("("):
                    saw_open = True
                continue
        else:
            if not saw_open:
                if stripped == "(":
                    saw_open = True
                continue
            if stripped == ")":
                break
            match = PYTHON_TUPLE_LINE_RE.match(line)
            if match is not None:
                paths.append(match.group(1))
    if not in_block:
        raise ValueError(f"Could not find {marker!r}")
    if not paths:
        raise ValueError(f"{marker!r} did not contain any helper paths")
    return paths


def collect_results(repo_root: Path) -> dict[str, object]:
    restore_helper = repo_root / RESTORE_HELPER_PATH
    restored_checkout_helper = repo_root / RESTORED_CHECKOUT_HELPER_PATH

    restore_paths = extract_shell_array_paths(
        restore_helper.read_text(encoding="utf-8"),
        "declare -a HELPER_SURFACE_PATHS=(",
    )
    restored_paths = extract_python_helper_surface_paths(
        restored_checkout_helper.read_text(encoding="utf-8"),
        "HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] =",
    )

    restore_set = set(restore_paths)
    restored_set = set(restored_paths)
    missing_from_restore = [path for path in restored_paths if path not in restore_set]
    restore_only_paths = [path for path in restore_paths if path not in restored_set]

    return {
        "status": "passed" if not missing_from_restore else "failed",
        "repo_root": str(repo_root),
        "restore_helper": str(restore_helper),
        "restored_checkout_helper": str(restored_checkout_helper),
        "restore_helper_path_count": len(restore_paths),
        "restored_checkout_path_count": len(restored_paths),
        "missing_from_restore_helper": missing_from_restore,
        "restore_only_paths": restore_only_paths,
        "suggested_next_step": (
            "add the missing restored-checkout helper paths to restore_saved_browser_snapshot.sh before relying on --sync-helper-surface"
            if missing_from_restore
            else None
        ),
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Restore helper: {result['restore_helper']}")
    print(f"Restored-checkout helper: {result['restored_checkout_helper']}")
    print(f"Restore helper paths: {result['restore_helper_path_count']}")
    print(f"Restored-checkout helper paths: {result['restored_checkout_path_count']}")

    missing = result["missing_from_restore_helper"]
    restore_only = result["restore_only_paths"]
    if missing:
        print("\nMissing from restore helper:")
        for path in missing:
            print(f"  - {path}")
    else:
        print("\nRestore helper already mirrors every restored-checkout helper path.")

    if restore_only:
        print("\nRestore-only helper paths:")
        for path in restore_only:
            print(f"  - {path}")

    if result["status"] == "passed":
        print("\nSaved snapshot helper-surface alignment check passed.")
        return

    print("\nSaved snapshot helper-surface alignment check failed.", file=sys.stderr)
    print(
        "Suggested next step: add the missing restored-checkout helper paths to "
        "restore_saved_browser_snapshot.sh before relying on --sync-helper-surface, "
        "or keep using the live helper root for follow-up commands until the sync "
        "surface is expanded.",
        file=sys.stderr,
    )


class SavedSnapshotHelperSurfaceAlignmentTests(unittest.TestCase):
    def test_extract_shell_array_paths(self) -> None:
        script_text = """
        declare -a HELPER_SURFACE_PATHS=(
            \"scripts/check_issue3_saved_rust_archive_candidates.py\"
            \"scripts/check_issue3_staged_zig_toolchain_candidates.py\"
        )
        """
        self.assertEqual(
            extract_shell_array_paths(script_text, "declare -a HELPER_SURFACE_PATHS=("),
            [
                "scripts/check_issue3_saved_rust_archive_candidates.py",
                "scripts/check_issue3_staged_zig_toolchain_candidates.py",
            ],
        )

    def test_extract_python_helper_surface_paths(self) -> None:
        script_text = """
        HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
            (\"scripts/check_issue3_saved_rust_archive_candidates.py\", \"saved Rust archive candidate helper\"),
            (\"scripts/check_issue3_staged_zig_toolchain_candidates.py\", \"staged Zig toolchain candidate helper\"),
        )
        """
        self.assertEqual(
            extract_python_helper_surface_paths(
                script_text,
                "HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] =",
            ),
            [
                "scripts/check_issue3_saved_rust_archive_candidates.py",
                "scripts/check_issue3_staged_zig_toolchain_candidates.py",
            ],
        )

    def test_collect_results_reports_restore_gap(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            restore_helper = repo_root / RESTORE_HELPER_PATH
            restore_helper.parent.mkdir(parents=True, exist_ok=True)
            restore_helper.write_text(
                """
                declare -a HELPER_SURFACE_PATHS=(
                    \"scripts/check_issue3_saved_memory_inputs.py\"
                    \"scripts/check_issue3_saved_zig_archive_candidates.py\"
                )
                """,
                encoding="utf-8",
            )
            restored_helper = repo_root / RESTORED_CHECKOUT_HELPER_PATH
            restored_helper.parent.mkdir(parents=True, exist_ok=True)
            restored_helper.write_text(
                """
                HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
                    (\"scripts/check_issue3_saved_memory_inputs.py\", \"saved-memory preflight helper\"),
                    (\"scripts/check_issue3_saved_rust_archive_candidates.py\", \"saved Rust archive candidate helper\"),
                    (\"scripts/check_issue3_saved_zig_archive_candidates.py\", \"saved Zig archive candidate helper\"),
                    (\"scripts/check_issue3_staged_zig_toolchain_candidates.py\", \"staged Zig toolchain candidate helper\"),
                )
                """,
                encoding="utf-8",
            )

            result = collect_results(repo_root)

            self.assertEqual(result["status"], "failed")
            self.assertEqual(
                result["missing_from_restore_helper"],
                [
                    "scripts/check_issue3_saved_rust_archive_candidates.py",
                    "scripts/check_issue3_staged_zig_toolchain_candidates.py",
                ],
            )

    def test_collect_results_passes_when_lists_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            helper_paths = [
                "scripts/check_issue3_saved_rust_archive_candidates.py",
                "scripts/check_issue3_staged_rust_toolchain_candidates.py",
                "scripts/check_issue3_saved_zig_archive_candidates.py",
                "scripts/check_issue3_staged_zig_toolchain_candidates.py",
            ]

            restore_helper = repo_root / RESTORE_HELPER_PATH
            restore_helper.parent.mkdir(parents=True, exist_ok=True)
            restore_helper.write_text(
                "declare -a HELPER_SURFACE_PATHS=(\n"
                + "\n".join(f'    \"{path}\"' for path in helper_paths)
                + "\n)\n",
                encoding="utf-8",
            )
            restored_helper = repo_root / RESTORED_CHECKOUT_HELPER_PATH
            restored_helper.parent.mkdir(parents=True, exist_ok=True)
            restored_helper.write_text(
                "HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (\n"
                + "\n".join(
                    f'    (\"{path}\", \"helper\"),' for path in helper_paths
                )
                + "\n)\n",
                encoding="utf-8",
            )

            result = collect_results(repo_root)

            self.assertEqual(result["status"], "passed")
            self.assertEqual(result["missing_from_restore_helper"], [])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedSnapshotHelperSurfaceAlignmentTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())
