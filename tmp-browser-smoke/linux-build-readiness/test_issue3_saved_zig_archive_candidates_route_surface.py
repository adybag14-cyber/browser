from __future__ import annotations

import pathlib
import unittest


class SavedZigArchiveCandidatesRouteSurfaceTests(unittest.TestCase):
    def test_route_note_keeps_issue11_and_candidate_helper_visible(self) -> None:
        route_note = pathlib.Path("docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md").read_text(encoding="utf-8")
        self.assertIn("issue `#11`", route_note)
        self.assertIn("scripts/check_issue3_saved_zig_archive_candidates.py", route_note)
        self.assertIn("docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md", route_note)
        self.assertIn("docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md", route_note)

    def test_surface_checker_keeps_route_and_helper_expectations(self) -> None:
        surface_script = pathlib.Path(
            "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh"
        ).read_text(encoding="utf-8")
        self.assertIn("docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md", surface_script)
        self.assertIn("scripts/check_issue3_saved_zig_archive_candidates.py", surface_script)
        self.assertIn("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", surface_script)
        self.assertIn("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", surface_script)

    def test_route_printer_keeps_candidate_and_recovery_commands_visible(self) -> None:
        route_printer = pathlib.Path(
            "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh"
        ).read_text(encoding="utf-8")
        self.assertIn("check_issue3_saved_zig_archive_candidates.py", route_printer)
        self.assertIn("check_issue3_zig_toolchain_archive_restore_route_surface.sh", route_printer)
        self.assertIn("show_issue3_zig_toolchain_recovery_route.sh", route_printer)
        self.assertIn("issue #11 while the lane is still about saved inputs", route_printer)


if __name__ == "__main__":
    unittest.main()
