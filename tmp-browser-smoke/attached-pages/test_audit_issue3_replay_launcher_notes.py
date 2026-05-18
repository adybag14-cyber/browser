import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

import audit_issue3_replay_launcher_notes as replay_note_audit


class Issue3ReplayLauncherNoteAuditTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.repo_root = Path(self.tempdir.name)
        (self.repo_root / "docs").mkdir()
        self._write(
            "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md",
            "python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --input '<attached-html-root>' --google-style --audit-sidecars\n",
        )
        self._write(
            "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars\n",
        )
        self._write(
            "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars\n",
        )
        self._write(
            "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md",
            "No launcher reference here.\n",
        )

    def tearDown(self):
        self.tempdir.cleanup()

    def _write(self, relative_path: str, content: str) -> None:
        path = self.repo_root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")

    def test_build_issue3_replay_audit_targets_default_note_family(self):
        audit = replay_note_audit.build_issue3_replay_audit(self.repo_root)
        self.assertEqual("issue3-replay-launcher-notes", audit["profile"])
        self.assertEqual(list(replay_note_audit.DEFAULT_REPLAY_NOTE_PATHS), audit["selected_note_paths"])
        self.assertEqual(4, audit["file_count"])
        self.assertEqual(1, audit["raw_python_reference_count"])
        self.assertEqual(2, audit["wrapper_reference_count"])
        self.assertEqual(2, audit["wrapper_sidecar_reference_count"])
        self.assertEqual(1, audit["google_wrapper_sidecar_reference_count"])

    def test_text_report_lists_selected_notes(self):
        audit = replay_note_audit.build_issue3_replay_audit(self.repo_root)
        report = replay_note_audit.render_issue3_replay_text_report(audit)
        self.assertIn("Issue #3 Replay Launcher Note Audit", report)
        self.assertIn("- docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md", report)
        self.assertIn("Raw Python launcher references: 1", report)
        self.assertIn("Wrapper sidecar references: 2", report)

    def test_cli_json_reports_failure_reasons(self):
        original_argv = sys.argv[:]
        stdout = io.StringIO()
        try:
            sys.argv = [
                str(Path(replay_note_audit.__file__)),
                "--repo-root",
                str(self.repo_root),
                "--json",
                "--require-google-wrapper-sidecar",
                "--allow-raw-launcher",
            ]
            with contextlib.redirect_stdout(stdout):
                exit_code = replay_note_audit.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(0, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual([], payload["failure_reasons"])
        self.assertEqual(1, payload["google_wrapper_sidecar_reference_count"])

    def test_cli_requires_wrapper_sidecar_when_requested(self):
        self._write("docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md", "No wrapper here.\n")
        self._write("docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md", "No wrapper here either.\n")

        original_argv = sys.argv[:]
        stdout = io.StringIO()
        try:
            sys.argv = [
                str(Path(replay_note_audit.__file__)),
                "--repo-root",
                str(self.repo_root),
                "--json",
                "--allow-raw-launcher",
                "--require-wrapper-sidecar",
            ]
            with contextlib.redirect_stdout(stdout):
                exit_code = replay_note_audit.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual(["no wrapper-backed sidecar audit references were found"], payload["failure_reasons"])


if __name__ == "__main__":
    unittest.main()
