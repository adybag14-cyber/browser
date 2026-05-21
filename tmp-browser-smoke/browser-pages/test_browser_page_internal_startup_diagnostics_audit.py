from __future__ import annotations

import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

from browser_page_internal_startup_diagnostics_audit import (
    INTERNAL_LOG_CASES,
    SOURCE_EXPECTATIONS,
    audit_log,
    audit_source,
    main,
    parse_logfmt_line,
)


class BrowserPageInternalStartupDiagnosticsAuditTests(unittest.TestCase):
    def test_parse_logfmt_line_keeps_key_value_fields(self) -> None:
        fields = parse_logfmt_line(
            'level=info msg="browse headed runtime" url=browser://downloads '
            "target_scheme=browser target_scope=internal target_host=downloads target_port=(none)"
        )
        self.assertEqual("browser://downloads", fields["url"])
        self.assertEqual("browser", fields["target_scheme"])
        self.assertEqual("internal", fields["target_scope"])

    def test_audit_source_passes_when_all_snippets_are_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            source_path = Path(tmp_dir) / "main.zig"
            source_path.write_text(
                "\n".join(expectation["snippet"] for expectation in SOURCE_EXPECTATIONS),
                encoding="utf-8",
            )
            result = audit_source(source_path)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_source_reports_missing_snippet(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            source_path = Path(tmp_dir) / "main.zig"
            source_path.write_text(
                "\n".join(expectation["snippet"] for expectation in SOURCE_EXPECTATIONS[1:]),
                encoding="utf-8",
            )
            result = audit_source(source_path)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][0]["present"])

    def test_audit_log_passes_when_all_internal_routes_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            log_path = Path(tmp_dir) / "browse.log"
            lines = []
            for case in INTERNAL_LOG_CASES:
                fields = " ".join(
                    f"{key}={value}" for key, value in case["expected_fields"].items()
                )
                lines.append(f'level=info msg="browse headed runtime" url={case["url"]} {fields}')
            log_path.write_text("\n".join(lines), encoding="utf-8")
            result = audit_log(log_path)
            self.assertTrue(result["ok"])
            self.assertEqual(0, result["missing_count"])

    def test_audit_log_reports_missing_internal_case(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            log_path = Path(tmp_dir) / "browse.log"
            lines = []
            for case in INTERNAL_LOG_CASES[1:]:
                fields = " ".join(
                    f"{key}={value}" for key, value in case["expected_fields"].items()
                )
                lines.append(f'level=info msg="browse headed runtime" url={case["url"]} {fields}')
            log_path.write_text("\n".join(lines), encoding="utf-8")
            result = audit_log(log_path)
            self.assertFalse(result["ok"])
            self.assertEqual(1, result["missing_count"])
            self.assertFalse(result["checks"][0]["present"])

    def test_main_emits_json_for_source_audit(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            source_path = Path(tmp_dir) / "main.zig"
            source_path.write_text(
                "\n".join(expectation["snippet"] for expectation in SOURCE_EXPECTATIONS),
                encoding="utf-8",
            )
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                exit_code = main(["source", str(source_path), "--json"])
            payload = json.loads(stdout.getvalue())
            self.assertEqual(0, exit_code)
            self.assertEqual("source", payload["audit_kind"])
            self.assertTrue(payload["ok"])

    def test_main_reports_failures_in_text_mode(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            log_path = Path(tmp_dir) / "browse.log"
            first = INTERNAL_LOG_CASES[0]
            fields = " ".join(
                f"{key}={value}" for key, value in first["expected_fields"].items()
            )
            log_path.write_text(
                f'level=info msg="browse headed runtime" url={first["url"]} {fields}\n',
                encoding="utf-8",
            )
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                exit_code = main(["log", str(log_path)])
            output = stdout.getvalue()
            self.assertEqual(1, exit_code)
            self.assertIn("[FAIL] browser-page internal startup diagnostics audit", output)
            self.assertIn("browser_settings_internal", output)


if __name__ == "__main__":
    unittest.main()
