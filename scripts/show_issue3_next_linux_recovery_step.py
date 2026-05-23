#!/usr/bin/env python3

"""Recommend the next Linux or WSL issue #3 recovery helper to run.

This keeps the saved-snapshot restore route, Memory preflight, offline-inputs
route, saved Rust route, Zig recovery route, and final Windows runtime handoff
behind one small decision surface.
"""

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
import zipfile


DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"
MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)")
REQUIRED_MEMORY_FILES = (
    "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
    "repo_archives/browser/README.md",
    "repo_archives/browser/blocker_intelligence.yaml",
    "repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
    "repo_archives/browser/dependencies/03-boringssl-zig-main.zip",
    "repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip",
)
OPTIONAL_OFFLINE_MARKERS = ("brotli", "zlib", "nghttp2", "curl")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Recommend the next branch-local Linux or WSL recovery helper for "
            "the blocked issue #3 Enter-submit runtime route."
        )
    )
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--memory-root", default=None)
    parser.add_argument("--toolchains-root", default=None)
    parser.add_argument("--offline-deps-root", default=None)
    parser.add_argument("--restored-checkout-root", default=None)
    parser.add_argument("--fallback-zig-archive", default=None)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    return parser


def quote_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def resolve_default_memory_root(repo_root: Path) -> Path:
    return (repo_root.parent / "memory").resolve()


def resolve_default_toolchains_root(repo_root: Path) -> Path:
    return (repo_root.parent / "toolchains").resolve()


def resolve_default_offline_deps_root(repo_root: Path) -> Path:
    return (repo_root.parent / "offline-deps").resolve()


