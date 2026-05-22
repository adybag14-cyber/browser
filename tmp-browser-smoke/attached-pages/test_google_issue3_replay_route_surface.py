import os
import pathlib
import tempfile
import unittest


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


FIXTURE_FILES = {
    "scripts/windows/show_google_issue3_replay_route.ps1": r"""
[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
    [switch]$Json
)

$resolvedRepoRoot = if ($RepoRoot) { $RepoRoot } else { "C:\repo" }
$recommendedRepoRoot = $resolvedRepoRoot
$recommendedSummaryPath = if ($PSBoundParameters.ContainsKey('SummaryPath')) { $SummaryPath } else { $null }
$recommendedInputPath = if ($PSBoundParameters.ContainsKey('InputPath')) { $InputPath } else { @() }
$runnerPatchStatePlaceholder = '<ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>'

$route = [ordered]@{
    issue = 'Google issue #3 replay route'
    purpose = 'Bridge the higher-level headed validation catalog, the newer attached-page route, the replay-route shortcut helper, the bounded Google flow helper, the attached three-page compatibility bundle branch, and the current safe-route replay helpers while preserving repo-root, summary-path, and pinned bundle-input context across the printed commands.'
    repo_root = $resolvedRepoRoot
    summary_path = $recommendedSummaryPath
    input_paths = $recommendedInputPath
    explicit_input_path_count = if ($recommendedInputPath) { @($recommendedInputPath).Count } else { 0 }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    replay_discovery_note_path = 'docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md'
    replay_route_shortcut_bridge_note_path = 'docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md'
    replay_route_bundle_first_bridge_note_path = 'docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md'
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    read_first_suite_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
        SuiteName = 'google-recommended'
    }) -RepoRootOverride $recommendedRepoRoot
    read_first_change_area_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
        ChangeArea = 'google-input'
    }) -RepoRootOverride $recommendedRepoRoot
    attached_html_change_area_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
        ChangeArea = 'attached-html'
    }) -RepoRootOverride $recommendedRepoRoot
    suite_router_shortcut_entrypoint_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    replay_route_shortcut_entrypoint_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    read_first_google_flow_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $recommendedRepoRoot
    suite_catalog_entrypoints_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    suite_router_handoff_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    suite_router_next_steps_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    attached_bundle_change_area_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
        ChangeArea = 'attached-html-target-bundle'
    }) -RepoRootOverride $recommendedRepoRoot
    attached_bundle_entrypoint_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    replay_shortcuts_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    safe_route_entrypoints_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    fresh_replay_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    reuse_current_outputs_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    runner_patch_next_step_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_patch_next_step.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        State = $runnerPatchStatePlaceholder
    }) -RepoRootOverride $recommendedRepoRoot
    notes = @(
        'Use suite_router_shortcut_entrypoint_command when the higher-level suite router has already narrowed the route to issue #3 and you want the shortest printed bridge back into the replay-route surface before deciding whether to narrow again into replay_route_shortcut_entrypoint_command, replay_shortcuts_command, the next-step matrix, or the attached bundle branch while preserving SummaryPath and InputPath context.'
        'Use replay_route_shortcut_entrypoint_command when you are already inside the replay-route helper and want the smaller attached-HTML, replay-shortcuts, next-step-matrix, contextual-flow, bundle-first, and safe-route companion surface without reopening the broader top-level route first.'
        'Use suite_router_next_steps_command when you want the compact next-step matrix from the higher-level suite router reprinted beside the current replay-route surface without reopening the longer Windows runbook or bridge note first.'
        'If the current saved or attached pages are the known three-page compatibility bundle, use attached_bundle_change_area_command and attached_bundle_entrypoint_command before reopening the broader wrapper-heavy safe route.'
        'Open safe_route_entrypoints_command when you are ready to choose between the fresh replay, reuse-current-outputs, refresh-status, handoff, summary-guide, and runner-wiring helpers.'
        'Keep replay_route_shortcut_bridge_note_path open when show_google_issue3_replay_route.ps1 is already active and you want the shortest documented handoff into the replay-route shortcut helper before choosing between the attached-page, replay-shortcuts, next-step, bundle-first, or safe-route follow-up surfaces.'
        'Keep replay_route_bundle_first_bridge_note_path open when the route has already narrowed to the attached three-page compatibility bundle and you want the compact written bridge that keeps the bundle-first helper, the broader attached-page route, and the replay shortcuts visible together before returning to the wrapper-heavy safe-route surfaces.'
        'When LIGHTPANDA_REPO_ROOT, a saved SummaryPath, or pinned InputPath values are already guiding the replay, the emitted suite-catalog, attached-page, shortcut-entrypoint, replay-route-shortcut, read-first, suite-router-handoff, suite-router-next-steps, replay-shortcuts, attached-bundle, safe-route, and runner-next-step commands preserve that same context so the replay-route shortcut can stay the default recommendation without losing the newer helper alignment.'
    )
}

$route.recommended_next_command = if ($route.explicit_input_path_count -gt 0) {
    $route.attached_bundle_entrypoint_command
} else {
    $route.replay_route_shortcut_entrypoint_command
}
$route.recommended_next_reason = if ($route.explicit_input_path_count -gt 0) {
    'Pinned input paths are already present, so stay on the attached three-page compatibility bundle branch first before widening back into the broader safe-route wrappers.'
} else {
    'No bundle inputs are pinned yet, so jump from the replay-route helper into the smaller replay-route shortcut surface and let that companion bridge decide whether replay shortcuts, the next-step matrix, the attached-page route, or the attached bundle branch should be reopened from the same context.'
}

Write-Host 'Google issue #3 replay route'
Write-Host ((\"Recommended next:    {0}\") -f $route.recommended_next_command)
Write-Host ((\"Why:                 {0}\") -f $route.recommended_next_reason)
Write-Host 'Read-first:'
Write-Host ((\"  Replay shortcut:       {0}\") -f $route.replay_route_shortcut_entrypoint_command)
Write-Host ((\"  Next-step matrix:      {0}\") -f $route.suite_router_next_steps_command)
Write-Host 'Attached-bundle branch:'
Write-Host ((\"  Bundle helper:       {0}\") -f $route.attached_bundle_entrypoint_command)
Write-Host 'Safe-route bridge:'
Write-Host ((\"  Runner next step:    {0}\") -f $route.runner_patch_next_step_command)
Write-Host 'Notes:'
Write-Host ((\"  Replay shortcut note: {0}\") -f $route.replay_route_shortcut_bridge_note_path)
Write-Host ((\"  Bundle-first note:    {0}\") -f $route.replay_route_bundle_first_bridge_note_path)
Write-Host ((\"  Validation chain:     {0}\") -f $route.validation_chain_note_path)
""",
    "scripts/windows/check_google_issue3_replay_route_validation_surface.ps1": r"""
$references = @(
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE.md" -Kind "file" -Purpose "Primary replay-route note that should stay aligned with the compact helper output."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Replay-route shortcut bridge note that should remain visible from the replay-route surface."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md" -Kind "file" -Purpose "Replay-route bundle-first bridge note that stays aligned when the route pins to the three-page compatibility bundle."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Kind "file" -Purpose "Replay-discovery handoff note reopened when the replay-route surface widens back out."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Replay quickstart note kept nearby from the replay-route surface."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned bundle reference note that should stay visible when replay-route narrows into the three-page compatibility branch."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain note that remains the later fallback after the replay-route surface narrows enough."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows runbook reopened when the replay-route surface needs the broader headed route again."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose attached-page and bundle change-area commands feed the replay-route surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Bounded Google flow helper surfaced from the replay-route surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Suite-catalog bridge helper that the replay-route surface can reopen."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Kind "file" -Purpose "Suite-router handoff helper that can reopen the broader issue #3 branch before replay-route narrows again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Next-step matrix helper surfaced from the replay-route surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Replay-route helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Replay-route shortcut helper surfaced as the default narrower follow-up from replay-route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper surfaced once replay-route has already re-established issue #3."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper surfaced when replay-route should stay pinned to the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map surfaced after replay-route narrows enough."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1" -Kind "file" -Purpose "Fresh safe-route replay helper surfaced from replay-route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1" -Kind "file" -Purpose "Existing-output safe-route wrapper surfaced from replay-route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_runner_patch_next_step.ps1" -Kind "file" -Purpose "Runner-patch follow-up helper surfaced from replay-route when wrapper state needs the next exact command."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-page localhost flow helper that replay-route reopens beside the narrower shortcut path."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-shaped attached-page flow helper kept visible from the replay-route surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Shortcut-first suite-router bridge that replay-route can reopen before narrowing again.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Snippet "replay_route_shortcut_entrypoint_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments ([ordered]@{" -Purpose "Replay-route helper wires the replay-route shortcut helper into its command surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Snippet "attached_bundle_entrypoint_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments ([ordered]@{" -Purpose "Replay-route helper keeps the bundle-first helper wired into the pinned three-page compatibility branch."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Snippet "safe_route_entrypoints_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments ([ordered]@{" -Purpose "Replay-route helper keeps the wrapper-heavy safe-route map wired into its later-stage bridge."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Snippet "Write-Host ((\"  Replay shortcut:       {0}\") -f $route.replay_route_shortcut_entrypoint_command)" -Purpose "Replay-route console output keeps the replay-route shortcut command visible in the read-first bridge."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Snippet "Write-Host ((\"  Bundle helper:       {0}\") -f $route.attached_bundle_entrypoint_command)" -Purpose "Replay-route console output keeps the bundle-first helper visible in the attached-bundle branch."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Snippet "'Use replay_route_shortcut_entrypoint_command when you are already inside the replay-route helper and want the smaller attached-HTML, replay-shortcuts, next-step-matrix, contextual-flow, bundle-first, and safe-route companion surface without reopening the broader top-level route first.'" -Purpose "Replay-route guidance still documents when the shortcut helper should be used from this broader surface."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_ROUTE.md" -Snippet "show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Purpose "Replay-route note still names the replay-route shortcut helper as the next narrower bridge."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_ROUTE.md" -Snippet "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md" -Purpose "Replay-route note still keeps the bundle-first bridge visible when the route stays pinned to the three-page compatibility set.")
)
""",
    "docs/ISSUE3_REPLAY_ROUTE.md": r"""
- `powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_replay_route_shortcut_entrypoint.ps1`
- `docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md`
""",
}


