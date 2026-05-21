import tempfile
import unittest
from collections import defaultdict
from pathlib import Path

import google_issue3_attached_pages_launcher_companion_audit as helper


HELPER_NOTE_PATH = (
    "windows_replay_attached_html_quickstart_note = "
    "'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'"
)
HELPER_NOTE_OUTPUT = (
    'Write-Host (("Windows replay note:     {0}") -f '
    "$helper.companion_paths.windows_replay_attached_html_quickstart_note)"
)
CHECKER_NOTE_PATH = (
    "(New-ValidationContentExpectation -Path "
    "'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' "
    "-Snippet \\\"windows_replay_attached_html_quickstart_note = "
    "'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'\\\""
)
CHECKER_NOTE_OUTPUT = (
    "(New-ValidationContentExpectation -Path "
    "'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' "
    "-Snippet 'Write-Host ((\\\\\\\"Windows replay note:     {0}\\\\\\\") -f "
    "$helper.companion_paths.windows_replay_attached_html_quickstart_note)'"
)


def build_contract_map() -> dict[str, str]:
    grouped: dict[str, list[str]] = defaultdict(list)
    for expectation in helper.EXPECTATIONS:
        grouped[expectation["path"]].append(expectation["snippet"])
    return {path: "\n\n".join(snippets) + "\n" for path, snippets in grouped.items()}


class GoogleIssue3LauncherCompanionWindowsReplayNoteAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_contract_files(self) -> dict[str, str]:
        contract_map = build_contract_map()
        for relative_path, content in contract_map.items():
            full_path = self.root / relative_path
            full_path.parent.mkdir(parents=True, exist_ok=True)
            full_path.write_text(content, encoding="utf-8")
        return contract_map

    def assert_path_fails_after_removal(self, path: str, snippet: str) -> None:
        self.write_contract_files()
        target = self.root / path
        original = target.read_text(encoding="utf-8")
        updated = original.replace(snippet + "\n\n", "", 1)
        if updated == original:
            updated = original.replace(snippet, "", 1)
        target.write_text(
            updated,
            encoding="utf-8",
        )

        audit = helper.build_launcher_companion_audit(self.root)
        self.assertGreater(audit["missing_count"], 0)
        failing_paths = [result["path"] for result in audit["results"] if not result["exists"]]
        self.assertIn(path, failing_paths)

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()
        audit = helper.build_launcher_companion_audit(self.root)
        self.assertEqual(0, audit["missing_count"])

    def test_build_audit_reports_missing_helper_windows_replay_note_path(self) -> None:
        self.assert_path_fails_after_removal(
            "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
            HELPER_NOTE_PATH,
        )

    def test_build_audit_reports_missing_helper_windows_replay_note_output(self) -> None:
        self.assert_path_fails_after_removal(
            "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
            HELPER_NOTE_OUTPUT,
        )

    def test_build_audit_reports_missing_checker_windows_replay_note_path_guard(self) -> None:
        self.assert_path_fails_after_removal(
            "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
            CHECKER_NOTE_PATH,
        )

    def test_build_audit_reports_missing_checker_windows_replay_note_output_guard(self) -> None:
        self.assert_path_fails_after_removal(
            "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
            CHECKER_NOTE_OUTPUT,
        )


if __name__ == "__main__":
    unittest.main()