#!/usr/bin/env python3

"""Surface the exact Rust-aware build-readiness rerun command for issue #11."""

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


EXPECTED_RUST_VERSION = "1.79.0"
EXPECTED_RUST_LINE = "1.79.x"
EXPECTED_TOOLCHAIN_DIR = "rust-1.79.0"
DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
DEFAULT_CANDIDATE_GLOBS = (
    "rust-*/cargo/bin/cargo",
    "*/cargo/bin/cargo",
)
VERSION_RE = re.compile(r"\b(\d+\.\d+\.\d+)\b")


def parse_version(text: str) -> str | None:
    match = VERSION_RE.search(text)
    if match is None:
        return None
    return match.group(1)


def parse_semver(version: str) -> tuple[int, int, int]:
    match = VERSION_RE.search(version)
    if match is None:
        raise ValueError(f"Could not parse semantic version from {version!r}")
    return tuple(int(part) for part in match.group(1).split("."))


def classify_version(version: str | None) -> str:
    if version is None:
        return "unknown-version"
    actual_parts = parse_semver(version)
    expected_parts = parse_semver(EXPECTED_RUST_VERSION)
    if actual_parts < expected_parts:
        return "older-than-expected"
    if actual_parts[:2] == expected_parts[:2]:
        return "matches-expected-line"
    return "mismatched-line"


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


def normalize_saved_archives_root(saved_archives_root: Path) -> Path:
    normalized_root = saved_archives_root.resolve()
    if normalized_root.name == "dependencies" and normalized_root.parent.is_dir():
        return normalized_root
    dependencies_root = normalized_root / "dependencies"
    return dependencies_root.resolve() if dependencies_root.is_dir() else normalized_root


def resolve_default_toolchains_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "toolchains")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "toolchains").resolve()


def resolve_default_saved_archives_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "memory/repo_archives/browser")
    if located is not None and located.is_dir():
        return normalize_saved_archives_root(located)
    return normalize_saved_archives_root(repo_root.parent / "memory" / "repo_archives" / "browser")


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
    return candidate if candidate.is_file() else None


def discover_candidates(toolchains_root: Path) -> list[Path]:
    if not toolchains_root.is_dir():
        return []

    seen: set[Path] = set()
    candidates: list[Path] = []
    for pattern in DEFAULT_CANDIDATE_GLOBS:
        for cargo_path in sorted(toolchains_root.glob(pattern)):
            if not cargo_path.is_file():
                continue
            resolved = cargo_path.resolve()
            if resolved in seen:
                continue
            seen.add(resolved)
            candidates.append(resolved)
    return candidates


def run_version(binary: Path, label: str) -> tuple[list[str], str | None]:
    try:
        completed = subprocess.run(
            [str(binary), "--version"],
            capture_output=True,
            check=True,
            text=True,
        )
    except FileNotFoundError:
        return [f"{label} not found: {binary}"], None
    except subprocess.CalledProcessError as exc:
        return [f"{label} version probe failed with exit code {exc.returncode}: {binary}"], None

    output = completed.stdout.strip() or completed.stderr.strip()
    return [], output or None


def describe_candidate(cargo_bin: Path) -> dict[str, object]:
    cargo_failures, cargo_output = run_version(cargo_bin, "cargo")
    rustc_bin = cargo_bin.parent.parent.parent / "rustc" / "bin" / "rustc"
    rustc_exists = rustc_bin.is_file()
    rustc_failures, rustc_output = ([], None)
    if rustc_exists:
        rustc_failures, rustc_output = run_version(rustc_bin, "rustc")
    else:
        rustc_failures = [f"missing rustc beside cargo: {rustc_bin}"]

    cargo_version = parse_version(cargo_output or "")
    rustc_version = parse_version(rustc_output or "")
    toolchain_root = cargo_bin.parent.parent.parent

    return {
        "toolchain_root": toolchain_root,
        "cargo_bin": cargo_bin,
        "rustc_bin": rustc_bin,
        "cargo_version": cargo_version,
        "rustc_version": rustc_version,
        "cargo_classification": classify_version(cargo_version),
        "rustc_classification": classify_version(rustc_version),
        "failures": cargo_failures + rustc_failures,
    }


def choose_preferred_candidate(candidates: list[dict[str, object]], expected_dir: Path) -> dict[str, object] | None:
    matching_candidates = [
        candidate
        for candidate in candidates
        if candidate["cargo_classification"] == "matches-expected-line"
        and candidate["rustc_classification"] == "matches-expected-line"
        and candidate["cargo_version"] is not None
    ]
    if not matching_candidates:
        return None

    for candidate in matching_candidates:
        if Path(str(candidate["toolchain_root"])).resolve() == expected_dir.resolve():
            return candidate

    return max(
        matching_candidates,
        key=lambda candidate: parse_semver(str(candidate["cargo_version"])),
    )


