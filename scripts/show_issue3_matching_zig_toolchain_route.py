#!/usr/bin/env python3

"""Print the branch-compatible Zig toolchain route for issue #3 build readiness."""

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


def resolve_default_toolchains_root(repo_root: Path) -> Path:
    return (repo_root.parent / "toolchains").resolve()


def resolve_default_agent_files_root(repo_root: Path) -> Path:
    return (repo_root.parent / "agent_files").resolve()


def resolve_fallback_zig_archive(repo_root: Path, fallback_zig_archive: Path | None) -> Path | None:
    if fallback_zig_archive is not None:
        return fallback_zig_archive
    candidate = resolve_default_agent_files_root(repo_root) / DEFAULT_FALLBACK_ZIG_ARCHIVE
    return candidate if candidate.is_file() else None


def load_minimum_zig(repo_root: Path) -> str:
    zon_path = repo_root / "build.zig.zon"
    text = zon_path.read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError(f"Could not find minimum_zig_version in {zon_path}")
    return match.group(1)


def discover_toolchain_zig_candidates(toolchains_root: Path) -> list[Path]:
    if not toolchains_root.exists() or not toolchains_root.is_dir():
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


def run_version_command(command: str) -> str:
    completed = subprocess.run(
        [command, "version"],
        check=True,
        capture_output=True,
        text=True,
    )
    return completed.stdout.strip() or completed.stderr.strip()


def describe_candidate(minimum_zig: str, zig_path: Path) -> dict[str, str]:
    version = run_version_command(str(zig_path))
    minimum_parts = parse_semver(minimum_zig)
    installed_parts = parse_semver(version)
    if installed_parts < minimum_parts:
        status = "older than minimum"
    elif same_version_line(minimum_zig, version):
        status = f"matches expected {minimum_parts[0]}.{minimum_parts[1]}.x line"
    else:
        status = f"mismatched: expected {minimum_parts[0]}.{minimum_parts[1]}.x line"
    return {
        "path": str(zig_path),
        "version": version,
        "status": status,
    }


def build_readiness_command(repo_root: Path, zig_path: Path) -> str:
    saved_archives_root = repo_root.parent / "memory" / "repo_archives" / "browser" / "dependencies"
    command = [
        "python",
        "scripts/check_linux_build_readiness.py",
        "--repo-root",
        str(repo_root),
        "--zig",
        str(zig_path),
        "--expect-saved-archives",
        "--saved-archives-root",
        str(saved_archives_root),
    ]
    return " ".join(shlex.quote(part) for part in command)


def build_output(
    *,
    repo_root: Path,
    minimum_zig: str,
    toolchains_root: Path,
    candidate_reports: list[dict[str, str]],
    fallback_archive: Path | None,
) -> dict[str, object]:
    minimum_parts = parse_semver(minimum_zig)
    matching_candidates = [entry for entry in candidate_reports if entry["status"].startswith("matches expected")]
    fallback_version = None
    fallback_status = None
    if fallback_archive is not None:
        match = SEMVER_RE.search(fallback_archive.name)
        if match is not None:
            fallback_version = match.group(0)
            fallback_status = (
                f"matches expected {minimum_parts[0]}.{minimum_parts[1]}.x line"
                if same_version_line(minimum_zig, fallback_version)
                else f"mismatched: expected {minimum_parts[0]}.{minimum_parts[1]}.x line"
            )

    recommended_zig = Path(matching_candidates[0]["path"]) if matching_candidates else None
    export_command = f"export ZIG={shlex.quote(str(recommended_zig))}" if recommended_zig else None
    readiness_command = build_readiness_command(repo_root, recommended_zig) if recommended_zig else None

    return {
        "repo_root": str(repo_root),
        "minimum_zig": minimum_zig,
        "toolchains_root": str(toolchains_root),
        "candidates": candidate_reports,
        "matching_candidates": [entry["path"] for entry in matching_candidates],
        "fallback_archive": None
        if fallback_archive is None
        else {
            "path": str(fallback_archive),
            "version": fallback_version,
            "status": fallback_status,
        },
        "recommended_zig": None if recommended_zig is None else str(recommended_zig),
        "export_command": export_command,
        "readiness_command": readiness_command,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Show the branch-compatible Zig route for issue #3 Linux or WSL build readiness."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser checkout root")
    parser.add_argument("--toolchains-root", default=None, help="Optional Zig toolchains root override")
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional fallback Zig archive override",
    )
    parser.add_argument("--json", action="store_true", help="Emit structured JSON")
    parser.add_argument("--self-test", action="store_true", help="Run focused helper tests")
    return parser


