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
        start_point = 'show_headed_validation_suites.ps1 -ChangeArea attached-html'
        default_next_helper = 'show_google_issue3_suite_router_attached_html_quickstart.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        use_when = 'The next replay is already narrowed to attached-page compatibility follow-up, and you want the shorter suite-router attached-page quickstart visible immediately before deciding whether to widen into the broader attached-page flow helper, the top-level attached-page quickstart, the top-level attached-page bridge, replay shortcuts, the next-step matrix, the pinned bundle-first path, or the safe-route helper chain.'
    }
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
)
$helper = [ordered]@{
    recommended_helper_key = $recommendedHelperKey
    recommended_helper_reason = $recommendedHelperReason
    recommended_helper_command = switch ($recommendedHelperKey) {
        'attached_bundle_first' { Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments }
        'contextual_flow' { Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments }
        'replay_shortcuts' { Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments }
        'replay_route' { Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments }
        'suite_router_shortcut_entrypoint' { Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments }
        default { Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleArguments }
    }
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
    helper_commands = [ordered]@{
        suite_router_surface_check = $suiteRouterSurfaceCheckCommand
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand
        google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_handoff = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $bundleArguments
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
    top_level_attached_html_companion_notes_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md'
    google_attached_html_entrypoint_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'
    notes = @(
        'Use suite_router_surface_check before trusting the printed matrix when you want the helper surface to fail fast on missing route notes, checker scripts, or attached-page companion helpers.',
        'Use attached_html_flow when the top-level attached HTML route is already visible but you want the broader attached-page helper surface printed before narrowing into the shorter attached quickstart, the top-level attached-page bridge, replay shortcuts, or the pinned bundle-first branch.',
        'Use suite_router_shortcut_entrypoint as the default next helper after the higher-level suite router when you want the shorter issue #3 bridge to decide between replay_shortcuts, contextual_flow, or attached_bundle_first without reopening the wider compact helpers first.',
        'Use contextual_flow as the default next helper whenever RepoRoot or SummaryPath is already in play and no pinned bundle inputs take precedence, so the next surface keeps that context aligned while you choose between the recommended runner, replay shortcuts, live trace, attached bundle, or later-stage follow-up commands.',
        'Use attached_bundle_first when the saved or attached pages are still the known three-page compatibility set and you want that route exercised before reopening the broader Google-only safe-route ladder.',
        'Use google_attached_html_surface_check when the replay is already inside the broader Google-shaped attached-page route and you want the wider fail-fast surface reprinted before the narrower issue-specific checker or dedicated flow helper.',
        'Use google_issue3_attached_html_surface_check when the replay is already inside the issue-specific Google-shaped attached-page route and you want the narrower fail-fast checker reprinted before the dedicated flow helper or the Google attached-html entrypoint.'
    )
}
Write-Host ((\"Recommended helper: {0}\") -f $helper.recommended_helper_command)
Write-Host ((\"Why:                {0}\") -f $helper.recommended_helper_reason)
Write-Host ((\"  Suite-router surface:       {0}\") -f $helper.suite_router_commands.suite_router_surface_check)
Write-Host ((\"  Attached flow helper:       {0}\") -f $helper.suite_router_commands.attached_html_flow)
Write-Host ((\"  Google attached surface:    {0}\") -f $helper.suite_router_commands.google_attached_html_surface_check)
Write-Host ((\"  Issue-specific surface:     {0}\") -f $helper.suite_router_commands.google_issue3_attached_html_surface_check)
Write-Host ((\"  Surface check:            {0}\") -f $helper.helper_commands.suite_router_surface_check)
Write-Host ((\"  Google surface check:     {0}\") -f $helper.helper_commands.google_attached_html_surface_check)
Write-Host ((\"  Issue-specific check:     {0}\") -f $helper.helper_commands.google_issue3_attached_html_surface_check)
Write-Host ((\"Top-level attached companions:{0}\") -f (\" $($helper.top_level_attached_html_companion_notes_path)\"))
""",
    "scripts/windows/check_google_issue3_suite_router_next_steps_validation_surface.ps1": r"""
$references = @(
    @{ Path = "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" },
    @{ Path = "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" },
    @{ Path = "docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md" },
    @{ Path = "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" },
    @{ Path = "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" },
    @{ Path = "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" },
    @{ Path = "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" },
    @{ Path = "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" },
    @{ Path = "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" },
    @{ Path = "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md" },
    @{ Path = "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" },
    @{ Path = "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" },
    @{ Path = "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" },
    @{ Path = "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" },
    @{ Path = "scripts/windows/check_google_attached_html_validation_surface.ps1" },
    @{ Path = "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" },
    @{ Path = "scripts/windows/show_google_attached_html_validation_flow.ps1" },
    @{ Path = "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" },
    @{ Path = "scripts/windows/show_google_issue3_replay_route.ps1" },
    @{ Path = "scripts/windows/show_google_issue3_contextual_flow.ps1" },
    @{ Path = "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" }
)
$contentExpectations = @(
    @{ Path = "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md"; Snippet = "show_google_issue3_suite_router_next_steps.ps1" },
    @{ Path = "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md"; Snippet = "check_google_issue3_suite_router_next_steps_validation_surface.ps1" },
    @{ Path = "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md"; Snippet = "show_google_issue3_suite_router_next_steps.ps1" },
    @{ Path = "scripts/windows/show_google_issue3_suite_router_next_steps.ps1"; Snippet = "default_next_helper = 'show_google_issue3_suite_router_attached_html_quickstart.ps1'" },
    @{ Path = "scripts/windows/show_google_issue3_suite_router_next_steps.ps1"; Snippet = "default_next_helper = 'show_google_issue3_google_attached_html_entrypoint.ps1'" },
    @{ Path = "scripts/windows/show_google_issue3_suite_router_next_steps.ps1"; Snippet = "google_attached_html_entrypoint_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'" },
    @{ Path = "scripts/windows/show_google_issue3_suite_router_next_steps.ps1"; Snippet = "top_level_attached_html_companion_notes_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md'" }
)
""",
    "scripts/windows/show_google_issue3_replay_route.ps1": r"""
$route = [ordered]@{
    suite_router_next_steps_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    notes = @(
        'Use suite_router_next_steps_command when you want the compact next-step matrix from the higher-level suite router reprinted beside the current replay-route surface without reopening the longer Windows runbook or bridge note first.'
    )
}
Write-Host ((\"  Next-step matrix:      {0}\") -f $route.suite_router_next_steps_command)
""",
    "scripts/windows/show_google_issue3_contextual_flow.ps1": r"""
$flow = [ordered]@{
    commands = [ordered]@{
        suite_router_next_steps = Format-HelperCommand -ScriptName "show_google_issue3_suite_router_next_steps.ps1" -Arguments $shortcutArgs
    }
    notes = @(
        "Use suite_router_next_steps when the route is already known to stay inside issue #3 and you want the fastest current helper recommendation without reopening the broader handoff surface first."
    )
}
Write-Host "[suite-router-next-steps] Pick the fastest current helper from the routed issue #3 state"
Write-Host ("  {0}" -f $flow.commands.suite_router_next_steps)
""",
    "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md": r"""
- `docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md`
- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_router_next_steps_validation_surface.ps1`
- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1`
""",
    "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md": r"""
- `docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md`
- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_suite_router_next_steps_validation_surface.ps1`
- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_suite_router_next_steps.ps1`
""",
}


PLACEHOLDER_FILES = (
    "docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md",
    "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md",
    "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
    "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md",
    "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md",
    "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md",
    "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md",
    "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md",
    "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
    "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md",
    "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
    "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1",
    "scripts/windows/check_google_attached_html_validation_surface.ps1",
    "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1",
    "scripts/windows/show_google_attached_html_validation_flow.ps1",
    "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
    "scripts/windows/show_headed_validation_suites.ps1",
)


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-suite-router-next-steps-"))
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


class GoogleIssue3SuiteRouterNextStepsSurfaceTest(unittest.TestCase):
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
        cls.surface_check = read_text(
            cls.repo_root / "scripts/windows/check_google_issue3_suite_router_next_steps_validation_surface.ps1"
        )
        cls.replay_route = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_replay_route.ps1"
        )
        cls.contextual_flow = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_contextual_flow.ps1"
        )
        cls.quickstart = read_text(cls.repo_root / "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md")
        cls.discovery = read_text(cls.repo_root / "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md")

    def test_recommended_helper_logic_keeps_shortcut_contextual_and_bundle_paths(self) -> None:
        for fragment in (
            "$recommendedHelperKey = 'suite_router_shortcut_entrypoint'",
            "$recommendedHelperKey = 'attached_bundle_first'",
            "$recommendedHelperKey = 'contextual_flow'",
            "No pinned bundle inputs, saved summary, or non-default repo root are in play yet",
            "Explicit input paths are already pinned",
            "A saved SummaryPath is already available",
            "A non-default RepoRoot is already in play",
        ):
            self.assertIn(fragment, self.next_steps)

    def test_matrix_keeps_attached_google_attached_and_bundle_entrypoints(self) -> None:
        for fragment in (
            "start_point = 'show_headed_validation_suites.ps1 -ChangeArea attached-html'",
            "default_next_helper = 'show_google_issue3_suite_router_attached_html_quickstart.ps1'",
            "command = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments",
            "start_point = 'show_headed_validation_suites.ps1 -ChangeArea google-attached-html'",
            "default_next_helper = 'show_google_issue3_google_attached_html_entrypoint.ps1'",
            "command = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments",
            "start_point = 'show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle'",
            "default_next_helper = 'show_google_issue3_attached_bundle_first_entrypoint.ps1'",
        ):
            self.assertIn(fragment, self.next_steps)

    def test_helper_maps_keep_surface_checks_attached_flow_and_later_stage_flows(self) -> None:
        for fragment in (
            "suite_router_surface_check = $suiteRouterSurfaceCheckCommand",
            "attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1'",
            "google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand",
            "google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand",
            "shared_enter_order = Format-HelperCommand -ScriptName 'show_google_shared_enter_order_validation_flow.ps1'",
            "live_trace = Format-HelperCommand -ScriptName 'show_google_trace_validation_flow.ps1'",
            "recommended_helper_command = switch ($recommendedHelperKey)",
        ):
            self.assertIn(fragment, self.next_steps)

    def test_output_keeps_read_first_and_key_helper_surface_checks_visible(self) -> None:
        for fragment in (
            "Suite-router surface:",
            "Attached flow helper:",
            "Google attached surface:",
            "Issue-specific surface:",
            "Surface check:",
            "Google surface check:",
            "Issue-specific check:",
        ):
            self.assertIn(fragment, self.next_steps)

    def test_companion_notes_and_attached_flow_guidance_stay_visible_on_next_steps_surface(self) -> None:
        for fragment in (
            "top_level_attached_html_companion_notes_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md'",
            "google_attached_html_entrypoint_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'",
            "Top-level attached companions:",
            "Use attached_html_flow when the top-level attached HTML route is already visible",
        ):
            self.assertIn(fragment, self.next_steps)

    def test_surface_checker_keeps_helper_and_note_contracts(self) -> None:
        for fragment in (
            "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
            "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md",
            "docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md",
            "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md",
            "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
            "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
            "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1",
            "scripts/windows/show_google_issue3_replay_route.ps1",
            "scripts/windows/show_google_issue3_contextual_flow.ps1",
            "scripts/windows/show_google_issue3_suite_router_next_steps.ps1",
            "default_next_helper = 'show_google_issue3_suite_router_attached_html_quickstart.ps1'",
            "default_next_helper = 'show_google_issue3_google_attached_html_entrypoint.ps1'",
        ):
            self.assertIn(fragment, self.surface_check)

    def test_quickstart_and_discovery_notes_keep_matrix_and_checker_visible(self) -> None:
        for source in (self.quickstart, self.discovery):
            self.assertIn("show_google_issue3_suite_router_next_steps.ps1", source)
            self.assertIn("check_google_issue3_suite_router_next_steps_validation_surface.ps1", source)
            self.assertIn("docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md", source)

    def test_replay_route_reprints_the_next_step_matrix(self) -> None:
        for fragment in (
            "suite_router_next_steps_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_suite_router_next_steps.ps1'",
            "Use suite_router_next_steps_command when you want the compact next-step matrix",
            "Next-step matrix:",
        ):
            self.assertIn(fragment, self.replay_route)

    def test_contextual_flow_keeps_suite_router_next_steps_bridge(self) -> None:
        for fragment in (
            'suite_router_next_steps = Format-HelperCommand -ScriptName "show_google_issue3_suite_router_next_steps.ps1"',
            "Use suite_router_next_steps when the route is already known to stay inside issue #3",
            "[suite-router-next-steps] Pick the fastest current helper from the routed issue #3 state",
        ):
            self.assertIn(fragment, self.contextual_flow)


if __name__ == "__main__":
    unittest.main()
