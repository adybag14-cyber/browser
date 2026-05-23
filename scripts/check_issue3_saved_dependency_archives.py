#!/usr/bin/env python3

"""Audit the saved dependency archives used by the issue #3 offline route.

This helper goes deeper than the basic Memory presence check. It confirms that
the saved dependency bundles still expose the nested members that the Linux/WSL
offline restore route expects before future runs spend time replaying restore
commands.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest
import zipfile


BROWSER_DEPS_ARCHIVE_NAME = "04-zig-browser-depo.tar.zip"
BORINGSSL_ARCHIVE_NAME = "03-boringssl-zig-main.zip"
HTML5EVER_ARCHIVE_NAME = "02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"

BROWSER_DEPS_REQUIRED_PATTERNS: tuple[tuple[str, str], ...] = (
    (r"^zig-v8-fork-.*\.tar\.gz$", "zig-v8-fork source tarball"),
    (r"^brotli-.*\.tar\.gz$", "brotli source tarball"),
    (r"^zlib-.*\.tar\.gz$", "zlib source tarball"),
    (r"^nghttp2-.*\.tar\.gz$", "nghttp2 source tarball"),
    (r"^curl-.*\.tar\.gz$", "curl source tarball"),
)

BROWSER_DEPS_OPTIONAL_PATTERNS: tuple[tuple[str, str], ...] = (
    (r"libc_v8_.*\.a$", "prebuilt V8 archive"),
)

BORINGSSL_REQUIRED_PATTERNS: tuple[tuple[str, str], ...] = (
    (r"^[^/]+/build\.zig$", "BoringSSL Zig build script"),
    (r"^[^/]+/README\.md$", "BoringSSL Zig README"),
)

HTML5EVER_REQUIRED_PATTERNS: tuple[tuple[str, str], ...] = (
    (r"^[^/]+/\.cargo/config\.toml$", "html5ever cargo config"),
    (r"^[^/]+/vendor/.+", "html5ever vendor payload"),
)


def resolve_dependencies_root(repo_root: Path) -> Path:
    return (repo_root.parent / "memory" / "repo_archives" / "browser" / "dependencies").resolve()


def compile_patterns(specs: tuple[tuple[str, str], ...]) -> tuple[tuple[re.Pattern[str], str], ...]:
    return tuple((re.compile(pattern), label) for pattern, label in specs)


def scan_zip_archive(
    archive_path: Path,
    required_specs: tuple[tuple[str, str], ...],
    optional_specs: tuple[tuple[str, str], ...] = (),
) -> dict[str, object]:
    report: dict[str, object] = {
        "path": str(archive_path),
        "exists": archive_path.is_file(),
        "readable": False,
        "entry_count": 0,
        "matched_required": {},
        "missing_required": [],
        "matched_optional": {},
        "errors": [],
    }
    if not report["exists"]:
        report["errors"].append("archive is missing")
        report["missing_required"] = [label for _pattern, label in required_specs]
        return report

    try:
        with zipfile.ZipFile(archive_path) as archive:
            names = archive.namelist()
            bad_member = archive.testzip()
            if bad_member is not None:
                raise zipfile.BadZipFile(f"CRC failure in {bad_member}")
    except (OSError, zipfile.BadZipFile) as exc:
        report["errors"].append(str(exc))
        report["missing_required"] = [label for _pattern, label in required_specs]
        return report

    report["readable"] = True
    report["entry_count"] = len(names)

    for pattern, label in compile_patterns(required_specs):
        matched = next((name for name in names if pattern.search(name)), None)
        if matched is None:
            report["missing_required"].append(label)
        else:
            report["matched_required"][label] = matched

    for pattern, label in compile_patterns(optional_specs):
        matched = next((name for name in names if pattern.search(name)), None)
        if matched is not None:
            report["matched_optional"][label] = matched

    return report


def build_report(
    dependencies_root: Path,
    *,
    browser_deps_archive: Path | None,
    boringssl_archive: Path | None,
    html5ever_archive: Path | None,
    require_html5ever: bool,
) -> dict[str, object]:
    browser_deps_path = browser_deps_archive or dependencies_root / BROWSER_DEPS_ARCHIVE_NAME
    boringssl_path = boringssl_archive or dependencies_root / BORINGSSL_ARCHIVE_NAME
    html5ever_path = html5ever_archive or dependencies_root / HTML5EVER_ARCHIVE_NAME

    browser_deps = scan_zip_archive(
        browser_deps_path,
        BROWSER_DEPS_REQUIRED_PATTERNS,
        BROWSER_DEPS_OPTIONAL_PATTERNS,
    )
    boringssl = scan_zip_archive(
        boringssl_path,
        BORINGSSL_REQUIRED_PATTERNS,
    )
    html5ever = scan_zip_archive(
        html5ever_path,
        HTML5EVER_REQUIRED_PATTERNS,
    )

    failures: list[str] = []
    if not browser_deps["exists"]:
        failures.append(f"missing browser dependency archive: {browser_deps_path}")
    elif not browser_deps["readable"]:
        failures.append(f"unreadable browser dependency archive: {browser_deps_path}")
    elif browser_deps["missing_required"]:
        failures.append(
            "browser dependency archive is missing required members: "
            + ", ".join(browser_deps["missing_required"])
        )

    if not boringssl["exists"]:
        failures.append(f"missing BoringSSL archive: {boringssl_path}")
    elif not boringssl["readable"]:
        failures.append(f"unreadable BoringSSL archive: {boringssl_path}")
    elif boringssl["missing_required"]:
        failures.append(
            "BoringSSL archive is missing required members: "
            + ", ".join(boringssl["missing_required"])
        )

    html5ever_warnings: list[str] = []
    if not html5ever["exists"]:
        message = f"missing html5ever archive: {html5ever_path}"
        if require_html5ever:
            failures.append(message)
        else:
            html5ever_warnings.append(message)
    elif not html5ever["readable"]:
        message = f"unreadable html5ever archive: {html5ever_path}"
        if require_html5ever:
            failures.append(message)
        else:
            html5ever_warnings.append(message)
    elif html5ever["missing_required"]:
        message = (
            "html5ever archive is missing required members: "
            + ", ".join(html5ever["missing_required"])
        )
        if require_html5ever:
            failures.append(message)
        else:
            html5ever_warnings.append(message)

    return {
        "ok": not failures,
        "dependencies_root": str(dependencies_root),
        "require_html5ever": require_html5ever,
        "archives": {
            "browser_deps": browser_deps,
            "boringssl": boringssl,
            "html5ever": html5ever,
        },
        "failures": failures,
        "warnings": html5ever_warnings,
    }


def emit_text(report: dict[str, object]) -> None:
    print(f"Dependencies root: {report['dependencies_root']}")
    for key in ("browser_deps", "boringssl", "html5ever"):
        archive = report["archives"][key]
        print(f"{key}:")
        print(f"  path: {archive['path']}")
        print(f"  exists: {'yes' if archive['exists'] else 'no'}")
        print(f"  readable: {'yes' if archive['readable'] else 'no'}")
        if archive["readable"]:
            print(f"  entry_count: {archive['entry_count']}")
        for label, member in archive["matched_required"].items():
            print(f"  matched_required: {label} -> {member}")
        for label, member in archive["matched_optional"].items():
            print(f"  matched_optional: {label} -> {member}")
        for label in archive["missing_required"]:
            print(f"  missing_required: {label}")
        for error in archive["errors"]:
            print(f"  error: {error}")

    for warning in report["warnings"]:
        print(f"warning: {warning}")

    if report["ok"]:
        print("ISSUE3_SAVED_DEPENDENCY_ARCHIVES=pass")
    else:
        print("ISSUE3_SAVED_DEPENDENCY_ARCHIVES=fail", file=sys.stderr)
        for failure in report["failures"]:
            print(f"failure: {failure}", file=sys.stderr)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the saved dependency archives still contain the nested "
            "inputs expected by the issue #3 offline build-readiness route."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser repo root (default: current directory)",
    )
    parser.add_argument(
        "--dependencies-root",
        default=None,
        help="Override the saved dependency archive root",
    )
    parser.add_argument(
        "--browser-deps-archive",
        default=None,
        help="Override the browser dependency archive path",
    )
    parser.add_argument(
        "--boringssl-archive",
        default=None,
        help="Override the BoringSSL archive path",
    )
    parser.add_argument(
        "--html5ever-archive",
        default=None,
        help="Override the html5ever archive path",
    )
    parser.add_argument(
        "--require-html5ever",
        action="store_true",
        help="Treat a missing or incomplete html5ever archive as a hard failure",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


class SavedDependencyArchiveTests(unittest.TestCase):
    def write_zip(self, path: Path, members: dict[str, str]) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(path, "w") as archive:
            for member, contents in members.items():
                archive.writestr(member, contents)

    def test_report_passes_with_expected_members(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            deps = root / "deps"
            self.write_zip(
                deps / BROWSER_DEPS_ARCHIVE_NAME,
                {
                    "zig-v8-fork-123.tar.gz": "x",
                    "brotli-1.tar.gz": "x",
                    "zlib-1.tar.gz": "x",
                    "nghttp2-1.tar.gz": "x",
                    "curl-1.tar.gz": "x",
                    "libc_v8_test.a": "x",
                },
            )
            self.write_zip(
                deps / BORINGSSL_ARCHIVE_NAME,
                {
                    "boringssl-zig-main/build.zig": "x",
                    "boringssl-zig-main/README.md": "x",
                },
            )
            self.write_zip(
                deps / HTML5EVER_ARCHIVE_NAME,
                {
                    "bundle/.cargo/config.toml": "x",
                    "bundle/vendor/index.txt": "x",
                },
            )

            report = build_report(
                deps,
                browser_deps_archive=None,
                boringssl_archive=None,
                html5ever_archive=None,
                require_html5ever=True,
            )

            self.assertTrue(report["ok"])
            self.assertEqual(report["warnings"], [])
            self.assertIn("prebuilt V8 archive", report["archives"]["browser_deps"]["matched_optional"])

    def test_report_warns_when_html5ever_is_missing_but_optional(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            deps = root / "deps"
            self.write_zip(
                deps / BROWSER_DEPS_ARCHIVE_NAME,
                {
                    "zig-v8-fork-123.tar.gz": "x",
                    "brotli-1.tar.gz": "x",
                    "zlib-1.tar.gz": "x",
                    "nghttp2-1.tar.gz": "x",
                    "curl-1.tar.gz": "x",
                },
            )
            self.write_zip(
                deps / BORINGSSL_ARCHIVE_NAME,
                {
                    "boringssl-zig-main/build.zig": "x",
                    "boringssl-zig-main/README.md": "x",
                },
            )

            report = build_report(
                deps,
                browser_deps_archive=None,
                boringssl_archive=None,
                html5ever_archive=None,
                require_html5ever=False,
            )

            self.assertTrue(report["ok"])
            self.assertEqual(len(report["warnings"]), 1)

    def test_report_fails_when_browser_bundle_is_incomplete(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            deps = root / "deps"
            self.write_zip(
                deps / BROWSER_DEPS_ARCHIVE_NAME,
                {
                    "zig-v8-fork-123.tar.gz": "x",
                    "brotli-1.tar.gz": "x",
                },
            )
            self.write_zip(
                deps / BORINGSSL_ARCHIVE_NAME,
                {
                    "boringssl-zig-main/build.zig": "x",
                    "boringssl-zig-main/README.md": "x",
                },
            )

            report = build_report(
                deps,
                browser_deps_archive=None,
                boringssl_archive=None,
                html5ever_archive=None,
                require_html5ever=False,
            )

            self.assertFalse(report["ok"])
            self.assertTrue(any("browser dependency archive is missing required members" in item for item in report["failures"]))


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedDependencyArchiveTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    dependencies_root = (
        Path(args.dependencies_root).resolve()
        if args.dependencies_root
        else resolve_dependencies_root(repo_root)
    )
    report = build_report(
        dependencies_root,
        browser_deps_archive=Path(args.browser_deps_archive).resolve() if args.browser_deps_archive else None,
        boringssl_archive=Path(args.boringssl_archive).resolve() if args.boringssl_archive else None,
        html5ever_archive=Path(args.html5ever_archive).resolve() if args.html5ever_archive else None,
        require_html5ever=args.require_html5ever,
    )

    if args.json:
        print(json.dumps({"profile": "issue3-saved-dependency-archives", **report}, indent=2))
    else:
        emit_text(report)
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())