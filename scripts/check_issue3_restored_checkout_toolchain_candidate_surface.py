#!/usr/bin/env python3

"""Check whether a restored checkout carries the issue #11 toolchain-helper surface.

Use this after restoring the saved browser snapshot when a future Linux or WSL
run wants to trust the restored checkout as a self-contained helper root for the
issue #11 Rust and Zig re-entry routes.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"
REQUIRED_REPO_ROOT_FILE = "build.zig.zon"
REQUIRED_TOOLCHAIN_HELPER_FILES: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "issue #11 progress-tracker guide"),
    ("docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md", "saved Rust toolchain guide"),
    ("docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md", "saved Zig archive candidate guide"),
    ("docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md", "saved Zig archive restore guide"),
    ("scripts/check_issue3_saved_rust_archive_candidates.py", "saved Rust archive candidate helper"),
    ("scripts/check_issue3_staged_rust_toolchain_candidates.py", "staged Rust toolchain candidate helper"),
    ("scripts/check_issue3_saved_zig_archive_candidates.py", "saved Zig archive candidate helper"),
    ("scripts/check_issue3_staged_zig_toolchain_candidates.py", "staged Zig toolchain candidate helper"),
    ("scripts/linux/check_issue3_progress_tracker_route_surface.sh", "issue #11 progress-tracker surface checker"),
    ("scripts/linux/show_issue3_progress_tracker_route.sh", "issue #11 progress-tracker route helper"),
    ("scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh", "saved Rust route surface checker"),
    ("scripts/linux/show_issue3_saved_rust_toolchain_route.sh", "saved Rust route helper"),
    ("scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh", "saved Zig route surface checker"),
    ("scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh", "saved Zig route helper"),
    ("scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh", "saved Zig restore surface checker"),
    ("scripts/linux/check_issue3_zig_toolchain_match.sh", "staged Zig matching-line checker"),
)


def collect_results(repo_root: Path) -> dict[str, object]:
    exists = repo_root.is_dir()
    build_manifest = repo_root / REQUIRED_REPO_ROOT_FILE
    has_build_manifest = build_manifest.is_file()

    helper_files = []
    missing_paths: list[str] = []
    for relative_path, label in REQUIRED_TOOLCHAIN_HELPER_FILES:
        target = repo_root / relative_path
        present = target.is_file()
        helper_files.append(
            {
                "relative_path": relative_path,
                "label": label,
                "path": str(target),
                "exists": present,
            }
        )
        if not present:
            missing_paths.append(relative_path)

    if not exists:
        status = "missing"
    elif not has_build_manifest:
        status = "missing-build-manifest"
    elif missing_paths:
        status = "incomplete-toolchain-helper-surface"
    else:
        status = "ready"

    return {
        "status": status,
        "repo_root": str(repo_root),
        "required_repo_root_file": REQUIRED_REPO_ROOT_FILE,
        "has_build_manifest": has_build_manifest,
        "helper_files": helper_files,
        "missing_paths": missing_paths,
        "ok": status == "ready",
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #11 restored-checkout toolchain helper surface")
    print()
    print(f"Repo root: {result['repo_root']}")
    print(
        "Build manifest: "
        f"{'present' if result['has_build_manifest'] else 'missing'} "
        f"({result['required_repo_root_file']})"
    )
    print()
    print("Required helper files:")
    for entry in result["helper_files"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['relative_path']}: {entry['label']}")

    if result["ok"]:
        print()
        print("Restored checkout toolchain-helper surface is ready.")
        return

    print()
    print("Restored checkout toolchain-helper surface is incomplete.", file=sys.stderr)
    if result["status"] == "missing":
        print(
            f"Suggested next step: restore {DEFAULT_RESTORED_CHECKOUT_NAME} before trusting it as a helper root.",
            file=sys.stderr,
        )
    elif result["status"] == "missing-build-manifest":
        print(
            f"Suggested next step: point --repo-root at a real browser checkout that contains {REQUIRED_REPO_ROOT_FILE}.",
            file=sys.stderr,
        )
    else:
        joined = ", ".join(result["missing_paths"])
        print(f"Missing helper paths: {joined}", file=sys.stderr)
        print(
            "Suggested next step: rerun scripts/linux/restore_saved_browser_snapshot.sh with --sync-helper-surface, "
            "or refresh the existing restored checkout with --sync-only from a live helper checkout before using the restored checkout as the issue #11 helper root.",
            file=sys.stderr,
        )


class RestoredCheckoutToolchainHelperSurfaceTests(unittest.TestCase):
    def test_collect_results_passes_when_surface_is_complete(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / DEFAULT_RESTORED_CHECKOUT_NAME
            repo_root.mkdir()
            (repo_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            for relative_path, _label in REQUIRED_TOOLCHAIN_HELPER_FILES:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("pass", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertEqual(result["status"], "ready")
            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_paths"], [])

    def test_collect_results_reports_missing_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / DEFAULT_RESTORED_CHECKOUT_NAME
            repo_root.mkdir()
            (repo_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            for relative_path, _label in REQUIRED_TOOLCHAIN_HELPER_FILES:
                if relative_path in {
                    "scripts/check_issue3_saved_rust_archive_candidates.py",
                    "scripts/check_issue3_staged_zig_toolchain_candidates.py",
                }:
                    continue
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("pass", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertEqual(result["status"], "incomplete-toolchain-helper-surface")
            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/check_issue3_saved_rust_archive_candidates.py",
                result["missing_paths"],
            )
            self.assertIn(
                "scripts/check_issue3_staged_zig_toolchain_candidates.py",
                result["missing_paths"],
            )

    def test_collect_results_requires_build_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / DEFAULT_RESTORED_CHECKOUT_NAME
            repo_root.mkdir()

            result = collect_results(repo_root)

            self.assertEqual(result["status"], "missing-build-manifest")
            self.assertFalse(result["ok"])


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Check whether a restored checkout carries the issue #11 toolchain-helper surface."
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the restored or live browser checkout root (default: current directory)",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON output")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            RestoredCheckoutToolchainHelperSurfaceTests
        )
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
