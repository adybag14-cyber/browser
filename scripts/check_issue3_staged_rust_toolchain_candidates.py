#!/usr/bin/env python3

"""Surface staged Rust toolchain candidates for issue #3 Linux/WSL re-entry."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest


EXPECTED_RUST_VERSION = "1.79.0"
EXPECTED_RUST_LINE = "1.79.x"
EXPECTED_TOOLCHAIN_DIR = "rust-1.79.0"
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
    return tuple(int(part) for part in match.groups())


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


def version_status(version: str | None) -> str:
    classification = classify_version(version)
    if classification == "unknown-version":
        return "unknown version"
    if classification == "older-than-expected":
        return "older-than-expected"
    if classification == "matches-expected-line":
        return f"matches expected {EXPECTED_RUST_LINE}"
    return f"mismatched: expected {EXPECTED_RUST_LINE}"


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
    cargo_classification = classify_version(cargo_version)
    rustc_classification = classify_version(rustc_version)

    status = version_status(cargo_version)
    if cargo_classification == "matches-expected-line" and rustc_version is None:
        status = f"cargo matches expected {EXPECTED_RUST_LINE} but rustc is unavailable"
    elif cargo_classification == "matches-expected-line" and rustc_classification == "matches-expected-line":
        status = f"matches expected {EXPECTED_RUST_LINE}"
    elif cargo_classification == "matches-expected-line" and rustc_classification == "older-than-expected":
        status = f"older rustc: expected {EXPECTED_RUST_LINE}"
    elif cargo_classification == "matches-expected-line" and rustc_classification == "mismatched-line":
        status = f"mismatched rustc: expected {EXPECTED_RUST_LINE}"

    toolchain_root = cargo_bin.parent.parent.parent
    return {
        "toolchain_root": toolchain_root,
        "cargo_bin": cargo_bin,
        "rustc_bin": rustc_bin,
        "cargo_output": cargo_output,
        "rustc_output": rustc_output,
        "cargo_version": cargo_version,
        "rustc_version": rustc_version,
        "cargo_classification": cargo_classification,
        "rustc_classification": rustc_classification,
        "status": status,
        "failures": cargo_failures + rustc_failures,
        "path_export": f'export PATH="{toolchain_root / "cargo" / "bin"}:{toolchain_root / "rustc" / "bin"}:$PATH"',
        "cargo_export": f'export CARGO="{cargo_bin}"',
        "rustc_export": f'export RUSTC="{rustc_bin}"',
    }


def choose_preferred_candidate(
    candidates: list[dict[str, object]],
    expected_dir: Path,
) -> dict[str, object] | None:
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


def collect_results(repo_root: Path, toolchains_root: Path) -> dict[str, object]:
    candidates = [describe_candidate(path) for path in discover_candidates(toolchains_root)]
    expected_dir = toolchains_root / EXPECTED_TOOLCHAIN_DIR
    preferred = choose_preferred_candidate(candidates, expected_dir)

    suggested_next_step = None
    if preferred is None:
        suggested_next_step = (
            f"restore a saved Rust {EXPECTED_RUST_LINE} toolchain under ../toolchains and rerun this helper before trusting Linux build-readiness output"
        )
    elif Path(str(preferred["toolchain_root"])).resolve() != expected_dir.resolve():
        suggested_next_step = (
            f"prefer {expected_dir} as the stable restore location, or reuse the surfaced exports from {preferred['toolchain_root']}"
        )

    return {
        "status": "passed" if preferred is not None else "failed",
        "repo_root": repo_root,
        "toolchains_root": toolchains_root,
        "expected_rust_version": EXPECTED_RUST_VERSION,
        "expected_rust_line": EXPECTED_RUST_LINE,
        "expected_toolchain_dir": expected_dir,
        "candidate_count": len(candidates),
        "preferred_candidate": preferred,
        "candidates": candidates,
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
        description="Discover staged Rust toolchain candidates for issue #3 Linux/WSL build re-entry."
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


class StagedRustToolchainCandidateTests(unittest.TestCase):
    def make_toolchain(self, root: Path, name: str, cargo_version: str, rustc_version: str | None) -> Path:
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

    def test_discover_candidates_finds_cargo_bins(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            toolchains_root = Path(tmpdir)
            first = self.make_toolchain(toolchains_root, "rust-1.79.0", "1.79.0", "1.79.0")
            self.make_toolchain(toolchains_root, "rust-1.80.1", "1.80.1", "1.80.1")

            candidates = discover_candidates(toolchains_root)

            self.assertIn(first.resolve(), candidates)
            self.assertEqual(len(candidates), 2)

    def test_collect_results_prefers_matching_saved_rust_toolchain(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            toolchains_root = repo_root.parent / "toolchains"
            self.make_toolchain(toolchains_root, "rust-1.79.0", "1.79.0", "1.79.0")
            self.make_toolchain(toolchains_root, "rust-1.80.1", "1.80.1", "1.80.1")

            result = collect_results(repo_root, toolchains_root)

            self.assertEqual(result["status"], "passed")
            preferred = result["preferred_candidate"]
            self.assertIsNotNone(preferred)
            self.assertEqual(preferred["cargo_version"], "1.79.0")
            self.assertEqual(preferred["rustc_version"], "1.79.0")

    def test_collect_results_accepts_matching_patch_line_candidate(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            toolchains_root = repo_root.parent / "toolchains"
            self.make_toolchain(toolchains_root, "rust-1.79.4", "1.79.4", "1.79.4")

            result = collect_results(repo_root, toolchains_root)

            self.assertEqual(result["status"], "passed")
            preferred = result["preferred_candidate"]
            self.assertIsNotNone(preferred)
            self.assertEqual(preferred["cargo_version"], "1.79.4")
            self.assertEqual(preferred["rustc_version"], "1.79.4")
            self.assertIn("matches expected 1.79.x", preferred["status"])

    def test_collect_results_fails_without_matching_candidate(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            toolchains_root = repo_root.parent / "toolchains"
            self.make_toolchain(toolchains_root, "rust-1.80.1", "1.80.1", "1.80.1")

            result = collect_results(repo_root, toolchains_root)

            self.assertEqual(result["status"], "failed")
            self.assertIsNone(result["preferred_candidate"])
            self.assertIn("restore a saved Rust 1.79.x toolchain", result["suggested_next_step"])

    def test_describe_candidate_reports_missing_rustc(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            toolchains_root = Path(tmpdir)
            cargo_bin = self.make_toolchain(toolchains_root, "rust-1.79.0", "1.79.0", None)

            candidate = describe_candidate(cargo_bin)

            self.assertIn("missing rustc beside cargo", candidate["failures"][0])
            self.assertIn("rustc is unavailable", candidate["status"])

    def test_default_toolchains_root_discovers_ancestor_workspace_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = Path(tmpdir)
            repo_root = workspace_root / "restored" / "browser-memory-snapshot" / "browser"
            repo_root.mkdir(parents=True)
            toolchains_root = workspace_root / "toolchains"
            toolchains_root.mkdir()

            self.assertEqual(resolve_default_toolchains_root(repo_root), toolchains_root.resolve())


if __name__ == "__main__":
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(StagedRustToolchainCandidateTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        sys.exit(0 if result.wasSuccessful() else 1)

    repo_root = Path(args.repo_root).resolve()
    toolchains_root = Path(args.toolchains_root).resolve() if args.toolchains_root else resolve_default_toolchains_root(repo_root)
    results = collect_results(repo_root, toolchains_root)

    if args.json:
        print(json.dumps(serialize(results), indent=2))
        sys.exit(0 if results["status"] == "passed" else 1)

    print(f"Repo root: {repo_root}")
    print(f"Toolchains root: {toolchains_root}")
    print(f"Expected Rust version: {EXPECTED_RUST_VERSION}")
    print(f"Expected Rust line: {EXPECTED_RUST_LINE}")
    if not results["candidates"]:
        print("Discovered candidates: none")
    else:
        print("Discovered candidates:")
        for candidate in results["candidates"]:
            print(
                "  - "
                f"{candidate['toolchain_root']} "
                f"[cargo={candidate['cargo_version'] or 'unknown'}, "
                f"rustc={candidate['rustc_version'] or 'unknown'}; "
                f"{candidate['status']}]"
            )
            for failure in candidate["failures"]:
                print(f"    note: {failure}")

    preferred = results["preferred_candidate"]
    if preferred is not None:
        print("\nPreferred candidate:")
        print(f"  toolchain: {preferred['toolchain_root']}")
        print(f"  {preferred['path_export']}")
        print(f"  {preferred['cargo_export']}")
        print(f"  {preferred['rustc_export']}")
        sys.exit(0)

    print("\nNo staged Rust 1.79.x candidate is ready.", file=sys.stderr)
    if results["suggested_next_step"] is not None:
        print(f"Suggested next step: {results['suggested_next_step']}", file=sys.stderr)
    sys.exit(1)
