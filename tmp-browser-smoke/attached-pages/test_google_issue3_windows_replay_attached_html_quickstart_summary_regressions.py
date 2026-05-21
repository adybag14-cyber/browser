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


class GoogleIssue3WindowsReplayAttachedHtmlQuickstartSummaryRegressionTests(
    unittest.TestCase
):
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

    def test_build_audit_keeps_multiple_missing_paths_grouped_separately(self) -> None:
        doc_path = "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md"
        replay_path = (
            "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"
        )
        self.write_contract_files({doc_path: "# drifted\n", replay_path: "# drifted\n"})

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        self.assertEqual(2, audit["missing_path_count"])
        summary = {entry["path"]: entry for entry in audit["missing_paths"]}
        self.assertIn(doc_path, summary)
        self.assertIn(replay_path, summary)
        self.assertGreater(summary[doc_path]["missing_expectation_count"], 1)
        self.assertGreater(summary[replay_path]["missing_expectation_count"], 1)
        self.assertIn(
            "replay-side surface checker visible",
            summary[doc_path]["first_missing_purpose"],
        )
        self.assertIn(
            "windows_replay_attached_html_surface_check = Format-HelperCommand",
            summary[replay_path]["first_missing_snippet"],
        )

    def test_render_text_report_lists_each_missing_path_summary(self) -> None:
        doc_path = "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md"
        replay_path = (
            "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"
        )
        self.write_contract_files({doc_path: "# drifted\n", replay_path: "# drifted\n"})

        audit = helper.build_replay_attached_quickstart_audit(self.root)
        report = helper.render_text_report(audit)

        self.assertIn("Missing paths:", report)
        self.assertIn(
            "- docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md (", report
        )
        self.assertIn(
            "- scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1 (",
            report,
        )
        self.assertIn(
            "First snippet: powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
            report,
        )
        self.assertIn(
            "First snippet: windows_replay_attached_html_surface_check = Format-HelperCommand",
            report,
        )


if __name__ == "__main__":
    unittest.main()
