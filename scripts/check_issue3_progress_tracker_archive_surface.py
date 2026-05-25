#!/usr/bin/env python3

"""Inspect the saved browser snapshot archive for issue #11 progress-tracker drift."""

from __future__ import annotations

import argparse
import json
import os
from dataclasses import asdict, dataclass
from pathlib import Path
import tempfile
import unittest
import zipfile


DEFAULT_ARCHIVE_NAME = "01-browser-fork-headed-mode-foundation.zip"
EXPECTED_ARCHIVE_PREFIX = "browser-fork-headed-mode-foundation/"
RESTORE_HELPER_HINT = "scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface"
REQUIRED_PROGRESS_TRACKER_PATHS = (
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "Issue #11 progress-tracker note that scheduled Linux or WSL re-entry runs should keep nearby.",
    ),
    (
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "Runtime gate note that explains when issue #11 should stay active instead of reopening the direct runtime patch.",
    ),
    (
        "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
        "Saved-Memory route note that should keep the issue #11 handoff visible during environment-gated reruns.",
    ),
    (
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "Linux or WSL build-readiness route note that should keep the issue #11 tracker visible.",
    ),
    (
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "Zig recovery route note that should stay nearby while issue #11 owns the lower-volume status lane.",
    ),
    (
        "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
        "Fail-fast surface checker for the issue #11 progress-tracker route.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "Compact route printer for the issue #11 progress-tracker handoff.",
    ),
)


@dataclass
class PathStatus:
    path: str
    present: bool
    purpose: str


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the saved browser snapshot archive already contains "
            "the issue #11 progress-tracker route surface."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=os.getcwd(),
        help="Live browser repo root used to infer the default Memory location.",
    )
    parser.add_argument(
        "--memory-root",
        help="Override the default Memory root (<repo-root>/../memory).",
    )
    parser.add_argument(
        "--archive",
        help="Override the saved snapshot archive path.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print a JSON summary instead of the human-readable surface.",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit.",
    )
    return parser


def resolve_memory_root(repo_root: Path, explicit_memory_root: str | None) -> Path:
    if explicit_memory_root:
        return Path(explicit_memory_root).resolve()
    return (repo_root.parent / "memory").resolve()


def resolve_archive_path(args: argparse.Namespace) -> Path:
    if args.archive:
        return Path(args.archive).resolve()
    repo_root = Path(args.repo_root).resolve()
    memory_root = resolve_memory_root(repo_root, args.memory_root)
    return (memory_root / "repo_archives" / "browser" / DEFAULT_ARCHIVE_NAME).resolve()


def inspect_archive(archive_path: Path) -> dict[str, object]:
    if not archive_path.is_file():
        return {
            "ok": False,
            "archive_path": str(archive_path),
            "archive_exists": False,
            "archive_prefix": EXPECTED_ARCHIVE_PREFIX,
            "checked_paths": [],
            "missing_paths": [path for path, _purpose in REQUIRED_PROGRESS_TRACKER_PATHS],
            "suggested_next_step": (
                "Restore or resurface the saved snapshot archive before trusting the issue #11 progress-tracker route."
            ),
        }

    with zipfile.ZipFile(archive_path) as archive:
        names = set(archive.namelist())
        prefix_present = any(name.startswith(EXPECTED_ARCHIVE_PREFIX) for name in names)
        statuses = [
            PathStatus(
                path=relative_path,
                present=f"{EXPECTED_ARCHIVE_PREFIX}{relative_path}" in names,
                purpose=purpose,
            )
            for relative_path, purpose in REQUIRED_PROGRESS_TRACKER_PATHS
        ]

    missing_paths = [status.path for status in statuses if not status.present]
    ok = prefix_present and not missing_paths
    if ok:
        suggested_next_step = (
            "The saved snapshot already carries the issue #11 progress-tracker route surface."
        )
    else:
        suggested_next_step = (
            "Use "
            + RESTORE_HELPER_HINT
            + " so the restored checkout inherits the live issue #11 progress-tracker route files before reuse."
        )

    return {
        "ok": ok,
        "archive_path": str(archive_path),
        "archive_exists": True,
        "archive_prefix": EXPECTED_ARCHIVE_PREFIX,
        "checked_paths": [asdict(status) for status in statuses],
        "missing_paths": missing_paths,
        "suggested_next_step": suggested_next_step,
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #11 progress-tracker archive surface")
    print()
    print(f"Archive: {result['archive_path']}")
    print(f"Top-level prefix: {result['archive_prefix']}")
    if not result["archive_exists"]:
        print()
        print("Saved snapshot archive is missing.")
        print(result["suggested_next_step"])
        return

    for entry in result["checked_paths"]:
        status = "PASS" if entry["present"] else "FAIL"
        print(f"[{status}] {entry['path']}")
        print(f"  {entry['purpose']}")

    print()
    if result["ok"]:
        print("Progress-tracker archive surface is present.")
    else:
        print("Progress-tracker archive surface is missing paths.")
    print(result["suggested_next_step"])


class ProgressTrackerArchiveSurfaceTests(unittest.TestCase):
    def build_archive(self, root: Path, included_paths: list[str]) -> Path:
        archive_path = root / DEFAULT_ARCHIVE_NAME
        with zipfile.ZipFile(archive_path, "w") as archive:
            archive.writestr(f"{EXPECTED_ARCHIVE_PREFIX}README.md", "snapshot")
            for relative_path in included_paths:
                archive.writestr(f"{EXPECTED_ARCHIVE_PREFIX}{relative_path}", "present")
        return archive_path

    def test_missing_archive_fails_cleanly(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            archive_path = Path(tmpdir) / DEFAULT_ARCHIVE_NAME
            result = inspect_archive(archive_path)

            self.assertFalse(result["ok"])
            self.assertFalse(result["archive_exists"])
            self.assertEqual(
                result["missing_paths"],
                [path for path, _purpose in REQUIRED_PROGRESS_TRACKER_PATHS],
            )

    def test_full_surface_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            archive_path = self.build_archive(
                Path(tmpdir),
                [path for path, _purpose in REQUIRED_PROGRESS_TRACKER_PATHS],
            )
            result = inspect_archive(archive_path)

            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_paths"], [])

    def test_missing_route_file_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            required_paths = [path for path, _purpose in REQUIRED_PROGRESS_TRACKER_PATHS]
            archive_path = self.build_archive(Path(tmpdir), required_paths[:-1])
            result = inspect_archive(archive_path)

            self.assertFalse(result["ok"])
            self.assertEqual(
                result["missing_paths"],
                ["scripts/linux/show_issue3_progress_tracker_route.sh"],
            )
            self.assertIn(RESTORE_HELPER_HINT, result["suggested_next_step"])


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            ProgressTrackerArchiveSurfaceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    archive_path = resolve_archive_path(args)
    result = inspect_archive(archive_path)
    if args.json:
        print(
            json.dumps(
                {"profile": "issue11-progress-tracker-archive-surface", **result},
                indent=2,
            )
        )
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
