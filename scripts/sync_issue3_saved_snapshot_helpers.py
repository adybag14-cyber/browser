#!/usr/bin/env python3

"""Sync the latest issue #3 helper surface into a restored saved snapshot.

This helper is meant for the saved-browser-snapshot route. The restored snapshot
is a stable older repo archive, so it may not contain the newer branch-local
docs and helper scripts that later Linux/WSL and Windows re-entry routes rely
on. This script copies the current live helper surface into the restored
snapshot so follow-up validation can run from one local checkout without
manually chasing missing files.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from pathlib import Path
import shutil
import stat
import tempfile
import unittest


HELPER_PATHS: tuple[str, ...] = (
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
    "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
    "scripts/check_issue3_saved_memory_inputs.py",
    "scripts/check_linux_build_readiness.py",
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
    "scripts/linux/restore_saved_browser_snapshot.sh",
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh",
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
    "scripts/linux/restore_saved_rust_toolchain.sh",
    "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
    "scripts/linux/show_issue3_offline_build_inputs_route.sh",
    "scripts/linux/prepare_offline_build_inputs.sh",
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
    "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
    "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
    "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
)


@dataclass
class SyncEntry:
    relative_path: str
    source_exists: bool
    destination_exists: bool
    content_differs: bool
    copied: bool = False

    @property
    def status(self) -> str:
        if not self.source_exists:
            return "missing-source"
        if self.copied:
            return "copied"
        if not self.destination_exists:
            return "missing-destination"
        if self.content_differs:
            return "outdated-destination"
        return "up-to-date"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Copy the current issue #3 helper docs and scripts from a live "
            "checkout into a restored saved browser snapshot."
        )
    )
    parser.add_argument(
        "--live-repo-root",
        default=".",
        help="Path to the live browser checkout that holds the newest helper surface",
    )
    parser.add_argument(
        "--snapshot-root",
        required=False,
        default="../browser-memory-snapshot",
        help="Path to the restored saved snapshot checkout to update",
    )
    parser.add_argument(
        "--check-only",
        action="store_true",
        help="Report which helper files are missing or outdated without copying them",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def file_bytes(path: Path) -> bytes:
    return path.read_bytes()


def same_file(source: Path, destination: Path) -> bool:
    return file_bytes(source) == file_bytes(destination)


def collect_entries(live_repo_root: Path, snapshot_root: Path) -> list[SyncEntry]:
    entries: list[SyncEntry] = []
    for relative_path in HELPER_PATHS:
        source = live_repo_root / relative_path
        destination = snapshot_root / relative_path
        source_exists = source.is_file()
        destination_exists = destination.is_file()
        content_differs = False
        if source_exists and destination_exists:
            content_differs = not same_file(source, destination)
        entries.append(
            SyncEntry(
                relative_path=relative_path,
                source_exists=source_exists,
                destination_exists=destination_exists,
                content_differs=content_differs,
            )
        )
    return entries


def validate_roots(live_repo_root: Path, snapshot_root: Path) -> list[str]:
    failures: list[str] = []
    if not (live_repo_root / "build.zig.zon").is_file():
        failures.append(f"live repo root does not look like a browser checkout: {live_repo_root}")
    if not (snapshot_root / "build.zig.zon").is_file():
        failures.append(f"snapshot root does not look like a restored browser checkout: {snapshot_root}")
    return failures


def copy_entry(entry: SyncEntry, live_repo_root: Path, snapshot_root: Path) -> None:
    source = live_repo_root / entry.relative_path
    destination = snapshot_root / entry.relative_path
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    source_mode = source.stat().st_mode
    destination.chmod(stat.S_IMODE(source_mode))
    entry.copied = True


def sync_entries(entries: list[SyncEntry], live_repo_root: Path, snapshot_root: Path) -> None:
    for entry in entries:
        if not entry.source_exists:
            continue
        if not entry.destination_exists or entry.content_differs:
            copy_entry(entry, live_repo_root, snapshot_root)


def build_result(live_repo_root: Path, snapshot_root: Path, entries: list[SyncEntry]) -> dict[str, object]:
    missing_sources = [entry.relative_path for entry in entries if not entry.source_exists]
    copied_paths = [entry.relative_path for entry in entries if entry.copied]
    outdated_paths = [entry.relative_path for entry in entries if entry.status == "outdated-destination"]
    missing_destinations = [entry.relative_path for entry in entries if entry.status == "missing-destination"]
    up_to_date = [entry.relative_path for entry in entries if entry.status == "up-to-date"]
    return {
        "live_repo_root": str(live_repo_root),
        "snapshot_root": str(snapshot_root),
        "helper_count": len(entries),
        "missing_source_count": len(missing_sources),
        "copied_count": len(copied_paths),
        "outdated_destination_count": len(outdated_paths),
        "missing_destination_count": len(missing_destinations),
        "up_to_date_count": len(up_to_date),
        "missing_sources": missing_sources,
        "copied_paths": copied_paths,
        "outdated_destination_paths": outdated_paths,
        "missing_destination_paths": missing_destinations,
        "up_to_date_paths": up_to_date,
        "entries": [
            {
                "path": entry.relative_path,
                "status": entry.status,
            }
            for entry in entries
        ],
    }


def emit_text(result: dict[str, object], check_only: bool) -> None:
    print(f"Live repo root: {result['live_repo_root']}")
    print(f"Snapshot root:  {result['snapshot_root']}")
    print(f"Helper paths:   {result['helper_count']}")
    print(f"Missing source paths:      {result['missing_source_count']}")
    print(f"Missing snapshot paths:    {result['missing_destination_count']}")
    print(f"Outdated snapshot paths:   {result['outdated_destination_count']}")
    print(f"Copied paths this run:     {result['copied_count']}")
    print(f"Already up to date paths:  {result['up_to_date_count']}")
    print()
    for entry in result["entries"]:
        print(f"[{entry['status']}] {entry['path']}")
    print()
    if check_only:
        print("Check-only complete.")
    else:
        print("Saved snapshot helper sync complete.")
    print(
        "Suggested next step: run the saved Memory input preflight and then the Linux build-readiness route against the snapshot checkout."
    )


class SyncSavedSnapshotHelpersTests(unittest.TestCase):
    def make_checkout(self, root: Path) -> None:
        (root / "build.zig.zon").write_text(".minimum_zig_version = \"0.15.2\";\n", encoding="utf-8")

    def seed_helper_surface(self, root: Path, suffix: str) -> None:
        for relative_path in HELPER_PATHS:
            target = root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(f"{relative_path}:{suffix}\n", encoding="utf-8")

    def test_collect_entries_reports_missing_snapshot_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            temp_root = Path(tmpdir)
            live_root = temp_root / "live"
            snapshot_root = temp_root / "snapshot"
            live_root.mkdir()
            snapshot_root.mkdir()
            self.make_checkout(live_root)
            self.make_checkout(snapshot_root)
            self.seed_helper_surface(live_root, "live")

            entries = collect_entries(live_root, snapshot_root)

            self.assertEqual(len(entries), len(HELPER_PATHS))
            self.assertTrue(all(entry.source_exists for entry in entries))
            self.assertTrue(all(not entry.destination_exists for entry in entries))

    def test_sync_entries_copies_missing_and_outdated_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            temp_root = Path(tmpdir)
            live_root = temp_root / "live"
            snapshot_root = temp_root / "snapshot"
            live_root.mkdir()
            snapshot_root.mkdir()
            self.make_checkout(live_root)
            self.make_checkout(snapshot_root)
            self.seed_helper_surface(live_root, "live")
            self.seed_helper_surface(snapshot_root, "old")

            entries = collect_entries(live_root, snapshot_root)
            sync_entries(entries, live_root, snapshot_root)

            self.assertTrue(any(entry.copied for entry in entries))
            self.assertEqual(
                (snapshot_root / HELPER_PATHS[0]).read_text(encoding="utf-8"),
                f"{HELPER_PATHS[0]}:live\n",
            )

    def test_validate_roots_requires_browser_checkout_shape(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            temp_root = Path(tmpdir)
            live_root = temp_root / "live"
            snapshot_root = temp_root / "snapshot"
            live_root.mkdir()
            snapshot_root.mkdir()

            failures = validate_roots(live_root, snapshot_root)

            self.assertEqual(len(failures), 2)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SyncSavedSnapshotHelpersTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    live_repo_root = Path(args.live_repo_root).resolve()
    snapshot_root = Path(args.snapshot_root).resolve()
    failures = validate_roots(live_repo_root, snapshot_root)
    entries = collect_entries(live_repo_root, snapshot_root)
    if not args.check_only and not failures and not any(not entry.source_exists for entry in entries):
        sync_entries(entries, live_repo_root, snapshot_root)

    result = build_result(live_repo_root, snapshot_root, entries)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result, args.check_only)

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}")
        return 2
    if any(not entry.source_exists for entry in entries):
        print("ERROR: one or more live helper files are missing")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
