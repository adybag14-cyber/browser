from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from browse_startup_target_catalog import (
    REPRESENTATIVE_STARTUP_TARGETS,
    audit_startup_log,
    expected_field_fragments,
    matching_startup_targets,
    missing_startup_targets,
    normalize_startup_log_text,
)


class BrowseStartupTargetCatalogTests(unittest.TestCase):
    def test_normalize_startup_log_text_is_casefolded(self) -> None:
        self.assertEqual("browser://downloads", normalize_startup_log_text("BROWSER://Downloads"))

    def test_expected_field_fragments_include_url_and_target_fields(self) -> None:
        fragments = expected_field_fragments("inline-data-html")
        self.assertIn("url=data:text/html,<title>Inline</title>", fragments)
        self.assertIn("target_scheme=data", fragments)
        self.assertIn("target_scope=inline", fragments)
        self.assertIn("target_host=(none)", fragments)
        self.assertIn("target_port=(none)", fragments)

    def test_matching_startup_targets_accepts_representative_log_lines(self) -> None:
        lines = [
            "ts=1 level=info msg='browse headed runtime' "
            "url=data:text/html,<title>Inline</title> target_scheme=data target_scope=inline "
            "target_host=(none) target_port=(none)",
            "ts=2 level=info msg='browse headed runtime' "
            "url=browser://downloads target_scheme=browser target_scope=internal "
            "target_host=downloads target_port=(none)",
        ]
        matches = matching_startup_targets(lines)
        self.assertTrue(matches["inline-data-html"])
        self.assertTrue(matches["browser-downloads"])
        self.assertFalse(matches["implicit-localhost"])

    def test_missing_startup_targets_reports_remaining_targets(self) -> None:
        missing = missing_startup_targets(
            [
                "url=about:blank#popup-probe target_scheme=about target_scope=internal "
                "target_host=blank target_port=(none)"
            ]
        )
        self.assertIn("inline-data-html", missing)
        self.assertIn("browser-downloads", missing)
        self.assertNotIn("about-blank-popup", missing)

    def test_audit_startup_log_reads_log_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            log_path = Path(tmp_dir) / "browse-startup.log"
            log_path.write_text(
                "\n".join(
                    " ".join(expected_field_fragments(name))
                    for name in REPRESENTATIVE_STARTUP_TARGETS
                ),
                encoding="utf-8",
            )
            self.assertEqual([], audit_startup_log(log_path))


if __name__ == "__main__":
    unittest.main()
