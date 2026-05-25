from __future__ import annotations

import tempfile
import unittest
from pathlib import Path


ADDED_RESTORE_SURFACE_PATHS = (
    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md",
    "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
    "scripts/check_issue3_saved_browser_snapshot_archive_surface.py",
    "scripts/check_issue3_saved_zig_archive_candidates.py",
    "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
    "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
    "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
    "scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh",
    "scripts/linux/show_issue3_progress_tracker_route.sh",
    "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh",
)


FIXTURE_FILES = {
    "scripts/check_issue3_saved_memory_inputs.py": """
REQUIRED_RESTORED_HELPER_FILES = (
    (\"docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md\", \"issue #11 progress-tracker route guide\"),
    (\"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md\", \"saved-browser-snapshot archive-surface guide\"),
    (\"docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md\", \"saved-memory inputs route guide\"),
    (\"docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md\", \"saved Zig archive candidate guide\"),
    (\"scripts/check_issue3_saved_browser_snapshot_archive_surface.py\", \"saved-browser-snapshot archive-surface helper\"),
    (\"scripts/check_issue3_saved_zig_archive_candidates.py\", \"saved Zig archive candidate helper\"),
    (\"scripts/linux/check_issue3_progress_tracker_route_surface.sh\", \"issue #11 progress-tracker route surface checker\"),
    (\"scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh\", \"saved-memory inputs route surface checker\"),
    (\"scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh\", \"saved Zig archive candidate route surface checker\"),
    (\"scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh\", \"Windows runtime handoff surface checker\"),
    (\"scripts/linux/show_issue3_progress_tracker_route.sh\", \"issue #11 progress-tracker route helper\"),
    (\"scripts/linux/show_issue3_saved_memory_inputs_route.sh\", \"saved-memory inputs route helper\"),
    (\"scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh\", \"saved Zig archive candidate route helper\"),
    (\"scripts/linux/show_issue3_windows_runtime_handoff_route.sh\", \"Windows runtime handoff route helper\"),
)
""",
    "scripts/linux/restore_saved_browser_snapshot.sh": """
declare -a HELPER_SURFACE_PATHS=(
    \"docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md\"
    \"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ARCHIVE_SURFACE.md\"
    \"docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md\"
    \"docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md\"
    \"scripts/check_issue3_saved_browser_snapshot_archive_surface.py\"
    \"scripts/check_issue3_saved_zig_archive_candidates.py\"
    \"scripts/linux/check_issue3_progress_tracker_route_surface.sh\"
    \"scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh\"
    \"scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh\"
    \"scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh\"
    \"scripts/linux/show_issue3_progress_tracker_route.sh\"
    \"scripts/linux/show_issue3_saved_memory_inputs_route.sh\"
    \"scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh\"
    \"scripts/linux/show_issue3_windows_runtime_handoff_route.sh\"
)
""",
}


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def build_fixture_repo() -> Path:
    root = Path(tempfile.mkdtemp(prefix="lightpanda-issue11-saved-memory-alignment-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class Issue11SavedMemoryHelperSurfaceAlignmentTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = build_fixture_repo()
        cls.saved_memory_helper = read_text(
            cls.repo_root / "scripts/check_issue3_saved_memory_inputs.py"
        )
        cls.restore_script = read_text(
            cls.repo_root / "scripts/linux/restore_saved_browser_snapshot.sh"
        )

    def test_saved_memory_helper_tracks_added_restore_surface_paths(self) -> None:
        for fragment in ADDED_RESTORE_SURFACE_PATHS:
            self.assertIn(fragment, self.saved_memory_helper)

    def test_restore_script_keeps_the_same_added_surface_paths_visible(self) -> None:
        for fragment in ADDED_RESTORE_SURFACE_PATHS:
            self.assertIn(fragment, self.restore_script)


if __name__ == "__main__":
    unittest.main()
