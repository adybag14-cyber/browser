#!/usr/bin/env python3

"""Audit known Zig 0.17 port blockers in the browser tree and sibling deps.

This helper is meant to run before a Linux/WSL `zig build` or focused `zig test`
retry when only the saved Zig 0.17 fallback is available. It checks a short
list of known compatibility patterns that have already blocked headed-mode
validation for this fork, including sibling dependency build scripts.
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
import tempfile
import unittest
from dataclasses import dataclass


@dataclass(frozen=True)
class BlockerCheck:
    label: str
    relative_path: str
    pattern: str
    guidance: str
    dependency_root: bool = False


KNOWN_BLOCKER_CHECKS = (
    BlockerCheck(
        label="legacy Config ArgIterator helper signatures",
        relative_path="src/Config.zig",
        pattern=r"std\.process\.ArgIterator",
        guidance="update helper signatures to std.process.Args.Iterator for Zig 0.17",
    ),
    BlockerCheck(
        label="Windows-only @cImport still parsed by hosted builds",
        relative_path="src/display/win32_backend.zig",
        pattern=r"@cImport\(",
        guidance="gate or translate the Win32 import before relying on Linux-hosted Zig 0.17 validation",
    ),
    BlockerCheck(
        label="bare-metal backend still uses a Windows-only @cImport surface",
        relative_path="src/display/baremetal_backend.zig",
        pattern=r"@cImport\(",
        guidance="stub or translate this import before retrying hosted Linux Zig 0.17 validation",
    ),
    BlockerCheck(
        label="shared renderer still uses a Windows-only @cImport surface",
        relative_path="src/render/DocumentPainter.zig",
        pattern=r"@cImport\(",
        guidance="replace or gate this shared import before retrying the Zig 0.17 build",
    ),
    BlockerCheck(
        label="canvas surface still uses a Windows-only @cImport surface",
        relative_path="src/browser/webapi/canvas/CanvasSurface.zig",
        pattern=r"@cImport\(",
        guidance="replace or gate this shared import before retrying the Zig 0.17 build",
    ),
    BlockerCheck(
        label="HTML image surface still uses a Windows-only @cImport surface",
        relative_path="src/browser/webapi/element/html/Image.zig",
        pattern=r"@cImport\(",
        guidance="replace or gate this shared import before retrying the Zig 0.17 build",
    ),
    BlockerCheck(
        label="curl bindings still rely on a direct @cImport surface",
        relative_path="src/sys/libcurl.zig",
        pattern=r"@cImport\(",
        guidance="translate the libcurl bindings or avoid parsing this path during Zig 0.17 validation",
    ),
    BlockerCheck(
        label="legacy repeat-expression spacing in the Win32 backend",
        relative_path="src/display/win32_backend.zig",
        pattern=r"\[_\][^\n=]*\{[^\n}]*\}\s+\*\*",
        guidance="normalize the repeat expression formatting before using Zig 0.17 to probe this file",
    ),
    BlockerCheck(
        label="zig-v8-fork still uses std.fs.cwd() in its build script",
        relative_path="zig-v8-fork/build.zig",
        pattern=r"std\.fs\.cwd\(",
        guidance="port the dependency build script to std.Io.Dir-style filesystem access before retrying Zig 0.17",
        dependency_root=True,
    ),
    BlockerCheck(
        label="boringssl-zig still uses the older addStaticLibrary build API",
        relative_path="boringssl-zig/build.zig",
        pattern=r"\.addStaticLibrary\(",
        guidance="port the dependency build script to the Zig 0.17 Build API before retrying Zig 0.17",
        dependency_root=True,
    ),
)


def resolve_check_path(
    repo_root: pathlib.Path,
    sibling_root: pathlib.Path,
    check: BlockerCheck,
) -> pathlib.Path:
    if check.dependency_root:
        return sibling_root / check.relative_path
    return repo_root / check.relative_path


def scan_file(path: pathlib.Path, pattern: str) -> list[int]:
    if not path.is_file():
        return []
    matcher = re.compile(pattern)
    hits: list[int] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if matcher.search(line):
            hits.append(line_number)
    return hits


def collect_blockers(
    repo_root: pathlib.Path,
    sibling_root: pathlib.Path,
    checks: tuple[BlockerCheck, ...] = KNOWN_BLOCKER_CHECKS,
) -> tuple[list[str], list[str]]:
    findings: list[str] = []
    warnings: list[str] = []

    for check in checks:
        path = resolve_check_path(repo_root, sibling_root, check)
        if not path.exists():
            warnings.append(f"skipped missing path for {check.label}: {path}")
            continue

        hit_lines = scan_file(path, check.pattern)
        if not hit_lines:
            continue

        joined_lines = ", ".join(str(line) for line in hit_lines[:5])
        extra = "" if len(hit_lines) <= 5 else f" (+{len(hit_lines) - 5} more)"
        findings.append(
            f"{check.label}: {path} [lines {joined_lines}{extra}] -> {check.guidance}"
        )

    return findings, warnings


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Audit the known Zig 0.17 blocker patterns before a browser build retry."
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--sibling-root",
        default=None,
        help="Directory that contains the browser checkout and sibling deps (default: repo parent)",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused unit tests and exit",
    )
    return parser


class Zig017BlockerTests(unittest.TestCase):
    def test_collects_repo_and_dependency_blockers(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            sibling_root = root

            config = repo_root / "src" / "Config.zig"
            config.parent.mkdir(parents=True)
            config.write_text("args: *std.process.ArgIterator,\n", encoding="utf-8")

            v8_build = sibling_root / "zig-v8-fork" / "build.zig"
            v8_build.parent.mkdir(parents=True)
            v8_build.write_text("const cwd = std.fs.cwd();\n", encoding="utf-8")

            findings, warnings = collect_blockers(
                repo_root,
                sibling_root,
                checks=(
                    KNOWN_BLOCKER_CHECKS[0],
                    KNOWN_BLOCKER_CHECKS[8],
                ),
            )

            self.assertEqual(len(findings), 2)
            self.assertEqual(warnings, [])
            self.assertIn("Config.zig", findings[0])
            self.assertIn("zig-v8-fork/build.zig", findings[1])

    def test_missing_paths_become_warnings(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()

            findings, warnings = collect_blockers(
                repo_root,
                root,
                checks=(KNOWN_BLOCKER_CHECKS[9],),
            )

            self.assertEqual(findings, [])
            self.assertEqual(len(warnings), 1)
            self.assertIn("boringssl-zig", warnings[0])

    def test_repeat_spacing_pattern_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()

            win32_backend = repo_root / "src" / "display" / "win32_backend.zig"
            win32_backend.parent.mkdir(parents=True)
            win32_backend.write_text(
                "var wide_path: [c.MAX_PATH + 1]u16 = [_]u16{0} ** (c.MAX_PATH + 1);\n",
                encoding="utf-8",
            )

            findings, warnings = collect_blockers(
                repo_root,
                root,
                checks=(KNOWN_BLOCKER_CHECKS[7],),
            )

            self.assertEqual(len(findings), 1)
            self.assertEqual(warnings, [])
            self.assertIn("repeat expression formatting", findings[0])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(Zig017BlockerTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    sibling_root = pathlib.Path(args.sibling_root).resolve() if args.sibling_root else repo_root.parent

    if not (repo_root / "build.zig.zon").is_file():
        print(f"ERROR: {repo_root / 'build.zig.zon'} not found", file=sys.stderr)
        return 2

    findings, warnings = collect_blockers(repo_root, sibling_root)

    print(f"Repo root: {repo_root}")
    print(f"Sibling dependency root: {sibling_root}")
    print(f"Known blocker checks: {len(KNOWN_BLOCKER_CHECKS)}")

    if warnings:
        print("Warnings:")
        for warning in warnings:
            print(f"  - {warning}")

    if findings:
        print("Known Zig 0.17 blockers still present:")
        for finding in findings:
            print(f"  - {finding}")
        print(
            "\nSuggested next step: clear the listed blockers or switch back to a Zig 0.15.2 toolchain before retrying Linux/WSL validation.",
            file=sys.stderr,
        )
        return 1

    print("No known Zig 0.17 blocker patterns were found in the scanned paths.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
