#!/usr/bin/env python3

"""Check whether a checkout carries the current issue #11 re-entry surface.

This helper is intentionally narrow. It gives Linux/WSL headed-mode recovery
runs one fast check for the newer low-volume progress-tracker route, the Linux
re-entry route index, the helper-surface source checker, the saved-memory
helper-contract checker, the helper-inventory consistency checker, the
toolchains-root candidate helper, and the compact runtime re-entry route helper
that recent issue #11 work depends on.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


REQUIRED_ISSUE11_SURFACE: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "issue #11 progress-tracker route note"),
    ("docs/ISSUE11_LINUX_REENTRY_ROUTE_INDEX.md", "issue #11 Linux re-entry route index"),
    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry gate note"),
    ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved snapshot restore note"),
    ("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness route note"),
    ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
    ("scripts/check_issue3_helper_surface_source.py", "helper-surface source checker"),
    ("scripts/check_linux_build_readiness.py", "Linux build-readiness checker"),
    ("scripts/check_issue11_saved_memory_helper_contract.py", "saved-memory helper-contract checker"),
    ("scripts/check_issue11_reentry_inventory_consistency.py", "helper-inventory consistency checker"),
    ("scripts/check_issue11_toolchains_root_candidates.py", "toolchains-root candidate helper"),
    ("scripts/linux/show_issue11_runtime_reentry_tracker_route.sh", "issue #11 runtime re-entry route helper"),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether a checkout includes the current issue #11 Linux/WSL "
            "re-entry tracker surface."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
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


def collect_results(repo_root: Path) -> dict[str, object]:
    entries: list[dict[str, object]] = []
    missing_paths: list[str] = []

    for relative_path, label in REQUIRED_ISSUE11_SURFACE:
        target = repo_root / relative_path
        exists = target.is_file()
        if not exists:
            missing_paths.append(relative_path)
        entries.append(
            {
                "path": relative_path,
                "label": label,
                "exists": exists,
            }
        )

    return {
        "ok": not missing_paths,
        "repo_root": str(repo_root),
        "required_surface_file_count": len(REQUIRED_ISSUE11_SURFACE),
        "missing_paths": missing_paths,
        "surface": entries,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Expected issue #11 surface files: {result['required_surface_file_count']}")
    print("Surface status:")
    for entry in result["surface"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['path']}: {entry['label']}")

    if result["ok"]:
        print("\nIssue #11 progress-tracker surface check passed.")
        return

    print("\nIssue #11 progress-tracker surface check failed.", file=sys.stderr)
    print(
        "Suggested next step: refresh the checkout from a live branch-local helper root "
        "before trusting it for issue #11 Linux/WSL re-entry work.",
        file=sys.stderr,
    )


class Issue11ProgressTrackerSurfaceTests(unittest.TestCase):
    def test_passes_for_complete_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            for relative_path, _label in REQUIRED_ISSUE11_SURFACE:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_paths"], [])

    def test_flags_missing_progress_tracker_route(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            for relative_path, _label in REQUIRED_ISSUE11_SURFACE:
                if relative_path == "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md":
                    continue
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertIn(
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                result["missing_paths"],
            )

    def test_flags_missing_route_index(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            for relative_path, _label in REQUIRED_ISSUE11_SURFACE:
                if relative_path == "docs/ISSUE11_LINUX_REENTRY_ROUTE_INDEX.md":
                    continue
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertIn(
                "docs/ISSUE11_LINUX_REENTRY_ROUTE_INDEX.md",
                result["missing_paths"],
            )

    def test_flags_missing_saved_memory_helper_contract(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            for relative_path, _label in REQUIRED_ISSUE11_SURFACE:
                if relative_path == "scripts/check_issue11_saved_memory_helper_contract.py":
                    continue
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/check_issue11_saved_memory_helper_contract.py",
                result["missing_paths"],
            )

    def test_flags_missing_toolchains_root_helper(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            for relative_path, _label in REQUIRED_ISSUE11_SURFACE:
                if relative_path == "scripts/check_issue11_toolchains_root_candidates.py":
                    continue
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/check_issue11_toolchains_root_candidates.py",
                result["missing_paths"],
            )

    def test_flags_missing_runtime_reentry_route_helper(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            for relative_path, _label in REQUIRED_ISSUE11_SURFACE:
                if relative_path == "scripts/linux/show_issue11_runtime_reentry_tracker_route.sh":
                    continue
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/linux/show_issue11_runtime_reentry_tracker_route.sh",
                result["missing_paths"],
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            Issue11ProgressTrackerSurfaceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
