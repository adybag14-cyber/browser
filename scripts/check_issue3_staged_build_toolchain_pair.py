#!/usr/bin/env python3

"""Surface staged Rust and Zig toolchain pairs for the issue #11 re-entry lane."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile
import unittest


EXPECTED_RUST_VERSION = "1.79.0"
DEFAULT_ZIG_GLOBS = (
    "zig*/zig",
    "zig*/bin/zig",
    "*/zig",
    "*/bin/zig",
    "zig",
)
DEFAULT_RUST_GLOBS = (
    "rust-*/cargo/bin/cargo",
    "*/cargo/bin/cargo",
)
MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"(\d+)\.(\d+)\.(\d+)")


def parse_semver(text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.search(text)
    if match is None:
        raise ValueError(f"Could not parse semantic version from {text!r}")
    return tuple(int(part) for part in match.groups())


def same_major_minor(expected: str, actual: str) -> bool:
    return parse_semver(expected)[:2] == parse_semver(actual)[:2]


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


def resolve_default_toolchains_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "toolchains")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "toolchains").resolve()


def load_minimum_zig(repo_root: Path) -> str:
    text = (repo_root / "build.zig.zon").read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError("Could not find minimum_zig_version in build.zig.zon")
    return match.group(1)


def discover_candidates(toolchains_root: Path, patterns: tuple[str, ...]) -> list[Path]:
    if not toolchains_root.is_dir():
        return []

    seen: set[Path] = set()
    candidates: list[Path] = []
    for pattern in patterns:
        for path in sorted(toolchains_root.glob(pattern)):
            if not path.is_file():
                continue
            resolved = path.resolve()
            if resolved in seen:
                continue
            seen.add(resolved)
            candidates.append(resolved)
    return candidates


def run_version(binary: Path, label: str) -> tuple[list[str], str | None]:
    try:
        completed = subprocess.run(
            [str(binary), "--version" if label != "zig" else "version"],
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


def describe_zig_candidate(minimum_zig: str, zig_bin: Path) -> dict[str, object]:
    failures, version_output = run_version(zig_bin, "zig")
    version = SEMVER_RE.search(version_output or "")
    parsed = version.group(0) if version is not None else None
    if parsed is None:
        status = "unknown version"
    elif parse_semver(parsed) < parse_semver(minimum_zig):
        status = "older than minimum"
    elif same_major_minor(minimum_zig, parsed):
        status = f"matches expected {parse_semver(minimum_zig)[0]}.{parse_semver(minimum_zig)[1]}.x line"
    else:
        status = f"mismatched: expected {parse_semver(minimum_zig)[0]}.{parse_semver(minimum_zig)[1]}.x line"
    return {
        "zig_bin": zig_bin,
        "version": parsed,
        "status": status,
        "failures": failures,
    }


def describe_rust_candidate(cargo_bin: Path) -> dict[str, object]:
    cargo_failures, cargo_output = run_version(cargo_bin, "cargo")
    cargo_version_match = SEMVER_RE.search(cargo_output or "")
    cargo_version = cargo_version_match.group(0) if cargo_version_match is not None else None

    rustc_bin = cargo_bin.parent.parent.parent / "rustc" / "bin" / "rustc"
    if rustc_bin.is_file():
        rustc_failures, rustc_output = run_version(rustc_bin, "rustc")
    else:
        rustc_failures, rustc_output = ([f"missing rustc beside cargo: {rustc_bin}"], None)
    rustc_version_match = SEMVER_RE.search(rustc_output or "")
    rustc_version = rustc_version_match.group(0) if rustc_version_match is not None else None

    if cargo_version == EXPECTED_RUST_VERSION and rustc_version == EXPECTED_RUST_VERSION:
        status = f"matches expected {EXPECTED_RUST_VERSION}"
    elif cargo_version == EXPECTED_RUST_VERSION and rustc_version is None:
        status = f"cargo matches expected {EXPECTED_RUST_VERSION} but rustc is unavailable"
    elif cargo_version == EXPECTED_RUST_VERSION:
        status = f"mismatched rustc: expected {EXPECTED_RUST_VERSION}"
    else:
        status = f"mismatched: expected {EXPECTED_RUST_VERSION}"

    toolchain_root = cargo_bin.parent.parent.parent
    return {
        "toolchain_root": toolchain_root,
        "cargo_bin": cargo_bin,
        "rustc_bin": rustc_bin,
        "cargo_version": cargo_version,
        "rustc_version": rustc_version,
        "status": status,
        "failures": cargo_failures + rustc_failures,
        "path_export": f'export PATH="{toolchain_root / "cargo" / "bin"}:{toolchain_root / "rustc" / "bin"}:$PATH"',
        "cargo_export": f'export CARGO="{cargo_bin}"',
        "rustc_export": f'export RUSTC="{rustc_bin}"',
    }


def choose_preferred_zig(candidates: list[dict[str, object]]) -> dict[str, object] | None:
    for candidate in candidates:
        if str(candidate["status"]).startswith("matches expected"):
            return candidate
    return None


def choose_preferred_rust(candidates: list[dict[str, object]]) -> dict[str, object] | None:
    for candidate in candidates:
        if candidate["status"] == f"matches expected {EXPECTED_RUST_VERSION}":
            return candidate
    return None


def format_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def build_readiness_command(
    repo_root: Path,
    zig_bin: Path,
    cargo_bin: Path,
    rustc_bin: Path,
) -> str:
    return format_command(
        [
            "python3",
            str(repo_root / "scripts" / "check_linux_build_readiness.py"),
            "--repo-root",
            str(repo_root),
            "--zig",
            str(zig_bin),
            "--cargo",
            str(cargo_bin),
            "--rustc",
            str(rustc_bin),
        ]
    )


def collect_results(repo_root: Path, toolchains_root: Path) -> dict[str, object]:
    minimum_zig = load_minimum_zig(repo_root)
    zig_candidates = [
        describe_zig_candidate(minimum_zig, path)
        for path in discover_candidates(toolchains_root, DEFAULT_ZIG_GLOBS)
    ]
    rust_candidates = [
        describe_rust_candidate(path)
        for path in discover_candidates(toolchains_root, DEFAULT_RUST_GLOBS)
    ]
    preferred_zig = choose_preferred_zig(zig_candidates)
    preferred_rust = choose_preferred_rust(rust_candidates)

    ready_pair = preferred_zig is not None and preferred_rust is not None
    readiness_command = None
    if ready_pair:
        readiness_command = build_readiness_command(
            repo_root,
            Path(str(preferred_zig["zig_bin"])),
            Path(str(preferred_rust["cargo_bin"])),
            Path(str(preferred_rust["rustc_bin"])),
        )

    failures: list[str] = []
    if preferred_rust is None:
        failures.append(
            f"no staged Rust toolchain under {toolchains_root} matches the expected {EXPECTED_RUST_VERSION}"
        )
    if preferred_zig is None:
        failures.append(
            "no staged Zig toolchain under "
            f"{toolchains_root} matches the branch minimum "
            f"{parse_semver(minimum_zig)[0]}.{parse_semver(minimum_zig)[1]}.x line"
        )

    return {
        "status": "passed" if ready_pair else "failed",
        "repo_root": repo_root,
        "toolchains_root": toolchains_root,
        "expected_rust": EXPECTED_RUST_VERSION,
        "minimum_zig": minimum_zig,
        "preferred_rust": preferred_rust,
        "preferred_zig": preferred_zig,
        "rust_candidates": rust_candidates,
        "zig_candidates": zig_candidates,
        "readiness_command": readiness_command,
        "failures": failures,
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
        description="Surface a staged Rust/Zig toolchain pair for the issue #11 Linux/WSL re-entry lane."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Path to the shared toolchains directory (default: nearest ancestor toolchains root or ../toolchains)",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON output")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


class StagedBuildToolchainPairTests(unittest.TestCase):
    def write_executable(self, path: Path, line: str) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f"#!/usr/bin/env bash\necho {line}\n", encoding="utf-8")
        os.chmod(path, 0o755)

    def make_repo(self, root: Path, minimum_zig: str = "0.15.2") -> Path:
        repo_root = root / "browser"
        repo_root.mkdir()
        (repo_root / "build.zig.zon").write_text(
            (
                '.{ .name = .browser, .version = "0.0.0", '
                f'.minimum_zig_version = "{minimum_zig}", .dependencies = .{{}}, .paths = .{{""}}, }}'
            ),
            encoding="utf-8",
        )
        return repo_root

    def make_rust_toolchain(self, root: Path, name: str, cargo_version: str, rustc_version: str | None) -> None:
        cargo_bin = root / name / "cargo" / "bin" / "cargo"
        self.write_executable(cargo_bin, f"cargo {cargo_version}")
        if rustc_version is not None:
            rustc_bin = root / name / "rustc" / "bin" / "rustc"
            self.write_executable(rustc_bin, f"rustc {rustc_version}")

    def make_zig_toolchain(self, root: Path, name: str, version: str) -> None:
        zig_bin = root / name / "zig"
        self.write_executable(zig_bin, version)

    def test_collect_results_passes_with_matching_rust_and_zig(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = self.make_repo(root)
            toolchains_root = root / "toolchains"
            self.make_rust_toolchain(toolchains_root, "rust-1.79.0", "1.79.0", "1.79.0")
            self.make_zig_toolchain(toolchains_root, "zig-0.15.7", "0.15.7")

            result = collect_results(repo_root, toolchains_root)

            self.assertEqual(result["status"], "passed")
            self.assertIsNotNone(result["preferred_rust"])
            self.assertIsNotNone(result["preferred_zig"])
            self.assertIn("--zig", result["readiness_command"])
            self.assertIn("--cargo", result["readiness_command"])
            self.assertIn("--rustc", result["readiness_command"])

    def test_collect_results_fails_when_only_one_side_matches(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = self.make_repo(root)
            toolchains_root = root / "toolchains"
            self.make_rust_toolchain(toolchains_root, "rust-1.79.0", "1.79.0", "1.79.0")
            self.make_zig_toolchain(toolchains_root, "zig-0.17.0", "0.17.0-dev.299+a76ce7710")

            result = collect_results(repo_root, toolchains_root)

            self.assertEqual(result["status"], "failed")
            self.assertIsNotNone(result["preferred_rust"])
            self.assertIsNone(result["preferred_zig"])
            self.assertTrue(result["failures"])

    def test_default_toolchains_root_discovers_ancestor_workspace(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace = Path(tmpdir)
            repo_root = workspace / "restored" / "browser-memory-snapshot" / "browser"
            repo_root.mkdir(parents=True)
            toolchains_root = workspace / "toolchains"
            toolchains_root.mkdir()
            self.assertEqual(resolve_default_toolchains_root(repo_root), toolchains_root.resolve())


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(StagedBuildToolchainPairTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    toolchains_root = (
        Path(args.toolchains_root).resolve() if args.toolchains_root else resolve_default_toolchains_root(repo_root)
    )
    results = collect_results(repo_root, toolchains_root)

    if args.json:
        print(json.dumps(serialize(results), indent=2))
        return 0 if results["status"] == "passed" else 1

    print("Issue #11 staged build-toolchain pair")
    print()
    print(f"Repo root:       {repo_root}")
    print(f"Toolchains root: {toolchains_root}")
    print(f"Expected Rust:   {EXPECTED_RUST_VERSION}")
    print(f"Minimum Zig:     {results['minimum_zig']}")
    print()
    print("Staged Rust candidates:")
    if results["rust_candidates"]:
        for candidate in results["rust_candidates"]:
            print(
                "  - "
                f"{candidate['toolchain_root']} "
                f"[cargo={candidate['cargo_version'] or 'unknown'}, "
                f"rustc={candidate['rustc_version'] or 'unknown'}; "
                f"{candidate['status']}]"
            )
    else:
        print("  none")

    print()
    print("Staged Zig candidates:")
    if results["zig_candidates"]:
        for candidate in results["zig_candidates"]:
            print(
                "  - "
                f"{candidate['zig_bin']} "
                f"[{candidate['version'] or 'unknown'}; {candidate['status']}]"
            )
    else:
        print("  none")

    if results["status"] == "passed":
        print()
        print("Preferred staged pair:")
        print(f"  Rust: {results['preferred_rust']['toolchain_root']}")
        print(f"  Zig:  {results['preferred_zig']['zig_bin']}")
        print()
        print("Exact readiness rerun:")
        print(f"  {results['readiness_command']}")
        return 0

    print()
    print("No full staged Rust/Zig pair is ready.", file=sys.stderr)
    for failure in results["failures"]:
        print(f"  - {failure}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
