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
    # Issue #3 Linux Build-Readiness Route

    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
    - `scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    """,
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md": """
    # Issue #3 Runtime Re-entry Gates

    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
    - `bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    """,
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh": """
    REFERENCE_PATHS=(
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file"
      "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file"
      "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file"
      "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file"
      "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file"
      "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh|file"
      "scripts/linux/restore_saved_browser_snapshot.sh|file"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file"
      "scripts/check_issue3_restored_checkout.py|file"
      "scripts/check_issue3_saved_memory_inputs.py|file"
      "scripts/check_issue3_saved_archive_integrity.py|file"
      "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|file"
      "scripts/linux/show_issue3_saved_archive_integrity_route.sh|file"
      "scripts/linux/show_issue3_linux_build_readiness_route.sh|file"
      "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|file"
      "build.zig.zon|file"
    )
    CONTENT_EXPECTATIONS=(
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|restore_saved_browser_snapshot.sh --check-only"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|show_issue3_saved_browser_snapshot_route.sh"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/check_issue3_restored_checkout.py"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|python ./scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Run the restored-checkout readiness check first"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/check_issue3_saved_memory_inputs.py"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|scripts/check_issue3_saved_archive_integrity.py"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|python ./scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Run the saved-archive integrity check immediately after"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|show_issue3_linux_build_readiness_route.sh"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|show_issue3_enter_submit_runtime_revalidation_route.sh"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|--helper-root /path/to/live/browser"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|--sync-helper-surface"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Recommended Self-Contained Restore"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|the saved archive can lag the current"
      "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|Do not switch into the restored checkout"
      "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
      "scripts/linux/restore_saved_browser_snapshot.sh|--check-only"
      "scripts/linux/restore_saved_browser_snapshot.sh|--helper-root"
      "scripts/linux/restore_saved_browser_snapshot.sh|--fallback-zig-archive"
      "scripts/linux/restore_saved_browser_snapshot.sh|--sync-helper-surface"
      "scripts/linux/restore_saved_browser_snapshot.sh|check_issue3_restored_checkout.py"
      "scripts/linux/restore_saved_browser_snapshot.sh|follow_up_restored_checkout_check"
      "scripts/linux/restore_saved_browser_snapshot.sh|check_issue3_saved_archive_integrity.py"
      "scripts/linux/restore_saved_browser_snapshot.sh|follow_up_archive_integrity_check"
      "scripts/linux/restore_saved_browser_snapshot.sh|Follow-up helper root:"
      "scripts/linux/restore_saved_browser_snapshot.sh|Fallback Zig archive:"
      "scripts/linux/restore_saved_browser_snapshot.sh|Helper surface sync:"
      "scripts/linux/restore_saved_browser_snapshot.sh|Suggested follow-up checks:"
      "scripts/linux/restore_saved_browser_snapshot.sh|show_issue3_linux_build_readiness_route.sh"
      "scripts/linux/restore_saved_browser_snapshot.sh|show_issue3_enter_submit_runtime_revalidation_route.sh"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|check_issue3_saved_browser_snapshot_route_surface.sh"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|restore_saved_browser_snapshot.sh"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|check_issue3_restored_checkout.py"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|check_issue3_saved_archive_integrity.py"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Restored-checkout readiness check:"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Synced restored-checkout readiness check:"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Saved-archive integrity preflight against the restored checkout:"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Synced saved-archive integrity preflight:"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|--helper-root"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|--sync-helper-surface"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|restored_checkout_check"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|sync_restored_checkout_check"
      "scripts/linux/show_issue3_saved_BROWSER_SNAPSHOT_ROUTE.sh|sync_saved_archive_integrity"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|follow_up_helper_root"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Sync helper surface:"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Recommended synced restore when the archive helper surface is stale:"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Synced saved-Memory preflight:"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Synced Linux or WSL build-readiness route:"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Synced direct runtime re-entry route:"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|Saved-Memory preflight against the restored checkout:"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|show_issue3_linux_build_readiness_route.sh"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|show_issue3_enter_submit_runtime_revalidation_route.sh"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|fallback-zig-archive"
      "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|current issue #3 helper docs and scripts"
      "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
      "scripts/check_issue3_saved_memory_inputs.py|repo_archives/browser/blocker_intelligence.yaml"
      "scripts/check_issue3_saved_memory_inputs.py|Saved Memory input check passed."
    )
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
    --helper-root
    --sync-helper-surface
    --fallback-zig-archive
    check_issue3_saved_browser_snapshot_route_surface.sh
    restore_saved_browser_snapshot.sh
    check_issue3_restored_checkout.py
    check_issue3_saved_archive_integrity.py
    Restored-checkout readiness check:
    Synced restored-checkout readiness check:
    Saved-archive integrity preflight against the restored checkout:
    Synced saved-archive integrity preflight:
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
    REQUIRED_MEMORY_FILES = (
        ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
        ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
    )
    DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    parser.add_argument("--fallback-zig-archive")
    Saved Memory input check passed.
    """,
    "scripts/check_issue3_saved_archive_integrity.py": """
    EXPECTED_MEMORY_ARCHIVES = (
        ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot", "sha"),
        ("repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip", "saved browser dependency archive", "sha"),
    )
    DEFAULT_FALLBACK_ZIG_SHA256 = "sha"
    parser.add_argument("--fallback-zig-archive")
    Saved archive integrity check passed.
    """,
    "scripts/check_issue3_restored_checkout.py": "build.zig.zon\nexpect-helper-surface\n",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh": "bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh": "bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md": "# restored checkout route",
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md": "# archive integrity route",
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh": "integrity surface",
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh": "integrity route",
    "build.zig.zon": '.minimum_zig_version = "0.15.2",',
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

        cls.saved_snapshot_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
        )
        cls.linux_build_note = read_text(
            cls.repo_root / "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
        )
        cls.runtime_gates_note = read_text(
            cls.repo_root / "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
        )
        cls.surface_checker = read_text(
            cls.repo_root / "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
        )
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )
        cls.saved_archive_integrity_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_archive_integrity.py"
        )

    def test_saved_snapshot_note_keeps_restore_and_follow_up_route_visible(self) -> None:
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
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "bash ./scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "bash ./scripts/linux/restore_saved_browser_snapshot.sh --check-only",
            "bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "python ./scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot",
            "python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface",
            "python ./scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot",
            "python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot",
            "Run the restored-checkout readiness check first",
            "Run the saved-archive integrity check immediately after",
            "--helper-root /path/to/live/browser",
            "--sync-helper-surface",
            "Recommended Self-Contained Restore",
            "the saved archive can lag the current",
            "Do not switch into the restored checkout",
        ):
            self.assertIn(fragment, self.saved_snapshot_note)

    def test_surface_checker_keeps_route_references_and_snippets_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|file",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md|file",
            "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md|file",
            "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|file",
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|file",
            "scripts/linux/restore_saved_browser_snapshot.sh|file",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh|file",
            "scripts/check_issue3_restored_checkout.py|file",
            "scripts/check_issue3_saved_memory_inputs.py|file",
            "scripts/check_issue3_saved_archive_integrity.py|file",
            "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh|file",
            "scripts/linux/show_issue3_saved_archive_integrity_route.sh|file",
            "build.zig.zon|file",
            "restore_saved_browser_snapshot.sh --check-only",
            "python ./scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot",
            "python ../browser-memory-snapshot/scripts/check_issue3_restored_checkout.py --repo-root ../browser-memory-snapshot --helper-root . --expect-helper-surface",
            "Run the restored-checkout readiness check first",
            "python ./scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot",
            "python ../browser-memory-snapshot/scripts/check_issue3_saved_archive_integrity.py --repo-root ../browser-memory-snapshot",
            "Run the saved-archive integrity check immediately after",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
            "--helper-root /path/to/live/browser",
            "--sync-helper-surface",
            "Recommended Self-Contained Restore",
            "the saved archive can lag the current",
            "Do not switch into the restored checkout",
            "Saved Memory input check passed.",
        ):
            self.assertIn(fragment, self.surface_checker)

    def test_route_printer_keeps_restore_preflight_and_follow_up_commands_visible(self) -> None:
        for fragment in (
            "check_issue3_saved_browser_snapshot_route_surface.sh",
            "restore_saved_browser_snapshot.sh",
            "check_issue3_restored_checkout.py",
            "check_issue3_saved_archive_integrity.py",
            "Restored-checkout readiness check:",
            "Synced restored-checkout readiness check:",
            "Saved-archive integrity preflight against the restored checkout:",
            "Synced saved-archive integrity preflight:",
            "--helper-root",
            "--sync-helper-surface",
            "--fallback-zig-archive",
            "restored_checkout_check",
            "sync_restored_checkout_check",
            "sync_saved_archive_integrity",
            "follow_up_helper_root",
            "Sync helper surface:",
            "Recommended synced restore when the archive helper surface is stale:",
            "Synced saved-Memory preflight:",
            "Synced Linux or WSL build-readiness route:",
            "Synced direct runtime re-entry route:",
            "Saved-Memory preflight against the restored checkout:",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
            "fallback-zig-archive",
            "current issue #3 helper docs and scripts",
        ):
            self.assertIn(fragment, self.route_printer)

    def test_restore_helper_keeps_check_only_sync_and_follow_up_surface_visible(self) -> None:
        for fragment in (
            "--check-only",
            "--helper-root",
            "--fallback-zig-archive",
            "--sync-helper-surface",
            "check_issue3_restored_checkout.py",
            "follow_up_restored_checkout_check",
            "check_issue3_saved_archive_integrity.py",
            "follow_up_archive_integrity_check",
            "Follow-up helper root:",
            "Fallback Zig archive:",
            "Helper surface sync:",
            "Suggested follow-up checks:",
            "show_issue3_linux_build_readiness_route.sh",
            "show_issue3_enter_submit_runtime_revalidation_route.sh",
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_build_readiness_and_runtime_notes_keep_saved_snapshot_route_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/check_issue3_saved_memory_inputs.py",
            "bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        ):
            self.assertIn(fragment, self.linux_build_note)

        for fragment in (
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        ):
            self.assertIn(fragment, self.runtime_gates_note)

    def test_saved_memory_helper_keeps_archive_blocker_and_fallback_zig_inputs_visible(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/blocker_intelligence.yaml",
            "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--fallback-zig-archive",
            "Saved Memory input check passed.",
        ):
            self.assertIn(fragment, self.saved_memory_helper)

    def test_saved_archive_integrity_helper_keeps_snapshot_dependency_and_fallback_surfaces_visible(self) -> None:
        for fragment in (
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip",
            "DEFAULT_FALLBACK_ZIG_SHA256",
            "--fallback-zig-archive",
            "Saved archive integrity check passed.",
        ):
            self.assertIn(fragment, self.saved_archive_integrity_helper)


if __name__ == "__main__":
    unittest.main()
