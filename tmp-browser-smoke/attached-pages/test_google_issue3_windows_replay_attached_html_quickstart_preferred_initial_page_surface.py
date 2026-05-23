import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1": r"""
$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $sharedArguments -Name PreferredInitialPage -Value $PreferredInitialPage
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $InputPath

$browserAwareSharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $browserAwareSharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $browserAwareSharedArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $browserAwareSharedArguments -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $browserAwareSharedArguments -Name PreferredInitialPage -Value $PreferredInitialPage
Add-SharedPathArrayArgument -Arguments $browserAwareSharedArguments -Name InputPath -Values $InputPath

$preferredInitialPageArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $preferredInitialPageArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $preferredInitialPageArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $preferredInitialPageArguments -Name PreferredInitialPage -Value $PreferredInitialPage
Add-SharedPathArrayArgument -Arguments $preferredInitialPageArguments -Name InputPath -Values $InputPath

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}
if ($PreferredInitialPage) {
    $attachedHtmlFlowArguments['PreferredInitialPage'] = $PreferredInitialPage
}
if ($BrowserExe) {
    $attachedHtmlFlowArguments['BrowserExe'] = $BrowserExe
}

$attachedHtmlChangeAreaArguments = [ordered]@{
    ChangeArea = 'attached-html'
}
if ($PreferredInitialPage) {
    $attachedHtmlChangeAreaArguments['PreferredInitialPage'] = $PreferredInitialPage
}

$googleAttachedHtmlChangeAreaArguments = [ordered]@{
    ChangeArea = 'google-attached-html'
}
if ($PreferredInitialPage) {
    $googleAttachedHtmlChangeAreaArguments['PreferredInitialPage'] = $PreferredInitialPage
}

$attachedBundleChangeAreaArguments = [ordered]@{
    ChangeArea = 'attached-html-target-bundle'
}
if ($PreferredInitialPage) {
    $attachedBundleChangeAreaArguments['PreferredInitialPage'] = $PreferredInitialPage
}

$helper = [ordered]@{
    preferred_initial_page = $PreferredInitialPage
    top_level_commands = [ordered]@{
        attached_html_change_area = $attachedHtmlChangeAreaCommand
        google_attached_html_change_area = $googleAttachedHtmlChangeAreaCommand
        attached_bundle_change_area = $attachedBundleChangeAreaCommand
    }
    commands = [ordered]@{
        attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $preferredInitialPageArguments
        google_attached_html_validation_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
    }
    notes = @(
        'Current preferred initial page: $PreferredInitialPage',
        'The top-level attached-html, Google-attached-html, and attached-html-target-bundle re-entry commands shown here now preserve -PreferredInitialPage when the replay should keep one saved page first before reopening the narrower helper ladder.',
        'The launcher-companion and dedicated Google attached-html flow commands shown here now also preserve the same preferred-first-page override, so the narrower replay ladder can keep the strongest Google-like page pinned without hand-editing each command.'
    )
}

if (-not [string]::IsNullOrWhiteSpace($PreferredInitialPage)) {
    Write-Host ((\"Preferred initial page: {0}\") -f $helper.preferred_initial_page)
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-replay-preferred-page-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleIssue3ReplayAttachedHtmlQuickstartPreferredInitialPageSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.quickstart = read_text(
            cls.repo_root
            / "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1"
        )

    def test_preferred_initial_page_flows_into_shared_argument_sets(self) -> None:
        for fragment in (
            "Add-SharedArgument -Arguments $sharedArguments -Name PreferredInitialPage -Value $PreferredInitialPage",
            "Add-SharedArgument -Arguments $browserAwareSharedArguments -Name PreferredInitialPage -Value $PreferredInitialPage",
            "Add-SharedArgument -Arguments $preferredInitialPageArguments -Name PreferredInitialPage -Value $PreferredInitialPage",
        ):
            self.assertIn(fragment, self.quickstart)

    def test_preferred_initial_page_flows_into_top_level_reentry_routes(self) -> None:
        for fragment in (
            "$attachedHtmlChangeAreaArguments['PreferredInitialPage'] = $PreferredInitialPage",
            "$googleAttachedHtmlChangeAreaArguments['PreferredInitialPage'] = $PreferredInitialPage",
            "$attachedBundleChangeAreaArguments['PreferredInitialPage'] = $PreferredInitialPage",
        ):
            self.assertIn(fragment, self.quickstart)

    def test_preferred_initial_page_flows_into_google_and_launcher_helpers(self) -> None:
        for fragment in (
            "$attachedHtmlFlowArguments['PreferredInitialPage'] = $PreferredInitialPage",
            "attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $preferredInitialPageArguments",
            "google_attached_html_validation_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot",
        ):
            self.assertIn(fragment, self.quickstart)

    def test_preferred_initial_page_guidance_and_output_stay_visible(self) -> None:
        for fragment in (
            "Current preferred initial page: $PreferredInitialPage",
            "preserve -PreferredInitialPage",
            "preferred-first-page override",
            "Preferred initial page: {0}",
        ):
            self.assertIn(fragment, self.quickstart)


if __name__ == "__main__":
    unittest.main()
