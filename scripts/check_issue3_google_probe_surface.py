#!/usr/bin/env python3

"""Fail-closed checker for the issue #3 reduced Google probe surface.

This helper verifies that the reduced Google homepage probe pair used for the
headed Windows typing investigation still exists and still exposes the key
runtime markers that the current narrowed regression depends on:

- the reduced Page.zig regression test
- the `google_home_title_probe.html` early-event instrumentation

It can validate either a live checkout root, the saved browser snapshot
archive, or both.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest
import zipfile


ARCHIVE_PREFIX = "browser-fork-headed-mode-foundation/"
DEFAULT_ARCHIVE_RELATIVE_PATH = "memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"

REQUIRED_PROBE_FILES: tuple[dict[str, object], ...] = (
    {
        "relative_path": "src/browser/Page.zig",
        "label": "reduced Google runtime regression test",
        "markers": (
            'test "Page reduced Google fixture accepts focused keyboard text and Enter submit"',
            'window.__lpEarlyEvents.join',
            'SUBMIT:n|',
        ),
    },
    {
        "relative_path": "src/browser/tests/page/google_home_title_probe.html",
        "label": "reduced Google homepage probe fixture",
        "markers": (
            "window.__lpEarlyEvents=[]",
            "document.forms.f.q",
            "mark('SUBMIT:",
            "window.setInterval(syncQueryInput, 250);",
        ),
    },
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the issue #3 reduced Google probe surface still exists "
            "and still carries the narrowed runtime markers."
        )
    )
    parser.add_argument(
        "--archive",
        default=DEFAULT_ARCHIVE_RELATIVE_PATH,
        help=(
            "Path to the saved repo snapshot zip "
            f"(default: {DEFAULT_ARCHIVE_RELATIVE_PATH})"
        ),
    )
    parser.add_argument(
        "--archive-prefix",
        default=ARCHIVE_PREFIX,
        help=f"Archive member prefix for the browser checkout (default: {ARCHIVE_PREFIX})",
    )
    parser.add_argument(
        "--helper-root",
        default=None,
        help=(
            "Optional checkout root to validate on disk. When provided, the "
            "checker verifies the same probe files and markers there too."
        ),
    )
    parser.add_argument(
        "--skip-archive",
        action="store_true",
        help="Only validate the helper root and skip the saved archive check.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text.",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit.",
    )
    return parser


def _check_text_surface(text: str, markers: tuple[str, ...]) -> tuple[bool, list[str]]:
    missing = [marker for marker in markers if marker not in text]
    return (len(missing) == 0, missing)


def _read_archive_text(archive: zipfile.ZipFile, member: str) -> str | None:
    try:
        return archive.read(member).decode("utf-8", "ignore")
    except KeyError:
        return None


def collect_results(
    *,
    archive_path: Path,
    archive_prefix: str,
    helper_root: Path | None,
    skip_archive: bool,
) -> dict[str, object]:
    result: dict[str, object] = {
        "ok": False,
        "archive_path": str(archive_path),
        "archive_prefix": archive_prefix,
        "helper_root": str(helper_root) if helper_root is not None else None,
        "archive_checked": not skip_archive,
        "archive_exists": archive_path.is_file(),
        "archive_readable": False,
        "archive_error": None,
        "helper_root_checked": helper_root is not None,
        "checked_files": [],
        "missing_archive_files": [],
        "missing_archive_markers": [],
        "missing_helper_root_files": [],
        "missing_helper_root_markers": [],
    }

    archive: zipfile.ZipFile | None = None
    archive_names: set[str] = set()

    if not skip_archive:
        if not archive_path.is_file():
            result["archive_error"] = "archive not found"
        else:
            try:
                archive = zipfile.ZipFile(archive_path)
                bad_member = archive.testzip()
                if bad_member is not None:
                    raise zipfile.BadZipFile(f"CRC failure in {bad_member}")
                archive_names = set(archive.namelist())
                result["archive_readable"] = True
            except (OSError, zipfile.BadZipFile) as exc:
                result["archive_error"] = str(exc)
                archive = None

    try:
        checked_files: list[dict[str, object]] = []
        for entry in REQUIRED_PROBE_FILES:
            relative_path = entry["relative_path"]
            label = entry["label"]
            markers = tuple(entry["markers"])

            file_result: dict[str, object] = {
                "relative_path": relative_path,
                "label": label,
                "archive_member": f"{archive_prefix}{relative_path}",
                "archive_exists": None,
                "archive_missing_markers": [],
                "helper_root_exists": None,
                "helper_root_missing_markers": [],
            }

            if not skip_archive and archive is not None:
                archive_member = file_result["archive_member"]
                archive_exists = archive_member in archive_names
                file_result["archive_exists"] = archive_exists
                if not archive_exists:
                    result["missing_archive_files"].append(relative_path)
                else:
                    archive_text = _read_archive_text(archive, archive_member)
                    archive_ok, archive_missing = _check_text_surface(archive_text or "", markers)
                    if not archive_ok:
                        for marker in archive_missing:
                            result["missing_archive_markers"].append(
                                {"relative_path": relative_path, "marker": marker}
                            )
                        file_result["archive_missing_markers"] = archive_missing

            if helper_root is not None:
                helper_path = helper_root / relative_path
                helper_exists = helper_path.is_file()
                file_result["helper_root_exists"] = helper_exists
                if not helper_exists:
                    result["missing_helper_root_files"].append(relative_path)
                else:
                    helper_text = helper_path.read_text(encoding="utf-8", errors="ignore")
                    helper_ok, helper_missing = _check_text_surface(helper_text, markers)
                    if not helper_ok:
                        for marker in helper_missing:
                            result["missing_helper_root_markers"].append(
                                {"relative_path": relative_path, "marker": marker}
                            )
                        file_result["helper_root_missing_markers"] = helper_missing

            checked_files.append(file_result)

        result["checked_files"] = checked_files
        result["ok"] = (
            (skip_archive or (result["archive_readable"] and not result["missing_archive_files"] and not result["missing_archive_markers"]))
            and (
                helper_root is None
                or (
                    not result["missing_helper_root_files"]
                    and not result["missing_helper_root_markers"]
                )
            )
        )
        return result
    finally:
        if archive is not None:
            archive.close()


def emit_text(result: dict[str, object]) -> None:
    if result["archive_checked"]:
        archive_status = "PASS" if result["archive_readable"] else "FAIL"
        print(f"Saved snapshot archive: [{archive_status}] {result['archive_path']}")
        if result["archive_error"]:
            print(f"Archive error: {result['archive_error']}")
    else:
        print("Saved snapshot archive: [SKIP] not checked")
    print(f"Archive prefix: {result['archive_prefix']}")
    print(f"Helper root: {result['helper_root'] or 'not provided'}")

    print("Reduced Google probe surface:")
    for entry in result["checked_files"]:
        archive_status = "SKIP"
        if result["archive_checked"]:
            archive_status = "PASS"
            if entry["archive_exists"] is False or entry["archive_missing_markers"]:
                archive_status = "FAIL"

        helper_status = "SKIP"
        if result["helper_root_checked"]:
            helper_status = "PASS"
            if entry["helper_root_exists"] is False or entry["helper_root_missing_markers"]:
                helper_status = "FAIL"

        print(f"  [archive={archive_status} helper={helper_status}] {entry['relative_path']}: {entry['label']}")
        for marker in entry["archive_missing_markers"]:
            print(f"         archive missing marker: {marker}")
        for marker in entry["helper_root_missing_markers"]:
            print(f"         helper root missing marker: {marker}")

    if result["ok"]:
        print("\nIssue #3 reduced Google probe surface check passed.")
        return

    print("\nIssue #3 reduced Google probe surface check failed.", file=sys.stderr)
    if result["missing_archive_files"] or result["missing_archive_markers"]:
        print(
            "Suggested next step: refresh the saved snapshot or sync the reduced Google probe files before relying on saved-archive issue #3 re-entry.",
            file=sys.stderr,
        )
    elif result["missing_helper_root_files"] or result["missing_helper_root_markers"]:
        print(
            "Suggested next step: re-read the live checkout root and restore the reduced Google probe pair before runtime validation.",
            file=sys.stderr,
        )


class Issue3GoogleProbeSurfaceTests(unittest.TestCase):
    def _write_archive(self, archive_path: Path, page_text: str, html_text: str) -> None:
        with zipfile.ZipFile(archive_path, "w") as archive:
            archive.writestr(f"{ARCHIVE_PREFIX}src/browser/Page.zig", page_text)
            archive.writestr(
                f"{ARCHIVE_PREFIX}src/browser/tests/page/google_home_title_probe.html",
                html_text,
            )

    def test_passes_when_archive_contains_required_markers(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            archive_path = root / "snapshot.zip"
            self._write_archive(
                archive_path,
                '\n'.join(REQUIRED_PROBE_FILES[0]["markers"]),
                '\n'.join(REQUIRED_PROBE_FILES[1]["markers"]),
            )

            result = collect_results(
                archive_path=archive_path,
                archive_prefix=ARCHIVE_PREFIX,
                helper_root=None,
                skip_archive=False,
            )

            self.assertTrue(result["ok"])

    def test_fails_when_archive_lacks_google_submit_marker(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            archive_path = root / "snapshot.zip"
            self._write_archive(
                archive_path,
                '\n'.join(REQUIRED_PROBE_FILES[0]["markers"]),
                "window.__lpEarlyEvents=[]\ndocument.forms.f.q\nwindow.setInterval(syncQueryInput, 250);",
            )

            result = collect_results(
                archive_path=archive_path,
                archive_prefix=ARCHIVE_PREFIX,
                helper_root=None,
                skip_archive=False,
            )

            self.assertFalse(result["ok"])
            self.assertIn(
                {
                    "relative_path": "src/browser/tests/page/google_home_title_probe.html",
                    "marker": "mark('SUBMIT:",
                },
                result["missing_archive_markers"],
            )

    def test_helper_root_validation_reports_missing_page_test_marker(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "browser"
            (helper_root / "src/browser/tests/page").mkdir(parents=True, exist_ok=True)
            (helper_root / "src/browser").mkdir(parents=True, exist_ok=True)

            (helper_root / "src/browser/Page.zig").write_text("SUBMIT:n|\n", encoding="utf-8")
            (helper_root / "src/browser/tests/page/google_home_title_probe.html").write_text(
                '\n'.join(REQUIRED_PROBE_FILES[1]["markers"]),
                encoding="utf-8",
            )

            result = collect_results(
                archive_path=root / "missing.zip",
                archive_prefix=ARCHIVE_PREFIX,
                helper_root=helper_root,
                skip_archive=True,
            )

            self.assertFalse(result["ok"])
            self.assertIn(
                {
                    "relative_path": "src/browser/Page.zig",
                    "marker": 'test "Page reduced Google fixture accepts focused keyboard text and Enter submit"',
                },
                result["missing_helper_root_markers"],
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            Issue3GoogleProbeSurfaceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    helper_root = Path(args.helper_root).resolve() if args.helper_root else None
    result = collect_results(
        archive_path=Path(args.archive).resolve(),
        archive_prefix=args.archive_prefix,
        helper_root=helper_root,
        skip_archive=args.skip_archive,
    )
    if args.json:
        print(
            json.dumps(
                {"profile": "issue3-google-probe-surface", **result},
                indent=2,
            )
        )
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())