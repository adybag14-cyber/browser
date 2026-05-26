#!/usr/bin/env python3

"""Check whether a checkout can supply the current issue #3 helper surface.

This helper is for the Linux/WSL re-entry lane when a run wants to use
restore_saved_browser_snapshot.sh with --sync-helper-surface or --sync-only.
It answers two questions:

- does the chosen helper root actually carry the expected helper-surface files?
- if a restored checkout already exists, which helper-surface files would still
  need to be refreshed there?
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest


HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry gate note"),
    ("docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md", "runtime revalidation note"),
    ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved snapshot restore note"),
    ("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md", "restored-checkout re-entry note"),
    (
        "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
        "restored helper-surface sync route note",
    ),
    ("docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md", "saved-archive integrity note"),
    (
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md",
        "saved snapshot archive-surface note",
    ),
    ("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "issue #11 progress-tracker route note"),
    ("docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md", "workspace-context route note"),
    ("docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md", "saved-Memory inputs route note"),
    ("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness note"),
    (
        "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md",
        "saved Rust build-readiness bridge note",
    ),
    (
        "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md",
        "saved Rust archive candidates route note",
    ),
    ("docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md", "Zig toolchain recovery note"),
    ("docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md", "Zig toolchain archive restore note"),
    (
        "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
        "saved Zig archive candidates route note",
    ),
    ("docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md", "offline build-inputs note"),
    ("docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md", "saved Rust toolchain note"),
    ("docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md", "attached-page validation flow note"),
    ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
    ("scripts/check_issue3_saved_archive_integrity.py", "saved-archive integrity helper"),
    ("scripts/check_issue3_saved_rust_archive_candidates.py", "saved Rust archive candidate helper"),
    (
        "scripts/check_issue3_staged_rust_toolchain_candidates.py",
        "staged Rust toolchain candidate helper",
    ),
    ("scripts/check_issue3_saved_browser_snapshot_archive_surface.py", "saved snapshot archive-surface helper"),
    ("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper"),
    ("scripts/check_issue3_restored_helper_surface_sync.py", "restored helper-surface sync helper"),
    ("scripts/check_issue3_workspace_context.py", "workspace-context helper"),
    ("scripts/check_issue3_saved_zig_archive_candidates.py", "saved Zig archive candidate helper"),
    (
        "scripts/check_issue3_staged_zig_toolchain_candidates.py",
        "staged Zig toolchain candidate helper",
    ),
    ("scripts/check_issue3_build_readiness_rerun.py", "build-readiness rerun helper"),
    ("scripts/check_issue11_saved_memory_helper_contract.py", "issue #11 saved-memory helper-contract checker"),
    ("scripts/check_issue11_progress_tracker_surface.py", "issue #11 progress-tracker surface checker"),
    ("scripts/check_issue11_reentry_inventory_consistency.py", "issue #11 re-entry inventory checker"),
    ("scripts/check_issue11_workspace_readiness.py", "issue #11 workspace-aware readiness helper"),
    ("scripts/show_issue11_matching_zig_readiness_command.py", "issue #11 matching-Zig readiness helper"),
    ("scripts/check_linux_build_readiness.py", "Linux build-readiness checker"),
    ("scripts/linux/check_issue3_progress_tracker_route_surface.sh", "issue #11 progress-tracker route surface check"),
    ("scripts/linux/show_issue3_progress_tracker_route.sh", "issue #11 progress-tracker route printer"),
    ("scripts/linux/check_issue3_workspace_context_route_surface.sh", "workspace-context route surface check"),
    ("scripts/linux/show_issue3_workspace_context_route.sh", "workspace-context route printer"),
    (
        "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
        "saved Zig archive candidates route surface check",
    ),
    (
        "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
        "saved Zig archive candidates route printer",
    ),
    ("scripts/windows/HeadedValidationHelpers.ps1", "Windows headed validation helper"),
    (
        "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
        "Windows runtime re-entry surface checker",
    ),
    (
        "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
        "Windows runtime re-entry route helper",
    ),
    (
        "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "Windows attached-page replay surface checker",
    ),
    (
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "Windows attached-page replay route helper",
    ),
    ("scripts/windows/start_attached_pages_catalog.ps1", "Windows attached-pages catalog launcher"),
    ("tmp-browser-smoke/attached-pages/README.md", "attached-pages launcher runbook"),
    ("tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py", "attached-pages catalog launcher"),
    ("scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh", "saved-archive integrity surface check"),
    ("scripts/linux/show_issue3_saved_archive_integrity_route.sh", "saved-archive integrity route printer"),
    ("scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh", "saved snapshot surface check"),
    ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved snapshot route printer"),
    ("scripts/linux/restore_saved_browser_snapshot.sh", "saved snapshot restore helper"),
    (
        "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh",
        "restored-checkout re-entry route surface check",
    ),
    (
        "scripts/linux/show_issue3_restored_checkout_reentry_route.sh",
        "restored-checkout re-entry route printer",
    ),
    (
        "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh",
        "restored helper-surface sync route surface check",
    ),
    (
        "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh",
        "restored helper-surface sync route printer",
    ),
    ("scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh", "saved-Memory route surface check"),
    ("scripts/linux/show_issue3_saved_memory_inputs_route.sh", "saved-Memory route printer"),
    (
        "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh",
        "saved Rust build-readiness bridge surface check",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
        "saved Rust build-readiness bridge route printer",
    ),
    (
        "scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh",
        "saved Rust archive candidates route surface check",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh",
        "saved Rust archive candidates route printer",
    ),
    ("scripts/linux/check_issue3_linux_build_readiness_route_surface.sh", "Linux build-readiness surface check"),
    ("scripts/linux/show_issue3_linux_build_readiness_route.sh", "Linux build-readiness route printer"),
    ("scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh", "runtime revalidation surface check"),
    ("scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh", "runtime revalidation route printer"),
    ("scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh", "Zig toolchain recovery surface check"),
    ("scripts/linux/check_issue3_zig_toolchain_match.sh", "Zig toolchain matching-line gate"),
    (
        "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
        "Zig toolchain archive-restore surface check",
    ),
    ("scripts/linux/show_issue3_zig_toolchain_recovery_route.sh", "Zig toolchain recovery route printer"),
    ("scripts/linux/restore_issue3_fallback_zig_toolchain.sh", "fallback Zig restore helper"),
    ("scripts/linux/restore_zig_toolchain_archive.sh", "saved Zig archive restore helper"),
    ("scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh", "saved Rust route surface check"),
    ("scripts/linux/show_issue3_saved_rust_toolchain_route.sh", "saved Rust route printer"),
    ("scripts/linux/restore_saved_rust_toolchain.sh", "saved Rust restore helper"),
    ("scripts/linux/check_issue3_offline_build_inputs_route_surface.sh", "offline inputs surface check"),
    ("scripts/linux/show_issue3_offline_build_inputs_route.sh", "offline inputs route printer"),
    ("scripts/linux/prepare_offline_build_inputs.sh", "offline inputs restore helper"),
    (
        "scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh",
        "Windows runtime handoff surface check",
    ),
    (
        "scripts/linux/show_issue3_windows_runtime_handoff_route.sh",
        "Windows runtime handoff route printer",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether a checkout can act as the current issue #3 helper-surface "
            "source for saved-snapshot sync flows."
        )
    )
    parser.add_argument(
        "--helper-root",
        default=".",
        help="Path to the checkout that should provide the current helper surface",
    )
    parser.add_argument(
        "--restored-checkout-root",
        default=None,
        help="Optional restored checkout to compare against the helper source",
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


def collect_results(
    *,
    helper_root: Path,
    restored_checkout_root: Path | None,
) -> dict[str, object]:
    helper_entries: list[dict[str, object]] = []
    missing_paths: list[str] = []
    drifted_paths: list[str] = []

    for relative_path, label in HELPER_SURFACE_PATHS:
        helper_path = helper_root / relative_path
        entry: dict[str, object] = {
            "path": relative_path,
            "label": label,
            "exists_in_helper_root": helper_path.is_file(),
            "helper_root_sha256": None,
            "exists_in_restored_checkout": None,
            "restored_checkout_sha256": None,
            "matches_restored_checkout": None,
        }
        if helper_path.is_file():
            entry["helper_root_sha256"] = file_sha256(helper_path)
        else:
            missing_paths.append(relative_path)

        if restored_checkout_root is not None:
            restored_path = restored_checkout_root / relative_path
            entry["exists_in_restored_checkout"] = restored_path.is_file()
            if restored_path.is_file():
                entry["restored_checkout_sha256"] = file_sha256(restored_path)
            if helper_path.is_file() and restored_path.is_file():
                matches = entry["helper_root_sha256"] == entry["restored_checkout_sha256"]
                entry["matches_restored_checkout"] = matches
                if not matches:
                    drifted_paths.append(relative_path)
            elif helper_path.is_file():
                entry["matches_restored_checkout"] = False
                drifted_paths.append(relative_path)

        helper_entries.append(entry)

    diagnosis = "ready"
    if missing_paths:
        diagnosis = "missing-helper-surface-source"
    elif drifted_paths:
        diagnosis = "restored-checkout-helper-surface-drift"

    return {
        "ok": not missing_paths and not drifted_paths,
        "diagnosis": diagnosis,
        "helper_root": str(helper_root),
        "restored_checkout_root": str(restored_checkout_root) if restored_checkout_root is not None else None,
        "helper_surface_file_count": len(HELPER_SURFACE_PATHS),
        "missing_paths": missing_paths,
        "drifted_paths": drifted_paths,
        "helper_surface": helper_entries,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Helper root: {result['helper_root']}")
    print(f"Restored checkout: {result['restored_checkout_root'] or 'not provided'}")
    print(f"Expected helper-surface files: {result['helper_surface_file_count']}")
    print("Helper-surface status:")
    for entry in result["helper_surface"]:
        if not entry["exists_in_helper_root"]:
            status = "FAIL"
        elif entry["matches_restored_checkout"] is False:
            status = "WARN"
        else:
            status = "PASS"
        print(f"  [{status}] {entry['path']}: {entry['label']}")
        if entry["matches_restored_checkout"] is False:
            print("         restored checkout needs refresh from this helper root")

    if result["ok"]:
        print("\nHelper-surface source check passed.")
        return

    print("\nHelper-surface source check failed.", file=sys.stderr)
    print(f"Diagnosis: {result['diagnosis']}", file=sys.stderr)
    if result["diagnosis"] == "missing-helper-surface-source":
        print(
            "Suggested next step: do not use this checkout as the --helper-root for "
            "--sync-helper-surface or --sync-only. Use a live branch-local checkout "
            "that carries the current issue #3 helper files instead.",
            file=sys.stderr,
        )
    else:
        print(
            "Suggested next step: refresh the restored checkout with "
            "restore_saved_browser_snapshot.sh --sync-only, then rerun this helper.",
            file=sys.stderr,
        )


class HelperSurfaceSourceTests(unittest.TestCase):
    def test_detects_missing_helper_surface_source(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper_root = Path(tmpdir) / "helper-root"
            helper_root.mkdir()
            result = collect_results(helper_root=helper_root, restored_checkout_root=None)
            self.assertFalse(result["ok"])
            self.assertEqual(result["diagnosis"], "missing-helper-surface-source")
            self.assertTrue(result["missing_paths"])

    def test_passes_for_complete_helper_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper_root = Path(tmpdir) / "helper-root"
            helper_root.mkdir()
            for relative_path, _label in HELPER_SURFACE_PATHS:
                target = helper_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(relative_path, encoding="utf-8")
            result = collect_results(helper_root=helper_root, restored_checkout_root=None)
            self.assertTrue(result["ok"])
            self.assertEqual(result["diagnosis"], "ready")

    def test_detects_restored_checkout_drift(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper_root = Path(tmpdir) / "helper-root"
            restored_root = Path(tmpdir) / "restored-root"
            helper_root.mkdir()
            restored_root.mkdir()
            for index, (relative_path, _label) in enumerate(HELPER_SURFACE_PATHS):
                helper_target = helper_root / relative_path
                restored_target = restored_root / relative_path
                helper_target.parent.mkdir(parents=True, exist_ok=True)
                restored_target.parent.mkdir(parents=True, exist_ok=True)
                helper_target.write_text(f"helper-{index}", encoding="utf-8")
                restored_target.write_text(
                    f"{'restored-drift' if index == 0 else f'helper-{index}'}",
                    encoding="utf-8",
                )
            result = collect_results(
                helper_root=helper_root,
                restored_checkout_root=restored_root,
            )
            self.assertFalse(result["ok"])
            self.assertEqual(result["diagnosis"], "restored-checkout-helper-surface-drift")
            self.assertEqual(result["drifted_paths"], [HELPER_SURFACE_PATHS[0][0]])

    def test_issue11_helper_contract_is_required(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper_root = Path(tmpdir) / "helper-root"
            helper_root.mkdir()
            for relative_path, _label in HELPER_SURFACE_PATHS:
                if relative_path == "scripts/check_issue11_saved_memory_helper_contract.py":
                    continue
                target = helper_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(relative_path, encoding="utf-8")

            result = collect_results(helper_root=helper_root, restored_checkout_root=None)

            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/check_issue11_saved_memory_helper_contract.py",
                result["missing_paths"],
            )

    def test_issue11_progress_tracker_surface_is_required(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper_root = Path(tmpdir) / "helper-root"
            helper_root.mkdir()
            for relative_path, _label in HELPER_SURFACE_PATHS:
                if relative_path == "scripts/check_issue11_progress_tracker_surface.py":
                    continue
                target = helper_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(relative_path, encoding="utf-8")

            result = collect_results(helper_root=helper_root, restored_checkout_root=None)

            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/check_issue11_progress_tracker_surface.py",
                result["missing_paths"],
            )

    def test_issue11_workspace_readiness_helper_is_required(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper_root = Path(tmpdir) / "helper-root"
            helper_root.mkdir()
            for relative_path, _label in HELPER_SURFACE_PATHS:
                if relative_path == "scripts/check_issue11_workspace_readiness.py":
                    continue
                target = helper_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(relative_path, encoding="utf-8")

            result = collect_results(helper_root=helper_root, restored_checkout_root=None)

            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/check_issue11_workspace_readiness.py",
                result["missing_paths"],
            )

    def test_issue11_matching_zig_helper_is_required(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper_root = Path(tmpdir) / "helper-root"
            helper_root.mkdir()
            for relative_path, _label in HELPER_SURFACE_PATHS:
                if relative_path == "scripts/show_issue11_matching_zig_readiness_command.py":
                    continue
                target = helper_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(relative_path, encoding="utf-8")

            result = collect_results(helper_root=helper_root, restored_checkout_root=None)

            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/show_issue11_matching_zig_readiness_command.py",
                result["missing_paths"],
            )

    def test_progress_tracker_route_printer_is_required(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper_root = Path(tmpdir) / "helper-root"
            helper_root.mkdir()
            for relative_path, _label in HELPER_SURFACE_PATHS:
                if relative_path == "scripts/linux/show_issue3_progress_tracker_route.sh":
                    continue
                target = helper_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(relative_path, encoding="utf-8")

            result = collect_results(helper_root=helper_root, restored_checkout_root=None)

            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/linux/show_issue3_progress_tracker_route.sh",
                result["missing_paths"],
            )


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(HelperSurfaceSourceTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    helper_root = Path(args.helper_root).resolve()
    if not helper_root.exists():
        print(f"Helper root does not exist: {helper_root}", file=sys.stderr)
        return 1

    restored_checkout_root = None
    if args.restored_checkout_root is not None:
        restored_checkout_root = Path(args.restored_checkout_root).resolve()
        if not restored_checkout_root.exists():
            print(f"Restored checkout does not exist: {restored_checkout_root}", file=sys.stderr)
            return 1

    result = collect_results(
        helper_root=helper_root,
        restored_checkout_root=restored_checkout_root,
    )
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
