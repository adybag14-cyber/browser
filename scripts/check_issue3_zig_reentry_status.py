#!/usr/bin/env python3

"""Summarize Zig re-entry status for the issue #3 Linux/WSL recovery lane."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import shlex
import subprocess
import sys
import tempfile
import unittest


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"(\d+)\.(\d+)\.(\d+)")
DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
TOOLCHAIN_GLOBS = ("zig*/zig", "zig*/bin/zig", "*/zig", "*/bin/zig", "zig")
ARCHIVE_GLOBS = ("zig*.tar", "zig*.tar.gz", "zig*.tgz", "zig*.tar.xz", "zig*.zip")


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


def probe_version(command: pathlib.Path) -> tuple[str | None, str | None]:
    try:
        completed = subprocess.run(
            [str(command), "version"],
            check=True,
            capture_output=True,
            text=True,
        )
    except (FileNotFoundError, PermissionError, subprocess.CalledProcessError) as exc:
        return None, str(exc)
    output = completed.stdout.strip() or completed.stderr.strip()
    return output or None, None


def discover_toolchain_candidates(toolchains_root: pathlib.Path) -> list[pathlib.Path]:
    if not toolchains_root.is_dir():
        return []
    candidates: list[pathlib.Path] = []
    seen: set[pathlib.Path] = set()
    for pattern in TOOLCHAIN_GLOBS:
        for path in sorted(toolchains_root.glob(pattern)):
            resolved = path.resolve()
            if not resolved.is_file() or resolved in seen:
                continue
            seen.add(resolved)
            candidates.append(resolved)
    return candidates


def describe_toolchain_candidates(
    minimum_zig: str,
    toolchains_root: pathlib.Path,
) -> list[dict[str, str]]:
    reports: list[dict[str, str]] = []
    for candidate in discover_toolchain_candidates(toolchains_root):
        version, error = probe_version(candidate)
        status = "version-probe-failed"
        if version is not None:
            try:
                status = classify_version(minimum_zig, version)
            except ValueError:
                status = "unknown-version"
        reports.append(
            {
                "path": str(candidate),
                "version": version or "",
                "status": status,
                "error": error or "",
            }
        )
    return reports


def infer_archive_version(path: pathlib.Path) -> str | None:
    match = SEMVER_RE.search(path.name)
    if match is None:
        return None
    return match.group(0)


def discover_saved_archives(saved_archives_root: pathlib.Path) -> list[pathlib.Path]:
    if not saved_archives_root.is_dir():
        return []
    archives: list[pathlib.Path] = []
    seen: set[pathlib.Path] = set()
    for pattern in ARCHIVE_GLOBS:
        for path in sorted(saved_archives_root.glob(pattern)):
            resolved = path.resolve()
            if not resolved.is_file() or resolved in seen:
                continue
            seen.add(resolved)
            archives.append(resolved)
    return archives


def describe_saved_archives(
    minimum_zig: str,
    saved_archives_root: pathlib.Path,
) -> list[dict[str, str]]:
    reports: list[dict[str, str]] = []
    for archive in discover_saved_archives(saved_archives_root):
        version = infer_archive_version(archive)
        status = "unknown-version"
        if version is not None:
            status = classify_version(minimum_zig, version)
        reports.append(
            {
                "path": str(archive),
                "version": version or "",
                "status": status,
            }
        )
    return reports


def choose_preferred_archive(
    minimum_zig: str,
    archive_reports: list[dict[str, str]],
) -> dict[str, str] | None:
    exact_match = next(
        (
            archive
            for archive in archive_reports
            if archive["status"] == "matches-expected-line" and archive["version"] == minimum_zig
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
    minimum_zig: str,
    toolchains_root: pathlib.Path,
    saved_archives_root: pathlib.Path,
    toolchain_reports: list[dict[str, str]],
    archive_reports: list[dict[str, str]],
    preferred_archive: dict[str, str] | None,
    fallback_archive: pathlib.Path | None,
) -> dict[str, object]:
    matching_candidates = [
        candidate for candidate in toolchain_reports if candidate["status"] == "matches-expected-line"
    ]
    fallback_report: dict[str, str] | None = None
    if fallback_archive is not None:
        fallback_version = infer_archive_version(fallback_archive)
        fallback_report = {
            "path": str(fallback_archive),
            "version": fallback_version or "",
            "status": classify_version(minimum_zig, fallback_version) if fallback_version else "unknown-version",
        }

    commands: dict[str, str] = {
        "matching_line_gate": format_command(
            [
                "bash",
                str(repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_match.sh"),
                "--repo-root",
                str(repo_root),
                "--toolchains-root",
                str(toolchains_root),
                "--saved-archives-root",
                str(saved_archives_root),
            ]
        ),
        "saved_archive_candidate_discovery": format_command(
            [
                "python",
                str(repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py"),
                "--repo-root",
                str(repo_root),
                "--saved-archives-root",
                str(saved_archives_root),
                "--toolchains-root",
                str(toolchains_root),
            ]
        ),
    }
    if preferred_archive is not None:
        preferred_path = pathlib.Path(preferred_archive["path"])
        commands["preferred_archive_restore_check"] = format_command(
            build_restore_command(repo_root, toolchains_root, preferred_path, check_only=True)
        )
        commands["preferred_archive_restore"] = format_command(
            build_restore_command(repo_root, toolchains_root, preferred_path, check_only=False)
        )
    if fallback_archive is not None:
        commands["fallback_archive_restore_check"] = format_command(
            build_fallback_restore_command(repo_root, toolchains_root, fallback_archive, check_only=True)
        )
        commands["fallback_archive_restore"] = format_command(
            build_fallback_restore_command(repo_root, toolchains_root, fallback_archive, check_only=False)
        )

    failures: list[str] = []
    if not matching_candidates:
        expected_prefix = f"{parse_semver(minimum_zig)[0]}.{parse_semver(minimum_zig)[1]}.x"
        failures.append(
            f"no staged Zig candidate under {toolchains_root} matches the branch's expected {expected_prefix} line"
        )
        if preferred_archive is not None:
            failures.append(
                f"saved Zig archive {pathlib.Path(preferred_archive['path']).name} matches that line but is not staged yet"
            )
        elif fallback_report is None:
            failures.append("no surfaced fallback Zig archive is available beside the repo workspace")
        elif fallback_report["status"] == "mismatched-line":
            failures.append(
                f"fallback Zig archive {pathlib.Path(fallback_report['path']).name} surfaces Zig "
                f"{fallback_report['version']}, which is not honest validation for this branch"
            )

    return {
        "status": "passed" if not failures else "failed",
        "repo_root": str(repo_root),
        "minimum_zig": minimum_zig,
        "toolchains_root": str(toolchains_root),
        "saved_archives_root": str(saved_archives_root),
        "matching_zig_candidates": matching_candidates,
        "zig_candidates": toolchain_reports,
        "saved_zig_archives": archive_reports,
        "preferred_saved_archive": preferred_archive,
        "fallback_zig_archive": fallback_report,
        "commands": commands,
        "failures": failures,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Summarize staged Zig candidates and saved archive recovery status for issue #3 re-entry."
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
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of the human-readable summary")
    parser.add_argument("--self-test", action="store_true", help="Run the helper's focused unit tests and exit")
    return parser


class ZigReentryStatusTests(unittest.TestCase):
    def test_choose_preferred_archive_prefers_exact_version(self) -> None:
        reports = [
            {"path": "/tmp/zig-0.15.7.tar.xz", "version": "0.15.7", "status": "matches-expected-line"},
            {"path": "/tmp/zig-0.15.2.tar.xz", "version": "0.15.2", "status": "matches-expected-line"},
        ]
        preferred = choose_preferred_archive("0.15.2", reports)
        self.assertIsNotNone(preferred)
        assert preferred is not None
        self.assertEqual(preferred["version"], "0.15.2")

    def test_choose_preferred_archive_falls_back_to_highest_matching_patch(self) -> None:
        reports = [
            {"path": "/tmp/zig-0.15.3.tar.xz", "version": "0.15.3", "status": "matches-expected-line"},
            {"path": "/tmp/zig-0.15.11.tar.xz", "version": "0.15.11", "status": "matches-expected-line"},
            {"path": "/tmp/zig-0.17.0.tar.xz", "version": "0.17.0", "status": "mismatched-line"},
        ]
        preferred = choose_preferred_archive("0.15.2", reports)
        self.assertIsNotNone(preferred)
        assert preferred is not None
        self.assertEqual(preferred["version"], "0.15.11")

    def test_build_report_flags_unstaged_matching_archive(self) -> None:
        report = build_report(
            repo_root=pathlib.Path("/tmp/browser"),
            minimum_zig="0.15.2",
            toolchains_root=pathlib.Path("/tmp/toolchains"),
            saved_archives_root=pathlib.Path("/tmp/memory/repo_archives/browser/dependencies"),
            toolchain_reports=[],
            archive_reports=[
                {
                    "path": "/tmp/memory/repo_archives/browser/dependencies/zig-linux-x86_64-0.15.2.tar.xz",
                    "version": "0.15.2",
                    "status": "matches-expected-line",
                }
            ],
            preferred_archive={
                "path": "/tmp/memory/repo_archives/browser/dependencies/zig-linux-x86_64-0.15.2.tar.xz",
                "version": "0.15.2",
                "status": "matches-expected-line",
            },
            fallback_archive=None,
        )
        self.assertEqual(report["status"], "failed")
        self.assertIn("matches that line but is not staged yet", report["failures"][1])
        self.assertIn("preferred_archive_restore_check", report["commands"])

    def test_describe_toolchain_candidates_finds_matching_and_mismatched_versions(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            matching = root / "zig-0.15.7" / "zig"
            mismatched = root / "zig-0.17.0" / "bin" / "zig"
            for candidate, version in (
                (matching, "0.15.7"),
                (mismatched, "0.17.0-dev.299+a76ce7710"),
            ):
                candidate.parent.mkdir(parents=True, exist_ok=True)
                candidate.write_text(f"#!/usr/bin/env bash\necho {version}\n", encoding="utf-8")
                candidate.chmod(0o755)

            reports = describe_toolchain_candidates("0.15.2", root)
            statuses = {report["path"]: report["status"] for report in reports}
            self.assertEqual(statuses[str(matching.resolve())], "matches-expected-line")
            self.assertEqual(statuses[str(mismatched.resolve())], "mismatched-line")

    def test_normalize_saved_archives_root_prefers_dependencies_subdirectory(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            dependencies = root / "dependencies"
            dependencies.mkdir()
            self.assertEqual(normalize_saved_archives_root(root), dependencies.resolve())


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ZigReentryStatusTests)
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
    toolchain_reports = describe_toolchain_candidates(minimum_zig, toolchains_root)
    archive_reports = describe_saved_archives(minimum_zig, saved_archives_root)
    preferred_archive = choose_preferred_archive(minimum_zig, archive_reports)
    report = build_report(
        repo_root=repo_root,
        minimum_zig=minimum_zig,
        toolchains_root=toolchains_root,
        saved_archives_root=saved_archives_root,
        toolchain_reports=toolchain_reports,
        archive_reports=archive_reports,
        preferred_archive=preferred_archive,
        fallback_archive=fallback_archive,
    )

    if args.json:
        print(json.dumps(report, indent=2))
        return 1 if report["failures"] else 0

    print("Issue #3 Zig re-entry status")
    print()
    print(f"Repo root:           {report['repo_root']}")
    print(f"Saved archives root: {report['saved_archives_root']}")
    print(f"Toolchains root:     {report['toolchains_root']}")
    print(f"Minimum Zig line:    {report['minimum_zig']}")
    fallback_report = report["fallback_zig_archive"]
    if fallback_report is None:
        print("Fallback archive:    not found beside the repo workspace")
    else:
        print(
            "Fallback archive:    "
            f"{fallback_report['path']} [{fallback_report['version'] or 'unknown'}; {fallback_report['status']}]"
        )

    print()
    if report["zig_candidates"]:
        print("Discovered staged Zig candidates:")
        for candidate in report["zig_candidates"]:
            version = candidate["version"] or "unknown-version"
            print(f"  - {candidate['path']} [{version}; {candidate['status']}]")
    else:
        print("Discovered staged Zig candidates: none")

    print()
    if report["saved_zig_archives"]:
        print("Discovered saved Zig archives:")
        for archive in report["saved_zig_archives"]:
            version = archive["version"] or "unknown-version"
            print(f"  - {archive['path']} [{version}; {archive['status']}]")
    else:
        print("Discovered saved Zig archives: none")

    if report["commands"]:
        print()
        print("Suggested commands:")
        for label, command in report["commands"].items():
            print(f"  - {label}: {command}")

    if report["failures"]:
        print()
        print("Zig re-entry status failed:", file=sys.stderr)
        for failure in report["failures"]:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print()
    print("Zig re-entry status passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
