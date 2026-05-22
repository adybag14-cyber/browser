from __future__ import annotations

import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_google_issue3_suite_router_next_steps.ps1": r"""
$helper = [ordered]@{
    suite_router_commands = [ordered]@{
        suite_name_google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        change_area_google_input = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        change_area_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        change_area_google_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        change_area_attached_bundle = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        suite_router_surface_check = $suiteRouterSurfaceCheckCommand
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand
        google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand
        google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $RepoRoot
    }
}

Write-Host 'Read-first suite-router commands:'
Write-Host '  Suite name:'
Write-Host '  Change area:'
Write-Host '  Attached HTML:'
Write-Host '  Google attached HTML:'
Write-Host '  Bundle change area:'
Write-Host '  Suite-router surface:'
Write-Host '  Attached flow helper:'
Write-Host '  Google attached surface:'
Write-Host '  Issue-specific surface:'
Write-Host '  Google attached flow:'
Write-Host '  Google flow helper:'
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-suite-router-read-first-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleIssue3SuiteRouterReadFirstSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.next_steps = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_suite_router_next_steps.ps1"
        )

    def test_read_first_command_map_keeps_top_level_suite_and_change_area_routes(self) -> None:
        for fragment in (
            "suite_name_google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1'",
            "SuiteName = 'google-recommended'",
            "change_area_google_input = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1'",
            "ChangeArea = 'google-input'",
            "change_area_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1'",
            "ChangeArea = 'attached-html'",
            "change_area_google_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1'",
            "ChangeArea = 'google-attached-html'",
            "change_area_attached_bundle = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1'",
            "ChangeArea = 'attached-html-target-bundle'",
        ):
            self.assertIn(fragment, self.next_steps)

    def test_read_first_command_map_keeps_broader_attached_and_google_helpers(self) -> None:
        for fragment in (
            "suite_router_surface_check = $suiteRouterSurfaceCheckCommand",
            "attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1'",
            "google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand",
            "google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand",
            "google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1'",
            "google_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1'",
        ):
            self.assertIn(fragment, self.next_steps)

    def test_read_first_output_keeps_operator_facing_labels_visible(self) -> None:
        for fragment in (
            "Read-first suite-router commands:",
            "Suite name:",
            "Change area:",
            "Attached HTML:",
            "Google attached HTML:",
            "Bundle change area:",
            "Suite-router surface:",
            "Attached flow helper:",
            "Google attached surface:",
            "Issue-specific surface:",
            "Google attached flow:",
            "Google flow helper:",
        ):
            self.assertIn(fragment, self.next_steps)


if __name__ == "__main__":
    unittest.main()
