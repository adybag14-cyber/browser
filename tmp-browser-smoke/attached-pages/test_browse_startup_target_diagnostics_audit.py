from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from browse_startup_target_diagnostics_audit import (
    BROWSER_INTERNAL_CASE_MARKERS,
    HELPER_MARKERS,
    LOCAL_PATH_CASE_MARKERS,
    LOOPBACK_CASE_MARKERS,
    STARTUP_DIAGNOSTIC_MARKERS,
    audit_main_source,
    matching_startup_markers,
    missing_startup_markers,
)


class BrowseStartupTargetDiagnosticsAuditTests(unittest.TestCase):
    def test_matching_startup_markers_marks_seen_markers(self) -> None:
        seen = matching_startup_markers(
            [
                "fn browseTargetInternal(url: []const u8, scheme: []const u8) ?BrowseTargetInfo {",
                'scope = "internal"',
                "browser://downloads",
                "attached-page.html?case=1",
                "localhost:8123/attached-page.html",
            ]
        )
        self.assertTrue(seen["fn browseTargetInternal("])
        self.assertTrue(seen['scope = "internal"'])
        self.assertTrue(seen["browser://downloads"])
        self.assertTrue(seen["attached-page.html?case=1"])
        self.assertTrue(seen["localhost:8123/attached-page.html"])
        self.assertFalse(seen["127.0.0.1/replay.xhtml#focus-probe"])

    def test_missing_startup_markers_reports_remaining_markers(self) -> None:
        missing = missing_startup_markers(
            [
                *HELPER_MARKERS,
                *BROWSER_INTERNAL_CASE_MARKERS,
                *LOCAL_PATH_CASE_MARKERS,
            ]
        )
        self.assertIn("localhost:8123/attached-page.html", missing)
        self.assertIn("127.0.0.1/replay.xhtml#focus-probe", missing)
        self.assertNotIn("browser://settings/homepage", missing)

    def test_audit_main_source_reads_utf8_text(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            source_path = Path(tmp_dir) / "main.zig"
            source_path.write_text(
                "\n".join(STARTUP_DIAGNOSTIC_MARKERS),
                encoding="utf-8",
            )
            self.assertEqual([], audit_main_source(source_path))

    def test_marker_sets_stay_populated(self) -> None:
        self.assertGreaterEqual(len(HELPER_MARKERS), 5)
        self.assertGreaterEqual(len(BROWSER_INTERNAL_CASE_MARKERS), 2)
        self.assertGreaterEqual(len(LOCAL_PATH_CASE_MARKERS), 3)
        self.assertGreaterEqual(len(LOOPBACK_CASE_MARKERS), 4)


if __name__ == "__main__":
    unittest.main()
