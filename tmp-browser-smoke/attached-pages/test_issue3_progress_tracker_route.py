from __future__ import annotations

import pathlib
import tempfile
import unittest


FIXTURE_TEXT = """
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
- `scripts/check_issue3_saved_memory_inputs.py`
- `scripts/check_issue3_saved_archive_integrity.py`
- `scripts/check_issue3_restored_checkout.py`
- `scripts/check_linux_build_readiness.py`
- progress update on issue `#11`
- comments on issue `#2` or issue `#3`
- `Page.zig`
- `win32_backend.zig`
- `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`
"""


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-progress-tracker-"))
    target = root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(FIXTURE_TEXT.lstrip("\n"), encoding="utf-8")
    return root


class Issue3ProgressTrackerRouteTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = build_fixture_repo()
        cls.route_text = (
            cls.repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
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
            "`scripts/check_issue3_saved_memory_inputs.py`",
            "`scripts/check_issue3_saved_archive_integrity.py`",
            "`scripts/check_issue3_restored_checkout.py`",
            "`scripts/check_linux_build_readiness.py`",
            "`Page.zig`",
            "`win32_backend.zig`",
        ):
            self.assertIn(fragment, self.route_text)


if __name__ == "__main__":
    unittest.main()
