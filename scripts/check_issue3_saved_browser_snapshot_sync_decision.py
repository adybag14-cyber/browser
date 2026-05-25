#!/usr/bin/env python3

"""Recommend the safest saved-snapshot restore mode for issue #3 re-entry."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shlex
import tempfile
import unittest
import zipfile


DEFAULT_ARCHIVE_NAME = "01-browser-fork-headed-mode-foundation.zip"
DEFAULT_DESTINATION_NAME = "browser-memory-snapshot"
RESTORE_HELPER_PATH = "scripts/linux/restore_saved_browser_snapshot.sh"
HELPER_SURFACE_LINE_RE = re.compile(r'^\s*"([^"]+)"\s*$')


def shell_join(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Recommend whether the saved browser snapshot route should use a "
            "plain restore, --sync-helper-surface, or --sync-only."
        )
    )
    parser.add_argument("--repo-root", default=os.getcwd(), help="Live browser repo root.")
    parser.add_argument(
        "--helper-root",
        default=None,
        help="Repo root that contains the current restore helper surface (default: repo root).",
    )
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Memory root that contains repo_archives/browser (default: inferred).",
    )
    parser.add_argument(
        "--archive",
        default=None,
        help="Saved browser snapshot zip path (default: inferred from memory root).",
    )
    parser.add_argument(
        "--destination",
        default=None,
        help="Restored checkout path (default: inferred browser-memory-snapshot path).",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON output.")
    parser.add_argument("--self-test", action="store_true", help="Run unit tests and exit.")
    return parser.parse_args()


def resolve_workspace_companion_path(root: Path, name: str) -> Path:
    child = root / name
    sibling = root.parent / name
    if child.exists():
        return child.resolve()
    if root.name == "workspace":
        return child.resolve()
    return sibling.resolve()


def infer_memory_root(repo_root: Path, explicit_memory_root: str | None) -> Path:
    if explicit_memory_root:
        return Path(explicit_memory_root).resolve()
    for candidate in (
        repo_root.parent / "memory",
        repo_root / "memory",
        Path("/workspace/memory"),
    ):
        if candidate.is_dir():
            return candidate.resolve()
    return (repo_root.parent / "memory").resolve()


def infer_archive_path(memory_root: Path, explicit_archive: str | None) -> Path:
    if explicit_archive:
        return Path(explicit_archive).resolve()
    return (memory_root / "repo_archives" / "browser" / DEFAULT_ARCHIVE_NAME).resolve()


def infer_destination(repo_root: Path, explicit_destination: str | None) -> Path:
    if explicit_destination:
        return Path(explicit_destination).resolve()
    return resolve_workspace_companion_path(repo_root, DEFAULT_DESTINATION_NAME)


def extract_helper_surface_paths(restore_helper_text: str) -> list[str]:
    marker = "declare -a HELPER_SURFACE_PATHS=("
    in_block = False
    paths: list[str] = []
    for line in restore_helper_text.splitlines():
        stripped = line.strip()
        if not in_block:
            if stripped == marker:
                in_block = True
            continue
        if stripped == ")":
            break
        match = HELPER_SURFACE_LINE_RE.match(line)
        if match is not None:
            paths.append(match.group(1))
    if not in_block:
        raise ValueError(f"Could not find HELPER_SURFACE_PATHS in {RESTORE_HELPER_PATH}")
    if not paths:
        raise ValueError(f"HELPER_SURFACE_PATHS is empty in {RESTORE_HELPER_PATH}")
    return paths


def infer_top_level_folder(archive_names: set[str]) -> str:
    prefixes = {
        name.split("/", 1)[0]
        for name in archive_names
        if "/" in name and name.split("/", 1)[0]
    }
    return next(iter(prefixes)) if len(prefixes) == 1 else ""


def load_archive_names(archive_path: Path) -> set[str]:
    with zipfile.ZipFile(archive_path) as archive:
        bad_member = archive.testzip()
        if bad_member is not None:
            raise ValueError(f"Snapshot archive failed CRC validation at: {bad_member}")
        return set(archive.namelist())


def missing_helper_surface_paths(helper_root: Path, archive_path: Path) -> list[str]:
    restore_helper = helper_root / RESTORE_HELPER_PATH
    if not restore_helper.is_file():
        raise FileNotFoundError(f"Missing restore helper: {restore_helper}")
    helper_paths = extract_helper_surface_paths(restore_helper.read_text(encoding="utf-8"))
    archive_names = load_archive_names(archive_path)
    top_level = infer_top_level_folder(archive_names)
    prefix = f"{top_level}/" if top_level else ""
    return [path for path in helper_paths if f"{prefix}{path}" not in archive_names]


def build_restore_command(
    *,
    helper_root: Path,
    repo_root: Path,
    memory_root: Path,
    archive_path: Path,
    destination: Path,
    mode_flag: str | None = None,
) -> str:
    parts = [
        "bash",
        str((helper_root / RESTORE_HELPER_PATH).resolve()),
        "--browser-root",
        str(repo_root),
        "--helper-root",
        str(helper_root),
        "--memory-root",
        str(memory_root),
        "--archive",
        str(archive_path),
        "--destination",
        str(destination),
    ]
    if mode_flag:
        parts.append(mode_flag)
    return shell_join(parts)


def build_restored_checkout_check(helper_root: Path, destination: Path) -> str:
    return shell_join(
        [
            "python",
            str((helper_root / "scripts/check_issue3_restored_checkout.py").resolve()),
            "--repo-root",
            str(destination),
        ]
    )


def decide_restore_mode(*, destination_exists: bool, missing_paths: list[str]) -> tuple[str, str]:
    if destination_exists and missing_paths:
        return (
            "sync-only",
            "A restored checkout already exists and the saved archive is missing current helper-surface paths.",
        )
    if destination_exists:
        return (
            "reuse-existing-checkout",
            "A restored checkout already exists and the saved archive already carries the current helper surface.",
        )
    if missing_paths:
        return (
            "sync-helper-surface",
            "The saved archive is missing current helper-surface paths, so the first restore should overlay them.",
        )
    return (
        "plain-restore",
        "The saved archive already carries the current helper surface, so a plain restore is sufficient.",
    )


def collect_result(
    *,
    repo_root: Path,
    helper_root: Path,
    memory_root: Path,
    archive_path: Path,
    destination: Path,
) -> dict[str, object]:
    missing_paths = missing_helper_surface_paths(helper_root, archive_path)
    destination_exists = destination.exists()
    recommendation, reason = decide_restore_mode(
        destination_exists=destination_exists,
        missing_paths=missing_paths,
    )
    plain_restore = build_restore_command(
        helper_root=helper_root,
        repo_root=repo_root,
        memory_root=memory_root,
        archive_path=archive_path,
        destination=destination,
    )
    synced_restore = build_restore_command(
        helper_root=helper_root,
        repo_root=repo_root,
        memory_root=memory_root,
        archive_path=archive_path,
        destination=destination,
        mode_flag="--sync-helper-surface",
    )
    sync_only = build_restore_command(
        helper_root=helper_root,
        repo_root=repo_root,
        memory_root=memory_root,
        archive_path=archive_path,
        destination=destination,
        mode_flag="--sync-only",
    )
    restored_checkout_check = build_restored_checkout_check(helper_root, destination)
    recommended_command = {
        "plain-restore": plain_restore,
        "sync-helper-surface": synced_restore,
        "sync-only": sync_only,
        "reuse-existing-checkout": restored_checkout_check,
    }[recommendation]
    return {
        "repo_root": str(repo_root),
        "helper_root": str(helper_root),
        "memory_root": str(memory_root),
        "archive_path": str(archive_path),
        "destination": str(destination),
        "destination_exists": destination_exists,
        "missing_helper_surface_paths": missing_paths,
        "missing_helper_surface_count": len(missing_paths),
        "recommendation": recommendation,
        "reason": reason,
        "commands": {
            "plain_restore": plain_restore,
            "sync_helper_surface_restore": synced_restore,
            "sync_only_refresh": sync_only,
            "restored_checkout_check": restored_checkout_check,
            "recommended": recommended_command,
        },
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #3 saved snapshot sync decision")
    print()
    print(f"Repo root: {result['repo_root']}")
    print(f"Helper root: {result['helper_root']}")
    print(f"Memory root: {result['memory_root']}")
    print(f"Snapshot archive: {result['archive_path']}")
    print(f"Restore destination: {result['destination']}")
    print(f"Destination exists: {'yes' if result['destination_exists'] else 'no'}")
    print(f"Recommendation: {result['recommendation']}")
    print(f"Reason: {result['reason']}")
    print()
    missing_paths = result["missing_helper_surface_paths"]
    if missing_paths:
        print("Missing helper-surface paths in the saved archive:")
        for path in missing_paths:
            print(f"  - {path}")
    else:
        print("The saved archive already contains every current helper-surface path.")
    print()
    print("Suggested commands:")
    commands = result["commands"]
    print(f"  Recommended: {commands['recommended']}")
    print(f"  Plain restore: {commands['plain_restore']}")
    print(f"  Restore with sync-helper-surface: {commands['sync_helper_surface_restore']}")
    print(f"  Sync-only refresh: {commands['sync_only_refresh']}")
    print(f"  Restored-checkout check: {commands['restored_checkout_check']}")


class SyncDecisionTests(unittest.TestCase):
    def write_restore_helper(self, root: Path, helper_paths: list[str]) -> None:
        helper_path = root / RESTORE_HELPER_PATH
        helper_path.parent.mkdir(parents=True, exist_ok=True)
        lines = ['declare -a HELPER_SURFACE_PATHS=(']
        lines.extend(f'    "{path}"' for path in helper_paths)
        lines.append(")")
        helper_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    def write_archive(self, path: Path, entries: list[str]) -> None:
        with zipfile.ZipFile(path, "w") as archive:
            for entry in entries:
                archive.writestr(f"browser-fork-headed-mode-foundation/{entry}", "x")

    def test_recommends_synced_restore_when_archive_is_stale(self) -> None:
        with tempfile.TemporaryDirectory() as tempdir:
            root = Path(tempdir)
            helper_root = root / "repo"
            helper_root.mkdir()
            self.write_restore_helper(helper_root, ["docs/a.md", "scripts/b.py"])
            archive_path = root / DEFAULT_ARCHIVE_NAME
            self.write_archive(archive_path, ["docs/a.md"])
            result = collect_result(
                repo_root=helper_root,
                helper_root=helper_root,
                memory_root=root,
                archive_path=archive_path,
                destination=root / DEFAULT_DESTINATION_NAME,
            )
            self.assertEqual(result["recommendation"], "sync-helper-surface")

    def test_recommends_sync_only_when_destination_exists_and_archive_is_stale(self) -> None:
        with tempfile.TemporaryDirectory() as tempdir:
            root = Path(tempdir)
            helper_root = root / "repo"
            helper_root.mkdir()
            self.write_restore_helper(helper_root, ["docs/a.md", "scripts/b.py"])
            archive_path = root / DEFAULT_ARCHIVE_NAME
            self.write_archive(archive_path, ["docs/a.md"])
            destination = root / DEFAULT_DESTINATION_NAME
            destination.mkdir()
            result = collect_result(
                repo_root=helper_root,
                helper_root=helper_root,
                memory_root=root,
                archive_path=archive_path,
                destination=destination,
            )
            self.assertEqual(result["recommendation"], "sync-only")

    def test_recommends_plain_restore_when_archive_matches_helper_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tempdir:
            root = Path(tempdir)
            helper_root = root / "repo"
            helper_root.mkdir()
            self.write_restore_helper(helper_root, ["docs/a.md", "scripts/b.py"])
            archive_path = root / DEFAULT_ARCHIVE_NAME
            self.write_archive(archive_path, ["docs/a.md", "scripts/b.py"])
            result = collect_result(
                repo_root=helper_root,
                helper_root=helper_root,
                memory_root=root,
                archive_path=archive_path,
                destination=root / DEFAULT_DESTINATION_NAME,
            )
            self.assertEqual(result["recommendation"], "plain-restore")

    def test_recommends_reuse_existing_when_destination_exists_and_archive_matches(self) -> None:
        with tempfile.TemporaryDirectory() as tempdir:
            root = Path(tempdir)
            helper_root = root / "repo"
            helper_root.mkdir()
            self.write_restore_helper(helper_root, ["docs/a.md"])
            archive_path = root / DEFAULT_ARCHIVE_NAME
            self.write_archive(archive_path, ["docs/a.md"])
            destination = root / DEFAULT_DESTINATION_NAME
            destination.mkdir()
            result = collect_result(
                repo_root=helper_root,
                helper_root=helper_root,
                memory_root=root,
                archive_path=archive_path,
                destination=destination,
            )
            self.assertEqual(result["recommendation"], "reuse-existing-checkout")


def main() -> int:
    args = parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SyncDecisionTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    helper_root = Path(args.helper_root).resolve() if args.helper_root else repo_root
    memory_root = infer_memory_root(repo_root, args.memory_root)
    archive_path = infer_archive_path(memory_root, args.archive)
    destination = infer_destination(repo_root, args.destination)

    result = collect_result(
        repo_root=repo_root,
        helper_root=helper_root,
        memory_root=memory_root,
        archive_path=archive_path,
        destination=destination,
    )
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())