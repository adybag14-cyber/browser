import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("issue3_attached_entrypoint_docs_audit.py")
SPEC = importlib.util.spec_from_file_location(
    "issue3_attached_entrypoint_docs_audit", MODULE_PATH
)
assert SPEC is not None and SPEC.loader is not None
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)


class Issue3AttachedEntrypointDocsAuditTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        (self.root / "build.zig").write_text("", encoding="utf-8")
        (self.root / "docs").mkdir()

    def tearDown(self):
        self.tempdir.cleanup()

    def write_docs(self, google_entrypoint: str, top_level_quickstart: str):
        (self.root / "docs" / "ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md").write_text(
            google_entrypoint,
            encoding="utf-8",
        )
        (self.root / "docs" / "ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md").write_text(
            top_level_quickstart,
            encoding="utf-8",
        )

    def test_build_audit_counts_raw_wrapper_and_surface_check_references(self):
        issue_check_line = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1\n"
        )
        top_level_check_line = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\check_google_issue3_top_level_attached_html_quickstart_validation_surface.ps1\n"
        )
        wrapper_google_sidecar_line = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\start_attached_pages_catalog.ps1 "
            "-InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n"
        )
        raw_python_line = (
            "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py "
            "--audit-sidecars --input '<attached-html-root>'\n"
        )
        self.write_docs(
            issue_check_line + wrapper_google_sidecar_line,
            top_level_check_line + wrapper_google_sidecar_line + raw_python_line,
        )

        audit = AUDIT.build_entrypoint_doc_audit(self.root)
        self.assertEqual(2, audit["target_doc_count"])
        self.assertEqual(1, audit["raw_python_reference_count"])
        self.assertEqual(2, audit["wrapper_reference_count"])
        self.assertEqual(2, audit["wrapper_sidecar_reference_count"])
        self.assertEqual(2, audit["google_wrapper_sidecar_reference_count"])
        self.assertEqual(1, audit["issue_entrypoint_surface_check_reference_count"])
        self.assertEqual(1, audit["top_level_surface_check_reference_count"])

    def test_json_output_reports_failure_reasons_for_missing_surface_checks(self):
        wrapper_google_sidecar_line = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\start_attached_pages_catalog.ps1 "
            "-InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n"
        )
        self.write_docs(wrapper_google_sidecar_line, wrapper_google_sidecar_line)

        stdout = io.StringIO()
        original_argv = sys.argv[:]
        try:
            sys.argv = [
                str(MODULE_PATH),
                "--repo-root",
                str(self.root),
                "--json",
                "--require-issue-entrypoint-surface-check",
                "--require-top-level-surface-check",
            ]
            with contextlib.redirect_stdout(stdout):
                exit_code = AUDIT.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertIn(
            "no issue-specific Google attached-html surface-check references were found in the attached entrypoint notes",
            payload["failure_reasons"],
        )
        self.assertIn(
            "no top-level attached-html surface-check references were found in the attached entrypoint notes",
            payload["failure_reasons"],
        )

    def test_requirement_switches_succeed_for_wrapper_and_surface_check_coverage(self):
        issue_check_line = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1\n"
        )
        top_level_check_line = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\check_google_issue3_top_level_attached_html_quickstart_validation_surface.ps1\n"
        )
        wrapper_google_sidecar_line = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\start_attached_pages_catalog.ps1 "
            "-InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n"
        )
        combined = issue_check_line + top_level_check_line + wrapper_google_sidecar_line
        self.write_docs(combined, combined)

        stdout = io.StringIO()
        stderr = io.StringIO()
        original_argv = sys.argv[:]
        try:
            sys.argv = [
                str(MODULE_PATH),
                "--repo-root",
                str(self.root),
                "--require-wrapper-sidecar",
                "--require-google-wrapper-sidecar",
                "--require-issue-entrypoint-surface-check",
                "--require-top-level-surface-check",
            ]
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                exit_code = AUDIT.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(0, exit_code)
        self.assertEqual("", stderr.getvalue())
        self.assertIn("Issue-specific surface-check references: 2", stdout.getvalue())
        self.assertIn("Top-level surface-check references: 2", stdout.getvalue())


if __name__ == "__main__":
    unittest.main()