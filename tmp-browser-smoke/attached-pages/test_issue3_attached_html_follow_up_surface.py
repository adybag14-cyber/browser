import os
import pathlib
import re
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def extract_function_block(source: str, function_name: str) -> str:
    pattern = re.compile(
        rf"function\s+{re.escape(function_name)}[^\{{]*\{{.*?^\}}",
        re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(source)
    if not match:
        raise AssertionError(f"Could not find function block for {function_name}")
    return match.group(0)


HELPER_SCRIPTS = (
    "scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
    "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1",
    "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1",
    "scripts/windows/show_attached_html_validation_flow.ps1",
    "scripts/windows/show_google_attached_html_validation_flow.ps1",
    "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1",
    "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1",
)


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
function Get-Issue3AttachedHtmlFollowUpCommands {
    return @(
        (Format-HelperCommand -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -Arguments $issue3AttachedHtmlSurfaceCheckArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $issue3AttachedHtmlArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
        (Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments),
        (Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $issue3AttachedHtmlBrowserArguments)
    )
}

function Get-Issue3AttachedHtmlFollowUpNotes {
    param(
        [switch]$BundleFocused
    )

    if ($BundleFocused) {
        $notes = @(
            "Use the compact bundle-suite surface first when the top-level router is already narrowed to the known three-page compatibility bundle.",
            "Keep the broader attached-page flow, the dedicated Google-shaped attached-page flow, and the top-level attached-page quickstart visible until the current pages are clearly still the pinned bundle.",
            "Only drop into the bundle-first helper after the suite surface, broader attached-page flows, and the top-level quickstart are visible, so the pinned bundle route stays easy to reopen."
        )
    } else {
        $notes = @(
            "Use the attached-html change-area quickstart when you want the shorter issue #3 attached-page helper ladder visible after the broader attached-pages catalog route."
        )
    }

    $notes += "Run the validation-router attached-html surface checker first so missing quickstart notes or downstream helper paths fail fast before you trust the shorter issue #3 attached-page ladder."

    if ($SummaryPath) {
        $notes += "Current saved summary: $SummaryPath"
        $notes += "The printed issue #3 follow-up commands now preserve -SummaryPath through the router handoff, so saved validation state can be reopened without manual re-entry."
    }

    if ($PreferredInitialPage) {
        $notes += "Current preferred initial page: $PreferredInitialPage"
        $notes += "The printed issue #3 follow-up commands now preserve -PreferredInitialPage through the broader attached-page flow and the narrower issue #3 quickstarts, so the same first page stays pinned without manual re-entry."
    }

    if ($isCustomBrowserExe) {
        $notes += "Current browser override: $BrowserExe"
        $notes += "The printed issue #3 follow-up commands now preserve -BrowserExe through the router handoff where the downstream helper accepts it. Keep rerunning this router before hopping between helper surfaces so the same custom binary stays pinned."
    }

    return $notes
}

Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes)

switch ($true) {
    { $SuiteName -eq "attached-html-target-bundle" } {
        $bundleFocused = $true
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes -BundleFocused:$bundleFocused)
        break
    }
    { $ChangeArea -eq "attached-html-target-bundle" -or $ChangeArea -eq "attached-html" } {
        $bundleFocused = $ChangeArea -eq "attached-html-target-bundle"
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes -BundleFocused:$bundleFocused)
        break
    }
}
""",
}

for relative_path in HELPER_SCRIPTS:
    FIXTURE_FILES[relative_path] = "# placeholder helper\n"


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-follow-up-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
    return root


class Issue3AttachedHtmlFollowUpSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.router = read_text(cls.repo_root / "scripts/windows/show_headed_validation_suites.ps1")

    def test_follow_up_command_helper_keeps_expected_scripts_in_order(self) -> None:
        commands_block = extract_function_block(self.router, "Get-Issue3AttachedHtmlFollowUpCommands")
        positions = []
        for relative_path in HELPER_SCRIPTS:
            name = pathlib.Path(relative_path).name
            self.assertIn(name, commands_block)
            positions.append(commands_block.index(name))
        self.assertEqual(positions, sorted(positions), "follow-up helper order should stay stable")

    def test_router_surfaces_follow_up_in_default_bundle_suite_and_change_area_views(self) -> None:
        self.assertRegex(
            self.router,
            r'Write-Route\s+-Name\s+"issue3-attached-html-follow-up"\s+-Commands\s+\(Get-Issue3AttachedHtmlFollowUpCommands\)\s+-Notes\s+\(Get-Issue3AttachedHtmlFollowUpNotes\)',
        )
        self.assertIn('Get-Issue3AttachedHtmlFollowUpNotes -BundleFocused:$bundleFocused', self.router)
        self.assertIn('$SuiteName -eq "attached-html-target-bundle"', self.router)
        self.assertIn('$ChangeArea -eq "attached-html-target-bundle"', self.router)

    def test_bundle_focused_notes_keep_compact_bundle_guidance(self) -> None:
        notes_block = extract_function_block(self.router, "Get-Issue3AttachedHtmlFollowUpNotes")
        self.assertIn("compact bundle-suite surface first", notes_block)
        self.assertIn("pinned bundle route stays easy to reopen", notes_block)
        self.assertIn("validation-router attached-html surface checker first", notes_block)

    def test_notes_keep_summary_page_and_browser_override_guidance(self) -> None:
        notes_block = extract_function_block(self.router, "Get-Issue3AttachedHtmlFollowUpNotes")
        self.assertIn("Current saved summary: $SummaryPath", notes_block)
        self.assertIn("preserve -SummaryPath through the router handoff", notes_block)
        self.assertIn("Current preferred initial page: $PreferredInitialPage", notes_block)
        self.assertIn("preserve -PreferredInitialPage through the broader attached-page flow", notes_block)
        self.assertIn("Current browser override: $BrowserExe", notes_block)
        self.assertIn("preserve -BrowserExe through the router handoff", notes_block)

    def test_expected_helper_scripts_exist(self) -> None:
        for relative_path in HELPER_SCRIPTS:
            self.assertTrue(
                (self.repo_root / relative_path).exists(),
                f"expected follow-up helper should exist: {relative_path}",
            )


if __name__ == "__main__":
    unittest.main()