class ZigRouteTests(unittest.TestCase):
    def test_same_version_line_checks_major_minor(self) -> None:
        self.assertTrue(same_version_line("0.15.2", "0.15.7"))
        self.assertFalse(same_version_line("0.15.2", "0.17.0-dev.299+a76ce7710"))

    def test_discover_toolchain_candidates(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            (root / "zig-0.15.7").mkdir()
            first = root / "zig-0.15.7" / "zig"
            first.write_text("#!/usr/bin/env bash\necho 0.15.7\n", encoding="utf-8")
            first.chmod(0o755)
            (root / "zig-0.17.0" / "bin").mkdir(parents=True)
            second = root / "zig-0.17.0" / "bin" / "zig"
            second.write_text("#!/usr/bin/env bash\necho 0.17.0-dev.299+a76ce7710\n", encoding="utf-8")
            second.chmod(0o755)
            discovered = discover_toolchain_zig_candidates(root)
            self.assertEqual(len(discovered), 2)

    def test_build_output_prefers_matching_candidate(self) -> None:
        repo_root = Path("/tmp/browser")
        matching = {
            "path": "/tmp/toolchains/zig-0.15.7/zig",
            "version": "0.15.7",
            "status": "matches expected 0.15.x line",
        }
        mismatched = {
            "path": "/tmp/toolchains/zig-0.17.0/bin/zig",
            "version": "0.17.0-dev.299+a76ce7710",
            "status": "mismatched: expected 0.15.x line",
        }
        result = build_output(
            repo_root=repo_root,
            minimum_zig="0.15.2",
            toolchains_root=Path("/tmp/toolchains"),
            candidate_reports=[mismatched, matching],
            fallback_archive=Path("/tmp/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"),
        )
        self.assertEqual(result["recommended_zig"], matching["path"])
        self.assertIn("--zig", result["readiness_command"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ZigRouteTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    minimum_zig = load_minimum_zig(repo_root)
    toolchains_root = Path(args.toolchains_root).resolve() if args.toolchains_root else resolve_default_toolchains_root(repo_root)
    fallback_archive = Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None
    fallback_archive = resolve_fallback_zig_archive(repo_root, fallback_archive)
    candidates = discover_toolchain_zig_candidates(toolchains_root)
    candidate_reports = [describe_candidate(minimum_zig, candidate) for candidate in candidates]
    result = build_output(
        repo_root=repo_root,
        minimum_zig=minimum_zig,
        toolchains_root=toolchains_root,
        candidate_reports=candidate_reports,
        fallback_archive=fallback_archive,
    )

    if args.json:
        print(json.dumps(result, indent=2))
        return 0

    print("Issue #3 branch-compatible Zig route")
    print()
    print(f"Repo root: {result['repo_root']}")
    print(f"Expected Zig line: {result['minimum_zig']}")
    print(f"Toolchains root: {result['toolchains_root']}")
    print()
    if result["candidates"]:
        print("Discovered Zig candidates:")
        for entry in result["candidates"]:
            print(f"  - {entry['path']} [{entry['version']}; {entry['status']}]")
    else:
        print("Discovered Zig candidates: none")
    print()
    fallback = result["fallback_archive"]
    if fallback is None:
        print("Fallback Zig archive: not found beside the repo workspace")
    else:
        version_suffix = ""
        if fallback["version"] is not None and fallback["status"] is not None:
            version_suffix = f" [{fallback['version']}; {fallback['status']}]"
        print(f"Fallback Zig archive: {fallback['path']}{version_suffix}")
    print()
    if result["recommended_zig"] is None:
        print("Recommended branch-compatible Zig: none discovered")
        print("Next: stage a Zig 0.15.x toolchain under ../toolchains before trusting Linux or WSL validation.")
    else:
        print(f"Recommended branch-compatible Zig: {result['recommended_zig']}")
        print("Suggested shell setup:")
        print(f"  {result['export_command']}")
        print("Suggested readiness rerun:")
        print(f"  {result['readiness_command']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
