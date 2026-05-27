#!/usr/bin/env python3

"""Check whether the saved snapshot archive includes the current helper surface.

This issue #11 helper compares the current
`scripts/linux/restore_saved_browser_snapshot.sh` helper-surface inventory with
the files that are actually present inside the saved Memory snapshot archive.
It gives Linux/WSL re-entry runs one small, honest check before they trust a
fresh restore to already include the newer issue #11 helper stack.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shlex
import tempfile
import unittest
import zipfile


ARCHIVE_RELATIVE_PATH = "memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
RESTORE_HELPER_RELATIVE_PATH = "scripts/linux/restore_saved_browser_snapshot.sh"
EXPECTED_ARCHIVE_PREFIX = "browser-fork-headed-mode-foundation/"
DEFAULT_DESTINATION_NAME = "browser-memory-snapshot"
ISSUE11_REENTRY_HINT_FRAGMENTS = (
    "issue11",
    "ISSUE3_PROGRESS_TRACKER_ROUTE",
    "ISSUE3_STAGED_ZIG_TOOLCHAIN",
    "ISSUE3_STAGED_RUST_TOOLCHAIN",
    "check_issue3_staged_zig_toolchain",
    "check_issue3_staged_rust_toolchain",
    "show_issue3_staged_zig_toolchain",
    "show_issue3_staged_rust_toolchain",
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the saved browser snapshot archive already contains "
            "the current issue #11 helper surface copied by the restore route."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the live browser repo root (default: current directory)",
    )
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Path to the workspace memory root (default: nearest ancestor memory dir)",
    )
    parser.add_argument(
        "--archive",
        default=None,
        help="Optional explicit path to the saved snapshot archive to inspect",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused self-tests and exit",
    )
    return parser


def ancestor_chain(start: Path) -> list[Path]:
    chain: list[Path] = []
    current = start.resolve()
    while True:
        chain.append(current)
        if current.parent == current:
            break
        current = current.parent
    return chain


def locate_first_existing_dir(start: Path, relative_path: str) -> Path | None:
    for ancestor in ancestor_chain(start):
        candidate = ancestor / relative_path
        if candidate.is_dir():
            return candidate.resolve()
    return None


def resolve_default_memory_root(repo_root: Path) -> Path:
    located = locate_first_existing_dir(repo_root, "memory")
    if located is not None:
        return located
    return (repo_root.parent / "memory").resolve()


def resolve_default_destination(repo_root: Path) -> Path:
    located = locate_first_existing_dir(repo_root, DEFAULT_DESTINATION_NAME)
    if located is not None:
        return located
    return (repo_root.parent / DEFAULT_DESTINATION_NAME).resolve()


def format_shell_arg(raw: str) -> str:
    return shlex.quote(raw)


def build_restore_command(
    repo_root: Path,
    memory_root: Path,
    archive_path: Path,
    destination: Path,
    *,
    sync_only: bool,
    check_only: bool,
) -> str:
    command = [
        "bash",
        str(repo_root / RESTORE_HELPER_RELATIVE_PATH),
        "--browser-root",
        str(repo_root),
        "--helper-root",
        str(repo_root),
        "--memory-root",
        str(memory_root),
        "--archive",
        str(archive_path),
        "--destination",
        str(destination),
    ]
    if sync_only:
        command.append("--sync-only")
    else:
        command.append("--sync-helper-surface")
    if check_only:
        command.append("--check-only")
    return " ".join(format_shell_arg(part) for part in command)


def extract_restore_helper_paths(script_text: str) -> list[str]:
    marker = "declare -a HELPER_SURFACE_PATHS=("
    in_block = False
    paths: list[str] = []

    for line in script_text.splitlines():
        stripped = line.strip()
        if not in_block:
            if stripped == marker:
                in_block = True
            continue

        if stripped == ")":
            break

        if stripped.startswith('"') and stripped.endswith('"'):
            paths.append(stripped.strip('"'))

    if not in_block:
        raise ValueError(f"Could not find HELPER_SURFACE_PATHS in {RESTORE_HELPER_RELATIVE_PATH}")
    if not paths:
        raise ValueError(f"HELPER_SURFACE_PATHS in {RESTORE_HELPER_RELATIVE_PATH} is empty")
    return paths


def determine_archive_prefix(names: list[str]) -> str:
    if any(name.startswith(EXPECTED_ARCHIVE_PREFIX) for name in names):
        return EXPECTED_ARCHIVE_PREFIX
    for name in names:
        if not name or name.startswith("__MACOSX/"):
            continue
        top_level = name.split("/", 1)[0]
        if top_level:
            return f"{top_level}/"
    raise ValueError("Could not determine the archive top-level folder")


def is_issue11_reentry_helper_path(relative_path: str) -> bool:
    return any(fragment in relative_path for fragment in ISSUE11_REENTRY_HINT_FRAGMENTS)


def collect_results(repo_root: Path, memory_root: Path, archive_path: Path) -> dict[str, object]:
    restore_helper_path = repo_root / RESTORE_HELPER_RELATIVE_PATH
    restore_helper_exists = restore_helper_path.is_file()
    restore_helper_paths: list[str] = []
    restore_helper_error: str | None = None
    restored_destination = resolve_default_destination(repo_root)

    if restore_helper_exists:
        try:
            restore_helper_paths = extract_restore_helper_paths(
                restore_helper_path.read_text(encoding="utf-8")
            )
        except (OSError, ValueError) as exc:
            restore_helper_error = str(exc)
    else:
        restore_helper_error = f"Missing restore helper: {restore_helper_path}"

    archive_exists = archive_path.is_file()
    archive_prefix: str | None = None
    archive_error: str | None = None
    archived_helper_paths: list[str] = []

    if archive_exists:
        try:
            with zipfile.ZipFile(archive_path) as archive:
                names = archive.namelist()
                archive_prefix = determine_archive_prefix(names)
                available = set(names)
                for relative_path in restore_helper_paths:
                    candidate = f"{archive_prefix}{relative_path}"
                    if candidate in available:
                        archived_helper_paths.append(relative_path)
        except (OSError, ValueError, zipfile.BadZipFile) as exc:
            archive_error = str(exc)
    else:
        archive_error = f"Missing archive: {archive_path}"

    missing_helper_paths = [
        relative_path
        for relative_path in restore_helper_paths
        if relative_path not in archived_helper_paths
    ]
    missing_issue11_paths = [
        relative_path
        for relative_path in missing_helper_paths
        if is_issue11_reentry_helper_path(relative_path)
    ]

    if restore_helper_error is not None:
        status = "restore-helper-error"
    elif archive_error is not None:
        status = "archive-error"
    elif missing_helper_paths:
        status = "stale-helper-surface"
    else:
        status = "ready"

    return {
        "ok": status == "ready",
        "status": status,
        "repo_root": str(repo_root),
        "memory_root": str(memory_root),
        "archive_path": str(archive_path),
        "archive_exists": archive_exists,
        "archive_prefix": archive_prefix,
        "restore_helper_path": str(restore_helper_path),
        "restore_helper_exists": restore_helper_exists,
        "restore_helper_error": restore_helper_error,
        "archive_error": archive_error,
        "helper_surface_count": len(restore_helper_paths),
        "archived_helper_count": len(archived_helper_paths),
        "missing_helper_paths": missing_helper_paths,
        "missing_issue11_paths": missing_issue11_paths,
        "restored_destination": str(restored_destination),
        "suggested_sync_surface_check_command": build_restore_command(
            repo_root,
            memory_root,
            archive_path,
            restored_destination,
            sync_only=False,
            check_only=True,
        ),
        "suggested_sync_restore_command": build_restore_command(
            repo_root,
            memory_root,
            archive_path,
            restored_destination,
            sync_only=False,
            check_only=False,
        ),
        "suggested_sync_only_check_command": build_restore_command(
            repo_root,
            memory_root,
            archive_path,
            restored_destination,
            sync_only=True,
            check_only=True,
        ),
        "suggested_sync_only_command": build_restore_command(
            repo_root,
            memory_root,
            archive_path,
            restored_destination,
            sync_only=True,
            check_only=False,
        ),
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Memory root: {result['memory_root']}")
    print(f"Archive: {result['archive_path']}")
    print(f"Status: {result['status']}")
    print(f"Restore helper paths: {result['helper_surface_count']}")
    print(f"Archived helper paths: {result['archived_helper_count']}")
    print(f"Default restore destination: {result['restored_destination']}")

    if result["restore_helper_error"]:
        print(f"Restore helper error: {result['restore_helper_error']}")
    if result["archive_error"]:
        print(f"Archive error: {result['archive_error']}")
    if result["archive_prefix"]:
        print(f"Archive prefix: {result['archive_prefix']}")

    if result["missing_helper_paths"]:
        print("Missing helper-surface paths from archive:")
        for relative_path in result["missing_helper_paths"]:
            print(f"  - {relative_path}")

    if result["ok"]:
        print("Saved snapshot archive helper-surface check passed.")
        return

    print("Saved snapshot archive helper-surface check failed.")
    if result["missing_issue11_paths"]:
        print(
            "Suggested next step: use the synced restore path before trusting "
            "the issue #11 helper stack from the restored checkout."
        )
        print("Suggested synced restore surface check:")
        print(f"  {result['suggested_sync_surface_check_command']}")
        print("Suggested synced restore command:")
        print(f"  {result['suggested_sync_restore_command']}")
        print("Suggested in-place helper refresh check for an existing restore:")
        print(f"  {result['suggested_sync_only_check_command']}")
        print("Suggested in-place helper refresh command for an existing restore:")
        print(f"  {result['suggested_sync_only_command']}")
    elif result["missing_helper_paths"]:
        print(
            "Suggested next step: refresh the restored checkout helper surface "
            "or widen the archive before future restore-based reruns."
        )


def make_restore_helper_script(*helper_surface_paths: str) -> str:
    lines = ["#!/usr/bin/env bash", "", "declare -a HELPER_SURFACE_PATHS=("]
    lines.extend(f'    "{path}"' for path in helper_surface_paths)
    lines.append(")")
    lines.append("")
    return "\n".join(lines)


def write_archive(archive_path: Path, *relative_paths: str) -> None:
    archive_path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive_path, "w") as archive:
        for relative_path in relative_paths:
            archive.writestr(f"{EXPECTED_ARCHIVE_PREFIX}{relative_path}", "x")


class Issue11SavedSnapshotHelperSurfaceTests(unittest.TestCase):
    def test_extract_restore_helper_paths(self) -> None:
        script = make_restore_helper_script(
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
        )
        self.assertEqual(
            extract_restore_helper_paths(script),
            [
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
            ],
        )

    def test_classifies_staged_toolchain_route_paths_as_issue11_reentry_hints(self) -> None:
        self.assertTrue(
            is_issue11_reentry_helper_path(
                "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md"
            )
        )
        self.assertTrue(
            is_issue11_reentry_helper_path(
                "scripts/check_issue3_staged_rust_toolchain_candidates.py"
            )
        )
        self.assertFalse(
            is_issue11_reentry_helper_path(
                "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
            )
        )

    def test_reports_stale_archive_when_issue11_helper_paths_are_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            archive_path = memory_root / "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
            restore_helper = repo_root / RESTORE_HELPER_RELATIVE_PATH
            restore_helper.parent.mkdir(parents=True, exist_ok=True)
            restore_helper.write_text(
                make_restore_helper_script(
                    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                    "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
                    "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
                    "scripts/check_issue11_saved_memory_helper_contract.py",
                ),
                encoding="utf-8",
            )
            write_archive(archive_path, "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md")

            result = collect_results(repo_root, memory_root, archive_path)

            self.assertFalse(result["ok"])
            self.assertEqual(result["status"], "stale-helper-surface")
            self.assertIn(
                "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
                result["missing_helper_paths"],
            )
            self.assertIn(
                "scripts/check_issue11_saved_memory_helper_contract.py",
                result["missing_issue11_paths"],
            )
            self.assertIn(
                "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
                result["missing_issue11_paths"],
            )
            self.assertIn("--sync-helper-surface", result["suggested_sync_surface_check_command"])
            self.assertIn("--sync-helper-surface", result["suggested_sync_restore_command"])
            self.assertIn("--sync-only", result["suggested_sync_only_check_command"])
            self.assertIn("--sync-only", result["suggested_sync_only_command"])

    def test_passes_when_archive_contains_current_helper_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            archive_path = memory_root / "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
            restore_helper = repo_root / RESTORE_HELPER_RELATIVE_PATH
            restore_helper.parent.mkdir(parents=True, exist_ok=True)
            helper_paths = (
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
                "scripts/check_issue11_saved_memory_helper_contract.py",
            )
            restore_helper.write_text(
                make_restore_helper_script(*helper_paths),
                encoding="utf-8",
            )
            write_archive(archive_path, *helper_paths)

            result = collect_results(repo_root, memory_root, archive_path)

            self.assertTrue(result["ok"])
            self.assertEqual(result["status"], "ready")
            self.assertEqual(result["missing_helper_paths"], [])

    def test_reports_archive_error_when_snapshot_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            archive_path = memory_root / "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
            restore_helper = repo_root / RESTORE_HELPER_RELATIVE_PATH
            restore_helper.parent.mkdir(parents=True, exist_ok=True)
            restore_helper.write_text(
                make_restore_helper_script("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"),
                encoding="utf-8",
            )

            result = collect_results(repo_root, memory_root, archive_path)

            self.assertFalse(result["ok"])
            self.assertEqual(result["status"], "archive-error")
            self.assertIn("Missing archive", result["archive_error"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            Issue11SavedSnapshotHelperSurfaceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    memory_root = (
        Path(args.memory_root).resolve()
        if args.memory_root
        else resolve_default_memory_root(repo_root)
    )
    archive_path = (
        Path(args.archive).resolve()
        if args.archive
        else (memory_root / "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip").resolve()
    )

    result = collect_results(repo_root, memory_root, archive_path)
    if args.json:
        print(json.dumps({"profile": "issue11-saved-snapshot-helper-surface", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())