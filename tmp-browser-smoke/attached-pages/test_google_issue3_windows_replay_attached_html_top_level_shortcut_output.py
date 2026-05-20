import unittest
from pathlib import Path


EXPECTED_TOP_LEVEL_SHORTCUT_OUTPUT = (
    'Write-Host (("  Top-level shortcut:       {0}") -f '
    "$helper.commands.top_level_shortcut_first)"
)


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


class GoogleIssue3WindowsReplayAttachedHtmlTopLevelShortcutOutputTests(
    unittest.TestCase
):
    def test_quickstart_surfaces_top_level_shortcut_output(self) -> None:
        script = (
            repo_root()
            / "scripts"
            / "windows"
            / "show_google_issue3_windows_replay_attached_html_quickstart.ps1"
        )

        content = script.read_text(encoding="utf-8")

        self.assertIn(EXPECTED_TOP_LEVEL_SHORTCUT_OUTPUT, content)


if __name__ == "__main__":
    unittest.main()
