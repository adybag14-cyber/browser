#!/usr/bin/env python3

"""Surface staged Zig toolchain candidates for issue #11 Linux/WSL re-entry."""

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


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"(\d+)\.(\d+)\.(\d+)")
DEFAULT_CANDIDATE_GLOBS = (
    "zig*/zig",
    "zig*/bin/zig",
    "*/zig",
    "*/bin/zig",
    "zig",
)


def parse_semver(text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.search(text)
    if match is None:
        raise ValueError(f"Could not parse semantic version from {text!r}")
    return tuple(int(part) for part in match.groups())


def classify_version(minimum_zig: str, actual: str | None) -> str:
    if actual is None:
        return "unknown version"

    actual_parts = parse_semver(actual)
    minimum_parts = parse_semver(minimum_zig)
    if actual_parts < minimum_parts:
        return "older-than-minimum"
    if actual_parts[:2] == minimum_parts[:2]:
        return "matches-expected-line"
    return "mismatched-line"


def resolve_default_toolchains_root(repo_root: Path) -> Path:
    return (repo_root.parent / "toolchains").resolve()


def load_minimum_zig(repo_root: Path) -> str:
    zon_path = repo_root / "build.zig.zon"
    text = zon_path.read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError(f"Could not find minimum_zig_version in {zon_path}")
    return match.group(1)


def discover_candidates(toolchains_root: Path) -> list[Path]:
    if not toolchains_root.is_dir():
        return []

    seen: set[Path] = set()
    candidates: list[Path] = []
    for pattern in DEFAULT_CANDIDATE_GLOBS:
        for zig_path in sorted(toolchains_root.glob(pattern)):
            if not zig_path.is_file():
                continue
            resolved = zig_path.resolve()
            if resolved in seen:
                continue
            seen.add(resolved)
            candidates.append(resolved)
    return candidates


def infer_toolchain_root(zig_bin: Path) -> Path:
    if zig_bin.parent.name == "bin":
        return zig_bin.parent.parent
    return zig_bin.parent


def run_version(binary: Path) -> tuple[list[str], str | None]:
    try:
        completed = subprocess.run(
            [str(binary), "version"],
            capture_output=True,
            check=True,
            text=True,
        )
    except FileNotFoundError:
        return [f"zig not found: {binary}"], None
    except subprocess.CalledProcessError as exc:
        return [f"zig version probe failed with exit code {exc.returncode}: {binary}"], None

    output = completed.stdout.strip() or completed.stderr.strip()
    return [], output or None


def describe_candidate(minimum_zig: str, zig_bin: Path) -> dict[str, object]:
    failures, version_output = run_version(zig_bin)
    version = None
    if version_output:
        try:
            version = SEMVER_RE.search(version_output).group(0)  # type: ignore[union-attr]
        except AttributeError:
            failures = failures + [f"could not parse Zig version output from {zig_bin}: {version_output}"]

    status = classify_version(minimum_zig, version)
    toolchain_root = infer_toolchain_root(zig_bin)
    return {
        "toolchain_root": toolchain_root,
        "zig_bin": zig_bin,
        "version_output": version_output,
        "version": version,
        "status": status,
        "failures": failures,
        "path_export": f'export PATH="{zig_bin.parent}:$PATH"',
        "zig_export": f'export ZIG="{zig_bin}"',
    }


def collect_results(repo_root: Path, toolchains_root: Path) -> dict[str, object]:
    minimum_zig = load_minimum_zig(repo_root)
    candidates = [describe_candidate(minimum_zig, path) for path in discover_candidates(toolchains_root)]

    matching_candidates = [
        candidate for candidate in candidates if candidate["status"] == "matches-expected-line" and candidate["version"]
    ]
    preferred = None
    exact_match = next(
        (
            candidate
            for candidate in matching_candidates
            if candidate["version"] == minimum_zig
        ),
        None,
    )
    if exact_match is not None:
        preferred = exact_match
    elif matching_candidates:
        preferred = max(matching_candidates, key=lambda item: parse_semver(str(item["version"])))

    suggested_next_step = None
    if preferred is None:
        suggested_next_step = (
            "restore a saved Zig 0.15.x archive under ../toolchains and rerun this helper before trusting Linux build-readiness output"
        )

    return {
        "status": "passed" if preferred is not None else "failed",
        "repo_root": repo_root,
        "toolchains_root": toolchains_root,
        "minimum_zig": minimum_zig,
        "candidate_count": len(candidates),
        "preferred_candidate": preferred,
        "matching_candidates": matching_candidates,
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
        description="Discover staged Zig toolchain candidates for issue #11 Linux/WSL build re-entry."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Path to the shared toolchains directory (default: ../toolchains beside the repo root)",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON output")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


class StagedZigToolchainCandidateTests(unittest.TestCase):
    def make_toolchain(self, root: Path, name: str, version: str, *, nested_bin: bool = False) -> Path:
        if nested_bin:
            zig_bin = root / name / "bin" / "zig"
        else:
            zig_bin = root / name / "zig"
        zig_bin.parent.mkdir(parents=True, exist_ok=True)
        zig_bin.write_text(f"#!/usr/bin/env bash\necho {version}\n", encoding="utf-8")
        os.chmod(zig_bin, 0o755)
        return zig_bin

    def test_discover_candidates_finds_zig_bins(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            toolchains_root = Path(tmpdir)
            first = self.make_toolchain(toolchains_root, "zig-linux-x86_64-0.15.2", "0.15.2")
            self.make_toolchain(toolchains_root, "zig-linux-x86_64-0.17.0-dev.299+a76ce7710", "0.17.0")

            candidates = discover_candidates(toolchains_root)

            self.assertIn(first.resolve(), candidates)
            self.assertEqual(len(candidates), 2)

    def test_collect_results_prefers_exact_minimum_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            (repo_root / "build.zig.zon").write_text('.minimum_zig_version = "0.15.2"\n', encoding="utf-8")
            toolchains_root = repo_root.parent / "toolchains"
            self.make_toolchain(toolchains_root, "zig-linux-x86_64-0.15.2", "0.15.2")
            self.make_toolchain(toolchains_root, "zig-linux-x86_64-0.15.7", "0.15.7")

            result = collect_results(repo_root, toolchains_root)

            self.assertEqual(result["status"], "passed")
            preferred = result["preferred_candidate"]
            self.assertIsNotNone(preferred)
            self.assertEqual(preferred["version"], "0.15.2")

    def test_collect_results_prefers_highest_matching_patch_when_exact_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            (repo_root / "build.zig.zon").write_text('.minimum_zig_version = "0.15.2"\n', encoding="utf-8")
            toolchains_root = repo_root.parent / "toolchains"
            self.make_toolchain(toolchains_root, "zig-linux-x86_64-0.15.3", "0.15.3")
            self.make_toolchain(toolchains_root, "zig-linux-x86_64-0.15.11", "0.15.11")

            result = collect_results(repo_root, toolchains_root)

            self.assertEqual(result["status"], "passed")
            preferred = result["preferred_candidate"]
            self.assertIsNotNone(preferred)
            self.assertEqual(preferred["version"], "0.15.11")

    def test_collect_results_fails_without_matching_candidate(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            (repo_root / "build.zig.zon").write_text('.minimum_zig_version = "0.15.2"\n', encoding="utf-8")
            toolchains_root = repo_root.parent / "toolchains"
            self.make_toolchain(toolchains_root, "zig-linux-x86_64-0.17.0", "0.17.0")

            result = collect_results(repo_root, toolchains_root)

            self.assertEqual(result["status"], "failed")
            self.assertIsNone(result["preferred_candidate"])
            self.assertIn("restore a saved Zig 0.15.x archive", result["suggested_next_step"])

    def test_infer_toolchain_root_handles_bin_layout(self) -> None:
        path = Path("/tmp/toolchains/zig-linux-x86_64-0.15.2/bin/zig")
        self.assertEqual(infer_toolchain_root(path), Path("/tmp/toolchains/zig-linux-x86_64-0.15.2"))


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(StagedZigToolchainCandidateTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    toolchains_root = Path(args.toolchains_root).resolve() if args.toolchains_root else resolve_default_toolchains_root(repo_root)
    results = collect_results(repo_root, toolchains_root)

    if args.json:
        print(json.dumps(serialize(results), indent=2))
        return 0 if results["status"] == "passed" else 1

    print(f"Repo root: {repo_root}")
    print(f"Toolchains root: {toolchains_root}")
    print(f"Minimum Zig version: {results['minimum_zig']}")
    if not results["candidates"]:
        print("Discovered candidates: none")
    else:
        print("Discovered candidates:")
        for candidate in results["candidates"]:
            print(
                "  - "
                f"{candidate['toolchain_root']} "
                f"[zig={candidate['version'] or 'unknown'}; {candidate['status']}]"
            )
            for failure in candidate["failures"]:
                print(f"    note: {failure}")

    preferred = results["preferred_candidate"]
    if preferred is not None:
        print("\nPreferred candidate:")
        print(f"  toolchain: {preferred['toolchain_root']}")
        print(f"  {preferred['path_export']}")
        print(f"  {preferred['zig_export']}")
        return 0

    print("\nNo staged Zig 0.15.x candidate is ready.", file=sys.stderr)
    if results["suggested_next_step"] is not None:
        print(f"Suggested next step: {results['suggested_next_step']}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())