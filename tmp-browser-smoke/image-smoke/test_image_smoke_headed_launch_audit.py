from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from image_smoke_headed_launch_audit import (
    HEADED_LAUNCH_TOKENS,
    IMAGE_SMOKE_PROBES,
    audit_image_smoke_lines,
    audit_image_smoke_root,
    explicit_headed_launch_present,
    load_probe_sources,
    missing_headed_launch_files,
)


class ImageSmokeHeadedLaunchAuditTests(unittest.TestCase):
    def test_explicit_headed_launch_present_accepts_expected_sequence(self) -> None:
        launch = 'Start-Process -ArgumentList @("browse", "--browser_mode", "headed", $pageUrl)'
        self.assertTrue(explicit_headed_launch_present(launch))

    def test_explicit_headed_launch_present_rejects_implicit_browse_launch(self) -> None:
        launch = 'Start-Process -ArgumentList "browse", $pageUrl, "--screenshot_png", $outPng'
        self.assertFalse(explicit_headed_launch_present(launch))

    def test_audit_image_smoke_lines_accepts_split_launch_tokens(self) -> None:
        self.assertTrue(
            audit_image_smoke_lines(
                [
                    '$browser = Start-Process -FilePath $browserExe -ArgumentList @(',
                    '"browse",',
                    '"--browser_mode",',
                    '"headed",',
                    '$pageUrl,',
                    ')',
                ]
            )
        )

    def test_missing_headed_launch_files_reports_only_implicit_entries(self) -> None:
        sources = {
            "ok.ps1": 'Start-Process -ArgumentList @("browse", "--browser_mode", "headed", $pageUrl)',
            "missing.ps1": 'Start-Process -ArgumentList "browse", $pageUrl',
        }
        self.assertEqual(["missing.ps1"], missing_headed_launch_files(sources))

    def test_load_probe_sources_reads_all_expected_probe_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            body = ", ".join(HEADED_LAUNCH_TOKENS)
            for name in IMAGE_SMOKE_PROBES:
                (root / name).write_text(body, encoding="utf-8")
            sources = load_probe_sources(root)
            self.assertEqual(set(IMAGE_SMOKE_PROBES), set(sources))

    def test_audit_image_smoke_root_reports_missing_probe_launches(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            expected = []
            for index, name in enumerate(IMAGE_SMOKE_PROBES):
                if index in (1, 7):
                    (root / name).write_text(
                        'Start-Process -ArgumentList "browse", $pageUrl',
                        encoding="utf-8",
                    )
                    expected.append(name)
                else:
                    (root / name).write_text(
                        'Start-Process -ArgumentList @("browse", "--browser_mode", "headed", $pageUrl)',
                        encoding="utf-8",
                    )
            self.assertEqual(expected, audit_image_smoke_root(root))


if __name__ == "__main__":
    unittest.main()