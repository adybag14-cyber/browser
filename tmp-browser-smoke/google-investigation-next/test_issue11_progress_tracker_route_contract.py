#!/usr/bin/env python3

from __future__ import annotations

import pathlib
import unittest


SCRIPT_RELATIVE_PATH = "scripts/check_issue3_progress_tracker_route_contract.py"


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


class Issue11ProgressTrackerRouteContractGuard(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = pathlib.Path(__file__).resolve().parents[2]
        cls.script_text = read_text(cls.repo_root / SCRIPT_RELATIVE_PATH)

    def test_guard_targets_issue11_progress_tracker_lane(self) -> None:
        for fragment in (
            "ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            "issue `#11`",
            "check_issue3_saved_rust_toolchain_route_surface.sh",
            "show_issue3_saved_zig_archive_candidates_route.sh",
            "--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "Goal:",
            "Achieved:",
        ):
            self.assertIn(fragment, self.script_text)

    def test_guard_keeps_saved_zig_and_archive_restore_checks_visible(self) -> None:
        for fragment in (
            "show_issue3_saved_zig_archive_candidates_route.sh",
            "saved_zig_archive_candidates_route",
            "zig_toolchain_matching_line_gate",
            "scripts/linux/show_issue3_progress_tracker_route.sh|--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        ):
            self.assertIn(fragment, self.script_text)

    def test_guard_keeps_comment_templates_exposed(self) -> None:
        for fragment in (
            "start_comment_template",
            "completion_comment_template",
            "Issue #11 progress-tracker route contract passed.",
        ):
            self.assertIn(fragment, self.script_text)


if __name__ == "__main__":
    unittest.main()
