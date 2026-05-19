import contextlib
import io
import json
import tempfile
import unittest
from collections import defaultdict
from pathlib import Path

import google_issue3_windows_replay_attached_html_quickstart_audit as helper


def build_contract_map() -> dict[str, str]:
    grouped: dict[str, list[str]] = defaultdict(list)
    for expectation in helper.EXPECTATIONS:
        grouped[expectation["path"]].append(expectation["snippet"])
    return {path: "\n\n".join(snippets) + "\n" for path, snippets in grouped.items()}


class GoogleIssue3WindowsReplayAttachedHtmlQuickstartAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_contract_files(self, overrides: dict[str, str] | None = None) -> None:
        contract_map = build_contract_map()
        if overrides:
            contract_map.update(overrides)
        for rel_path, content in contract_map.items():
            path = self.root / rel_path
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()
        audit = helper.build_replay_attached_quickstart_audit(self.root)
        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_missing_validation_router_quickstart_command(self) -> None:
        contract_map = build_contract_map()
        path = "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md"
        snippet = (
            "powershell -ExecutionPolicy Bypass -File "
            ".\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1"
        )
        self.write_contract_files({path: contract_map[path].replace(snippet, "")})
        audit = helper.build_replay_attached_quickstart_audit(self.root)
        self.assertGreater(audit["missing_count"], 0)
        failing = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(snippet, failing)

    def test_build_audit_reports_missing_google_surface_check_wiring(self) -> None:
        contract_map = build_contract_map()
        path = "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"
        snippet = (
            "google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv "
            "-ScriptName 'check_google_attached_html_validation_surface.ps1' "
            "-RepoRootOverride $RepoRoot"
        )
        self.write_contract_files({path: contract_map[path].replace(snippet, "")})
        audit = helper.build_replay_attached_quickstart_audit(self.root)
        self.assertGreater(audit["missing_count"], 0)
        failing = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(snippet, failing)

    def test_build_audit_reports_missing_google_surface_check_guidance(self) -> None:
        contract_map = build_contract_map()
        path = "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"
        snippet = (
            "Use google_attached_html_surface_check when branch state may have moved "
            "and the replay should fail fast on the dedicated Google-shaped attached-page "
            "lane before reopening the narrower Google helper from this same replay ladder."
        )
        self.write_contract_files({path: contract_map[path].replace(snippet, "drifted note")})
        audit = helper.build_replay_attached_quickstart_audit(self.root)
        self.assertGreater(audit["missing_count"], 0)
        failing = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(snippet, failing)

    def test_build_audit_reports_missing_attached_bundle_output(self) -> None:
        contract_map = build_contract_map()
        path = "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"
        snippet = 'Write-Host (("  Attached bundle:        {0}") -f $helper.top_level_commands.attached_bundle_change_area)'
        self.write_contract_files({path: contract_map[path].replace(snippet, "")})
        audit = helper.build_replay_attached_quickstart_audit(self.root)
        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(path, failing_paths)

    def test_build_audit_reports_missing_route_surface_check_output(self) -> None:
        contract_map = build_contract_map()
        path = "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"
        snippet = 'Write-Host (("  Route surface check:     {0}") -f $helper.commands.windows_full_use_attached_html_route_surface_check)'
        self.write_contract_files({path: contract_map[path].replace(snippet, "")})
        audit = helper.build_replay_attached_quickstart_audit(self.root)
        self.assertGreater(audit["missing_count"], 0)
        failing = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(snippet, failing)

    def test_build_audit_reports_missing_catalog_quickstart_output(self) -> None:
        contract_map = build_contract_map()
        path = "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"
        snippet = 'Write-Host (("  Catalog quickstart:       {0}") -f $helper.commands.windows_full_use_attached_html_catalog_quickstart)'
        self.write_contract_files({path: contract_map[path].replace(snippet, "")})
        audit = helper.build_replay_attached_quickstart_audit(self.root)
        self.assertGreater(audit["missing_count"], 0)
        failing = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(snippet, failing)

    def test_build_audit_reports_missing_launcher_surface_check_output(self) -> None:
        contract_map = build_contract_map()
        path = "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"
        snippet = 'Write-Host (("  Launcher surface check:   {0}") -f $helper.commands.attached_pages_launcher_companion_surface_check)'
        self.write_contract_files({path: contract_map[path].replace(snippet, "")})
        audit = helper.build_replay_attached_quickstart_audit(self.root)
        self.assertGreater(audit["missing_count"], 0)
        failing = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(snippet, failing)

    def test_build_audit_reports_missing_launcher_companion_output(self) -> None:
        contract_map = build_contract_map()
        path = "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"
        snippet = 'Write-Host (("  Launcher companion:       {0}") -f $helper.commands.attached_pages_launcher_companion)'
        self.write_contract_files({path: contract_map[path].replace(snippet, "")})
        audit = helper.build_replay_attached_quickstart_audit(self.root)
        self.assertGreater(audit["missing_count"], 0)
        failing = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(snippet, failing)

    def test_build_audit_reports_missing_bundle_proof_surface_check_wiring(self) -> None:
        contract_map = build_contract_map()
        path = "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"
        snippet = (
            "attached_bundle_proof_surface_check = Format-HelperCommand -ScriptName "
            "'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' "
            "-Arguments $routeSurfaceArguments"
        )
        self.write_contract_files({path: contract_map[path].replace(snippet, "")})
        audit = helper.build_replay_attached_quickstart_audit(self.root)
        self.assertGreater(audit["missing_count"], 0)
        failing = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(snippet, failing)

    def test_build_audit_reports_missing_bundle_proof_entry_output(self) -> None:
        contract_map = build_contract_map()
        path = "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"
        snippet = 'Write-Host (("  Bundle proof entry:      {0}") -f $helper.commands.attached_bundle_proof_entrypoint)'
        self.write_contract_files({path: contract_map[path].replace(snippet, "")})
        audit = helper.build_replay_attached_quickstart_audit(self.root)
        self.assertGreater(audit["missing_count"], 0)
        failing = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(snippet, failing)

    def test_build_audit_reports_missing_bundle_proof_guidance(self) -> None:
        contract_map = build_contract_map()
        path = "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"
        snippet = (
            "Use attached_bundle_proof_entrypoint when the replay is already pinned "
            "to the known three-page compatibility bundle and you want the proof-only "
            "follow-up helper kept visible beside the proof surface checker before the "
            "route widens again."
        )
        self.write_contract_files({path: contract_map[path].replace(snippet, "drifted note")})
        audit = helper.build_replay_attached_quickstart_audit(self.root)
        self.assertGreater(audit["missing_count"], 0)
        failing = [result["snippet"] for result in audit["results"] if not result["exists"]]
        self.assertIn(snippet, failing)

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(
            {"docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md": "# drifted\n"}
        )
        audit = helper.build_replay_attached_quickstart_audit(self.root)
        report = helper.render_text_report(audit)
        self.assertIn("Google Issue #3 Windows Replay Attached HTML Quickstart Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn("[FAIL] docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md", report)

    def test_cli_json_output_returns_nonzero_when_contract_drifts(self) -> None:
        self.write_contract_files(
            {"scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1": "# drifted\n"}
        )
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])
        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)


if __name__ == "__main__":
    unittest.main()
