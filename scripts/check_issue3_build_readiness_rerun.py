#!/usr/bin/env python3

"""Surface the exact branch-compatible Zig rerun command for issue #11."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile
import unittest


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)")
DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
DEFAULT_ZIG_TOOLCHAIN_GLOBS = (
    "zig*/zig",
    "zig*/bin/zig",
    "*/zig",
    "*/bin/zig",
    "zig",
)


def parse_semver(version_text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.match(version_text)
    if not match:
        raise ValueError(f"Could not parse semantic version from {version_text!r}")
    return tuple(int(part) for part in match.groups())


def same_version_line(expected_version: str, actual_version: str) -> bool:
    expected_parts = parse_semver(expected_version)
    actual_parts = parse_semver(actual_version)
    return actual_parts[:2] == expected_parts[:2]


def ancestor_chain(start: Path) -> list[Path]:
    chain: list[Path] = []
    current = start.resolve()
    while True:
        chain.append(current)
        if current.parent == current:
            break
        current = current.parent
    return chain


def locate_first_existing(start: Path, relative_path: str) -> Path | None:
    for ancestor in ancestor_chain(start):
        candidate = ancestor / relative_path
        if candidate.exists():
            return candidate.resolve()
    return None


def load_minimum_zig(repo_root: Path) -> str:
    text = (repo_root / "build.zig.zon").read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError(f"Could not find minimum_zig_version in {repo_root / 'build.zig.zon'}")
    return match.group(1)


def resolve_default_helper_root(repo_root: Path) -> Path:
    return repo_root.resolve()


def resolve_default_toolchains_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "toolchains")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "toolchains").resolve()


def resolve_default_saved_archives_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "memory/repo_archives/browser")
    if located is not None and located.is_dir():
        root = located
    else:
        root = (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()
    dependencies_root = root / "dependencies"
    return dependencies_root if dependencies_root.is_dir() else root


def resolve_default_offline_deps_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "offline-deps")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "offline-deps").resolve()


def resolve_fallback_zig_archive(repo_root: Path, explicit_archive: Path | None) -> Path | None:
    if explicit_archive is not None:
        return explicit_archive.resolve()
    located = locate_first_existing(repo_root, f"agent_files/{DEFAULT_FALLBACK_ZIG_ARCHIVE}")
    if located is not None and located.is_file():
        return located
    candidate = (repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve()
    return candidate if candidate.exists() else None


def discover_toolchain_zig_candidates(toolchains_root: Path) -> list[Path]:
    if not toolchains_root.is_dir():
        return []
    candidates: list[Path] = []
    seen: set[Path] = set()
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


def probe_zig_version(zig_path: Path) -> str:
    completed = subprocess.run(
        [str(zig_path), "version"],
        check=True,
        capture_output=True,
        text=True,
    )
    output = completed.stdout.strip() or completed.stderr.strip()
    if not output:
        raise ValueError(f"zig candidate {zig_path} produced no version output")
    return output


def choose_matching_candidate(minimum_zig: str, toolchains_root: Path) -> tuple[Path | None, list[dict[str, str]]]:
    reports: list[dict[str, str]] = []
    selected: Path | None = None
    minimum_parts = parse_semver(minimum_zig)
    for candidate in discover_toolchain_zig_candidates(toolchains_root):
        try:
            version = probe_zig_version(candidate)
            status = "matches-expected-line" if same_version_line(minimum_zig, version) else (
                "older-than-minimum" if parse_semver(version) < minimum_parts else "mismatched-line"
            )
        except (subprocess.CalledProcessError, FileNotFoundError, ValueError) as exc:
            version = ""
            status = f"unusable: {exc}"
        reports.append(
            {
                "path": str(candidate),
                "version": version,
                "status": status,
            }
        )
        if selected is None and status == "matches-expected-line":
            selected = candidate
    return selected, reports


def build_readiness_rerun_command(
    repo_root: Path,
    helper_root: Path,
    zig_path: Path,
    toolchains_root: Path,
    saved_archives_root: Path,
    offline_deps_root: Path,
    fallback_zig_archive: Path | None,
) -> list[str]:
    command = [
        "python",
        str(helper_root / "scripts" / "check_linux_build_readiness.py"),
        "--repo-root",
        str(repo_root),
        "--zig",
        str(zig_path),
        "--toolchains-root",
        str(toolchains_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--expect-saved-archives",
        "--offline-deps-root",
        str(offline_deps_root),
        "--expect-offline-deps",
        "--require-prebuilt-v8",
    ]
    if fallback_zig_archive is not None:
        command.extend(["--fallback-zig-archive", str(fallback_zig_archive)])
    return command


def format_shell_command(command: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in command)


def collect_report(
    repo_root: Path,
    helper_root: Path,
    toolchains_root: Path,
    saved_archives_root: Path,
    offline_deps_root: Path,
    fallback_zig_archive: Path | None,
) -> dict[str, object]:
    minimum_zig = load_minimum_zig(repo_root)
    selected, reports = choose_matching_candidate(minimum_zig, toolchains_root)
    rerun_command = (
        build_readiness_rerun_command(
            repo_root,
            helper_root,
            selected,
            toolchains_root,
            saved_archives_root,
            offline_deps_root,
            fallback_zig_archive,
        )
        if selected is not None
        else None
    )
    recovery_route_command = [
        "bash",
        str(helper_root / "scripts" / "linux" / "show_issue3_zig_toolchain_recovery_route.sh"),
        "--repo-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--offline-deps-root",
        str(offline_deps_root),
    ]
    if fallback_zig_archive is not None:
        recovery_route_command.extend(["--fallback-zig-archive", str(fallback_zig_archive)])
    return {
        "status": "passed" if selected is not None else "failed",
        "repo_root": str(repo_root),
        "helper_root": str(helper_root),
        "minimum_zig": minimum_zig,
        "toolchains_root": str(toolchains_root),
        "saved_archives_root": str(saved_archives_root),
        "offline_deps_root": str(offline_deps_root),
        "fallback_zig_archive": str(fallback_zig_archive) if fallback_zig_archive is not None else None,
        "zig_candidates": reports,
        "selected_zig_candidate": str(selected) if selected is not None else None,
        "suggested_readiness_rerun_command": rerun_command,
        "suggested_recovery_route_command": recovery_route_command,
    }


def emit_text(report: dict[str, object]) -> None:
    print(f"Repo root: {report['repo_root']}")
    print(f"Helper root: {report['helper_root']}")
    print(f"Minimum Zig from build.zig.zon: {report['minimum_zig']}")
    print(f"Toolchains root: {report['toolchains_root']}")
    print(f"Saved archives root: {report['saved_archives_root']}")
    print(f"Offline deps root: {report['offline_deps_root']}")
    print("Discovered Zig candidates:")
    candidates = report["zig_candidates"]
    if candidates:
        for candidate in candidates:
            version = candidate["version"] or "unknown"
            print(f"  - {candidate['path']} [{version}; {candidate['status']}]")
    else:
        print("  - none")

    if report["selected_zig_candidate"] is not None:
        print("\nSuggested readiness rerun command:")
        print(f"  {format_shell_command(report['suggested_readiness_rerun_command'])}")
    else:
        print("\nNo branch-compatible staged Zig candidate found.")
        print("Suggested recovery route command:")
        print(f"  {format_shell_command(report['suggested_recovery_route_command'])}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Print the exact branch-compatible Zig rerun command for issue #11 Linux/WSL recovery."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser checkout root (default: current directory)")
    parser.add_argument(
        "--helper-root",
        default=None,
        help="Path to the live helper checkout that should supply the rerun and recovery scripts (default: repo root)",
    )
    parser.add_argument("--toolchains-root", default=None, help="Path to the staged Zig toolchains root")
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help="Path to the saved archive root (default: nearest ancestor memory/repo_archives/browser or its dependencies dir)",
    )
    parser.add_argument("--offline-deps-root", default=None, help="Path to the offline dependency root")
    parser.add_argument("--fallback-zig-archive", default=None, help="Optional explicit path to the fallback Zig archive")
    parser.add_argument("--json", action="store_true", help="Emit structured JSON instead of line-oriented text")
    parser.add_argument("--self-test", action="store_true", help="Run focused helper tests and exit")
    return parser


class BranchCompatibleZigRerunTests(unittest.TestCase):
    def test_selects_first_matching_candidate_and_builds_rerun_command(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            (repo_root / "build.zig.zon").write_text('.minimum_zig_version = "0.15.2"', encoding="utf-8")

            toolchains_root = root / "toolchains"
            matching = toolchains_root / "zig-0.15.7" / "zig"
            mismatched = toolchains_root / "zig-0.17.0" / "bin" / "zig"
            for candidate, version in (
                (matching, "0.15.7"),
                (mismatched, "0.17.0-dev.299+a76ce7710"),
            ):
                candidate.parent.mkdir(parents=True, exist_ok=True)
                candidate.write_text(f"#!/usr/bin/env bash\necho {version}\n", encoding="utf-8")
                candidate.chmod(0o755)

            report = collect_report(
                repo_root,
                repo_root,
                toolchains_root,
                root / "memory" / "repo_archives" / "browser" / "dependencies",
                root / "offline-deps",
                None,
            )

            self.assertEqual(report["status"], "passed")
            self.assertEqual(report["selected_zig_candidate"], str(matching.resolve()))
            command = report["suggested_readiness_rerun_command"]
            self.assertIn(str(matching.resolve()), command)
            self.assertIn("--expect-offline-deps", command)
            self.assertIn("--require-prebuilt-v8", command)
            self.assertEqual(command[1], str((repo_root / "scripts" / "check_linux_build_readiness.py").resolve()))

    def test_reports_recovery_route_when_no_matching_candidate_exists(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            (repo_root / "build.zig.zon").write_text('.minimum_zig_version = "0.15.2"', encoding="utf-8")

            toolchains_root = root / "toolchains"
            mismatched = toolchains_root / "zig-0.17.0" / "bin" / "zig"
            mismatched.parent.mkdir(parents=True, exist_ok=True)
            mismatched.write_text("#!/usr/bin/env bash\necho 0.17.0-dev.299+a76ce7710\n", encoding="utf-8")
            mismatched.chmod(0o755)

            report = collect_report(
                repo_root,
                repo_root,
                toolchains_root,
                root / "memory" / "repo_archives" / "browser" / "dependencies",
                root / "offline-deps",
                root / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE,
            )

            self.assertEqual(report["status"], "failed")
            self.assertIsNone(report["selected_zig_candidate"])
            self.assertIsNone(report["suggested_readiness_rerun_command"])
            self.assertIn(
                "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
                report["suggested_recovery_route_command"][1],
            )

    def test_candidate_reports_use_lane_shared_status_tokens(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            (repo_root / "build.zig.zon").write_text('.minimum_zig_version = "0.15.2"', encoding="utf-8")

            toolchains_root = root / "toolchains"
            matching = toolchains_root / "zig-0.15.7" / "zig"
            mismatched = toolchains_root / "zig-0.17.0" / "bin" / "zig"
            older = toolchains_root / "zig-0.14.1" / "zig"
            for candidate, version in (
                (matching, "0.15.7"),
                (mismatched, "0.17.0-dev.299+a76ce7710"),
                (older, "0.14.1"),
            ):
                candidate.parent.mkdir(parents=True, exist_ok=True)
                candidate.write_text(f"#!/usr/bin/env bash\necho {version}\n", encoding="utf-8")
                candidate.chmod(0o755)

            selected, reports = choose_matching_candidate("0.15.2", toolchains_root)

            self.assertEqual(selected, matching.resolve())
            statuses = {report["path"]: report["status"] for report in reports}
            self.assertEqual(statuses[str(matching.resolve())], "matches-expected-line")
            self.assertEqual(statuses[str(mismatched.resolve())], "mismatched-line")
            self.assertEqual(statuses[str(older.resolve())], "older-than-minimum")

    def test_default_roots_discover_ancestor_workspace_layout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = Path(tmpdir)
            repo_root = workspace_root / "restored" / "browser-memory-snapshot" / "browser"
            repo_root.mkdir(parents=True)
            (repo_root / "build.zig.zon").write_text('.minimum_zig_version = "0.15.2"', encoding="utf-8")

            toolchains_root = workspace_root / "toolchains"
            toolchains_root.mkdir()
            saved_archives_root = workspace_root / "memory" / "repo_archives" / "browser"
            (saved_archives_root / "dependencies").mkdir(parents=True)
            offline_deps_root = workspace_root / "offline-deps"
            offline_deps_root.mkdir()
            agent_files_root = workspace_root / "agent_files"
            agent_files_root.mkdir()
            fallback_archive = agent_files_root / DEFAULT_FALLBACK_ZIG_ARCHIVE
            fallback_archive.write_text("zig", encoding="utf-8")

            self.assertEqual(resolve_default_toolchains_root(repo_root), toolchains_root.resolve())
            self.assertEqual(
                resolve_default_saved_archives_root(repo_root),
                (saved_archives_root / "dependencies").resolve(),
            )
            self.assertEqual(resolve_default_offline_deps_root(repo_root), offline_deps_root.resolve())
            self.assertEqual(resolve_fallback_zig_archive(repo_root, None), fallback_archive.resolve())

    def test_explicit_helper_root_supplies_live_rerun_and_recovery_scripts(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "browser"
            repo_root = root / "browser-memory-snapshot"
            helper_root.mkdir()
            repo_root.mkdir()
            (repo_root / "build.zig.zon").write_text('.minimum_zig_version = "0.15.2"', encoding="utf-8")

            toolchains_root = root / "toolchains"
            matching = toolchains_root / "zig-0.15.7" / "zig"
            matching.parent.mkdir(parents=True, exist_ok=True)
            matching.write_text("#!/usr/bin/env bash\necho 0.15.7\n", encoding="utf-8")
            matching.chmod(0o755)

            report = collect_report(
                repo_root,
                helper_root,
                toolchains_root,
                root / "memory" / "repo_archives" / "browser" / "dependencies",
                root / "offline-deps",
                None,
            )

            self.assertEqual(report["helper_root"], str(helper_root.resolve()))
            self.assertEqual(
                report["suggested_readiness_rerun_command"][1],
                str((helper_root / "scripts" / "check_linux_build_readiness.py").resolve()),
            )
            self.assertEqual(
                report["suggested_recovery_route_command"][1],
                str((helper_root / "scripts" / "linux" / "show_issue3_zig_toolchain_recovery_route.sh").resolve()),
            )
            self.assertIn(str(repo_root.resolve()), report["suggested_readiness_rerun_command"])
            self.assertIn(str(repo_root.resolve()), report["suggested_recovery_route_command"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(BranchCompatibleZigRerunTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    helper_root = Path(args.helper_root).resolve() if args.helper_root else resolve_default_helper_root(repo_root)
    toolchains_root = Path(args.toolchains_root).resolve() if args.toolchains_root else resolve_default_toolchains_root(repo_root)
    saved_archives_root = (
        Path(args.saved_archives_root).resolve() if args.saved_archives_root else resolve_default_saved_archives_root(repo_root)
    )
    offline_deps_root = (
        Path(args.offline_deps_root).resolve() if args.offline_deps_root else resolve_default_offline_deps_root(repo_root)
    )
    fallback_zig_archive = (
        Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None
    )
    fallback_zig_archive = resolve_fallback_zig_archive(repo_root, fallback_zig_archive)

    report = collect_report(
        repo_root=repo_root,
        helper_root=helper_root,
        toolchains_root=toolchains_root,
        saved_archives_root=saved_archives_root,
        offline_deps_root=offline_deps_root,
        fallback_zig_archive=fallback_zig_archive,
    )
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())