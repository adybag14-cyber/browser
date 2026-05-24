#!/usr/bin/env python3

"""Check whether a restored checkout carries the route-critical helper surface.

This helper focuses on the small set of restore and route files that a synced
issue #3 checkout needs before Linux or WSL recovery helpers can honestly reuse
that checkout as a self-contained follow-up root.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"

REQUIRED_SURFACE_FILES: tuple[tuple[str, str], ...] = (
    ("build.zig.zon", "restored checkout build manifest"),
    (
        "scripts/check_issue3_saved_memory_inputs.py",
        "saved-memory preflight helper",
    ),
    (
        "scripts/check_issue3_saved_archive_integrity.py",
        "saved-archive integrity helper",
    ),
    (
        "scripts/check_linux_build_readiness.py",
        "Linux build-readiness helper",
    ),
    (
        "scripts/linux/restore_saved_browser_snapshot.sh",
        "saved-browser-snapshot restore helper",
    ),
    (
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "saved-browser-snapshot route helper",
    ),
    (
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "Linux build-readiness route helper",
    ),
    (
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
        "runtime re-entry route helper",
    ),
    (
        "scripts/linux/restore_saved_rust_toolchain.sh",
        "saved Rust toolchain restore helper",
    ),
    (
        "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
        "fallback Zig restore helper",
    ),
    (
        "scripts/linux/restore_zig_toolchain_archive.sh",
        "generic Zig archive restore helper",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether a restored issue #3 checkout includes the helper "
            "surface needed for self-contained Linux or WSL follow-up routes."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--restored-checkout-root",
        default=None,
        help=(
            "Optional explicit restored checkout path "
            "(default: ../browser-memory-snapshot beside the repo root)"
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
    if (repo_root / "build.zig.zon").is_file():
        return (repo_root.parent / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()
    return (repo_root / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()


def collect_results(*, repo_root: Path, restored_checkout_root: Path) -> dict[str, object]:
    file_entries = []
    missing_paths: list[str] = []
    for relative_path, label in REQUIRED_SURFACE_FILES:
        candidate = restored_checkout_root / relative_path
        exists = candidate.is_file()
        if not exists:
            missing_paths.append(relative_path)
        file_entries.append(
            {
                "label": label,
                "relative_path": relative_path,
                "path": str(candidate),
                "exists": exists,
            }
        )

    restored_exists = restored_checkout_root.is_dir()
    has_build_manifest = (restored_checkout_root / "build.zig.zon").is_file()
    helper_surface_ok = restored_exists and not missing_paths
    if not restored_exists:
        status = "missing"
    elif helper_surface_ok:
        status = "ready"
    else:
        status = "incomplete-helper-surface"

    return {
        "ok": helper_surface_ok,
        "repo_root": str(repo_root),
        "restored_checkout_root": str(restored_checkout_root),
        "restored_checkout_exists": restored_exists,
        "has_build_manifest": has_build_manifest,
        "status": status,
        "required_files": file_entries,
        "missing_paths": missing_paths,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Restored checkout: {result['restored_checkout_root']}")
    print(f"Status: {result['status']}")
    print("Required helper surface:")
    for entry in result["required_files"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['label']}: {entry['relative_path']}")
    if result["ok"]:
        print("\nRestored checkout helper surface check passed.")
    else:
        print("\nRestored checkout helper surface check failed.", file=sys.stderr)
        if result["missing_paths"]:
            print(
                "Suggested next step: restore the snapshot with "
                "--sync-helper-surface or refresh the missing helper files "
                "before trusting the restored checkout as the next route root.",
                file=sys.stderr,
            )


class RestoredCheckoutHelperSurfaceTests(unittest.TestCase):
    def test_ready_checkout_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            restored = Path(tmpdir) / DEFAULT_RESTORED_CHECKOUT_NAME
            repo_root.mkdir()
            restored.mkdir()
            for relative_path, _label in REQUIRED_SURFACE_FILES:
                target = restored / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                restored_checkout_root=restored,
            )

            self.assertTrue(result["ok"])
            self.assertEqual(result["status"], "ready")
            self.assertEqual(result["missing_paths"], [])

    def test_missing_restore_scripts_fail_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            restored = Path(tmpdir) / DEFAULT_RESTORED_CHECKOUT_NAME
            repo_root.mkdir()
            restored.mkdir()
            for relative_path, _label in REQUIRED_SURFACE_FILES:
                if relative_path in {
                    "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
                    "scripts/linux/restore_zig_toolchain_archive.sh",
                }:
                    continue
                target = restored / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                restored_checkout_root=restored,
            )

            self.assertFalse(result["ok"])
            self.assertEqual(result["status"], "incomplete-helper-surface")
            self.assertIn(
                "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
                result["missing_paths"],
            )
            self.assertIn(
                "scripts/linux/restore_zig_toolchain_archive.sh",
                result["missing_paths"],
            )

    def test_missing_checkout_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            restored = Path(tmpdir) / DEFAULT_RESTORED_CHECKOUT_NAME

            result = collect_results(
                repo_root=repo_root,
                restored_checkout_root=restored,
            )

            self.assertFalse(result["ok"])
            self.assertEqual(result["status"], "missing")
            self.assertFalse(result["restored_checkout_exists"])

    def test_default_root_resolution_handles_repo_and_workspace_layouts(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            (repo_root / "build.zig.zon").write_text("{}", encoding="utf-8")
            self.assertEqual(
                resolve_default_restored_checkout_root(repo_root),
                Path(tmpdir) / DEFAULT_RESTORED_CHECKOUT_NAME,
            )

            workspace_root = Path(tmpdir) / "workspace"
            workspace_root.mkdir()
            self.assertEqual(
                resolve_default_restored_checkout_root(workspace_root),
                workspace_root / DEFAULT_RESTORED_CHECKOUT_NAME,
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            RestoredCheckoutHelperSurfaceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    restored_checkout_root = (
        Path(args.restored_checkout_root).resolve()
        if args.restored_checkout_root
        else resolve_default_restored_checkout_root(repo_root)
    )
    result = collect_results(
        repo_root=repo_root,
        restored_checkout_root=restored_checkout_root,
    )
    if args.json:
        print(
            json.dumps(
                {"profile": "issue3-restored-checkout-helper-surface", **result},
                indent=2,
            )
        )
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