def build_readiness_rerun_command(
    repo_root: Path,
    preferred_candidate: dict[str, object],
    toolchains_root: Path,
    saved_archives_root: Path,
    offline_deps_root: Path,
    fallback_zig_archive: Path | None,
) -> list[str]:
    command = [
        "python",
        "scripts/check_linux_build_readiness.py",
        "--repo-root",
        str(repo_root),
        "--cargo",
        str(preferred_candidate["cargo_bin"]),
        "--rustc",
        str(preferred_candidate["rustc_bin"]),
        "--toolchains-root",
        str(toolchains_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--expect-saved-archives",
        "--offline-deps-root",
        str(offline_deps_root),
        "--expect-offline-deps",
        "--require-prebuilt-v8",
        "--skip-zig-check",
    ]
    if fallback_zig_archive is not None:
        command.extend(["--fallback-zig-archive", str(fallback_zig_archive)])
    return command


def build_route_command(
    repo_root: Path,
    saved_archives_root: Path,
    toolchains_root: Path,
    rust_toolchain_dir: Path,
) -> list[str]:
    return [
        "bash",
        "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
        "--repo-root",
        str(repo_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--toolchains-root",
        str(toolchains_root),
        "--rust-toolchain-dir",
        str(rust_toolchain_dir),
    ]


def format_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def collect_report(
    repo_root: Path,
    toolchains_root: Path,
    saved_archives_root: Path,
    offline_deps_root: Path,
    fallback_zig_archive: Path | None,
) -> dict[str, object]:
    candidates = [describe_candidate(path) for path in discover_candidates(toolchains_root)]
    expected_dir = toolchains_root / EXPECTED_TOOLCHAIN_DIR
    preferred = choose_preferred_candidate(candidates, expected_dir)
    rerun_command = (
        build_readiness_rerun_command(
            repo_root,
            preferred,
            toolchains_root,
            saved_archives_root,
            offline_deps_root,
            fallback_zig_archive,
        )
        if preferred is not None
        else None
    )
    route_command = build_route_command(repo_root, saved_archives_root, toolchains_root, expected_dir)

    return {
        "status": "passed" if preferred is not None else "failed",
        "repo_root": str(repo_root),
        "toolchains_root": str(toolchains_root),
        "saved_archives_root": str(saved_archives_root),
        "offline_deps_root": str(offline_deps_root),
        "fallback_zig_archive": str(fallback_zig_archive) if fallback_zig_archive is not None else None,
        "expected_rust_version": EXPECTED_RUST_VERSION,
        "expected_rust_line": EXPECTED_RUST_LINE,
        "preferred_candidate": serialize(preferred),
        "candidates": serialize(candidates),
        "suggested_readiness_rerun_command": rerun_command,
        "suggested_saved_rust_route_command": route_command,
    }


def serialize(value: object) -> object:
    if isinstance(value, Path):
        return str(value)
    if isinstance(value, dict):
        return {str(key): serialize(inner) for key, inner in value.items()}
    if isinstance(value, list):
        return [serialize(item) for item in value]
    return value


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Print the exact saved-Rust build-readiness rerun command for issue #11."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument("--toolchains-root", default=None, help="Path to the shared toolchains directory")
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help="Path to repo_archives/browser or repo_archives/browser/dependencies",
    )
    parser.add_argument("--offline-deps-root", default=None, help="Path to the offline dependency root")
    parser.add_argument("--fallback-zig-archive", default=None, help="Optional explicit path to the fallback Zig archive")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of human-readable output")
    parser.add_argument("--self-test", action="store_true", help="Run focused helper tests and exit")
    return parser


class SavedRustBuildReadinessRerunTests(unittest.TestCase):
    def make_toolchain(self, root: Path, name: str, cargo_version: str, rustc_version: str | None) -> Path:
        cargo_bin = root / name / "cargo" / "bin" / "cargo"
        cargo_bin.parent.mkdir(parents=True, exist_ok=True)
        cargo_bin.write_text(f"#!/usr/bin/env bash\necho cargo {cargo_version}\n", encoding="utf-8")
        cargo_bin.chmod(0o755)

        if rustc_version is not None:
            rustc_bin = root / name / "rustc" / "bin" / "rustc"
            rustc_bin.parent.mkdir(parents=True, exist_ok=True)
            rustc_bin.write_text(f"#!/usr/bin/env bash\necho rustc {rustc_version}\n", encoding="utf-8")
            rustc_bin.chmod(0o755)
        return cargo_bin

    def test_builds_rerun_command_for_preferred_candidate(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            toolchains_root = root / "toolchains"
            self.make_toolchain(toolchains_root, "rust-1.79.0", "1.79.0", "1.79.0")

            report = collect_report(
                repo_root,
                toolchains_root,
                root / "memory" / "repo_archives" / "browser" / "dependencies",
                root / "offline-deps",
                root / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE,
            )

            self.assertEqual(report["status"], "passed")
            command = report["suggested_readiness_rerun_command"]
            self.assertIsNotNone(command)
            assert command is not None
            self.assertIn("--cargo", command)
            self.assertIn("--rustc", command)
            self.assertIn("--expect-saved-archives", command)
            self.assertIn("--expect-offline-deps", command)
            self.assertIn("--require-prebuilt-v8", command)
            self.assertIn("--skip-zig-check", command)

    def test_reports_saved_rust_route_when_no_candidate_exists(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            toolchains_root = root / "toolchains"
            self.make_toolchain(toolchains_root, "rust-1.80.1", "1.80.1", "1.80.1")

            report = collect_report(
                repo_root,
                toolchains_root,
                root / "memory" / "repo_archives" / "browser" / "dependencies",
                root / "offline-deps",
                None,
            )

            self.assertEqual(report["status"], "failed")
            self.assertIsNone(report["suggested_readiness_rerun_command"])
            self.assertIn(
                "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
                report["suggested_saved_rust_route_command"],
            )

    def test_defaults_discover_ancestor_workspace_roots(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = Path(tmpdir)
            repo_root = workspace_root / "restored" / "browser-memory-snapshot" / "browser"
            repo_root.mkdir(parents=True)
            toolchains_root = workspace_root / "toolchains"
            toolchains_root.mkdir()
            saved_archives_root = workspace_root / "memory" / "repo_archives" / "browser"
            (saved_archives_root / "dependencies").mkdir(parents=True)
            offline_deps_root = workspace_root / "offline-deps"
            offline_deps_root.mkdir()
            fallback_archive = workspace_root / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE
            fallback_archive.parent.mkdir()
            fallback_archive.write_text("zig", encoding="utf-8")

            self.assertEqual(resolve_default_toolchains_root(repo_root), toolchains_root.resolve())
            self.assertEqual(
                resolve_default_saved_archives_root(repo_root),
                (saved_archives_root / "dependencies").resolve(),
            )
            self.assertEqual(resolve_default_offline_deps_root(repo_root), offline_deps_root.resolve())
            self.assertEqual(resolve_fallback_zig_archive(repo_root, None), fallback_archive.resolve())


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedRustBuildReadinessRerunTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    toolchains_root = Path(args.toolchains_root).resolve() if args.toolchains_root else resolve_default_toolchains_root(repo_root)
    saved_archives_root = (
        Path(args.saved_archives_root).resolve() if args.saved_archives_root else resolve_default_saved_archives_root(repo_root)
    )
    saved_archives_root = normalize_saved_archives_root(saved_archives_root)
    offline_deps_root = (
        Path(args.offline_deps_root).resolve() if args.offline_deps_root else resolve_default_offline_deps_root(repo_root)
    )
    fallback_zig_archive = (
        Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None
    )
    fallback_zig_archive = resolve_fallback_zig_archive(repo_root, fallback_zig_archive)

    report = collect_report(
        repo_root=repo_root,
        toolchains_root=toolchains_root,
        saved_archives_root=saved_archives_root,
        offline_deps_root=offline_deps_root,
        fallback_zig_archive=fallback_zig_archive,
    )
    if args.json:
        print(json.dumps(serialize(report), indent=2))
    else:
        print(f"Repo root: {report['repo_root']}")
        print(f"Toolchains root: {report['toolchains_root']}")
        print(f"Saved archives root: {report['saved_archives_root']}")
        print(f"Offline deps root: {report['offline_deps_root']}")
        print(f"Expected Rust version: {report['expected_rust_version']}")
        print(f"Expected Rust line: {report['expected_rust_line']}")
        if report["fallback_zig_archive"] is not None:
            print(f"Fallback Zig archive: {report['fallback_zig_archive']}")
        candidates = report["candidates"]
        if candidates:
            print("Discovered Rust candidates:")
            for candidate in candidates:
                print(
                    "  - "
                    f"{candidate['toolchain_root']} "
                    f"[cargo={candidate['cargo_version'] or 'unknown'}, "
                    f"rustc={candidate['rustc_version'] or 'unknown'}]"
                )
        else:
            print("Discovered Rust candidates: none")

        if report["suggested_readiness_rerun_command"] is not None:
            print("\nSuggested readiness rerun command:")
            print(f"  {format_command(report['suggested_readiness_rerun_command'])}")
        else:
            print("\nNo reusable staged Rust 1.79.x candidate is ready.")
            print("Suggested saved-Rust bridge route:")
            print(f"  {format_command(report['suggested_saved_rust_route_command'])}")
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())
