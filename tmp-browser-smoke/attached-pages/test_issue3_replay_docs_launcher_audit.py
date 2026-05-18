import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("issue3_replay_docs_launcher_audit.py")
SPEC = importlib.util.spec_from_file_location("issue3_replay_docs_launcher_audit", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)


class Issue3ReplayDocsLauncherAuditTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        (self.root / "build.zig").write_text("", encoding="utf-8")
        (self.root / "docs").mkdir()

    def tearDown(self):
        self.tempdir.cleanup()

    def write_docs(
        self,
        replay_handoff: str,
        replay_quickstart: str,
        replay_attached_html_quickstart: str,
        top_level_attached_html_quickstart: str,
    ):
        (self.root / "docs" / "ISSUE3_REPLAY_DISCOVERY_HANDOFF.md").write_text(
            replay_handoff,
            encoding="utf-8",
        )
        (self.root / "docs" / "ISSUE3_WINDOWS_REPLAY_QUICKSTART.md").write_text(
            replay_quickstart,
            encoding="utf-8",
        )
        (
            self.root
            / "docs"
            / "ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md"
        ).write_text(
            replay_attached_html_quickstart,
            encoding="utf-8",
        )
        (
            self.root
            / "docs"
            / "ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md"
        ).write_text(
            top_level_attached_html_quickstart,
            encoding="utf-8",
        )

    def test_build_audit_counts_raw_and_wrapper_references(self):
        self.write_docs(
            "\n".join(
                [
                    "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --input '<attached-html-root>' --google-style --audit-sidecars",
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars",
                ]
            )
            + "\n",
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars\n",
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n",
            "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --input '<attached-html-root>' --audit-sidecars\n",
        )

        audit = AUDIT.build_replay_doc_audit(self.root)
        self.assertEqual(4, audit["target_doc_count"])
        self.assertEqual(2, audit["raw_python_reference_count"])
        self.assertEqual(3, audit["wrapper_reference_count"])
        self.assertEqual(3, audit["wrapper_sidecar_reference_count"])
        self.assertEqual(2, audit["google_wrapper_sidecar_reference_count"])

    def test_json_output_reports_failure_reason_for_missing_google_wrapper(self):
        wrapper_line = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\start_attached_pages_catalog.ps1 "
            "-InputPath '<attached-html-root>' -AuditSidecars\n"
        )
        self.write_docs(
            "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --input '<attached-html-root>' --audit-sidecars\n",
            wrapper_line,
            wrapper_line,
            wrapper_line,
        )

        stdout = io.StringIO()
        original_argv = sys.argv[:]
        try:
            sys.argv = [
                str(MODULE_PATH),
                "--repo-root",
                str(self.root),
                "--json",
                "--require-google-wrapper-sidecar",
            ]
            with contextlib.redirect_stdout(stdout):
                exit_code = AUDIT.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertIn(
            "no Google-style wrapper-backed sidecar audit references were found in the replay notes",
            payload["failure_reasons"],
        )

    def test_requirement_switches_succeed_for_wrapper_backed_google_path(self):
        wrapper_line = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\start_attached_pages_catalog.ps1 "
            "-InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n"
        )
        self.write_docs(
            wrapper_line,
            wrapper_line,
            wrapper_line,
            wrapper_line,
        )

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
            ]
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                exit_code = AUDIT.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(0, exit_code)
        self.assertEqual("", stderr.getvalue())
        self.assertIn("Google-style wrapper sidecar references: 4", stdout.getvalue())


if __name__ == "__main__":
    unittest.main()