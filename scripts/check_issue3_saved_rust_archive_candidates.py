#!/usr/bin/env python3

"""Surface saved Rust archive candidates for the issue #11 Linux/WSL re-entry lane."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import shlex
import tempfile
import unittest


DEFAULT_EXPECTED_RUST = "1.79.0"
SEMVER_RE = re.compile(r"(\d+)\.(\d+)\.(\d+)")
ARCHIVE_RE = re.compile(r"01-rust-(\d+\.\d+\.\d+)-([^.]+(?:\.[^.]+)*)\.tar\.xz$")


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
        return "older-than-expected"
    if actual_parts[:2] == expected_parts[:2]:
        return "matches-expected-line"
    return "mismatched-line"


def ancestor_chain(start: pathlib.Path) -> list[pathlib.Path]:
    chain: list[pathlib.Path] = []
    current = start.resolve()
    while True:
        chain.append(current)
        if current.parent == current:
            break
        current = current.parent
    return chain


def locate_first_existing(start: pathlib.Path, relative_path: str) -> pathlib.Path | None:
    for ancestor in ancestor_chain(start):
        candidate = ancestor / relative_path
        if candidate.exists():
            return candidate.resolve()
    return None


def normalize_saved_archives_root(saved_archives_root: pathlib.Path) -> pathlib.Path:
    normalized_root = saved_archives_root.resolve()
    if normalized_root.name == "dependencies" and normalized_root.parent.is_dir():
        return normalized_root.parent
    return normalized_root


def build_saved_archive_search_roots(saved_archives_root: pathlib.Path) -> list[pathlib.Path]:
    normalized_root = normalize_saved_archives_root(saved_archives_root)
    search_roots = [normalized_root]
    dependencies_root = normalized_root / "dependencies"
    if dependencies_root.is_dir():
        search_roots.append(dependencies_root.resolve())
    return search_roots


def resolve_default_saved_archives_root(repo_root: pathlib.Path) -> pathlib.Path:
    located = locate_first_existing(repo_root, "memory/repo_archives/browser")
    if located is not None and located.is_dir():
        return normalize_saved_archives_root(located)
    return normalize_saved_archives_root(repo_root.parent / "memory" / "repo_archives" / "browser")


def resolve_default_toolchains_root(repo_root: pathlib.Path) -> pathlib.Path:
    located = locate_first_existing(repo_root, "toolchains")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "toolchains").resolve()


def discover_rust_archives(search_roots: list[pathlib.Path]) -> list[pathlib.Path]:
    discovered: list[pathlib.Path] = []
    seen: set[pathlib.Path] = set()
    for root in search_roots:
        if not root.exists() or not root.is_dir():
            continue
        for path in sorted(root.rglob("01-rust-*.tar.xz")):
            if not path.is_file():
                continue
            resolved = path.resolve()
            if resolved in seen:
                continue
            seen.add(resolved)
            discovered.append(resolved)
    return discovered


def infer_archive_metadata(path: pathlib.Path) -> tuple[str | None, str]:
    match = ARCHIVE_RE.match(path.name)
    if match is None:
        return None, ""
    return match.group(1), match.group(2)


def describe_archive(expected: str, path: pathlib.Path) -> dict[str, str]:
    version, triple = infer_archive_metadata(path)
    status = "unknown-version" if version is None else classify_version(expected, version)
    return {
        "path": str(path),
        "version": version or "",
        "target_triple": triple,
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
    saved_archives_root: pathlib.Path,
    toolchains_root: pathlib.Path,
    archive_path: pathlib.Path,
    *,
    check_only: bool,
) -> list[str]:
    version, _triple = infer_archive_metadata(archive_path)
    toolchain_dir = f"rust-{version}" if version else "rust-unknown"
    command = [
        "bash",
        str(repo_root / "scripts" / "linux" / "restore_saved_rust_toolchain.sh"),
        "--browser-root",
        str(repo_root),
        "--dependencies-root",
        str(saved_archives_root),
        "--toolchain-root",
        str(toolchains_root / toolchain_dir),
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
    saved_archives_search_roots: list[pathlib.Path],
    toolchains_root: pathlib.Path,
    expected_rust: str,
    archive_reports: list[dict[str, str]],
    preferred_archive: dict[str, str] | None,
) -> dict[str, object]:
    report: dict[str, object] = {
        "status": "passed" if preferred_archive is not None else "failed",
        "repo_root": str(repo_root),
        "saved_archives_root": str(saved_archives_root),
        "saved_archives_search_roots": [str(root) for root in saved_archives_search_roots],
        "toolchains_root": str(toolchains_root),
        "expected_rust": expected_rust,
        "rust_archives": archive_reports,
        "preferred_archive": preferred_archive,
    }

    commands: dict[str, str] = {}
    if preferred_archive is not None:
        archive_path = pathlib.Path(preferred_archive["path"])
        commands["restore_check"] = format_command(
            build_restore_command(
                repo_root,
                saved_archives_root,
                toolchains_root,
                archive_path,
                check_only=True,
            )
        )
        commands["restore"] = format_command(
            build_restore_command(
                repo_root,
                saved_archives_root,
                toolchains_root,
                archive_path,
                check_only=False,
            )
        )
    report["commands"] = commands

    failures: list[str] = []
    if preferred_archive is None:
        expected_prefix = f"{parse_semver(expected_rust)[0]}.{parse_semver(expected_rust)[1]}.x"
        searched_roots = ", ".join(str(root) for root in saved_archives_search_roots)
        failures.append(
            f"no saved Rust archive under {searched_roots} matches the expected {expected_prefix} line"
        )
    report["failures"] = failures
    return report


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Surface saved Rust archive candidates for the issue #11 Linux/WSL recovery route."
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
        help="Path to the shared toolchains directory (default: nearest ancestor toolchains root or ../toolchains)",
    )
    parser.add_argument(
        "--expected-rust",
        default=DEFAULT_EXPECTED_RUST,
        help=f"Expected Rust version for the saved route (default: {DEFAULT_EXPECTED_RUST})",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of the human-readable summary")
    parser.add_argument("--self-test", action="store_true", help="Run the helper's focused unit tests and exit")
    return parser


class SavedRustArchiveHelperTests(unittest.TestCase):
    def test_normalize_saved_archives_root_preserves_browser_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            dependencies = root / "dependencies"
            dependencies.mkdir()
            self.assertEqual(normalize_saved_archives_root(root), root.resolve())

    def test_build_saved_archive_search_roots_includes_browser_root_and_dependencies(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            dependencies = root / "dependencies"
            dependencies.mkdir()
            self.assertEqual(
                build_saved_archive_search_roots(root),
                [root.resolve(), dependencies.resolve()],
            )

    def test_build_saved_archive_search_roots_accepts_dependencies_input(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            dependencies = root / "dependencies"
            dependencies.mkdir()
            root_archive = root / "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz"
            deps_archive = dependencies / "01-rust-1.80.1-x86_64-unknown-linux-gnu.tar.xz"
            root_archive.write_text("rust", encoding="utf-8")
            deps_archive.write_text("rust", encoding="utf-8")

            discovered = discover_rust_archives(build_saved_archive_search_roots(dependencies))
            reports = [describe_archive("1.79.0", path) for path in discovered]
            preferred = choose_preferred_archive("1.79.0", reports)

            self.assertEqual(set(discovered), {root_archive.resolve(), deps_archive.resolve()})
            self.assertIsNotNone(preferred)
            assert preferred is not None
            self.assertEqual(preferred["path"], str(root_archive.resolve()))
            self.assertEqual(preferred["version"], "1.79.0")

    def test_describe_archive_parses_version_and_triple(self) -> None:
        archive = pathlib.Path("/tmp/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz")
        report = describe_archive("1.79.0", archive)
        self.assertEqual(report["version"], "1.79.0")
        self.assertEqual(report["target_triple"], "x86_64-unknown-linux-gnu")
        self.assertEqual(report["status"], "matches-expected-line")

    def test_describe_archive_reports_unknown_version_for_unexpected_name(self) -> None:
        archive = pathlib.Path("/tmp/rust-toolchain.tar.xz")
        report = describe_archive("1.79.0", archive)
        self.assertEqual(report["version"], "")
        self.assertEqual(report["status"], "unknown-version")

    def test_choose_preferred_archive_prefers_exact_version(self) -> None:
        reports = [
            {"path": "/tmp/01-rust-1.79.1-x86_64-unknown-linux-gnu.tar.xz", "version": "1.79.1", "status": "matches-expected-line"},
            {"path": "/tmp/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz", "version": "1.79.0", "status": "matches-expected-line"},
        ]
        preferred = choose_preferred_archive("1.79.0", reports)
        self.assertIsNotNone(preferred)
        assert preferred is not None
        self.assertEqual(preferred["version"], "1.79.0")

    def test_choose_preferred_archive_prefers_highest_matching_patch_when_exact_missing(self) -> None:
        reports = [
            {"path": "/tmp/01-rust-1.79.1-x86_64-unknown-linux-gnu.tar.xz", "version": "1.79.1", "status": "matches-expected-line"},
            {"path": "/tmp/01-rust-1.79.4-x86_64-unknown-linux-gnu.tar.xz", "version": "1.79.4", "status": "matches-expected-line"},
            {"path": "/tmp/01-rust-1.78.2-x86_64-unknown-linux-gnu.tar.xz", "version": "1.78.2", "status": "older-than-expected"},
        ]
        preferred = choose_preferred_archive("1.79.0", reports)
        self.assertIsNotNone(preferred)
        assert preferred is not None
        self.assertEqual(preferred["version"], "1.79.4")

    def test_build_restore_command_targets_versioned_toolchain_root(self) -> None:
        command = build_restore_command(
            pathlib.Path("/tmp/browser"),
            pathlib.Path("/tmp/memory/repo_archives/browser/dependencies"),
            pathlib.Path("/tmp/toolchains"),
            pathlib.Path("/tmp/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz"),
            check_only=True,
        )
        self.assertIn("/tmp/toolchains/rust-1.79.0", command)
        self.assertEqual(command[-1], "--check-only")

    def test_default_roots_discover_ancestor_workspace_layout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = pathlib.Path(tmpdir)
            repo_root = workspace_root / "restored" / "browser-memory-snapshot" / "browser"
            repo_root.mkdir(parents=True)
            saved_archives_root = workspace_root / "memory" / "repo_archives" / "browser"
            dependencies_root = saved_archives_root / "dependencies"
            dependencies_root.mkdir(parents=True)
            toolchains_root = workspace_root / "toolchains"
            toolchains_root.mkdir()

            self.assertEqual(resolve_default_saved_archives_root(repo_root), saved_archives_root.resolve())
            self.assertEqual(resolve_default_toolchains_root(repo_root), toolchains_root.resolve())

    def test_build_report_fails_without_matching_archive(self) -> None:
        search_roots = [
            pathlib.Path("/tmp/memory/repo_archives/browser"),
            pathlib.Path("/tmp/memory/repo_archives/browser/dependencies"),
        ]
        report = build_report(
            repo_root=pathlib.Path("/tmp/browser"),
            saved_archives_root=pathlib.Path("/tmp/memory/repo_archives/browser"),
            saved_archives_search_roots=search_roots,
            toolchains_root=pathlib.Path("/tmp/toolchains"),
            expected_rust="1.79.0",
            archive_reports=[],
            preferred_archive=None,
        )
        self.assertEqual(report["status"], "failed")
        self.assertEqual(
            report["saved_archives_search_roots"],
            [str(root) for root in search_roots],
        )
        self.assertTrue(report["failures"])
        self.assertIn(
            "/tmp/memory/repo_archives/browser, /tmp/memory/repo_archives/browser/dependencies",
            report["failures"][0],
        )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedRustArchiveHelperTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    saved_archives_root = (
        pathlib.Path(args.saved_archives_root).resolve()
        if args.saved_archives_root
        else resolve_default_saved_archives_root(repo_root)
    )
    saved_archives_root = normalize_saved_archives_root(saved_archives_root)
    saved_archives_search_roots = build_saved_archive_search_roots(saved_archives_root)
    toolchains_root = (
        pathlib.Path(args.toolchains_root).resolve()
        if args.toolchains_root
        else resolve_default_toolchains_root(repo_root)
    )

    archive_reports = [
        describe_archive(args.expected_rust, path)
        for path in discover_rust_archives(saved_archives_search_roots)
    ]
    preferred_archive = choose_preferred_archive(args.expected_rust, archive_reports)

    report = build_report(
        repo_root=repo_root,
        saved_archives_root=saved_archives_root,
        saved_archives_search_roots=saved_archives_search_roots,
        toolchains_root=toolchains_root,
        expected_rust=args.expected_rust,
        archive_reports=archive_reports,
        preferred_archive=preferred_archive,
    )

    if args.json:
        print(json.dumps(report, indent=2))
        return 1 if report["failures"] else 0

    print("Issue #11 saved Rust archive candidates")
    print()
    print(f"Repo root:              {repo_root}")
    print(f"Saved archives root:    {saved_archives_root}")
    print(f"Saved archive search:   {', '.join(str(root) for root in saved_archives_search_roots)}")
    print(f"Toolchains root:        {toolchains_root}")
    print(f"Expected Rust line:     {args.expected_rust}")
    print()
    if archive_reports:
        print("Discovered saved Rust archives:")
        for archive in archive_reports:
            version = archive["version"] or "unknown-version"
            triple = archive["target_triple"] or "unknown-target"
            print(f"  - {archive['path']} [{triple}; {version}; {archive['status']}]")
    else:
        print("Discovered saved Rust archives: none")

    if preferred_archive is not None:
        print()
        print("Preferred restore commands:")
        print(f"  {report['commands']['restore_check']}")
        print(f"  {report['commands']['restore']}")
        return 0

    print()
    print("Saved Rust archive discovery failed:")
    for failure in report["failures"]:
        print(f"  - {failure}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())