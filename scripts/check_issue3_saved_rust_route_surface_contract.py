#!/usr/bin/env python3

"""Check the issue #11 saved-Rust helper surface contract.

This helper gives Linux/WSL headed-mode re-entry runs one focused check for the
saved-Rust helper chain described by issue #11. It verifies that the branch's
saved-Rust route references are present in the route note and route printer, and
that the restored-helper-surface carriers still include the same helper files.

The goal is to fail fast on route drift or partial helper-surface updates before
future runs trust a restored checkout for saved-Rust or broader build-readiness
work.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


EXPECTED_REFERENCES: tuple[tuple[str, tuple[str, ...]], ...] = (
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        (
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
        ),
    ),
    (
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
        (
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/linux/restore_saved_rust_toolchain.sh",
        ),
    ),
    (
        "scripts/check_issue3_saved_memory_inputs.py",
        (
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
        ),
    ),
    (
        "scripts/linux/restore_saved_browser_snapshot.sh",
        (
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
        ),
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Check the issue #11 saved-Rust helper surface contract."
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser repo root (default: current directory)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON instead of human-readable text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused unit tests and exit",
    )
    return parser


def collect_results(repo_root: Path) -> dict[str, object]:
    file_results: list[dict[str, object]] = []
    missing_files: list[str] = []
    missing_references: list[dict[str, object]] = []

    for relative_path, expected_references in EXPECTED_REFERENCES:
        target = repo_root / relative_path
        exists = target.is_file()
        missing = []
        if exists:
            content = target.read_text(encoding="utf-8")
            missing = [reference for reference in expected_references if reference not in content]
        else:
            missing_files.append(relative_path)
            missing = list(expected_references)

        if missing:
            missing_references.append(
                {
                    "path": relative_path,
                    "missing_references": missing,
                }
            )

        file_results.append(
            {
                "path": relative_path,
                "exists": exists,
                "missing_references": missing,
                "ok": exists and not missing,
            }
        )

    ok = not missing_files and not missing_references
    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "file_results": file_results,
        "missing_files": missing_files,
        "missing_references": missing_references,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print("Issue #11 saved-Rust helper surface contract:")
    for entry in result["file_results"]:
        status = "PASS" if entry["ok"] else "FAIL"
        print(f"  [{status}] {entry['path']}")
        if not entry["exists"]:
            print("         file is missing")
        elif entry["missing_references"]:
            joined = ", ".join(entry["missing_references"])
            print(f"         missing references: {joined}")

    if result["ok"]:
        print("Saved-Rust helper surface contract passed.")
        return

    print("Saved-Rust helper surface contract failed.", file=sys.stderr)
    print(
        "Suggested next step: add the missing saved-Rust candidate helpers to the restored-helper-surface carriers before trusting issue #11 saved-Rust or broader Linux build-readiness re-entry.",
        file=sys.stderr,
    )


class SavedRustSurfaceContractTests(unittest.TestCase):
    def write_expected_files(self, root: Path) -> None:
        for relative_path, references in EXPECTED_REFERENCES:
            target = root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            body = "\n".join(references) + "\n"
            target.write_text(body, encoding="utf-8")

    def test_collect_results_passes_when_all_references_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self.write_expected_files(repo_root)

            result = collect_results(repo_root)

            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_files"], [])
            self.assertEqual(result["missing_references"], [])

    def test_collect_results_flags_missing_references(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self.write_expected_files(repo_root)
            target = repo_root / "scripts/check_issue3_saved_memory_inputs.py"
            target.write_text("scripts/check_issue3_saved_rust_archive_candidates.py\n", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            missing = {
                entry["path"]: entry["missing_references"] for entry in result["missing_references"]
            }
            self.assertIn("scripts/check_issue3_saved_memory_inputs.py", missing)
            self.assertEqual(
                missing["scripts/check_issue3_saved_memory_inputs.py"],
                ["scripts/check_issue3_staged_rust_toolchain_candidates.py"],
            )

    def test_collect_results_flags_missing_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self.write_expected_files(repo_root)
            (repo_root / "scripts/linux/restore_saved_browser_snapshot.sh").unlink()

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/linux/restore_saved_browser_snapshot.sh",
                result["missing_files"],
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedRustSurfaceContractTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(
            json.dumps(
                {
                    "profile": "issue11-saved-rust-helper-surface-contract",
                    **result,
                },
                indent=2,
            )
        )
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
