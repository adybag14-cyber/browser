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


DRIFT_CASES = (
    (
        "validation_router_quickstart_note",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1",
        "",
    ),
    (
        "google_surface_check_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot",
        "",
    ),
    (
        "google_surface_check_guidance",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "Use google_attached_html_surface_check when branch state may have moved and the replay should fail fast on the dedicated Google-shaped attached-page lane before reopening the narrower Google helper from this same replay ladder.",
        "drifted note",
    ),
    (
        "bundle_proof_note_reference",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`",
        "",
    ),
    (
        "bundle_proof_entry_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Bundle proof entry:      {0}") -f $helper.commands.attached_bundle_proof_entrypoint)',
        "",
    ),
    (
        "launcher_surface_check_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Launcher surface check:   {0}") -f $helper.commands.attached_pages_launcher_companion_surface_check)',
        "",
    ),
    (
        "launcher_windows_replay_wiring",
        "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "windows_replay_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $wrapperArguments",
        "",
    ),
    (
        "launcher_replay_route_guidance",
        "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "Use replay_route_shortcut when the preflight already narrowed the problem and you want the shorter replay-route companion visible before the route drops into the attached-page shortcut, replay shortcuts, contextual flow, bundle-first reuse, or the safe-route map.",
        "drifted note",
    ),
    (
        "replay_route_shortcut_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Replay-route shortcut:    {0}") -f $helper.commands.replay_route_shortcut)',
        "",
    ),
    (
        "replay_route_shortcut_surface_check_note",
        "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1",
        "",
    ),
    (
        "replay_windows_bridge_surface_check_wiring",
        "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1",
        "windows_replay_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "",
    ),
    (
        "replay_to_windows_wiring",
        "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "replay_shortcuts_windows_replay_attached_html_bridge = $replayShortcutsWindowsReplayAttachedHtmlBridgeCommand",
        "",
    ),
    (
        "replay_to_windows_guidance",
        "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "Use replay_shortcuts_windows_replay_attached_html_bridge when the replay-route shortcut still needs the replay-side surface check, the Windows replay attached-page quickstart, and the broader Windows-first bridge kept visible before the route collapses back to the shorter attached-page helper chain.",
        "drifted note",
    ),
    (
        "google_entrypoint_note_command",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1",
        "",
    ),
    (
        "google_entrypoint_issue_specific_output",
        "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        'Write-Host (("  9. Issue-specific check: {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)',
        "",
    ),
    (
        "google_entrypoint_companion_flow_guidance",
        "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "Use google_attached_html_validation_flow when the broader Google-style attached-page flow helper still needs to stay visible after the sidecar audit, broader surface check, asset audit, and dedicated entrypoint surface check and before the route narrows into the shorter issue #3 shortcut-first, replay-shortcut, context-preserving, or bundle-aware branches.",
        "drifted note",
    ),
    (
        "google_entrypoint_companion_flow_output",
        "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        'Write-Host (("  Google attached flow:  {0}") -f $entrypoint.helper_commands.google_attached_html_validation_flow)',
        "",
    ),
)


class GoogleIssue3WindowsReplayAttachedHtmlQuickstartAuditTests(unittest.TestCase):
    maxDiff = None

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

    def test_build_audit_reports_selected_contract_drift_cases(self) -> None:
        contract_map = build_contract_map()

        for name, path, snippet, replacement in DRIFT_CASES:
            with self.subTest(name=name):
                self.write_contract_files(
                    {path: contract_map[path].replace(snippet, replacement)}
                )
                audit = helper.build_replay_attached_quickstart_audit(self.root)
                self.assertGreater(audit["missing_count"], 0)
                failing = [
                    result["snippet"]
                    for result in audit["results"]
                    if not result["exists"]
                ]
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


if __name__ == "__main__":
    unittest.main()
