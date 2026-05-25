from __future__ import annotations

import unittest
from pathlib import Path


RESTORE_SCRIPT = (
    Path(__file__).resolve().parents[2]
    / "scripts"
    / "linux"
    / "restore_saved_browser_snapshot.sh"
)

REQUIRED_SURFACE_PATHS = (
    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
    "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
)


class RestoreSavedBrowserSnapshotSyncSurfaceTests(unittest.TestCase):
    def test_saved_zig_route_surface_is_synced(self) -> None:
        script = RESTORE_SCRIPT.read_text(encoding="utf-8")
        for relative_path in REQUIRED_SURFACE_PATHS:
            quoted = f'"{relative_path}"'
            self.assertIn(
                quoted,
                script,
                f"restore helper surface is missing {relative_path}",
            )


if __name__ == "__main__":
    unittest.main()
