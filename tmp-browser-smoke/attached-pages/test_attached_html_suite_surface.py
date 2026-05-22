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


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
function Get-AttachedHtmlCatalogCommand {
    param(
        [string]$TargetInputPath,
        [string]$TargetPreferredInitialPage,
        [switch]$GoogleStyle,
        [string[]]$ExtraSwitches = @()
    )

    $arguments = [System.Collections.Generic.List[string]]::new()
    if ($GoogleStyle) {
        $arguments.Add('-GoogleStyle')
    }
    foreach ($switchName in $ExtraSwitches) {
        $arguments.Add("-$switchName")
    }
    return Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $arguments
}

function Get-AttachedHtmlRouteCommands {
    param(
        [string]$TargetInputPath,
        [string]$TargetPreferredInitialPage,
        [switch]$GoogleStyle
    )

    return @(
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -TargetPreferredInitialPage $TargetPreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('AuditSidecars')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -TargetPreferredInitialPage $TargetPreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('AuditAssets')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -TargetPreferredInitialPage $TargetPreferredInitialPage -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteSidecars', 'RequireCompleteAssets')),
        "& `"$BrowserExe`" browse --headed --window_width 1366 --window_height 900 `"http://127.0.0.1:8235/`""
    )
}

function Get-AttachedHtmlNotes {
    $notes = @(
        "Run the attached-pages sidecar audit first so missing sibling _files directories are visible before the browser is blamed.",
        "Run the attached-pages asset audit second so missing local assets stay visible before the browser is blamed.",
        "Use the attached-pages catalog wrapper to pin the current HTML bundle and expose short localhost routes at /, /manifest.json, /pages/<n>, /named/<slug>, and /raw/... .",
        "The manual-html change area still reuses this attached-pages catalog route when you want a direct saved-page replay without a narrower bounded family."
    )
    return $notes
}

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
            "Use the attached-html change-area quickstart when you want the shorter issue #3 attached-page helper ladder visible after the broader attached-pages catalog route.",
            "Use the top-level attached-page quickstart when the next replay should stay inside that shorter issue #3 attached-page ladder before you drop into the bundle-only or shortcut-first helpers.",
            "Keep the broader attached-page flow visible when the replay may still widen back out beyond the shorter issue #3 attached-page ladder.",
            "Keep the dedicated Google-shaped attached-page flow visible when the replay still looks Google-like before you narrow into the bundle-only or shortcut-first helpers.",
            "Use the compact bundle-suite surface before the bundle-first helper when the replay should stay pinned to the known three-page compatibility set or when -InputPath already fixes the bundle inputs."
        )
    }
    return $notes
}

switch ($true) {
    { $SuiteName -eq "google-attached-html" -or $SuiteName -eq "attached-html-target-bundle" } {
        $useGoogleStyleCatalog = $SuiteName -eq "google-attached-html"
        $bundleFocused = $SuiteName -eq "attached-html-target-bundle"
        $commands = Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$useGoogleStyleCatalog
        $notes = Get-AttachedHtmlNotes
        if ($useGoogleStyleCatalog) {
            $notes += "Google-style auto-discovery keeps the strongest Google-like saved page first when -InputPath is omitted."
        }
        Write-Route -Name $SuiteName -Commands $commands -Notes $notes
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes -BundleFocused:$bundleFocused)
        break
    }
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-attached-html-suite-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class AttachedHtmlSuiteSurfaceTest(unittest.TestCase):
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

    def test_suite_router_keeps_google_and_bundle_named_entrypoints(self) -> None:
        self.assertIn('$SuiteName -eq "google-attached-html"', self.router)
        self.assertIn('$SuiteName -eq "attached-html-target-bundle"', self.router)
        self.assertIn('$useGoogleStyleCatalog = $SuiteName -eq "google-attached-html"', self.router)
        self.assertIn('$bundleFocused = $SuiteName -eq "attached-html-target-bundle"', self.router)

    def test_attached_html_route_commands_keep_google_style_catalog_and_headed_launch(self) -> None:
        commands_block = extract_function_block(self.router, "Get-AttachedHtmlRouteCommands")
        self.assertIn("-GoogleStyle:$GoogleStyle", commands_block)
        self.assertIn("AuditSidecars", commands_block)
        self.assertIn("AuditAssets", commands_block)
        self.assertIn("RequireCompleteSidecars', 'RequireCompleteAssets", commands_block)
        self.assertIn('browse --headed --window_width 1366 --window_height 900', commands_block)
        self.assertIn('http://127.0.0.1:8235/', commands_block)

    def test_google_attached_html_suite_keeps_auto_discovery_note(self) -> None:
        self.assertIn("Google-style auto-discovery keeps the strongest Google-like saved page first", self.router)
        self.assertIn('Write-Route -Name $SuiteName -Commands $commands -Notes $notes', self.router)

    def test_bundle_focused_follow_up_notes_keep_bundle_and_broader_flow_guidance(self) -> None:
        notes_block = extract_function_block(self.router, "Get-Issue3AttachedHtmlFollowUpNotes")
        self.assertIn("Use the compact bundle-suite surface first", notes_block)
        self.assertIn("Keep the broader attached-page flow", notes_block)
        self.assertIn("Only drop into the bundle-first helper", notes_block)
        self.assertIn("Keep the dedicated Google-shaped attached-page flow visible", notes_block)
        self.assertIn("Use the attached-html change-area quickstart", notes_block)

    def test_suite_follow_up_route_keeps_issue3_replay_ladder(self) -> None:
        commands_block = extract_function_block(self.router, "Get-Issue3AttachedHtmlFollowUpCommands")
        self.assertIn("check_google_issue3_validation_router_attached_html_quickstart_surface.ps1", commands_block)
        self.assertIn("show_google_issue3_attached_html_change_area_quickstart.ps1", commands_block)
        self.assertIn("show_google_issue3_top_level_attached_html_quickstart.ps1", commands_block)
        self.assertIn("show_attached_html_validation_flow.ps1", commands_block)
        self.assertIn("show_google_attached_html_validation_flow.ps1", commands_block)
        self.assertIn("show_google_issue3_attached_html_target_bundle_suite_surface.ps1", commands_block)
        self.assertIn("show_google_issue3_attached_bundle_first_entrypoint.ps1", commands_block)

    def test_attached_html_notes_keep_catalog_and_manual_html_guidance(self) -> None:
        notes_block = extract_function_block(self.router, "Get-AttachedHtmlNotes")
        self.assertIn("sidecar audit first", notes_block)
        self.assertIn("asset audit second", notes_block)
        self.assertIn("short localhost routes", notes_block)
        self.assertIn("manual-html change area still reuses this attached-pages catalog route", notes_block)


if __name__ == "__main__":
    unittest.main()
