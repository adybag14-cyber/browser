from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from explicit_headed_probe_launch_audit import EXPECTATIONS, audit


class ExplicitHeadedProbeLaunchAuditTests(unittest.TestCase):
    def write_fixture_repo(self, repo_root: Path, drop_index: int | None = None) -> None:
        for index, expectation in enumerate(EXPECTATIONS):
            if drop_index is not None and index == drop_index:
                continue
            target = repo_root / expectation["path"]
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(expectation["snippet"], encoding="utf-8")

    def test_audit_passes_when_all_expected_snippets_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_fixture_repo(repo_root)

            result = audit(repo_root)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_reports_missing_snippet_when_one_file_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_fixture_repo(repo_root, drop_index=0)

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][0]["exists"])
            self.assertFalse(result["checks"][0]["present"])

    def test_audit_reports_missing_snippet_for_existing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo_root = Path(tmp_dir)
            self.write_fixture_repo(repo_root)
            first_target = repo_root / EXPECTATIONS[0]["path"]
            first_target.write_text("Start-Process -FilePath $script:BrowserExe -ArgumentList @(\"browse\",$StartupUrl)", encoding="utf-8")

            result = audit(repo_root)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertTrue(result["checks"][0]["exists"])
            self.assertFalse(result["checks"][0]["present"])

    def test_audit_covers_common_and_single_probe_surfaces(self) -> None:
        covered_paths = {expectation["path"] for expectation in EXPECTATIONS}
        self.assertTrue(
            {
                "tmp-browser-smoke/fetch-credentials/FetchCredentialsProbeCommon.ps1",
                "tmp-browser-smoke/fetch-abort/FetchAbortProbeCommon.ps1",
                "tmp-browser-smoke/attachment-downloads/AttachmentProbeCommon.ps1",
                "tmp-browser-smoke/cookie-persistence/CookieProbeCommon.ps1",
                "tmp-browser-smoke/websocket-smoke/chrome-websocket-echo-probe.ps1",
                "tmp-browser-smoke/websocket-smoke/chrome-websocket-binary-close-probe.ps1",
                "tmp-browser-smoke/websocket-smoke/chrome-websocket-subprotocol-probe.ps1",
            }.issubset(covered_paths)
        )


if __name__ == "__main__":
    unittest.main()