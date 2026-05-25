#!/usr/bin/env python3

"""Surface saved Zig archives that can unblock issue #3 Linux/WSL recovery."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
import tempfile
import unittest


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"(\d+)\.(\d+)\.(\d+)")
ARCHIVE_GLOBS = ("zig*.tar", "zig*.tar.gz", "zig*.tgz", "zig*.tar.xz", "zig*.zip")


def parse_semver(text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.search(text)
    if match is None:
        raise ValueError(f"Could not parse Zig version from {text!r}")
    return tuple(int(part) for part in match.groups())


def same_version_line(expected: str, actual: str) -> bool:
    return parse_semver(expected)[:2] == parse_semver(actual)[:2]


def normalize_saved_archives_root(path: pathlib.Path) -> pathlib.Path:
    dependencies_root = path / "dependencies"
    if dependencies_root.is_dir():
        return dependencies_root.resolve()
    return path.resolve()


def load_minimum_zig(repo_root: pathlib.Path) -> str:
    zon_path = repo_root / "build.zig.zon"
    text = zon_path.read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError(f"Could not find minimum_zig_version in {zon_path}")
    return match.group(1)


def discover_saved_zig_archives(saved_archives_root: pathlib.Path) -> list[pathlib.Path]:
    seen: set[pathlib.Path] = set()
    discovered: list[pathlib.Path] = []
    for pattern in ARCHIVE_GLOBS:
        for path in sorted(saved_archives_root.glob(pattern)):
            resolved = path.resolve()
            if not resolved.is_file() or resolved in seen:
                continue
            seen.add(resolved)
            discovered.append(resolved)
    return discovered


def infer_archive_version(path: pathlib.Path) -> str | None:
    match = SEMVER_RE.search(path.name)
    if match is None:
        return None
    return match.group(0)


def archive_top_level_name(path: pathlib.Path) -> str:
    name = path.name
    for suffix in (".tar.gz", ".tar.xz", ".tgz", ".zip", ".tar"):
        if name.endswith(suffix):
            return name[: -len(suffix)]
    return path.stem


def classify_archive(minimum_zig: str, archive_path: pathlib.Path) -> dict[str, str]:
    version = infer_archive_version(archive_path)
    if version is None:
        status = "unknown-version"
    else:
        minimum_parts = parse_semver(minimum_zig)
        archive_parts = parse_semver(version)
        if archive_parts < minimum_parts:
            status = "older-than-minimum"
        elif same_version_line(minimum_zig, version):
            status = "matches-expected-line"
        else:
            status = "mismatched-line"
    return {
        "path": str(archive_path),
        "top_level": archive_top_level_name(archive_path),
        "version": version or "",
        "status": status,
    }


def pick_preferred_archive(minimum_zig: str, archives: list[dict[str, str]]) -> dict[str, str] | None:
    for archive in archives:
        if archive["status"] == "matches-expected-line" and archive["version"] == minimum_zig:
            return archive
    for archive in archives:
        if archive["status"] == "matches-expected-line":
            return archive
    return None


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


def format_shell_command(parts: list[str]) -> str:
    escaped: list[str] = []
    for part in parts:
        if re.fullmatch(r"[A-Za-z0-9_./:=+-]+", part):
            escaped.append(part)
        else:
            escaped.append("'" + part.replace("'", "'\"'\"'") + "'")
    return " ".join(escaped)


def build_report(
    repo_root: pathlib.Path,
    saved_archives_root: pathlib.Path,
    toolchains_root: pathlib.Path,
    minimum_zig: str,
    archives: list[dict[str, str]],
    preferred_archive: dict[str, str] | None,
) -> dict[str, object]:
    report: dict[str, object] = {
        "status": "passed" if preferred_archive is not None else "failed",
        "repo_root": str(repo_root),
        "saved_archives_root": str(saved_archives_root),
        "toolchains_root": str(toolchains_root),
        "minimum_zig": minimum_zig,
        "saved_zig_archives": archives,
        "preferred_saved_zig_archive": preferred_archive,
    }
    if preferred_archive is not None:
        archive_path = pathlib.Path(preferred_archive["path"])
        report["restore_check_command"] = build_restore_command(
            repo_root,
            toolchains_root,
            archive_path,
            check_only=True,
        )
        report["restore_command"] = build_restore_command(
            repo_root,
            toolchains_root,
            archive_path,
            check_only=False,
        )
    return report


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Find saved Zig archives that match the branch minimum Zig line."
    )
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--saved-archives-root", default=None)
    parser.add_argument("--toolchains-root", default=None)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    return parser


class SavedZigArchiveTests(unittest.TestCase):
    def test_normalize_saved_archives_root_prefers_dependencies_dir(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            deps = root / "dependencies"
            deps.mkdir()
            self.assertEqual(normalize_saved_archives_root(root), deps.resolve())

    def test_discovery_and_preferred_archive_pick_matching_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            older = root / "zig-x86_64-linux-0.14.1.tar.xz"
            matching = root / "zig-x86_64-linux-0.15.7.tar.xz"
            fallback = root / "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
            for path in (older, matching, fallback):
                path.write_text("zig", encoding="utf-8")

            archives = [
                classify_archive("0.15.2", path)
                for path in discover_saved_zig_archives(root)
            ]
            preferred = pick_preferred_archive("0.15.2", archives)

            self.assertEqual(preferred["path"], str(matching))
            self.assertEqual(preferred["status"], "matches-expected-line")

    def test_build_restore_command_uses_existing_branch_helper(self) -> None:
        command = build_restore_command(
            pathlib.Path("/tmp/browser"),
            pathlib.Path("/tmp/toolchains"),
            pathlib.Path("/tmp/memory/zig-x86_64-linux-0.15.7.tar.xz"),
            check_only=True,
        )
        self.assertEqual(command[0], "bash")
        self.assertIn("--archive", command)
        self.assertEqual(command[-1], "--check-only")


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedZigArchiveTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    if not (repo_root / "build.zig.zon").is_file():
        print(f"ERROR: {(repo_root / 'build.zig.zon')} not found", file=sys.stderr)
        return 2

    saved_archives_root = pathlib.Path(args.saved_archives_root).resolve() if args.saved_archives_root else (
        repo_root.parent / "memory" / "repo_archives" / "browser"
    ).resolve()
    saved_archives_root = normalize_saved_archives_root(saved_archives_root)
    toolchains_root = pathlib.Path(args.toolchains_root).resolve() if args.toolchains_root else (
        repo_root.parent / "toolchains"
    ).resolve()

    minimum_zig = load_minimum_zig(repo_root)
    archive_reports = [
        classify_archive(minimum_zig, path)
        for path in discover_saved_zig_archives(saved_archives_root)
    ]
    preferred_archive = pick_preferred_archive(minimum_zig, archive_reports)
    report = build_report(
        repo_root,
        saved_archives_root,
        toolchains_root,
        minimum_zig,
        archive_reports,
        preferred_archive,
    )

    if args.json:
        print(json.dumps(report, indent=2))
        return 0 if preferred_archive is not None else 1

    print("Saved Zig archive recovery check")
    print()
    print(f"Repo root:           {repo_root}")
    print(f"Saved archives root: {saved_archives_root}")
    print(f"Toolchains root:     {toolchains_root}")
    print(f"Minimum Zig line:    {minimum_zig}")
    if archive_reports:
        print("Discovered saved Zig archives:")
        for archive in archive_reports:
            version = archive["version"] or "unknown-version"
            print(
                f"  - {archive['path']} "
                f"[top-level={archive['top_level']}; {version}; {archive['status']}]"
            )
    else:
        print("Discovered saved Zig archives: none")

    if preferred_archive is None:
        print()
        print("No branch-compatible saved Zig archive was found.", file=sys.stderr)
        print(
            "Next: add a Zig 0.15.x archive under the saved archives root or stage a matching toolchain under ../toolchains.",
            file=sys.stderr,
        )
        return 1

    print()
    print("Preferred saved Zig archive:")
    print(f"  {preferred_archive['path']}")
    print("Suggested restore commands:")
    print(f"  {format_shell_command(report['restore_check_command'])}")
    print(f"  {format_shell_command(report['restore_command'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
