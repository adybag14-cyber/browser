import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

import issue3_bundle_proof_reference_audit as proof_audit


class Issue3BundleProofReferenceAuditTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self):
        self.tempdir.cleanup()

    def test_detects_proof_helper_note_and_bundle_route_references(self):
        docs_dir = self.root / "docs"
        docs_dir.mkdir()
        quickstart = docs_dir / "ISSUE3_WINDOWS_REPLAY_QUICKSTART.md"
        quickstart.write_text(
            "\n".join(
                [
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_target_bundle_validation_surface.ps1",
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1 -Wait",
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
                    "- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`",
                ]
            )
            + "\n",
            encoding="utf-8",
        )

        audit = proof_audit.build_reference_audit(self.root)
        self.assertEqual(1, audit["proof_helper_reference_count"])
        self.assertEqual(1, audit["proof_note_reference_count"])
        self.assertEqual(1, audit["bundle_surface_reference_count"])
        self.assertEqual(1, audit["bundle_check_reference_count"])
        self.assertEqual(1, audit["bundle_runner_reference_count"])

    def test_selected_files_mode_uses_relative_display_paths(self):
        docs_dir = self.root / "docs"
        docs_dir.mkdir()
        first = docs_dir / "a.md"
        second = docs_dir / "b.md"
        first.write_text(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1\n",
            encoding="utf-8",
        )
        second.write_text(
            "- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`\n",
            encoding="utf-8",
        )

        audit = proof_audit.build_reference_audit(selected_files=[first, second])
        display_paths = {entry["display_path"] for entry in audit["files"]}
        self.assertIn("a.md", display_paths)
        self.assertIn("b.md", display_paths)
        self.assertEqual(1, audit["proof_helper_reference_count"])
        self.assertEqual(1, audit["proof_note_reference_count"])

    def test_text_report_surfaces_bundle_route_counts(self):
        note = self.root / "ISSUE3_REPLAY_DISCOVERY_HANDOFF.md"
        note.write_text(
            "\n".join(
                [
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1 -Wait",
                ]
            )
            + "\n",
            encoding="utf-8",
        )

        audit = proof_audit.build_reference_audit(self.root)
        report = proof_audit.render_text_report(audit)
        self.assertIn("Issue #3 Bundle Proof Reference Audit", report)
        self.assertIn("Bundle surface references: 1", report)
        self.assertIn("Bundle runner references: 1", report)
        self.assertIn("ISSUE3_REPLAY_DISCOVERY_HANDOFF.md", report)

    def test_cli_json_output_reports_failure_reasons(self):
        note = self.root / "ISSUE3_WINDOWS_REPLAY_QUICKSTART.md"
        note.write_text(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1\n",
            encoding="utf-8",
        )

        original_argv = sys.argv[:]
        buffer = io.StringIO()
        try:
            sys.argv = [
                str(Path(proof_audit.__file__)),
                "--root",
                str(self.root),
                "--json",
                "--require-proof-note",
                "--require-bundle-runner",
            ]
            with contextlib.redirect_stdout(buffer):
                exit_code = proof_audit.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(1, exit_code)
        payload = json.loads(buffer.getvalue())
        self.assertEqual(1, payload["proof_helper_reference_count"])
        self.assertEqual(
            [
                "no issue #3 bundle proof note references were found",
                "no issue #3 bundle runner references were found",
            ],
            payload["failure_reasons"],
        )

    def test_cli_requirement_switches_gate_success(self):
        note = self.root / "ISSUE3_WINDOWS_REPLAY_QUICKSTART.md"
        note.write_text(
            "\n".join(
                [
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
                    "- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`",
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
                    "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1 -Wait",
                ]
            )
            + "\n",
            encoding="utf-8",
        )

        original_argv = sys.argv[:]
        stdout = io.StringIO()
        stderr = io.StringIO()
        try:
            sys.argv = [
                str(Path(proof_audit.__file__)),
                "--root",
                str(self.root),
                "--require-proof-helper",
                "--require-proof-note",
                "--require-bundle-surface",
                "--require-bundle-runner",
            ]
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                exit_code = proof_audit.main()
        finally:
            sys.argv = original_argv

        self.assertEqual(0, exit_code)
        self.assertEqual("", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()