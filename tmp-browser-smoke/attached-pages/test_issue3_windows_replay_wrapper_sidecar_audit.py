import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("issue3_windows_replay_wrapper_sidecar_audit.py")
SPEC = importlib.util.spec_from_file_location(
    "issue3_windows_replay_wrapper_sidecar_audit", MODULE_PATH
)
assert SPEC is not None and SPEC.loader is not None
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)


class Issue3WindowsReplayWrapperSidecarAuditTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        (self.root / "build.zig").write_text("", encoding="utf-8")
        (self.root / "docs").mkdir()

    def tearDown(self):
        self.tempdir.cleanup()

    def write_docs(self, replay_quickstart: str, replay_attached_html_quickstart: str):
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

    def test_build_audit_counts_raw_and_wrapper_references(self):
        wrapper_line = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\start_attached_pages_catalog.ps1 "
            "-InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n"
        )
        self.write_docs(
            "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --input '<attached-html-root>' --google-style --audit-sidecars\n"
            + wrapper_line,
            wrapper_line,
        )

        audit = AUDIT.build_audit(self.root)
        self.assertEqual(2, audit["target_doc_count"])
        self.assertEqual(1, audit["raw_python_reference_count"])
        self.assertEqual(2, audit["wrapper_reference_count"])
        self.assertEqual(2, audit["google_wrapper_sidecar_reference_count"])

    def test_json_output_reports_failure_for_raw_launcher_drift(self):
        wrapper_line = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\start_attached_pages_catalog.ps1 "
            "-InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n"
        )
        self.write_docs(
            "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --input '<attached-html-root>' --google-style --audit-sidecars\n"
            + wrapper_line,
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
            ]
            with contextlib.redirect_stdout(stdout):
                exit_code = AUDIT.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertIn(
            "raw Python attached-pages launcher references remain in the Windows replay notes",
            payload["failure_reasons"],
        )

    def test_json_output_reports_failure_when_wrapper_sidecar_is_missing(self):
        self.write_docs(
            "No wrapper-backed commands here.\n",
            "Still no wrapper-backed commands here.\n",
        )

        stdout = io.StringIO()
        original_argv = sys.argv[:]
        try:
            sys.argv = [
                str(MODULE_PATH),
                "--repo-root",
                str(self.root),
                "--json",
                "--allow-raw-launcher",
            ]
            with contextlib.redirect_stdout(stdout):
                exit_code = AUDIT.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertIn(
            "no Google-style wrapper-backed sidecar audit references were found in the Windows replay notes",
            payload["failure_reasons"],
        )

    def test_success_when_both_windows_replay_notes_use_wrapper_sidecar_commands(self):
        wrapper_line = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\start_attached_pages_catalog.ps1 "
            "-InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n"
        )
        self.write_docs(wrapper_line, wrapper_line)

        stdout = io.StringIO()
        stderr = io.StringIO()
        original_argv = sys.argv[:]
        try:
            sys.argv = [
                str(MODULE_PATH),
                "--repo-root",
                str(self.root),
            ]
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                exit_code = AUDIT.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(0, exit_code)
        self.assertEqual("", stderr.getvalue())
        self.assertIn("Raw Python launcher references: 0", stdout.getvalue())
        self.assertIn(
            "Google-style wrapper sidecar references: 2",
            stdout.getvalue(),
        )


if __name__ == "__main__":
    unittest.main()