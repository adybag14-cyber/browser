import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_google_issue3_suite_router_next_steps.ps1": r"""
$recommendedHelperKey = 'suite_router_shortcut_entrypoint'
$recommendedHelperReason = 'No pinned bundle inputs, saved summary, or non-default repo root are in play yet, so reopen the shortcut-first entrypoint first and keep the shorter issue #3 bridge visible before widening into replay shortcuts, the next-step matrix, replay route, or the safe-route helper.'
if ($InputPath -and @($InputPath).Count -gt 0) {
    $recommendedHelperKey = 'attached_bundle_first'
    $recommendedHelperReason = 'Explicit input paths are already pinned, so the fastest correct next step is the attached bundle-first helper before reopening the broader Google-only wrappers.'
} elseif (-not [string]::IsNullOrWhiteSpace($SummaryPath)) {
    $recommendedHelperKey = 'contextual_flow'
    $recommendedHelperReason = 'A saved SummaryPath is already available, so open the context-preserving helper next and keep the current replay state aligned while you choose between replay shortcuts, replay route, safe-route wrappers, or the later trace and attached-page branches.'
} elseif (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
    $recommendedHelperKey = 'contextual_flow'
    $recommendedHelperReason = 'A non-default RepoRoot is already in play, so open the context-preserving helper next and keep that checkout aligned while you choose between replay shortcuts, replay route, safe-route wrappers, or the later trace and attached-page branches.'
}

$matrix = @(
    [ordered]@{
        start_point = 'show_headed_validation_suites.ps1 -ChangeArea google-attached-html'
        default_next_helper = 'show_google_issue3_google_attached_html_entrypoint.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        use_when = 'The replay is already narrowed to the issue-specific Google-shaped attached-page route and you want the dedicated surface checks, Google attached-html flow helper, and Google attached-html entrypoint visible before deciding between the shortcut-first bridge, replay shortcuts, the next-step matrix, the pinned bundle-first path, or the safe-route helper chain.'
    }
    [ordered]@{
        start_point = 'show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle'
        default_next_helper = 'show_google_issue3_attached_bundle_first_entrypoint.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        use_when = 'The current saved or attached inputs are still the pinned three-page compatibility bundle and you want the one-command bundle-first helper to keep that locked route plus the safe-route return visible before the broader Google-only wrappers.'
    }
    [ordered]@{
        start_point = 'saved summary or current pinned context already in play'
        default_next_helper = 'show_google_issue3_contextual_flow.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        use_when = 'RepoRoot, SummaryPath, or fixed InputPath values already matter and you want the next helper surface to keep that context aligned before choosing between the recommended runner, replay shortcuts, live trace, attached bundle, or later-stage follow-up commands.'
    }
)

$helper = [ordered]@{
    recommended_helper_key = $recommendedHelperKey
    recommended_helper_reason = $recommendedHelperReason
    suite_router_commands = [ordered]@{
        suite_router_surface_check = $suiteRouterSurfaceCheckCommand
        change_area_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        change_area_google_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        change_area_attached_bundle = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand
        google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand
        google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        suite_router_surface_check = $suiteRouterSurfaceCheckCommand
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand
        google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $safeRouteArguments
        runner_patch_next_step = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_patch_next_step.ps1' -Arguments ([ordered]@{
            SummaryPath = $SummaryPath
            State = $runnerPatchStatePlaceholder
        }) -RepoRootOverride $RepoRoot
    }
    later_stage_flow_commands = [ordered]@{
        submit_timing = Format-HelperCommand -ScriptName 'show_google_submit_timing_validation_flow.ps1' -Arguments $submitTimingFlowArguments
        shared_enter_order = Format-HelperCommand -ScriptName 'show_google_shared_enter_order_validation_flow.ps1' -Arguments $sharedEnterOrderFlowArguments
        live_trace = Format-HelperCommand -ScriptName 'show_google_trace_validation_flow.ps1' -Arguments $liveTraceFlowArguments
    }
    google_attached_html_entrypoint_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'
    top_level_attached_html_companion_notes_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md'
    notes = @(
        'When RepoRoot is supplied, the top-level suite-router, attached-html flow, and Google attached-html flow commands preserve that same LIGHTPANDA_REPO_ROOT context instead of falling back to the default checkout path.',
        'When SummaryPath is supplied, the replay-route, replay-shortcuts, contextual-flow, safe-route entrypoints, fresh safe-route replay, reuse-current-outputs, and runner next-step helpers keep that same saved summary context attached.',
        'When InputPath is supplied, the suite-router handoff, replay-route, replay-shortcuts, contextual-flow, attached-bundle-first, safe-route entrypoints, attached-html flow, and Google attached-html flow helpers keep the current fixed bundle inputs pinned instead of relying on auto-discovery.',
        'Use change_area_google_attached_html when the next replay is already narrowed to the issue-specific Google-shaped attached-page route and you want that top-level branch printed beside the broader attached-page checker, the narrower issue-specific checker, the dedicated flow helper, and the Google attached-html entrypoint before deciding between the shortcut-first bridge, replay shortcuts, the next-step matrix, the pinned bundle-first branch, or the safe-route helper chain.',
        'Use google_attached_html_flow when the current attached-page set already includes a Google-like page and you want the dedicated Google-shaped attached-page helper surface printed before narrowing into the Google attached-html entrypoint, the shortcut-first bridge, replay shortcuts, or the pinned bundle-first branch.',
        'Keep discovery_handoff_note_path open for the shortest prose bridge from the top-level suite catalog into the newer suite-router handoff and replay-route helpers, quickstart_note_path for the shortest replay note, suite_router_attached_html_quickstart_note_path for the shorter suite-router attached-page bridge, top_level_attached_html_quickstart_note_path, top_level_attached_html_bridge_note_path, top_level_attached_html_catalog_quickstart_note_path, and top_level_attached_html_companion_notes_path for the compact, broader, catalog-flavored, and companion top-level attached-page notes.'
    )
}

