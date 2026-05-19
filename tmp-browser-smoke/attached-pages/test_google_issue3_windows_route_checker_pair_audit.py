import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import google_issue3_windows_route_checker_pair_audit as helper


FULL_USE_ROUTE_DOC = """powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars
"""

REPLAY_ROUTE_DOC = """powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1
powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1
"""

FULL_USE_CHECKER = """(New-ValidationReference -Path \"docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md\" -Kind \"file\" -Purpose \"Replay-side attached-page quickstart note kept beside the broader Windows full-use route.\")
(New-ValidationReference -Path \"scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1\" -Kind \"file\" -Purpose \"Replay-side attached-page quickstart helper referenced by the newer Windows replay route notes.\")
(New-ValidationContentExpectation -Path \"docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md\" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath ''<attached-html-root>'' -AuditSidecars'
"""

REPLAY_CHECKER = """(New-ValidationReference -Path \"scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1\" -Kind \"file\" -Purpose \"Fail-fast launcher companion checker that should stay visible once the replay helper surfaces the sidecar-first attached-pages route.\")
(New-ValidationReference -Path \"scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1\" -Kind \"file\" -Purpose \"Launcher companion helper that keeps the wrapper-backed sidecar audit route and the pinned proof-only bundle follow-up visible from the replay ladder.\")
(New-ValidationReference -Path \"scripts/windows/check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1\" -Kind \"file\" -Purpose \"Proof-entrypoint surface checker surfaced directly from the replay-side ladder when proof-only bundle follow-up matters.\")
(New-ValidationReference -Path \"scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1\" -Kind \"file\" -Purpose \"Proof-entrypoint helper surfaced directly from the replay-side ladder when proof-only bundle follow-up matters.\")
"""


class GoogleIssue3WindowsRouteCheckerPairAuditTests(unittest.TestCase):
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
        full_use_route_doc: str = FULL_USE_ROUTE_DOC,
        replay_route_doc: str = REPLAY_ROUTE_DOC,
        full_use_checker: str = FULL_USE_CHECKER,
        replay_checker: str = REPLAY_CHECKER,
    ) -> None:
        (self.root / "docs" / "ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md").write_text(
            full_use_route_doc, encoding="utf-8"
        )
        (self.root / "docs" / "ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md").write_text(
            replay_route_doc, encoding="utf-8"
        )
        (
            self.root / "scripts" / "windows" / "check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1"
        ).write_text(full_use_checker, encoding="utf-8")
        (
            self.root / "scripts" / "windows" / "check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1"
        ).write_text(replay_checker, encoding="utf-8")

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()

        audit = helper.build_route_checker_pair_audit(self.root)

        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_sidecar_audit_route(self) -> None:
        self.write_contract_files(
            full_use_route_doc=FULL_USE_ROUTE_DOC.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -AuditSidecars\n",
                "",
            )
        )

        audit = helper.build_route_checker_pair_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md", failing_paths)

    def test_build_audit_reports_missing_launcher_companion_reference(self) -> None:
        self.write_contract_files(
            replay_checker=REPLAY_CHECKER.replace(
                '(New-ValidationReference -Path \"scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1\" -Kind \"file\" -Purpose \"Launcher companion helper that keeps the wrapper-backed sidecar audit route and the pinned proof-only bundle follow-up visible from the replay ladder.\")\n',
                "",
            )
        )

        audit = helper.build_route_checker_pair_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(
            "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
            failing_paths,
        )

    def test_build_audit_reports_missing_proof_route_command(self) -> None:
        self.write_contract_files(
            replay_route_doc=REPLAY_ROUTE_DOC.replace(
                "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1\n",
                "",
            )
        )

        audit = helper.build_route_checker_pair_audit(self.root)

        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn("docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md", failing_paths)

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(full_use_checker="# drifted\n")

        audit = helper.build_route_checker_pair_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Google Issue #3 Windows Route Checker Pair Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn(
            "[FAIL] scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1",
            report,
        )

    def test_cli_json_output_returns_nonzero_when_contract_drifts(self) -> None:
        self.write_contract_files(replay_route_doc="# drifted\n")

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)


if __name__ == "__main__":
    unittest.main()