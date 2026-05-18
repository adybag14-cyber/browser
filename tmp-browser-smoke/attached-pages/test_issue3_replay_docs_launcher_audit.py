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

    def test_build_audit_counts_raw_wrapper_and_companion_references(self):
        self.write_docs(
            "\n".join(
                [
                    "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --input '<attached-html-root>' --google-style --audit-sidecars",
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars",
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1",
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
        self.assertEqual(1, audit["launcher_companion_reference_count"])
        self.assertEqual(1, audit["launcher_companion_surface_check_reference_count"])

    def test_json_output_reports_failure_reasons_for_missing_companion_surface(self):
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
        original_argv = sys.argv[:]
        try:
            sys.argv = [
                str(MODULE_PATH),
                "--repo-root",
                str(self.root),
                "--json",
                "--require-launcher-companion",
                "--require-launcher-companion-surface-check",
            ]
            with contextlib.redirect_stdout(stdout):
                exit_code = AUDIT.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertIn(
            "no launcher companion helper references were found in the replay notes",
            payload["failure_reasons"],
        )
        self.assertIn(
            "no launcher companion surface-check references were found in the replay notes",
            payload["failure_reasons"],
        )

    def test_json_output_reports_quickstart_specific_raw_launcher_failure(self):
        wrapper_line = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\start_attached_pages_catalog.ps1 "
            "-InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n"
        )
        raw_quickstart_line = (
            "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py "
            "--input '<attached-html-root>' --google-style --audit-sidecars\n"
        )
        self.write_docs(
            wrapper_line,
            raw_quickstart_line,
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
            ]
            with contextlib.redirect_stdout(stdout):
                exit_code = AUDIT.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertIn(
            "raw Python attached-pages launcher references remain",
            payload["failure_reasons"],
        )
        self.assertIn(
            "Windows replay quickstart still carries raw Python attached-pages launcher references",
            payload["failure_reasons"],
        )

    def test_requirement_switches_succeed_for_wrapper_and_companion_coverage(self):
        wrapper_line = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\start_attached_pages_catalog.ps1 "
            "-InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n"
        )
        surface_check_line = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1\n"
        )
        companion_line = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1\n"
        )
        combined = wrapper_line + surface_check_line + companion_line
        self.write_docs(combined, combined, combined, combined)

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
                "--require-launcher-companion",
                "--require-launcher-companion-surface-check",
            ]
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                exit_code = AUDIT.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(0, exit_code)
        self.assertEqual("", stderr.getvalue())
        self.assertIn("Launcher companion references: 4", stdout.getvalue())
        self.assertIn(
            "Launcher companion surface-check references: 4",
            stdout.getvalue(),
        )

    def test_quickstart_google_wrapper_path_replaces_raw_launcher(self):
        replay_handoff = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\start_attached_pages_catalog.ps1 "
            "-InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n"
        )
        replay_quickstart = replay_handoff
        replay_attached_html_quickstart = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\start_attached_pages_catalog.ps1 "
            "-InputPath '<attached-html-root>' -AuditSidecars\n"
        )
        top_level_attached_html_quickstart = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\start_attached_pages_catalog.ps1 "
            "-InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n"
        )
        self.write_docs(
            replay_handoff,
            replay_quickstart,
            replay_attached_html_quickstart,
            top_level_attached_html_quickstart,
        )

        audit = AUDIT.build_replay_doc_audit(self.root)
        quickstart_result = next(
            file_result
            for file_result in audit["files"]
            if file_result["display_path"] == "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md"
        )

        self.assertEqual(0, quickstart_result["raw_python_reference_count"])
        self.assertEqual(1, quickstart_result["google_wrapper_sidecar_reference_count"])


if __name__ == "__main__":
    unittest.main()