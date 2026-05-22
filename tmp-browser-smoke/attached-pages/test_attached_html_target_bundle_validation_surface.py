import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_headed_validation_suites.ps1": r"""
switch ($true) {
    { $SuiteName -eq "google-attached-html" -or $SuiteName -eq "attached-html-target-bundle" } {
        $useGoogleStyleCatalog = $SuiteName -eq "google-attached-html"
        $bundleFocused = $SuiteName -eq "attached-html-target-bundle"
        $commands = Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$useGoogleStyleCatalog
        Write-Route -Name $SuiteName -Commands $commands -Notes $notes
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes -BundleFocused:$bundleFocused)
        break
    }
    { $ChangeArea -eq "attached-html" -or $ChangeArea -eq "attached-html-target-bundle" -or $ChangeArea -eq "google-attached-html" -or $ChangeArea -eq "manual-html" } {
        $useGoogleStyleCatalog = $ChangeArea -eq "google-attached-html"
        $bundleFocused = $ChangeArea -eq "attached-html-target-bundle"
        $commands = Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath -TargetPreferredInitialPage $PreferredInitialPage -GoogleStyle:$useGoogleStyleCatalog
        Write-Route -Name "attached-pages-catalog-follow-up" -Commands $commands -Notes $notes
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes -BundleFocused:$bundleFocused)
        break
    }
}
""",
    "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1": r"""
$surface = [ordered]@{
    known_bundle_files = @(
        'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html'
        'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html'
        'Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html'
    )
    preferred_initial_page_hint = 'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html'
    suite_commands = [ordered]@{
        attached_html_target_bundle = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea 'attached-html-target-bundle'"
        attached_html = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea 'attached-html'"
        google_attached_html = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea 'google-attached-html'"
    }
    helper_commands = [ordered]@{
        google_attached_html_surface_check = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1'
        google_attached_html_asset_closure = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle'
        broader_attached_html_flow = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1'
        google_attached_html_flow = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1'
        google_attached_html_runner = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait'
        google_issue3_attached_html_surface_check = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1'
        google_issue3_attached_html_entrypoint = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_google_attached_html_entrypoint.ps1'
        bundle_surface_check = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1'
        bundle_check = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1'
        bundle_flow = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1'
        bundle_runner = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait'
        bundle_proof_entrypoint = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1'
        top_level_attached_html_bridge = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_entrypoint.ps1'
        bundle_first_entrypoint = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1'
        replay_route = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route.ps1'
        replay_shortcuts = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1'
    }
    note_paths = [ordered]@{
        bundle_reference = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
        bundle_quickstart = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md'
        bundle_proof = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md'
        bundle_checklist = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md'
        bundle_first_bridge = 'docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md'
    }
    notes = @(
        'Start with the attached_html_target_bundle suite command when the current attached pages are already the likely three-page compatibility bundle and you want the compact suite surface first.',
        'Run bundle_surface_check before trusting the bundle-only replay after branch moves or helper renames.',
        'Run bundle_check right after bundle_surface_check when you want the current saved-page set revalidated as the same known three-page compatibility bundle before the delegated runner takes over.',
        'Use bundle_first_entrypoint when explicit input paths, repo-root context, replay-route context, or a non-default BrowserExe are already in play and you want the narrower issue #3 bridge printed before the delegated bundle flow.'
    )
}
$surface.recommended_next_key = if ($surface.explicit_input_path_count -gt 0) { 'bundle_first_entrypoint' } else { 'bundle_surface_check' }
$surface.recommended_next_command = $surface.helper_commands[$surface.recommended_next_key]
""",
    "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1": r"""
