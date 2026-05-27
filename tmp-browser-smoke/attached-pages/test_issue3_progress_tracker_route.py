from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


FIXTURE_NOTE_TEXT = """
# Issue #3 Progress Tracker Route

- issue `#2`
- issue `#3`
- issue `#11`
- `Headed runtime re-entry: Linux/WSL build and toolchain readiness tracker`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
- `docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`
- `docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`
- `scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh`
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_linux_build_readiness.py`
- `--fallback-zig-archive`
- progress update on issue `#11`
- comments on issue `#2` or issue `#3`
- `Page.zig`
- `win32_backend.zig`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
"""

FIXTURE_ROUTE_PRINTER_TEXT = """
Issue #11 progress-tracker route for blocked issue #3 re-entry
show_issue3_saved_memory_inputs_route.sh
show_issue3_zig_toolchain_recovery_route.sh
show_issue3_zig_toolchain_archive_restore_route.sh
--fallback-zig-archive
Goal:
Achieved:
"""


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-progress-tracker-"))

    note_path = root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
    note_path.parent.mkdir(parents=True, exist_ok=True)
    note_path.write_text(FIXTURE_NOTE_TEXT.lstrip("\n"), encoding="utf-8")

    route_printer_path = root / "scripts/linux/show_issue3_progress_tracker_route.sh"
    route_printer_path.parent.mkdir(parents=True, exist_ok=True)
    route_printer_path.write_text(
        FIXTURE_ROUTE_PRINTER_TEXT.lstrip("\n"),
        encoding="utf-8",
    )
    return root


class Issue3ProgressTrackerRouteTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        cls.repo_root = (
            pathlib.Path(env_root).resolve() if env_root else build_fixture_repo()
        )
        cls.route_text = (
            cls.repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
        ).read_text(encoding="utf-8")
        cls.route_printer_text = (
            cls.repo_root / "scripts/linux/show_issue3_progress_tracker_route.sh"
        ).read_text(encoding="utf-8")

    def test_tracker_note_keeps_issue_handoff_visible(self) -> None:
        for fragment in (
            "issue `#2`",
            "issue `#3`",
            "issue `#11`",
            "Headed runtime re-entry: Linux/WSL build and toolchain readiness tracker",
            "progress update on issue `#11`",
            "comments on issue `#2` or issue `#3`",
        ):
            self.assertIn(fragment, self.route_text)

    def test_tracker_note_keeps_branch_local_reentry_surfaces_visible(self) -> None:
        for fragment in (
            "`docs/ISSUE3_RUNTIME_REENTRY_GATES.md`",
            "`docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md`",
            "`docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md`",
            "`docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`",
            "`docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`",
            "`docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md`",
            "`scripts/linux/show_issue3_zig_toolchain_archive_restore_route.sh`",
            "`scripts/check_issue3_saved_memory_inputs.py`",
            "`scripts/check_issue3_saved_archive_integrity.py`",
            "`scripts/check_issue3_restored_checkout.py`",
            "`scripts/check_linux_build_readiness.py`",
            "`--fallback-zig-archive`",
            "`Page.zig`",
            "`win32_backend.zig`",
        ):
            self.assertIn(fragment, self.route_text)

    def test_route_printer_keeps_fallback_archive_handoff_visible(self) -> None:
        for fragment in (
            "Issue #11 progress-tracker route for blocked issue #3 re-entry",
            "show_issue3_saved_memory_inputs_route.sh",
            "show_issue3_zig_toolchain_recovery_route.sh",
            "show_issue3_zig_toolchain_archive_restore_route.sh",
            "--fallback-zig-archive",
            "Goal:",
            "Achieved:",
        ):
            self.assertIn(fragment, self.route_printer_text)


if __name__ == "__main__":
    unittest.main()
