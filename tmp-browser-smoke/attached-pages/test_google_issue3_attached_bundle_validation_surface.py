import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def assert_fragments_present(
    testcase: unittest.TestCase, source: str, fragments: tuple[str, ...], label: str
) -> None:
    for fragment in fragments:
        testcase.assertIn(fragment, source, f"{label} should keep {fragment}")


FIXTURE_FILES = {
    "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1": r"""
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
    }
    notes = @(
        'Start with the attached_html_target_bundle suite command when the current attached pages are already the likely three-page compatibility bundle and you want the compact suite surface first.',
        'Keep the attached_html suite command nearby when the replay may still need the broader attached-page fallback before it locks onto the pinned bundle branch.',
        'Keep the google_attached_html suite command nearby when the current inputs include a Google-like attached page and the narrower issue-specific Google attached-page chain still matters before bundle-first replay.',
        'Run bundle_surface_check before trusting the bundle-only replay after branch moves or helper renames.',
        'Run bundle_check right after bundle_surface_check when you want the current saved-page set revalidated as the same known three-page compatibility bundle before the delegated runner takes over.',
        'Pass -BrowserExe when the bundle-specific route should stay pinned to a non-default Windows headed build through the suite surface, bundle-first entrypoint, printed bundle flow, and delegated bundle runner.',
        'Pass -PreferredInitialPage when the suite surface should keep the same Google-like page first across the broader attached-page lane, the narrower issue #3 re-entry helpers, and the compact bundle-first follow-up.',
        'Use bundle_first_entrypoint when explicit input paths, repo-root context, replay-route context, or a non-default BrowserExe are already in play and you want the narrower issue #3 bridge printed before the delegated bundle flow.'
    )
}
Write-Host 'Pinned compatibility bundle:'
Write-Host 'Keep visible beside bundle replay:'
Write-Host 'Narrower issue #3 re-entry:'
""",
    "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1": r"""
$entrypoint = [ordered]@{
    broader_attached_html_suite_router_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $broaderAttachedHtmlSuiteRouterArguments -RepoRootOverride $RepoRoot
    google_attached_html_suite_router_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $googleAttachedHtmlSuiteRouterArguments -RepoRootOverride $RepoRoot
    windows_replay_attached_html_quickstart_command = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $preferredInitialPageReentryArguments
    top_level_attached_html_quickstart_command = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $topLevelAttachedHtmlQuickstartArguments
    attached_html_shortcut_command = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $preferredInitialPageReentryArguments
    attached_html_flow_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
    google_attached_html_flow_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments -RepoRootOverride $RepoRoot
    bundle_surface_check_command = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $bundleSurfaceCheckArguments
    bundle_check_command = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle.ps1' -Arguments $bundleCheckerArguments
    suite_router_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $attachedHtmlTargetBundleSuiteArguments -RepoRootOverride $RepoRoot
    bundle_flow_command = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleFlowArguments
    bundle_runner_command = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleRunnerArguments -Switches @('Wait')
    bundle_proof_surface_check_command = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $bundleSurfaceCheckArguments
    bundle_proof_entrypoint_command = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $reentryArguments
    local_html_fixture_surface_check_command = Format-HelperCommand -ScriptName 'check_local_html_fixture_validation_surface.ps1' -Arguments $localHtmlFixtureSurfaceArguments
    local_html_fixture_probe_command = Format-PowerShellFileCommand -RelativePath 'tmp-browser-smoke\\local-html-fixtures\\chrome-local-html-fixture-probe.ps1' -Arguments $localHtmlFixtureProbeArguments
    replay_shortcuts_command = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $replayShortcutsArguments
    return_to_safe_route_command = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $safeRouteArguments
    notes = @(
        'Use broader_attached_html_suite_router_command first when the next replay is still being chosen from the wider attached-page router and you want the generic attached-page branch visible before the replay narrows back into the pinned bundle-only lane.',
        'Use google_attached_html_suite_router_command next when the current replay should keep the Google-shaped attached-page route visible beside the broader attached-page branch before the bundle-only branch takes over.',
        'Start with bundle_surface_check_command so the pinned bundle reference note, bundle quickstart, written proof note, pinned manual checklist, checker, helper, runner, and delegated attached-html surfaces fail fast before localhost replay.',
        'Run bundle_check_command next when you want the current saved-page set revalidated as the same three-page compatibility bundle before you trust the printed flow helper or runner.',
        'Use suite_router_command when you want the attached-html-target-bundle suite surface reprinted beside the broader attached-page suite routers, the broader attached-page flow helper, the dedicated Google-shaped attached-page guide, the bundle checker, the proof-note surface, and the bundle flow helper before the delegated localhost runner.',
        'After the bundle runner turns green, reopen bundle_proof_surface_check_command and bundle_proof_entrypoint_command so the written proof note, the proof-only helper, and the reusable fixed-list screenshot-and-title proof stay pinned to the same bundle inputs before the route widens back out.',
        'After the bundle runner turns green, reopen local_html_fixture_surface_check_command and local_html_fixture_probe_command so the same pinned compatibility bundle can pass through the reusable screenshot-and-title proof path before the route widens back into the larger issue #3 helper chain.',
        'Pass -BrowserExe when the replay should stay pinned to a non-default Windows headed build through the broader attached-page suite routers, the top-level attached-page quickstart, the Google-shaped flow helper, the printed bundle flow helper, and the delegated bundle runner instead of drifting back to .\\zig-out\\bin\\lightpanda.exe.'
    )
}
Write-Host 'Re-enter before bundle route:'
Write-Host 'Bundle-first route:'
Write-Host 'Proof after bundle replay:'
Write-Host 'Return after bundle replay:'
""",
    "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1": r"""
$helper = [ordered]@{
    commands = [ordered]@{
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $attachedBundleSuiteArguments -RepoRootOverride $RepoRoot
        attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $preferredInitialPageSharedArguments
        attached_bundle_proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $sharedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Use attached_bundle_suite_surface when the current replay is already pinned to the known three-page compatibility bundle and you want the compact suite-level bundle surface reprinted before the route narrows into the bundle-first helper or the delegated bundle runner.',
        'Use attached_bundle_proof_entrypoint when the pinned three-page compatibility bundle is already green and you want the fixed-list screenshot-and-title proof reprinted before the route widens back into the broader attached-page or Google-shaped follow-up helpers.',
        'Use attached_bundle_change_area, then attached_bundle_suite_surface, then attached_bundle_proof_entrypoint, and only then attached_bundle_first when the current replay should stay pinned to the known three-page compatibility bundle before widening back into the broader Google-only helper chain.',
        'Pass -BrowserExe when the shorter issue #3 attached-page ladder should stay pinned to a non-default Windows headed build through the broader Google-shaped flow helper, the bundle-suite surface, the bundle-first bridge, and the delegated bundle route instead of drifting back to .\\zig-out\\bin\\lightpanda.exe.'
    )
}
Write-Host 'Top-level attached-page entrypoints:'
Write-Host 'Compact follow-up helpers:'
Write-Host 'Bundle suite note:'
Write-Host 'Bundle proof note:'
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-attached-bundle-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleIssue3AttachedBundleValidationSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.bundle_suite = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1"
        )
        cls.bundle_first = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1"
        )
        cls.top_level = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1"
        )

    def test_bundle_suite_keeps_pinned_bundle_identity_and_suite_reentry_commands(self) -> None:
        assert_fragments_present(
            self,
            self.bundle_suite,
            (
                "Control your online safety and privacy",
                "Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic",
                "Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html",
                "preferred_initial_page_hint",
                "attached_html_target_bundle = Format-HelperCommandWithRepoRootEnv",
                "attached_html = Format-HelperCommandWithRepoRootEnv",
                "google_attached_html = Format-HelperCommandWithRepoRootEnv",
                "Pinned compatibility bundle:",
            ),
            "bundle suite surface",
        )

    def test_bundle_suite_keeps_bundle_follow_up_and_bundle_first_helpers_visible(self) -> None:
        assert_fragments_present(
            self,
            self.bundle_suite,
            (
                "google_attached_html_surface_check",
                "google_issue3_attached_html_surface_check",
                "google_issue3_attached_html_entrypoint",
                "bundle_surface_check",
                "bundle_check",
                "bundle_flow",
                "bundle_runner",
                "bundle_proof_entrypoint",
                "top_level_attached_html_bridge",
                "bundle_first_entrypoint",
                "replay_route",
                "replay_shortcuts",
                "Keep visible beside bundle replay:",
                "Narrower issue #3 re-entry:",
            ),
            "bundle suite follow-up ladder",
        )

    def test_bundle_suite_notes_keep_bundle_pin_and_context_guidance(self) -> None:
        assert_fragments_present(
            self,
            self.bundle_suite,
            (
                "three-page compatibility bundle",
                "broader attached-page fallback",
                "Google-like attached page",
                "Run bundle_surface_check before trusting the bundle-only replay",
                "Run bundle_check right after bundle_surface_check",
                "Pass -BrowserExe",
                "Pass -PreferredInitialPage",
                "Use bundle_first_entrypoint",
            ),
            "bundle suite notes",
        )

    def test_bundle_first_entrypoint_keeps_reentry_bundle_proof_and_return_routes(self) -> None:
        assert_fragments_present(
            self,
            self.bundle_first,
            (
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
                "Re-enter before bundle route:",
                "Bundle-first route:",
                "Proof after bundle replay:",
                "Return after bundle replay:",
            ),
            "bundle-first entrypoint",
        )

    def test_bundle_first_notes_keep_prebundle_postbundle_and_override_guidance(self) -> None:
        assert_fragments_present(
            self,
            self.bundle_first,
            (
                "wider attached-page router",
                "Google-shaped attached-page route",
                "Start with bundle_surface_check_command",
                "Run bundle_check_command next",
                "Use suite_router_command",
                "After the bundle runner turns green, reopen bundle_proof_surface_check_command",
                "After the bundle runner turns green, reopen local_html_fixture_surface_check_command",
                "Pass -BrowserExe",
            ),
            "bundle-first notes",
        )

    def test_top_level_quickstart_keeps_bundle_surface_and_bundle_first_routes_visible(self) -> None:
        assert_fragments_present(
            self,
            self.top_level,
            (
                "attached_bundle_change_area",
                "attached_bundle_suite_surface",
                "attached_bundle_proof_entrypoint",
                "attached_bundle_first",
                "safe_route_entrypoints",
                "Top-level attached-page entrypoints:",
                "Compact follow-up helpers:",
                "Bundle suite note:",
                "Bundle proof note:",
            ),
            "top-level attached bundle quickstart",
        )

    def test_top_level_notes_keep_bundle_escalation_order_and_browser_override_guidance(self) -> None:
        assert_fragments_present(
            self,
            self.top_level,
            (
                "known three-page compatibility bundle",
                "compact suite-level bundle surface",
                "fixed-list screenshot-and-title proof",
                "Use attached_bundle_change_area, then attached_bundle_suite_surface, then attached_bundle_proof_entrypoint, and only then attached_bundle_first",
                "Pass -BrowserExe",
            ),
            "top-level bundle notes",
        )


if __name__ == "__main__":
    unittest.main()
