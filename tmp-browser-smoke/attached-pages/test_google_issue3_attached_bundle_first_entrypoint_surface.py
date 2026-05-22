import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
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
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    attached_html_shortcut_note_path = 'docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    attached_html_target_bundle_reference_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
    attached_html_target_bundle_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md'
    attached_html_target_bundle_proof_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md'
    attached_html_target_bundle_checklist_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    notes = @(
        'Use this helper when the current saved or attached pages are still the known three-page compatibility bundle and you want the narrower replay-side attached-html quickstart, the top-level attached-page quickstart, the issue-specific attached-page shortcut, the broader attached-page flow helper, the narrower Google-shaped attached-page flow guide, the written proof note, the proof-entrypoint surface checker, and the reusable fixed-list proof path kept visible just long enough to confirm the replay should stay pinned to that bundle.',
        'Use broader_attached_html_suite_router_command first when the next replay is still being chosen from the wider attached-page router and you want the generic attached-page branch visible before the replay narrows back into the pinned bundle-only lane.',
        'Use google_attached_html_suite_router_command next when the current replay should keep the Google-shaped attached-page route visible beside the broader attached-page branch before the bundle-only branch takes over.',
        'Use windows_replay_attached_html_quickstart_command first when the replay reopened from the broader Windows replay route and you want the newer attached-html ladder visible before you commit to the bundle-only branch.',
        'Use top_level_attached_html_quickstart_command next when you want the compact top-level attached-page bridge kept visible before the replay drops from the replay-side attached-html ladder into the pinned bundle route.',
        'Use attached_html_shortcut_command next when the route is already clearly inside the shorter attached-page helper chain and you want explicit bundle inputs preserved before the replay narrows into the bundle-only branch.',
        'Start with bundle_surface_check_command so the pinned bundle reference note, bundle quickstart, written proof note, pinned manual checklist, checker, helper, runner, and delegated attached-html surfaces fail fast before localhost replay.',
        'Run bundle_check_command next when you want the current saved-page set revalidated as the same three-page compatibility bundle before you trust the printed flow helper or runner.',
        'After the bundle runner turns green, reopen bundle_proof_surface_check_command and bundle_proof_entrypoint_command so the written proof note, the proof-only helper, and the reusable fixed-list screenshot-and-title proof stay pinned to the same bundle inputs before the route widens back out.',
        'After the bundle runner turns green, reopen local_html_fixture_surface_check_command and local_html_fixture_probe_command so the same pinned compatibility bundle can pass through the reusable screenshot-and-title proof path before the route widens back into the larger issue #3 helper chain.',
        'Pass -PreferredInitialPage when one bundle page should stay first through the broader attached-page flow helper, the dedicated Google-shaped attached-page guide, and the delegated bundle runner instead of falling back to automatic first-page selection.',
        'Pass -BrowserExe when the replay should stay pinned to a non-default Windows headed build through the broader attached-page suite routers, the top-level attached-page quickstart, the Google-shaped flow helper, the printed bundle flow helper, and the delegated bundle runner instead of drifting back to .\\zig-out\\bin\\lightpanda.exe.',
        'Pass -InputPath when you want to keep an explicit bundle path or fixed file list pinned through the bundle check, the broader attached-page flow helper, the Google-shaped attached-page flow guide, the proof-entrypoint helper, the printed bundle flow helper, the delegated bundle runner, the local fixture proof command, replay-shortcuts helper, and safe-route return command instead of relying on auto-discovery.',
        'Pass -RepoRoot and -SummaryPath when the replay is running from a non-default checkout and you want the replay-side attached-html quickstart, the top-level quickstart, the attached-page shortcut, the broader attached-page suite routers, the proof-entrypoint helper, the replay-shortcuts helper, and the safe-route return commands to preserve that same context.',
        'Use replay_shortcuts_command after the bundle replay when you want the broader issue #3 discovery bridge, attached-bundle branch, and safe-route shortcuts printed together before choosing whether to stay broad or narrow next.',
        'Return to the broader issue #3 safe-route helper only after the bundle replay or the reusable fixed-list proof path makes the next Google-style input or submit failure state clear.'
    )
}
""",
}


PLACEHOLDER_FILES = (
    "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
    "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
    "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md",
    "docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md",
    "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md",
    "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md",
    "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md",
    "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md",
    "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md",
    "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md",
    "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
    "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1",
    "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1",
    "scripts/windows/show_attached_html_validation_flow.ps1",
    "scripts/windows/show_google_attached_html_validation_flow.ps1",
    "scripts/windows/check_attached_html_target_bundle_validation_surface.ps1",
    "scripts/windows/check_attached_html_target_bundle.ps1",
    "scripts/windows/show_headed_validation_suites.ps1",
    "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1",
    "scripts/windows/run_attached_html_target_bundle_validation.ps1",
    "scripts/windows/check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1",
    "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
    "scripts/windows/check_local_html_fixture_validation_surface.ps1",
    "tmp-browser-smoke/local-html-fixtures/chrome-local-html-fixture-probe.ps1",
    "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
    "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1",
)


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-issue3-bundle-first-surface-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")

    for relative_path in PLACEHOLDER_FILES:
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists():
            target.write_text("# placeholder\n", encoding="utf-8")
    return root


class GoogleIssue3AttachedBundleFirstEntrypointSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.entrypoint = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1"
        )

    def test_entrypoint_keeps_reentry_commands_before_bundle_only_route(self) -> None:
        for fragment in (
            "broader_attached_html_suite_router_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1'",
            "google_attached_html_suite_router_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1'",
            "show_google_issue3_windows_replay_attached_html_quickstart.ps1",
            "show_google_issue3_top_level_attached_html_quickstart.ps1",
            "show_google_issue3_attached_html_shortcut_entrypoint.ps1",
            "show_attached_html_validation_flow.ps1",
            "show_google_attached_html_validation_flow.ps1",
        ):
            self.assertIn(fragment, self.entrypoint)

    def test_entrypoint_keeps_bundle_only_route_and_proof_follow_up_commands(self) -> None:
        for fragment in (
            "check_attached_html_target_bundle_validation_surface.ps1",
            "check_attached_html_target_bundle.ps1",
            "show_attached_html_target_bundle_validation_flow.ps1",
            "run_attached_html_target_bundle_validation.ps1",
            "check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1",
            "show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
            "check_local_html_fixture_validation_surface.ps1",
            "tmp-browser-smoke\\\\local-html-fixtures\\\\chrome-local-html-fixture-probe.ps1",
            "show_google_issue3_replay_shortcuts.ps1",
            "show_google_issue3_safe_route_entrypoints.ps1",
        ):
            self.assertIn(fragment, self.entrypoint)

    def test_entrypoint_keeps_bundle_and_validation_note_paths_visible(self) -> None:
        for fragment in (
            "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
            "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
            "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md",
            "docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md",
            "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md",
            "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md",
            "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md",
        ):
            self.assertIn(fragment, self.entrypoint)

    def test_entrypoint_keeps_context_preservation_guidance(self) -> None:
        for fragment in (
            "Pass -PreferredInitialPage",
            "Pass -BrowserExe",
            "Pass -InputPath",
            "Pass -RepoRoot and -SummaryPath",
            "current saved or attached pages are still the known three-page compatibility bundle",
            "broader attached-page suite routers",
            "written proof note",
            "reusable fixed-list proof path",
            "Return to the broader issue #3 safe-route helper only after the bundle replay or the reusable fixed-list proof path makes the next Google-style input or submit failure state clear.",
        ):
            self.assertIn(fragment, self.entrypoint)

    def test_entrypoint_referenced_docs_and_helpers_exist(self) -> None:
        for relative_path in PLACEHOLDER_FILES:
            self.assertTrue((self.repo_root / relative_path).exists(), f"{relative_path} should exist")


if __name__ == "__main__":
    unittest.main()
