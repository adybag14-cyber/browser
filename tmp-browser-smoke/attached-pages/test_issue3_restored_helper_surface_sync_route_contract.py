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
    - `bash ./scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh`
    - `bash ./scripts/linux/show_issue3_restored_helper_surface_sync_route.sh`
    - `python ./scripts/check_issue3_restored_helper_surface_sync.py`
    - `restore_saved_browser_snapshot.sh`
    - `--sync-only`
    - `helper-surface refresh`
    """,
    "scripts/check_issue3_restored_helper_surface_sync.py": """
    REQUIRED_REENTRY_ROUTE_FILES = (
        ("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "issue #11 tracker route"),
        ("docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md", "saved Zig archive candidates route"),
        ("docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md", "saved Rust toolchain route"),
        ("docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md", "restored helper-surface sync route note"),
        ("scripts/check_issue3_restored_helper_surface_sync.py", "restored helper-surface sync helper"),
        ("scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh", "saved-memory route surface checker"),
        ("scripts/linux/show_issue3_saved_memory_inputs_route.sh", "saved-memory route helper"),
        ("scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh", "saved Zig archive candidates surface checker"),
        ("scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh", "saved Zig archive candidates route helper"),
        ("scripts/check_issue3_saved_zig_archive_candidates.py", "saved Zig archive candidates helper"),
        ("scripts/check_issue3_saved_rust_archive_candidates.py", "saved Rust archive candidates helper"),
        ("scripts/check_issue3_staged_rust_toolchain_candidates.py", "staged Rust toolchain candidates helper"),
        ("scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh", "saved Rust toolchain route surface checker"),
        ("scripts/linux/show_issue3_saved_rust_toolchain_route.sh", "saved Rust toolchain route helper"),
        ("scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh", "restored helper-surface sync route surface checker"),
        ("scripts/linux/show_issue3_restored_helper_surface_sync_route.sh", "restored helper-surface sync route helper"),
        ("scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh", "Zig archive restore route helper"),
        ("scripts/linux/show_issue3_windows_runtime_handoff_route.sh", "Linux-to-Windows runtime handoff helper"),
    )
    print("Restored helper surface sync passed.")
    print("Refresh the restored checkout helper surface from the live branch-local helper root")
    """,
    "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh": r"""
    REFERENCE_PATHS=(
        "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|file|"
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|"
        "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|"
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|file|"
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|"
        "scripts/check_issue3_restored_helper_surface_sync.py|file|"
        "scripts/check_issue3_restored_checkout.py|file|"
        "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh|file|"
        "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|file|"
        "scripts/linux/restore_saved_browser_snapshot.sh|file|"
    )
    CONTENT_EXPECTATIONS=(
        "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|check_issue3_restored_helper_surface_sync_route_surface.sh|"
        "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|show_issue3_restored_helper_surface_sync_route.sh|"
        "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|check_issue3_restored_helper_surface_sync.py|"
        "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|restore_saved_browser_snapshot.sh|"
        "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|check_issue3_restored_helper_surface_sync.py|"
        "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|check_issue3_restored_helper_surface_sync.py|"
        "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|restore_saved_browser_snapshot.sh|"
        "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|sync_check|"
        "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|sync_refresh|"
    )
    """,
    "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh": """
    "issue": "Issue #11 Linux/WSL restored helper-surface sync route for issue #3 re-entry",
    "read_first": [
        "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    ],
    "commands": {
        "route_surface": "bash /tmp/browser/scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh --repo-root /tmp/browser",
        "sync_check": "python /tmp/browser/scripts/check_issue3_restored_helper_surface_sync.py --helper-root /tmp/browser --restored-root /tmp/browser-memory-snapshot",
        "sync_refresh": "bash /tmp/browser/scripts/linux/restore_saved_browser_snapshot.sh --browser-root /tmp/browser --helper-root /tmp/browser --memory-root /tmp/memory --archive /tmp/memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip --destination /tmp/browser-memory-snapshot --sync-only"
    },
    "notes": [
        "Run the route surface first so missing route files fail before the restored checkout is trusted as its own helper root.",
        "Run the narrower sync check after the broader restored-checkout readiness check and before saved-memory, saved-archive, build-readiness, or runtime follow-up helpers are trusted from the restored checkout.",
        "Use the sync-only refresh when the restored checkout already exists and only the helper surface needs to be repaired in place."
    ]
    Narrower helper-surface sync check:
    In-place helper-surface refresh when the restored checkout is stale:
    """,
    "scripts/linux/restore_saved_browser_snapshot.sh": """
    --sync-helper-surface
    --sync-only
    if [[ "${SYNC_ONLY}" == "true" ]]; then
        SYNC_HELPER_SURFACE=true
    fi
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(
        tempfile.mkdtemp(prefix="lightpanda-restored-helper-sync-contract-")
    )
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3RestoredHelperSurfaceSyncRouteContractTest(unittest.TestCase):
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
        cls.sync_helper = read_text(
            cls.repo_root / "scripts/check_issue3_restored_helper_surface_sync.py"
        )
        cls.route_surface = read_text(
            cls.repo_root
            / "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root
            / "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )

    def test_route_note_keeps_sync_surface_check_and_refresh_path_visible(self) -> None:
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
            self.assertIn(fragment, self.route_note)

    def test_sync_helper_keeps_issue11_drift_watch_list_in_scope(self) -> None:
        for fragment in (
            "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
            "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
            "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
            "scripts/check_issue3_saved_zig_archive_candidates.py",
            "scripts/check_issue3_saved_rust_archive_candidates.py",
            "scripts/check_issue3_staged_rust_toolchain_candidates.py",
            "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
            "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            "scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh",
            "scripts/linux/show_issue3_restored_helper_surface_sync_route.sh",
            "scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh",
            "scripts/linux/show_issue3_windows_runtime_handoff_route.sh",
            "Restored helper surface sync passed.",
            "Refresh the restored checkout helper surface from the live branch-local helper root",
        ):
            self.assertIn(fragment, self.sync_helper)

    def test_route_surface_guard_keeps_json_route_keys_and_refresh_dependency_visible(self) -> None:
        for fragment in (
            '"docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|file|"',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file|"',
            '"docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file|"',
            '"docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md|file|"',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file|"',
            '"scripts/check_issue3_restored_helper_surface_sync.py|file|"',
            '"scripts/check_issue3_restored_checkout.py|file|"',
            '"scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh|file|"',
            '"scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|file|"',
            '"scripts/linux/restore_saved_browser_snapshot.sh|file|"',
            '"docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|check_issue3_restored_helper_surface_sync_route_surface.sh|"',
            '"docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|show_issue3_restored_helper_surface_sync_route.sh|"',
            '"docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|check_issue3_restored_helper_surface_sync.py|"',
            '"docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md|restore_saved_browser_snapshot.sh|"',
            '"docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|check_issue3_restored_helper_surface_sync.py|"',
            '"scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|check_issue3_restored_helper_surface_sync.py|"',
            '"scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|restore_saved_browser_snapshot.sh|"',
            '"scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|sync_check|"',
            '"scripts/linux/show_issue3_restored_helper_surface_sync_route.sh|sync_refresh|"',
        ):
            self.assertIn(fragment, self.route_surface)

    def test_route_printer_keeps_issue11_json_contract_and_sync_only_refresh_command(self) -> None:
        for fragment in (
            '"issue": "Issue #11 Linux/WSL restored helper-surface sync route for issue #3 re-entry"',
            '"docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md"',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"',
            '"docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"',
            '"docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"',
            '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"',
            '"route_surface":',
            "check_issue3_restored_helper_surface_sync_route_surface.sh",
            '"sync_check":',
            "check_issue3_restored_helper_surface_sync.py",
            '"sync_refresh":',
            "restore_saved_browser_snapshot.sh",
            "--sync-only",
            "Run the route surface first",
            "Use the sync-only refresh when the restored checkout already exists",
            "Narrower helper-surface sync check:",
            "In-place helper-surface refresh when the restored checkout is stale:",
        ):
            self.assertIn(fragment, self.route_printer)

    def test_restore_helper_keeps_sync_only_mode_wired_to_sync_helper_surface(self) -> None:
        for fragment in (
            "--sync-helper-surface",
            "--sync-only",
            'if [[ "${SYNC_ONLY}" == "true" ]]; then',
            "SYNC_HELPER_SURFACE=true",
        ):
            self.assertIn(fragment, self.restore_helper)


if __name__ == "__main__":
    unittest.main()
