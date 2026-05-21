from __future__ import annotations

import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

from issue3_trace_target_catalog import (
    ISSUE3_TRACE_HINTS,
    REPRESENTATIVE_TRACE_URLS,
    audit_trace_log,
    audit_trace_source,
    build_audit_result,
    is_issue3_trace_target,
    main,
    matching_trace_hints,
    matching_trace_urls,
    missing_trace_hints,
    missing_trace_urls,
)


class Issue3TraceTargetCatalogTests(unittest.TestCase):
    def test_issue3_trace_target_accepts_all_representative_urls(self) -> None:
        for url in REPRESENTATIVE_TRACE_URLS.values():
            self.assertTrue(is_issue3_trace_target(url), url)

    def test_issue3_trace_target_rejects_unrelated_url(self) -> None:
        self.assertFalse(is_issue3_trace_target("http://127.0.0.1:8000/unrelated.html"))

    def test_matching_trace_hints_marks_seen_hints(self) -> None:
        seen = matching_trace_hints(
            [
                "// google-home- and google.com remain enabled",
                "// google_home_title_probe.html expands the fixture surface",
                "// file:///tmp/Control%20your%20online%20safety%20and%20privacy%20%E2%80%93%20Google%20Safety%20Centre.html",
            ]
        )
        self.assertTrue(seen["google-home-"])
        self.assertTrue(seen["google.com"])
        self.assertTrue(seen["google_home_title_probe.html"])
        self.assertTrue(seen["control%20your%20online%20safety%20and%20privacy"])
        self.assertFalse(seen["mouse_down_focus_input.html"])

    def test_missing_trace_hints_reports_remaining_hints(self) -> None:
        missing = missing_trace_hints(
            [
                "google-home-",
                "google.com",
                "google_home_title_probe.html",
            ]
        )
        self.assertIn("body_onload_keyboard_input.html", missing)
        self.assertIn("department of war", missing)
        self.assertNotIn("google-home-", missing)

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

    def test_audit_trace_source_reads_source_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            trace_path = Path(tmp_dir) / "trace-targets.txt"
            trace_path.write_text("\n".join(ISSUE3_TRACE_HINTS), encoding="utf-8")
            self.assertEqual([], audit_trace_source(trace_path))

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

    def test_build_audit_result_reports_failures(self) -> None:
        result = build_audit_result("source", "src/lightpanda.zig", ["anthropic"])
        self.assertEqual("source", result["audit_kind"])
        self.assertEqual("src/lightpanda.zig", result["path"])
        self.assertEqual(["anthropic"], result["missing"])
        self.assertEqual(1, result["missing_count"])
        self.assertFalse(result["ok"])

    def test_main_emits_json_for_source_audit(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            trace_path = Path(tmp_dir) / "trace-targets.txt"
            trace_path.write_text("\n".join(ISSUE3_TRACE_HINTS), encoding="utf-8")
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                exit_code = main(["source", str(trace_path), "--json"])
            payload = json.loads(stdout.getvalue())
            self.assertEqual(0, exit_code)
            self.assertEqual("source", payload["audit_kind"])
            self.assertTrue(payload["ok"])
            self.assertEqual([], payload["missing"])

    def test_main_reports_missing_log_targets_in_text_mode(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            trace_path = Path(tmp_dir) / "browse-render.log"
            trace_path.write_text(
                f"stage|url={REPRESENTATIVE_TRACE_URLS['google-home']}|detail=ok\n",
                encoding="utf-8",
            )
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                exit_code = main(["log", str(trace_path)])
            output = stdout.getvalue()
            self.assertEqual(1, exit_code)
            self.assertIn("[FAIL] issue3 trace log audit", output)
            self.assertIn("fixture-onload-input", output)


if __name__ == "__main__":
    unittest.main()
