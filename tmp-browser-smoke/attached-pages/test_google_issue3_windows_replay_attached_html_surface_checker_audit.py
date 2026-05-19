import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_windows_replay_attached_html_surface_checker_audit as helper


CHECKER_SNIPPET = """$references = @(
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md" -Kind "file" -Purpose "Pinned bundle proof note."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1" -Kind "file" -Purpose "Launcher checker."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Kind "file" -Purpose "Launcher helper."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Proof checker."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Kind "file" -Purpose "Proof helper.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Snippet 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md' -Purpose "Proof note survives."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Purpose "Proof checker survives."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "attached_pages_launcher_companion_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $routeSurfaceArguments" -Purpose "Launcher checker stays wired."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "attached_bundle_proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $sharedArguments" -Purpose "Proof helper stays wired."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet "proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $surfaceCheckArguments" -Purpose "Launcher proof bridge stays wired."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet 'Write-Host ((\\\"  Proof entrypoint:   {0}\\\") -f $helper.helper_commands.proof_entrypoint)' -Purpose "Launcher proof helper stays printed.")
)

Write-Host "Google issue #3 Windows replay attached-html quickstart surface is intact, including the suite-catalog fail-fast discovery block, the replay-side helper contract, the compact attached-bundle surface, the executable proof-entrypoint checker/helper pair, the launcher-companion proof bridge, the pinned proof-only bundle follow-up, the bundle-first replay branch, and the broader attached-page fallbacks that keep the shorter replay note honest."
"""


class GoogleIssue3WindowsReplayAttachedHtmlSurfaceCheckerAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        (self.root / "scripts" / "windows").mkdir(parents=True)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_checker(self, text: str = CHECKER_SNIPPET) -> None:
        (self.root / helper.CHECKER_PATH).write_text(text, encoding="utf-8")

    def test_build_audit_passes_when_checker_contract_is_present(self) -> None:
        self.write_checker()

        audit = helper.build_surface_checker_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_launcher_reference(self) -> None:
        self.write_checker(
            CHECKER_SNIPPET.replace(
                '(New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Kind "file" -Purpose "Launcher helper."),\n',
                "",
            )
        )

        audit = helper.build_surface_checker_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_snippets = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            '(New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Kind "file"',
            failing_snippets,
        )

    def test_build_audit_reports_missing_launcher_proof_bridge_expectation(self) -> None:
        self.write_checker(
            CHECKER_SNIPPET.replace(
                '(New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet "proof_surface_check = Format-HelperCommand -ScriptName \'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1\' -Arguments $surfaceCheckArguments" -Purpose "Launcher proof bridge stays wired."),\n',
                "",
            )
        )

        audit = helper.build_surface_checker_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_purposes = [result["purpose"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "The replay-attached surface checker verifies the launcher companion helper still bridges directly into the proof checker.",
            failing_purposes,
        )

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_checker("# drifted\n")

        audit = helper.build_surface_checker_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Windows Replay Attached HTML Surface Checker Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn("[FAIL] scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1", report)

    def test_cli_json_output_returns_nonzero_when_checker_drifts(self) -> None:
        self.write_checker("# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)


if __name__ == "__main__":
    unittest.main()
