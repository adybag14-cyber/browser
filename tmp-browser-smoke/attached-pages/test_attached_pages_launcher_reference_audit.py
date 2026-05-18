import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

import attached_pages_launcher_reference_audit as launcher_audit


class AttachedPagesLauncherReferenceAuditTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self):
        self.tempdir.cleanup()

    def test_detects_raw_python_and_wrapper_sidecar_references(self):
        docs_dir = self.root / "docs"
        docs_dir.mkdir()
        replay_note = docs_dir / "ISSUE3_REPLAY_DISCOVERY_HANDOFF.md"
        replay_note.write_text(
            "\n".join(
                [
                    "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --input '<attached-html-root>' --google-style --audit-sidecars",
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars",
                ]
            )
            + "\n",
            encoding="utf-8",
        )

        audit = launcher_audit.build_reference_audit(self.root)
        self.assertEqual(1, audit["files_with_raw_python"])
        self.assertEqual(1, audit["raw_python_reference_count"])
        self.assertEqual(1, audit["wrapper_reference_count"])
        self.assertEqual(1, audit["wrapper_sidecar_reference_count"])
        self.assertEqual(1, audit["google_wrapper_sidecar_reference_count"])
        self.assertEqual(1, audit["files"][0]["google_wrapper_sidecar_reference_count"])

    def test_selected_files_mode_reports_relative_display_paths(self):
        docs_dir = self.root / "docs"
        docs_dir.mkdir()
        first = docs_dir / "a.md"
        second = docs_dir / "b.md"
        first.write_text(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars\n",
            encoding="utf-8",
        )
        second.write_text(
            "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --input '<attached-html-root>' --audit-sidecars\n",
            encoding="utf-8",
        )

        audit = launcher_audit.build_reference_audit(selected_files=[first, second])
        display_paths = {entry["display_path"] for entry in audit["files"]}
        self.assertIn("a.md", display_paths)
        self.assertIn("b.md", display_paths)
        self.assertEqual(1, audit["raw_python_reference_count"])
        self.assertEqual(1, audit["wrapper_reference_count"])

    def test_text_report_surfaces_wrapper_sidecar_counts(self):
        note = self.root / "ISSUE3_WINDOWS_REPLAY_QUICKSTART.md"
        note.write_text(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n",
            encoding="utf-8",
        )

        audit = launcher_audit.build_reference_audit(self.root)
        report = launcher_audit.render_text_report(audit)
        self.assertIn("Attached Pages Launcher Reference Audit", report)
        self.assertIn("Wrapper sidecar references: 1", report)
        self.assertIn("Google-style wrapper sidecar references: 1", report)
        self.assertIn("ISSUE3_WINDOWS_REPLAY_QUICKSTART.md", report)

    def test_cli_json_output_reports_failure_reasons(self):
        note = self.root / "ISSUE3_WINDOWS_REPLAY_QUICKSTART.md"
        note.write_text(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars\n",
            encoding="utf-8",
        )

        original_argv = sys.argv[:]
        buffer = io.StringIO()
        try:
            sys.argv = [
                str(Path(launcher_audit.__file__)),
                "--root",
                str(self.root),
                "--json",
                "--require-google-wrapper-sidecar",
            ]
            with contextlib.redirect_stdout(buffer):
                exit_code = launcher_audit.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        payload = json.loads(buffer.getvalue())
        self.assertEqual(0, payload["raw_python_reference_count"])
        self.assertEqual(
            ["no Google-style wrapper-backed sidecar audit references were found"],
            payload["failure_reasons"],
        )

    def test_cli_requirement_switches_gate_success(self):
        note = self.root / "ISSUE3_WINDOWS_REPLAY_QUICKSTART.md"
        note.write_text(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n",
            encoding="utf-8",
        )

        original_argv = sys.argv[:]
        stdout = io.StringIO()
        stderr = io.StringIO()
        try:
            sys.argv = [
                str(Path(launcher_audit.__file__)),
                "--root",
                str(self.root),
                "--require-wrapper-sidecar",
                "--require-google-wrapper-sidecar",
            ]
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                exit_code = launcher_audit.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(0, exit_code)
        self.assertEqual("", stderr.getvalue())

    def test_cli_allow_raw_launcher_still_requires_google_wrapper_when_requested(self):
        note = self.root / "ISSUE3_WINDOWS_REPLAY_QUICKSTART.md"
        note.write_text(
            "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --input '<attached-html-root>' --audit-sidecars\n",
            encoding="utf-8",
        )

        original_argv = sys.argv[:]
        stdout = io.StringIO()
        stderr = io.StringIO()
        try:
            sys.argv = [
                str(Path(launcher_audit.__file__)),
                "--root",
                str(self.root),
                "--allow-raw-launcher",
                "--require-google-wrapper-sidecar",
            ]
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                exit_code = launcher_audit.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        self.assertIn("FAIL: no Google-style wrapper-backed sidecar audit references were found", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()