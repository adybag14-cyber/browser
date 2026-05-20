import contextlib
import io
import json
import tempfile
import unittest
from collections import defaultdict
from pathlib import Path

import google_issue3_windows_replay_quickstart_audit as helper


def build_contract_map() -> dict[str, str]:
    grouped: dict[str, list[str]] = defaultdict(list)
    for expectation in helper.EXPECTATIONS:
        grouped[expectation["path"]].append(expectation["snippet"])
    return {path: "\n\n".join(snippets) + "\n" for path, snippets in grouped.items()}


DRIFT_CASES = (
    (
        "missing_replay_attached_helper_doc_command",
        "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "",
    ),
    (
        "missing_launcher_companion_doc_command",
        "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1",
        "",
    ),
    (
        "missing_suite_router_shortcut_doc_command",
        "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "",
    ),
    (
        "missing_replay_route_shortcut_doc_command",
        "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "",
    ),
    (
        "missing_windows_catalog_quickstart_doc_command",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "",
    ),
    (
        "missing_windows_validation_bridge_wiring",
        "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "windows_full_use_validation_router_attached_html_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $sharedArguments",
        "",
    ),
    (
        "missing_windows_validation_bridge_output",
        "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        'Write-Host (("  Windows validation bridge: {0}") -f $helper.commands.windows_full_use_validation_router_attached_html_bridge)',
        "",
    ),
    (
        "missing_launcher_companion_repo_root_doc_command",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'",
        "",
    ),
    (
        "missing_launcher_companion_wiring",
        "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments",
        "",
    ),
    (
        "missing_suite_router_shortcut_wiring",
        "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "suite_router_shortcut_first = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $sharedArguments",
        "",
    ),
    (
        "missing_replay_route_shortcut_wiring",
        "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "replay_route_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $sharedArguments",
        "",
    ),
    (
        "missing_replay_note_pairing_guidance",
        "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "Treat replay_attached_html_note_path as the read-first written companion to windows_replay_attached_html_quickstart",
        "drifted guidance",
    ),
    (
        "missing_launcher_surface_guidance",
        "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "Use attached_pages_launcher_surface_check and attached_pages_launcher_companion when the replay has already narrowed into attached localhost follow-up",
        "drifted guidance",
    ),
    (
        "missing_route_shortcut_output",
        "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        'Write-Host (("  Route shortcut:            {0}") -f $helper.commands.replay_route_shortcut_entrypoint)',
        "",
    ),
)


class GoogleIssue3WindowsReplayQuickstartAuditTests(unittest.TestCase):
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
        audit = helper.build_replay_quickstart_audit(self.root)
        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_selected_contract_drift_cases(self) -> None:
        contract_map = build_contract_map()

        for name, path, snippet, replacement in DRIFT_CASES:
            with self.subTest(name=name):
                self.write_contract_files(
                    {path: contract_map[path].replace(snippet, replacement)}
                )
                audit = helper.build_replay_quickstart_audit(self.root)
                self.assertGreater(audit["missing_count"], 0)
                failing = [
                    result["snippet"]
                    for result in audit["results"]
                    if not result["exists"]
                ]
                self.assertIn(snippet, failing)

    def test_missing_path_summary_groups_multiple_expectations_for_one_path(self) -> None:
        self.write_contract_files(
            {"docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md": "# drifted\n"}
        )

        audit = helper.build_replay_quickstart_audit(self.root)

        summary = {entry["path"]: entry for entry in audit["missing_paths"]}
        self.assertIn("docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md", summary)
        self.assertGreater(
            summary["docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md"][
                "missing_expectation_count"
            ],
            1,
        )
        self.assertIn(
            "replay-attached fail-fast checker visible",
            summary["docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md"][
                "first_missing_purpose"
            ],
        )
        self.assertIn(
            "check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
            summary["docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md"][
                "first_missing_snippet"
            ],
        )

    def test_text_report_surfaces_failure_count(self) -> None:
        self.write_contract_files(
            {"scripts/windows/show_google_issue3_windows_replay_quickstart.ps1": "# drifted\n"}
        )
        audit = helper.build_replay_quickstart_audit(self.root)
        report = helper.render_text_report(audit)
        self.assertIn("Google Issue #3 Windows Replay Quickstart Audit", report)
        self.assertIn("Missing expectations:", report)
        self.assertIn("[FAIL] scripts/windows/show_google_issue3_windows_replay_quickstart.ps1", report)
        self.assertIn("Missing path summary:", report)
        self.assertIn("first snippet:", report)

    def test_cli_json_output_returns_nonzero_and_grouped_summary_when_contract_drifts(self) -> None:
        self.write_contract_files(
            {"docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md": "# drifted\n"}
        )
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])
        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertGreater(payload["missing_count"], 0)
        self.assertGreater(payload["missing_path_count"], 0)
        self.assertEqual(
            "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
            payload["missing_paths"][0]["path"],
        )
        self.assertGreater(
            payload["missing_paths"][0]["missing_expectation_count"],
            1,
        )
        self.assertIn(
            "check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
            payload["missing_paths"][0]["first_missing_snippet"],
        )

    def test_cli_json_output_reports_missing_repo_root_cleanly(self) -> None:
        missing_root = self.root / "missing-repo-root"

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(missing_root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(stdout.getvalue())
        self.assertEqual("repo_root_not_found", payload["error_type"])
        self.assertEqual(str(missing_root), payload["repo_root"])
        self.assertIsNone(payload["missing_count"])
        self.assertIn("repo root does not exist:", payload["error"])

    def test_cli_text_output_reports_missing_repo_root_cleanly(self) -> None:
        missing_root = self.root / "missing-repo-root"

        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = helper.main(["--repo-root", str(missing_root)])

        self.assertEqual(1, exit_code)
        report = stdout.getvalue()
        self.assertIn("Google Issue #3 Windows Replay Quickstart Audit", report)
        self.assertIn(f"Repo root: {missing_root}", report)
        self.assertIn("Error: repo root does not exist:", report)


if __name__ == "__main__":
    unittest.main()
