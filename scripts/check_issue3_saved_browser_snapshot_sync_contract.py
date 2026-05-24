#!/usr/bin/env python3

"""Check the synced saved-browser-snapshot restore contract for issue #3.

This helper guards the branch-local contract around the self-contained restore
path introduced for Linux or WSL follow-up work:

- `--sync-helper-surface` should switch follow-up commands into the restored
  checkout instead of keeping them on the live helper root.
- `--sync-only` should stay visible as the in-place refresh path for an already
  restored checkout.
- the note, restore helper, and route printer should all keep the synced
  restored-checkout, saved-memory, and saved-archive follow-up commands visible.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import textwrap
import unittest


REQUIRED_FILES: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved-browser-snapshot route note"),
    ("scripts/linux/restore_saved_browser_snapshot.sh", "saved-browser-snapshot restore helper"),
    ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved-browser-snapshot route printer"),
    ("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper"),
    ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
    ("scripts/check_issue3_saved_archive_integrity.py", "saved-archive integrity helper"),
)

SYNC_EXPECTATIONS: tuple[tuple[str, str, str], ...] = (
    (
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "--sync-helper-surface",
        "The route note keeps the synced helper-surface restore mode visible.",
    ),
    (
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "--sync-only",
        "The route note keeps the in-place helper-surface refresh mode visible.",
    ),
    (
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface",
        "The route note keeps the synced restored-checkout readiness follow-up visible.",
    ),
    (
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot",
        "The route note keeps the synced saved-archive integrity follow-up visible.",
    ),
    (
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "the saved archive can lag the current branch-local helper surface",
        "The route note explains why the synced helper surface matters.",
    ),
    (
        "scripts/linux/restore_saved_browser_snapshot.sh",
        "if [[ \"${SYNC_ONLY}\" == \"true\" ]]; then\n    SYNC_HELPER_SURFACE=true\nfi",
        "The restore helper still forces helper-surface sync when --sync-only is used.",
    ),
    (
        "scripts/linux/restore_saved_browser_snapshot.sh",
        "FOLLOW_UP_HELPER_ROOT=\"${DESTINATION}\"",
        "The restore helper still pivots follow-up commands into the restored checkout for synced flows.",
    ),
    (
        "scripts/linux/restore_saved_browser_snapshot.sh",
        "python $(format_shell_arg \"${FOLLOW_UP_HELPER_ROOT}/scripts/check_issue3_saved_archive_integrity.py\") --repo-root $(format_shell_arg \"${DESTINATION}\")",
        "The restore helper still emits the synced saved-archive integrity follow-up command.",
    ),
    (
        "scripts/linux/restore_saved_browser_snapshot.sh",
        "python $(format_shell_arg \"${FOLLOW_UP_HELPER_ROOT}/scripts/check_issue3_restored_checkout.py\") --repo-root $(format_shell_arg \"${DESTINATION}\")",
        "The restore helper still emits the synced restored-checkout follow-up command.",
    ),
    (
        "scripts/linux/restore_saved_browser_snapshot.sh",
        "--helper-root $(format_shell_arg \"${HELPER_ROOT}\") --expect-helper-surface",
        "The restore helper still requires helper-root comparison on synced follow-up checks.",
    ),
    (
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "\"follow_up_helper_root\":",
        "The route printer JSON still surfaces the synced follow-up helper root.",
    ),
    (
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "\"sync_restored_checkout_check\":",
        "The route printer JSON still surfaces the synced restored-checkout follow-up command.",
    ),
    (
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "\"sync_saved_archive_integrity\":",
        "The route printer JSON still surfaces the synced saved-archive integrity follow-up command.",
    ),
    (
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "Synced helper-surface refresh command for an existing restored checkout:",
        "The route printer text still keeps the in-place helper refresh path visible.",
    ),
    (
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "Synced restored-checkout readiness check:",
        "The route printer text still keeps the synced restored-checkout follow-up visible.",
    ),
    (
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "Synced saved-archive integrity preflight:",
        "The route printer text still keeps the synced saved-archive integrity follow-up visible.",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the synced saved-browser-snapshot restore contract stays "
            "aligned across the note, restore helper, and route printer."
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
    expectation_results: list[dict[str, object]] = []

    for relative_path, label in REQUIRED_FILES:
        path = repo_root / relative_path
        file_results.append(
            {
                "path": relative_path,
                "label": label,
                "exists": path.is_file(),
            }
        )

    for relative_path, snippet, purpose in SYNC_EXPECTATIONS:
        path = repo_root / relative_path
        exists = False
        if path.is_file():
            exists = snippet in path.read_text(encoding="utf-8")
        expectation_results.append(
            {
                "path": relative_path,
                "snippet": snippet,
                "purpose": purpose,
                "exists": exists,
            }
        )

    ok = all(entry["exists"] for entry in file_results) and all(
        entry["exists"] for entry in expectation_results
    )
    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "required_files": file_results,
        "sync_expectations": expectation_results,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print("Required files:")
    for entry in result["required_files"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['path']}: {entry['label']}")
    print("Synced-route expectations:")
    for entry in result["sync_expectations"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['path']}")
        print(f"         {entry['purpose']}")
    if result["ok"]:
        print("\nSaved-browser-snapshot sync contract check passed.")
    else:
        print("\nSaved-browser-snapshot sync contract check failed.", file=sys.stderr)
        print(
            "Suggested next step: repair the synced restore note or helper surfaces before trusting the self-contained snapshot route again.",
            file=sys.stderr,
        )


def write_file(root: Path, relative_path: str, content: str) -> None:
    target = root / relative_path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(textwrap.dedent(content).lstrip("\n"), encoding="utf-8")


class SavedBrowserSnapshotSyncContractTests(unittest.TestCase):
    def make_repo_root(self) -> Path:
        tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(tempdir.cleanup)
        repo_root = Path(tempdir.name) / "browser"
        repo_root.mkdir()
        for relative_path, _label in REQUIRED_FILES:
            write_file(repo_root, relative_path, "placeholder\n")

        write_file(
            repo_root,
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            """
            --sync-helper-surface
            --sync-only
            python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface
            python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot
            the saved archive can lag the current branch-local helper surface
            """,
        )
        write_file(
            repo_root,
            "scripts/linux/restore_saved_browser_snapshot.sh",
            """
            if [[ "${SYNC_ONLY}" == "true" ]]; then
                SYNC_HELPER_SURFACE=true
            fi
            FOLLOW_UP_HELPER_ROOT="${DESTINATION}"
            python $(format_shell_arg "${FOLLOW_UP_HELPER_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${DESTINATION}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface
            python $(format_shell_arg "${FOLLOW_UP_HELPER_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${DESTINATION}")
            """,
        )
        write_file(
            repo_root,
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            """
            "follow_up_helper_root":
            "sync_restored_checkout_check":
            "sync_saved_archive_integrity":
            Synced helper-surface refresh command for an existing restored checkout:
            Synced restored-checkout readiness check:
            Synced saved-archive integrity preflight:
            """,
        )
        return repo_root

    def test_collect_results_passes_when_sync_contract_is_present(self) -> None:
        repo_root = self.make_repo_root()
        result = collect_results(repo_root)
        self.assertTrue(result["ok"])

    def test_collect_results_fails_when_sync_only_contract_is_missing(self) -> None:
        repo_root = self.make_repo_root()
        write_file(
            repo_root,
            "scripts/linux/restore_saved_browser_snapshot.sh",
            """
            FOLLOW_UP_HELPER_ROOT="${DESTINATION}"
            python $(format_shell_arg "${FOLLOW_UP_HELPER_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${DESTINATION}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface
            python $(format_shell_arg "${FOLLOW_UP_HELPER_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${DESTINATION}")
            """,
        )
        result = collect_results(repo_root)
        self.assertFalse(result["ok"])
        missing = [entry for entry in result["sync_expectations"] if not entry["exists"]]
        self.assertTrue(
            any("--sync-only" not in entry["snippet"] and "SYNC_ONLY" in entry["snippet"] for entry in missing)
        )

    def test_collect_results_fails_when_synced_archive_followup_is_missing(self) -> None:
        repo_root = self.make_repo_root()
        write_file(
            repo_root,
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            """
            "follow_up_helper_root":
            "sync_restored_checkout_check":
            Synced helper-surface refresh command for an existing restored checkout:
            Synced restored-checkout readiness check:
            """,
        )
        result = collect_results(repo_root)
        self.assertFalse(result["ok"])
        missing = [entry["snippet"] for entry in result["sync_expectations"] if not entry["exists"]]
        self.assertIn("\"sync_saved_archive_integrity\":", missing)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedBrowserSnapshotSyncContractTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_results(repo_root)
    if args.json:
        print(
            json.dumps(
                {
                    "profile": "issue3-saved-browser-snapshot-sync-contract",
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