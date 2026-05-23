from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md": """
# Issue #3 Saved Browser Snapshot Restore Route

- `scripts/linux/restore_saved_browser_snapshot.sh`
- `scripts/linux/show_issue3_saved_browser_snapshot_route.sh`
- `--helper-root /path/to/live/browser`
- `--sync-helper-surface`
- `bash ./scripts/linux/restore_saved_browser_snapshot.sh --check-only`
""",
    "scripts/linux/restore_saved_browser_snapshot.sh": r"""
Usage:
  bash scripts/linux/restore_saved_browser_snapshot.sh \
    [--browser-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--destination /path/to/extracted/browser-checkout] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--sync-helper-surface] \
    [--check-only]
printf "  bash %s --browser-root %s --helper-root %s --memory-root %s --archive %s --destination %s%s%s\n" \
    "$(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh")" \
    "$(format_shell_arg "${BROWSER_ROOT}")" \
    "$(format_shell_arg "${HELPER_ROOT}")" \
    "$(format_shell_arg "${MEMORY_ROOT}")" \
    "$(format_shell_arg "${ARCHIVE_PATH}")" \
    "$(format_shell_arg "${DESTINATION}")" \
    "${RESTORE_FALLBACK_FLAG}" \
    "${SYNC_FLAG}"
""",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh": r"""
Usage:
  bash scripts/linux/show_issue3_saved_browser_snapshot_route.sh \
    [--memory-root /path/to/workspace/memory] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip]
RESTORE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}")${SYNC_FLAG}"
""",
}


def build_fixture_repo() -> Path:
    root = Path(tempfile.mkdtemp(prefix="lightpanda-restore-check-only-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class RestoreSavedBrowserSnapshotCheckOnlyCommandSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = Path(__file__).resolve().parents[2]

        cls.saved_snapshot_note = read_text(
            cls.repo_root / "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
        )
        cls.restore_helper = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )
        cls.route_printer = read_text(
            cls.repo_root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
        )

    def test_restore_helper_usage_keeps_memory_and_archive_overrides_visible(self) -> None:
        for fragment in (
            "--memory-root /path/to/workspace/memory",
            "--archive /path/to/01-browser-fork-headed-mode-foundation.zip",
            "--check-only",
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_check_only_restore_command_keeps_memory_root_and_archive_flags(self) -> None:
        for fragment in (
            "--browser-root %s --helper-root %s --memory-root %s --archive %s --destination %s",
            '$(format_shell_arg "${MEMORY_ROOT}")',
            '$(format_shell_arg "${ARCHIVE_PATH}")',
        ):
            self.assertIn(fragment, self.restore_helper)

    def test_route_printer_keeps_exact_restore_command_shape_visible(self) -> None:
        for fragment in (
            '--memory-root $(format_shell_arg "${MEMORY_ROOT}")',
            '--archive $(format_shell_arg "${ARCHIVE_PATH}")',
            '--destination $(format_shell_arg "${DESTINATION}")',
        ):
            self.assertIn(fragment, self.route_printer)

    def test_saved_snapshot_note_stays_aligned_with_check_only_surface(self) -> None:
        for fragment in (
            "scripts/linux/restore_saved_browser_snapshot.sh",
            "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
            "--helper-root /path/to/live/browser",
            "--sync-helper-surface",
            "bash ./scripts/linux/restore_saved_browser_snapshot.sh --check-only",
        ):
            self.assertIn(fragment, self.saved_snapshot_note)


if __name__ == "__main__":
    unittest.main()