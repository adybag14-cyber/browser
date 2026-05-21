from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from issue3_trace_target_catalog import (
    REPRESENTATIVE_TRACE_URLS,
    audit_trace_log,
    is_issue3_trace_target,
    matching_trace_urls,
    missing_trace_urls,
)


class Issue3TraceTargetCatalogTests(unittest.TestCase):
    def test_issue3_trace_target_accepts_all_representative_urls(self) -> None:
        for url in REPRESENTATIVE_TRACE_URLS.values():
            self.assertTrue(is_issue3_trace_target(url), url)

    def test_issue3_trace_target_rejects_unrelated_url(self) -> None:
        self.assertFalse(is_issue3_trace_target("http://127.0.0.1:8000/unrelated.html"))

    def test_matching_trace_urls_marks_seen_urls(self) -> None:
        seen = matching_trace_urls(
            [
                f"stage|url={REPRESENTATIVE_TRACE_URLS['google-home']}|detail=ok",
                f"stage|url={REPRESENTATIVE_TRACE_URLS['fixture-title-probe']}|detail=ok",
            ]
        )
        self.assertTrue(seen["google-home"])
        self.assertTrue(seen["fixture-title-probe"])
        self.assertFalse(seen["saved-google-safety"])

    def test_missing_trace_urls_reports_remaining_targets(self) -> None:
        missing = missing_trace_urls(
            [f"stage|url={REPRESENTATIVE_TRACE_URLS['google-home']}|detail=ok"]
        )
        self.assertIn("fixture-onload-input", missing)
        self.assertIn("saved-google-safety", missing)
        self.assertNotIn("google-home", missing)

    def test_audit_trace_log_reads_trace_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            trace_path = Path(tmp_dir) / "browse-render.log"
            trace_path.write_text(
                "\n".join(
                    [
                        f"stage|url={REPRESENTATIVE_TRACE_URLS['google-home']}|detail=ok",
                        f"stage|url={REPRESENTATIVE_TRACE_URLS['fixture-title-probe']}|detail=ok",
                        f"stage|url={REPRESENTATIVE_TRACE_URLS['fixture-onload-input']}|detail=ok",
                        f"stage|url={REPRESENTATIVE_TRACE_URLS['fixture-mousedown-input']}|detail=ok",
                        f"stage|url={REPRESENTATIVE_TRACE_URLS['saved-google-safety']}|detail=ok",
                        f"stage|url={REPRESENTATIVE_TRACE_URLS['saved-anthropic-job']}|detail=ok",
                        f"stage|url={REPRESENTATIVE_TRACE_URLS['saved-department-of-war']}|detail=ok",
                    ]
                ),
                encoding="utf-8",
            )
            self.assertEqual([], audit_trace_log(trace_path))


if __name__ == "__main__":
    unittest.main()
