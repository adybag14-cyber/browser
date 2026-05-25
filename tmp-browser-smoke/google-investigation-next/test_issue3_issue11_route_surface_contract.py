#!/usr/bin/env python3

"""Check that the issue #11 route surfaces keep their key handoff markers."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


REQUIRED_FILES: tuple[tuple[str, str], ...] = (
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "Issue #11 progress-tracker route note",
    ),
    (
        "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
        "Workspace-context route note",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "Issue #11 route printer",
    ),
    (
        "scripts/linux/show_issue3_workspace_context_route.sh",
        "Workspace-context route printer",
    ),
)

CONTENT_EXPECTATIONS: tuple[tuple[str, str, str], ...] = (
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "issue `#11`",
        "The progress-tracker note should still target issue #11.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "check_issue3_saved_rust_build_readiness_route_surface.sh",
        "The progress-tracker note should keep the saved-Rust bridge surface visible.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "show_issue3_saved_rust_build_readiness_route.sh",
        "The progress-tracker note should keep the saved-Rust bridge route visible.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "check_issue3_saved_rust_toolchain_route_surface.sh",
        "The progress-tracker note should keep the raw saved-Rust route surface visible.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "check_issue3_staged_zig_toolchain_candidates.py",
        "The progress-tracker note should keep the staged-Zig helper visible.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "check_issue3_build_readiness_rerun.py",
        "The progress-tracker note should keep the build-readiness rerun helper visible.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        "The progress-tracker note should keep the explicit fallback Zig override visible.",
    ),
    (
        "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
        "show_issue3_progress_tracker_route.sh",
        "The workspace-context note should keep the issue #11 follow-up route visible.",
    ),
    (
        "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
        "show_issue3_saved_rust_toolchain_route.sh",
        "The workspace-context note should keep the saved-Rust follow-up visible.",
    ),
    (
        "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
        "check_issue3_staged_rust_toolchain_candidates.py",
        "The workspace-context note should keep the staged-Rust helper visible.",
    ),
    (
        "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
        "show_issue3_saved_zig_archive_candidates_route.sh",
        "The workspace-context note should keep the saved-Zig follow-up visible.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "saved_rust_build_readiness_route_surface",
        "The issue #11 route printer JSON should expose the saved-Rust bridge surface key.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "saved_rust_build_readiness_route",
        "The issue #11 route printer JSON should expose the saved-Rust bridge route key.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "saved_rust_toolchain_route_surface",
        "The issue #11 route printer JSON should still expose the raw saved-Rust surface key.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "staged_zig_toolchain_candidates",
        "The issue #11 route printer JSON should expose the staged-Zig key.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "build_readiness_rerun_helper",
        "The issue #11 route printer JSON should expose the rerun helper key.",
    ),
    (
        "scripts/linux/show_issue3_workspace_context_route.sh",
        "issue11_progress_tracker_route",
        "The workspace-context route printer JSON should expose the issue #11 follow-up key.",
    ),
    (
        "scripts/linux/show_issue3_workspace_context_route.sh",
        "saved_rust_archive_candidates",
        "The workspace-context route printer JSON should expose the saved-Rust archive candidates key.",
    ),
    (
        "scripts/linux/show_issue3_workspace_context_route.sh",
        "saved_zig_archive_candidates_route",
        "The workspace-context route printer JSON should expose the saved-Zig route key.",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the issue #11 progress-tracker and workspace-context "
            "route surfaces still expose the expected headed-mode re-entry markers."
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
        help="Run focused unit tests and exit",
    )
    return parser


def collect_results(repo_root: Path) -> dict[str, object]:
    missing_files: list[dict[str, str]] = []
    missing_snippets: list[dict[str, str]] = []

    for relative_path, label in REQUIRED_FILES:
        path = repo_root / relative_path
        if not path.is_file():
            missing_files.append(
                {
                    "path": relative_path,
                    "label": label,
                }
            )

    for relative_path, snippet, reason in CONTENT_EXPECTATIONS:
        path = repo_root / relative_path
        if not path.is_file():
            missing_snippets.append(
                {
                    "path": relative_path,
                    "snippet": snippet,
                    "reason": f"{reason} File is missing.",
                }
            )
            continue
        if snippet not in path.read_text(encoding="utf-8"):
            missing_snippets.append(
                {
                    "path": relative_path,
                    "snippet": snippet,
                    "reason": reason,
                }
            )

    return {
        "profile": "issue11-route-surface-contract",
        "repo_root": str(repo_root),
        "required_file_count": len(REQUIRED_FILES),
        "content_expectation_count": len(CONTENT_EXPECTATIONS),
        "missing_files": missing_files,
        "missing_snippets": missing_snippets,
        "ok": not missing_files and not missing_snippets,
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #11 route surface contract")
    print()
    print(f"Repo root: {result['repo_root']}")
    print(f"Required files checked: {result['required_file_count']}")
    print(f"Content expectations checked: {result['content_expectation_count']}")
    print()

    missing_files = result["missing_files"]
    missing_snippets = result["missing_snippets"]

    if not missing_files and not missing_snippets:
        print("All issue #11 route surface checks passed.")
        return

    if missing_files:
        print("Missing files:")
        for entry in missing_files:
            print(f"  - {entry['path']}: {entry['label']}")

    if missing_snippets:
        print("Missing snippets:")
        for entry in missing_snippets:
            print(f"  - {entry['path']}: {entry['reason']}")


class Issue11RouteSurfaceContractTests(unittest.TestCase):
    def test_collect_results_passes_when_all_markers_exist(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            for relative_path, _label in REQUIRED_FILES:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                snippets = [
                    snippet
                    for path, snippet, _reason in CONTENT_EXPECTATIONS
                    if path == relative_path
                ]
                target.write_text("\n".join(snippets) or "ok", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_files"], [])
            self.assertEqual(result["missing_snippets"], [])

    def test_collect_results_fails_when_file_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            for relative_path, _label in REQUIRED_FILES[1:]:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                snippets = [
                    snippet
                    for path, snippet, _reason in CONTENT_EXPECTATIONS
                    if path == relative_path
                ]
                target.write_text("\n".join(snippets) or "ok", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertEqual(result["missing_files"][0]["path"], REQUIRED_FILES[0][0])

    def test_collect_results_fails_when_snippet_drops(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            for relative_path, _label in REQUIRED_FILES:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                snippets = [
                    snippet
                    for path, snippet, _reason in CONTENT_EXPECTATIONS
                    if path == relative_path
                ]
                if relative_path == "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md":
                    snippets = [
                        snippet
                        for snippet in snippets
                        if snippet != "check_issue3_build_readiness_rerun.py"
                    ]
                target.write_text("\n".join(snippets) or "ok", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertEqual(len(result["missing_snippets"]), 1)
            self.assertEqual(
                result["missing_snippets"][0]["snippet"],
                "check_issue3_build_readiness_rerun.py",
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            Issue11RouteSurfaceContractTests
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
