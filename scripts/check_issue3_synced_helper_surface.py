#!/usr/bin/env python3

"""Check whether a restored checkout has the synced issue #3 helper surface."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import tempfile
import unittest


SYNCED_HELPER_SURFACE_FILES: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry gate note"),
    ("docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md", "runtime revalidation note"),
    ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved browser snapshot route note"),
    ("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness route note"),
    ("docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md", "Zig toolchain recovery route note"),
    ("docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md", "Zig archive restore route note"),
    ("docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md", "offline build-inputs route note"),
    ("docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md", "saved Rust toolchain route note"),
    ("scripts/check_issue3_saved_memory_inputs.py", "saved Memory input preflight helper"),
    ("scripts/check_linux_build_readiness.py", "Linux build-readiness helper"),
    ("scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh", "saved-browser-snapshot surface checker"),
    ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved-browser-snapshot route printer"),
    ("scripts/linux/restore_saved_browser_snapshot.sh", "saved-browser-snapshot restore helper"),
    ("scripts/linux/check_issue3_linux_build_readiness_route_surface.sh", "Linux build-readiness surface checker"),
    ("scripts/linux/show_issue3_linux_build_readiness_route.sh", "Linux build-readiness route printer"),
    ("scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh", "runtime revalidation surface checker"),
    ("scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh", "runtime revalidation route printer"),
    ("scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh", "Zig recovery surface checker"),
    ("scripts/linux/show_issue3_zig_toolchain_recovery_route.sh", "Zig recovery route printer"),
    ("scripts/linux/restore_issue3_fallback_zig_toolchain.sh", "fallback Zig restore helper"),
    ("scripts/linux/restore_zig_toolchain_archive.sh", "generic Zig archive restore helper"),
    ("scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh", "saved Rust surface checker"),
    ("scripts/linux/show_issue3_saved_rust_toolchain_route.sh", "saved Rust route printer"),
    ("scripts/linux/restore_saved_rust_toolchain.sh", "saved Rust restore helper"),
    ("scripts/linux/check_issue3_offline_build_inputs_route_surface.sh", "offline build-inputs surface checker"),
    ("scripts/linux/show_issue3_offline_build_inputs_route.sh", "offline build-inputs route printer"),
    ("scripts/linux/prepare_offline_build_inputs.sh", "offline build-inputs restore helper"),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that a restored checkout already carries the full synced "
            "issue #3 helper surface before Linux/WSL recovery relies on it."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the restored browser checkout root (default: current directory)",
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


def collect_results(repo_root: Path) -> dict[str, object]:
    build_manifest = repo_root / "build.zig.zon"
    entries = []
    missing_paths: list[str] = []
    for relative_path, label in SYNCED_HELPER_SURFACE_FILES:
        full_path = repo_root / relative_path
        exists = full_path.is_file()
        entries.append(
            {
                "label": label,
                "path": str(full_path),
                "relative_path": relative_path,
                "exists": exists,
            }
        )
        if not exists:
            missing_paths.append(relative_path)

    ok = build_manifest.is_file() and not missing_paths
    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "build_manifest": {
            "path": str(build_manifest),
            "exists": build_manifest.is_file(),
        },
        "expected_file_count": len(SYNCED_HELPER_SURFACE_FILES),
        "helper_surface_files": entries,
        "missing_helper_surface_files": missing_paths,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    build_manifest = result["build_manifest"]
    build_status = "PASS" if build_manifest["exists"] else "FAIL"
    print(f"Build manifest: [{build_status}] {build_manifest['path']}")
    print("Synced helper surface:")
    for entry in result["helper_surface_files"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['relative_path']}")
        print(f"         {entry['label']}")
    if result["ok"]:
        print("\nIssue #3 synced helper surface check passed.")
    else:
        missing = ", ".join(result["missing_helper_surface_files"]) or "build.zig.zon"
        print("\nIssue #3 synced helper surface check failed.")
        print(f"Missing surface files: {missing}")


class SyncedHelperSurfaceTests(unittest.TestCase):
    def test_collect_results_passes_when_all_surface_files_exist(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            (repo_root / "build.zig.zon").write_text("{}", encoding="utf-8")
            for relative_path, _label in SYNCED_HELPER_SURFACE_FILES:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("x", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_helper_surface_files"], [])
            self.assertEqual(result["expected_file_count"], len(SYNCED_HELPER_SURFACE_FILES))

    def test_collect_results_fails_when_helper_file_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            (repo_root / "build.zig.zon").write_text("{}", encoding="utf-8")
            for relative_path, _label in SYNCED_HELPER_SURFACE_FILES[1:]:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("x", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertEqual(
                result["missing_helper_surface_files"],
                [SYNCED_HELPER_SURFACE_FILES[0][0]],
            )

    def test_collect_results_fails_when_build_manifest_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            for relative_path, _label in SYNCED_HELPER_SURFACE_FILES:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("x", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertTrue(result["build_manifest"]["path"].endswith("build.zig.zon"))


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SyncedHelperSurfaceTests)
        outcome = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if outcome.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
