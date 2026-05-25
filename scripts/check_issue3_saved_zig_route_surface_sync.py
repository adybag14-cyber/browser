#!/usr/bin/env python3

"""Check that saved-Zig route surfaces are wired into issue #3 preflights."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


TARGET_FILES: tuple[str, ...] = (
    "scripts/check_issue3_restored_checkout.py",
    "scripts/check_issue3_saved_memory_inputs.py",
)

REQUIRED_ROUTE_ENTRIES: tuple[str, ...] = (
    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
    "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the saved-Zig archive route surface is referenced by the "
            "issue #3 restored-checkout and saved-Memory preflight helpers."
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
        help="Emit structured JSON instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def inspect_target(repo_root: Path, relative_path: str) -> dict[str, object]:
    path = repo_root / relative_path
    result: dict[str, object] = {
        "path": relative_path,
        "exists": path.is_file(),
        "missing_entries": [],
    }
    if not path.is_file():
        return result

    text = path.read_text(encoding="utf-8")
    missing_entries = [
        entry for entry in REQUIRED_ROUTE_ENTRIES if entry not in text
    ]
    result["missing_entries"] = missing_entries
    return result


def collect_results(repo_root: Path) -> dict[str, object]:
    targets = [inspect_target(repo_root, relative_path) for relative_path in TARGET_FILES]
    failures: list[str] = []
    for target in targets:
        if not target["exists"]:
            failures.append(f"missing target file: {target['path']}")
            continue
        missing_entries = target["missing_entries"]
        if missing_entries:
            failures.append(
                f"{target['path']} is missing saved-Zig route entries: "
                + ", ".join(missing_entries)
            )

    return {
        "status": "passed" if not failures else "failed",
        "repo_root": str(repo_root),
        "target_files": targets,
        "required_route_entries": list(REQUIRED_ROUTE_ENTRIES),
        "failures": failures,
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #3 saved-Zig route surface sync")
    print()
    print(f"Repo root: {result['repo_root']}")
    for target in result["target_files"]:
        if not target["exists"]:
            print(f"  [FAIL] {target['path']}: file is missing")
            continue
        missing_entries = target["missing_entries"]
        if missing_entries:
            print(f"  [FAIL] {target['path']}")
            for entry in missing_entries:
                print(f"         missing route entry: {entry}")
        else:
            print(f"  [PASS] {target['path']}")

    if result["failures"]:
        print("\nSaved-Zig route surface sync check failed.", file=sys.stderr)
        for failure in result["failures"]:
            print(f"  - {failure}", file=sys.stderr)
    else:
        print("\nSaved-Zig route surface sync check passed.")


class SavedZigRouteSurfaceSyncTests(unittest.TestCase):
    def test_collect_results_passes_when_targets_include_all_entries(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            for relative_path in TARGET_FILES:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("\n".join(REQUIRED_ROUTE_ENTRIES), encoding="utf-8")

            result = collect_results(repo_root)

            self.assertEqual(result["status"], "passed")
            self.assertEqual(result["failures"], [])

    def test_collect_results_reports_missing_entries(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            target = repo_root / TARGET_FILES[0]
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(REQUIRED_ROUTE_ENTRIES[0], encoding="utf-8")
            other_target = repo_root / TARGET_FILES[1]
            other_target.parent.mkdir(parents=True, exist_ok=True)
            other_target.write_text("\n".join(REQUIRED_ROUTE_ENTRIES), encoding="utf-8")

            result = collect_results(repo_root)

            self.assertEqual(result["status"], "failed")
            self.assertEqual(len(result["failures"]), 1)
            self.assertIn(TARGET_FILES[0], result["failures"][0])
            self.assertIn(REQUIRED_ROUTE_ENTRIES[1], result["failures"][0])

    def test_collect_results_reports_missing_target_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            target = repo_root / TARGET_FILES[0]
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("\n".join(REQUIRED_ROUTE_ENTRIES), encoding="utf-8")

            result = collect_results(repo_root)

            self.assertEqual(result["status"], "failed")
            self.assertEqual(len(result["failures"]), 1)
            self.assertIn(TARGET_FILES[1], result["failures"][0])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedZigRouteSurfaceSyncTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())
