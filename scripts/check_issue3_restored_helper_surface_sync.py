#!/usr/bin/env python3

"""Check that restored issue #3 helper surfaces include the newer re-entry routes.

This helper focuses on the smaller set of late-added Linux/WSL re-entry route
files that older restored snapshots can miss while still looking mostly usable.
It is meant to fail fast before a run trusts a restored checkout for issue #11
or reopens the narrowed issue #3 runtime lane.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest


REQUIRED_REENTRY_ROUTE_FILES: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "issue #11 tracker route"),
    (
        "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
        "saved Zig archive candidates route",
    ),
    (
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
        "saved Rust toolchain route",
    ),
    (
        "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
        "saved-memory route surface checker",
    ),
    (
        "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
        "saved-memory route helper",
    ),
    (
        "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
        "saved Zig archive candidates surface checker",
    ),
    (
        "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
        "saved Zig archive candidates route helper",
    ),
    (
        "scripts/check_issue3_saved_zig_archive_candidates.py",
        "saved Zig archive candidates helper",
    ),
    (
        "scripts/check_issue3_saved_rust_archive_candidates.py",
        "saved Rust archive candidates helper",
    ),
    (
        "scripts/check_issue3_staged_rust_toolchain_candidates.py",
        "staged Rust toolchain candidates helper",
    ),
    (
        "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
        "saved Rust toolchain route surface checker",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
        "saved Rust toolchain route helper",
    ),
    (
        "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
        "Zig archive restore route helper",
    ),
    (
        "scripts/linux/show_issue3_windows_runtime_handoff_route.sh",
        "Linux-to-Windows runtime handoff helper",
    ),
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def collect_file_state(root: Path, relative_path: str, label: str) -> dict[str, object]:
    path = root / relative_path
    exists = path.is_file()
    return {
        "label": label,
        "relative_path": relative_path,
        "path": str(path),
        "exists": exists,
        "sha256": sha256(path) if exists else None,
    }


def compare_helper_surfaces(helper_root: Path, restored_root: Path) -> dict[str, object]:
    helper_rows: list[dict[str, object]] = []
    restored_rows: list[dict[str, object]] = []
    drifted: list[str] = []
    missing_in_helper: list[str] = []
    missing_in_restored: list[str] = []

    for relative_path, label in REQUIRED_REENTRY_ROUTE_FILES:
        helper_row = collect_file_state(helper_root, relative_path, label)
        restored_row = collect_file_state(restored_root, relative_path, label)
        helper_rows.append(helper_row)
        restored_rows.append(restored_row)

        helper_exists = bool(helper_row["exists"])
        restored_exists = bool(restored_row["exists"])
        if not helper_exists:
            missing_in_helper.append(relative_path)
        if not restored_exists:
            missing_in_restored.append(relative_path)
        if helper_exists and restored_exists and helper_row["sha256"] != restored_row["sha256"]:
            drifted.append(relative_path)

    ok = not missing_in_helper and not missing_in_restored and not drifted
    return {
        "ok": ok,
        "helper_root": str(helper_root),
        "restored_root": str(restored_root),
        "helper_files": helper_rows,
        "restored_files": restored_rows,
        "missing_in_helper": missing_in_helper,
        "missing_in_restored": missing_in_restored,
        "drifted_files": drifted,
    }


def emit_text(report: dict[str, object]) -> None:
    print("Issue #3 restored helper surface sync")
    print()
    print(f"Helper root:   {report['helper_root']}")
    print(f"Restored root: {report['restored_root']}")
    print()

    for relative_path in report["missing_in_helper"]:
        print(f"[FAIL] helper root missing {relative_path}")
    for relative_path in report["missing_in_restored"]:
        print(f"[FAIL] restored checkout missing {relative_path}")
    for relative_path in report["drifted_files"]:
        print(f"[FAIL] restored checkout drifted at {relative_path}")

    if report["ok"]:
        print("Restored helper surface sync passed.")
        return

    print()
    print("Suggested next step:")
    print(
        "  Refresh the restored checkout helper surface from the live branch-local "
        "helper root before trusting Linux/WSL re-entry commands."
    )



def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether a restored checkout still carries the newer issue #3 "
            "Linux/WSL re-entry helper surface."
        )
    )
    parser.add_argument(
        "--helper-root",
        default=".",
        help="Path to the live helper checkout root (default: current directory)",
    )
    parser.add_argument(
        "--restored-root",
        required=False,
        default="../browser-memory-snapshot",
        help="Path to the restored checkout root to compare",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON instead of the human-readable summary",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused unit tests and exit",
    )
    return parser


class RestoredHelperSurfaceSyncTests(unittest.TestCase):
    def test_compare_passes_when_roots_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "helper"
            restored_root = root / "restored"
            helper_root.mkdir()
            restored_root.mkdir()
            for relative_path, _label in REQUIRED_REENTRY_ROUTE_FILES:
                for base in (helper_root, restored_root):
                    target = base / relative_path
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_text(relative_path, encoding="utf-8")

            report = compare_helper_surfaces(helper_root, restored_root)

            self.assertTrue(report["ok"])
            self.assertEqual(report["missing_in_restored"], [])
            self.assertEqual(report["drifted_files"], [])

    def test_compare_reports_missing_and_drifted_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "helper"
            restored_root = root / "restored"
            helper_root.mkdir()
            restored_root.mkdir()

            for relative_path, _label in REQUIRED_REENTRY_ROUTE_FILES:
                helper_target = helper_root / relative_path
                helper_target.parent.mkdir(parents=True, exist_ok=True)
                helper_target.write_text("live", encoding="utf-8")

                if relative_path == "scripts/check_issue3_saved_zig_archive_candidates.py":
                    continue

                restored_target = restored_root / relative_path
                restored_target.parent.mkdir(parents=True, exist_ok=True)
                restored_target.write_text(
                    "drifted"
                    if relative_path == "scripts/linux/show_issue3_windows_runtime_handoff_route.sh"
                    else "live",
                    encoding="utf-8"),

            report = compare_helper_surfaces(helper_root, restored_root)

            self.assertFalse(report["ok"])
            self.assertIn(
                "scripts/check_issue3_saved_zig_archive_candidates.py",
                report["missing_in_restored"],
            )
            self.assertIn(
                "scripts/linux/show_issue3_windows_runtime_handoff_route.sh",
                report["drifted_files"],
            )



def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            RestoredHelperSurfaceSyncTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    helper_root = Path(args.helper_root).resolve()
    restored_root = Path(args.restored_root).resolve()
    report = compare_helper_surfaces(helper_root, restored_root)

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())