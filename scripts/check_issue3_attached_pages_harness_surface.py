#!/usr/bin/env python3

"""Check whether the attached-pages localhost harness surface is present.

This helper is intentionally narrow:
- verifies the attached-pages harness files exist in the selected checkout
- keeps the Google-style attached HTML route note visible
- fails fast before Linux/WSL or Windows replay work trusts a stale snapshot
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


HARNESS_PATHS: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md", "Google-style attached HTML validation note"),
    ("tmp-browser-smoke/attached-pages/README.md", "attached-pages harness runbook"),
    ("tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py", "attached-pages catalog launcher"),
    ("tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py", "attached-pages preflight report"),
    ("tmp-browser-smoke/attached-pages/attached_pages_server.py", "attached-pages localhost server"),
    ("tmp-browser-smoke/attached-pages/attached_pages_sidecar_audit.py", "attached-pages sidecar audit"),
    ("scripts/windows/start_attached_pages_catalog.ps1", "Windows attached-pages launcher"),
    ("scripts/windows/show_attached_pages_preflight_report.ps1", "Windows attached-pages preflight wrapper"),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the attached-pages localhost harness surface is present "
            "before trusting issue #3 compatibility replay."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout to inspect (default: current directory)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of text output",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def collect_results(repo_root: Path) -> dict[str, object]:
    checked_paths: list[dict[str, object]] = []
    missing_paths: list[str] = []

    for relative_path, label in HARNESS_PATHS:
        full_path = repo_root / relative_path
        exists = full_path.is_file()
        checked_paths.append(
            {
                "path": relative_path,
                "label": label,
                "exists": exists,
            }
        )
        if not exists:
            missing_paths.append(relative_path)

    diagnosis = "ready" if not missing_paths else "missing-attached-pages-harness-surface"
    suggested_next_step = (
        "Run the attached-pages preflight or launcher surfaces from this checkout."
        if not missing_paths
        else "Restore or sync the attached-pages harness files into this checkout before replaying the saved HTML pages."
    )

    return {
        "ok": not missing_paths,
        "diagnosis": diagnosis,
        "repo_root": str(repo_root),
        "checked_paths": checked_paths,
        "missing_paths": missing_paths,
        "suggested_next_step": suggested_next_step,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print("Attached-pages harness paths:")
    for entry in result["checked_paths"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['path']}: {entry['label']}")

    if result["ok"]:
        print("\nAttached-pages harness surface check passed.")
        return

    print("\nAttached-pages harness surface check failed.", file=sys.stderr)
    print(f"Diagnosis: {result['diagnosis']}", file=sys.stderr)
    print(f"Suggested next step: {result['suggested_next_step']}", file=sys.stderr)


class AttachedPagesHarnessSurfaceTests(unittest.TestCase):
    def test_collect_results_passes_when_harness_surface_exists(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            for relative_path, _label in HARNESS_PATHS:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertTrue(result["ok"])
            self.assertEqual(result["diagnosis"], "ready")
            self.assertEqual(result["missing_paths"], [])

    def test_collect_results_reports_missing_preflight_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            for relative_path, _label in HARNESS_PATHS:
                if relative_path == "tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py":
                    continue
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertEqual(
                result["diagnosis"],
                "missing-attached-pages-harness-surface",
            )
            self.assertIn(
                "tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py",
                result["missing_paths"],
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            AttachedPagesHarnessSurfaceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(json.dumps({"profile": "issue3-attached-pages-harness-surface", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())