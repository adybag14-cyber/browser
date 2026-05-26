from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md": """
    # Issue #3 Saved Browser Snapshot Restore Route

    - `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
    - `scripts/linux/restore_saved_browser_snapshot.sh`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
    - `scripts/check_issue3_restored_checkout.py`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `--sync-helper-surface`
    - `--sync-only`
    - `--check-only`
    - `../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py`
    - `../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py`
    - `../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py`
    - `../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - rerun the restore with `--sync-helper-surface`
    """,
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md": """
    # Issue #3 Restored-Checkout Re-entry Route

    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
    - `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
    - `docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md`
    - `scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh`
    - `scripts/linux/show_issue3_restored_checkout_reentry_route.sh`
    - `scripts/check_issue3_restored_checkout.py`
    - `scripts/check_issue3_restored_helper_surface_sync.py`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `scripts/check_linux_build_readiness.py`
    - `scripts/linux/restore_saved_browser_snapshot.sh`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `python ./scripts/check_issue3_restored_checkout.py`
    - `--helper-root .`
    - `--expect-helper-surface`
    - `python ./scripts/check_issue3_restored_helper_surface_sync.py`
    - `python ./scripts/check_issue3_saved_memory_inputs.py`
    - `python ./scripts/check_issue3_saved_archive_integrity.py`
    - `bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    """,
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
    - `bash ./scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh`
    - `bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh`
    - `python ./scripts/check_issue3_restored_helper_surface_sync.py`
    - `restore_saved_browser_snapshot.sh`
    - `--sync-only`
    - `helper-surface refresh`
    """,
    "scripts/linux/restore_saved_browser_snapshot.sh": """
    Usage:
      bash scripts/linux/restore_saved_browser_snapshot.sh \\
        [--browser-root /path/to/browser-repo] \\
        [--helper-root /path/to/live/browser-repo] \\
        [--memory-root /path/to/workspace/memory] \\
        [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \\
        [--destination /path/to/extracted/browser-checkout] \\
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \\
        [--sync-helper-surface] \\
        [--sync-only] \\
        [--check-only] \\
        [--json] \\
        [--force]
    declare -a HELPER_SURFACE_PATHS=(
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
        "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"
        "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md"
        "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md"
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md"
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
        "scripts/check_issue3_saved_memory_inputs.py"
        "scripts/check_issue3_restored_checkout.py"
        "scripts/check_issue3_restored_helper_surface_sync.py"
        "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh"
        "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh"
        "scripts/linux/restore_saved_browser_snapshot.sh"
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
        "scripts/linux/prepare_offline_build_inputs.sh"
    )
    if [[ "${SYNC_ONLY}" == "true" ]]; then
        SYNC_HELPER_SURFACE=true
    fi
    """,
    "scripts/check_issue3_restored_checkout.py": """
    HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
        ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry gate note"),
        ("docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md", "runtime revalidation note"),
        ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved snapshot restore note"),
        ("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md", "restored-checkout re-entry note"),
        ("docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md", "restored helper-surface sync route note"),
        ("docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md", "saved-archive integrity note"),
        ("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "issue #11 progress-tracker route note"),
        ("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness note"),
        ("docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md", "offline build-inputs note"),
        ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
        ("scripts/check_issue3_saved_archive_integrity.py", "saved-archive integrity helper"),
        ("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper"),
        ("scripts/check_issue3_restored_helper_surface_sync.py", "restored helper-surface sync helper"),
        ("scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh", "restored helper-surface sync route surface check"),
        ("scripts/linux/show_issue3_restored_helper_surface_sync_route.sh", "restored helper-surface sync route printer"),
        ("scripts/linux/restore_saved_browser_snapshot.sh", "saved snapshot restore helper"),
        ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved snapshot route printer"),
        ("scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh", "runtime revalidation route printer"),
        ("scripts/linux/prepare_offline_build_inputs.sh", "offline inputs restore helper"),
    )
    parser.add_argument("--helper-root")
    parser.add_argument("--expect-helper-surface")
    "matches_helper_root": None,
    print("Suggested next step: rerun restore_saved_browser_snapshot.sh with --sync-helper-surface or keep using the live helper root for follow-up commands.")
    """,
    "scripts/check_issue3_saved_memory_inputs.py": """
    REQUIRED_MEMORY_FILES = (
        ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
        ("repo_archives/browser/README.md", "saved repo notes"),
        ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
    )
    REQUIRED_RESTORED_HELPER_FILES = (
        ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved-browser-snapshot restore guide"),
        ("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md", "restored-checkout re-entry guide"),
        ("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper"),
        ("scripts/linux/restore_saved_browser_snapshot.sh", "saved-browser-snapshot restore helper"),
        ("scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh", "runtime re-entry route helper"),
    )
    DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-snapshot-route-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedSnapshotRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.snapshot_route = read_text(cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md")
        cls.restored_route = read_text(
            cls.repo_root / "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"
        )
        cls.restored_sync_route = read_text(
            cls.repo_root / "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md"
        )
        cls.restore_script = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )
        cls.restored_helper = read_text(cls.repo_root / "scripts/check_issue3_restored_checkout.py")
    def test_snapshot_route_keeps_synced_restore_refresh_and_followup_commands_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "scripts/linux/restore_saved_browser_snapshot.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "--sync-helper-surface",
            "--sync-only",
            "--check-only",
            "../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py",
            "../browser-memory-snapshot/scripts/check_issue3_saved_memory_inputs.py",
            "../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py",
            "../browser-memory-snapshot/scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "../browser-memory-snapshot/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "rerun the restore with `--sync-helper-surface`",
        ):
            self.assertIn(fragment, self.snapshot_route)

    def test_restored_route_keeps_checkout_before_sync_saved_inputs_and_runtime_reentry(self) -> None:
        for fragment in (
            "scripts/check_issue3_restored_checkout.py",
            "scripts/check_issue3_restored_helper_surface_sync.py",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_linux_build_readiness.py",
            "scripts/linux/restore_saved_browser_snapshot.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "--helper-root .",
            "--expect-helper-surface",
            "python ./scripts/check_issue3_restored_helper_surface_sync.py",
            "python ./scripts/check_issue3_saved_memory_inputs.py",
            "python ./scripts/check_issue3_saved_archive_integrity.py",
            "bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
        ):
            self.assertIn(fragment, self.restored_route)

        restored_index = self.restored_route.index("python ./scripts/check_issue3_restored_checkout.py")
        sync_index = self.restored_route.index("python ./scripts/check_issue3_restored_helper_surface_sync.py")
        saved_memory_index = self.restored_route.index("python ./scripts/check_issue3_saved_memory_inputs.py")
        saved_archive_index = self.restored_route.index("python ./scripts/check_issue3_saved_archive_integrity.py")
        build_index = self.restored_route.index("bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh")
        runtime_index = self.restored_route.index("bash ./scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh")
        self.assertLess(restored_index, sync_index)
        self.assertLess(sync_index, saved_memory_index)
        self.assertLess(saved_memory_index, saved_archive_index)
        self.assertLess(saved_archive_index, build_index)
        self.assertLess(build_index, runtime_index)

    def test_restored_helper_sync_route_keeps_narrower_sync_refresh_path_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "scripts/check_issue3_restored_helper_surface_sync.py",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh",
            "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh",
            "bash ./scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh",
            "bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh",
            "python ./scripts/check_issue3_restored_helper_surface_sync.py",
            "restore_saved_browser_snapshot.sh",
            "--sync-only",
            "helper-surface refresh",
        ):
            self.assertIn(fragment, self.restored_sync_route)

    def test_restore_script_keeps_sync_modes_and_helper_surface_paths_in_scope(self) -> None:
        for fragment in (
            "--browser-root /path/to/browser-repo",
            "--helper-root /path/to/live/browser-repo",
            "--memory-root /path/to/workspace/memory",
            "--archive /path/to/01-browser-fork-headed-mode-foundation.zip",
            "--destination /path/to/extracted/browser-checkout",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--sync-helper-surface",
            "--sync-only",
            "--check-only",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/check_issue3_restored_helper_surface_sync.py",
            "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh",
            "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh",
            "scripts/linux/restore_saved_browser_snapshot.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "scripts/linux/prepare_offline_build_inputs.sh",
            'if [[ "${SYNC_ONLY}" == "true" ]]; then',
            "SYNC_HELPER_SURFACE=true",
        ):
            self.assertIn(fragment, self.restore_script)

    def test_restored_checkout_helper_keeps_synced_surface_contract_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/check_issue3_restored_helper_surface_sync.py",
            "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh",
            "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh",
            "scripts/linux/restore_saved_browser_snapshot.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
            "scripts/linux/prepare_offline_build_inputs.sh",
            "--helper-root",
            "--expect-helper-surface",
            '"matches_helper_root": None',
            "rerun restore_saved_browser_snapshot.sh with --sync-helper-surface",
        ):
            self.assertIn(fragment, self.restored_helper)


if __name__ == "__main__":
    unittest.main()
