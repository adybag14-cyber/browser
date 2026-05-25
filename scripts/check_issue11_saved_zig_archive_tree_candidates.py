#!/usr/bin/env python3

"""Surface saved Zig archive candidates across the full Memory archive tree.

This helper exists for the issue #11 Linux/WSL readiness lane. It is a smaller,
create-only workaround for cases where runs need to inspect the broader
repo_archives/browser tree instead of assuming every useful Zig archive lives
under the dependencies/ subdirectory.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import shlex
import sys
import tarfile
import tempfile
import unittest
import zipfile


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"(\d+)\.(\d+)\.(\d+)")
ARCHIVE_PATTERNS = ("*.tar", "*.tar.gz", "*.tgz", "*.tar.xz", "*.zip")
DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
ZIG_BINARY_SUFFIXES = ("/zig", "/bin/zig", "/zig.exe", "/bin/zig.exe")


def parse_semver(text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.search(text)
    if match is None:
        raise ValueError(f"Could not parse semantic version from {text!r}")
    return tuple(int(part) for part in match.groups())


def same_version_line(expected: str, actual: str) -> bool:
    return parse_semver(expected)[:2] == parse_semver(actual)[:2]


def classify_version(expected: str, actual: str) -> str:
    actual_parts = parse_semver(actual)
    expected_parts = parse_semver(expected)
    if actual_parts < expected_parts:
        return "older-than-minimum"
    if actual_parts[:2] == expected_parts[:2]:
        return "matches-expected-line"
    return "mismatched-line"


def resolve_default_saved_archives_root(repo_root: pathlib.Path) -> pathlib.Path:
    return (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()


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


def strip_archive_suffix(name: str) -> str:
    for suffix in (".tar.gz", ".tar.xz", ".tgz", ".zip", ".tar"):
        if name.endswith(suffix):
            return name[: -len(suffix)]
    return pathlib.Path(name).stem


def archive_member_names(path: pathlib.Path) -> list[str]:
    try:
        if zipfile.is_zipfile(path):
            with zipfile.ZipFile(path) as archive:
                return archive.namelist()
        if tarfile.is_tarfile(path):
            with tarfile.open(path) as archive:
                return archive.getnames()
    except (OSError, tarfile.TarError, zipfile.BadZipFile):
        return []
    return []


def first_top_level(entries: list[str]) -> str | None:
    names: list[str] = []
    for raw_name in entries:
        if not raw_name or raw_name.startswith("__MACOSX/"):
            continue
        normalized = raw_name[2:] if raw_name.startswith("./") else raw_name
        if normalized:
            names.append(normalized)

    if not names:
        return None

    top_levels = sorted({name.rstrip("/").split("/", 1)[0] for name in names if name.rstrip("/")})
    if len(top_levels) != 1:
        return None

    top_level = top_levels[0]
    if not any(name.startswith(f"{top_level}/") for name in names):
        return None
    return top_level


def infer_archive_top_level(path: pathlib.Path) -> str | None:
    return first_top_level(archive_member_names(path))


def infer_archive_version(path: pathlib.Path) -> tuple[str | None, str]:
    top_level = infer_archive_top_level(path)
    candidates = [top_level, strip_archive_suffix(path.name), path.name]
    for candidate in candidates:
        if not candidate:
            continue
        match = SEMVER_RE.search(candidate)
        if match is not None:
            return match.group(0), top_level or ""
    return None, top_level or ""


def archive_contains_zig_binary(entries: list[str]) -> bool:
    for member_name in entries:
        normalized = member_name.rstrip("/")
        if any(normalized.endswith(suffix) for suffix in ZIG_BINARY_SUFFIXES):
            return True
    return False


def looks_like_zig_toolchain_archive(path: pathlib.Path, version: str | None, top_level: str) -> bool:
    entries = archive_member_names(path)
    if not entries:
        return False

    candidate_names = (top_level, strip_archive_suffix(path.name), path.name)
    if version is not None:
        for candidate in candidate_names:
            if candidate and strip_archive_suffix(candidate).startswith("zig"):
                return True
    return archive_contains_zig_binary(entries)


def discover_zig_archives(root: pathlib.Path) -> list[pathlib.Path]:
    if not root.exists() or not root.is_dir():
        return []

    discovered: list[pathlib.Path] = []
    seen: set[pathlib.Path] = set()
    for pattern in ARCHIVE_PATTERNS:
        for path in sorted(root.rglob(pattern)):
            resolved = path.resolve()
            if resolved in seen or not resolved.is_file():
                continue
            seen.add(resolved)

            version, top_level = infer_archive_version(resolved)
            if not looks_like_zig_toolchain_archive(resolved, version, top_level):
                continue
            discovered.append(resolved)
    return discovered


def describe_archive(expected: str, path: pathlib.Path) -> dict[str, str]:
    version, top_level = infer_archive_version(path)
    status = "unknown-version" if version is None else classify_version(expected, version)
    return {
        "path": str(path),
        "top_level": top_level,
        "version": version or "",
        "status": status,
    }


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

    matching_archives = [
        archive
        for archive in archive_reports
        if archive["status"] == "matches-expected-line" and archive["version"]
    ]
    if not matching_archives:
        return None

    return max(matching_archives, key=lambda archive: parse_semver(archive["version"]))


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


def build_report(
    *,
    repo_root: pathlib.Path,
    saved_archives_root: pathlib.Path,
    toolchains_root: pathlib.Path,
    minimum_zig: str,
    archive_reports: list[dict[str, str]],
    preferred_archive: dict[str, str] | None,
    fallback_archive: pathlib.Path | None,
) -> dict[str, object]:
    report: dict[str, object] = {
        "status": "passed" if preferred_archive is not None else "failed",
        "repo_root": str(repo_root),
        "saved_archives_root": str(saved_archives_root),
        "toolchains_root": str(toolchains_root),
        "minimum_zig": minimum_zig,
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
    report["commands"] = commands

    failures: list[str] = []
    if preferred_archive is None:
        expected_prefix = f"{parse_semver(minimum_zig)[0]}.{parse_semver(minimum_zig)[1]}.x"
        failures.append(
            f"no saved Zig archive under {saved_archives_root} matches the branch's expected {expected_prefix} line"
        )
        if fallback_archive is None:
            failures.append("no surfaced fallback Zig archive is available beside the repo workspace")
    report["failures"] = failures
    return report


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Surface saved Zig archive candidates across the full issue #11 Memory tree."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root (default: current directory)")
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help="Path to repo_archives/browser or any subdirectory that may contain saved Zig archives",
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
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of the human-readable summary")
    parser.add_argument("--self-test", action="store_true", help="Run the helper's focused unit tests and exit")
    return parser


class SavedZigArchiveTreeHelperTests(unittest.TestCase):
    def test_default_saved_archives_root_uses_browser_root(self) -> None:
        repo_root = pathlib.Path("/tmp/workspace/browser")
        self.assertEqual(
            resolve_default_saved_archives_root(repo_root),
            pathlib.Path("/tmp/workspace/memory/repo_archives/browser"),
        )

    def test_discover_zig_archives_finds_nested_archive_outside_dependencies(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            (root / "dependencies").mkdir()
            nested = root / "toolchains-cache"
            nested.mkdir()
            archive_path = nested / "saved-zig-toolchain.tar.xz"
            top_level = "zig-linux-x86_64-0.15.2"
            extracted_file = root / top_level / "zig"
            extracted_file.parent.mkdir(parents=True)
            extracted_file.write_text("zig", encoding="utf-8")
            with tarfile.open(archive_path, "w:xz") as archive:
                archive.add(extracted_file.parent, arcname=top_level)

            discovered = discover_zig_archives(root)

            self.assertEqual(discovered, [archive_path.resolve()])

    def test_discover_zig_archives_accepts_dependencies_subdirectory_input(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            dependencies = root / "dependencies"
            dependencies.mkdir()
            archive_path = dependencies / "zig-linux-x86_64-0.15.2.zip"
            with zipfile.ZipFile(archive_path, "w") as archive:
                archive.writestr("zig-linux-x86_64-0.15.2/zig", "binary")

            discovered = discover_zig_archives(dependencies)

            self.assertEqual(discovered, [archive_path.resolve()])

    def test_choose_preferred_archive_prefers_exact_version(self) -> None:
        reports = [
            {"path": "/tmp/zig-0.15.7.tar.xz", "version": "0.15.7", "status": "matches-expected-line"},
            {"path": "/tmp/zig-0.15.2.tar.xz", "version": "0.15.2", "status": "matches-expected-line"},
        ]
        preferred = choose_preferred_archive("0.15.2", reports)
        self.assertIsNotNone(preferred)
        assert preferred is not None
        self.assertEqual(preferred["version"], "0.15.2")


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedZigArchiveTreeHelperTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    saved_archives_root = (
        pathlib.Path(args.saved_archives_root).resolve()
        if args.saved_archives_root
        else resolve_default_saved_archives_root(repo_root)
    )
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
    archive_reports = [describe_archive(minimum_zig, path) for path in discover_zig_archives(saved_archives_root)]
    preferred_archive = choose_preferred_archive(minimum_zig, archive_reports)

    report = build_report(
        repo_root=repo_root,
        saved_archives_root=saved_archives_root,
        toolchains_root=toolchains_root,
        minimum_zig=minimum_zig,
        archive_reports=archive_reports,
        preferred_archive=preferred_archive,
        fallback_archive=fallback_archive,
    )

    if args.json:
        print(json.dumps(report, indent=2))
        return 1 if report["failures"] else 0

    print("Issue #11 saved Zig archive tree candidates")
    print()
    print(f"Repo root:           {repo_root}")
    print(f"Saved archives root: {saved_archives_root}")
    print(f"Toolchains root:     {toolchains_root}")
    print(f"Minimum Zig line:    {minimum_zig}")
    print(
        "Fallback archive:    "
        f"{fallback_archive if fallback_archive is not None else 'not found beside the repo workspace'}"
    )
    print()
    if archive_reports:
        print("Discovered saved Zig archives:")
        for archive in archive_reports:
            version = archive["version"] or "unknown-version"
            top_level = archive["top_level"] or "unknown-top-level"
            print(f"  - {archive['path']} [top-level={top_level}; {version}; {archive['status']}]")
    else:
        print("Discovered saved Zig archives: none")

    if preferred_archive is not None:
        print()
        print("Preferred restore commands:")
        print(f"  {report['commands']['restore_check']}")
        print(f"  {report['commands']['restore']}")
        return 0

    print()
    print("Saved Zig archive tree discovery failed:", file=sys.stderr)
    for failure in report["failures"]:
        print(f"  - {failure}", file=sys.stderr)
    if fallback_archive is not None:
        print(
            "  - use the fallback archive only as a surfaced stopgap; it is not branch-compatible validation evidence",
            file=sys.stderr,
        )
    return 1


if __name__ == "__main__":
    sys.exit(main())