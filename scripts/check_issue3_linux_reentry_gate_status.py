#!/usr/bin/env python3

"""Summarize which Linux/WSL issue #11 re-entry gate is still closed."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"(\d+)\.(\d+)\.(\d+)")
RUST_CANDIDATE_GLOBS = ("rust-*/cargo/bin/cargo", "*/cargo/bin/cargo")
ZIG_CANDIDATE_GLOBS = ("zig*/zig", "zig*/bin/zig", "*/zig", "*/bin/zig", "zig")
SAVED_ARCHIVE_PATTERNS = {
    "repo_snapshot": "01-browser-fork-headed-mode-foundation.zip",
    "rust_toolchain": "dependencies/01-rust-*.tar.xz",
    "html5ever": "dependencies/02-litefetch-html5ever-*.zip",
    "boringssl": "dependencies/03-boringssl-zig-main.zip",
    "browser_deps": "dependencies/04-zig-browser-depo.tar.zip",
}
OFFLINE_DEP_NAMES = ("brotli", "zlib", "nghttp2", "curl")
PREBUILT_V8_GLOB = "libc_v8_*.a"
DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"


def parse_semver(text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.search(text)
    if match is None:
        raise ValueError(f"could not parse semantic version from {text!r}")
    return tuple(int(part) for part in match.groups())


def same_major_minor(expected: str, actual: str) -> bool:
    return parse_semver(expected)[:2] == parse_semver(actual)[:2]


def read_minimum_zig(repo_root: Path) -> str:
    text = (repo_root / "build.zig.zon").read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError("minimum_zig_version not found in build.zig.zon")
    return match.group(1)


def run_version(binary: Path) -> str | None:
    try:
        completed = subprocess.run(
            [str(binary), "--version"],
            capture_output=True,
            check=True,
            text=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return None
    return completed.stdout.strip() or completed.stderr.strip() or None


def discover_rust_candidates(toolchains_root: Path) -> list[dict[str, str]]:
    if not toolchains_root.is_dir():
        return []

    reports: list[dict[str, str]] = []
    seen: set[Path] = set()
    for pattern in RUST_CANDIDATE_GLOBS:
        for cargo_path in sorted(toolchains_root.glob(pattern)):
            if not cargo_path.is_file():
                continue
            resolved = cargo_path.resolve()
            if resolved in seen:
                continue
            seen.add(resolved)
            toolchain_root = resolved.parent.parent.parent
            rustc_path = toolchain_root / "rustc" / "bin" / "rustc"
            cargo_output = run_version(resolved)
            rustc_output = run_version(rustc_path) if rustc_path.is_file() else None
            reports.append(
                {
                    "toolchain_root": str(toolchain_root),
                    "cargo_bin": str(resolved),
                    "rustc_bin": str(rustc_path),
                    "cargo_version": cargo_output or "",
                    "rustc_version": rustc_output or "",
                }
            )
    return reports


def discover_zig_candidates(toolchains_root: Path) -> list[dict[str, str]]:
    if not toolchains_root.is_dir():
        return []

    reports: list[dict[str, str]] = []
    seen: set[Path] = set()
    for pattern in ZIG_CANDIDATE_GLOBS:
        for zig_path in sorted(toolchains_root.glob(pattern)):
            if not zig_path.is_file():
                continue
            resolved = zig_path.resolve()
            if resolved in seen:
                continue
            seen.add(resolved)
            version = run_version(resolved)
            reports.append({"zig_bin": str(resolved), "version": version or ""})
    return reports


def discover_saved_archives(memory_browser_root: Path) -> dict[str, str]:
    discovered: dict[str, str] = {}
    for key, pattern in SAVED_ARCHIVE_PATTERNS.items():
        matches = sorted(memory_browser_root.glob(pattern))
        if matches:
            discovered[key] = str(matches[0].resolve())
    return discovered


def check_offline_deps(offline_deps_root: Path) -> dict[str, object]:
    status = {
        "root": str(offline_deps_root),
        "present": offline_deps_root.is_dir(),
        "missing_dirs": [],
        "prebuilt_v8": "",
    }
    if not offline_deps_root.is_dir():
        status["missing_dirs"] = list(OFFLINE_DEP_NAMES)
        return status

    missing = [name for name in OFFLINE_DEP_NAMES if not (offline_deps_root / name).is_dir()]
    status["missing_dirs"] = missing
    prebuilt = sorted(offline_deps_root.glob(PREBUILT_V8_GLOB))
    if prebuilt:
        status["prebuilt_v8"] = str(prebuilt[0].resolve())
    return status


def resolve_workspace_root(repo_root: Path) -> Path:
    markers = ("memory", "agent_files", "toolchains", "offline-deps")
    for candidate in (repo_root, *repo_root.parents):
        if any((candidate / marker).exists() for marker in markers):
            return candidate
    return repo_root.parent


def choose_next_step(
    *,
    saved_archives: dict[str, str],
    preferred_rust: dict[str, str] | None,
    preferred_zig: dict[str, str] | None,
    offline_status: dict[str, object],
    repo_root: Path,
) -> tuple[str, str]:
    if "repo_snapshot" not in saved_archives or "rust_toolchain" not in saved_archives or "boringssl" not in saved_archives or "browser_deps" not in saved_archives:
        return (
            "saved-memory",
            f"python {repo_root / 'scripts' / 'check_issue3_saved_memory_inputs.py'} --repo-root {repo_root}",
        )
    if preferred_rust is None:
        return (
            "saved-rust",
            f"bash {repo_root / 'scripts' / 'linux' / 'show_issue3_saved_rust_toolchain_route.sh'} --browser-root {repo_root}",
        )
    if preferred_zig is None:
        return (
            "zig-recovery",
            f"bash {repo_root / 'scripts' / 'linux' / 'show_issue3_zig_toolchain_recovery_route.sh'} --repo-root {repo_root}",
        )
    if offline_status["missing_dirs"] or not offline_status["prebuilt_v8"]:
        return (
            "offline-inputs",
            f"bash {repo_root / 'scripts' / 'linux' / 'show_issue3_offline_build_inputs_route.sh'} --browser-root {repo_root}",
        )
    return (
        "build-readiness",
        (
            f"python {repo_root / 'scripts' / 'check_linux_build_readiness.py'} "
            f"--repo-root {repo_root} --expect-saved-archives --expect-offline-deps --require-prebuilt-v8"
        ),
    )


def build_report(repo_root: Path, *, fallback_zig_archive: Path | None = None) -> dict[str, object]:
    minimum_zig = read_minimum_zig(repo_root)
    workspace_root = resolve_workspace_root(repo_root)
    memory_browser_root = workspace_root / "memory" / "repo_archives" / "browser"
    toolchains_root = workspace_root / "toolchains"
    offline_deps_root = workspace_root / "offline-deps"
    fallback_path = fallback_zig_archive or (workspace_root / "agent_files" / DEFAULT_FALLBACK_ZIG)

    saved_archives = discover_saved_archives(memory_browser_root)
    rust_candidates = discover_rust_candidates(toolchains_root)
    zig_candidates = discover_zig_candidates(toolchains_root)
    offline_status = check_offline_deps(offline_deps_root)

    preferred_rust = next(
        (
            candidate
            for candidate in rust_candidates
            if candidate["cargo_version"] and candidate["rustc_version"]
            and parse_semver(candidate["cargo_version"]) == (1, 79, 0)
            and parse_semver(candidate["rustc_version"]) == (1, 79, 0)
        ),
        None,
    )
    preferred_zig = next(
        (
            candidate
            for candidate in zig_candidates
            if candidate["version"] and same_major_minor(minimum_zig, candidate["version"])
        ),
        None,
    )

    next_gate, next_command = choose_next_step(
        saved_archives=saved_archives,
        preferred_rust=preferred_rust,
        preferred_zig=preferred_zig,
        offline_status=offline_status,
        repo_root=repo_root,
    )

    return {
        "status": "passed" if next_gate == "build-readiness" else "gated",
        "repo_root": str(repo_root),
        "minimum_zig": minimum_zig,
        "memory_browser_root": str(memory_browser_root),
        "toolchains_root": str(toolchains_root),
        "offline_deps_root": str(offline_deps_root),
        "fallback_zig_archive": str(fallback_path),
        "fallback_zig_present": fallback_path.is_file(),
        "saved_archives": saved_archives,
        "rust_candidates": rust_candidates,
        "preferred_rust": preferred_rust,
        "zig_candidates": zig_candidates,
        "preferred_zig": preferred_zig,
        "offline_status": offline_status,
        "next_gate": next_gate,
        "next_command": next_command,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Summarize which issue #11 Linux/WSL re-entry gate is still closed."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit path to the fallback Zig archive",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON output")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


class LinuxReentryGateStatusTests(unittest.TestCase):
    def test_same_major_minor_matches_line(self) -> None:
        self.assertTrue(same_major_minor("0.15.2", "0.15.7"))
        self.assertFalse(same_major_minor("0.15.2", "0.17.0-dev.299+a76ce7710"))

    def test_discover_saved_archives_reads_expected_layout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            (root / "01-browser-fork-headed-mode-foundation.zip").write_text("repo", encoding="utf-8")
            deps = root / "dependencies"
            deps.mkdir()
            (deps / "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz").write_text("rust", encoding="utf-8")
            (deps / "03-boringssl-zig-main.zip").write_text("ssl", encoding="utf-8")
            (deps / "04-zig-browser-depo.tar.zip").write_text("deps", encoding="utf-8")

            discovered = discover_saved_archives(root)

            self.assertIn("repo_snapshot", discovered)
            self.assertIn("rust_toolchain", discovered)
            self.assertIn("boringssl", discovered)
            self.assertIn("browser_deps", discovered)

    def test_check_offline_deps_reports_missing_dirs(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            status = check_offline_deps(Path(tmpdir))
            self.assertEqual(sorted(status["missing_dirs"]), sorted(OFFLINE_DEP_NAMES))

    def test_choose_next_step_prefers_saved_memory_first(self) -> None:
        gate, _command = choose_next_step(
            saved_archives={},
            preferred_rust=None,
            preferred_zig=None,
            offline_status={"missing_dirs": list(OFFLINE_DEP_NAMES), "prebuilt_v8": ""},
            repo_root=Path("/tmp/browser"),
        )
        self.assertEqual(gate, "saved-memory")

    def test_resolve_workspace_root_finds_shared_memory_ancestor(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace = Path(tmpdir)
            repo_root = workspace / "nested" / "browser"
            repo_root.mkdir(parents=True)
            (workspace / "memory").mkdir()
            (workspace / "agent_files").mkdir()

            self.assertEqual(resolve_workspace_root(repo_root), workspace)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(LinuxReentryGateStatusTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    fallback = Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None
    report = build_report(repo_root, fallback_zig_archive=fallback)

    if args.json:
        print(json.dumps(report, indent=2))
        return 0 if report["status"] == "passed" else 1

    print("Issue #11 Linux/WSL re-entry gate status")
    print()
    print(f"Repo root:           {report['repo_root']}")
    print(f"Minimum Zig line:    {report['minimum_zig']}")
    print(f"Memory browser root: {report['memory_browser_root']}")
    print(f"Toolchains root:     {report['toolchains_root']}")
    print(f"Offline deps root:   {report['offline_deps_root']}")
    print(f"Fallback Zig:        {report['fallback_zig_archive']} [{'present' if report['fallback_zig_present'] else 'missing'}]")
    print()
    print(f"Saved archives found: {', '.join(sorted(report['saved_archives'])) or 'none'}")
    print(f"Rust candidates:      {len(report['rust_candidates'])}")
    if report["preferred_rust"] is not None:
        print(f"Preferred Rust:       {report['preferred_rust']['toolchain_root']}")
    else:
        print("Preferred Rust:       none")
    print(f"Zig candidates:       {len(report['zig_candidates'])}")
    if report["preferred_zig"] is not None:
        print(f"Preferred Zig:        {report['preferred_zig']['zig_bin']} [{report['preferred_zig']['version']}]")
    else:
        print("Preferred Zig:        none")
    missing_dirs = report["offline_status"]["missing_dirs"]
    print(f"Offline deps missing: {', '.join(missing_dirs) if missing_dirs else 'none'}")
    print(
        "Prebuilt V8:         "
        + (report["offline_status"]["prebuilt_v8"] or "missing")
    )
    print()
    print(f"Next gate:    {report['next_gate']}")
    print(f"Next command: {report['next_command']}")
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
