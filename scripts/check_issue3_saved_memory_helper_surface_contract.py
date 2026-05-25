#!/usr/bin/env python3

"""Audit the saved-memory preflight helper against expected live helper surfaces.

This is a small branch-local regression helper for the issue #11 Linux/WSL
re-entry lane. It checks whether scripts/check_issue3_saved_memory_inputs.py
still requires the helper-surface files that newer route notes and follow-up
helpers depend on before a scheduled run trusts the saved-Memory preflight.
"""

from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path
import tempfile
import unittest


TARGET_SCRIPT = "scripts/check_issue3_saved_memory_inputs.py"
TARGET_CONSTANT = "REQUIRED_RESTORED_HELPER_FILES"

EXPECTED_HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
    (
        "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
        "saved-memory route note should stay visible to the same preflight it documents",
    ),
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "issue #11 tracker note should stay visible before broader build-readiness helpers are trusted",
    ),
    (
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md",
        "saved snapshot archive-surface note should stay visible before restore mode is chosen",
    ),
    (
        "scripts/check_issue3_saved_browser_snapshot_archive_surface.py",
        "saved snapshot archive-surface helper should stay visible before restore mode is chosen",
    ),
    (
        "scripts/check_issue3_saved_zig_archive_candidates.py",
        "saved Zig archive candidate helper should stay visible before archive selection is rebuilt by hand",
    ),
    (
        "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
        "saved-memory route surface check should stay visible before the preflight is trusted",
    ),
    (
        "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
        "saved-memory route printer should stay visible before the preflight is trusted",
    ),
    (
        "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
        "issue #11 tracker route surface check should stay visible before issue comments are treated as the current lane",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "issue #11 tracker route printer should stay visible before issue comments are treated as the current lane",
    ),
    (
        "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
        "saved Zig archive route surface check should stay visible before archive choice is rebuilt by hand",
    ),
    (
        "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
        "saved Zig archive route printer should stay visible before archive choice is rebuilt by hand",
    ),
    (
        "scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh",
        "Windows runtime handoff surface check should stay visible once the Linux/WSL gates reopen",
    ),
    (
        "scripts/linux/show_issue3_windows_runtime_handoff_route.sh",
        "Windows runtime handoff route printer should stay visible once the Linux/WSL gates reopen",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether scripts/check_issue3_saved_memory_inputs.py still "
            "requires the live helper-surface entries that the Linux/WSL re-entry "
            "lane depends on."
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


def extract_required_helper_paths(script_path: Path, constant_name: str) -> set[str]:
    module = ast.parse(script_path.read_text(encoding="utf-8"), filename=str(script_path))
    for node in module.body:
        if not isinstance(node, ast.Assign):
            continue
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id == constant_name:
                value = ast.literal_eval(node.value)
                return {entry[0] for entry in value}
    raise ValueError(f"Could not find {constant_name} in {script_path}")


def collect_results(repo_root: Path) -> dict[str, object]:
    target_script = repo_root / TARGET_SCRIPT
    target_script_exists = target_script.is_file()
    required_paths = (
        extract_required_helper_paths(target_script, TARGET_CONSTANT)
        if target_script_exists
        else set()
    )

    expected_entries: list[dict[str, object]] = []
    missing_live_paths: list[str] = []
    missing_contract_paths: list[str] = []

    for relative_path, reason in EXPECTED_HELPER_SURFACE_PATHS:
        live_path = repo_root / relative_path
        live_exists = live_path.is_file()
        in_contract = relative_path in required_paths
        if not live_exists:
            missing_live_paths.append(relative_path)
        elif not in_contract:
            missing_contract_paths.append(relative_path)
        expected_entries.append(
            {
                "path": relative_path,
                "reason": reason,
                "live_exists": live_exists,
                "in_saved_memory_contract": in_contract,
            }
        )

    ok = target_script_exists and not missing_live_paths and not missing_contract_paths
    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "target_script": str(target_script),
        "target_script_exists": target_script_exists,
        "target_constant": TARGET_CONSTANT,
        "expected_entries": expected_entries,
        "missing_live_paths": missing_live_paths,
        "missing_contract_paths": missing_contract_paths,
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #11 saved-memory helper-surface contract audit")
    print()
    print(f"Repo root:      {result['repo_root']}")
    print(f"Target script:  {result['target_script']}")
    print(f"Target constant:{result['target_constant']}")
    print()
    for entry in result["expected_entries"]:
        if not entry["live_exists"]:
            status = "WARN"
        elif entry["in_saved_memory_contract"]:
            status = "PASS"
        else:
            status = "FAIL"
        print(f"[{status}] {entry['path']}")
        print(f"  {entry['reason']}")

    if result["ok"]:
        print("\nSaved-memory helper-surface contract looks current.")
        return

    print("\nSaved-memory helper-surface contract audit failed.")
    if not result["target_script_exists"]:
        print("Suggested next step: restore or fetch the target saved-memory helper before trusting this audit.")
        return
    if result["missing_live_paths"]:
        joined = ", ".join(result["missing_live_paths"])
        print(f"Suggested next step: confirm the live helper surface first; missing repo paths: {joined}")
        return
    joined = ", ".join(result["missing_contract_paths"])
    print(
        "Suggested next step: update scripts/check_issue3_saved_memory_inputs.py "
        f"so REQUIRED_RESTORED_HELPER_FILES includes the missing live helper-surface paths: {joined}"
    )


class SavedMemoryHelperSurfaceContractTests(unittest.TestCase):
    def make_repo(
        self,
        root: Path,
        *,
        included_contract_paths: set[str],
        live_paths: set[str],
    ) -> Path:
        repo_root = root / "browser"
        target_script = repo_root / TARGET_SCRIPT
        target_script.parent.mkdir(parents=True, exist_ok=True)
        lines = [f'    ("{path}", "label"),' for path in sorted(included_contract_paths)]
        constant_entries = "\n".join(lines)
        target_script.write_text(
            (
                "REQUIRED_RESTORED_HELPER_FILES = (\n"
                f"{constant_entries}\n"
                ")\n"
            ),
            encoding="utf-8",
        )
        for relative_path in live_paths:
            live_path = repo_root / relative_path
            live_path.parent.mkdir(parents=True, exist_ok=True)
            live_path.write_text("live", encoding="utf-8")
        return repo_root

    def test_extract_required_helper_paths_reads_literal_tuple(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            script_path = Path(tmpdir) / "helper.py"
            script_path.write_text(
                'REQUIRED_RESTORED_HELPER_FILES = (("a", "one"), ("b", "two"))\n',
                encoding="utf-8",
            )
            self.assertEqual(
                extract_required_helper_paths(script_path, "REQUIRED_RESTORED_HELPER_FILES"),
                {"a", "b"},
            )

    def test_collect_results_passes_when_live_paths_and_contract_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            live_paths = {path for path, _reason in EXPECTED_HELPER_SURFACE_PATHS}
            repo_root = self.make_repo(
                Path(tmpdir),
                included_contract_paths=live_paths,
                live_paths=live_paths,
            )
            result = collect_results(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_live_paths"], [])
            self.assertEqual(result["missing_contract_paths"], [])

    def test_collect_results_reports_missing_contract_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            live_paths = {path for path, _reason in EXPECTED_HELPER_SURFACE_PATHS}
            included = live_paths - {
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "scripts/linux/show_issue3_progress_tracker_route.sh",
            }
            repo_root = self.make_repo(
                Path(tmpdir),
                included_contract_paths=included,
                live_paths=live_paths,
            )
            result = collect_results(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(result["missing_live_paths"], [])
            self.assertIn("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", result["missing_contract_paths"])
            self.assertIn(
                "scripts/linux/show_issue3_progress_tracker_route.sh",
                result["missing_contract_paths"],
            )

    def test_collect_results_reports_missing_live_paths_separately(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            live_paths = {path for path, _reason in EXPECTED_HELPER_SURFACE_PATHS} - {
                "scripts/linux/show_issue3_windows_runtime_handoff_route.sh"
            }
            included = {path for path, _reason in EXPECTED_HELPER_SURFACE_PATHS}
            repo_root = self.make_repo(
                Path(tmpdir),
                included_contract_paths=included,
                live_paths=live_paths,
            )
            result = collect_results(repo_root)
            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/linux/show_issue3_windows_runtime_handoff_route.sh",
                result["missing_live_paths"],
            )
            self.assertEqual(result["missing_contract_paths"], [])

    def test_collect_results_reports_missing_target_script(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            result = collect_results(repo_root)
            self.assertFalse(result["ok"])
            self.assertFalse(result["target_script_exists"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedMemoryHelperSurfaceContractTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(
            json.dumps(
                {"profile": "issue11-saved-memory-helper-surface-contract", **result},
                indent=2,
            )
        )
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())