$entrypoint = [ordered]@{
    broader_attached_html_suite_router_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea 'attached-html'"
    google_attached_html_suite_router_command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea 'google-attached-html'"
    windows_replay_attached_html_quickstart_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1'
    top_level_attached_html_quickstart_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1'
    attached_html_shortcut_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_shortcut_entrypoint.ps1'
    attached_html_flow_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1'
    google_attached_html_flow_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1'
    bundle_surface_check_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1'
    bundle_check_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1'
    suite_router_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle'
    bundle_flow_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1'
    bundle_runner_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait'
    bundle_proof_surface_check_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1'
    bundle_proof_entrypoint_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1'
    local_html_fixture_surface_check_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_local_html_fixture_validation_surface.ps1'
    local_html_fixture_probe_command = 'powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1'
    replay_shortcuts_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_shortcuts.ps1'
    return_to_safe_route_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1'
    notes = @(
        'Use suite_router_command when you want the attached-html-target-bundle suite surface reprinted beside the broader attached-page suite routers, the broader attached-page flow helper, the dedicated Google-shaped attached-page guide, the bundle checker, the proof-note surface, and the bundle flow helper before the delegated localhost runner.',
        'After the bundle runner turns green, reopen bundle_proof_surface_check_command and bundle_proof_entrypoint_command so the written proof note, the proof-only helper, and the reusable fixed-list screenshot-and-title proof stay pinned to the same bundle inputs before the route widens back out.',
        'Use replay_shortcuts_command after the bundle replay when you want the broader issue #3 discovery bridge, attached-bundle branch, and safe-route shortcuts printed together before choosing whether to stay broad or narrow next.'
    )
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-attached-bundle-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class AttachedHtmlTargetBundleValidationSurfaceTest(unittest.TestCase):
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
        cls.bundle_suite_surface = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1"
        )
        cls.bundle_first_entrypoint = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1"
        )

    def test_router_keeps_bundle_suite_and_follow_up_surface(self) -> None:
        self.assertIn('$SuiteName -eq "attached-html-target-bundle"', self.router)
        self.assertIn('$bundleFocused = $SuiteName -eq "attached-html-target-bundle"', self.router)
        self.assertIn('$ChangeArea -eq "attached-html-target-bundle"', self.router)
        self.assertIn('Write-Route -Name "issue3-attached-html-follow-up"', self.router)
        self.assertIn('Get-Issue3AttachedHtmlFollowUpNotes -BundleFocused:$bundleFocused', self.router)

    def test_bundle_suite_surface_keeps_known_bundle_and_three_suite_reentry_commands(self) -> None:
        for needle in (
            "Google Safety Centre",
            "Anthropic",
            "Department of War.html",
            "preferred_initial_page_hint",
            "attached_html_target_bundle",
            "attached_html =",
            "google_attached_html =",
        ):
            self.assertIn(needle, self.bundle_suite_surface)

        self.assertIn("show_headed_validation_suites.ps1 -ChangeArea 'attached-html-target-bundle'", self.bundle_suite_surface)
        self.assertIn("show_headed_validation_suites.ps1 -ChangeArea 'attached-html'", self.bundle_suite_surface)
        self.assertIn("show_headed_validation_suites.ps1 -ChangeArea 'google-attached-html'", self.bundle_suite_surface)

    def test_bundle_suite_surface_keeps_bundle_google_and_replay_helpers_visible(self) -> None:
        for helper in (
            "check_google_attached_html_validation_surface.ps1",
            "check_attached_html_local_asset_closure.ps1 -GoogleStyle",
            "show_attached_html_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "run_google_attached_html_validation.ps1 -Wait",
            "check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1",
            "show_google_issue3_google_attached_html_entrypoint.ps1",
            "check_attached_html_target_bundle_validation_surface.ps1",
            "check_attached_html_target_bundle.ps1",
            "show_attached_html_target_bundle_validation_flow.ps1",
            "run_attached_html_target_bundle_validation.ps1 -Wait",
            "show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
            "show_google_issue3_top_level_attached_html_entrypoint.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
            "show_google_issue3_replay_route.ps1",
            "show_google_issue3_replay_shortcuts.ps1",
        ):
            self.assertIn(helper, self.bundle_suite_surface)

    def test_bundle_suite_surface_keeps_recommended_next_logic_and_bundle_notes(self) -> None:
        self.assertIn("recommended_next_key", self.bundle_suite_surface)
        self.assertIn("'bundle_first_entrypoint'", self.bundle_suite_surface)
        self.assertIn("'bundle_surface_check'", self.bundle_suite_surface)
        self.assertIn("Run bundle_surface_check before trusting the bundle-only replay", self.bundle_suite_surface)
        self.assertIn("Run bundle_check right after bundle_surface_check", self.bundle_suite_surface)
        self.assertIn("Use bundle_first_entrypoint when explicit input paths", self.bundle_suite_surface)
        self.assertIn("docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md", self.bundle_suite_surface)
        self.assertIn("docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md", self.bundle_suite_surface)

    def test_bundle_first_entrypoint_keeps_bundle_reentry_proof_and_safe_route_helpers(self) -> None:
        for helper in (
            "broader_attached_html_suite_router_command",
            "google_attached_html_suite_router_command",
            "windows_replay_attached_html_quickstart_command",
            "top_level_attached_html_quickstart_command",
            "attached_html_shortcut_command",
            "attached_html_flow_command",
            "google_attached_html_flow_command",
            "bundle_surface_check_command",
            "bundle_check_command",
            "suite_router_command",
            "bundle_flow_command",
            "bundle_runner_command",
            "bundle_proof_surface_check_command",
            "bundle_proof_entrypoint_command",
            "local_html_fixture_surface_check_command",
            "local_html_fixture_probe_command",
            "replay_shortcuts_command",
            "return_to_safe_route_command",
        ):
            self.assertIn(helper, self.bundle_first_entrypoint)

    def test_bundle_first_entrypoint_notes_keep_post_bundle_proof_and_return_guidance(self) -> None:
        self.assertIn("attached-html-target-bundle suite surface reprinted", self.bundle_first_entrypoint)
        self.assertIn("After the bundle runner turns green", self.bundle_first_entrypoint)
        self.assertIn("reusable fixed-list screenshot-and-title proof", self.bundle_first_entrypoint)
        self.assertIn("Use replay_shortcuts_command after the bundle replay", self.bundle_first_entrypoint)


if __name__ == "__main__":
    unittest.main()
