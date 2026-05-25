#!/usr/bin/env python3

"""Find a staged branch-compatible Zig toolchain for issue #3 Linux re-entry."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import shlex
import subprocess
import sys
import tempfile
import textwrap
import unittest


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)")
DEFAULT_ZIG_TOOLCHAIN_GLOBS = (
    "zig*/zig",
    "zig*/bin/zig",
    "*/zig",
    "*/bin/zig",
    "zig",
)
DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"


def parse_semver(version_text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.match(version_text)
    if not match:
        raise ValueError(f"Could not parse semantic version from {version_text!r}")
    return tuple(int(part) for part in match.groups())


def same_version_line(expected_version: str, actual_version: str) -> bool:
    return parse_semver(expected_version)[:2] == parse_semver(actual_version)[:2]


def resolve_default_toolchains_root(repo_root: pathlib.Path) -> pathlib.Path:
    return (repo_root.parent / "toolchains").resolve()


def resolve_default_offline_deps_root(repo_root: pathlib.Path) -> pathlib.Path:
    return (repo_root.parent / "offline-deps").resolve()


def resolve_default_saved_archives_root(repo_root: pathlib.Path) -> pathlib.Path:
    browser_root = (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()
    dependencies_root = browser_root / "dependencies"
    return dependencies_root if dependencies_root.is_dir() else browser_root


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


def run_version_command(command: str) -> tuple[list[str], str | None]:
    failures: list[str] = []
    try:
        completed = subprocess.run(
            [command, "version"],
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        failures.append(f"zig candidate not found: {command}")
        return failures, None
    except subprocess.CalledProcessError as exc:
        failures.append(f"zig candidate version probe failed with exit code {exc.returncode}: {command}")
        return failures, None

    output = completed.stdout.strip() or completed.stderr.strip()
    return failures, output or None


def discover_toolchain_zig_candidates(toolchains_root: pathlib.Path) -> list[pathlib.Path]:
    if not toolchains_root.exists() or not toolchains_root.is_dir():
        return []

    candidates: list[pathlib.Path] = []
    seen: set[pathlib.Path] = set()
    for pattern in DEFAULT_ZIG_TOOLCHAIN_GLOBS:
        for path in sorted(toolchains_root.glob(pattern)):
            if not path.is_file():
                continue
            resolved = path.resolve()
            if resolved in seen:
                continue
            seen.add(resolved)
            candidates.append(resolved)
    return candidates


def describe_candidate(minimum_zig: str, zig_path: pathlib.Path) -> dict[str, str]:
    failures, installed = run_version_command(str(zig_path))
    if failures or installed is None:
        return {
            "path": str(zig_path),
            "version": "",
            "status": "unusable",
            "error": failures[0] if failures else "unknown version failure",
        }

    minimum_parts = parse_semver(minimum_zig)
    installed_parts = parse_semver(installed)
    if installed_parts < minimum_parts:
        status = "older-than-minimum"
    elif same_version_line(minimum_zig, installed):
        status = "matches-expected-line"
    else:
        status = "mismatched-line"
    return {
        "path": str(zig_path),
        "version": installed,
        "status": status,
        "error": "",
    }


def choose_preferred_candidate(minimum_zig: str, candidate_reports: list[dict[str, str]]) -> dict[str, str] | None:
    exact_match = next(
        (
            candidate
            for candidate in candidate_reports
            if candidate["status"] == "matches-expected-line" and candidate["version"] == minimum_zig
        ),
        None,
    )
    if exact_match is not None:
        return exact_match

    matching_candidates = [
        candidate
        for candidate in candidate_reports
        if candidate["status"] == "matches-expected-line" and candidate["version"]
    ]
    if not matching_candidates:
        return None

    return max(matching_candidates, key=lambda candidate: parse_semver(candidate["version"]))


def format_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def build_readiness_command(
    *,
    repo_root: pathlib.Path,
    zig_path: pathlib.Path,
    toolchains_root: pathlib.Path,
    offline_deps_root: pathlib.Path | None,
    saved_archives_root: pathlib.Path | None,
    fallback_zig_archive: pathlib.Path | None,
    expect_offline_deps: bool,
    expect_saved_archives: bool,
    require_prebuilt_v8: bool,
    skip_rust_check: bool,
) -> list[str]:
    command = [
        "python",
        "scripts/check_linux_build_readiness.py",
        "--repo-root",
        str(repo_root),
        "--zig",
        str(zig_path),
        "--toolchains-root",
        str(toolchains_root),
    ]
    if expect_offline_deps:
        command.append("--expect-offline-deps")
        if offline_deps_root is not None:
            command.extend(("--offline-deps-root", str(offline_deps_root)))
    if expect_saved_archives:
        command.append("--expect-saved-archives")
        if saved_archives_root is not None:
            command.extend(("--saved-archives-root", str(saved_archives_root)))
    if require_prebuilt_v8:
        command.append("--require-prebuilt-v8")
    if skip_rust_check:
        command.append("--skip-rust-check")
    if fallback_zig_archive is not None:
        command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
    return command


def build_report(
    *,
    repo_root: pathlib.Path,
    minimum_zig: str,
    toolchains_root: pathlib.Path,
    offline_deps_root: pathlib.Path | None,
    saved_archives_root: pathlib.Path | None,
    fallback_zig_archive: pathlib.Path | None,
    candidate_reports: list[dict[str, str]],
    preferred_candidate: dict[str, str] | None,
    readiness_command: list[str] | None,
) -> dict[str, object]:
    failures: list[str] = []
    if preferred_candidate is None:
        expected_major, expected_minor, _patch = parse_semver(minimum_zig)
        failures.append(
            f"no staged Zig candidate under {toolchains_root} matches the branch's expected {expected_major}.{expected_minor}.x line"
        )
    return {
        "status": "passed" if preferred_candidate is not None else "failed",
        "repo_root": str(repo_root),
        "minimum_zig": minimum_zig,
        "toolchains_root": str(toolchains_root),
        "offline_deps_root": str(offline_deps_root) if offline_deps_root is not None else "",
        "saved_archives_root": str(saved_archives_root) if saved_archives_root is not None else "",
        "fallback_zig_archive": str(fallback_zig_archive) if fallback_zig_archive is not None else "",
        "candidates": candidate_reports,
        "preferred_candidate": preferred_candidate,
        "suggested_readiness_command": readiness_command or [],
        "failures": failures,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Surface the best staged Zig candidate and a rerun command for issue #3 Linux/WSL readiness."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root (default: current directory)")
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Path to the shared toolchains directory (default: ../toolchains beside the repo)",
    )
    parser.add_argument(
        "--offline-deps-root",
        default=None,
        help="Optional path to the shared offline dependency root",
    )
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help="Optional path to repo_archives/browser or repo_archives/browser/dependencies",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit path to the surfaced fallback Zig archive",
    )
    parser.add_argument("--expect-offline-deps", action="store_true", help="Carry --expect-offline-deps into the suggested rerun command")
    parser.add_argument("--expect-saved-archives", action="store_true", help="Carry --expect-saved-archives into the suggested rerun command")
    parser.add_argument("--require-prebuilt-v8", action="store_true", help="Carry --require-prebuilt-v8 into the suggested rerun command")
    parser.add_argument("--skip-rust-check", action="store_true", help="Carry --skip-rust-check into the suggested rerun command")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of the human-readable summary")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


class MatchingZigToolchainTests(unittest.TestCase):
    def write_fake_zig(self, path: pathlib.Path, version: str) -> pathlib.Path:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            textwrap.dedent(
                f"""\
                #!/usr/bin/env bash
                echo {version}
                """
            ),
            encoding="utf-8",
        )
        path.chmod(0o755)
        return path

    def test_choose_preferred_candidate_prefers_exact_match(self) -> None:
        reports = [
            {"path": "/tmp/zig-0.15.7/zig", "version": "0.15.7", "status": "matches-expected-line", "error": ""},
            {"path": "/tmp/zig-0.15.2/zig", "version": "0.15.2", "status": "matches-expected-line", "error": ""},
        ]
        preferred = choose_preferred_candidate("0.15.2", reports)
        self.assertIsNotNone(preferred)
        assert preferred is not None
        self.assertEqual(preferred["version"], "0.15.2")

    def test_choose_preferred_candidate_prefers_highest_matching_patch(self) -> None:
        reports = [
            {"path": "/tmp/zig-0.15.3/zig", "version": "0.15.3", "status": "matches-expected-line", "error": ""},
            {"path": "/tmp/zig-0.15.11/zig", "version": "0.15.11", "status": "matches-expected-line", "error": ""},
            {"path": "/tmp/zig-0.17.0/zig", "version": "0.17.0", "status": "mismatched-line", "error": ""},
        ]
        preferred = choose_preferred_candidate("0.15.2", reports)
        self.assertIsNotNone(preferred)
        assert preferred is not None
        self.assertEqual(preferred["version"], "0.15.11")

    def test_discover_toolchain_zig_candidates_finds_nested_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            toolchains_root = pathlib.Path(tmpdir)
            direct = self.write_fake_zig(toolchains_root / "zig", "0.15.2")
            nested = self.write_fake_zig(toolchains_root / "zig-0.15.7" / "bin" / "zig", "0.15.7")

            discovered = discover_toolchain_zig_candidates(toolchains_root)

            self.assertEqual(discovered, [nested.resolve(), direct.resolve()])

    def test_describe_candidate_classifies_versions(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            toolchains_root = pathlib.Path(tmpdir)
            match = self.write_fake_zig(toolchains_root / "zig-0.15.7" / "zig", "0.15.7")
            older = self.write_fake_zig(toolchains_root / "zig-0.14.9" / "zig", "0.14.9")
            mismatch = self.write_fake_zig(toolchains_root / "zig-0.17.0" / "zig", "0.17.0-dev.299+a76ce7710")

            self.assertEqual(describe_candidate("0.15.2", match)["status"], "matches-expected-line")
            self.assertEqual(describe_candidate("0.15.2", older)["status"], "older-than-minimum")
            self.assertEqual(describe_candidate("0.15.2", mismatch)["status"], "mismatched-line")

    def test_build_readiness_command_carries_requested_flags(self) -> None:
        command = build_readiness_command(
            repo_root=pathlib.Path("/tmp/browser"),
            zig_path=pathlib.Path("/tmp/toolchains/zig-0.15.2/zig"),
            toolchains_root=pathlib.Path("/tmp/toolchains"),
            offline_deps_root=pathlib.Path("/tmp/offline-deps"),
            saved_archives_root=pathlib.Path("/tmp/memory/repo_archives/browser/dependencies"),
            fallback_zig_archive=pathlib.Path("/tmp/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"),
            expect_offline_deps=True,
            expect_saved_archives=True,
            require_prebuilt_v8=True,
            skip_rust_check=True,
        )
        rendered = format_command(command)
        self.assertIn("--zig /tmp/toolchains/zig-0.15.2/zig", rendered)
        self.assertIn("--expect-offline-deps", rendered)
        self.assertIn("--offline-deps-root /tmp/offline-deps", rendered)
        self.assertIn("--expect-saved-archives", rendered)
        self.assertIn("--saved-archives-root /tmp/memory/repo_archives/browser/dependencies", rendered)
        self.assertIn("--require-prebuilt-v8", rendered)
        self.assertIn("--skip-rust-check", rendered)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(MatchingZigToolchainTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    toolchains_root = pathlib.Path(args.toolchains_root).resolve() if args.toolchains_root else resolve_default_toolchains_root(repo_root)
    offline_deps_root = pathlib.Path(args.offline_deps_root).resolve() if args.offline_deps_root else (
        resolve_default_offline_deps_root(repo_root) if args.expect_offline_deps else None
    )
    saved_archives_root = pathlib.Path(args.saved_archives_root).resolve() if args.saved_archives_root else (
        resolve_default_saved_archives_root(repo_root) if args.expect_saved_archives else None
    )
    fallback_zig_archive = pathlib.Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else resolve_default_fallback_archive(repo_root)

    minimum_zig = load_minimum_zig(repo_root)
    candidate_reports = [describe_candidate(minimum_zig, path) for path in discover_toolchain_zig_candidates(toolchains_root)]
    preferred_candidate = choose_preferred_candidate(minimum_zig, candidate_reports)
    readiness_command = None
    if preferred_candidate is not None:
        readiness_command = build_readiness_command(
            repo_root=repo_root,
            zig_path=pathlib.Path(preferred_candidate["path"]),
            toolchains_root=toolchains_root,
            offline_deps_root=offline_deps_root,
            saved_archives_root=saved_archives_root,
            fallback_zig_archive=fallback_zig_archive,
            expect_offline_deps=args.expect_offline_deps,
            expect_saved_archives=args.expect_saved_archives,
            require_prebuilt_v8=args.require_prebuilt_v8,
            skip_rust_check=args.skip_rust_check,
        )

    report = build_report(
        repo_root=repo_root,
        minimum_zig=minimum_zig,
        toolchains_root=toolchains_root,
        offline_deps_root=offline_deps_root,
        saved_archives_root=saved_archives_root,
        fallback_zig_archive=fallback_zig_archive,
        candidate_reports=candidate_reports,
        preferred_candidate=preferred_candidate,
        readiness_command=readiness_command,
    )

    if args.json:
        print(json.dumps(report, indent=2))
        return 1 if report["failures"] else 0

    print("Issue #3 matching staged Zig toolchain")
    print()
    print(f"Repo root:            {report['repo_root']}")
    print(f"Minimum Zig line:     {report['minimum_zig']}")
    print(f"Toolchains root:      {report['toolchains_root']}")
    print(f"Offline deps root:    {report['offline_deps_root'] or 'not requested'}")
    print(f"Saved archives root:  {report['saved_archives_root'] or 'not requested'}")
    print(f"Fallback Zig archive: {report['fallback_zig_archive'] or 'not found beside the repo workspace'}")
    print()
    if report["candidates"]:
        print("Discovered staged Zig candidates:")
        for candidate in report["candidates"]:
            version = candidate["version"] or "unknown-version"
            error_suffix = f"; {candidate['error']}" if candidate["error"] else ""
            print(f"  - {candidate['path']} [{version}; {candidate['status']}{error_suffix}]")
    else:
        print("Discovered staged Zig candidates: none")

    if report["preferred_candidate"] is not None:
        print()
        print("Preferred readiness rerun command:")
        print(f"  {format_command(report['suggested_readiness_command'])}")
        return 0

    print()
    print("Matching staged Zig toolchain discovery failed:", file=sys.stderr)
    for failure in report["failures"]:
        print(f"  - {failure}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
