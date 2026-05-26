#!/usr/bin/env python3

"""Check whether a restored checkout includes the issue #11 build-readiness surface.

This helper focuses on the newer Linux/WSL re-entry helpers that may be absent
from older restored snapshots even when the broader checkout looks usable.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


BUILD_READINESS_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
    (
        "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md",
        "staged Rust toolchain candidates route note",
    ),
    (
        "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
        "staged Zig toolchain candidates route note",
    ),
    (
        "scripts/check_issue3_staged_rust_toolchain_candidates.py",
        "staged Rust toolchain candidates helper",
    ),
    (
        "scripts/check_issue3_staged_zig_toolchain_candidates.py",
        "staged Zig toolchain candidates helper",
    ),
    (
        "scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh",
        "staged Rust route surface checker",
    ),
    (
        "scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh",
        "staged Rust route printer",
    ),
    (
        "scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh",
        "staged Zig route surface checker",
    ),
    (
        "scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh",
        "staged Zig route printer",
    ),
    (
        "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
        "offline build-inputs route surface checker",
    ),
    (
        "scripts/linux/show_issue3_offline_build_inputs_route.sh",
        "offline build-inputs route printer",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether a restored browser snapshot includes the build-readiness "
            "route files used by issue #11 Linux/WSL re-entry work."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the restored browser checkout (default: current directory)",
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
    for relative_path, label in BUILD_READINESS_SURFACE_PATHS:
        exists = (repo_root / relative_path).is_file()
        entry = {
            "path": relative_path,
            "label": label,
            "exists": exists,
        }
        entries.append(entry)
        if not exists:
            missing_paths.append(relative_path)
    ok = not missing_paths
    return {
        "ok": ok,
        "diagnosis": "ready" if ok else "missing-build-readiness-surface",
        "repo_root": str(repo_root),
        "surface_entries": entries,
        "missing_paths": missing_paths,
        "suggested_next_step": (
            ""
            if ok
            else "Refresh the restored checkout helper surface from a live helper root, then rerun this checker before trusting issue #11 build-readiness routes."
        ),
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Restored checkout: {result['repo_root']}")
    print("Issue #11 build-readiness surface:")
    for entry in result["surface_entries"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['path']}: {entry['label']}")
    if result["ok"]:
        print("\nBuild-readiness surface check passed.")
        return
    print("\nBuild-readiness surface check failed.", file=sys.stderr)
    print(f"Diagnosis: {result['diagnosis']}", file=sys.stderr)
    print(f"Suggested next step: {result['suggested_next_step']}", file=sys.stderr)


class RestoredBuildReadinessSurfaceTests(unittest.TestCase):
    def test_collect_results_passes_when_surface_is_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser-memory-snapshot"
            repo_root.mkdir()
            for relative_path, _label in BUILD_READINESS_SURFACE_PATHS:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertTrue(result["ok"])
            self.assertEqual(result["diagnosis"], "ready")
            self.assertEqual(result["missing_paths"], [])

    def test_collect_results_reports_missing_staged_zig_route_note(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser-memory-snapshot"
            repo_root.mkdir()
            for relative_path, _label in BUILD_READINESS_SURFACE_PATHS:
                if relative_path == "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md":
                    continue
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertEqual(result["diagnosis"], "missing-build-readiness-surface")
            self.assertIn(
                "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
                result["missing_paths"],
            )

    def test_collect_results_reports_missing_offline_surface_checker(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser-memory-snapshot"
            repo_root.mkdir()
            for relative_path, _label in BUILD_READINESS_SURFACE_PATHS:
                if relative_path == "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh":
                    continue
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("ok", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
                result["missing_paths"],
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            RestoredBuildReadinessSurfaceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(json.dumps({"profile": "issue3-restored-build-readiness-surface", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())