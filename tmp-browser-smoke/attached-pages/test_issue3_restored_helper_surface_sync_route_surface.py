from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md": """
    # Issue #3 Restored Helper-Surface Sync Route

    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
    - `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
    - `docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md`
    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `scripts/check_issue3_restored_helper_surface_sync.py`
    - `scripts/check_issue3_restored_checkout.py`
    - `scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh`
    - `scripts/linux/show_issue3_restored_helper_surface_sync_route.sh`
    - issue `#11` helper surface
    - `--sync-only`
    - `python ./scripts/check_issue3_restored_helper_surface_sync.py`
    """,
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md": """
    # Issue #3 Restored-Checkout Re-entry Route

    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh`
    - `scripts/linux/show_issue3_restored_checkout_reentry_route.sh`
    - `scripts/check_issue3_restored_checkout.py`
    - `scripts/check_issue3_restored_helper_surface_sync.py`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `scripts/check_linux_build_readiness.py`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `python ./scripts/check_issue3_restored_checkout.py`
    - `python ./scripts/check_issue3_restored_helper_surface_sync.py`
    - `python ./scripts/check_issue3_saved_memory_inputs.py`
    - `python ./scripts/check_issue3_saved_archive_integrity.py`
    - `bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
    - `docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md`
    - `scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh`
    - `scripts/linux/show_issue3_restored_checkout_reentry_route.sh`
    - `scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh`
    - `scripts/linux/show_issue3_restored_helper_surface_sync_route.sh`
    - `scripts/check_issue3_restored_checkout.py`
    - `scripts/check_issue3_restored_helper_surface_sync.py`
    - `restore_saved_browser_snapshot.sh --sync-only`
    - `python ./scripts/check_issue3_restored_checkout.py`
    - `python ./scripts/check_issue3_restored_helper_surface_sync.py`
    - `bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh`
    """,
    "scripts/check_issue3_restored_helper_surface_sync.py": """
    REQUIRED_REENTRY_ROUTE_FILES: tuple[tuple[str, str], ...] = (
        ("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "issue #11 tracker route"),
        ("docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md", "saved Zig archive candidates route"),
        ("docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md", "saved Rust toolchain route"),
        ("docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md", "restored helper-surface sync route note"),
        ("scripts/check_issue3_restored_helper_surface_sync.py", "restored helper-surface sync helper"),
        ("scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh", "restored helper-surface sync route surface checker"),
        ("scripts/linux/show_issue3_restored_helper_surface_sync_route.sh", "restored helper-surface sync route helper"),
        ("scripts/linux/show_issue3_windows_runtime_handoff_route.sh", "Linux-to-Windows runtime handoff helper"),
    )
    "missing_in_restored"
    "drifted_files"
    "Refresh the restored checkout helper surface from the live branch-local helper root"
    """,
    "scripts/check_issue3_restored_checkout.py": """
    HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
        ("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "issue #11 progress-tracker route note"),
        ("docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md", "workspace-context route note"),
        ("docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md", "saved-Memory inputs route note"),
        ("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness note"),
        ("docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md", "saved Rust toolchain note"),
        ("docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md", "saved Zig archive candidates route note"),
        ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
        ("scripts/check_issue3_saved_archive_integrity.py", "saved-archive integrity helper"),
        ("scripts/check_issue3_saved_rust_archive_candidates.py", "saved Rust archive candidate helper"),
        ("scripts/check_issue3_staged_rust_toolchain_candidates.py", "staged Rust toolchain candidate helper"),
        ("scripts/check_issue3_saved_zig_archive_candidates.py", "saved Zig archive candidate helper"),
        ("scripts/check_issue3_staged_zig_toolchain_candidates.py", "staged Zig toolchain candidate helper"),
        ("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper"),
        ("scripts/check_issue3_restored_helper_surface_sync.py", "restored helper-surface sync helper"),
        ("scripts/linux/check_issue3_progress_tracker_route_surface.sh", "issue #11 progress-tracker route surface check"),
        ("scripts/linux/show_issue3_progress_tracker_route.sh", "issue #11 progress-tracker route printer"),
        ("scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh", "saved Zig archive candidates route surface check"),
        ("scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh", "saved Zig archive candidates route printer"),
        ("scripts/linux/check_issue3_zig_toolchain_match.sh", "Zig toolchain matching-line gate"),
        ("scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh", "Zig toolchain archive-restore surface check"),
        ("scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh", "Windows runtime handoff surface check"),
        ("scripts/windows/start_attached_pages_catalog.ps1", "Windows attached-pages catalog launcher"),
    )
    "Suggested next step: rerun restore_saved_browser_snapshot.sh with --sync-helper-surface or keep using the live helper root for follow-up commands."
    "Suggested next step: refresh the restored helper surface from the live helper checkout with restore_saved_browser_snapshot.sh --sync-only, then rerun this helper with --helper-root."
    "Restored checkout check passed."
    """,
    "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh": """
    Usage:
      bash scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh \
        [--repo-root /path/to/browser-repo] \
        [--json]
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|file|Read-first note for comparing a restored checkout helper surface against the live issue #11 helper root."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|Broader restored-checkout re-entry note that should hand runs into this narrower sync route."
    "scripts/check_issue3_restored_helper_surface_sync.py|file|Narrower restored-helper comparison helper that reports missing or drifted issue #11 route files."
    "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh|file|Fail-fast surface checker for this restored-helper sync route."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|file|Compact route printer for this restored-helper sync route."
    "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper that should stay visible when the next fix is a --sync-only refresh."
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|check_issue3_restored_helper_surface_sync.py|The route note keeps the narrower sync helper visible."
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|check_issue3_restored_helper_surface_sync.py|The broader restored-checkout route still points runs at the narrower sync helper."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|sync_check|The route printer JSON output exposes the sync-check command explicitly."
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|sync_refresh|The route printer JSON output exposes the sync-refresh command explicitly."
    "All restored-helper-surface sync route surfaces are present."
    """,
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh": """
    Usage:
      bash scripts/linux/show_issue3_restored_helper_surface_sync_route.sh \
        [--helper-root /path/to/live/browser] \
        [--restored-root /path/to/browser-memory-snapshot] \
        [--memory-root /path/to/workspace/memory] \
        [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
        [--json]
    "route_surface"
    "sync_check"
    "sync_refresh"
    "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    "Run the route surface first"
    "Use the sync-only refresh when the restored checkout already exists"
    "Issue #11 Linux/WSL restored helper-surface sync route for issue #3 re-entry"
    "Narrower helper-surface sync check:"
    "In-place helper-surface refresh when the restored checkout is stale:"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-restored-helper-sync-route-")
    )
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3RestoredHelperSurfaceSyncRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.route_note = read_text(
            cls.repo_root / "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md"
        )
        cls.restored_route = read_text(
            cls.repo_root / "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"
        )
        cls.build_readiness_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.sync_helper = read_text(
            cls.repo_root / "scripts/check_issue3_restored_helper_surface_sync.py"
        )
        cls.restored_checkout_helper = read_text(
            cls.repo_root / "scripts/check_issue3_restored_checkout.py"
        )
        cls.surface_checker = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh"
        )

    def test_route_note_keeps_sync_check_refresh_and_issue11_scope_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "scripts/check_issue3_restored_helper_surface_sync.py",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh",
            "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh",
            "issue `#11` helper surface",
            "--sync-only",
            "python ./scripts/check_issue3_restored_helper_surface_sync.py",
        ):
            self.assertIn(fragment, self.route_note)

    def test_broader_restored_checkout_route_keeps_narrower_sync_gate_ordered_before_wider_followups(self) -> None:
        for fragment in (
            "scripts/check_issue3_restored_checkout.py",
            "scripts/check_issue3_restored_helper_surface_sync.py",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "python ./scripts/check_issue3_restored_checkout.py",
            "python ./scripts/check_issue3_restored_helper_surface_sync.py",
            "python ./scripts/check_issue3_saved_memory_inputs.py",
            "python ./scripts/check_issue3_saved_archive_integrity.py",
            "bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
        ):
            self.assertIn(fragment, self.restored_route)

        restored_index = self.restored_route.index(
            "python ./scripts/check_issue3_restored_checkout.py"
        )
        sync_index = self.restored_route.index(
            "python ./scripts/check_issue3_restored_helper_surface_sync.py"
        )
        saved_memory_index = self.restored_route.index(
            "python ./scripts/check_issue3_saved_memory_inputs.py"
        )
        saved_archive_index = self.restored_route.index(
            "python ./scripts/check_issue3_saved_archive_integrity.py"
        )
        build_index = self.restored_route.index(
            "bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        runtime_index = self.restored_route.index(
            "bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
        )
        self.assertLess(restored_index, sync_index)
        self.assertLess(sync_index, saved_memory_index)
        self.assertLess(saved_memory_index, saved_archive_index)
        self.assertLess(saved_archive_index, build_index)
        self.assertLess(build_index, runtime_index)

    def test_build_readiness_route_keeps_restored_checkout_and_sync_routes_visible_before_wider_followups(self) -> None:
        for fragment in (
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
            "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh",
            "scripts/linux/show_issue3_restored_checkout_reentry_route.sh",
            "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh",
            "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/check_issue3_restored_helper_surface_sync.py",
            "restore_saved_browser_snapshot.sh --sync-only",
            "python ./scripts/check_issue3_restored_checkout.py",
            "python ./scripts/check_issue3_restored_helper_surface_sync.py",
            "bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh",
        ):
            self.assertIn(fragment, self.build_readiness_note)

        restored_index = self.build_readiness_note.index(
            "python ./scripts/check_issue3_restored_checkout.py"
        )
        sync_index = self.build_readiness_note.index(
            "python ./scripts/check_issue3_restored_helper_surface_sync.py"
        )
        build_index = self.build_readiness_note.index(
            "bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh"
        )
        self.assertLess(restored_index, sync_index)
        self.assertLess(sync_index, build_index)

    def test_sync_helper_keeps_required_issue11_route_surface_catalog_visible(self) -> None:
        for fragment in (
            '("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "issue #11 tracker route")',
            '("docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md", "saved Zig archive candidates route")',
            '("docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md", "saved Rust toolchain route")',
            '("docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md", "restored helper-surface sync route note")',
            '("scripts/check_issue3_restored_helper_surface_sync.py", "restored helper-surface sync helper")',
            '("scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh", "restored helper-surface sync route surface checker")',
            '("scripts/linux/show_issue3_restored_helper_surface_sync_route.sh", "restored helper-surface sync route helper")',
            '("scripts/linux/show_issue3_windows_runtime_handoff_route.sh", "Linux-to-Windows runtime handoff helper")',
            '"missing_in_restored"',
            '"drifted_files"',
            "Refresh the restored checkout helper surface from the live branch-local helper root",
        ):
            self.assertIn(fragment, self.sync_helper)

    def test_restored_checkout_helper_keeps_issue11_surface_catalog_and_sync_guidance_visible(self) -> None:
        for fragment in (
            '("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "issue #11 progress-tracker route note")',
            '("docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md", "workspace-context route note")',
            '("docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md", "saved-Memory inputs route note")',
            '("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness note")',
            '("docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md", "saved Rust toolchain note")',
            '("docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md", "saved Zig archive candidates route note")',
            '("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper")',
            '("scripts/check_issue3_saved_archive_integrity.py", "saved-archive integrity helper")',
            '("scripts/check_issue3_saved_rust_archive_candidates.py", "saved Rust archive candidate helper")',
            '("scripts/check_issue3_staged_rust_toolchain_candidates.py", "staged Rust toolchain candidate helper")',
            '("scripts/check_issue3_saved_zig_archive_candidates.py", "saved Zig archive candidate helper")',
            '("scripts/check_issue3_staged_zig_toolchain_candidates.py", "staged Zig toolchain candidate helper")',
            '("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper")',
            '("scripts/check_issue3_restored_helper_surface_sync.py", "restored helper-surface sync helper")',
            '("scripts/linux/check_issue3_progress_tracker_route_surface.sh", "issue #11 progress-tracker route surface check")',
            '("scripts/linux/show_issue3_progress_tracker_route.sh", "issue #11 progress-tracker route printer")',
            '("scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh", "saved Zig archive candidates route surface check")',
            '("scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh", "saved Zig archive candidates route printer")',
            '("scripts/linux/check_issue3_zig_toolchain_match.sh", "Zig toolchain matching-line gate")',
            '("scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh", "Zig toolchain archive-restore surface check")',
            '("scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh", "Windows runtime handoff surface check")',
            '("scripts/windows/start_attached_pages_catalog.ps1", "Windows attached-pages catalog launcher")',
            "Suggested next step: rerun restore_saved_browser_snapshot.sh with --sync-helper-surface or keep using the live helper root for follow-up commands.",
            "Suggested next step: refresh the restored helper surface from the live helper checkout with restore_saved_browser_snapshot.sh --sync-only, then rerun this helper with --helper-root.",
            "Restored checkout check passed.",
        ):
            self.assertIn(fragment, self.restored_checkout_helper)

    def test_surface_checker_and_route_printer_keep_sync_route_contracts_visible(self) -> None:
        for fragment in (
            "--repo-root /path/to/browser-repo",
            "--json",
            "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|file|Read-first note for comparing a restored checkout helper surface against the live issue #11 helper root.",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|Broader restored-checkout re-entry note that should hand runs into this narrower sync route.",
            "scripts/check_issue3_restored_helper_surface_sync.py|file|Narrower restored-helper comparison helper that reports missing or drifted issue #11 route files.",
            "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh|file|Fail-fast surface checker for this restored-helper sync route.",
            "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|file|Compact route printer for this restored-helper sync route.",
            "scripts/linux/restore_saved_browser_snapshot.sh|file|Restore helper that should stay visible when the next fix is a --sync-only refresh.",
            "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|check_issue3_restored_helper_surface_sync.py|The route note keeps the narrower sync helper visible.",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|check_issue3_restored_helper_surface_sync.py|The broader restored-checkout route still points runs at the narrower sync helper.",
            "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|sync_check|The route printer JSON output exposes the sync-check command explicitly.",
            "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|sync_refresh|The route printer JSON output exposes the sync-refresh command explicitly.",
            "All restored-helper-surface sync route surfaces are present.",
        ):
            self.assertIn(fragment, self.surface_checker)

        for fragment in (
            "--helper-root /path/to/live/browser",
            "--restored-root /path/to/browser-memory-snapshot",
            "--memory-root /path/to/workspace/memory",
            "--archive /path/to/01-browser-fork-headed-mode-foundation.zip",
            "--json",
            '"route_surface"',
            '"sync_check"',
            '"sync_refresh"',
            '"docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md"',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"',
            '"docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"',
            '"docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            '"Run the route surface first',
            '"Use the sync-only refresh when the restored checkout already exists',
            "Issue #11 Linux/WSL restored helper-surface sync route for issue #3 re-entry",
            "Narrower helper-surface sync check:",
            "In-place helper-surface refresh when the restored checkout is stale:",
        ):
            self.assertIn(fragment, self.route_printer)


if __name__ == "__main__":
    unittest.main()
