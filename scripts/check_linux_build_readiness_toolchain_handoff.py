#!/usr/bin/env python3

"""Surface one exact staged Rust+Zig handoff for Linux build-readiness reruns."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile
import unittest


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"(\d+)\.(\d+)\.(\d+)")
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


def parse_semver(text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.search(text)
    if match is None:
        raise ValueError(f"Could not parse semantic version from {text!r}")
    return tuple(int(part) for part in match.groups())


def same_version_line(expected: str, actual: str) -> bool:
    return parse_semver(expected)[:2] == parse_semver(actual)[:2]


def format_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


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
    zon_path = repo_root / "build.zig.zon"
    text = zon_path.read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError(f"Could not find minimum_zig_version in {zon_path}")
    return match.group(1)


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


def discover_candidates(root: Path, globs: tuple[str, ...]) -> list[Path]:
    if not root.is_dir():
        return []

    seen: set[Path] = set()
    candidates: list[Path] = []
    for pattern in globs:
        for path in sorted(root.glob(pattern)):
            if not path.is_file():
                continue
            resolved = path.resolve()
            if resolved in seen:
                continue
            seen.add(resolved)
            candidates.append(resolved)
    return candidates


def describe_zig_candidate(expected_zig: str, zig_bin: Path) -> dict[str, object]:
    failures, version_output = run_version(zig_bin, "zig")
    version = version_output if version_output else None
    status = "unknown version"
    if version is not None:
        if parse_semver(version) < parse_semver(expected_zig):
            status = "older than minimum"
        elif same_version_line(expected_zig, version):
            status = f"matches expected {parse_semver(expected_zig)[0]}.{parse_semver(expected_zig)[1]}.x line"
        else:
            status = f"mismatched: expected {parse_semver(expected_zig)[0]}.{parse_semver(expected_zig)[1]}.x line"
    return {
        "toolchain_root": zig_bin.parent if zig_bin.parent.name != "bin" else zig_bin.parent.parent,
        "zig_bin": zig_bin,
        "version": version,
        "status": status,
        "failures": failures,
        "zig_export": f'export ZIG="{zig_bin}"',
    }


def describe_rust_candidate(expected_rust: str, cargo_bin: Path) -> dict[str, object]:
    cargo_failures, cargo_output = run_version(cargo_bin, "cargo")
    rustc_bin = cargo_bin.parent.parent.parent / "rustc" / "bin" / "rustc"
    rustc_exists = rustc_bin.is_file()
    rustc_failures, rustc_output = ([], None)
    if rustc_exists:
        rustc_failures, rustc_output = run_version(rustc_bin, "rustc")
    else:
        rustc_failures = [f"missing rustc beside cargo: {rustc_bin}"]

    cargo_version = None
    rustc_version = None
    if cargo_output:
        match = SEMVER_RE.search(cargo_output)
        cargo_version = match.group(0) if match else None
    if rustc_output:
        match = SEMVER_RE.search(rustc_output)
        rustc_version = match.group(0) if match else None

    status = "unknown version"
    if cargo_version is not None:
        if parse_semver(cargo_version) < parse_semver(expected_rust):
            status = "older than expected"
        elif same_version_line(expected_rust, cargo_version):
            status = f"matches expected {parse_semver(expected_rust)[0]}.{parse_semver(expected_rust)[1]}.x line"
        else:
            status = f"mismatched: expected {parse_semver(expected_rust)[0]}.{parse_semver(expected_rust)[1]}.x line"
    if status.startswith("matches expected") and rustc_version is None:
        status = f"cargo matches expected {parse_semver(expected_rust)[0]}.{parse_semver(expected_rust)[1]}.x but rustc is unavailable"
    elif status.startswith("matches expected") and rustc_version is not None and not same_version_line(expected_rust, rustc_version):
        status = f"mismatched rustc: expected {parse_semver(expected_rust)[0]}.{parse_semver(expected_rust)[1]}.x line"

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


def choose_preferred_zig(expected_zig: str, candidates: list[dict[str, object]], toolchains_root: Path) -> dict[str, object] | None:
    matching = [
        candidate
        for candidate in candidates
        if isinstance(candidate.get("version"), str)
        and str(candidate.get("status", "")).startswith("matches expected")
    ]
    if not matching:
        return None

    expected_root = toolchains_root / f"zig-{expected_zig}"
    for candidate in matching:
        if Path(str(candidate["toolchain_root"])).resolve() == expected_root.resolve():
            return candidate

    return max(matching, key=lambda candidate: parse_semver(str(candidate["version"])))


def choose_preferred_rust(expected_rust: str, candidates: list[dict[str, object]], toolchains_root: Path) -> dict[str, object] | None:
    matching = [
        candidate
        for candidate in candidates
        if isinstance(candidate.get("cargo_version"), str)
        and isinstance(candidate.get("rustc_version"), str)
        and str(candidate.get("status", "")).startswith("matches expected")
    ]
    if not matching:
        return None

    expected_root = toolchains_root / f"rust-{expected_rust}"
    for candidate in matching:
        if Path(str(candidate["toolchain_root"])).resolve() == expected_root.resolve():
            return candidate

    return max(matching, key=lambda candidate: parse_semver(str(candidate["cargo_version"])))


def build_readiness_command(
    repo_root: Path,
    toolchains_root: Path,
    zig_candidate: dict[str, object] | None,
    rust_candidate: dict[str, object] | None,
) -> list[str]:
    command = [
        "python",
        str(repo_root / "scripts" / "check_linux_build_readiness.py"),
        "--repo-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
    ]
    if zig_candidate is not None:
        command.extend(["--zig", str(zig_candidate["zig_bin"])])
    if rust_candidate is not None:
        command.extend(["--cargo", str(rust_candidate["cargo_bin"])])
        command.extend(["--rustc", str(rust_candidate["rustc_bin"])])
    return command


def collect_results(repo_root: Path, toolchains_root: Path) -> dict[str, object]:
    expected_zig = load_minimum_zig(repo_root)
    zig_candidates = [
        describe_zig_candidate(expected_zig, path)
        for path in discover_candidates(toolchains_root, DEFAULT_ZIG_GLOBS)
    ]
    rust_candidates = [
        describe_rust_candidate(EXPECTED_RUST_VERSION, path)
        for path in discover_candidates(toolchains_root, DEFAULT_RUST_GLOBS)
    ]

    preferred_zig = choose_preferred_zig(expected_zig, zig_candidates, toolchains_root)
    preferred_rust = choose_preferred_rust(EXPECTED_RUST_VERSION, rust_candidates, toolchains_root)
    readiness_command = build_readiness_command(repo_root, toolchains_root, preferred_zig, preferred_rust)

    failures: list[str] = []
    if preferred_zig is None:
        failures.append(
            f"no staged Zig candidate under {toolchains_root} matches the expected {parse_semver(expected_zig)[0]}.{parse_semver(expected_zig)[1]}.x line"
        )
    if preferred_rust is None:
        failures.append(
            f"no staged Rust candidate under {toolchains_root} matches the expected {parse_semver(EXPECTED_RUST_VERSION)[0]}.{parse_semver(EXPECTED_RUST_VERSION)[1]}.x line"
        )

    suggested_next_step = None
    if failures:
        suggested_next_step = (
            "restore the missing staged toolchain under ../toolchains, then rerun this helper before trusting Linux build-readiness output"
        )

    return {
        "status": "passed" if not failures else "failed",
        "repo_root": repo_root,
        "toolchains_root": toolchains_root,
        "expected_zig": expected_zig,
        "expected_rust": EXPECTED_RUST_VERSION,
        "preferred_zig": preferred_zig,
        "preferred_rust": preferred_rust,
        "zig_candidates": zig_candidates,
        "rust_candidates": rust_candidates,
        "readiness_command": format_command(readiness_command),
        "failures": failures,
        "suggested_next_step": suggested_next_step,
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
        description="Surface the preferred staged Rust+Zig handoff for Linux build-readiness reruns."
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


class ToolchainHandoffTests(unittest.TestCase):
    def make_zig(self, root: Path, name: str, version: str, *, nested_bin: bool = False) -> Path:
        zig_bin = root / name / ("bin/zig" if nested_bin else "zig")
        zig_bin.parent.mkdir(parents=True, exist_ok=True)
        zig_bin.write_text(f"#!/usr/bin/env bash\necho {version}\n", encoding="utf-8")
        os.chmod(zig_bin, 0o755)
        return zig_bin

    def make_rust(self, root: Path, name: str, cargo_version: str, rustc_version: str | None) -> Path:
        cargo_bin = root / name / "cargo" / "bin" / "cargo"
        cargo_bin.parent.mkdir(parents=True, exist_ok=True)
        cargo_bin.write_text(f"#!/usr/bin/env bash\necho cargo {cargo_version}\n", encoding="utf-8")
        os.chmod(cargo_bin, 0o755)
        if rustc_version is not None:
            rustc_bin = root / name / "rustc" / "bin" / "rustc"
            rustc_bin.parent.mkdir(parents=True, exist_ok=True)
            rustc_bin.write_text(f"#!/usr/bin/env bash\necho rustc {rustc_version}\n", encoding="utf-8")
            os.chmod(rustc_bin, 0o755)
        return cargo_bin

    def make_repo(self, root: Path, minimum_zig: str = "0.15.2") -> Path:
        repo_root = root / "browser"
        repo_root.mkdir()
        (repo_root / "scripts").mkdir()
        (repo_root / "scripts" / "check_linux_build_readiness.py").write_text("# stub\n", encoding="utf-8")
        (repo_root / "build.zig.zon").write_text(
            f'.{{ .minimum_zig_version = "{minimum_zig}" }}\n',
            encoding="utf-8",
        )
        return repo_root

    def test_collect_results_prefers_matching_candidates(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = self.make_repo(root)
            toolchains_root = root / "toolchains"
            self.make_zig(toolchains_root, "zig-0.15.7", "0.15.7")
            self.make_zig(toolchains_root, "zig-0.17.0", "0.17.0-dev.299+a76ce7710", nested_bin=True)
            self.make_rust(toolchains_root, "rust-1.79.4", "1.79.4", "1.79.4")
            self.make_rust(toolchains_root, "rust-1.80.1", "1.80.1", "1.80.1")

            result = collect_results(repo_root, toolchains_root)

            self.assertEqual(result["status"], "passed")
            assert result["preferred_zig"] is not None
            assert result["preferred_rust"] is not None
            self.assertEqual(result["preferred_zig"]["version"], "0.15.7")
            self.assertEqual(result["preferred_rust"]["cargo_version"], "1.79.4")
            self.assertIn("--zig", result["readiness_command"])
            self.assertIn("--cargo", result["readiness_command"])
            self.assertIn("--rustc", result["readiness_command"])

    def test_collect_results_fails_when_matching_candidates_are_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = self.make_repo(root)
            toolchains_root = root / "toolchains"
            self.make_zig(toolchains_root, "zig-0.17.0", "0.17.0-dev.299+a76ce7710")
            self.make_rust(toolchains_root, "rust-1.80.1", "1.80.1", "1.80.1")

            result = collect_results(repo_root, toolchains_root)

            self.assertEqual(result["status"], "failed")
            self.assertEqual(len(result["failures"]), 2)
            self.assertIsNotNone(result["suggested_next_step"])

    def test_resolve_default_toolchains_root_discovers_ancestor_workspace(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = Path(tmpdir)
            repo_root = workspace_root / "restored" / "browser-memory-snapshot" / "browser"
            repo_root.mkdir(parents=True)
            toolchains_root = workspace_root / "toolchains"
            toolchains_root.mkdir()

            self.assertEqual(resolve_default_toolchains_root(repo_root), toolchains_root.resolve())


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ToolchainHandoffTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    toolchains_root = Path(args.toolchains_root).resolve() if args.toolchains_root else resolve_default_toolchains_root(repo_root)
    results = collect_results(repo_root, toolchains_root)

    if args.json:
        print(json.dumps(serialize(results), indent=2))
        return 0 if results["status"] == "passed" else 1

    print("Linux build-readiness toolchain handoff")
    print()
    print(f"Repo root:         {repo_root}")
    print(f"Toolchains root:   {toolchains_root}")
    print(f"Expected Zig:      {results['expected_zig']}")
    print(f"Expected Rust:     {results['expected_rust']}")
    print()

    print("Discovered Zig candidates:")
    if results["zig_candidates"]:
        for candidate in results["zig_candidates"]:
            print(
                f"  - {candidate['zig_bin']} [{candidate['version'] or 'unknown'}; {candidate['status']}]"
            )
            for failure in candidate["failures"]:
                print(f"    note: {failure}")
    else:
        print("  none")

    print()
    print("Discovered Rust candidates:")
    if results["rust_candidates"]:
        for candidate in results["rust_candidates"]:
            print(
                "  - "
                f"{candidate['toolchain_root']} "
                f"[cargo={candidate['cargo_version'] or 'unknown'}, "
                f"rustc={candidate['rustc_version'] or 'unknown'}; "
                f"{candidate['status']}]"
            )
            for failure in candidate["failures"]:
                print(f"    note: {failure}")
    else:
        print("  none")

    preferred_zig = results["preferred_zig"]
    preferred_rust = results["preferred_rust"]
    if preferred_zig is not None or preferred_rust is not None:
        print()
        print("Preferred handoff:")
        if preferred_zig is not None:
            print(f"  {preferred_zig['zig_export']}")
        if preferred_rust is not None:
            print(f"  {preferred_rust['path_export']}")
            print(f"  {preferred_rust['cargo_export']}")
            print(f"  {preferred_rust['rustc_export']}")
        print(f"  {results['readiness_command']}")

    if results["failures"]:
        print()
        print("Toolchain handoff check failed:", file=sys.stderr)
        for failure in results["failures"]:
            print(f"  - {failure}", file=sys.stderr)
        if results["suggested_next_step"] is not None:
            print(f"Suggested next step: {results['suggested_next_step']}", file=sys.stderr)
        return 1

    print()
    print("Toolchain handoff check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
