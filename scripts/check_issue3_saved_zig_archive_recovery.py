#!/usr/bin/env python3

"""Surface saved Zig archive recovery candidates for the issue #3 route."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import shlex
import sys
import tempfile
import unittest


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"(\d+)\.(\d+)\.(\d+)")
ARCHIVE_PATTERNS = ("zig*.tar", "zig*.tar.gz", "zig*.tgz", "zig*.tar.xz", "zig*.zip")
DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"


def parse_semver(text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.search(text)
    if match is None:
        raise ValueError(f"Could not parse semantic version from {text!r}")
    return tuple(int(part) for part in match.groups())


def classify_version(expected: str, actual: str) -> str:
    actual_parts = parse_semver(actual)
    expected_parts = parse_semver(expected)
    if actual_parts < expected_parts:
        return "older-than-minimum"
    if actual_parts[:2] == expected_parts[:2]:
        return "matches-expected-line"
    return "mismatched-line"


def normalize_saved_archives_root(saved_archives_root: pathlib.Path) -> pathlib.Path:
    dependencies_root = saved_archives_root / "dependencies"
    if dependencies_root.is_dir():
        return dependencies_root.resolve()
    return saved_archives_root.resolve()


def resolve_default_saved_archives_root(repo_root: pathlib.Path) -> pathlib.Path:
    return normalize_saved_archives_root(repo_root.parent / "memory" / "repo_archives" / "browser")


def resolve_default_toolchains_root(repo_root: pathlib.Path) -> pathlib.Path:
    return (repo_root.parent / "toolchains").resolve()


def resolve_default_fallback_archive(repo_root: pathlib.Path) -> pathlib.Path | None:
    candidate = (repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve()
    return candidate if candidate.is_file() else None


def load_minimum_zig(repo_root: pathlib.Path) -> str:
    zon_path = repo_root / "build.zig.zon"
    text = zon_path.read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError(f"Could not find minimum_zig_version in {zon_path}")
    return match.group(1)


def discover_zig_archives(root: pathlib.Path) -> list[pathlib.Path]:
    if not root.exists() or not root.is_dir():
        return []

    discovered: list[pathlib.Path] = []
    seen: set[pathlib.Path] = set()
    for pattern in ARCHIVE_PATTERNS:
        for path in sorted(root.glob(pattern)):
            resolved = path.resolve()
            if resolved in seen or not resolved.is_file():
                continue
            seen.add(resolved)
            discovered.append(resolved)
    return discovered


def infer_archive_version(path: pathlib.Path) -> str | None:
    match = SEMVER_RE.search(path.name)
    if match is None:
        return None
    return match.group(0)


def describe_archive(expected: str, path: pathlib.Path, source_root: pathlib.Path, source_label: str) -> dict[str, str]:
    version = infer_archive_version(path)
    status = "unknown-version" if version is None else classify_version(expected, version)
    return {
        "path": str(path),
        "version": version or "",
        "status": status,
        "source_root": str(source_root),
        "source_label": source_label,
    }


def discover_archive_reports(
    expected: str,
    search_roots: list[tuple[str, pathlib.Path]],
) -> list[dict[str, str]]:
    reports: list[dict[str, str]] = []
    seen: set[pathlib.Path] = set()
    for label, root in search_roots:
        for path in discover_zig_archives(root):
            resolved = path.resolve()
            if resolved in seen:
                continue
            seen.add(resolved)
            reports.append(describe_archive(expected, resolved, root.resolve(), label))
    return reports


def choose_preferred_archive(expected: str, archive_reports: list[dict[str, str]]) -> dict[str, str] | None:
    exact_match = next(
        (
            archive
            for archive in archive_reports
            if archive["status"] == "matches-expected-line" and archive["version"] == expected
        ),
        None,
    )
    if exact_match is not None:
        return exact_match

    return next(
        (archive for archive in archive_reports if archive["status"] == "matches-expected-line"),
        None,
    )


def format_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def build_restore_command(
    repo_root: pathlib.Path,
    toolchains_root: pathlib.Path,
    archive_path: pathlib.Path,
    *,
    check_only: bool,
) -> list[str]:
    command = [
        "bash",
        str(repo_root / "scripts" / "linux" / "restore_zig_toolchain_archive.sh"),
        "--browser-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
        "--archive",
        str(archive_path),
    ]
    if check_only:
        command.append("--check-only")
    return command


def build_fallback_restore_command(
    repo_root: pathlib.Path,
    toolchains_root: pathlib.Path,
    archive_path: pathlib.Path,
    *,
    check_only: bool,
) -> list[str]:
    command = [
        "bash",
        str(repo_root / "scripts" / "linux" / "restore_issue3_fallback_zig_toolchain.sh"),
        "--browser-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
        "--archive",
        str(archive_path),
    ]
    if check_only:
        command.append("--check-only")
    return command


def build_report(
    *,
    repo_root: pathlib.Path,
    toolchains_root: pathlib.Path,
    minimum_zig: str,
    search_roots: list[tuple[str, pathlib.Path]],
    archive_reports: list[dict[str, str]],
    preferred_archive: dict[str, str] | None,
    fallback_archive: pathlib.Path | None,
) -> dict[str, object]:
    report: dict[str, object] = {
        "status": "passed" if preferred_archive is not None else "failed",
        "repo_root": str(repo_root),
        "toolchains_root": str(toolchains_root),
        "minimum_zig": minimum_zig,
        "search_roots": [
            {"label": label, "path": str(path.resolve())}
            for label, path in search_roots
        ],
        "zig_archives": archive_reports,
        "preferred_archive": preferred_archive,
        "fallback_archive": str(fallback_archive) if fallback_archive is not None else "",
    }

    commands: dict[str, str] = {}
    if preferred_archive is not None:
        archive_path = pathlib.Path(preferred_archive["path"])
        commands["restore_check"] = format_command(
            build_restore_command(repo_root, toolchains_root, archive_path, check_only=True)
        )
        commands["restore"] = format_command(
            build_restore_command(repo_root, toolchains_root, archive_path, check_only=False)
        )
    if fallback_archive is not None:
        commands["fallback_restore_check"] = format_command(
            build_fallback_restore_command(repo_root, toolchains_root, fallback_archive, check_only=True)
        )
        commands["fallback_restore"] = format_command(
            build_fallback_restore_command(repo_root, toolchains_root, fallback_archive, check_only=False)
        )
    report["commands"] = commands

    failures: list[str] = []
    if preferred_archive is None:
        expected_prefix = f"{parse_semver(minimum_zig)[0]}.{parse_semver(minimum_zig)[1]}.x"
        failures.append(
            f"no discovered Zig archive matches the branch's expected {expected_prefix} line"
        )
        if fallback_archive is None:
            failures.append("no surfaced fallback Zig archive is available beside the repo workspace")
    report["failures"] = failures
    return report


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Surface saved Zig archive recovery candidates for the issue #3 Linux/WSL route."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root (default: current directory)")
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help="Path to repo_archives/browser or repo_archives/browser/dependencies",
    )
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Path to the shared toolchains directory (default: ../toolchains beside the repo)",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional path to the attached fallback Zig archive",
    )
    parser.add_argument(
        "--extra-search-root",
        action="append",
        default=[],
        help="Additional directory to search for Zig archives; can be passed more than once",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of the human-readable summary")
    parser.add_argument("--self-test", action="store_true", help="Run the helper's focused unit tests and exit")
    return parser


class SavedZigArchiveRecoveryHelperTests(unittest.TestCase):
    def test_normalize_saved_archives_root_prefers_dependencies_subdirectory(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            dependencies = root / "dependencies"
            dependencies.mkdir()
            self.assertEqual(normalize_saved_archives_root(root), dependencies.resolve())

    def test_discover_archive_reports_deduplicates_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            archives = root / "archives"
            fallback = root / "fallback"
            archives.mkdir()
            fallback.mkdir()
            archive = archives / "zig-linux-x86_64-0.15.2.tar.xz"
            archive.write_text("a", encoding="utf-8")
            linked = fallback / archive.name
            linked.symlink_to(archive)

            reports = discover_archive_reports(
                "0.15.2",
                [("saved-archives", archives), ("fallback", fallback)],
            )

            self.assertEqual(len(reports), 1)
            self.assertEqual(reports[0]["source_label"], "saved-archives")

    def test_choose_preferred_archive_prefers_exact_version(self) -> None:
        reports = [
            {
                "path": "/tmp/zig-0.15.7.tar.xz",
                "version": "0.15.7",
                "status": "matches-expected-line",
                "source_root": "/tmp",
                "source_label": "saved-archives",
            },
            {
                "path": "/tmp/zig-0.15.2.tar.xz",
                "version": "0.15.2",
                "status": "matches-expected-line",
                "source_root": "/tmp",
                "source_label": "saved-archives",
            },
        ]
        preferred = choose_preferred_archive("0.15.2", reports)
        self.assertIsNotNone(preferred)
        assert preferred is not None
        self.assertEqual(preferred["version"], "0.15.2")

    def test_build_report_surfaces_fallback_commands_without_matching_archive(self) -> None:
        report = build_report(
            repo_root=pathlib.Path("/tmp/browser"),
            toolchains_root=pathlib.Path("/tmp/toolchains"),
            minimum_zig="0.15.2",
            search_roots=[("saved-archives", pathlib.Path("/tmp/memory/repo_archives/browser/dependencies"))],
            archive_reports=[],
            preferred_archive=None,
            fallback_archive=pathlib.Path("/tmp/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"),
        )
        self.assertEqual(report["status"], "failed")
        commands = report["commands"]
        assert isinstance(commands, dict)
        self.assertIn("fallback_restore_check", commands)
        self.assertIn("fallback_restore", commands)

    def test_build_restore_command_includes_check_only_when_requested(self) -> None:
        command = build_restore_command(
            pathlib.Path("/tmp/browser"),
            pathlib.Path("/tmp/toolchains"),
            pathlib.Path("/tmp/zig-0.15.2.tar.xz"),
            check_only=True,
        )
        self.assertEqual(command[-1], "--check-only")


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedZigArchiveRecoveryHelperTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    saved_archives_root = (
        pathlib.Path(args.saved_archives_root).resolve()
        if args.saved_archives_root
        else resolve_default_saved_archives_root(repo_root)
    )
    saved_archives_root = normalize_saved_archives_root(saved_archives_root)
    toolchains_root = (
        pathlib.Path(args.toolchains_root).resolve()
        if args.toolchains_root
        else resolve_default_toolchains_root(repo_root)
    )
    fallback_archive = (
        pathlib.Path(args.fallback_zig_archive).resolve()
        if args.fallback_zig_archive
        else resolve_default_fallback_archive(repo_root)
    )

    minimum_zig = load_minimum_zig(repo_root)
    search_roots: list[tuple[str, pathlib.Path]] = [("saved-archives", saved_archives_root)]
    for raw_root in args.extra_search_root:
        search_roots.append((f"extra-search:{raw_root}", pathlib.Path(raw_root).resolve()))
    if fallback_archive is not None:
        search_roots.append(("fallback-archive-parent", fallback_archive.parent))

    archive_reports = discover_archive_reports(minimum_zig, search_roots)
    preferred_archive = choose_preferred_archive(minimum_zig, archive_reports)

    report = build_report(
        repo_root=repo_root,
        toolchains_root=toolchains_root,
        minimum_zig=minimum_zig,
        search_roots=search_roots,
        archive_reports=archive_reports,
        preferred_archive=preferred_archive,
        fallback_archive=fallback_archive,
    )

    if args.json:
        print(json.dumps(report, indent=2))
        return 1 if report["failures"] else 0

    print("Issue #3 saved Zig archive recovery")
    print()
    print(f"Repo root:           {repo_root}")
    print(f"Toolchains root:     {toolchains_root}")
    print(f"Minimum Zig line:    {minimum_zig}")
    print(
        "Fallback archive:    "
        f"{fallback_archive if fallback_archive is not None else 'not found beside the repo workspace'}"
    )
    print()
    print("Search roots:")
    for search_root in report["search_roots"]:
        print(f"  - {search_root['label']}: {search_root['path']}")
    print()

    if archive_reports:
        print("Discovered Zig archives:")
        for archive in archive_reports:
            version = archive["version"] or "unknown-version"
            print(
                f"  - {archive['path']} [{version}; {archive['status']}; "
                f"source={archive['source_label']}]"
            )
    else:
        print("Discovered Zig archives: none")

    commands = report["commands"]
    if preferred_archive is not None:
        print()
        print("Preferred restore commands:")
        print(f"  {commands['restore_check']}")
        print(f"  {commands['restore']}")
        return 0

    print()
    print("Saved Zig archive recovery is still blocked:", file=sys.stderr)
    for failure in report["failures"]:
        print(f"  - {failure}", file=sys.stderr)
    if "fallback_restore_check" in commands and "fallback_restore" in commands:
        print("  - the attached fallback archive can still be staged for route discovery:", file=sys.stderr)
        print(f"    {commands['fallback_restore_check']}", file=sys.stderr)
        print(f"    {commands['fallback_restore']}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
