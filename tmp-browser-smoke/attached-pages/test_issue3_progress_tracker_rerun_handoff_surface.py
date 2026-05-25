from __future__ import annotations

import pathlib
import tempfile
import unittest


DOC_TEXT = """
# Issue #3 Progress Tracker Route

- `scripts/check_issue3_build_readiness_rerun.py`
- build-readiness rerun command
- `docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`
- `docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`
- `scripts/check_issue3_staged_zig_toolchain_candidates.py`
- `scripts/check_issue3_zig_toolchain_match.sh`
- `scripts/check_issue3_zig_toolchain_archive_restore_route_surface.sh`
"""

ROUTE_TEXT = """
Build-readiness rerun helper:
  python3 ./scripts/check_issue3_build_readiness_rerun.py --repo-root .

"build_readiness_rerun_helper": "python3 ./scripts/check_issue3_build_readiness_rerun.py --repo-root .",
"staged_zig_toolchain_candidates": "python3 ./scripts/check_issue3_staged_zig_toolchain_candidates.py --repo-root .",
"zig_toolchain_matching_line_gate": "bash ./scripts/linux/check_issue3_zig_toolchain_match.sh",
"linux_build_readiness_route": "bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh",
"zig_toolchain_recovery_route": "bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
build-readiness-rerun
"""

SURFACE_TEXT = """
scripts/check_issue3_build_readiness_rerun.py
build_readiness_rerun_helper
Build-readiness rerun helper:
build-readiness-rerun
"""


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-progress-rerun-"))
    (root / "docs").mkdir(parents=True, exist_ok=True)
    (root / "scripts/linux").mkdir(parents=True, exist_ok=True)
    (root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md").write_text(
        DOC_TEXT.lstrip("\n"), encoding="utf-8"
    )
    (root / "scripts/linux/show_issue3_progress_tracker_route.sh").write_text(
        ROUTE_TEXT.lstrip("\n"), encoding="utf-8"
    )
    (root / "scripts/linux/check_issue3_progress_tracker_route_surface.sh").write_text(
        SURFACE_TEXT.lstrip("\n"), encoding="utf-8"
    )
    return root


class Issue3ProgressTrackerRerunHandoffSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = build_fixture_repo()
        cls.doc_text = (cls.repo_root / "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md").read_text(
            encoding="utf-8"
        )
        cls.route_text = (
            cls.repo_root / "scripts/linux/show_issue3_progress_tracker_route.sh"
        ).read_text(encoding="utf-8")
        cls.surface_text = (
            cls.repo_root / "scripts/linux/check_issue3_progress_tracker_route_surface.sh"
        ).read_text(encoding="utf-8")

    def test_progress_tracker_doc_keeps_rerun_helper_visible(self) -> None:
        for fragment in (
            "`scripts/check_issue3_build_readiness_rerun.py`",
            "build-readiness rerun command",
            "`docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md`",
            "`docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md`",
            "`scripts/check_issue3_staged_zig_toolchain_candidates.py`",
            "`scripts/check_issue3_zig_toolchain_match.sh`",
            "`scripts/check_issue3_zig_toolchain_archive_restore_route_surface.sh`",
        ):
            self.assertIn(fragment, self.doc_text)

    def test_route_printer_keeps_rerun_helper_visible(self) -> None:
        for fragment in (
            "Build-readiness rerun helper:",
            "check_issue3_build_readiness_rerun.py",
            "build_readiness_rerun_helper",
            "staged_zig_toolchain_candidates",
            "zig_toolchain_matching_line_gate",
            "linux_build_readiness_route",
            "zig_toolchain_recovery_route",
            "build-readiness-rerun",
        ):
            self.assertIn(fragment, self.route_text)

    def test_surface_checker_keeps_rerun_helper_expectations_visible(self) -> None:
        for fragment in (
            "scripts/check_issue3_build_readiness_rerun.py",
            "build_readiness_rerun_helper",
            "Build-readiness rerun helper:",
            "build-readiness-rerun",
        ):
            self.assertIn(fragment, self.surface_text)


if __name__ == "__main__":
    unittest.main()
