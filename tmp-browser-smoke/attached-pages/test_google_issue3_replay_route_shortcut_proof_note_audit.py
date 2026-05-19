import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_replay_route_shortcut_proof_note_audit as helper


DOC_SNIPPET = """# Issue #3 Replay-Route Shortcut Bridge

- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1
```
"""


ENTRYPOINT_SCRIPT_SNIPPET = """$entrypoint = [ordered]@{
    attached_html_target_bundle_proof_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md'
    notes = @(
        'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md plus docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md reopened first'
    )
}

Write-Host (("  Bundle proof note:     {0}") -f $entrypoint.attached_html_target_bundle_proof_note_path)
"""


class GoogleIssue3ReplayRouteShortcutProofNoteAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        (self.root / "docs").mkdir()
        (self.root / "scripts" / "windows").mkdir(parents=True)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_contract_files(
        self,
        *,
        doc_text: str = DOC_SNIPPET,
        entrypoint_script_text: str = ENTRYPOINT_SCRIPT_SNIPPET,
    ) -> None:
        (self.root / "docs" / "ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md").write_text(
            doc_text,
            encoding="utf-8",
        )
        (self.root / "scripts" / "windows" / "show_google_issue3_replay_route_shortcut_entrypoint.ps1").write_text(
            entrypoint_script_text,
            encoding="utf-8",
        )

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_replay_route_shortcut_proof_note_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_proof_note_reference(self) -> None:
        self.write_contract_files(doc_text="# drifted\n")

        audit = helper.build_replay_route_shortcut_proof_note_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn("- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`", failing_snippets)

    def test_build_audit_reports_missing_proof_note_output(self) -> None:
        self.write_contract_files(
            entrypoint_script_text=ENTRYPOINT_SCRIPT_SNIPPET.replace(
                'Write-Host (("  Bundle proof note:     {0}") -f $entrypoint.attached_html_target_bundle_proof_note_path)\n',
                "",
            )
        )

        audit = helper.build_replay_route_shortcut_proof_note_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1", failing_paths)

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(entrypoint_script_text="# drifted\n")

        audit = helper.build_replay_route_shortcut_proof_note_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Replay-Route Shortcut Proof-Note Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn("[FAIL] scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1", report)

    def test_cli_json_output_returns_nonzero_when_contract_drifts(self) -> None:
        self.write_contract_files(doc_text="# drifted\n", entrypoint_script_text="# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)


if __name__ == "__main__":
    unittest.main()