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
    - `repo_archives/browser/01-browser-fork-headed-mode-foundation.zip`
    - `bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
    - `bash ./scripts/linux/restore_saved_browser_snapshot.sh --check-only`
    - `bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `python ./scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot`
    - `python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface`
    - `python ./scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot`
    - `python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot`
    - `Run the restored-checkout readiness check first`
    - `Run the saved-archive integrity check immediately after`
    - `--helper-root /path/to/live/browser`
    - `--sync-helper-surface`
    - `Recommended Self-Contained Restore`
    - `the saved archive can lag the current`
    - Do not switch into the restored checkout
    """,
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md": """
    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
    - `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    """,
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
    - `bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    """,
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh": """
    docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file
    docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file
    docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file
    docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file
    docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file
    scripts/linux/restore_saved_browser_snapshot.sh|file
    scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file
    scripts/check_issue3_restored_checkout.py|file
    scripts/check_issue3_saved_memory_inputs.py|file
    scripts/check_issue3_saved_archive_integrity.py|file
    scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|file
    scripts/linux/show_issue3_saved_archive_integrity_route.sh|file
    build.zig.zon|file
    restore_saved_browser_snapshot.sh --check-only
    python ./scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot
    python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface
    Run the restored-checkout readiness check first
    python ./scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot
    python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot
    Run the saved-archive integrity check immediately after
    show_issue3_linux_build_readiness_route.sh
    show_issue3_enter_submit_runtime_revalidation_route.sh
    --helper-root /path/to/live/browser
    --sync-helper-surface
    Recommended Self-Contained Restore
    the saved archive can lag the current
    Do not switch into the restored checkout
    Saved Memory input check passed.
    """,
    "scripts/linux/restore_saved_browser_snapshot.sh": """
    --check-only
    --helper-root
    --fallback-zig-archive
    --sync-helper-surface
    check_issue3_restored_checkout.py
    follow_up_restored_checkout_check
    check_issue3_saved_archive_integrity.py
    follow_up_archive_integrity_check
    Follow-up helper root:
    Fallback Zig archive:
    Helper surface sync:
    Suggested follow-up checks:
    show_issue3_linux_build_readiness_route.sh
    show_issue3_enter_submit_runtime_revalidation_route.sh
    """,
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": """
    check_issue3_saved_browser_snapshot_route_surface.sh
    restore_saved_browser_snapshot.sh
    check_issue3_restored_checkout.py
    check_issue3_saved_archive_integrity.py
    Restored-checkout readiness check:
    Synced restored-checkout readiness check:
    Saved-archive integrity preflight against the restored checkout:
    Synced saved-archive integrity preflight:
    --helper-root
    --sync-helper-surface
    --fallback-zig-archive
    restored_checkout_check
    sync_restored_checkout_check
    sync_saved_archive_integrity
    follow_up_helper_root
    Sync helper surface:
    Recommended synced restore when the archive helper surface is stale:
    Synced saved-Memory preflight:
    Synced Linux or WSL build-readiness route:
    Synced direct runtime re-entry route:
    Saved-Memory preflight against the restored checkout:
    show_issue3_linux_build_readiness_route.sh
    show_issue3_enter_submit_runtime_revalidation_route.sh
    fallback-zig-archive
    current issue #3 helper docs and scripts
    """,
    "scripts/check_issue3_saved_memory_inputs.py": """
    repo_archives/browser/01-browser-fork-headed-mode-foundation.zip
    repo_archives/browser/blocker_intelligence.yaml
    zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz
    --fallback-zig-archive
    Saved Memory input check passed.
    """,
    "scripts/check_issue3_saved_archive_integrity.py": """
    repo_archives/browser/01-browser-fork-headed-mode-foundation.zip
    repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip
    DEFAULT_FALLBACK_ZIG_SHA256
    --fallback-zig-archive
    Saved archive integrity check passed.
    """,
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md": "# restored checkout route",
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md": "# archive integrity route",
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh": "integrity surface",
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh": "integrity route",
    "build.zig.zon": '.minimum_zig_version = "0.15.2"',
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-snapshot-route-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedBrowserSnapshotRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.files = {
            "saved_snapshot_note": read_text(
                cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
            ),
            "linux_build_note": read_text(
                cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
            ),
            "runtime_gates_note": read_text(
                cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
            ),
            "surface_checker": read_text(
                cls.repo_root / "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"
            ),
            "restore_helper": read_text(
                cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
            ),
            "route_printer": read_text(
                cls.repo_root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
            ),
            "saved_memory_helper": read_text(
                cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
            ),
            "saved_archive_integrity_helper": read_text(
                cls.repo_root / "scripts/check_issue3_saved_archive_integrity.py"
            ),
        }

    def assert_fragments(self, key: str, fragments: tuple[str, ...]) -> None:
        haystack = self.files[key]
        for fragment in fragments:
            self.assertIn(fragment, haystack)

    def test_saved_snapshot_note_surface(self) -> None:
        self.assert_fragments(
            "saved_snapshot_note",
            (
                "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
                "scripts/linux/restore_saved_browser_snapshot.sh",
                "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
                "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
                "scripts/check_issue3_restored_checkout.py",
                "scripts/check_issue3_saved_memory_inputs.py",
                "scripts/check_issue3_saved_archive_integrity.py",
                "Run the restored-checkout readiness check first",
                "Run the saved-archive integrity check immediately after",
                "--helper-root /path/to/live/browser",
                "--sync-helper-surface",
                "Recommended Self-Contained Restore",
                "the saved archive can lag the current",
                "Do not switch into the restored checkout",
            ),
        )

    def test_surface_checker_fragments(self) -> None:
        self.assert_fragments(
            "surface_checker",
            (
                "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file",
                "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file",
                "scripts/check_issue3_restored_checkout.py|file",
                "scripts/check_issue3_saved_archive_integrity.py|file",
                "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|file",
                "scripts/linux/show_issue3_saved_archive_integrity_route.sh|file",
                "python ./scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot",
                "python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot",
                "Run the saved-archive integrity check immediately after",
                "Recommended Self-Contained Restore",
                "the saved archive can lag the current",
                "Saved Memory input check passed.",
            ),
        )

    def test_route_printer_fragments(self) -> None:
        self.assert_fragments(
            "route_printer",
            (
                "check_issue3_restored_checkout.py",
                "check_issue3_saved_archive_integrity.py",
                "Restored-checkout readiness check:",
                "Synced restored-checkout readiness check:",
                "Saved-archive integrity preflight against the restored checkout:",
                "Synced saved-archive integrity preflight:",
                "restored_checkout_check",
                "sync_restored_checkout_check",
                "sync_saved_archive_integrity",
                "follow_up_helper_root",
                "Recommended synced restore when the archive helper surface is stale:",
                "Synced saved-Memory preflight:",
                "Synced Linux or WSL build-readiness route:",
                "Synced direct runtime re-entry route:",
                "fallback-zig-archive",
            ),
        )

    def test_restore_helper_fragments(self) -> None:
        self.assert_fragments(
            "restore_helper",
            (
                "check_issue3_restored_checkout.py",
                "follow_up_restored_checkout_check",
                "check_issue3_saved_archive_integrity.py",
                "follow_up_archive_integrity_check",
                "Follow-up helper root:",
                "Fallback Zig archive:",
                "Helper surface sync:",
                "Suggested follow-up checks:",
            ),
        )

    def test_neighboring_notes_keep_route_visible(self) -> None:
        self.assert_fragments(
            "linux_build_note",
            (
                "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
                "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
                "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
                "scripts/check_issue3_saved_memory_inputs.py",
            ),
        )
        self.assert_fragments(
            "runtime_gates_note",
            (
                "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
                "bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            ),
        )

    def test_saved_memory_helper_fragments(self) -> None:
        self.assert_fragments(
            "saved_memory_helper",
            (
                "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
                "repo_archives/browser/blocker_intelligence.yaml",
                "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
                "--fallback-zig-archive",
                "Saved Memory input check passed.",
            ),
        )

    def test_saved_archive_integrity_helper_fragments(self) -> None:
        self.assert_fragments(
            "saved_archive_integrity_helper",
            (
                "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
                "repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip",
                "DEFAULT_FALLBACK_ZIG_SHA256",
                "--fallback-zig-archive",
                "Saved archive integrity check passed.",
            ),
        )


if __name__ == "__main__":
    unittest.main()
