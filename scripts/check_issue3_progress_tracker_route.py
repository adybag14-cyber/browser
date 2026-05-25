#!/usr/bin/env python3

"""Check the issue #11 progress-tracker route for issue #3 re-entry work."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


REQUIRED_PATHS: tuple[tuple[str, str], ...] = (
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "Issue #11 handoff note for Linux/WSL re-entry work.",
    ),
    (
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "Runtime re-entry gate note that decides when issue #11 should own the run.",
    ),
    (
        "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
        "Saved-Memory route note used by issue #11 follow-up work.",
    ),
    (
        "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
        "Saved-Zig route note used when issue #11 is tracking archive selection.",
    ),
    (
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "Linux build-readiness route note used before the runtime lane reopens.",
    ),
    (
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "Zig recovery route note used while issue #11 owns toolchain work.",
    ),
    (
        "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
        "Fail-fast surface checker for the issue #11 route packet.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "Compact route printer for issue #11 progress updates.",
    ),
    (
        "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
        "Saved-Memory follow-up route printer used by issue #11.",
    ),
    (
        "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
        "Saved-Zig follow-up route printer used by issue #11.",
    ),
    (
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "Linux build-readiness route printer used by issue #11.",
    ),
    (
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        "Zig recovery route printer used by issue #11.",
    ),
)

CONTENT_CHECKS: tuple[tuple[str, str, str], ...] = (
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "issue `#11`",
        "The tracker note still points progress updates to issue #11.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "The tracker note keeps the runtime gate note visible.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "show_issue3_saved_memory_inputs_route.sh",
        "The tracker note keeps the saved-Memory route visible.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "show_issue3_saved_zig_archive_candidates_route.sh",
        "The tracker note keeps the saved-Zig route visible.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "show_issue3_linux_build_readiness_route.sh",
        "The tracker note keeps the Linux build-readiness route visible.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "show_issue3_zig_toolchain_recovery_route.sh",
        "The tracker note keeps the Zig recovery route visible.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "Goal:",
        "The tracker note keeps the compact start comment template visible.",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "Achieved:",
        "The tracker note keeps the compact completion comment template visible.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "ISSUE_NUMBER=11",
        "The route printer still targets issue #11 explicitly.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "ISSUE_URL=",
        "The route printer still exposes the issue URL.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "show_issue3_saved_memory_inputs_route.sh",
        "The route printer still exposes the saved-Memory route.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "show_issue3_saved_zig_archive_candidates_route.sh",
        "The route printer still exposes the saved-Zig route.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "show_issue3_linux_build_readiness_route.sh",
        "The route printer still exposes the Linux build-readiness route.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "show_issue3_zig_toolchain_recovery_route.sh",
        "The route printer still exposes the Zig recovery route.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "start_comment_template",
        "The route printer JSON path still exposes the start template.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "completion_comment_template",
        "The route printer JSON path still exposes the completion template.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        "The route printer still advertises the surfaced fallback Zig override.",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the issue #11 progress-tracker route for blocked issue #3 "
            "Linux/WSL re-entry work still has its required note, helper files, "
            "and key command markers in place."
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


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def collect_results(repo_root: Path) -> dict[str, object]:
    file_results: list[dict[str, object]] = []
    content_results: list[dict[str, object]] = []

    for relative_path, purpose in REQUIRED_PATHS:
        path = repo_root / relative_path
        file_results.append(
            {
                "path": relative_path,
                "purpose": purpose,
                "exists": path.is_file(),
            }
        )

    for relative_path, snippet, purpose in CONTENT_CHECKS:
        path = repo_root / relative_path
        exists = path.is_file()
        found = exists and snippet in read_text(path)
        content_results.append(
            {
                "path": relative_path,
                "snippet": snippet,
                "purpose": purpose,
                "found": found,
            }
        )

    missing_paths = [entry for entry in file_results if not entry["exists"]]
    missing_content = [entry for entry in content_results if not entry["found"]]
    return {
        "ok": not missing_paths and not missing_content,
        "repo_root": str(repo_root),
        "required_path_count": len(file_results),
        "content_check_count": len(content_results),
        "missing_path_count": len(missing_paths),
        "missing_content_count": len(missing_content),
        "required_paths": file_results,
        "content_checks": content_results,
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #3 progress-tracker route checker")
    print(f"Repo root: {result['repo_root']}")
    print()
    print("Required files:")
    for entry in result["required_paths"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"[{status}] {entry['path']}")
        print(f"  {entry['purpose']}")
    print()
    print("Content checks:")
    for entry in result["content_checks"]:
        status = "PASS" if entry["found"] else "FAIL"
        print(f"[{status}] {entry['path']}")
        print(f"  {entry['purpose']}")
    print()
    print(f"Missing paths: {result['missing_path_count']}")
    print(f"Missing content checks: {result['missing_content_count']}")
    if result["ok"]:
        print("Issue #11 progress-tracker route looks ready.")


class ProgressTrackerRouteTests(unittest.TestCase):
    def create_repo(self, *, include_saved_zig_route: bool = True) -> Path:
        tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(tempdir.cleanup)
        root = Path(tempdir.name)
        files: dict[str, str] = {
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md": (
                "issue `#11`\n"
                "docs/ISSUE3_RUNTIME_REENTRY_GATES.md\n"
                "show_issue3_saved_memory_inputs_route.sh\n"
                "show_issue3_saved_zig_archive_candidates_route.sh\n"
                "show_issue3_linux_build_readiness_route.sh\n"
                "show_issue3_zig_toolchain_recovery_route.sh\n"
                "Goal:\n"
                "Achieved:\n"
            ),
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": "gate\n",
            "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md": "saved memory\n",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": "linux build\n",
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md": "zig recovery\n",
            "scripts/linux/check_issue3_progress_tracker_route_surface.sh": "surface\n",
            "scripts/linux/show_issue3_saved_memory_inputs_route.sh": "saved memory route\n",
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh": "saved zig route\n",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh": "linux route\n",
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh": "zig route\n",
            "scripts/linux/show_issue3_progress_tracker_route.sh": (
                "ISSUE_NUMBER=11\n"
                "ISSUE_URL=https://github.com/adybag14-cyber/browser/issues/11\n"
                "show_issue3_saved_memory_inputs_route.sh\n"
                "show_issue3_saved_zig_archive_candidates_route.sh\n"
                "show_issue3_linux_build_readiness_route.sh\n"
                "show_issue3_zig_toolchain_recovery_route.sh\n"
                "start_comment_template\n"
                "completion_comment_template\n"
                "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz\n"
            ),
        }
        if include_saved_zig_route:
            files["docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"] = "saved zig\n"
        for relative_path, content in files.items():
            path = root / relative_path
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
        return root

    def test_collect_results_passes_when_all_markers_exist(self) -> None:
        root = self.create_repo()
        result = collect_results(root)
        self.assertTrue(result["ok"])
        self.assertEqual(result["missing_path_count"], 0)
        self.assertEqual(result["missing_content_count"], 0)

    def test_collect_results_fails_when_required_file_is_missing(self) -> None:
        root = self.create_repo(include_saved_zig_route=False)
        result = collect_results(root)
        self.assertFalse(result["ok"])
        self.assertEqual(result["missing_path_count"], 1)

    def test_collect_results_fails_when_content_marker_is_missing(self) -> None:
        root = self.create_repo()
        printer = root / "scripts/linux/show_issue3_progress_tracker_route.sh"
        printer.write_text("ISSUE_NUMBER=11\n", encoding="utf-8")
        result = collect_results(root)
        self.assertFalse(result["ok"])
        self.assertGreater(result["missing_content_count"], 0)


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            ProgressTrackerRouteTests
        )
        result = unittest.TextTestRunner(verbosity=0).run(suite)
        if result.wasSuccessful():
            print("ISSUE3_PROGRESS_TRACKER_ROUTE_SELF_TEST=pass")
            print(f"ISSUE3_PROGRESS_TRACKER_ROUTE_SELF_TEST_CASES={result.testsRun}")
            return 0
        print("ISSUE3_PROGRESS_TRACKER_ROUTE_SELF_TEST=fail", file=sys.stderr)
        return 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
