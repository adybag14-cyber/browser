#!/usr/bin/env python3

"""Audit the saved browser snapshot archive for issue #3 helper-surface drift."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest
import zipfile


EXPECTED_ARCHIVE_PREFIX = "browser-fork-headed-mode-foundation/"
DEFAULT_ARCHIVE_RELATIVE_PATH = "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"

REQUIRED_ARCHIVE_CORE_PATHS: tuple[tuple[str, str], ...] = (
    ("build.zig", "top-level build entrypoint"),
    ("build.zig.zon", "dependency manifest"),
    ("docs/HEADED_MODE_ROADMAP.md", "headed-mode roadmap"),
    ("docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md", "headed-mode production guide"),
    ("src/browser/Page.zig", "page runtime surface"),
    ("src/display/win32_backend.zig", "Win32 runtime surface"),
)

HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry guide"),
    ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved snapshot restore guide"),
    ("docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md", "saved Memory inputs guide"),
    ("docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md", "saved archive integrity guide"),
    ("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness guide"),
    ("docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md", "Zig toolchain recovery guide"),
    ("docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md", "offline build inputs guide"),
    ("scripts/check_issue3_saved_memory_inputs.py", "saved Memory preflight helper"),
    ("scripts/check_issue3_saved_archive_integrity.py", "saved archive integrity helper"),
    ("scripts/check_issue3_restored_checkout.py", "restored checkout helper"),
    ("scripts/check_linux_build_readiness.py", "Linux build-readiness helper"),
    ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved snapshot route printer"),
    ("scripts/linux/show_issue3_linux_build_readiness_route.sh", "Linux build-readiness route printer"),
    ("scripts/linux/show_issue3_zig_toolchain_recovery_route.sh", "Zig toolchain recovery route printer"),
    ("scripts/linux/show_issue3_offline_build_inputs_route.sh", "offline inputs route printer"),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the saved browser snapshot zip is current enough for the "
            "issue #3 Linux/WSL re-entry helper chain."
        )
    )
    parser.add_argument("--repo-root", default=".", help="Path to the live browser checkout")
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Path to the memory root (default: ../memory beside the repo root)",
    )
    parser.add_argument(
        "--archive-path",
        default=None,
        help="Optional explicit path to the saved repo archive zip",
    )
    parser.add_argument(
        "--helper-root",
        default=None,
        help="Optional explicit path to the live helper checkout to compare against",
    )
    parser.add_argument("--json", action="store_true", help="Emit structured JSON")
    parser.add_argument("--self-test", action="store_true", help="Run focused self-tests")
    return parser


def resolve_default_memory_root(repo_root: Path) -> Path:
    return (repo_root.parent / "memory").resolve()


def resolve_default_archive_path(memory_root: Path) -> Path:
    return (memory_root / DEFAULT_ARCHIVE_RELATIVE_PATH).resolve()


def resolve_default_helper_root(repo_root: Path) -> Path:
    return repo_root.resolve()


def list_archive_members(archive_path: Path) -> tuple[list[str], str | None]:
    with zipfile.ZipFile(archive_path) as archive:
        names = archive.namelist()
        bad_member = archive.testzip()
        if bad_member is not None:
            raise zipfile.BadZipFile(f"CRC failure in {bad_member}")
        return names, EXPECTED_ARCHIVE_PREFIX if any(
            name.startswith(EXPECTED_ARCHIVE_PREFIX) for name in names
        ) else None


def collect_path_presence(
    names: set[str],
    prefix: str | None,
    relative_paths: tuple[tuple[str, str], ...],
) -> list[dict[str, object]]:
    results: list[dict[str, object]] = []
    for relative_path, label in relative_paths:
        archive_member = f"{prefix}{relative_path}" if prefix else relative_path
        results.append(
            {
                "path": relative_path,
                "label": label,
                "archive_member": archive_member,
                "in_archive": archive_member in names,
            }
        )
    return results


def collect_helper_surface(
    names: set[str],
    prefix: str | None,
    helper_root: Path,
) -> list[dict[str, object]]:
    results: list[dict[str, object]] = []
    for relative_path, label in HELPER_SURFACE_PATHS:
        archive_member = f"{prefix}{relative_path}" if prefix else relative_path
        helper_path = helper_root / relative_path
        results.append(
            {
                "path": relative_path,
                "label": label,
                "archive_member": archive_member,
                "in_archive": archive_member in names,
                "in_helper_root": helper_path.is_file(),
            }
        )
    return results


def diagnose_result(
    archive_exists: bool,
    archive_readable: bool,
    archive_prefix: str | None,
    missing_core_paths: list[str],
    helper_only_missing: list[str],
    helper_root_missing: list[str],
) -> str:
    if not archive_exists:
        return "missing-archive"
    if not archive_readable:
        return "unreadable-archive"
    if archive_prefix is None or missing_core_paths:
        return "missing-archive-core-paths"
    if helper_only_missing:
        return "historical-snapshot-missing-helper-surface"
    if helper_root_missing:
        return "helper-root-also-missing-surface"
    return "ready"


def collect_results(
    *,
    repo_root: Path,
    memory_root: Path,
    archive_path: Path,
    helper_root: Path,
) -> dict[str, object]:
    archive_exists = archive_path.is_file()
    archive_readable = False
    archive_prefix: str | None = None
    archive_error: str | None = None
    names: set[str] = set()

    if archive_exists:
        try:
            raw_names, archive_prefix = list_archive_members(archive_path)
            names = set(raw_names)
            archive_readable = True
        except (OSError, zipfile.BadZipFile) as exc:
            archive_error = str(exc)

    core_paths = collect_path_presence(names, archive_prefix, REQUIRED_ARCHIVE_CORE_PATHS)
    helper_surface = collect_helper_surface(names, archive_prefix, helper_root)

    missing_core_paths = [entry["path"] for entry in core_paths if not entry["in_archive"]]
    helper_only_missing = [
        entry["path"]
        for entry in helper_surface
        if not entry["in_archive"] and entry["in_helper_root"]
    ]
    helper_root_missing = [
        entry["path"]
        for entry in helper_surface
        if not entry["in_archive"] and not entry["in_helper_root"]
    ]

    diagnosis = diagnose_result(
        archive_exists,
        archive_readable,
        archive_prefix,
        missing_core_paths,
        helper_only_missing,
        helper_root_missing,
    )

    recommended_command = None
    if diagnosis == "historical-snapshot-missing-helper-surface":
        recommended_command = (
            "bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh "
            f"--repo-root {repo_root} --sync-helper-surface"
        )

    return {
        "profile": "issue3-saved-snapshot-archive-audit",
        "ok": diagnosis == "ready",
        "diagnosis": diagnosis,
        "repo_root": str(repo_root),
        "memory_root": str(memory_root),
        "archive_path": str(archive_path),
        "helper_root": str(helper_root),
        "archive_exists": archive_exists,
        "archive_readable": archive_readable,
        "archive_prefix": archive_prefix,
        "archive_error": archive_error,
        "core_paths": core_paths,
        "helper_surface": helper_surface,
        "missing_core_paths": missing_core_paths,
        "helper_only_missing_paths": helper_only_missing,
        "helper_root_missing_paths": helper_root_missing,
        "recommended_sync_command": recommended_command,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Memory root: {result['memory_root']}")
    print(f"Archive path: {result['archive_path']}")
    print(f"Helper root: {result['helper_root']}")
    print(f"Diagnosis: {result['diagnosis']}")

    if not result["archive_exists"]:
        print("\nSaved snapshot archive is missing.", file=sys.stderr)
        return
    if not result["archive_readable"]:
        print("\nSaved snapshot archive is unreadable.", file=sys.stderr)
        if result["archive_error"]:
            print(f"Archive error: {result['archive_error']}", file=sys.stderr)
        return

    print("\nArchive core paths:")
    for entry in result["core_paths"]:
        status = "PASS" if entry["in_archive"] else "FAIL"
        print(f"  [{status}] {entry['path']}: {entry['label']}")

    print("\nHelper-surface paths:")
    for entry in result["helper_surface"]:
        if entry["in_archive"]:
            status = "PASS"
        elif entry["in_helper_root"]:
            status = "WARN"
        else:
            status = "FAIL"
        print(f"  [{status}] {entry['path']}: {entry['label']}")

    if result["ok"]:
        print("\nSaved snapshot archive check passed.")
        return

    if result["diagnosis"] == "historical-snapshot-missing-helper-surface":
        print(
            "\nThe saved archive looks like a historical snapshot: core browser files are present, "
            "but the newer issue #3 helper surface only exists in the live helper root.",
            file=sys.stderr,
        )
        if result["recommended_sync_command"]:
            print(
                f"Suggested next step: {result['recommended_sync_command']}",
                file=sys.stderr,
            )
    elif result["diagnosis"] == "helper-root-also-missing-surface":
        print(
            "\nThe archive and helper root are both missing part of the expected issue #3 helper surface.",
            file=sys.stderr,
        )
    else:
        print("\nSaved snapshot archive check failed.", file=sys.stderr)


class SavedSnapshotArchiveTests(unittest.TestCase):
    def _write_archive(self, archive_path: Path, members: set[str]) -> None:
        with zipfile.ZipFile(archive_path, "w") as archive:
            for member in sorted(members):
                archive.writestr(member, "ok")

    def _make_helper_root(self, helper_root: Path, include_all: bool) -> None:
        for relative_path, _label in HELPER_SURFACE_PATHS:
            if not include_all and relative_path.endswith("show_issue3_offline_build_inputs_route.sh"):
                continue
            target = helper_root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("ok", encoding="utf-8")

    def test_ready_archive_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            helper_root = repo_root
            memory_root = root / "memory"
            archive_path = memory_root / DEFAULT_ARCHIVE_RELATIVE_PATH
            helper_root.mkdir(parents=True)
            archive_path.parent.mkdir(parents=True, exist_ok=True)

            self._make_helper_root(helper_root, include_all=True)
            members = {
                f"{EXPECTED_ARCHIVE_PREFIX}{relative_path}"
                for relative_path, _label in (*REQUIRED_ARCHIVE_CORE_PATHS, *HELPER_SURFACE_PATHS)
            }
            self._write_archive(archive_path, members)

            result = collect_results(
                repo_root=repo_root,
                memory_root=memory_root,
                archive_path=archive_path,
                helper_root=helper_root,
            )

            self.assertTrue(result["ok"])
            self.assertEqual(result["diagnosis"], "ready")
            self.assertEqual(result["helper_only_missing_paths"], [])

    def test_historical_snapshot_missing_helper_surface_is_detected(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            helper_root = repo_root
            memory_root = root / "memory"
            archive_path = memory_root / DEFAULT_ARCHIVE_RELATIVE_PATH
            helper_root.mkdir(parents=True)
            archive_path.parent.mkdir(parents=True, exist_ok=True)

            self._make_helper_root(helper_root, include_all=True)
            members = {
                f"{EXPECTED_ARCHIVE_PREFIX}{relative_path}"
                for relative_path, _label in REQUIRED_ARCHIVE_CORE_PATHS
            }
            self._write_archive(archive_path, members)

            result = collect_results(
                repo_root=repo_root,
                memory_root=memory_root,
                archive_path=archive_path,
                helper_root=helper_root,
            )

            self.assertFalse(result["ok"])
            self.assertEqual(result["diagnosis"], "historical-snapshot-missing-helper-surface")
            self.assertTrue(result["recommended_sync_command"])
            self.assertIn(
                "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
                result["helper_only_missing_paths"],
            )

    def test_missing_archive_fails_cleanly(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            helper_root = repo_root
            memory_root = root / "memory"
            repo_root.mkdir(parents=True)

            result = collect_results(
                repo_root=repo_root,
                memory_root=memory_root,
                archive_path=memory_root / DEFAULT_ARCHIVE_RELATIVE_PATH,
                helper_root=helper_root,
            )

            self.assertFalse(result["ok"])
            self.assertEqual(result["diagnosis"], "missing-archive")

    def test_missing_core_paths_fail_even_when_helper_surface_exists(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            helper_root = repo_root
            memory_root = root / "memory"
            archive_path = memory_root / DEFAULT_ARCHIVE_RELATIVE_PATH
            helper_root.mkdir(parents=True)
            archive_path.parent.mkdir(parents=True, exist_ok=True)

            self._make_helper_root(helper_root, include_all=True)
            members = {
                f"{EXPECTED_ARCHIVE_PREFIX}{relative_path}"
                for relative_path, _label in HELPER_SURFACE_PATHS
            }
            self._write_archive(archive_path, members)

            result = collect_results(
                repo_root=repo_root,
                memory_root=memory_root,
                archive_path=archive_path,
                helper_root=helper_root,
            )

            self.assertFalse(result["ok"])
            self.assertEqual(result["diagnosis"], "missing-archive-core-paths")
            self.assertIn("build.zig", result["missing_core_paths"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedSnapshotArchiveTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    memory_root = Path(args.memory_root).resolve() if args.memory_root else resolve_default_memory_root(repo_root)
    archive_path = Path(args.archive_path).resolve() if args.archive_path else resolve_default_archive_path(memory_root)
    helper_root = Path(args.helper_root).resolve() if args.helper_root else resolve_default_helper_root(repo_root)

    result = collect_results(
        repo_root=repo_root,
        memory_root=memory_root,
        archive_path=archive_path,
        helper_root=helper_root,
    )
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
