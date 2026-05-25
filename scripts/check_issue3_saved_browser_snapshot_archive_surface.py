#!/usr/bin/env python3

"""Inspect the saved browser snapshot archive for current issue #3 helper-surface drift."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import tempfile
import unittest
import zipfile
from dataclasses import asdict, dataclass


DEFAULT_ARCHIVE_NAME = "01-browser-fork-headed-mode-foundation.zip"
REQUIRED_PATHS = [
    (
        "build.zig.zon",
        "Snapshot manifest expected in a reusable restored checkout.",
    ),
    (
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "Runtime re-entry gate note that current issue #3 follow-up runs expect before reopening the direct runtime lane.",
    ),
    (
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "Direct issue #3 runtime revalidation note for the narrowed Page.zig and win32_backend.zig path.",
    ),
    (
        "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
        "Saved-archive integrity note that should stay available before restore or runtime follow-up trust the saved snapshot.",
    ),
    (
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "Read-first saved-browser-snapshot restore note for the blocked issue #3 runtime lane.",
    ),
    (
        "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
        "Restored-checkout re-entry note that should stay available after restore succeeds.",
    ),
    (
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "Linux or WSL build-readiness note that current follow-up runs expect after restore.",
    ),
    (
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "Zig toolchain recovery note that should stay available before a fallback Zig replay is trusted.",
    ),
    (
        "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
        "Saved Zig archive restore note that should stay available when a matching Zig bundle is ready to stage.",
    ),
    (
        "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
        "Offline build-inputs note that should stay available before sibling dependency staging is trusted.",
    ),
    (
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
        "Saved Rust toolchain route that should stay available before host Rust is trusted.",
    ),
    (
        "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md",
        "Google-shaped attached-page validation note that should stay available when replay widens back out from the runtime path.",
    ),
    (
        "scripts/check_issue3_saved_memory_inputs.py",
        "Saved-Memory preflight that checks the repo archive, blocker file, and dependency bundles.",
    ),
    (
        "scripts/check_issue3_saved_archive_integrity.py",
        "Saved-archive integrity helper that verifies the exact repo and dependency bundle fingerprints.",
    ),
    (
        "scripts/check_issue3_restored_checkout.py",
        "Restored-checkout readiness helper that should stay available after restore.",
    ),
    (
        "scripts/check_linux_build_readiness.py",
        "Linux build-readiness helper that should stay available after restore.",
    ),
    (
        "scripts/windows/HeadedValidationHelpers.ps1",
        "Shared Windows headed validation helper surface.",
    ),
    (
        "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
        "Windows runtime re-entry surface checker that should stay available when the restored helper surface is current.",
    ),
    (
        "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
        "Windows runtime re-entry helper that should stay available when the restored helper surface is current.",
    ),
    (
        "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "Windows attached-page replay surface checker that should stay available when replay widens back out from the runtime route.",
    ),
    (
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "Windows attached-page replay route printer that should stay available when replay widens back out from the runtime route.",
    ),
    (
        "scripts/windows/start_attached_pages_catalog.ps1",
        "Windows attached-pages catalog launcher that should stay available when attached replay is reopened.",
    ),
    (
        "tmp-browser-smoke/attached-pages/README.md",
        "Attached-pages launcher runbook that should stay available when the restored checkout becomes its own follow-up root.",
    ),
    (
        "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py",
        "Attached-pages catalog launcher that should stay available when the restored checkout becomes its own follow-up root.",
    ),
    (
        "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
        "Saved-archive-integrity surface checker that should stay available before restore or runtime follow-up trust the saved snapshot.",
    ),
    (
        "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
        "Compact route printer for the saved-archive-integrity path.",
    ),
    (
        "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "Saved snapshot restore surface checker that should stay available before the archive is extracted again.",
    ),
    (
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "Compact route printer for the saved-browser-snapshot restore path.",
    ),
    (
        "scripts/linux/restore_saved_browser_snapshot.sh",
        "Restore helper that supports --check-only and --sync-helper-surface.",
    ),
    (
        "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh",
        "Restored-checkout re-entry surface checker that should stay available after restore succeeds.",
    ),
    (
        "scripts/linux/show_issue3_restored_checkout_reentry_route.sh",
        "Restored-checkout re-entry route printer that should stay available after restore succeeds.",
    ),
    (
        "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "Linux build-readiness surface checker that should stay available after restore.",
    ),
    (
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "Linux build-readiness route printer that should stay available after restore.",
    ),
    (
        "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
        "Runtime revalidation surface checker that should stay available before the narrowed runtime lane is reopened.",
    ),
    (
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
        "Companion direct runtime re-entry route printer after restore.",
    ),
    (
        "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
        "Zig toolchain recovery surface checker that should stay available before fallback Zig is trusted.",
    ),
    (
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        "Zig toolchain recovery route printer that should stay available before fallback Zig is trusted.",
    ),
    (
        "scripts/linux/restore_issue3_fallback_zig_toolchain.sh",
        "Fallback Zig restore helper that should stay available when only the attached Zig bundle exists.",
    ),
    (
        "scripts/linux/restore_zig_toolchain_archive.sh",
        "Saved Zig archive restore helper that should stay available when a matching Zig bundle is staged.",
    ),
    (
        "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
        "Saved Rust toolchain surface checker that should stay available before the saved Rust archive is reused.",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
        "Saved Rust toolchain route printer that should stay available before the saved Rust archive is reused.",
    ),
    (
        "scripts/linux/restore_saved_rust_toolchain.sh",
        "Saved Rust toolchain restore helper that should stay available before host Rust is trusted.",
    ),
    (
        "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
        "Offline build-inputs surface checker that should stay available before sibling dependency staging is trusted.",
    ),
    (
        "scripts/linux/show_issue3_offline_build_inputs_route.sh",
        "Offline build-inputs route printer that should stay available before sibling dependency staging is trusted.",
    ),
    (
        "scripts/linux/prepare_offline_build_inputs.sh",
        "Offline build-inputs restore helper that should stay available before sibling dependency staging is trusted.",
    ),
]


@dataclass
class PathStatus:
    path: str
    present: bool
    purpose: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the saved browser snapshot archive already contains the "
            "current issue #3 restore-route helper surface or whether "
            "--sync-helper-surface should be preferred."
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
    return parser.parse_args()


def resolve_archive_path(args: argparse.Namespace) -> tuple[str, str]:
    repo_root = os.path.abspath(args.repo_root)
    if args.memory_root:
        memory_root = os.path.abspath(args.memory_root)
    else:
        candidates = [
            os.path.join(os.path.dirname(repo_root), "memory"),
            os.path.join(repo_root, "memory"),
            os.path.join("/workspace", "memory"),
        ]
        memory_root = next(
            (path for path in candidates if os.path.isdir(path)), candidates[0]
        )
    archive_path = (
        os.path.abspath(args.archive)
        if args.archive
        else os.path.join(
            memory_root, "repo_archives", "browser", DEFAULT_ARCHIVE_NAME
        )
    )
    return memory_root, archive_path


def infer_top_level_folder(names: set[str]) -> str:
    prefixes = sorted(
        {
            name.split("/", 1)[0]
            for name in names
            if "/" in name and name.split("/", 1)[0]
        }
    )
    if len(prefixes) == 1:
        return prefixes[0]
    return ""


def build_statuses(names: set[str], top_level_folder: str) -> list[PathStatus]:
    prefix = f"{top_level_folder}/" if top_level_folder else ""
    return [
        PathStatus(path=path, present=f"{prefix}{path}" in names, purpose=purpose)
        for path, purpose in REQUIRED_PATHS
    ]


def load_archive_names(archive_path: str) -> set[str]:
    with zipfile.ZipFile(archive_path) as archive:
        bad_member = archive.testzip()
        if bad_member is not None:
            raise ValueError(f"Snapshot archive failed CRC validation at: {bad_member}")
        return set(archive.namelist())


def build_payload(archive_path: str, names: set[str]) -> dict[str, object]:
    top_level_folder = infer_top_level_folder(names)
    statuses = build_statuses(names, top_level_folder)
    missing_paths = [status.path for status in statuses if not status.present]
    return {
        "issue": "issue3-saved-browser-snapshot-archive-surface",
        "archive_path": archive_path,
        "archive_top_level_root": top_level_folder,
        "helper_surface_complete": not missing_paths,
        "recommended_restore_mode": (
            "sync-helper-surface" if missing_paths else "plain"
        ),
        "missing_paths": missing_paths,
        "required_paths": [asdict(status) for status in statuses],
    }


def human_output(archive_path: str, top_level_folder: str, statuses: list[PathStatus]) -> str:
    missing = [status for status in statuses if not status.present]
    recommended_restore_mode = (
        "--sync-helper-surface" if missing else "plain restore is safe"
    )
    lines = [
        "Issue #3 saved browser snapshot archive surface",
        "",
        f"Snapshot archive:       {archive_path}",
        f"Archive top-level root: {top_level_folder or 'unable to infer'}",
        f"Recommended restore:    {recommended_restore_mode}",
        "",
        "Archive helper surface:",
    ]
    for status in statuses:
        prefix = "PASS" if status.present else "WARN"
        lines.append(f"[{prefix}] {status.path}")
        lines.append(f"  {status.purpose}")
    lines.extend(
        [
            "",
            "Working rules:",
            "  - Prefer a plain restore only when the saved archive already contains the current restore and runtime helper surface.",
            "  - Use --sync-helper-surface when any helper path above is missing from the archive.",
            "  - Keep the live helper root for the next follow-up commands when the archive helper surface is stale.",
            "  - Treat this helper as a quick trust check for the saved snapshot archive, not as proof that build or runtime validation is already green.",
        ]
    )
    if missing:
        lines.extend(
            [
                "",
                "Missing helper paths detected in the saved archive:",
            ]
        )
        lines.extend(f"  - {status.path}" for status in missing)
    else:
        lines.extend(
            [
                "",
                "The saved archive already carries the current helper surface.",
            ]
        )
    return "\n".join(lines)


class SavedBrowserSnapshotArchiveSurfaceTests(unittest.TestCase):
    def test_infer_top_level_folder_returns_single_prefix(self) -> None:
        names = {
            "browser-fork-headed-mode-foundation/build.zig.zon",
            "browser-fork-headed-mode-foundation/docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        }
        self.assertEqual(
            infer_top_level_folder(names),
            "browser-fork-headed-mode-foundation",
        )

    def test_build_payload_marks_missing_paths_and_sync_restore(self) -> None:
        names = {
            "browser-fork-headed-mode-foundation/build.zig.zon",
            "browser-fork-headed-mode-foundation/docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        }
        payload = build_payload("/tmp/archive.zip", names)

        self.assertFalse(payload["helper_surface_complete"])
        self.assertEqual(payload["recommended_restore_mode"], "sync-helper-surface")
        self.assertIn(
            "scripts/check_issue3_saved_memory_inputs.py",
            payload["missing_paths"],
        )

    def test_build_payload_marks_plain_restore_when_surface_is_complete(self) -> None:
        top_level = "browser-fork-headed-mode-foundation"
        names = {f"{top_level}/{path}" for path, _purpose in REQUIRED_PATHS}
        payload = build_payload("/tmp/archive.zip", names)

        self.assertTrue(payload["helper_surface_complete"])
        self.assertEqual(payload["recommended_restore_mode"], "plain")
        self.assertEqual(payload["missing_paths"], [])

    def test_resolve_archive_path_prefers_existing_memory_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            memory_root = Path(tmpdir) / "memory"
            repo_root.mkdir()
            memory_root.mkdir()

            args = argparse.Namespace(
                repo_root=str(repo_root),
                memory_root=None,
                archive=None,
            )
            resolved_memory_root, archive_path = resolve_archive_path(args)

            self.assertEqual(resolved_memory_root, str(memory_root.resolve()))
            self.assertEqual(
                archive_path,
                str(
                    (
                        memory_root
                        / "repo_archives/browser"
                        / DEFAULT_ARCHIVE_NAME
                    ).resolve()
                ),
            )

    def test_load_archive_names_rejects_crc_failures(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            archive_path = Path(tmpdir) / "broken.zip"
            archive_path.write_text("not a zip", encoding="utf-8")

            with self.assertRaises(zipfile.BadZipFile):
                load_archive_names(str(archive_path))


def main() -> int:
    args = parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedBrowserSnapshotArchiveSurfaceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    _, archive_path = resolve_archive_path(args)
    if not os.path.isfile(archive_path):
        print(f"Snapshot archive not found: {archive_path}", file=os.sys.stderr)
        return 1

    try:
        names = load_archive_names(archive_path)
    except (ValueError, zipfile.BadZipFile) as exc:
        print(str(exc), file=os.sys.stderr)
        return 1

    payload = build_payload(archive_path, names)
    top_level_folder = payload["archive_top_level_root"]
    statuses = [
        PathStatus(**entry) for entry in payload["required_paths"]
    ]

    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        print(human_output(archive_path, top_level_folder, statuses))

    return 0 if not payload["missing_paths"] else 2


if __name__ == "__main__":
    raise SystemExit(main())