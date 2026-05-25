#!/usr/bin/env python3

"""Audit the issue #11 Linux/WSL progress-tracker route contract.

This helper gives scheduled runs a small branch-local check they can run before
they trust issue #11 and its linked helper routes as the current low-volume
progress lane for the blocked issue #3 runtime re-entry work.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import tempfile
import textwrap
import unittest


EXPECTED_SURFACES: tuple[tuple[str, str], ...] = (
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "Route note that explains when Linux/WSL work should report progress on issue #11.",
    ),
    (
        "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
        "Fail-fast shell surface check for the issue #11 progress route.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "Compact route printer for the issue #11 progress lane.",
    ),
)

EXPECTED_SNIPPETS: tuple[tuple[str, str, str], ...] = (
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "issue `#11`",
        "Route note should keep the lower-volume issue #11 handoff visible.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "check_issue3_saved_zig_archive_candidates_route_surface.sh",
        "Route note should keep the saved-Zig surface check visible before archive-selection work is trusted.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "check_issue3_zig_toolchain_match.sh",
        "Route note should keep the matching-line gate visible after any saved Zig restore.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
        "Route note should keep the archive-restore surface visible before broader readiness resumes.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "show_issue3_linux_build_readiness_route.sh",
        "Route note should keep the Linux/WSL build-readiness handoff visible.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        "Route note should keep the fallback Zig archive override visible.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "Goal:",
        "Route note should keep the start comment template visible.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "Achieved:",
        "Route note should keep the completion comment template visible.",
    ),
    (
        "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "Surface checker should audit the route note itself.",
    ),
    (
        "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
        "show_issue3_saved_zig_archive_candidates_route.sh",
        "Surface checker should require the saved-Zig route printer.",
    ),
    (
        "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
        "check_issue3_zig_toolchain_archive_restore_route_surface.sh",
        "Surface checker should require the archive-restore surface checker.",
    ),
    (
        "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
        "show_issue3_zig_toolchain_recovery_route.sh",
        "Surface checker should require the Zig recovery route printer.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "issue #11 progress-tracker route",
        "Route printer should still introduce the issue #11 handoff clearly.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "saved_zig_archive_route_surface",
        "Route printer JSON should expose the saved-Zig surface check explicitly.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "zig_archive_restore_surface",
        "Route printer JSON should expose the archive-restore surface explicitly.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "zig_toolchain_matching_line_gate",
        "Route printer JSON should expose the matching-line gate explicitly.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "show_issue3_linux_build_readiness_route.sh",
        "Route printer should expose the Linux/WSL build-readiness follow-up.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        "Route printer usage should expose the fallback Zig archive override.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "start_comment_template",
        "Route printer JSON should expose the start-comment template.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "completion_comment_template",
        "Route printer JSON should expose the completion-comment template.",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the issue #11 Linux/WSL progress-tracker route note "
            "and its companion shell helpers still expose the branch-local "
            "handoff surface that scheduled runs depend on."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser repo root (default: current directory)",
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


def collect_results(repo_root: Path) -> dict[str, object]:
    surface_entries: list[dict[str, object]] = []
    snippet_entries: list[dict[str, object]] = []
    missing_paths: list[str] = []
    missing_snippets: list[dict[str, str]] = []

    for relative_path, reason in EXPECTED_SURFACES:
        full_path = repo_root / relative_path
        exists = full_path.is_file()
        if not exists:
            missing_paths.append(relative_path)
        surface_entries.append(
            {
                "path": relative_path,
                "reason": reason,
                "exists": exists,
            }
        )

    for relative_path, snippet, reason in EXPECTED_SNIPPETS:
        full_path = repo_root / relative_path
        exists = full_path.is_file() and snippet in full_path.read_text(encoding="utf-8")
        if not exists:
            missing_snippets.append(
                {
                    "path": relative_path,
                    "snippet": snippet,
                    "reason": reason,
                }
            )
        snippet_entries.append(
            {
                "path": relative_path,
                "snippet": snippet,
                "reason": reason,
                "exists": exists,
            }
        )

    return {
        "ok": not missing_paths and not missing_snippets,
        "repo_root": str(repo_root),
        "surface_entries": surface_entries,
        "snippet_entries": snippet_entries,
        "missing_paths": missing_paths,
        "missing_snippets": missing_snippets,
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #11 progress-tracker route contract audit")
    print()
    print(f"Repo root: {result['repo_root']}")
    print()
    for entry in result["surface_entries"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"[{status}] {entry['path']}")
        print(f"  {entry['reason']}")
    print()
    print("Snippet expectations:")
    for entry in result["snippet_entries"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"[{status}] {entry['path']}")
        print(f"  {entry['reason']}")

    if result["ok"]:
        print("\nIssue #11 progress-tracker route contract looks current.")
        return

    print("\nIssue #11 progress-tracker route contract audit failed.")
    if result["missing_paths"]:
        print("Missing files:")
        for path in result["missing_paths"]:
            print(f"  - {path}")
    if result["missing_snippets"]:
        print("Missing snippets:")
        for entry in result["missing_snippets"]:
            print(f"  - {entry['path']}: {entry['snippet']}")


def make_fixture_repo(root: Path) -> Path:
    repo_root = root / "browser"
    files = {
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md": textwrap.dedent(
            """
            # Issue #3 Progress Tracker Route

            Use issue `#11`.
            Run `check_issue3_saved_zig_archive_candidates_route_surface.sh`.
            Run `check_issue3_zig_toolchain_match.sh`.
            Run `check_issue3_zig_toolchain_archive_restore_route_surface.sh`.
            Run `show_issue3_linux_build_readiness_route.sh`.
            Use `--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz`.

            Goal:
            Achieved:
            """
        ).strip()
        + "\n",
        "scripts/linux/check_issue3_progress_tracker_route_surface.sh": textwrap.dedent(
            """
            docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
            show_issue3_saved_zig_archive_candidates_route.sh
            check_issue3_zig_toolchain_archive_restore_route_surface.sh
            show_issue3_zig_toolchain_recovery_route.sh
            """
        ).strip()
        + "\n",
        "scripts/linux/show_issue3_progress_tracker_route.sh": textwrap.dedent(
            """
            issue #11 progress-tracker route
            saved_zig_archive_route_surface
            zig_archive_restore_surface
            zig_toolchain_matching_line_gate
            show_issue3_linux_build_readiness_route.sh
            --fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz
            start_comment_template
            completion_comment_template
            """
        ).strip()
        + "\n",
    }
    for relative_path, body in files.items():
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(body, encoding="utf-8")
    return repo_root


class Issue11ProgressTrackerRouteContractTests(unittest.TestCase):
    def test_collect_results_passes_for_complete_fixture(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = make_fixture_repo(Path(tmpdir))
            result = collect_results(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_paths"], [])
            self.assertEqual(result["missing_snippets"], [])

    def test_collect_results_reports_missing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = make_fixture_repo(Path(tmpdir))
            (repo_root / "scripts/linux/show_issue3_progress_tracker_route.sh").unlink()
            result = collect_results(repo_root)
            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/linux/show_issue3_progress_tracker_route.sh",
                result["missing_paths"],
            )

    def test_collect_results_reports_missing_snippet(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = make_fixture_repo(Path(tmpdir))
            target = repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
            target.write_text("# Issue #3 Progress Tracker Route\nUse issue `#11`.\n", encoding="utf-8")
            result = collect_results(repo_root)
            self.assertFalse(result["ok"])
            snippets = {entry["snippet"] for entry in result["missing_snippets"]}
            self.assertIn("check_issue3_zig_toolchain_match.sh", snippets)
            self.assertIn("Goal:", snippets)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            Issue11ProgressTrackerRouteContractTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(
            json.dumps(
                {"profile": "issue11-progress-tracker-route-contract", **result},
                indent=2,
            )
        )
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())