def resolve_default_restored_checkout_root(repo_root: Path) -> Path:
    return (repo_root.parent / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()


def resolve_default_fallback_zig_archive(repo_root: Path) -> Path:
    return (repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG).resolve()


def parse_semver(value: str) -> tuple[int, int, int]:
    match = SEMVER_RE.match(value)
    if match is None:
        raise ValueError(f"Could not parse semantic version from {value!r}")
    return tuple(int(part) for part in match.groups())


def load_minimum_zig(repo_root: Path) -> str:
    text = (repo_root / "build.zig.zon").read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError("Could not find .minimum_zig_version in build.zig.zon")
    return match.group(1)


def find_matching_zig(toolchains_root: Path, minimum_zig: str) -> tuple[Path | None, str | None]:
    expected_major_minor = parse_semver(minimum_zig)[:2]
    if not toolchains_root.is_dir():
        return None, None

    patterns = ("zig*/zig", "zig*/bin/zig", "*/zig", "*/bin/zig", "zig")
    seen: set[Path] = set()
    for pattern in patterns:
        for candidate in sorted(toolchains_root.glob(pattern)):
            resolved = candidate.resolve()
            if resolved in seen or not resolved.is_file():
                continue
            seen.add(resolved)
            try:
                completed = subprocess.run(
                    [str(resolved), "version"],
                    check=True,
                    capture_output=True,
                    text=True,
                )
            except (OSError, subprocess.CalledProcessError):
                continue
            version = completed.stdout.strip() or completed.stderr.strip()
            try:
                actual_major_minor = parse_semver(version)[:2]
            except ValueError:
                continue
            if actual_major_minor == expected_major_minor:
                return resolved, version
    return None, None


def memory_inputs_ok(memory_root: Path) -> tuple[bool, list[str]]:
    missing: list[str] = []
    for relative_path in REQUIRED_MEMORY_FILES:
        if not (memory_root / relative_path).is_file():
            missing.append(relative_path)
    return not missing, missing


def restored_checkout_ready(restored_checkout_root: Path) -> bool:
    return (
        restored_checkout_root.is_dir()
        and (restored_checkout_root / "build.zig.zon").is_file()
    )


def saved_rust_ready(toolchains_root: Path) -> bool:
    cargo = toolchains_root / "rust-1.79.0" / "cargo" / "bin" / "cargo"
    rustc = toolchains_root / "rust-1.79.0" / "rustc" / "bin" / "rustc"
    return cargo.is_file() and rustc.is_file()


def offline_inputs_ready(repo_root: Path, offline_deps_root: Path) -> bool:
    sibling_roots = (
        (repo_root.parent / "zig-v8-fork").is_dir(),
        (repo_root.parent / "boringssl-zig").is_dir(),
        offline_deps_root.is_dir(),
    )
    if not all(sibling_roots):
        return False
    return any((offline_deps_root / marker).exists() for marker in OPTIONAL_OFFLINE_MARKERS)


def build_result(
    *,
    repo_root: Path,
    memory_root: Path,
    toolchains_root: Path,
    offline_deps_root: Path,
    restored_checkout_root: Path,
    fallback_zig_archive: Path | None,
) -> dict[str, object]:
    minimum_zig = load_minimum_zig(repo_root)
    memory_ok, missing_memory = memory_inputs_ok(memory_root)
    matching_zig, matching_zig_version = find_matching_zig(toolchains_root, minimum_zig)
    rust_ok = saved_rust_ready(toolchains_root)
    restored_ok = restored_checkout_ready(restored_checkout_root)
    offline_ok = offline_inputs_ready(repo_root, offline_deps_root)

    saved_archives_root = memory_root / "repo_archives" / "browser" / "dependencies"
    fallback_parts: list[str] = []
    if fallback_zig_archive is not None and fallback_zig_archive.is_file():
        fallback_parts = ["--fallback-zig-archive", str(fallback_zig_archive)]

    if not memory_ok:
        stage = "memory-inputs"
        reason = "Required saved Memory inputs are missing."
        command = quote_command(
            ["python", "scripts/check_issue3_saved_memory_inputs.py", "--repo-root", str(repo_root), *fallback_parts]
        )
    elif not restored_ok:
        stage = "restore-checkout"
        reason = "No reusable restored checkout is ready beside the workspace."
        command = quote_command(
            ["bash", "scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "--repo-root", str(repo_root), *fallback_parts]
        )
    elif not rust_ok:
        stage = "saved-rust"
        reason = "The saved Rust 1.79.0 toolchain is not restored under ../toolchains yet."
        command = quote_command(
            [
                "bash",
                "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
                "--browser-root",
                str(repo_root),
                "--dependencies-root",
                str(saved_archives_root),
                "--toolchain-root",
                str(toolchains_root / "rust-1.79.0"),
            ]
        )
    elif not offline_ok:
        stage = "offline-inputs"
        reason = "The sibling offline dependency layout is not staged yet."
        command = quote_command(
            [
                "bash",
                "scripts/linux/show_issue3_offline_build_inputs_route.sh",
                "--repo-root",
                str(repo_root),
                "--saved-archives-root",
                str(saved_archives_root),
                "--offline-deps-root",
                str(offline_deps_root),
                *fallback_parts,
            ]
        )
    elif matching_zig is None:
        stage = "zig-toolchain"
        reason = f"No staged Zig binary matches the branch minimum {minimum_zig} line."
        command = quote_command(
            [
                "bash",
                "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
                "--repo-root",
                str(repo_root),
                "--toolchains-root",
                str(toolchains_root),
                "--saved-archives-root",
                str(saved_archives_root),
                "--offline-deps-root",
                str(offline_deps_root),
                *fallback_parts,
            ]
        )
    else:
        stage = "windows-runtime-handoff"
        reason = "The saved-archive setup surfaces look ready enough to reopen the narrow Windows runtime route."
        command = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1"
        )

    return {
        "issue": "Google issue #3 next Linux recovery step",
        "repo_root": str(repo_root),
        "memory_root": str(memory_root),
        "toolchains_root": str(toolchains_root),
        "offline_deps_root": str(offline_deps_root),
        "restored_checkout_root": str(restored_checkout_root),
        "minimum_zig": minimum_zig,
        "fallback_zig_archive": str(fallback_zig_archive) if fallback_zig_archive else "",
        "matching_zig": str(matching_zig) if matching_zig else "",
        "matching_zig_version": matching_zig_version or "",
        "saved_memory_inputs_ok": memory_ok,
        "missing_memory_inputs": missing_memory,
        "restored_checkout_ready": restored_ok,
        "saved_rust_ready": rust_ok,
        "offline_inputs_ready": offline_ok,
        "recommended_stage": stage,
        "reason": reason,
        "recommended_command": command,
    }


def emit_text(result: dict[str, object]) -> None:
    print("Google issue #3 next Linux recovery step")
    print()
    print(f"Repo root:              {result['repo_root']}")
    print(f"Memory root:            {result['memory_root']}")
    print(f"Toolchains root:        {result['toolchains_root']}")
    print(f"Offline deps root:      {result['offline_deps_root']}")
    print(f"Restored checkout root: {result['restored_checkout_root']}")
    print(f"Minimum Zig line:       {result['minimum_zig']}")
    print(f"Fallback Zig archive:   {result['fallback_zig_archive'] or 'not found beside the repo workspace'}")
    print()
    print("Current checkpoints")
    print("===================")
    print(f"  Saved Memory inputs:  {'ready' if result['saved_memory_inputs_ok'] else 'missing pieces'}")
    print(f"  Restored checkout:    {'ready' if result['restored_checkout_ready'] else 'missing'}")
    print(f"  Saved Rust toolchain: {'ready' if result['saved_rust_ready'] else 'missing'}")
    print(f"  Offline inputs:       {'ready' if result['offline_inputs_ready'] else 'missing'}")
    if result["matching_zig"]:
        print(f"  Matching Zig:         {result['matching_zig']} [{result['matching_zig_version']}]")
    else:
        print("  Matching Zig:         not staged")
    if result["missing_memory_inputs"]:
        print("  Missing Memory items:")
        for relative_path in result["missing_memory_inputs"]:
            print(f"    {relative_path}")
    print()
    print(f"Recommended stage: {result['recommended_stage']}")
    print(f"Reason: {result['reason']}")
    print()
    print("Next command")
    print("============")
    print(f"  {result['recommended_command']}")


class NextRecoveryStepTests(unittest.TestCase):
    def write_minimum_zig(self, repo_root: Path, minimum_zig: str = "0.15.2") -> None:
        (repo_root / "build.zig.zon").write_text(
            f'.minimum_zig_version = "{minimum_zig}"\n',
            encoding="utf-8",
        )

    def populate_memory(self, memory_root: Path) -> None:
        for relative_path in REQUIRED_MEMORY_FILES:
            target = memory_root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.suffix == ".zip":
                with zipfile.ZipFile(target, "w") as archive:
                    archive.writestr("browser-fork-headed-mode-foundation/README.md", "x")
            else:
                target.write_text("x", encoding="utf-8")

    def test_missing_memory_inputs_win_first(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            self.write_minimum_zig(repo_root)

            result = build_result(
                repo_root=repo_root,
                memory_root=root / "memory",
                toolchains_root=root / "toolchains",
                offline_deps_root=root / "offline-deps",
                restored_checkout_root=root / DEFAULT_RESTORED_CHECKOUT_NAME,
                fallback_zig_archive=None,
            )

            self.assertEqual(result["recommended_stage"], "memory-inputs")

    def test_missing_restored_checkout_is_next_after_memory(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            self.write_minimum_zig(repo_root)
            self.populate_memory(root / "memory")

            result = build_result(
                repo_root=repo_root,
                memory_root=root / "memory",
                toolchains_root=root / "toolchains",
                offline_deps_root=root / "offline-deps",
                restored_checkout_root=root / DEFAULT_RESTORED_CHECKOUT_NAME,
                fallback_zig_archive=None,
            )

            self.assertEqual(result["recommended_stage"], "restore-checkout")

    def test_missing_rust_is_prioritized_before_offline_and_zig(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            self.write_minimum_zig(repo_root)
            self.populate_memory(root / "memory")
            restored = root / DEFAULT_RESTORED_CHECKOUT_NAME
            restored.mkdir()
            (restored / "build.zig.zon").write_text("{}", encoding="utf-8")

            result = build_result(
                repo_root=repo_root,
                memory_root=root / "memory",
                toolchains_root=root / "toolchains",
                offline_deps_root=root / "offline-deps",
                restored_checkout_root=restored,
                fallback_zig_archive=None,
            )

            self.assertEqual(result["recommended_stage"], "saved-rust")

    def test_offline_inputs_come_before_zig_when_rust_exists(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            self.write_minimum_zig(repo_root)
            self.populate_memory(root / "memory")
            restored = root / DEFAULT_RESTORED_CHECKOUT_NAME
            restored.mkdir()
            (restored / "build.zig.zon").write_text("{}", encoding="utf-8")
            cargo = root / "toolchains" / "rust-1.79.0" / "cargo" / "bin"
            rustc = root / "toolchains" / "rust-1.79.0" / "rustc" / "bin"
            cargo.mkdir(parents=True)
            rustc.mkdir(parents=True)
            (cargo / "cargo").write_text("", encoding="utf-8")
            (rustc / "rustc").write_text("", encoding="utf-8")

            result = build_result(
                repo_root=repo_root,
                memory_root=root / "memory",
                toolchains_root=root / "toolchains",
                offline_deps_root=root / "offline-deps",
                restored_checkout_root=restored,
                fallback_zig_archive=None,
            )

            self.assertEqual(result["recommended_stage"], "offline-inputs")


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(NextRecoveryStepTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    memory_root = Path(args.memory_root).resolve() if args.memory_root else resolve_default_memory_root(repo_root)
    toolchains_root = (
        Path(args.toolchains_root).resolve() if args.toolchains_root else resolve_default_toolchains_root(repo_root)
    )
    offline_deps_root = (
        Path(args.offline_deps_root).resolve()
        if args.offline_deps_root
        else resolve_default_offline_deps_root(repo_root)
    )
    restored_checkout_root = (
        Path(args.restored_checkout_root).resolve()
        if args.restored_checkout_root
        else resolve_default_restored_checkout_root(repo_root)
    )
    fallback_zig_archive = (
        Path(args.fallback_zig_archive).resolve()
        if args.fallback_zig_archive
        else resolve_default_fallback_zig_archive(repo_root)
    )
    if not fallback_zig_archive.is_file():
        fallback_zig_archive = None

    result = build_result(
        repo_root=repo_root,
        memory_root=memory_root,
        toolchains_root=toolchains_root,
        offline_deps_root=offline_deps_root,
        restored_checkout_root=restored_checkout_root,
        fallback_zig_archive=fallback_zig_archive,
    )
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0


if __name__ == "__main__":
    sys.exit(main())