PLACEHOLDER_FILES = (
    "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
    "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md",
    "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md",
    "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
    "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md",
    "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md",
    "docs/WINDOWS_FULL_USE.md",
    "scripts/windows/HeadedValidationHelpers.ps1",
    "scripts/windows/show_headed_validation_suites.ps1",
    "scripts/windows/show_google_input_validation_flow.ps1",
    "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1",
    "scripts/windows/show_google_issue3_suite_router_handoff.ps1",
    "scripts/windows/show_google_issue3_suite_router_next_steps.ps1",
    "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
    "scripts/windows/show_google_issue3_replay_shortcuts.ps1",
    "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1",
    "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1",
    "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1",
    "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1",
    "scripts/windows/show_google_issue3_runner_patch_next_step.ps1",
    "scripts/windows/show_attached_html_validation_flow.ps1",
    "scripts/windows/show_google_attached_html_validation_flow.ps1",
    "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
)


def build_fixture_repo() -> pathlib.Path:
    root = pathlib.Path(tempfile.mkdtemp(prefix="lightpanda-replay-route-surface-"))
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


class GoogleIssue3ReplayRouteSurfaceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        env_root = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
        if env_root:
            cls.repo_root = pathlib.Path(env_root).resolve()
        elif os.environ.get("LIGHTPANDA_FIXTURE_REPO") == "1":
            cls.repo_root = build_fixture_repo()
        else:
            cls.repo_root = pathlib.Path(__file__).resolve().parents[2]

        cls.replay_route = read_text(
            cls.repo_root / "scripts/windows/show_google_issue3_replay_route.ps1"
        )
        cls.surface_check = read_text(
            cls.repo_root / "scripts/windows/check_google_issue3_replay_route_validation_surface.ps1"
        )
        cls.replay_note = read_text(cls.repo_root / "docs/ISSUE3_REPLAY_ROUTE.md")

    def test_replay_route_keeps_shortcut_bundle_and_safe_route_commands(self) -> None:
        expected_fragments = (
            "replay_route_shortcut_entrypoint_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1'",
            "suite_router_next_steps_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_suite_router_next_steps.ps1'",
            "attached_bundle_entrypoint_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1'",
            "safe_route_entrypoints_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1'",
            "fresh_replay_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1'",
            "reuse_current_outputs_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1'",
            "runner_patch_next_step_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_patch_next_step.ps1'",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.replay_route)

    def test_replay_route_keeps_recommended_next_logic_for_shortcut_and_bundle(self) -> None:
        expected_fragments = (
            "$route.recommended_next_command = if ($route.explicit_input_path_count -gt 0)",
            "$route.attached_bundle_entrypoint_command",
            "$route.replay_route_shortcut_entrypoint_command",
            "Pinned input paths are already present",
            "No bundle inputs are pinned yet",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.replay_route)

    def test_replay_route_notes_keep_context_and_bridge_guidance(self) -> None:
        expected_fragments = (
            "Use suite_router_shortcut_entrypoint_command when the higher-level suite router has already narrowed the route to issue #3",
            "Use replay_route_shortcut_entrypoint_command when you are already inside the replay-route helper",
            "Use suite_router_next_steps_command when you want the compact next-step matrix",
            "If the current saved or attached pages are the known three-page compatibility bundle",
            "Open safe_route_entrypoints_command when you are ready to choose between the fresh replay, reuse-current-outputs, refresh-status, handoff, summary-guide, and runner-wiring helpers.",
            "Keep replay_route_shortcut_bridge_note_path open",
            "Keep replay_route_bundle_first_bridge_note_path open",
            "When LIGHTPANDA_REPO_ROOT, a saved SummaryPath, or pinned InputPath values are already guiding the replay",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.replay_route)

    def test_replay_route_console_output_keeps_key_companion_surfaces_visible(self) -> None:
        expected_fragments = (
            "Write-Host 'Google issue #3 replay route'",
            'Write-Host ((\\"Recommended next:    {0}\\") -f $route.recommended_next_command)',
            'Write-Host ((\\"  Replay shortcut:       {0}\\") -f $route.replay_route_shortcut_entrypoint_command)',
            'Write-Host ((\\"  Next-step matrix:      {0}\\") -f $route.suite_router_next_steps_command)',
            'Write-Host ((\\"  Bundle helper:       {0}\\") -f $route.attached_bundle_entrypoint_command)',
            'Write-Host ((\\"  Runner next step:    {0}\\") -f $route.runner_patch_next_step_command)',
            'Write-Host ((\\"  Replay shortcut note: {0}\\") -f $route.replay_route_shortcut_bridge_note_path)',
            'Write-Host ((\\"  Bundle-first note:    {0}\\") -f $route.replay_route_bundle_first_bridge_note_path)',
            'Write-Host ((\\"  Validation chain:     {0}\\") -f $route.validation_chain_note_path)',
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.replay_route)

    def test_surface_checker_keeps_replay_route_contract_references(self) -> None:
        expected_fragments = (
            'New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE.md"',
            'New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md"',
            'New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md"',
            'New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1"',
            'New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1"',
            'New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1"',
            'New-ValidationReference -Path "scripts/windows/show_google_issue3_runner_patch_next_step.ps1"',
            'New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1"',
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.surface_check)

    def test_surface_checker_keeps_replay_route_content_expectations(self) -> None:
        expected_fragments = (
            "replay_route_shortcut_entrypoint_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1'",
            "attached_bundle_entrypoint_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1'",
            "safe_route_entrypoints_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1'",
            'Write-Host ((\\"  Replay shortcut:       {0}\\") -f $route.replay_route_shortcut_entrypoint_command)',
            'Write-Host ((\\"  Bundle helper:       {0}\\") -f $route.attached_bundle_entrypoint_command)',
            "docs/ISSUE3_REPLAY_ROUTE.md",
            "show_google_issue3_replay_route_shortcut_entrypoint.ps1",
            "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md",
        )
        for fragment in expected_fragments:
            self.assertIn(fragment, self.surface_check)

    def test_replay_route_note_keeps_shortcut_and_bundle_bridge_mentions(self) -> None:
        self.assertIn("show_google_issue3_replay_route_shortcut_entrypoint.ps1", self.replay_note)
        self.assertIn("docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md", self.replay_note)


if __name__ == "__main__":
    unittest.main()
