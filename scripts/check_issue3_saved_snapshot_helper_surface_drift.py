#!/usr/bin/env python3

"""Check whether the saved browser snapshot archive lags the live helper surface.

This helper is for the blocked issue #3 re-entry path. It inspects the saved
repo snapshot zip and reports whether it already contains the current helper
files used by the Linux/WSL restore and runtime re-entry routes.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest
import zipfile


ARCHIVE_PREFIX = "browser-fork-headed-mode-foundation/"
DEFAULT_ARCHIVE_RELATIVE_PATH = "memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"

REQUIRED_HELPER_SURFACE_FILES: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry gate note"),
    ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved snapshot restore guide"),
    ("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md", "restored checkout guide"),
    ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
    ("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper"),
    (
        "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "saved-snapshot surface checker",
    ),
    (
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "saved-snapshot route printer",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the saved repo snapshot archive already contains the "
            "current issue #3 helper-surface files."
        )
    )
    parser.add_argument(
        "--archive",
        default=DEFAULT_ARCHIVE_RELATIVE_PATH,
        help=(
            "Path to the saved repo snapshot zip "
            f"(default: {DEFAULT_ARCHIVE_RELATIVE_PATH})"
        ),
    )
    parser.add_argument(
        "--archive-prefix",
        default=ARCHIVE_PREFIX,
        help=f"Archive member prefix for the browser checkout (default: {ARCHIVE_PREFIX})",
    )
    parser.add_argument(
        "--helper-root",
        default=None,
        help=(
            "Optional live helper checkout root. When provided, the helper files "
            "must also exist on disk there before they are counted as expected."
        ),
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


def collect_results(
    *,
    archive_path: Path,
    archive_prefix: str,
    helper_root: Path | None,
) -> dict[str, object]:
    result: dict[str, object] = {
        "ok": False,
        "archive_path": str(archive_path),
        "archive_prefix": archive_prefix,
        "helper_root": str(helper_root) if helper_root is not None else None,
        "archive_exists": archive_path.is_file(),
        "archive_readable": False,
        "archive_error": None,
        "checked_files": [],
        "missing_in_archive": [],
        "missing_in_helper_root": [],
        "archive_entry_count": None,
    }

    if not archive_path.is_file():
        result["archive_error"] = "archive not found"
        return result

    try:
        with zipfile.ZipFile(archive_path) as archive:
            names = set(archive.namelist())
            bad_member = archive.testzip()
            if bad_member is not None:
                raise zipfile.BadZipFile(f"CRC failure in {bad_member}")
            result["archive_readable"] = True
            result["archive_entry_count"] = len(names)

            missing_in_archive: list[str] = []
            missing_in_helper_root: list[str] = []
            checked_files: list[dict[str, object]] = []

            for relative_path, label in REQUIRED_HELPER_SURFACE_FILES:
                helper_root_exists = None
                expected_from_live_helper = True
                if helper_root is not None:
                    helper_root_exists = (helper_root / relative_path).is_file()
                    expected_from_live_helper = helper_root_exists
                    if not helper_root_exists:
                        missing_in_helper_root.append(relative_path)

                archive_member = f"{archive_prefix}{relative_path}"
                archive_exists = archive_member in names
                if expected_from_live_helper and not archive_exists:
                    missing_in_archive.append(relative_path)

                checked_files.append(
                    {
                        "relative_path": relative_path,
                        "label": label,
                        "archive_member": archive_member,
                        "archive_exists": archive_exists,
                        "helper_root_exists": helper_root_exists,
                        "expected_from_live_helper": expected_from_live_helper,
                    }
                )

            result["checked_files"] = checked_files
            result["missing_in_archive"] = missing_in_archive
            result["missing_in_helper_root"] = missing_in_helper_root
            result["ok"] = not missing_in_archive and not missing_in_helper_root
            return result
    except (OSError, zipfile.BadZipFile) as exc:
        result["archive_error"] = str(exc)
        return result


def emit_text(result: dict[str, object]) -> None:
    archive_status = "PASS" if result["archive_exists"] and result["archive_readable"] else "FAIL"
    print(f"Saved snapshot archive: [{archive_status}] {result['archive_path']}")
    print(f"Archive prefix: {result['archive_prefix']}")
    print(f"Helper root: {result['helper_root'] or 'not provided'}")
    if result["archive_error"]:
        print(f"Archive error: {result['archive_error']}")
    if result["archive_entry_count"] is not None:
        print(f"Archive entries: {result['archive_entry_count']}")

    print("Helper-surface coverage:")
    for entry in result["checked_files"]:
        if entry["helper_root_exists"] is False:
            status = "WARN"
        elif entry["archive_exists"]:
            status = "PASS"
        else:
            status = "FAIL"
        print(f"  [{status}] {entry['relative_path']}: {entry['label']}")
        if entry["helper_root_exists"] is False:
            print("         missing from helper root; this file was skipped as a live expectation")
        elif not entry["archive_exists"]:
            print("         missing from saved snapshot archive")

    if result["ok"]:
        print("\nSaved snapshot helper-surface check passed.")
        return

    print("\nSaved snapshot helper-surface check failed.", file=sys.stderr)
    if result["missing_in_archive"]:
        print(
            "Suggested next step: use the saved-browser-snapshot restore path with "
            "--sync-helper-surface before trusting the restored checkout for issue #3 re-entry.",
            file=sys.stderr,
        )
    elif result["missing_in_helper_root"]:
        print(
            "Suggested next step: point --helper-root at the live branch-local helper surface and rerun the check.",
            file=sys.stderr,
        )


class SavedSnapshotHelperSurfaceDriftTests(unittest.TestCase):
    def test_passes_when_archive_contains_expected_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            archive_path = root / "snapshot.zip"
            with zipfile.ZipFile(archive_path, "w") as archive:
                for relative_path, _label in REQUIRED_HELPER_SURFACE_FILES:
                    archive.writestr(f"{ARCHIVE_PREFIX}{relative_path}", "x")

            result = collect_results(
                archive_path=archive_path,
                archive_prefix=ARCHIVE_PREFIX,
                helper_root=None,
            )

            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_in_archive"], [])

    def test_fails_when_archive_lacks_current_helper_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            archive_path = root / "snapshot.zip"
            with zipfile.ZipFile(archive_path, "w") as archive:
                archive.writestr(f"{ARCHIVE_PREFIX}build.zig", "x")

            result = collect_results(
                archive_path=archive_path,
                archive_prefix=ARCHIVE_PREFIX,
                helper_root=None,
            )

            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/check_issue3_saved_memory_inputs.py",
                result["missing_in_archive"],
            )

    def test_helper_root_filters_live_expectations(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "browser"
            helper_root.mkdir()
            archive_path = root / "snapshot.zip"

            first_relative_path, _label = REQUIRED_HELPER_SURFACE_FILES[0]
            (helper_root / first_relative_path).parent.mkdir(parents=True, exist_ok=True)
            (helper_root / first_relative_path).write_text("x", encoding="utf-8")

            with zipfile.ZipFile(archive_path, "w") as archive:
                archive.writestr(f"{ARCHIVE_PREFIX}{first_relative_path}", "x")

            result = collect_results(
                archive_path=archive_path,
                archive_prefix=ARCHIVE_PREFIX,
                helper_root=helper_root,
            )

            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/check_issue3_saved_memory_inputs.py",
                result["missing_in_helper_root"],
            )
            self.assertEqual(result["missing_in_archive"], [])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedSnapshotHelperSurfaceDriftTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    helper_root = Path(args.helper_root).resolve() if args.helper_root else None
    result = collect_results(
        archive_path=Path(args.archive).resolve(),
        archive_prefix=args.archive_prefix,
        helper_root=helper_root,
    )
    if args.json:
        print(
            json.dumps(
                {"profile": "issue3-saved-snapshot-helper-surface-drift", **result},
                indent=2,
            )
        )
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