Write-Host (("  Suite-router surface:       {0}") -f $helper.suite_router_commands.suite_router_surface_check)
Write-Host (("  Google attached surface:    {0}") -f $helper.suite_router_commands.google_attached_html_surface_check)
Write-Host (("  Issue-specific surface:     {0}") -f $helper.suite_router_commands.google_issue3_attached_html_surface_check)
Write-Host (("  Surface check:            {0}") -f $helper.helper_commands.suite_router_surface_check)
Write-Host (("  Google surface check:     {0}") -f $helper.helper_commands.google_attached_html_surface_check)
Write-Host (("  Issue-specific check:     {0}") -f $helper.helper_commands.google_issue3_attached_html_surface_check)
Write-Host (("Top-level attached companions:{0}") -f (" $($helper.top_level_attached_html_companion_notes_path)"))
""",
    "scripts/windows/check_google_issue3_suite_router_next_steps_validation_surface.ps1": r"""
$references = @(
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md" -Kind "file" -Purpose "Focused suite-router next-steps note that should stay aligned with the live helper and the broader replay notes."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint note that the next-step matrix keeps visible for the narrower attached-page route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md" -Kind "file" -Purpose "Top-level attached-html companion note map that should stay surfaced beside the catalog-side attached-page route from the suite-router matrix."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint helper that remains a narrower next-step option from the matrix."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Suite-router next-steps helper whose dependent surface this checker validates.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1' -Purpose "The suite-router next-steps note keeps the Google attached-page branch pointed at the issue-specific entrypoint helper instead of drifting back to a broader flow helper."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet "start_point = 'show_headed_validation_suites.ps1 -ChangeArea google-attached-html'" -Purpose "Suite-router matrix keeps the google-attached-html branch anchored to the dedicated top-level route before the narrower helper is chosen."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet "default_next_helper = 'show_google_issue3_google_attached_html_entrypoint.ps1'" -Purpose "Suite-router matrix keeps the google-attached-html branch routed to the issue-specific entrypoint helper rather than drifting back to a broader attached-page flow."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet "google_attached_html_entrypoint_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'" -Purpose "Suite-router helper output keeps the Google attached-html companion note surfaced beside the narrower issue-specific branch."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet "top_level_attached_html_companion_notes_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md'" -Purpose "Suite-router helper output keeps the top-level attached companion-note map surfaced beside the catalog-side attached-page route.")
)
""",
}


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-suite-router-next-steps-"))
    for relative_path, content in FIXTURE_FILES.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content.lstrip("\n"), encoding="utf-8")
    return root


class GoogleIssue3SuiteRouterNextStepsValidationSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.helper = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_suite_router_next_steps.ps1"
        )
        cls.surface_check = read_text(
            cls.repo_root / "scripts/windows/check_google_issue3_suite_router_next_steps_validation_surface.ps1"
        )

    def test_matrix_keeps_google_attached_html_bundle_and_contextual_routes(self) -> None:
        for snippet in (
            "start_point = 'show_headed_validation_suites.ps1 -ChangeArea google-attached-html'",
            "default_next_helper = 'show_google_issue3_google_attached_html_entrypoint.ps1'",
            "command = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments",
            "start_point = 'show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle'",
            "default_next_helper = 'show_google_issue3_attached_bundle_first_entrypoint.ps1'",
            "start_point = 'saved summary or current pinned context already in play'",
            "default_next_helper = 'show_google_issue3_contextual_flow.ps1'",
        ):
            self.assertIn(snippet, self.helper)

    def test_recommended_helper_priority_keeps_inputpath_then_summary_then_reporoot(self) -> None:
        for snippet in (
            "$recommendedHelperKey = 'suite_router_shortcut_entrypoint'",
            "$recommendedHelperKey = 'attached_bundle_first'",
            "$recommendedHelperKey = 'contextual_flow'",
            "Explicit input paths are already pinned",
            "A saved SummaryPath is already available",
            "A non-default RepoRoot is already in play",
        ):
            self.assertIn(snippet, self.helper)

    def test_suite_router_commands_keep_read_first_surface_and_attached_routes(self) -> None:
        for snippet in (
            "suite_router_surface_check = $suiteRouterSurfaceCheckCommand",
            "ChangeArea = 'attached-html'",
            "ChangeArea = 'google-attached-html'",
            "ChangeArea = 'attached-html-target-bundle'",
            "attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1'",
            "google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand",
            "google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand",
            "google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1'",
            "google_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1'",
        ):
            self.assertIn(snippet, self.helper)

    def test_helper_commands_keep_issue3_bridge_bundle_and_safe_route_links(self) -> None:
        for snippet in (
            "suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1'",
            "suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1'",
            "google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1'",
            "replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1'",
            "replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1'",
            "contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1'",
            "attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1'",
            "safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1'",
            "runner_patch_next_step = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_patch_next_step.ps1'",
        ):
            self.assertIn(snippet, self.helper)

    def test_later_stage_flows_and_notes_keep_context_preserving_guidance(self) -> None:
        for snippet in (
            "submit_timing = Format-HelperCommand -ScriptName 'show_google_submit_timing_validation_flow.ps1'",
            "shared_enter_order = Format-HelperCommand -ScriptName 'show_google_shared_enter_order_validation_flow.ps1'",
            "live_trace = Format-HelperCommand -ScriptName 'show_google_trace_validation_flow.ps1'",
            "When RepoRoot is supplied",
            "When SummaryPath is supplied",
            "When InputPath is supplied",
            "Use change_area_google_attached_html",
            "Use google_attached_html_flow",
        ):
            self.assertIn(snippet, self.helper)

    def test_printed_output_keeps_surface_checks_and_companion_note_map(self) -> None:
        for snippet in (
            'Write-Host (("  Suite-router surface:       {0}") -f $helper.suite_router_commands.suite_router_surface_check)',
            'Write-Host (("  Google attached surface:    {0}") -f $helper.suite_router_commands.google_attached_html_surface_check)',
            'Write-Host (("  Issue-specific surface:     {0}") -f $helper.suite_router_commands.google_issue3_attached_html_surface_check)',
            'Write-Host (("  Surface check:            {0}") -f $helper.helper_commands.suite_router_surface_check)',
            'Write-Host (("  Google surface check:     {0}") -f $helper.helper_commands.google_attached_html_surface_check)',
            'Write-Host (("  Issue-specific check:     {0}") -f $helper.helper_commands.google_issue3_attached_html_surface_check)',
            'Write-Host (("Top-level attached companions:{0}") -f (" $($helper.top_level_attached_html_companion_notes_path)"))',
        ):
            self.assertIn(snippet, self.helper)

    def test_surface_checker_keeps_next_steps_google_entrypoint_and_companion_note_contracts(self) -> None:
        for snippet in (
            'docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md',
            'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md',
            'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md',
            'scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1',
            'scripts/windows/show_google_issue3_suite_router_next_steps.ps1',
            "start_point = 'show_headed_validation_suites.ps1 -ChangeArea google-attached-html'",
            "default_next_helper = 'show_google_issue3_google_attached_html_entrypoint.ps1'",
            "google_attached_html_entrypoint_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'",
            "top_level_attached_html_companion_notes_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md'",
        ):
            self.assertIn(snippet, self.surface_check)


if __name__ == "__main__":
    unittest.main()
