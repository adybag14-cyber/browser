#!/usr/bin/env python3

"""Check whether a restored browser snapshot checkout is ready for follow-up.

This helper keeps the saved-browser-snapshot route honest after extraction:
- verifies the restored checkout still looks like a browser repo
- optionally requires the issue #3 helper surface to exist inside that checkout
- optionally compares synced helper files against a live helper root to detect drift
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest


RESTORED_CHECKOUT_PATHS: tuple[tuple[str, str], ...] = (
    ("build.zig", "top-level build entrypoint"),
    ("build.zig.zon", "dependency manifest"),
    ("docs/HEADED_MODE_ROADMAP.md", "headed-mode roadmap"),
    ("docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md", "headed-mode production guide"),
    ("src/browser/Page.zig", "page runtime surface"),
    ("src/display/win32_backend.zig", "Win32 backend runtime surface"),
)

HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry gate note"),
    ("docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md", "runtime revalidation note"),
    ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved snapshot restore note"),
    ("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md", "restored-checkout re-entry note"),
    ("docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md", "saved-archive integrity note"),
    ("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness note"),
    ("docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md", "Zig toolchain recovery note"),
    ("docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md", "Zig toolchain archive restore note"),
    ("docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md", "offline build-inputs note"),
    ("docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md", "saved Rust toolchain note"),
    ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
    ("scripts/check_issue3_saved_archive_integrity.py", "saved-archive integrity helper"),
    ("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper"),
    ("scripts/check_linux_build_readiness.py", "Linux build-readiness checker"),
    ("scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh", "saved-archive integrity surface check"),
    ("scripts/linux/show_issue3_saved_archive_integrity_route.sh", "saved-archive integrity route printer"),
    ("scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh", "saved snapshot surface check"),
    ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved snapshot route printer"),
    ("scripts/linux/restore_saved_browser_snapshot.sh", "saved snapshot restore helper"),
    ("scripts/linux/check_issue3_linux_build_readiness_route_surface.sh", "Linux build-readiness surface check"),
    ("scripts/linux/show_issue3_linux_build_readiness_route.sh", "Linux build-readiness route printer"),
    ("scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh", "runtime revalidation surface check"),
    ("scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh", "runtime revalidation route printer"),
    ("scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh", "Zig toolchain recovery surface check"),
    ("scripts/linux/show_issue3_zig_toolchain_recovery_route.sh", "Zig toolchain recovery route printer"),
    ("scripts/linux/restore_issue3_fallback_zig_toolchain.sh", "fallback Zig restore helper"),
    ("scripts/linux/restore_zig_toolchain_archive.sh", "saved Zig archive restore helper"),
    ("scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh", "saved Rust route surface check"),
    ("scripts/linux/show_issue3_saved_rust_toolchain_route.sh", "saved Rust route printer"),
    ("scripts/linux/restore_saved_rust_toolchain.sh", "saved Rust restore helper"),
    ("scripts/linux/check_issue3_offline_build_inputs_route_surface.sh", "offline inputs surface check"),
    ("scripts/linux/show_issue3_offline_build_inputs_route.sh", "offline inputs route printer"),
    ("scripts/linux/prepare_offline_build_inputs.sh", "offline inputs restore helper"),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether a restored browser snapshot checkout is ready for "
            "issue #3 Linux/WSL follow-up work."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the restored browser checkout (default: current directory)",
    )
    parser.add_argument(
        "--helper-root",
        default=None,
        help=(
            "Optional live helper checkout to compare helper-surface files "
            "against when the restored checkout was synced with --sync-helper-surface"
        ),
    )
    parser.add_argument(
        "--expect-helper-surface",
        action="store_true",
        help="Require the issue #3 helper surface to exist inside the restored checkout",
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


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def check_required_paths(repo_root: Path) -> list[dict[str, object]]:
    results: list[dict[str, object]] = []
    for relative_path, label in RESTORED_CHECKOUT_PATHS:
        path = repo_root / relative_path
        results.append(
            {
                "path": relative_path,
                "label": label,
                "exists": path.is_file(),
            }
        )
    return results


def check_helper_surface(
    repo_root: Path,
    helper_root: Path | None,
    *,
    expect_helper_surface: bool,
) -> list[dict[str, object]]:
    results: list[dict[str, object]] = []
    for relative_path, label in HELPER_SURFACE_PATHS:
        restored_path = repo_root / relative_path
        entry: dict[str, object] = {
            "path": relative_path,
            "label": label,
            "exists": restored_path.is_file(),
            "required": expect_helper_surface,
            "matches_helper_root": None,
            "restored_sha256": None,
            "helper_root_sha256": None,
        }
        if restored_path.is_file():
            entry["restored_sha256"] = file_sha256(restored_path)
        if helper_root is not None:
            helper_path = helper_root / relative_path
            entry["helper_root_exists"] = helper_path.is_file()
            if helper_path.is_file():
                entry["helper_root_sha256"] = file_sha256(helper_path)
                if restored_path.is_file():
                    entry["matches_helper_root"] = (
                        entry["restored_sha256"] == entry["helper_root_sha256"]
                    )
            else:
                entry["matches_helper_root"] = False if restored_path.is_file() else None
        results.append(entry)
    return results


def collect_results(
    *,
    repo_root: Path,
    helper_root: Path | None,
    expect_helper_surface: bool,
) -> dict[str, object]:
    required_paths = check_required_paths(repo_root)
    helper_surface = check_helper_surface(
        repo_root,
        helper_root,
        expect_helper_surface=expect_helper_surface,
    )

    missing_required = [entry for entry in required_paths if not entry["exists"]]
    missing_helper_surface = [
        entry
        for entry in helper_surface
        if expect_helper_surface and not entry["exists"]
    ]
    drifted_helper_surface = [
        entry
        for entry in helper_surface
        if entry["exists"] and entry.get("matches_helper_root") is False
    ]

    ok = not missing_required and not missing_helper_surface and not drifted_helper_surface
    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "helper_root": str(helper_root) if helper_root is not None else None,
        "expect_helper_surface": expect_helper_surface,
        "required_paths": required_paths,
        "helper_surface": helper_surface,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Restored checkout: {result['repo_root']}")
    print(f"Helper root: {result['helper_root'] or 'not provided'}")
    print(f"Expect helper surface: {'yes' if result['expect_helper_surface'] else 'no'}")
    print("Required restored-checkout paths:")
    for entry in result["required_paths"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['path']}: {entry['label']}")
    print("Helper-surface files:")
    for entry in result["helper_surface"]:
        if not entry["required"] and not entry["exists"] and result["helper_root"] is None:
            status = "INFO"
        elif entry["required"] and not entry["exists"]:
            status = "FAIL"
        elif entry.get("matches_helper_root") is False:
            status = "FAIL"
        elif entry["exists"]:
            status = "PASS"
        else:
            status = "WARN"
        print(f"  [{status}] {entry['path']}: {entry['label']}")
        if entry.get("matches_helper_root") is False:
            print("         helper-root comparison: drift detected")
    if result["ok"]:
        print("\nRestored checkout check passed.")
        return

    print("\nRestored checkout check failed.", file=sys.stderr)
    if result["expect_helper_surface"]:
        print(
            "Suggested next step: rerun restore_saved_browser_snapshot.sh with --sync-helper-surface or keep using the live helper root for follow-up commands.",
            file=sys.stderr,
        )
    else:
        print(
            "Suggested next step: restore a clean snapshot checkout and then rerun this helper before Linux/WSL follow-up work.",
            file=sys.stderr,
        )


class RestoredCheckoutTests(unittest.TestCase):
    def test_collect_results_passes_for_minimal_restored_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser-memory-snapshot"
            repo_root.mkdir()
            for relative_path, _label in RESTORED_CHECKOUT_PATHS:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                helper_root=None,
                expect_helper_surface=False,
            )

            self.assertTrue(result["ok"])

    def test_expect_helper_surface_requires_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser-memory-snapshot"
            repo_root.mkdir()
            for relative_path, _label in RESTORED_CHECKOUT_PATHS:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                helper_root=None,
                expect_helper_surface=True,
            )

            self.assertFalse(result["ok"])
            self.assertFalse(result["helper_surface"][0]["exists"])

    def test_helper_root_drift_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            repo_root = base / "browser-memory-snapshot"
            helper_root = base / "browser-live"
            repo_root.mkdir()
            helper_root.mkdir()
            for relative_path, _label in RESTORED_CHECKOUT_PATHS:
                for root in (repo_root, helper_root):
                    target = root / relative_path
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_text("ok", encoding="utf-8")
            for index, (relative_path, _label) in enumerate(HELPER_SURFACE_PATHS):
                for root in (repo_root, helper_root):
                    target = root / relative_path
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_text("same", encoding="utf-8")
                if index == 0:
                    (repo_root / relative_path).write_text("drift", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                helper_root=helper_root,
                expect_helper_surface=True,
            )

            self.assertFalse(result["ok"])
            self.assertFalse(result["helper_surface"][0]["matches_helper_root"])

    def test_archive_integrity_surface_is_required_for_synced_helper_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser-memory-snapshot"
            repo_root.mkdir()
            for relative_path, _label in RESTORED_CHECKOUT_PATHS:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")
            for relative_path, _label in HELPER_SURFACE_PATHS:
                if relative_path == "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md":
                    continue
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                helper_root=None,
                expect_helper_surface=True,
            )

            self.assertFalse(result["ok"])
            missing = {
                entry["path"]
                for entry in result["helper_surface"]
                if not entry["exists"]
            }
            self.assertIn("docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md", missing)

    def test_restored_checkout_checker_is_required_for_synced_helper_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser-memory-snapshot"
            repo_root.mkdir()
            for relative_path, _label in RESTORED_CHECKOUT_PATHS:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")
            for relative_path, _label in HELPER_SURFACE_PATHS:
                if relative_path == "scripts/check_issue3_restored_checkout.py":
                    continue
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                helper_root=None,
                expect_helper_surface=True,
            )

            self.assertFalse(result["ok"])
            missing = {
                entry["path"]
                for entry in result["helper_surface"]
                if not entry["exists"]
            }
            self.assertIn("scripts/check_issue3_restored_checkout.py", missing)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(RestoredCheckoutTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    helper_root = Path(args.helper_root).resolve() if args.helper_root else None
    result = collect_results(
        repo_root=repo_root,
        helper_root=helper_root,
        expect_helper_surface=args.expect_helper_surface,
    )
    if args.json:
        print(json.dumps({"profile": "issue3-restored-checkout", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
