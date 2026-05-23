#!/usr/bin/env python3

"""Validate a restored saved Rust toolchain tree for issue #3 Linux recovery."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import os
import re
import subprocess
import sys
import tempfile
import unittest


DEFAULT_TOOLCHAIN_DIR_NAME = "rust-1.79.0"
DEFAULT_EXPECTED_VERSION = "1.79.0"
SEMVER_RE = re.compile(r"(\d+\.\d+\.\d+)")


def resolve_default_toolchain_root(repo_root: Path) -> Path:
    return (repo_root.parent / "toolchains" / DEFAULT_TOOLCHAIN_DIR_NAME).resolve()


def resolve_tool_paths(toolchain_root: Path) -> dict[str, Path]:
    return {
        "cargo": toolchain_root / "cargo" / "bin" / "cargo",
        "rustc": toolchain_root / "rustc" / "bin" / "rustc",
        "rustdoc": toolchain_root / "rust-docs" / "bin" / "rustdoc",
    }


def parse_version(text: str) -> str | None:
    match = SEMVER_RE.search(text)
    if match is None:
        return None
    return match.group(1)


def run_version(path: Path, label: str) -> tuple[list[str], str | None, str | None]:
    if not path.exists():
        return [f"{label} does not exist: {path}"], None, None
    if not path.is_file():
        return [f"{label} is not a file: {path}"], None, None
    if not os.access(path, os.X_OK):
        return [f"{label} is not executable: {path}"], None, None

    try:
        completed = subprocess.run(
            [str(path), "--version"],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as exc:
        return [f"{label} version probe failed with exit code {exc.returncode}: {path}"], None, None

    output = completed.stdout.strip() or completed.stderr.strip()
    version = parse_version(output)
    if version is None:
        return [f"{label} version output did not include a semantic version: {output!r}"], output, None
    return [], output, version


def collect_report(repo_root: Path, toolchain_root: Path, expected_version: str) -> dict[str, object]:
    tool_paths = resolve_tool_paths(toolchain_root)
    failures: list[str] = []
    warnings: list[str] = []

    cargo_failures, cargo_output, cargo_version = run_version(tool_paths["cargo"], "cargo")
    rustc_failures, rustc_output, rustc_version = run_version(tool_paths["rustc"], "rustc")
    failures.extend(cargo_failures)
    failures.extend(rustc_failures)

    rustdoc_failures, rustdoc_output, rustdoc_version = run_version(tool_paths["rustdoc"], "rustdoc")
    if rustdoc_failures:
        warnings.extend(rustdoc_failures)

    if cargo_version is not None and cargo_version != expected_version:
        failures.append(
            f"cargo version {cargo_version} does not match expected saved Rust version {expected_version}"
        )
    if rustc_version is not None and rustc_version != expected_version:
        failures.append(
            f"rustc version {rustc_version} does not match expected saved Rust version {expected_version}"
        )

    export_path_parts = [
        str(toolchain_root / "cargo" / "bin"),
        str(toolchain_root / "rustc" / "bin"),
    ]
    if tool_paths["rustdoc"].exists() and os.access(tool_paths["rustdoc"], os.X_OK):
        export_path_parts.append(str(toolchain_root / "rust-docs" / "bin"))

    return {
        "ok": not failures,
        "repo_root": str(repo_root),
        "toolchain_root": str(toolchain_root),
        "expected_version": expected_version,
        "cargo_bin": str(tool_paths["cargo"]),
        "rustc_bin": str(tool_paths["rustc"]),
        "rustdoc_bin": str(tool_paths["rustdoc"]),
        "cargo_version_output": cargo_output,
        "cargo_version": cargo_version,
        "rustc_version_output": rustc_output,
        "rustc_version": rustc_version,
        "rustdoc_version_output": rustdoc_output,
        "rustdoc_version": rustdoc_version,
        "export_path": ":".join(export_path_parts),
        "failures": failures,
        "warnings": warnings,
    }


def emit_text(report: dict[str, object]) -> None:
    print(f"Repo root: {report['repo_root']}")
    print(f"Toolchain root: {report['toolchain_root']}")
    print(f"Expected saved Rust version: {report['expected_version']}")
    if report["cargo_version_output"] is not None:
        print(f"cargo: {report['cargo_version_output']}")
    if report["rustc_version_output"] is not None:
        print(f"rustc: {report['rustc_version_output']}")
    if report["rustdoc_version_output"] is not None:
        print(f"rustdoc: {report['rustdoc_version_output']}")
    print("Suggested shell setup:")
    print(f"  export PATH='{report['export_path']}:$PATH'")
    print(f"  export CARGO='{report['cargo_bin']}'")
    print(f"  export RUSTC='{report['rustc_bin']}'")
    if report["warnings"]:
        print("Warnings:")
        for warning in report["warnings"]:
            print(f"  - {warning}")
    if report["failures"]:
        print("Failures:", file=sys.stderr)
        for failure in report["failures"]:
            print(f"  - {failure}", file=sys.stderr)
    else:
        print("\nSaved Rust toolchain check passed.")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the restored saved Rust toolchain tree is present, executable, "
            "and on the expected 1.79.0 line before Linux or WSL build-readiness work."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--toolchain-root",
        default=None,
        help="Path to the restored Rust toolchain root (default: ../toolchains/rust-1.79.0 beside the repo)",
    )
    parser.add_argument(
        "--expected-version",
        default=DEFAULT_EXPECTED_VERSION,
        help="Expected semantic version for cargo and rustc (default: 1.79.0)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


class SavedRustToolchainTests(unittest.TestCase):
    def make_fake_binary(self, path: Path, version_output: str) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f"#!/usr/bin/env bash\necho '{version_output}'\n", encoding="utf-8")
        os.chmod(path, 0o755)

    def test_default_toolchain_root_follows_workspace_layout(self) -> None:
        repo_root = Path("/tmp/workspace/browser")
        self.assertEqual(
            resolve_default_toolchain_root(repo_root),
            Path("/tmp/workspace/toolchains/rust-1.79.0"),
        )

    def test_collect_report_passes_for_expected_versions(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            toolchain_root = root / "toolchains" / "rust-1.79.0"
            repo_root.mkdir()
            self.make_fake_binary(toolchain_root / "cargo/bin/cargo", "cargo 1.79.0 (abc123)")
            self.make_fake_binary(toolchain_root / "rustc/bin/rustc", "rustc 1.79.0 (def456)")
            self.make_fake_binary(toolchain_root / "rust-docs/bin/rustdoc", "rustdoc 1.79.0 (ghi789)")

            report = collect_report(repo_root, toolchain_root, "1.79.0")

            self.assertTrue(report["ok"])
            self.assertEqual(report["failures"], [])
            self.assertEqual(report["warnings"], [])

    def test_collect_report_fails_when_rustc_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            toolchain_root = root / "toolchains" / "rust-1.79.0"
            repo_root.mkdir()
            self.make_fake_binary(toolchain_root / "cargo/bin/cargo", "cargo 1.79.0 (abc123)")

            report = collect_report(repo_root, toolchain_root, "1.79.0")

            self.assertFalse(report["ok"])
            self.assertIn("rustc does not exist", report["failures"][0])

    def test_collect_report_fails_when_versions_do_not_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            toolchain_root = root / "toolchains" / "rust-1.79.0"
            repo_root.mkdir()
            self.make_fake_binary(toolchain_root / "cargo/bin/cargo", "cargo 1.80.0 (abc123)")
            self.make_fake_binary(toolchain_root / "rustc/bin/rustc", "rustc 1.80.0 (def456)")

            report = collect_report(repo_root, toolchain_root, "1.79.0")

            self.assertFalse(report["ok"])
            self.assertEqual(len(report["failures"]), 2)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedRustToolchainTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    toolchain_root = Path(args.toolchain_root).resolve() if args.toolchain_root else resolve_default_toolchain_root(repo_root)
    report = collect_report(repo_root, toolchain_root, args.expected_version)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
