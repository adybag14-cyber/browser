#!/usr/bin/env python3

"""Check whether the issue #3 attached-pages re-entry surface is present.

This helper gives restore-based Linux or WSL follow-up a small, focused check
for the newer attached-pages replay bridge files that now sit between the saved
snapshot route and the broader Windows replay ladder.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest


ATTACHED_PAGES_REENTRY_PATHS: tuple[tuple[str, str], ...] = (
    (
        "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md",
        "Google-shaped attached-page validation flow note",
    ),
    (
        "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md",
        "top-level attached-page replay bridge note",
    ),
    (
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "Windows replay attached-page quickstart note",
    ),
    (
        "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "launcher-companion surface checker",
    ),
    (
        "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "launcher-companion route helper",
    ),
    (
        "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "Windows replay attached-page surface checker",
    ),
    (
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "Windows replay attached-page route helper",
    ),
    (
        "scripts/windows/start_attached_pages_catalog.ps1",
        "Windows attached-pages catalog launcher",
    ),
    (
        "tmp-browser-smoke/attached-pages/README.md",
        "attached-pages launcher runbook",
    ),
    (
        "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py",
        "cross-platform attached-pages launcher",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the issue #3 attached-pages re-entry helper surface "
            "is available before broader replay follow-up."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout to inspect (default: current directory)",
    )
    parser.add_argument(
        "--helper-root",
        default=None,
        help=(
            "Optional live helper checkout to compare against when the current "
            "checkout may be a restored snapshot"
        ),
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def collect_results(repo_root: Path, helper_root: Path | None) -> dict[str, object]:
    surface_files: list[dict[str, object]] = []
    missing_paths: list[str] = []
    drifted_paths: list[str] = []

    for relative_path, label in ATTACHED_PAGES_REENTRY_PATHS:
        checkout_path = repo_root / relative_path
        entry: dict[str, object] = {
            "path": relative_path,
            "label": label,
            "exists": checkout_path.is_file(),
            "matches_helper_root": None,
            "checkout_sha256": None,
            "helper_root_sha256": None,
        }
        if checkout_path.is_file():
            entry["checkout_sha256"] = file_sha256(checkout_path)
        else:
            missing_paths.append(relative_path)

        if helper_root is not None:
            helper_path = helper_root / relative_path
            entry["helper_root_exists"] = helper_path.is_file()
            if helper_path.is_file():
                entry["helper_root_sha256"] = file_sha256(helper_path)
                if checkout_path.is_file():
                    entry["matches_helper_root"] = (
                        entry["checkout_sha256"] == entry["helper_root_sha256"]
                    )
                    if entry["matches_helper_root"] is False:
                        drifted_paths.append(relative_path)
                else:
                    entry["matches_helper_root"] = False
            else:
                entry["matches_helper_root"] = None if not checkout_path.is_file() else False
                if checkout_path.is_file():
                    drifted_paths.append(relative_path)

        surface_files.append(entry)

    diagnosis = "ready"
    if missing_paths and drifted_paths:
        diagnosis = "missing-paths-and-drift"
    elif missing_paths:
        diagnosis = "missing-paths"
    elif drifted_paths:
        diagnosis = "helper-surface-drift"

    return {
        "ok": not missing_paths and not drifted_paths,
        "diagnosis": diagnosis,
        "repo_root": str(repo_root),
        "helper_root": str(helper_root) if helper_root is not None else None,
        "surface_files": surface_files,
        "missing_paths": missing_paths,
        "drifted_paths": drifted_paths,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Helper root: {result['helper_root'] or 'not provided'}")
    print("Attached-pages re-entry surface:")
    for entry in result["surface_files"]:
        if entry["exists"] and entry.get("matches_helper_root") is False:
            status = "FAIL"
        elif entry["exists"]:
            status = "PASS"
        else:
            status = "FAIL"
        print(f"  [{status}] {entry['path']}: {entry['label']}")
        if entry.get("matches_helper_root") is False:
            print("         helper-root comparison: drift detected")

    if result["ok"]:
        print("\nAttached-pages re-entry surface check passed.")
        return

    print("\nAttached-pages re-entry surface check failed.", file=sys.stderr)
    print(f"Diagnosis: {result['diagnosis']}", file=sys.stderr)
    if result["missing_paths"]:
        joined = ", ".join(result["missing_paths"])
        print(
            f"Missing paths: {joined}",
            file=sys.stderr,
        )
    if result["drifted_paths"]:
        joined = ", ".join(result["drifted_paths"])
        print(
            f"Drifted paths: {joined}",
            file=sys.stderr,
        )


class AttachedPagesReentrySurfaceTests(unittest.TestCase):
    def test_collect_results_passes_for_complete_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            for relative_path, _label in ATTACHED_PAGES_REENTRY_PATHS:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(repo_root, helper_root=None)

            self.assertTrue(result["ok"])
            self.assertEqual(result["diagnosis"], "ready")

    def test_collect_results_reports_missing_launcher_companion_checker(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            for relative_path, _label in ATTACHED_PAGES_REENTRY_PATHS:
                if (
                    relative_path
                    == "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1"
                ):
                    continue
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(repo_root, helper_root=None)

            self.assertFalse(result["ok"])
            self.assertEqual(result["diagnosis"], "missing-paths")
            self.assertIn(
                "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
                result["missing_paths"],
            )

    def test_collect_results_reports_missing_top_level_bridge(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            for relative_path, _label in ATTACHED_PAGES_REENTRY_PATHS:
                if relative_path == "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md":
                    continue
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(repo_root, helper_root=None)

            self.assertFalse(result["ok"])
            self.assertEqual(result["diagnosis"], "missing-paths")
            self.assertIn(
                "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md",
                result["missing_paths"],
            )

    def test_collect_results_reports_helper_root_drift(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            repo_root = base / "restored"
            helper_root = base / "live"
            repo_root.mkdir()
            helper_root.mkdir()
            for index, (relative_path, _label) in enumerate(ATTACHED_PAGES_REENTRY_PATHS):
                for root in (repo_root, helper_root):
                    target = root / relative_path
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_text("same", encoding="utf-8")
                if index == 0:
                    (repo_root / relative_path).write_text("drift", encoding="utf-8")

            result = collect_results(repo_root, helper_root=helper_root)

            self.assertFalse(result["ok"])
            self.assertEqual(result["diagnosis"], "helper-surface-drift")
            self.assertIn(
                "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md",
                result["drifted_paths"],
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            AttachedPagesReentrySurfaceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    helper_root = Path(args.helper_root).resolve() if args.helper_root else None
    result = collect_results(repo_root, helper_root)
    if args.json:
        print(json.dumps({"profile": "issue3-attached-pages-reentry-surface", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
