#!/usr/bin/env python3

"""Check whether a Zig archive filename matches the branch's required Zig line."""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
import tempfile
import unittest


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)")
ARCHIVE_VERSION_RE = re.compile(r"(?<!\d)(\d+\.\d+\.\d+(?:-[A-Za-z0-9.+-]+)?)")


def parse_semver(version_text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.match(version_text)
    if not match:
        raise ValueError(f"Could not parse semantic version from {version_text!r}")
    return tuple(int(part) for part in match.groups())


def load_minimum_zig_version(repo_root: pathlib.Path) -> str:
    zon_path = repo_root / "build.zig.zon"
    text = zon_path.read_text(encoding="utf-8")
    match = MINIMUM_ZIG_RE.search(text)
    if match is None:
        raise ValueError(f"Could not find minimum_zig_version in {zon_path}")
    return match.group(1)


def extract_archive_version(path: pathlib.Path) -> str | None:
    filename = path.name
    for suffix in (".tar.xz", ".tar.gz", ".zip", ".xz", ".gz"):
        if filename.endswith(suffix):
            filename = filename[: -len(suffix)]
            break
    match = ARCHIVE_VERSION_RE.search(filename)
    return match.group(1) if match else None


def check_archive_compatibility(minimum_zig: str, archive_path: pathlib.Path) -> tuple[list[str], str | None]:
    failures: list[str] = []
    if not archive_path.exists():
        return [f"Zig archive path does not exist: {archive_path}"], None
    if not archive_path.is_file():
        return [f"Zig archive path is not a file: {archive_path}"], None

    detected_version = extract_archive_version(archive_path)
    if detected_version is None:
        failures.append(
            f"Could not infer a Zig version from archive name {archive_path.name!r}; expected a filename containing digits like 0.15.2"
        )
        return failures, None

    minimum_parts = parse_semver(minimum_zig)
    detected_parts = parse_semver(detected_version)

    if detected_parts < minimum_parts:
        failures.append(
            f"archive Zig {detected_version} is older than the branch minimum {minimum_zig}"
        )
    elif detected_parts[:2] != minimum_parts[:2]:
        failures.append(
            f"archive Zig {detected_version} does not match the branch's expected {minimum_parts[0]}.{minimum_parts[1]}.x line"
        )

    return failures, detected_version


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Check whether a Zig archive matches the browser branch's minimum Zig line."
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--zig-archive",
        required=False,
        help="Path to the Zig archive to inspect",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run the helper's focused unit tests and exit",
    )
    return parser


class ZigArchiveCompatTests(unittest.TestCase):
    def test_extracts_release_version_from_archive_name(self) -> None:
        version = extract_archive_version(pathlib.Path("zig-linux-x86_64-0.15.2.tar.xz"))
        self.assertEqual(version, "0.15.2")

    def test_extracts_dev_version_from_archive_name(self) -> None:
        version = extract_archive_version(
            pathlib.Path("zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz")
        )
        self.assertEqual(version, "0.17.0-dev.299+a76ce7710")

    def test_reports_mismatched_minor_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            archive_path = pathlib.Path(tmpdir) / "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
            archive_path.write_text("zig", encoding="utf-8")
            failures, detected = check_archive_compatibility("0.15.2", archive_path)

        self.assertEqual(detected, "0.17.0-dev.299+a76ce7710")
        self.assertEqual(
            failures,
            ["archive Zig 0.17.0-dev.299+a76ce7710 does not match the branch's expected 0.15.x line"],
        )

    def test_accepts_matching_release_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            archive_path = pathlib.Path(tmpdir) / "zig-linux-x86_64-0.15.2.tar.xz"
            archive_path.write_text("zig", encoding="utf-8")
            failures, detected = check_archive_compatibility("0.15.2", archive_path)

        self.assertEqual(detected, "0.15.2")
        self.assertEqual(failures, [])

    def test_reports_missing_archive(self) -> None:
        archive_path = pathlib.Path("/tmp/does-not-exist/zig-linux-x86_64-0.15.2.tar.xz")
        failures, detected = check_archive_compatibility("0.15.2", archive_path)

        self.assertIsNone(detected)
        self.assertEqual(failures, [f"Zig archive path does not exist: {archive_path}"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ZigArchiveCompatTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    if not args.zig_archive:
        print("ERROR: --zig-archive is required unless --self-test is used", file=sys.stderr)
        return 2

    repo_root = pathlib.Path(args.repo_root).resolve()
    zon_path = repo_root / "build.zig.zon"
    if not zon_path.is_file():
        print(f"ERROR: {zon_path} not found", file=sys.stderr)
        return 2

    minimum_zig = load_minimum_zig_version(repo_root)
    archive_path = pathlib.Path(args.zig_archive).resolve()
    failures, detected_version = check_archive_compatibility(minimum_zig, archive_path)

    print(f"Repo root: {repo_root}")
    print(f"Branch minimum Zig: {minimum_zig}")
    print(f"Archive path: {archive_path}")
    print(f"Archive version: {detected_version or 'unknown'}")

    if failures:
        print("\nCompatibility check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        print(
            "\nSuggested next step: stage a Zig 0.15.x archive before retrying Linux or WSL validation for this branch.",
            file=sys.stderr,
        )
        return 1

    print("\nCompatibility check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
