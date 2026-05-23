#!/usr/bin/env python3

"""Check whether a restored issue #3 checkout has the current helper surface."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"
SYNCED_HELPER_PATHS: tuple[str, ...] = (
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
    "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
    "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md",
    "scripts/check_issue3_saved_memory_inputs.py",
    "scripts/check_linux_build_readiness.py",
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
    "scripts/linux/restore_saved_browser_snapshot.sh",
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh",
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
    "scripts/linux/restore_saved_rust_toolchain.sh",
    "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
    "scripts/linux/show_issue3_offline_build_inputs_route.sh",
    "scripts/linux/prepare_offline_build_inputs.sh",
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh",
    "scripts/windows/HeadedValidationHelpers.ps1",
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
    "scripts/windows/show_headed_validation_suites.ps1",
    "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
    "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
    "src/browser/tests/page/google_home_title_probe.html",
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether a restored browser-memory-snapshot checkout still "
            "needs helper-surface sync before issue #3 Linux/WSL recovery work."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the current live browser checkout (default: current directory)",
    )
    parser.add_argument(
        "--restored-checkout-root",
        default=None,
        help=(
            "Path to the restored snapshot checkout "
            "(default: ../browser-memory-snapshot beside the live checkout)"
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


def resolve_default_restored_checkout_root(repo_root: Path) -> Path:
    return (repo_root.parent / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()


def collect_result(repo_root: Path, restored_checkout_root: Path) -> dict[str, object]:
    exists = restored_checkout_root.is_dir()
    build_manifest_path = restored_checkout_root / "build.zig.zon"
    build_manifest_exists = build_manifest_path.is_file()

    helper_rows: list[dict[str, object]] = []
    missing_helper_paths: list[str] = []
    present_helper_count = 0

    for relative_path in SYNCED_HELPER_PATHS:
        full_path = restored_checkout_root / relative_path
        present = full_path.is_file()
        helper_rows.append({"path": relative_path, "present": present})
        if present:
            present_helper_count += 1
        else:
            missing_helper_paths.append(relative_path)

    if not exists:
        status = "missing"
        recommendation = (
            "Run scripts/linux/restore_saved_browser_snapshot.sh before Linux or WSL "
            "re-entry work."
        )
    elif not build_manifest_exists:
        status = "incomplete"
        recommendation = (
            "Rebuild the restored checkout from the saved snapshot before trusting it "
            "for build-readiness or runtime re-entry work."
        )
    elif present_helper_count == 0:
        status = "snapshot-only"
        recommendation = (
            "Rerun scripts/linux/restore_saved_browser_snapshot.sh "
            "--sync-helper-surface so the restored checkout carries the newer "
            "issue #3 helper docs and scripts."
        )
    elif present_helper_count == len(SYNCED_HELPER_PATHS):
        status = "synced"
        recommendation = (
            "The restored checkout already carries the tracked helper surface and is "
            "ready for the saved-memory preflight and Linux/WSL route helpers."
        )
    else:
        status = "partially-synced"
        recommendation = (
            "Refresh the restored checkout with "
            "scripts/linux/restore_saved_browser_snapshot.sh --sync-helper-surface "
            "before relying on branch-local helper routes inside it."
        )

    return {
        "repo_root": str(repo_root),
        "restored_checkout_root": str(restored_checkout_root),
        "status": status,
        "build_manifest_exists": build_manifest_exists,
        "synced_helper_path_count": len(SYNCED_HELPER_PATHS),
        "present_helper_path_count": present_helper_count,
        "missing_helper_paths": missing_helper_paths,
        "helper_paths": helper_rows,
        "recommendation": recommendation,
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #3 restored checkout helper-surface check")
    print()
    print(f"Live repo root:        {result['repo_root']}")
    print(f"Restored checkout:     {result['restored_checkout_root']}")
    print(f"Status:                {result['status']}")
    print(
        "Build manifest:        "
        f"{'yes' if result['build_manifest_exists'] else 'no'}"
    )
    print(
        "Tracked helper paths:  "
        f"{result['present_helper_path_count']}/{result['synced_helper_path_count']}"
    )
    if result["missing_helper_paths"]:
        print("Missing helper paths:")
        for relative_path in result["missing_helper_paths"]:
            print(f"  - {relative_path}")
    print()
    print(f"Recommendation: {result['recommendation']}")


class RestoredCheckoutSurfaceTests(unittest.TestCase):
    def test_missing_checkout_reports_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            result = collect_result(repo_root, resolve_default_restored_checkout_root(repo_root))
            self.assertEqual(result["status"], "missing")

    def test_snapshot_only_reports_missing_helper_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            restored = root / DEFAULT_RESTORED_CHECKOUT_NAME
            repo_root.mkdir()
            restored.mkdir()
            (restored / "build.zig.zon").write_text("{}", encoding="utf-8")

            result = collect_result(repo_root, restored)
            self.assertEqual(result["status"], "snapshot-only")
            self.assertEqual(result["present_helper_path_count"], 0)

    def test_partially_synced_checkout_reports_missing_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            restored = root / DEFAULT_RESTORED_CHECKOUT_NAME
            repo_root.mkdir()
            restored.mkdir()
            (restored / "build.zig.zon").write_text("{}", encoding="utf-8")
            for relative_path in SYNCED_HELPER_PATHS[:2]:
                target = restored / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("x", encoding="utf-8")

            result = collect_result(repo_root, restored)
            self.assertEqual(result["status"], "partially-synced")
            self.assertEqual(result["present_helper_path_count"], 2)
            self.assertIn(SYNCED_HELPER_PATHS[2], result["missing_helper_paths"])

    def test_synced_checkout_reports_ready(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            restored = root / DEFAULT_RESTORED_CHECKOUT_NAME
            repo_root.mkdir()
            restored.mkdir()
            (restored / "build.zig.zon").write_text("{}", encoding="utf-8")
            for relative_path in SYNCED_HELPER_PATHS:
                target = restored / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("x", encoding="utf-8")

            result = collect_result(repo_root, restored)
            self.assertEqual(result["status"], "synced")
            self.assertEqual(result["present_helper_path_count"], len(SYNCED_HELPER_PATHS))


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(RestoredCheckoutSurfaceTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    restored_checkout_root = (
        Path(args.restored_checkout_root).resolve()
        if args.restored_checkout_root
        else resolve_default_restored_checkout_root(repo_root)
    )
    result = collect_result(repo_root, restored_checkout_root)
    if args.json:
        print(json.dumps({"profile": "issue3-restored-checkout-surface", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["status"] == "synced" else 1


if __name__ == "__main__":
    sys.exit(main())
