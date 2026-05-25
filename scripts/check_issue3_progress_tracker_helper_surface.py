#!/usr/bin/env python3

"""Fail fast when issue #11 helper-surface files drift out of restore routes."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import tempfile
import unittest


RESTORE_SOURCES = (
    "scripts/check_issue3_saved_memory_inputs.py",
    "scripts/linux/restore_saved_browser_snapshot.sh",
)

EXPECTED_HELPER_PATHS = (
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
    "scripts/check_issue3_workspace_context.py",
    "scripts/check_issue3_saved_rust_archive_candidates.py",
    "scripts/check_issue3_staged_rust_toolchain_candidates.py",
    "scripts/check_issue3_saved_zig_archive_candidates.py",
    "scripts/check_issue3_staged_zig_toolchain_candidates.py",
    "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
    "scripts/linux/show_issue3_progress_tracker_route.sh",
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
    "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
    "scripts/linux/check_issue3_workspace_context_route_surface.sh",
    "scripts/linux/show_issue3_workspace_context_route.sh",
)


def collect_surface_status(repo_root: Path) -> dict[str, object]:
    files: list[dict[str, object]] = []
    missing_sources: list[str] = []
    missing_entries: dict[str, list[str]] = {}

    for relative_source in RESTORE_SOURCES:
        source_path = repo_root / relative_source
        if not source_path.is_file():
            missing_sources.append(relative_source)
            files.append(
                {
                    "path": relative_source,
                    "exists": False,
                    "missing_entries": list(EXPECTED_HELPER_PATHS),
                }
            )
            missing_entries[relative_source] = list(EXPECTED_HELPER_PATHS)
            continue

        text = source_path.read_text(encoding="utf-8")
        absent = [entry for entry in EXPECTED_HELPER_PATHS if entry not in text]
        files.append(
            {
                "path": relative_source,
                "exists": True,
                "missing_entries": absent,
            }
        )
        if absent:
            missing_entries[relative_source] = absent

    return {
        "status": "passed" if not missing_sources and not missing_entries else "failed",
        "repo_root": str(repo_root),
        "expected_helper_count": len(EXPECTED_HELPER_PATHS),
        "restore_source_count": len(RESTORE_SOURCES),
        "missing_sources": missing_sources,
        "missing_entries": missing_entries,
        "files": files,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that saved-checkout restore surfaces still carry the newer "
            "issue #11 progress-tracker helper set."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser repo root (default: current directory)",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON output")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


class ProgressTrackerHelperSurfaceTests(unittest.TestCase):
    def write_source(self, repo_root: Path, relative_path: str, entries: tuple[str, ...]) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("\n".join(entries) + "\n", encoding="utf-8")

    def test_passes_when_all_expected_entries_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            for relative_path in RESTORE_SOURCES:
                self.write_source(repo_root, relative_path, EXPECTED_HELPER_PATHS)

            result = collect_surface_status(repo_root)

            self.assertEqual(result["status"], "passed")
            self.assertEqual(result["missing_sources"], [])
            self.assertEqual(result["missing_entries"], {})

    def test_reports_missing_entries_per_source(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self.write_source(
                repo_root,
                RESTORE_SOURCES[0],
                EXPECTED_HELPER_PATHS[:-2],
            )
            self.write_source(repo_root, RESTORE_SOURCES[1], EXPECTED_HELPER_PATHS)

            result = collect_surface_status(repo_root)

            self.assertEqual(result["status"], "failed")
            missing_entries = result["missing_entries"]
            self.assertIn(RESTORE_SOURCES[0], missing_entries)
            self.assertEqual(
                missing_entries[RESTORE_SOURCES[0]],
                list(EXPECTED_HELPER_PATHS[-2:]),
            )

    def test_reports_missing_source_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self.write_source(repo_root, RESTORE_SOURCES[0], EXPECTED_HELPER_PATHS)

            result = collect_surface_status(repo_root)

            self.assertEqual(result["status"], "failed")
            self.assertEqual(result["missing_sources"], [RESTORE_SOURCES[1]])
            self.assertIn(RESTORE_SOURCES[1], result["missing_entries"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            ProgressTrackerHelperSurfaceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_surface_status(repo_root)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print("Issue #11 progress-tracker helper-surface check")
        print()
        print(f"Repo root: {result['repo_root']}")
        print(f"Restore sources: {result['restore_source_count']}")
        print(f"Expected helper entries: {result['expected_helper_count']}")
        for file_result in result["files"]:
            status = "PASS" if file_result["exists"] and not file_result["missing_entries"] else "FAIL"
            print()
            print(f"[{status}] {file_result['path']}")
            if not file_result["exists"]:
                print("  source file is missing")
                continue
            if file_result["missing_entries"]:
                for entry in file_result["missing_entries"]:
                    print(f"  missing: {entry}")
            else:
                print("  all expected helper entries are present")

    return 0 if result["status"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main())