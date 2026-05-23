#!/usr/bin/env python3

"""Check whether the saved browser snapshot lags the live issue #3 helper surface."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest
import zipfile


DEFAULT_ARCHIVE_RELATIVE_PATH = "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
DEFAULT_ARCHIVE_TOP_LEVEL = "browser-fork-headed-mode-foundation/"

HELPER_SURFACE_PATHS: tuple[str, ...] = (
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
    "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
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
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the saved Memory browser snapshot zip already carries "
            "the live issue #3 helper surface, or whether restore should use "
            "--sync-helper-surface."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the live browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Path to the workspace memory root (default: ../memory beside the repo root)",
    )
    parser.add_argument(
        "--archive",
        default=None,
        help="Explicit path to the saved browser snapshot zip",
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


def resolve_default_memory_root(repo_root: Path) -> Path:
    return (repo_root.parent / "memory").resolve()


def resolve_archive_path(repo_root: Path, memory_root: Path, explicit_archive: str | None) -> Path:
    if explicit_archive:
        return Path(explicit_archive).resolve()
    return (memory_root / DEFAULT_ARCHIVE_RELATIVE_PATH).resolve()


def read_archive_names(archive_path: Path) -> list[str]:
    with zipfile.ZipFile(archive_path) as archive:
        return archive.namelist()


def infer_top_level_prefix(names: list[str]) -> str:
    visible = [name for name in names if name and not name.startswith("__MACOSX/")]
    if not visible:
        raise ValueError("saved browser snapshot archive has no visible entries")
    first = visible[0].split("/", 1)[0]
    if not first:
        raise ValueError("could not infer the archive top-level folder")
    return first.rstrip("/") + "/"


def collect_helper_surface_gap(
    *,
    repo_root: Path,
    memory_root: Path,
    archive_path: Path,
) -> dict[str, object]:
    live_entries: list[dict[str, object]] = []
    for relative_path in HELPER_SURFACE_PATHS:
        live_path = repo_root / relative_path
        live_entries.append(
            {
                "relative_path": relative_path,
                "live_path": str(live_path),
                "live_exists": live_path.is_file(),
            }
        )

    if not archive_path.is_file():
        return {
            "ok": False,
            "repo_root": str(repo_root),
            "memory_root": str(memory_root),
            "archive_path": str(archive_path),
            "archive_exists": False,
            "archive_top_level": "",
            "helper_entries": live_entries,
            "missing_from_live": [entry["relative_path"] for entry in live_entries if not entry["live_exists"]],
            "missing_from_archive": [],
            "archive_count": 0,
            "sync_helper_surface_recommended": False,
        }

    names = read_archive_names(archive_path)
    archive_top_level = infer_top_level_prefix(names)
    archive_name_set = set(names)

    helper_entries: list[dict[str, object]] = []
    for entry in live_entries:
        relative_path = str(entry["relative_path"])
        archive_member = archive_top_level + relative_path
        helper_entries.append(
            {
                **entry,
                "archive_member": archive_member,
                "archive_has_file": archive_member in archive_name_set,
            }
        )

    missing_from_live = [entry["relative_path"] for entry in helper_entries if not entry["live_exists"]]
    missing_from_archive = [entry["relative_path"] for entry in helper_entries if entry["live_exists"] and not entry["archive_has_file"]]

    return {
        "ok": not missing_from_live,
        "repo_root": str(repo_root),
        "memory_root": str(memory_root),
        "archive_path": str(archive_path),
        "archive_exists": True,
        "archive_top_level": archive_top_level,
        "helper_entries": helper_entries,
        "missing_from_live": missing_from_live,
        "missing_from_archive": missing_from_archive,
        "archive_count": len(names),
        "sync_helper_surface_recommended": bool(missing_from_archive),
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Memory root: {result['memory_root']}")
    print(f"Saved snapshot: {result['archive_path']}")
    if not result["archive_exists"]:
        print("Saved snapshot archive: [FAIL] missing")
        print("\nSuggested next step: restore or remount the saved browser snapshot zip before replay.")
        return

    print(f"Archive top level: {result['archive_top_level']}")
    missing_live = result["missing_from_live"]
    missing_archive = result["missing_from_archive"]

    print("Issue #3 helper surface:")
    for entry in result["helper_entries"]:
        live_status = "PASS" if entry["live_exists"] else "FAIL"
        archive_status = "PASS" if entry["archive_has_file"] else "WARN"
        print(
            f"  [{live_status}/{archive_status}] {entry['relative_path']}"
        )

    if missing_live:
        print("\nLive helper surface is incomplete:")
        for relative_path in missing_live:
            print(f"  - {relative_path}")

    if missing_archive:
        print("\nSaved snapshot is missing helper files that exist on the live branch:")
        for relative_path in missing_archive:
            print(f"  - {relative_path}")
        print("\nRecommendation: restore with --sync-helper-surface before Linux or WSL follow-up.")
    else:
        print("\nSaved snapshot already matches the live issue #3 helper surface.")


class HelperSurfaceGapTests(unittest.TestCase):
    def test_detects_archive_gap(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            repo_root.mkdir()
            archive_path = memory_root / DEFAULT_ARCHIVE_RELATIVE_PATH
            archive_path.parent.mkdir(parents=True, exist_ok=True)

            for relative_path in HELPER_SURFACE_PATHS[:3]:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("live\n", encoding="utf-8")

            with zipfile.ZipFile(archive_path, "w") as archive:
                archive.writestr(DEFAULT_ARCHIVE_TOP_LEVEL + HELPER_SURFACE_PATHS[0], "archived\n")

            result = collect_helper_surface_gap(
                repo_root=repo_root,
                memory_root=memory_root,
                archive_path=archive_path,
            )

            self.assertTrue(result["archive_exists"])
            self.assertIn(HELPER_SURFACE_PATHS[1], result["missing_from_archive"])
            self.assertTrue(result["sync_helper_surface_recommended"])

    def test_passes_when_archive_matches_live_subset(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            repo_root.mkdir()
            archive_path = memory_root / DEFAULT_ARCHIVE_RELATIVE_PATH
            archive_path.parent.mkdir(parents=True, exist_ok=True)

            for relative_path in HELPER_SURFACE_PATHS:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("live\n", encoding="utf-8")

            with zipfile.ZipFile(archive_path, "w") as archive:
                for relative_path in HELPER_SURFACE_PATHS:
                    archive.writestr(DEFAULT_ARCHIVE_TOP_LEVEL + relative_path, "archived\n")

            result = collect_helper_surface_gap(
                repo_root=repo_root,
                memory_root=memory_root,
                archive_path=archive_path,
            )

            self.assertEqual(result["missing_from_archive"], [])
            self.assertFalse(result["sync_helper_surface_recommended"])
            self.assertTrue(result["ok"])

    def test_reports_missing_archive_cleanly(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            repo_root.mkdir()
            archive_path = memory_root / DEFAULT_ARCHIVE_RELATIVE_PATH

            result = collect_helper_surface_gap(
                repo_root=repo_root,
                memory_root=memory_root,
                archive_path=archive_path,
            )

            self.assertFalse(result["archive_exists"])
            self.assertEqual(result["missing_from_archive"], [])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(HelperSurfaceGapTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    memory_root = Path(args.memory_root).resolve() if args.memory_root else resolve_default_memory_root(repo_root)
    archive_path = resolve_archive_path(repo_root, memory_root, args.archive)

    result = collect_helper_surface_gap(
        repo_root=repo_root,
        memory_root=memory_root,
        archive_path=archive_path,
    )
    payload = {"profile": "issue3-saved-snapshot-helper-surface-gap", **result}
    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        emit_text(payload)
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())