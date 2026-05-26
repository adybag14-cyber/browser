#!/usr/bin/env python3

"""Check whether issue #11 re-entry inventories still point at live helpers.

This helper is intentionally narrow. It confirms that the current issue #11
Linux/WSL re-entry surface still references the real branch-local tracker,
nested-workspace root-discovery helpers, saved Rust and Zig candidate helpers,
the build-readiness rerun helper, and the route docs that hand runs back
through the live Linux/WSL helper surface instead of stale helper names.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


FILES = {
    "saved_memory_helper": "scripts/check_issue3_saved_memory_inputs.py",
    "restored_checkout_helper": "scripts/check_issue3_restored_checkout.py",
    "restore_helper": "scripts/linux/restore_saved_browser_snapshot.sh",
    "progress_tracker_route": "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
    "restored_helper_sync_route": "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
    "saved_rust_build_readiness_route": "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md",
    "linux_build_readiness_route": "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
    "zig_toolchain_recovery_route": "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
}

REQUIRED_FRAGMENTS: tuple[tuple[str, tuple[str, ...], str], ...] = (
    (
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        (
            "saved_memory_helper",
            "restored_checkout_helper",
            "restore_helper",
            "restored_helper_sync_route",
            "saved_rust_build_readiness_route",
            "linux_build_readiness_route",
        ),
        "Issue #11 progress-tracker route guidance should stay visible across the re-entry inventory surfaces.",
    ),
    (
        "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
        ("progress_tracker_route", "saved_rust_build_readiness_route"),
        "The progress-tracker and saved-Rust build-readiness routes should keep the workspace-context route note visible before nested or restored reruns trust default roots.",
    ),
    (
        "scripts/linux/check_issue3_workspace_context_route_surface.sh",
        ("progress_tracker_route", "saved_rust_build_readiness_route"),
        "The progress-tracker and saved-Rust build-readiness routes should keep the workspace-context surface checker visible before nested or restored reruns trust default roots.",
    ),
    (
        "scripts/linux/show_issue3_workspace_context_route.sh",
        ("progress_tracker_route", "saved_rust_build_readiness_route"),
        "The progress-tracker and saved-Rust build-readiness routes should keep the workspace-context route printer visible before nested or restored reruns trust default roots.",
    ),
    (
        "scripts/check_issue3_workspace_context.py",
        ("progress_tracker_route", "saved_rust_build_readiness_route"),
        "The progress-tracker and saved-Rust build-readiness routes should keep the workspace-context helper visible before nested or restored reruns rebuild shared-root overrides by hand.",
    ),
    (
        "scripts/check_issue3_saved_rust_archive_candidates.py",
        (
            "saved_memory_helper",
            "restored_checkout_helper",
            "restore_helper",
            "progress_tracker_route",
            "saved_rust_build_readiness_route",
        ),
        "Saved Rust archive candidate discovery should stay visible across the reusable helper inventories and route notes.",
    ),
    (
        "scripts/check_issue3_staged_rust_toolchain_candidates.py",
        (
            "saved_memory_helper",
            "restored_checkout_helper",
            "restore_helper",
            "progress_tracker_route",
            "saved_rust_build_readiness_route",
        ),
        "Staged Rust toolchain candidate discovery should stay visible across the reusable helper inventories and route notes.",
    ),
    (
        "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
        (
            "saved_memory_helper",
            "restored_checkout_helper",
            "progress_tracker_route",
            "saved_rust_build_readiness_route",
        ),
        "The progress-tracker and saved-Rust build-readiness route notes should keep the nested-workspace saved-Memory preflight helper visible before Rust archive selection or restore work widens.",
    ),
    (
        "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md",
        (
            "saved_memory_helper",
            "restored_checkout_helper",
            "progress_tracker_route",
            "saved_rust_build_readiness_route",
        ),
        "The progress-tracker and saved-Rust build-readiness route notes should keep the staged-Rust route note visible before archive restore is retried.",
    ),
    (
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
        ("progress_tracker_route", "saved_rust_build_readiness_route"),
        "The progress-tracker and saved-Rust build-readiness route notes should keep the saved-Rust toolchain route note visible before raw restore exports are retried.",
    ),
    (
        "scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh",
        (
            "saved_memory_helper",
            "restored_checkout_helper",
            "progress_tracker_route",
            "saved_rust_build_readiness_route",
        ),
        "The progress-tracker and saved-Rust build-readiness route notes should keep the staged-Rust route surface check visible before archive restore is retried.",
    ),
    (
        "scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh",
        (
            "saved_memory_helper",
            "restored_checkout_helper",
            "progress_tracker_route",
            "saved_rust_build_readiness_route",
        ),
        "The progress-tracker and saved-Rust build-readiness route notes should keep the staged-Rust route printer visible before archive restore is retried.",
    ),
    (
        "scripts/check_issue3_saved_zig_archive_candidates.py",
        (
            "saved_memory_helper",
            "restored_checkout_helper",
            "restore_helper",
            "progress_tracker_route",
            "linux_build_readiness_route",
            "zig_toolchain_recovery_route",
        ),
        "Saved Zig archive candidate discovery should stay visible across the reusable helper inventories and route notes.",
    ),
    (
        "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
        ("progress_tracker_route", "linux_build_readiness_route"),
        "The progress-tracker and Linux build-readiness routes should keep the saved-Zig route note visible before archive restore work widens.",
    ),
    (
        "scripts/check_issue3_staged_zig_toolchain_candidates.py",
        (
            "saved_memory_helper",
            "restored_checkout_helper",
            "restore_helper",
            "progress_tracker_route",
            "linux_build_readiness_route",
        ),
        "Staged Zig toolchain candidate discovery should stay visible across the restore-side helper inventory and Linux build-readiness route.",
    ),
    (
        "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
        (
            "saved_memory_helper",
            "restored_checkout_helper",
            "progress_tracker_route",
            "linux_build_readiness_route",
        ),
        "The progress-tracker and Linux build-readiness routes should keep the staged-Zig route note visible before archive restore work widens.",
    ),
    (
        "scripts/check_issue3_build_readiness_rerun.py",
        (
            "restored_checkout_helper",
            "restore_helper",
            "progress_tracker_route",
            "linux_build_readiness_route",
        ),
        "The build-readiness rerun helper should stay visible across the restore-side helper inventory and Linux build-readiness route.",
    ),
    (
        "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
        ("saved_memory_helper", "restored_checkout_helper", "restore_helper"),
        "The issue #11 progress-tracker surface checker should stay visible before broader Linux/WSL reruns.",
    ),
    (
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        ("saved_memory_helper", "restored_checkout_helper", "restore_helper"),
        "The issue #11 progress-tracker route printer should stay visible before broader Linux/WSL reruns.",
    ),
    (
        "scripts/check_issue11_saved_memory_helper_contract.py",
        ("restored_checkout_helper", "restore_helper", "restored_helper_sync_route"),
        "The restored-helper sync route should keep the saved-memory helper contract check visible.",
    ),
    (
        "scripts/check_issue11_reentry_inventory_consistency.py",
        ("restored_checkout_helper", "restore_helper", "restored_helper_sync_route"),
        "The restored-helper sync route should keep this issue #11 re-entry inventory check visible.",
    ),
    (
        "scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh",
        (
            "saved_memory_helper",
            "restored_checkout_helper",
            "progress_tracker_route",
            "linux_build_readiness_route",
        ),
        "The progress-tracker and Linux build-readiness routes should keep the staged Zig route surface check visible before restore work widens.",
    ),
    (
        "scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh",
        (
            "saved_memory_helper",
            "restored_checkout_helper",
            "progress_tracker_route",
            "linux_build_readiness_route",
        ),
        "The progress-tracker and Linux build-readiness routes should keep the staged Zig route printer visible before restore work widens.",
    ),
    (
        "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
        (
            "progress_tracker_route",
            "linux_build_readiness_route",
            "zig_toolchain_recovery_route",
        ),
        "The progress-tracker, Linux build-readiness, and Zig recovery routes should keep the saved Zig route surface check visible before archive restore work widens.",
    ),
    (
        "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
        ("progress_tracker_route", "linux_build_readiness_route"),
        "The progress-tracker and Linux build-readiness routes should keep the saved Zig route printer visible before archive restore work widens.",
    ),
    (
        "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
        ("progress_tracker_route", "linux_build_readiness_route", "zig_toolchain_recovery_route"),
        "The progress-tracker, Linux build-readiness, and Zig recovery routes should keep the Zig archive-restore note visible before a saved archive is staged.",
    ),
    (
        "scripts/linux/check_issue3_zig_toolchain_match.sh",
        ("progress_tracker_route", "zig_toolchain_recovery_route"),
        "The progress-tracker and Zig recovery routes should keep the matching-line gate visible before broader readiness reruns are trusted again.",
    ),
    (
        "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
        ("progress_tracker_route", "zig_toolchain_recovery_route"),
        "The progress-tracker and Zig recovery routes should keep the archive-restore surface check visible before a saved Zig archive is staged.",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the issue #11 Linux/WSL re-entry inventories still "
            "point at the current branch-local helper surface."
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


def read_inventory_texts(repo_root: Path) -> dict[str, str]:
    return {
        key: (repo_root / relative_path).read_text(encoding="utf-8")
        for key, relative_path in FILES.items()
    }


def collect_results(repo_root: Path) -> dict[str, object]:
    texts = read_inventory_texts(repo_root)
    checks: list[dict[str, object]] = []
    missing_by_file: dict[str, list[str]] = {}

    for fragment, required_in, purpose in REQUIRED_FRAGMENTS:
        for file_key in required_in:
            exists = fragment in texts[file_key]
            if not exists:
                missing_by_file.setdefault(FILES[file_key], []).append(fragment)
            checks.append(
                {
                    "file_key": file_key,
                    "path": FILES[file_key],
                    "fragment": fragment,
                    "purpose": purpose,
                    "exists": exists,
                }
            )

    return {
        "ok": not missing_by_file,
        "repo_root": str(repo_root),
        "checks": checks,
        "missing_by_file": missing_by_file,
        "required_fragment_count": len(REQUIRED_FRAGMENTS),
        "target_file_count": len(FILES),
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Required fragment checks: {result['required_fragment_count']}")
    print(f"Target files: {result['target_file_count']}")

    for entry in result["checks"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"[{status}] {entry['path']}")
        print(f"  fragment: {entry['fragment']}")
        print(f"  {entry['purpose']}")

    if result["ok"]:
        print("\nIssue #11 re-entry inventory consistency check passed.")
        return

    print("\nIssue #11 re-entry inventory consistency check failed.", file=sys.stderr)
    for path, fragments in result["missing_by_file"].items():
        print(f"  {path}", file=sys.stderr)
        for fragment in fragments:
            print(f"    missing: {fragment}", file=sys.stderr)


def build_fixture_repo(*, missing: dict[str, set[str]] | None = None) -> Path:
    repo_root = Path(tempfile.mkdtemp(prefix="issue11-reentry-inventory-"))
    missing = missing or {}

    for file_key, relative_path in FILES.items():
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        body_lines = []
        for fragment, required_in, _purpose in REQUIRED_FRAGMENTS:
            if file_key not in required_in:
                continue
            if fragment in missing.get(file_key, set()):
                continue
            body_lines.append(fragment)
        target.write_text("\n".join(body_lines) + "\n", encoding="utf-8")

    return repo_root


class Issue11InventoryConsistencyTests(unittest.TestCase):
    def test_passes_when_all_current_fragments_are_present(self) -> None:
        repo_root = build_fixture_repo()
        result = collect_results(repo_root)

        self.assertTrue(result["ok"])
        self.assertEqual(result["missing_by_file"], {})

    def test_flags_missing_saved_rust_fragment(self) -> None:
        repo_root = build_fixture_repo(
            missing={"saved_memory_helper": {"scripts/check_issue3_saved_rust_archive_candidates.py"}}
        )
        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertIn(
            "scripts/check_issue3_saved_memory_inputs.py",
            result["missing_by_file"],
        )
        self.assertIn(
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            result["missing_by_file"]["scripts/check_issue3_saved_memory_inputs.py"],
        )

    def test_flags_missing_issue11_contract_reference(self) -> None:
        repo_root = build_fixture_repo(
            missing={
                "restored_helper_sync_route": {
                    "scripts/check_issue11_reentry_inventory_consistency.py"
                }
            }
        )
        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertIn(
            "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
            result["missing_by_file"],
        )
        self.assertIn(
            "scripts/check_issue11_reentry_inventory_consistency.py",
            result["missing_by_file"]["docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md"],
        )

    def test_flags_missing_issue11_contract_checker_in_restored_checkout_helper(self) -> None:
        repo_root = build_fixture_repo(
            missing={
                "restored_checkout_helper": {
                    "scripts/check_issue11_saved_memory_helper_contract.py"
                }
            }
        )
        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertIn(
            "scripts/check_issue3_restored_checkout.py",
            result["missing_by_file"],
        )
        self.assertIn(
            "scripts/check_issue11_saved_memory_helper_contract.py",
            result["missing_by_file"]["scripts/check_issue3_restored_checkout.py"],
        )

    def test_flags_missing_staged_rust_route_note_in_progress_tracker(self) -> None:
        repo_root = build_fixture_repo(
            missing={
                "progress_tracker_route": {
                    "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md"
                }
            }
        )
        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertIn(
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            result["missing_by_file"],
        )
        self.assertIn(
            "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md",
            result["missing_by_file"]["docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"],
        )

    def test_flags_missing_staged_rust_route_note_in_restored_checkout_helper(self) -> None:
        repo_root = build_fixture_repo(
            missing={
                "restored_checkout_helper": {
                    "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md"
                }
            }
        )
        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertIn(
            "scripts/check_issue3_restored_checkout.py",
            result["missing_by_file"],
        )
        self.assertIn(
            "docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md",
            result["missing_by_file"]["scripts/check_issue3_restored_checkout.py"],
        )

    def test_flags_missing_saved_zig_route_note_in_progress_tracker(self) -> None:
        repo_root = build_fixture_repo(
            missing={
                "progress_tracker_route": {
                    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"
                }
            }
        )
        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertIn(
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            result["missing_by_file"],
        )
        self.assertIn(
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
            result["missing_by_file"]["docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"],
        )

    def test_flags_missing_workspace_context_route_in_progress_tracker(self) -> None:
        repo_root = build_fixture_repo(
            missing={
                "progress_tracker_route": {
                    "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md"
                }
            }
        )
        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertIn(
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            result["missing_by_file"],
        )
        self.assertIn(
            "docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md",
            result["missing_by_file"]["docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"],
        )

    def test_flags_missing_workspace_context_helper_in_saved_rust_build_doc(self) -> None:
        repo_root = build_fixture_repo(
            missing={
                "saved_rust_build_readiness_route": {
                    "scripts/check_issue3_workspace_context.py"
                }
            }
        )
        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertIn(
            "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md",
            result["missing_by_file"],
        )
        self.assertIn(
            "scripts/check_issue3_workspace_context.py",
            result["missing_by_file"]["docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md"],
        )

    def test_flags_missing_nested_workspace_helper_in_saved_rust_build_doc(self) -> None:
        repo_root = build_fixture_repo(
            missing={
                "saved_rust_build_readiness_route": {
                    "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh"
                }
            }
        )
        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertIn(
            "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md",
            result["missing_by_file"],
        )
        self.assertIn(
            "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
            result["missing_by_file"]["docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md"],
        )

    def test_flags_missing_staged_rust_route_surface_in_saved_rust_build_doc(self) -> None:
        repo_root = build_fixture_repo(
            missing={
                "saved_rust_build_readiness_route": {
                    "scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh"
                }
            }
        )
        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertIn(
            "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md",
            result["missing_by_file"],
        )
        self.assertIn(
            "scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh",
            result["missing_by_file"]["docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md"],
        )

    def test_flags_missing_staged_rust_route_surface_in_restored_checkout_helper(self) -> None:
        repo_root = build_fixture_repo(
            missing={
                "restored_checkout_helper": {
                    "scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh"
                }
            }
        )
        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertIn(
            "scripts/check_issue3_restored_checkout.py",
            result["missing_by_file"],
        )
        self.assertIn(
            "scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh",
            result["missing_by_file"]["scripts/check_issue3_restored_checkout.py"],
        )

    def test_flags_missing_archive_restore_route_note_in_zig_recovery_doc(self) -> None:
        repo_root = build_fixture_repo(
            missing={
                "zig_toolchain_recovery_route": {
                    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md"
                }
            }
        )
        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertIn(
            "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
            result["missing_by_file"],
        )
        self.assertIn(
            "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
            result["missing_by_file"]["docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"],
        )

    def test_flags_missing_staged_zig_route_fragment_in_linux_doc(self) -> None:
        repo_root = build_fixture_repo(
            missing={
                "linux_build_readiness_route": {
                    "scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh"
                }
            }
        )
        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertIn(
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
            result["missing_by_file"],
        )
        self.assertIn(
            "scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh",
            result["missing_by_file"]["docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"],
        )

    def test_flags_missing_staged_zig_route_note_in_saved_memory_helper(self) -> None:
        repo_root = build_fixture_repo(
            missing={
                "saved_memory_helper": {
                    "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md"
                }
            }
        )
        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertIn(
            "scripts/check_issue3_saved_memory_inputs.py",
            result["missing_by_file"],
        )
        self.assertIn(
            "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
            result["missing_by_file"]["scripts/check_issue3_saved_memory_inputs.py"],
        )

    def test_flags_missing_nested_workspace_helper_in_restored_checkout_helper(self) -> None:
        repo_root = build_fixture_repo(
            missing={
                "restored_checkout_helper": {
                    "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh"
                }
            }
        )
        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertIn(
            "scripts/check_issue3_restored_checkout.py",
            result["missing_by_file"],
        )
        self.assertIn(
            "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
            result["missing_by_file"]["scripts/check_issue3_restored_checkout.py"],
        )

    def test_flags_missing_staged_zig_route_fragment_in_restored_checkout_helper(self) -> None:
        repo_root = build_fixture_repo(
            missing={
                "restored_checkout_helper": {
                    "scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh"
                }
            }
        )
        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertIn(
            "scripts/check_issue3_restored_checkout.py",
            result["missing_by_file"],
        )
        self.assertIn(
            "scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh",
            result["missing_by_file"]["scripts/check_issue3_restored_checkout.py"],
        )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            Issue11InventoryConsistencyTests
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
