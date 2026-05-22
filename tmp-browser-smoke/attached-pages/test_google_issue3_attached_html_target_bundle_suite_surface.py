import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1": r"""
$attachedHtmlTargetBundleSuiteArguments = [ordered]@{
    ChangeArea = 'attached-html-target-bundle'
}
$attachedHtmlSuiteArguments = [ordered]@{
    ChangeArea = 'attached-html'
}
$googleAttachedHtmlSuiteArguments = [ordered]@{
    ChangeArea = 'google-attached-html'
}
$surface = [ordered]@{
    known_bundle_files = @(
        'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html'
        'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html'
        'Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html'
    )
    preferred_initial_page_hint = 'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html'
    suite_commands = [ordered]@{
        attached_html_target_bundle = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $attachedHtmlTargetBundleSuiteArguments -RepoRootOverride $RepoRoot
        attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $attachedHtmlSuiteArguments -RepoRootOverride $RepoRoot
        google_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $googleAttachedHtmlSuiteArguments -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot
        google_attached_html_asset_closure = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_attached_html_local_asset_closure.ps1' -Arguments $attachedHtmlFlowArguments -Switches @('GoogleStyle') -RepoRootOverride $RepoRoot
        broader_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_runner = Format-HelperCommandWithRepoRootEnv -ScriptName 'run_google_attached_html_validation.ps1' -Arguments $googleAttachedHtmlFlowArguments -Switches @('Wait') -RepoRootOverride $RepoRoot
        google_issue3_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1' -RepoRootOverride $RepoRoot
        google_issue3_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $reentryArguments
        bundle_surface_check = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $bundleSurfaceCheckArguments
        bundle_check = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle.ps1' -Arguments $bundleCheckerArguments
        bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleRouteArguments
        bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleRouteArguments -Switches @('Wait')
        bundle_proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $reentryArguments
        top_level_attached_html_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $reentryArguments
        bundle_first_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleFirstArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $reentryArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $reentryArguments
    }
    note_paths = [ordered]@{
        bundle_reference = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
        bundle_quickstart = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md'
        bundle_proof = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md'
        bundle_checklist = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md'
        top_level_attached_html_bridge = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
        bundle_first_bridge = 'docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md'
        google_attached_html_flow = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
        google_issue3_attached_html_entrypoint = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'
        windows_replay_attached_html_quickstart = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
        validation_chain = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    }
    notes = @(
        'Use this helper when you want the attached-html-target-bundle suite surface printed with the broader attached-page lane, the full Google-shaped attached-page follow-up route, the narrower issue-specific Google attached-page checker and entrypoint, the bundle checker, and the proof-entry follow-up still visible beside it.',
        'When the replay should stay pinned to the known three-page compatibility bundle, use the exact saved filenames printed on this surface and prefer the Google Safety Centre export as -PreferredInitialPage when one Google-like page should stay first.',
        'Run google_attached_html_surface_check, google_attached_html_asset_closure, broader_attached_html_flow, google_attached_html_flow, and google_attached_html_runner before the bundle-only route when the next decision still depends on seeing the broader attached-page lane and the full Google-shaped attached-page chain beside the pinned bundle lane.',
        'Run google_issue3_attached_html_surface_check and google_issue3_attached_html_entrypoint after the broader Google-shaped attached-page surface looks right when the replay should stay on the narrower issue-specific Google lane before narrowing into the bundle-only route.',
        'Pass -BrowserExe when the bundle-specific route should stay pinned to a non-default Windows headed build through the suite surface, bundle-first entrypoint, printed bundle flow, and delegated bundle runner.',
        'Pass -PreferredInitialPage when the suite surface should keep the same Google-like page first across the broader attached-page lane, the narrower issue #3 re-entry helpers, and the compact bundle-first follow-up.',
        'Use bundle_proof_entrypoint after the bundle runner when the delegated bundle replay is green and the next decision depends on keeping the fixed-list screenshot-and-title proof pinned to the same saved inputs.',
        'Return to replay_route or replay_shortcuts only after the pinned bundle route makes the next attached-page failure state clear.'
    )
}
$surface.recommended_next_key = if ($surface.explicit_input_path_count -gt 0) {
    'bundle_first_entrypoint'
} else {
    'bundle_surface_check'
}
$surface.recommended_next_command = $surface.helper_commands[$surface.recommended_next_key]
$surface.recommended_next_reason = if ($surface.recommended_next_key -eq 'bundle_first_entrypoint') {
    'Explicit attached-page paths are already pinned, so keep that same bundle context on the narrower issue #3 bridge before you delegate into the bundle flow and runner.'
} else {
    'No explicit bundle paths are pinned yet, so fail fast on the bundle surface first while the broader attached-page lane, the full Google-shaped attached-page route, the bundle checker, and the proof-entry follow-up stay visible beside the suite surface.'
}
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-bundle-suite-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleIssue3AttachedBundleSuiteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.surface = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1"
        )

    def test_surface_keeps_the_known_three_page_bundle_and_preferred_page_hint(self) -> None:
        for html_file in (
            "Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html",
            "Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html",
            "Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html",
        ):
            self.assertIn(html_file, self.surface)
        self.assertIn("preferred_initial_page_hint", self.surface)

    def test_surface_keeps_broader_suite_reentry_commands_visible(self) -> None:
        for fragment in (
            "attached_html_target_bundle = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1'",
            "attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1'",
            "google_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1'",
            "ChangeArea = 'attached-html-target-bundle'",
            "ChangeArea = 'attached-html'",
            "ChangeArea = 'google-attached-html'",
        ):
            self.assertIn(fragment, self.surface)

    def test_surface_keeps_bundle_google_and_replay_helper_commands(self) -> None:
        for fragment in (
            "check_google_attached_html_validation_surface.ps1",
            "check_attached_html_local_asset_closure.ps1",
            "show_attached_html_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
            "run_google_attached_html_validation.ps1",
            "check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1",
            "show_google_issue3_google_attached_html_entrypoint.ps1",
            "check_attached_html_target_bundle_validation_surface.ps1",
            "check_attached_html_target_bundle.ps1",
            "show_attached_html_target_bundle_validation_flow.ps1",
            "run_attached_html_target_bundle_validation.ps1",
            "show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
            "show_google_issue3_top_level_attached_html_entrypoint.ps1",
            "show_google_issue3_attached_bundle_first_entrypoint.ps1",
            "show_google_issue3_replay_route.ps1",
            "show_google_issue3_replay_shortcuts.ps1",
        ):
            self.assertIn(fragment, self.surface)

    def test_surface_keeps_bundle_note_paths_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md",
            "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md",
            "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md",
            "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md",
            "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
            "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
            "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md",
        ):
            self.assertIn(fragment, self.surface)

    def test_surface_keeps_context_and_escalation_guidance(self) -> None:
        for fragment in (
            "broader attached-page lane",
            "full Google-shaped attached-page follow-up route",
            "narrower issue-specific Google attached-page checker and entrypoint",
            "Pass -BrowserExe",
            "Pass -PreferredInitialPage",
            "Use bundle_proof_entrypoint after the bundle runner",
            "Return to replay_route or replay_shortcuts only after the pinned bundle route makes the next attached-page failure state clear.",
        ):
            self.assertIn(fragment, self.surface)

    def test_surface_keeps_recommended_next_logic_for_pinned_and_unpinned_inputs(self) -> None:
        self.assertIn("recommended_next_key = if ($surface.explicit_input_path_count -gt 0)", self.surface)
        self.assertIn("'bundle_first_entrypoint'", self.surface)
        self.assertIn("'bundle_surface_check'", self.surface)
        self.assertIn("Explicit attached-page paths are already pinned", self.surface)
        self.assertIn("No explicit bundle paths are pinned yet", self.surface)


if __name__ == "__main__":
    unittest.main()
