#!/usr/bin/env python3

"""Surface the fallback Zig archive status for the blocked issue #3 route.

This helper keeps one small build-readiness check focused on the builder-attached
fallback Zig bundle. It reads the branch minimum Zig line from build.zig.zon,
finds the fallback archive beside the repo workspace by default, and reports
whether that archive both opens cleanly and matches the branch's expected
major.minor line.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys
import tarfile
import tempfile
import unittest
import zipfile


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)")
ARCHIVE_SEMVER_RE = re.compile(r"(\d+\.\d+\.\d+)")
DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Show whether the surfaced fallback Zig archive matches the branch "
            "minimum Zig line for the issue #3 Linux or WSL re-entry route."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--agent-files-root",
        default=None,
        help="Path to the builder-attached files root (default: ../agent_files beside the repo workspace)",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit path to the fallback Zig archive to inspect",
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


def parse_semver(version_text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.match(version_text)
    if match is None:
        raise ValueError(f"Could not parse semantic version from {version_text!r}")
    return tuple(int(part) for part in match.groups())


def same_version_line(expected_version: str, actual_version: str) -> bool:
    expected_parts = parse_semver(expected_version)
    actual_parts = parse_semver(actual_version)
    return actual_parts[:2] == expected_parts[:2]


def resolve_default_agent_files_root(repo_root: Path) -> Path:
    return (repo_root.parent / "agent_files").resolve()


def load_minimum_zig_version(repo_root: Path) -> str:
    zon_path = repo_root / "build.zig.zon"
    if not zon_path.is_file():
        raise FileNotFoundError(f"{zon_path} not found")

    text = zon_path.read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError(f"Could not find minimum_zig_version in {zon_path}")
    return match.group(1)


def discover_archive(
    *,
    repo_root: Path,
    agent_files_root: Path,
    fallback_zig_archive: Path | None,
) -> tuple[Path, str]:
    if fallback_zig_archive is not None:
        return fallback_zig_archive, "explicit"
    return agent_files_root / DEFAULT_FALLBACK_ZIG, "auto"


def infer_archive_semver(path: Path) -> str | None:
    match = ARCHIVE_SEMVER_RE.search(path.name)
    if match is None:
        return None
    return match.group(1)


def inspect_archive_readability(path: Path) -> tuple[bool, str | None, str | None]:
    try:
        if path.suffix == ".zip":
            with zipfile.ZipFile(path) as archive:
                names = archive.namelist()
                if not names:
                    raise ValueError("archive has no entries")
                bad_member = archive.testzip()
                if bad_member is not None:
                    raise zipfile.BadZipFile(f"CRC failure in {bad_member}")
                return True, f"zip entries={len(names)}", None
        if path.suffixes[-2:] in ([".tar", ".xz"], [".tar", ".gz"]):
            with tarfile.open(path, mode="r:*") as archive:
                members = archive.getmembers()
                if not members:
                    raise ValueError("archive has no members")
                return True, f"tar entries={len(members)}", None
        return True, "integrity check not defined for this archive type", None
    except (tarfile.TarError, zipfile.BadZipFile, ValueError, OSError) as exc:
        return False, None, str(exc)


def describe_archive_status(minimum_zig: str, archive_path: Path) -> dict[str, object]:
    result: dict[str, object] = {
        "path": str(archive_path),
        "exists": archive_path.is_file(),
        "version": None,
        "status": "missing",
        "matches_expected_line": None,
        "archive_readable": None,
        "archive_summary": None,
        "archive_error": None,
    }
    if not archive_path.is_file():
        return result

    archive_readable, archive_summary, archive_error = inspect_archive_readability(archive_path)
    result["archive_readable"] = archive_readable
    result["archive_summary"] = archive_summary
    result["archive_error"] = archive_error
    if not archive_readable:
        result["status"] = "unreadable"
        return result

    archive_version = infer_archive_semver(archive_path)
    result["version"] = archive_version
    if archive_version is None:
        result["status"] = "unknown version"
        return result

    matches = same_version_line(minimum_zig, archive_version)
    result["matches_expected_line"] = matches
    expected_parts = parse_semver(minimum_zig)
    if matches:
        result["status"] = f"matches expected {expected_parts[0]}.{expected_parts[1]}.x line"
    else:
        result["status"] = f"mismatched: expected {expected_parts[0]}.{expected_parts[1]}.x line"
    return result


def collect_result(
    *,
    repo_root: Path,
    agent_files_root: Path,
    fallback_zig_archive: Path | None,
) -> dict[str, object]:
    minimum_zig = load_minimum_zig_version(repo_root)
    archive_path, discovery_mode = discover_archive(
        repo_root=repo_root,
        agent_files_root=agent_files_root,
        fallback_zig_archive=fallback_zig_archive,
    )
    archive_result = describe_archive_status(minimum_zig, archive_path)
    expected_parts = parse_semver(minimum_zig)
    return {
        "profile": "issue3-fallback-zig-archive-surface",
        "repo_root": str(repo_root),
        "agent_files_root": str(agent_files_root),
        "minimum_zig_version": minimum_zig,
        "expected_version_line": f"{expected_parts[0]}.{expected_parts[1]}.x",
        "archive_discovery_mode": discovery_mode,
        "fallback_zig_archive": archive_result,
    }


def emit_text(result: dict[str, object]) -> None:
    archive = result["fallback_zig_archive"]
    print(f"Repo root: {result['repo_root']}")
    print(f"Agent files root: {result['agent_files_root']}")
    print(f"Minimum Zig from build.zig.zon: {result['minimum_zig_version']}")
    print(f"Expected version line: {result['expected_version_line']}")
    print(f"Fallback Zig archive discovery: {result['archive_discovery_mode']}")
    print(f"Fallback Zig archive: {archive['path']}")
    print(f"Archive present: {'yes' if archive['exists'] else 'no'}")
    if archive["archive_readable"] is not None:
        print(f"Archive readable: {'yes' if archive['archive_readable'] else 'no'}")
    if archive["archive_summary"] is not None:
        print(f"Archive summary: {archive['archive_summary']}")
    if archive["archive_error"] is not None:
        print(f"Archive error: {archive['archive_error']}")
    if archive["version"] is not None:
        print(f"Archive version line: {archive['version']}")
    print(f"Archive status: {archive['status']}")


def create_tar_archive(path: Path) -> None:
    payload = path.parent / "payload.txt"
    payload.write_text("zig", encoding="utf-8")
    with tarfile.open(path, "w:xz") as archive:
        archive.add(payload, arcname="payload.txt")


class FallbackZigArchiveTests(unittest.TestCase):
    def test_default_agent_files_root_tracks_workspace_layout(self) -> None:
        repo_root = Path("/tmp/workspace/browser")
        self.assertEqual(resolve_default_agent_files_root(repo_root), Path("/tmp/workspace/agent_files"))

    def test_collect_result_marks_auto_discovered_archive_as_mismatched(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            agent_files_root.mkdir()
            (repo_root / "build.zig.zon").write_text(
                '.{ .minimum_zig_version = "0.15.2", .dependencies = .{}, .paths = .{""}, }\n',
                encoding="utf-8",
            )
            create_tar_archive(agent_files_root / DEFAULT_FALLBACK_ZIG)

            result = collect_result(
                repo_root=repo_root,
                agent_files_root=agent_files_root,
                fallback_zig_archive=None,
            )

            archive = result["fallback_zig_archive"]
            self.assertEqual(result["archive_discovery_mode"], "auto")
            self.assertTrue(archive["exists"])
            self.assertTrue(archive["archive_readable"])
            self.assertEqual(archive["version"], "0.17.0")
            self.assertFalse(archive["matches_expected_line"])
            self.assertIn("mismatched", archive["status"])

    def test_collect_result_accepts_matching_explicit_archive(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            agent_files_root = root / "agent_files"
            explicit_archive = root / "zig-x86_64-linux-0.15.2.tar.xz"
            repo_root.mkdir()
            agent_files_root.mkdir()
            (repo_root / "build.zig.zon").write_text(
                '.{ .minimum_zig_version = "0.15.2", .dependencies = .{}, .paths = .{""}, }\n',
                encoding="utf-8",
            )
            create_tar_archive(explicit_archive)

            result = collect_result(
                repo_root=repo_root,
                agent_files_root=agent_files_root,
                fallback_zig_archive=explicit_archive,
            )

            archive = result["fallback_zig_archive"]
            self.assertEqual(result["archive_discovery_mode"], "explicit")
            self.assertTrue(archive["exists"])
            self.assertTrue(archive["archive_readable"])
            self.assertEqual(archive["version"], "0.15.2")
            self.assertTrue(archive["matches_expected_line"])
            self.assertIn("matches expected 0.15.x line", archive["status"])

    def test_collect_result_reports_missing_archive_without_failing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            agent_files_root.mkdir()
            (repo_root / "build.zig.zon").write_text(
                '.{ .minimum_zig_version = "0.15.2", .dependencies = .{}, .paths = .{""}, }\n',
                encoding="utf-8",
            )

            result = collect_result(
                repo_root=repo_root,
                agent_files_root=agent_files_root,
                fallback_zig_archive=None,
            )

            archive = result["fallback_zig_archive"]
            self.assertFalse(archive["exists"])
            self.assertEqual(archive["status"], "missing")

    def test_collect_result_marks_broken_archive_as_unreadable(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            agent_files_root = root / "agent_files"
            broken_archive = agent_files_root / DEFAULT_FALLBACK_ZIG
            repo_root.mkdir()
            agent_files_root.mkdir()
            (repo_root / "build.zig.zon").write_text(
                '.{ .minimum_zig_version = "0.15.2", .dependencies = .{}, .paths = .{""}, }\n',
                encoding="utf-8",
            )
            broken_archive.write_text("not a real archive", encoding="utf-8")

            result = collect_result(
                repo_root=repo_root,
                agent_files_root=agent_files_root,
                fallback_zig_archive=None,
            )

            archive = result["fallback_zig_archive"]
            self.assertTrue(archive["exists"])
            self.assertFalse(archive["archive_readable"])
            self.assertIsNotNone(archive["archive_error"])
            self.assertEqual(archive["status"], "unreadable")


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(FallbackZigArchiveTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    agent_files_root = (
        Path(args.agent_files_root).resolve() if args.agent_files_root else resolve_default_agent_files_root(repo_root)
    )
    fallback_zig_archive = Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None

    try:
        result = collect_result(
            repo_root=repo_root,
            agent_files_root=agent_files_root,
            fallback_zig_archive=fallback_zig_archive,
        )
    except (FileNotFoundError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0


if __name__ == "__main__":
    sys.exit(main())
