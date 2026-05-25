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
    - `scripts/check_issue3_saved_browser_snapshot_archive_surface.py`
    - `scripts/linux/restore_saved_browser_snapshot.sh`
    - `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
    - `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md`
    - `docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md`
    - `scripts/check_issue3_restored_checkout.py`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `repo_archives/browser/01-browser-fork-headed-mode-foundation.zip`
    - `../browser-memory-snapshot`
    - `--sync-helper-surface`
    - `--sync-only`
    - `--check-only`
    - `check_issue3_saved_browser_snapshot_archive_surface.py`
    - `check_issue3_restored_checkout.py`
    - `check_issue3_saved_memory_inputs.py`
    - `check_issue3_saved_archive_integrity.py`
    - `show_issue3_linux_build_readiness_route.sh`
    - `show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `scripts/check_issue3_saved_memory_inputs.py`
    - `scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh`
    - `scripts/check_issue3_saved_archive_integrity.py`
    - `scripts/linux/show_issue3_linux_build_readiness_route.sh`
    - `scripts/check_issue3_restored_checkout.py`
    - `Treat that as archive age, not restore corruption`
    - `The route helper prints those same commands`
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
    Restore the saved browser repo snapshot from Memory into a reusable local
    checkout for Linux or WSL validation work
    Use --sync-helper-surface when the restored checkout should also carry the
    current issue #3 helper docs and route scripts from the live helper root.
    Use --sync-only to refresh that helper surface inside an existing restored
    checkout without re-extracting the saved repo archive
    DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"
    DEFAULT_DESTINATION_NAME="browser-memory-snapshot"
    DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md"
    "scripts/check_issue3_saved_browser_snapshot_archive_surface.py"
    "scripts/check_issue3_restored_checkout.py"
    "scripts/check_issue3_saved_memory_inputs.py"
    "scripts/check_issue3_saved_archive_integrity.py"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
    "scripts/linux/restore_saved_browser_snapshot.sh"
    if [[ "${SYNC_ONLY}" == "true" ]]; then
        SYNC_HELPER_SURFACE=true
    fi
    sync_helper_surface "${HELPER_ROOT}" "${DESTINATION}"
    """,
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": """
    Usage:
      bash scripts/linux/show_issue3_saved_browser_snapshot_route.sh \\
        [--repo-root /path/to/browser-repo] \\
        [--helper-root /path/to/live/browser-repo] \\
        [--memory-root /path/to/workspace/memory] \\
        [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \\
        [--destination /path/to/extracted/browser-checkout] \\
        [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \\
        [--sync-helper-surface] \\
        [--sync-only] \\
        [--json]
    ROUTE_SURFACE_COMMAND=
    ARCHIVE_SURFACE_COMMAND=
    SURFACE_CHECK_COMMAND=
    RESTORE_COMMAND=
    RESTORED_CHECKOUT_CHECK_COMMAND=
    SAVED_MEMORY_PREFLIGHT_COMMAND=
    SAVED_ARCHIVE_INTEGRITY_COMMAND=
    LINUX_BUILD_ROUTE_COMMAND=
    RUNTIME_ROUTE_COMMAND=
    SYNC_SURFACE_CHECK_COMMAND=
    SYNC_RESTORE_COMMAND=
    SYNC_ONLY_CHECK_COMMAND=
    SYNC_ONLY_COMMAND=
    SYNC_RESTORED_CHECKOUT_CHECK_COMMAND=
    SYNC_SAVED_MEMORY_PREFLIGHT_COMMAND=
    SYNC_SAVED_ARCHIVE_INTEGRITY_COMMAND=
    SYNC_LINUX_BUILD_ROUTE_COMMAND=
    SYNC_RUNTIME_ROUTE_COMMAND=
    "follow_up_helper_root"
    "route_surface"
    "archive_surface"
    "sync_only_refresh"
    "sync_runtime_route"
    "Run archive_surface next when the saved snapshot may lag the live helper surface"
    "Use --sync-only when the restored checkout already exists"
    "Prefer the sync_* commands when the restored checkout should become its own follow-up root"
    "Use runtime_route only after the saved checkout exists"
    """,
    "scripts/check_issue3_saved_browser_snapshot_archive_surface.py": """
    DEFAULT_ARCHIVE_NAME = "01-browser-fork-headed-mode-foundation.zip"
    ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
     "Read-first saved-browser-snapshot restore note for the blocked issue #3 runtime lane.")
    ("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
     "Restored-checkout re-entry note that should stay available after restore succeeds.")
    ("scripts/check_issue3_saved_memory_inputs.py",
     "Saved-Memory preflight that checks the repo archive, blocker file, and dependency bundles.")
    ("scripts/check_issue3_restored_checkout.py",
     "Restored-checkout readiness helper that should stay available after restore.")
    ("scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
     "Saved snapshot restore surface checker that should stay available before the archive is extracted again.")
    ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
     "Compact route printer for the saved-browser-snapshot restore path.")
    ("scripts/linux/restore_saved_browser_snapshot.sh",
     "Restore helper that supports --check-only and --sync-helper-surface.")
    """,
    "scripts/check_issue3_restored_checkout.py": """
    RESTORED_CHECKOUT_PATHS: tuple[tuple[str, str], ...] = (
        ("build.zig", "top-level build entrypoint"),
        ("build.zig.zon", "dependency manifest"),
        ("docs/HEADED_MODE_ROADMAP.md", "headed-mode roadmap"),
        ("src/browser/Page.zig", "page runtime surface"),
        ("src/display/win32_backend.zig", "Win32 backend runtime surface"),
    )
    HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
        ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved snapshot restore note"),
        ("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md", "restored-checkout re-entry note"),
        ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
        ("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper"),
        ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved snapshot route printer"),
        ("scripts/linux/restore_saved_browser_snapshot.sh", "saved snapshot restore helper"),
    )
    parser.add_argument("--helper-root", default=None)
    parser.add_argument("--expect-helper-surface", action="store_true")
    "matches_helper_root": None
    return "stale-helper-surface"
    return "helper-surface-drift"
    return "partial-helper-surface-and-drift"
    """,
    "scripts/check_issue3_saved_memory_inputs.py": """
    REQUIRED_MEMORY_FILES: tuple[tuple[str, str], ...] = (
        ("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
        ("repo_archives/browser/README.md", "saved repo notes"),
        ("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence"),
    )
    REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
        ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved-browser-snapshot restore guide"),
        ("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md", "restored-checkout re-entry guide"),
        ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper"),
        ("scripts/check_issue3_saved_archive_integrity.py", "saved-archive integrity helper"),
        ("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper"),
        ("scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh", "saved-browser-snapshot route surface checker"),
        ("scripts/linux/restore_saved_browser_snapshot.sh", "saved-browser-snapshot restore helper"),
        ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved-browser-snapshot route helper"),
    )
    DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"
    EXPECTED_REPO_SNAPSHOT_PREFIX = "browser-fork-headed-mode-foundation/"
    """,
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-snapshot-route-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue3SavedBrowserSnapshotSyncSurfaceTest(unittest.TestCase):
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
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )
        cls.route_helper = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
        )
        cls.archive_surface_helper = read_text(
            cls.repo_root
            / "scripts/check_issue3_saved_browser_snapshot_archive_surface.py"
        )
        cls.restored_checkout_helper = read_text(
            cls.repo_root / "scripts/check_issue3_restored_checkout.py"
        )
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )

    def test_route_note_keeps_sync_modes_and_follow_up_ladder_visible(self) -> None:
        for fragment in (
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "scripts/check_issue3_saved_browser_snapshot_archive_surface.py",
            "scripts/linux/restore_saved_browser_snapshot.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
            "../browser-memory-snapshot",
            "--sync-helper-surface",
            "--sync-only",
            "--check-only",
            "Treat that as archive age, not restore corruption",
            "The route helper prints those same commands",
        ):
            self.assertIn(fragment, self.route_note)

        for fragment in (
            "scripts/check_issue3_restored_checkout.py",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_saved_archive_integrity.py",
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
        ):
            self.assertIn(fragment, self.route_note)

    def test_restore_helper_keeps_restore_and_sync_surface_controls_visible(self) -> None:
        for fragment in (
            "bash scripts/linux/restore_saved_browser_snapshot.sh",
            "--browser-root /path/to/browser-repo",
            "--helper-root /path/to/live/browser-repo",
            "--memory-root /path/to/workspace/memory",
            "--archive /path/to/01-browser-fork-headed-mode-foundation.zip",
            "--destination /path/to/extracted/browser-checkout",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--sync-helper-surface",
            "--sync-only",
            "--check-only",
            "--json",
            "--force",
            'DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"',
            'DEFAULT_DESTINATION_NAME="browser-memory-snapshot"',
            'DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"',
            '"docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"',
            '"scripts/check_issue3_saved_browser_snapshot_archive_surface.py"',
            '"scripts/check_issue3_restored_checkout.py"',
            '"scripts/check_issue3_saved_memory_inputs.py"',
            '"scripts/check_issue3_saved_archive_integrity.py"',
            '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh"',
            '"scripts/linux/restore_saved_browser_snapshot.sh"',
            'if [[ "${SYNC_ONLY}" == "true" ]]; then',
            "SYNC_HELPER_SURFACE=true",
            'sync_helper_surface "${HELPER_ROOT}" "${DESTINATION}"',
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_route_printer_keeps_surface_and_sync_command_ladder_visible(self) -> None:
        for fragment in (
            "bash scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "--repo-root /path/to/browser-repo",
            "--helper-root /path/to/live/browser-repo",
            "--memory-root /path/to/workspace/memory",
            "--archive /path/to/01-browser-fork-headed-mode-foundation.zip",
            "--destination /path/to/extracted/browser-checkout",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--sync-helper-surface",
            "--sync-only",
            "--json",
            "ROUTE_SURFACE_COMMAND",
            "ARCHIVE_SURFACE_COMMAND",
            "SURFACE_CHECK_COMMAND",
            "RESTORE_COMMAND",
            "RESTORED_CHECKOUT_CHECK_COMMAND",
            "SAVED_MEMORY_PREFLIGHT_COMMAND",
            "SAVED_ARCHIVE_INTEGRITY_COMMAND",
            "LINUX_BUILD_ROUTE_COMMAND",
            "RUNTIME_ROUTE_COMMAND",
            "SYNC_SURFACE_CHECK_COMMAND",
            "SYNC_RESTORE_COMMAND",
            "SYNC_ONLY_CHECK_COMMAND",
            "SYNC_ONLY_COMMAND",
            "SYNC_RESTORED_CHECKOUT_CHECK_COMMAND",
            "SYNC_SAVED_MEMORY_PREFLIGHT_COMMAND",
            "SYNC_SAVED_ARCHIVE_INTEGRITY_COMMAND",
            "SYNC_LINUX_BUILD_ROUTE_COMMAND",
            "SYNC_RUNTIME_ROUTE_COMMAND",
            '"follow_up_helper_root"',
            '"route_surface"',
            '"archive_surface"',
            '"sync_only_refresh"',
            '"sync_runtime_route"',
            "Run archive_surface next when the saved snapshot may lag the live helper surface",
            "Use --sync-only when the restored checkout already exists",
            "Prefer the sync_* commands when the restored checkout should become its own follow-up root",
            "Use runtime_route only after the saved checkout exists",
        ):
            self.assertIn(fragment, self.route_helper)

    def test_archive_and_follow_up_helpers_keep_stale_archive_decision_visible(self) -> None:
        for fragment in (
            'DEFAULT_ARCHIVE_NAME = "01-browser-fork-headed-mode-foundation.zip"',
            "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
            "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/check_issue3_restored_checkout.py",
            "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "scripts/linux/restore_saved_browser_snapshot.sh",
            "supports --check-only and --sync-helper-surface",
        ):
            self.assertIn(fragment, self.archive_surface_helper)

        for fragment in (
            '("build.zig", "top-level build entrypoint")',
            '("build.zig.zon", "dependency manifest")',
            '("docs/HEADED_MODE_ROADMAP.md", "headed-mode roadmap")',
            '("src/browser/Page.zig", "page runtime surface")',
            '("src/display/win32_backend.zig", "Win32 backend runtime surface")',
            '("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved snapshot restore note")',
            '("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md", "restored-checkout re-entry note")',
            '("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper")',
            '("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper")',
            '("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved snapshot route printer")',
            '("scripts/linux/restore_saved_browser_snapshot.sh", "saved snapshot restore helper")',
            'parser.add_argument("--helper-root", default=None)',
            'parser.add_argument("--expect-helper-surface", action="store_true")',
            '"matches_helper_root": None',
            'return "stale-helper-surface"',
            'return "helper-surface-drift"',
            'return "partial-helper-surface-and-drift"',
        ):
            self.assertIn(fragment, self.restored_checkout_helper)

        for fragment in (
            '("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot")',
            '("repo_archives/browser/README.md", "saved repo notes")',
            '("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence")',
            '("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved-browser-snapshot restore guide")',
            '("docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md", "restored-checkout re-entry guide")',
            '("scripts/check_issue3_saved_memory_inputs.py", "saved-memory preflight helper")',
            '("scripts/check_issue3_saved_archive_integrity.py", "saved-archive integrity helper")',
            '("scripts/check_issue3_restored_checkout.py", "restored-checkout readiness helper")',
            '("scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh", "saved-browser-snapshot route surface checker")',
            '("scripts/linux/restore_saved_browser_snapshot.sh", "saved-browser-snapshot restore helper")',
            '("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved-browser-snapshot route helper")',
            'DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"',
            'DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"',
            'EXPECTED_REPO_SNAPSHOT_PREFIX = "browser-fork-headed-mode-foundation/"',
        ):
            self.assertIn(fragment, self.saved_memory_helper)


if __name__ == "__main__":
    unittest.main()
