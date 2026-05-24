#!/usr/bin/env python3

"""Check the restored-checkout helper-surface contract for issue #3.

This helper guards one narrow branch-local contract: when the saved browser
snapshot route is used in synced helper-surface mode, the restored checkout
should carry the restored-checkout route scripts alongside the broader saved
Memory, archive-integrity, and runtime re-entry helpers.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


TARGET_FILES: tuple[tuple[str, str], ...] = (
    (
        "scripts/check_issue3_saved_memory_inputs.py",
        "saved-memory preflight helper surface",
    ),
    (
        "scripts/check_issue3_restored_checkout.py",
        "restored-checkout readiness helper surface",
    ),
    (
        "scripts/linux/restore_saved_browser_snapshot.sh",
        "saved browser snapshot restore helper surface",
    ),
)

REQUIRED_ROUTE_SNIPPETS: tuple[tuple[str, str], ...] = (
    (
        "scripts/linux/check_issue3_restored_checkout_route_surface.sh",
        "restored-checkout route surface checker",
    ),
    (
        "scripts/linux/show_issue3_restored_checkout_route.sh",
        "restored-checkout route helper",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the issue #3 restored-checkout helper surface keeps its "
            "route scripts synced across the saved-memory, restored-checkout, "
            "and saved-snapshot helpers."
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
    file_results: list[dict[str, object]] = []
    missing_contracts: list[str] = []

    for relative_path, label in TARGET_FILES:
        full_path = repo_root / relative_path
        exists = full_path.is_file()
        text = full_path.read_text(encoding="utf-8") if exists else ""
        snippet_results: list[dict[str, object]] = []
        for snippet, snippet_label in REQUIRED_ROUTE_SNIPPETS:
            present = snippet in text
            snippet_results.append(
                {
                    "snippet": snippet,
                    "label": snippet_label,
                    "present": present,
                }
            )
            if not present:
                missing_contracts.append(f"{relative_path}:{snippet}")
        file_results.append(
            {
                "path": relative_path,
                "label": label,
                "exists": exists,
                "required_snippets": snippet_results,
            }
        )
        if not exists:
            missing_contracts.append(relative_path)

    return {
        "ok": not missing_contracts,
        "repo_root": str(repo_root),
        "files": file_results,
        "missing_contracts": missing_contracts,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print("Restored-checkout helper-surface contract:")
    for entry in result["files"]:
        file_status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{file_status}] {entry['path']}: {entry['label']}")
        for snippet_entry in entry["required_snippets"]:
            snippet_status = "PASS" if snippet_entry["present"] else "FAIL"
            print(
                f"    [{snippet_status}] {snippet_entry['snippet']}: "
                f"{snippet_entry['label']}"
            )

    if result["ok"]:
        print("\nRestored-checkout helper-surface contract passed.")
    else:
        print("\nRestored-checkout helper-surface contract failed.", file=sys.stderr)
        print(
            "Suggested next step: add the restored-checkout route scripts to the "
            "saved-memory, restored-checkout, and saved-snapshot helper surfaces "
            "before treating synced snapshot restores as self-contained.",
            file=sys.stderr,
        )


class RestoredCheckoutHelperSurfaceContractTests(unittest.TestCase):
    def test_collect_results_passes_when_all_targets_carry_route_scripts(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            for relative_path, _label in TARGET_FILES:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(
                    "\n".join(snippet for snippet, _snippet_label in REQUIRED_ROUTE_SNIPPETS),
                    encoding="utf-8",
                )

            result = collect_results(repo_root)

            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_contracts"], [])

    def test_collect_results_fails_when_a_route_script_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            first_snippet, _label = REQUIRED_ROUTE_SNIPPETS[0]
            second_snippet, _label = REQUIRED_ROUTE_SNIPPETS[1]

            for index, (relative_path, _label) in enumerate(TARGET_FILES):
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                payload = first_snippet
                if index != 0:
                    payload += "\n" + second_snippet
                target.write_text(payload, encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/check_issue3_saved_memory_inputs.py:"
                "scripts/linux/show_issue3_restored_checkout_route.sh",
                result["missing_contracts"],
            )

    def test_collect_results_fails_when_a_target_file_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            for relative_path, _label in TARGET_FILES[1:]:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(
                    "\n".join(snippet for snippet, _snippet_label in REQUIRED_ROUTE_SNIPPETS),
                    encoding="utf-8",
                )

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertIn(
                "scripts/check_issue3_saved_memory_inputs.py",
                result["missing_contracts"],
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            RestoredCheckoutHelperSurfaceContractTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(
            json.dumps(
                {"profile": "issue3-restored-checkout-helper-surface-contract", **result},
                indent=2,
            )
        )
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
