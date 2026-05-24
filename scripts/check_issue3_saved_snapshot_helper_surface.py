#!/usr/bin/env python3

"""Check whether the saved issue #3 repo snapshot already carries the helper surface.

This helper gives the saved-browser-snapshot restore route one small preflight
before extraction starts. It inspects the saved repo zip and reports whether the
archive already includes the current route-opening helper files or whether the
next restore should prefer `--sync-helper-surface`.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest
import zipfile


DEFAULT_ARCHIVE_NAME = "01-browser-fork-headed-mode-foundation.zip"
EXPECTED_PREFIX = "browser-fork-headed-mode-foundation/"
MINIMUM_HELPER_SURFACE: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved-browser-snapshot restore guide"),
    ("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md", "restored-checkout re-entry guide"),
    ("docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md", "saved-archive integrity guide"),
    ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
    ("scripts/check_issue3_saved_archive_integrity.py", "saved-archive integrity helper"),
    ("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper"),
    ("scripts/linux/restore_saved_browser_snapshot.sh", "saved-browser-snapshot restore helper"),
    ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved-browser-snapshot route printer"),
    ("scripts/linux/show_issue3_linux_build_readiness_route.sh", "Linux build-readiness route printer"),
    ("scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh", "runtime re-entry route printer"),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the saved issue #3 browser snapshot zip already carries "
            "the helper surface needed for restore, Linux build-readiness, and "
            "runtime re-entry follow-up work."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the live browser checkout root or workspace root (default: current directory)",
    )
    parser.add_argument(
        "--archive",
        default=None,
        help="Optional explicit path to the saved browser snapshot zip",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented output",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def resolve_default_archive(repo_root: Path) -> Path:
    repo_root = repo_root.resolve()
    workspace_root = repo_root.parent if (repo_root / "build.zig.zon").is_file() else repo_root
    return (workspace_root / "memory" / "repo_archives" / "browser" / DEFAULT_ARCHIVE_NAME).resolve()


def inspect_archive(archive_path: Path) -> dict[str, object]:
    result: dict[str, object] = {
        "archive_path": str(archive_path),
        "exists": archive_path.is_file(),
        "archive_readable": False,
        "expected_prefix": EXPECTED_PREFIX,
        "archive_top_level": None,
        "helper_surface_complete": False,
        "present_helper_paths": [],
        "missing_helper_paths": [],
        "recommended_restore_mode": "sync-helper-surface",
        "recommended_restore_flag": "--sync-helper-surface",
        "suggested_follow_up": "Use the synced restore path before Linux build-readiness or runtime re-entry work.",
        "archive_summary": None,
        "archive_error": None,
    }
    if not result["exists"]:
        result["archive_error"] = "saved browser snapshot archive is missing"
        return result

    try:
        with zipfile.ZipFile(archive_path) as archive:
            names = [name for name in archive.namelist() if name and not name.startswith("__MACOSX/")]
            bad_member = archive.testzip()
            if bad_member is not None:
                raise zipfile.BadZipFile(f"CRC failure in {bad_member}")
            if not names:
                raise ValueError("archive has no entries")

            top_level = names[0].split("/", 1)[0]
            if not top_level:
                raise ValueError("could not determine top-level folder")
            expected_prefix = f"{top_level}/"
            present = set(names)
            present_helper_paths: list[str] = []
            missing_helper_paths: list[str] = []
            for relative_path, _label in MINIMUM_HELPER_SURFACE:
                archive_member = f"{expected_prefix}{relative_path}"
                if archive_member in present:
                    present_helper_paths.append(relative_path)
                else:
                    missing_helper_paths.append(relative_path)

            helper_surface_complete = not missing_helper_paths
            result.update(
                {
                    "archive_readable": True,
                    "archive_top_level": top_level,
                    "expected_prefix": expected_prefix,
                    "helper_surface_complete": helper_surface_complete,
                    "present_helper_paths": present_helper_paths,
                    "missing_helper_paths": missing_helper_paths,
                    "archive_summary": f"zip entries={len(names)}; helper_paths_present={len(present_helper_paths)}; helper_paths_missing={len(missing_helper_paths)}",
                    "recommended_restore_mode": "plain-restore" if helper_surface_complete else "sync-helper-surface",
                    "recommended_restore_flag": "" if helper_surface_complete else "--sync-helper-surface",
                    "suggested_follow_up": (
                        "The archive already carries the minimum helper surface. A plain restore is enough unless the live helper root has moved ahead again."
                        if helper_surface_complete
                        else "The archive is missing current helper files. Prefer restore_saved_browser_snapshot.sh --sync-helper-surface or --sync-only before Linux build-readiness or runtime re-entry work."
                    ),
                }
            )
            return result
    except (zipfile.BadZipFile, OSError, ValueError) as exc:
        result["archive_error"] = str(exc)
        return result


def emit_text(result: dict[str, object]) -> None:
    archive_status = "PASS" if result["exists"] and result["archive_readable"] else "FAIL"
    print(f"Saved snapshot archive: [{archive_status}] {result['archive_path']}")
    if result["archive_top_level"]:
        print(f"Archive top level: {result['archive_top_level']}")
    if result["archive_summary"]:
        print(f"Archive summary: {result['archive_summary']}")
    if result["archive_error"]:
        print(f"Archive error: {result['archive_error']}")

    print("Minimum helper surface:")
    for relative_path, label in MINIMUM_HELPER_SURFACE:
        status = "PASS" if relative_path in result["present_helper_paths"] else "FAIL"
        print(f"  [{status}] {relative_path}: {label}")

    if result["helper_surface_complete"]:
        print("\nArchive helper-surface check passed.")
    else:
        print("\nArchive helper-surface check failed.", file=sys.stderr)

    print(f"Recommended restore mode: {result['recommended_restore_mode']}")
    if result["recommended_restore_flag"]:
        print(f"Recommended restore flag: {result['recommended_restore_flag']}")
    print(f"Suggested follow-up: {result['suggested_follow_up']}")


class SavedSnapshotHelperSurfaceTests(unittest.TestCase):
    def test_detects_complete_helper_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            archive_path = Path(tmpdir) / DEFAULT_ARCHIVE_NAME
            with zipfile.ZipFile(archive_path, "w") as archive:
                archive.writestr(f"{EXPECTED_PREFIX}build.zig.zon", "x")
                for relative_path, _label in MINIMUM_HELPER_SURFACE:
                    archive.writestr(f"{EXPECTED_PREFIX}{relative_path}", "x")

            result = inspect_archive(archive_path)

            self.assertTrue(result["archive_readable"])
            self.assertTrue(result["helper_surface_complete"])
            self.assertEqual(result["missing_helper_paths"], [])
            self.assertEqual(result["recommended_restore_mode"], "plain-restore")
            self.assertEqual(result["recommended_restore_flag"], "")

    def test_detects_missing_helper_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            archive_path = Path(tmpdir) / DEFAULT_ARCHIVE_NAME
            with zipfile.ZipFile(archive_path, "w") as archive:
                archive.writestr(f"{EXPECTED_PREFIX}build.zig.zon", "x")
                archive.writestr(f"{EXPECTED_PREFIX}README.md", "x")

            result = inspect_archive(archive_path)

            self.assertTrue(result["archive_readable"])
            self.assertFalse(result["helper_surface_complete"])
            self.assertIn(
                "scripts/linux/restore_saved_browser_snapshot.sh",
                result["missing_helper_paths"],
            )
            self.assertEqual(result["recommended_restore_mode"], "sync-helper-surface")
            self.assertEqual(result["recommended_restore_flag"], "--sync-helper-surface")

    def test_reports_missing_archive(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            archive_path = Path(tmpdir) / DEFAULT_ARCHIVE_NAME
            result = inspect_archive(archive_path)
            self.assertFalse(result["exists"])
            self.assertFalse(result["archive_readable"])
            self.assertEqual(result["archive_error"], "saved browser snapshot archive is missing")


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedSnapshotHelperSurfaceTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    archive_path = Path(args.archive).resolve() if args.archive else resolve_default_archive(repo_root)
    result = inspect_archive(archive_path)
    if args.json:
        print(json.dumps({"profile": "issue3-saved-snapshot-helper-surface", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["exists"] and result["archive_readable"] else 1


if __name__ == "__main__":
    sys.exit(main())
