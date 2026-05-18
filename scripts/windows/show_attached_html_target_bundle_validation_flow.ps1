[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string[]]$InputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-PowerShellSingleQuotedLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Add-SharedArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        $Value
    )

    if ($null -eq $Value) {
        return
    }
    if ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    $Arguments.Add("-$Name")
    if ($Value -is [string]) {
        $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $Value))
    } else {
        $Arguments.Add([string]$Value)
    }
}

function Add-SharedPathArrayArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string[]]$Values
    )

    if (-not $Values -or $Values.Count -eq 0) {
        return
    }

    $Arguments.Add("-$Name")
    foreach ($value in $Values) {
        $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $value))
    }
}

function Format-HelperCommandWithRepoRootEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [System.Collections.Generic.List[string]]$Arguments,
        [string]$RepoRootOverride
    )

    $fileCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\$ScriptName"
    if ($Arguments -and $Arguments.Count -gt 0) {
        $fileCommand += " " + ($Arguments -join ' ')
    }

    if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        return $fileCommand
    }

    $command = "& '.\\scripts\\windows\\$ScriptName'"
    if ($Arguments -and $Arguments.Count -gt 0) {
        $command += " " + ($Arguments -join ' ')
    }

    $escapedRepoRoot = ("$RepoRootOverride") -replace "'", "''"
    return "powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$env:LIGHTPANDA_REPO_ROOT = '$escapedRepoRoot'; $command`""
}

$bundleSurfaceCheckPath = Join-Path $PSScriptRoot "check_attached_html_target_bundle_validation_surface.ps1"
$bundleSurfaceCheckCommand = '.\\scripts\\windows\\check_attached_html_target_bundle_validation_surface.ps1'
if (-not (Test-Path -LiteralPath $bundleSurfaceCheckPath -PathType Leaf)) {
    throw "Attached HTML target-bundle validation surface checker not found: $bundleSurfaceCheckPath"
}

$bundleSurfaceCheckArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleSurfaceCheckArgs -Name RepoRoot -Value $RepoRoot
$printedBundleSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File $bundleSurfaceCheckCommand"
if ($bundleSurfaceCheckArgs.Count -gt 0) {
    $printedBundleSurfaceCheckCommand += " " + ($bundleSurfaceCheckArgs -join " ")
}

$bundleCheckerPath = Join-Path $PSScriptRoot "check_attached_html_target_bundle.ps1"
$bundleCheckerCommand = '.\\scripts\\windows\\check_attached_html_target_bundle.ps1'
if (-not (Test-Path -LiteralPath $bundleCheckerPath -PathType Leaf)) {
    throw "Attached HTML target bundle checker not found: $bundleCheckerPath"
}

$bundleCheckerArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleCheckerArgs -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleCheckerArgs -Name InputPath -Values $InputPath
$printedBundleCheckerCommand = "powershell -ExecutionPolicy Bypass -File $bundleCheckerCommand"
if ($bundleCheckerArgs.Count -gt 0) {
    $printedBundleCheckerCommand += " " + ($bundleCheckerArgs -join " ")
}

$invokeArgs = @{ Json = $true }
if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
    $invokeArgs.RepoRoot = $RepoRoot
}
if ($InputPath -and $InputPath.Count -gt 0) {
    $invokeArgs.InputPath = $InputPath
}

$bundleJson = (& $bundleCheckerPath @invokeArgs) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$bundle = $bundleJson | ConvertFrom-Json -Depth 12
$overall = $bundle.overall_recommendation
if (-not $overall.bundle_validation_profile) {
    throw "Attached HTML target bundle checker did not return bundle-pinned validation metadata."
}

$suiteRouterArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $suiteRouterArgs -Name ChangeArea -Value $overall.first_change_area
$suiteRouterCommand = if ($overall.first_change_area) {
    Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $suiteRouterArgs -RepoRootOverride $RepoRoot
} else {
    $null
}

$suiteRouterNote = if ($suiteRouterCommand) {
    "Use the shared suite router shortcut '$suiteRouterCommand' when you want the main validation map to point back at the same primary change area before you lock into the bundle-pinned attached-page follow-up, while keeping a non-default repo root attached when one is already in play."
} else {
    "Resolve at least one bundle target first so the shared suite router shortcut can point back at the matching primary change area before localhost replay."
}

$resolvedTargets = @($bundle.targets | Where-Object { $_.status -eq 'found' })
$targetSummary = @(
    $resolvedTargets | ForEach-Object {
        [ordered]@{
            display_name = $_.display_name
            display_path = $_.display_path
            route_change_area = $_.route_change_area
            bounded_first_step = $_.bounded_first_step
            follow_up = $_.follow_up
        }
    }
)

$resolvedFixturePaths = @($resolvedTargets | ForEach-Object { $_.path } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
$pinnedBundleFollowUpArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $pinnedBundleFollowUpArgs -Name RepoRoot -Value $RepoRoot
if ($resolvedFixturePaths.Count -gt 0) {
    Add-SharedPathArrayArgument -Arguments $pinnedBundleFollowUpArgs -Name InputPath -Values $resolvedFixturePaths
} else {
    Add-SharedPathArrayArgument -Arguments $pinnedBundleFollowUpArgs -Name InputPath -Values $InputPath
}

$bundleFlowArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleFlowArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleFlowArgs -Name BrowserExe -Value $BrowserExe
if ($resolvedFixturePaths.Count -gt 0) {
    Add-SharedPathArrayArgument -Arguments $bundleFlowArgs -Name InputPath -Values $resolvedFixturePaths
} else {
    Add-SharedPathArrayArgument -Arguments $bundleFlowArgs -Name InputPath -Values $InputPath
}
$bundleFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_target_bundle_validation_flow.ps1"
if ($bundleFlowArgs.Count -gt 0) {
    $bundleFlowCommand += " " + ($bundleFlowArgs -join " ")
}

$bundleRunnerArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleRunnerArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleRunnerArgs -Name BrowserExe -Value $BrowserExe
if ($resolvedFixturePaths.Count -gt 0) {
    Add-SharedPathArrayArgument -Arguments $bundleRunnerArgs -Name InputPath -Values $resolvedFixturePaths
} else {
    Add-SharedPathArrayArgument -Arguments $bundleRunnerArgs -Name InputPath -Values $InputPath
}
$bundleRunnerCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1"
if ($bundleRunnerArgs.Count -gt 0) {
    $bundleRunnerCommand += " " + ($bundleRunnerArgs -join " ")
}

$attachedPagesSidecarAuditArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $attachedPagesSidecarAuditArgs -Name RepoRoot -Value $RepoRoot
if ($resolvedFixturePaths.Count -gt 0) {
    Add-SharedPathArrayArgument -Arguments $attachedPagesSidecarAuditArgs -Name InputPath -Values $resolvedFixturePaths
} else {
    Add-SharedPathArrayArgument -Arguments $attachedPagesSidecarAuditArgs -Name InputPath -Values $InputPath
}
$attachedPagesSidecarAuditCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1"
if ($attachedPagesSidecarAuditArgs.Count -gt 0) {
    $attachedPagesSidecarAuditCommand += " " + ($attachedPagesSidecarAuditArgs -join " ")
}
$attachedPagesSidecarAuditCommand += " -AuditSidecars"

$issue3SuiteRouterNextStepsCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_next_steps.ps1"
if ($pinnedBundleFollowUpArgs.Count -gt 0) {
    $issue3SuiteRouterNextStepsCommand += " " + ($pinnedBundleFollowUpArgs -join " ")
}

$issue3ReplayShortcutsCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1"
if ($pinnedBundleFollowUpArgs.Count -gt 0) {
    $issue3ReplayShortcutsCommand += " " + ($pinnedBundleFollowUpArgs -join " ")
}

$localHtmlFixtureSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_local_html_fixture_validation_surface.ps1"
if ($pinnedBundleFollowUpArgs.Count -gt 0) {
    $localHtmlFixtureSurfaceCheckCommand += " " + ($pinnedBundleFollowUpArgs -join " ")
}

$localHtmlFixtureProbeCommand = $null
if ($resolvedFixturePaths.Count -gt 0) {
    $fixtureProbeArgs = [System.Collections.Generic.List[string]]::new()
    Add-SharedArgument -Arguments $fixtureProbeArgs -Name RepoRoot -Value $RepoRoot
    Add-SharedPathArrayArgument -Arguments $fixtureProbeArgs -Name FixturePaths -Values $resolvedFixturePaths
    $localHtmlFixtureProbeCommand = "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\local-html-fixtures\\chrome-local-html-fixture-probe.ps1"
    if ($fixtureProbeArgs.Count -gt 0) {
        $localHtmlFixtureProbeCommand += " " + ($fixtureProbeArgs -join " ")
    }
}

$flow = [ordered]@{
    issue = "Attached HTML compatibility bundle validation flow"
    focus = "Print the current bundle-pinned headed localhost route for the known three-page compatibility set so future runs can start with a fail-fast surface check, keep the pinned manual checklist nearby, and replay the same inputs through both the bundle runner and the reusable fixed-list probe."
    input_mode = $bundle.input_mode
    discovered_candidate_count = $bundle.discovered_candidate_count
    matched_target_count = $bundle.matched_target_count
    validation_profile = $overall.bundle_validation_profile
    locked_input_count = $overall.bundle_locked_input_count
    locked_input_paths = $resolvedFixturePaths
    preferred_initial_page = $overall.preferred_initial_page_display_path
    browser_exe = $BrowserExe
    first_change_area = $overall.first_change_area
    suite_router_command = $suiteRouterCommand
    issue3_suite_router_next_steps_command = $issue3SuiteRouterNextStepsCommand
    issue3_replay_shortcuts_command = $issue3ReplayShortcutsCommand
    local_html_fixture_surface_check_command = $localHtmlFixtureSurfaceCheckCommand
    local_html_fixture_probe_command = $localHtmlFixtureProbeCommand
    attached_pages_sidecar_audit_command = $attachedPagesSidecarAuditCommand
    first_bounded_step = $overall.first_step
    follow_up = $overall.follow_up
    bundle_summary = $overall.bundle_summary
    checklist_note = "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md"
    steps = @(
        [ordered]@{
            name = "bundle-route-surface-check"
            goal = "Fail fast if the bundle guide, checklist, checker, helper, runner, reusable fixture probe, or delegated attached-HTML validation surfaces drifted before you trust the pinned bundle route."
            command = $printedBundleSurfaceCheckCommand
        }
        [ordered]@{
            name = "bundle-check"
            goal = "Confirm the current saved-page set still resolves to the expected three-page compatibility bundle and reuse the same locked InputPath set for the rest of the flow."
            command = $printedBundleCheckerCommand
        }
        [ordered]@{
            name = "bundle-sidecar-audit"
            goal = "Fail fast if any locked bundle export is missing its sibling `_files` sidecar before broader attached-page surface checks or the delegated runner start."
            command = $attachedPagesSidecarAuditCommand
        }
        [ordered]@{
            name = "bundle-surface-check"
            goal = "Run the exact bundle-pinned surface checker before the broader localhost replay starts."
            command = $overall.bundle_surface_check
        }
        [ordered]@{
            name = "bundle-asset-closure"
            goal = "Run the exact deep asset-closure audit for the same locked bundle so missing sibling assets fail fast before launch."
            command = $overall.bundle_asset_closure
        }
        [ordered]@{
            name = "bundle-flow"
            goal = "Print the exact localhost-first validation ladder with the current bundle paths and preferred initial page already pinned."
            command = $bundleFlowCommand
        }
        [ordered]@{
            name = "bundle-runner"
            goal = "Launch the headed localhost replay through the same bundle-pinned route after the earlier checks stay green."
            command = $bundleRunnerCommand
        }
        [ordered]@{
            name = "local-fixture-surface-check"
            goal = "Fail fast on the reusable fixed-list fixture probe surface before rerunning the same saved pages through the screenshot-and-title harness."
            command = $localHtmlFixtureSurfaceCheckCommand
        }
        [ordered]@{
            name = "local-fixture-probe"
            goal = "Replay the same locked compatibility bundle through the reusable fixed-list localhost fixture probe for screenshot-and-title proof outside the broader attached-page wrapper."
            command = $localHtmlFixtureProbeCommand
        }
    )
    targets = $targetSummary
    notes = @(
        "Use this helper after the bundle route surface check when you want a stable read-first command surface for the current compatibility set instead of copying commands out of free-form checker output.",
        $suiteRouterNote,
        "Keep docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md nearby for the page-by-page manual checks once the bundle-pinned localhost route is green.",
        'Run the attached-pages sidecar audit command before the broader attached-page surface checks when you want a missing sibling `_files` bundle to fail fast on the same locked inputs instead of looking like a deeper browser regression.',
        "Use the reusable fixed-list fixture surface check and probe when you want screenshot-and-title proof for the same locked inputs without reopening the broader attached-page wrapper flow.",
        "When the bundle targets resolve successfully, the printed issue #3 next-step, replay-shortcuts, and local-fixture surface-check commands already carry the same locked paths forward, even when the current bundle started from auto-discovery.",
        "Use the issue #3 next-step matrix when you want the compact branch chooser reprinted with the same pinned bundle inputs before deciding whether to stay on the bundle route or reopen the narrower replay-shortcuts helper.",
        "Use the issue #3 replay-shortcuts helper after the bundle flow or bundle runner when the attached-page replay has already narrowed the failure and you want the narrower safe-route, replay-route, and bundle-first commands preserved with the same pinned inputs.",
        "The preferred initial page stays pinned to the Google Safety Centre target when the current bundle includes the Google-style page, so the issue #3 localhost-first follow-up remains aligned with the current runbook.",
        "Pass -BrowserExe when the replay should stay pinned to a non-default headed build all the way through the printed bundle flow and delegated bundle runner instead of falling back to .\\zig-out\\bin\\lightpanda.exe.",
        "Pass -InputPath when you want the same printed bundle flow but against an explicit saved-page set rather than the auto-discovered workspace bundle.",
        "Pass -RepoRoot when you want the bundle route surface check, the bundle checker, and the shared suite-router shortcut to stay attached to a non-default working tree before printing the pinned commands."
    )
    next_steps = @(
        "Use the bundle route surface-check command first when the branch has moved and you want the bundle-aware guide, checklist, helper, runner, reusable fixture probe, and delegated attached-HTML surfaces to fail fast before anything else.",
        'Use the attached-pages sidecar audit command right after the bundle check when you want missing sibling `_files` bundles ruled out before broader attached-page surface checks or the delegated runner make the failure look deeper than it is.',
        "Use the bundle-pinned flow command when you want the exact printed localhost ladder with the current paths and BrowserExe already locked in.",
        "Use the bundle-pinned runner command when the bundle checks are green and you want to launch the headed localhost replay directly.",
        "Use the reusable local fixture surface check and probe when you want screenshot-and-title proof for the same three saved pages after the broader bundle route is confirmed.",
        "Use the issue #3 next-step matrix when you want the same pinned bundle inputs carried back into the compact branch chooser before reopening replay shortcuts or the broader safe-route map.",
        "Use the issue #3 replay-shortcuts helper after the bundle route when the failure is now clearly inside issue #3 and you want the narrower safe-route, replay-route, and bundle-first commands with the same pinned inputs.",
        "Move back to the smaller Google title, submit-timing, or shared Enter-order ladders only after the attached-page replay makes the next failure state clear."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host "Attached HTML compatibility bundle validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Input mode: {0}" -f $flow.input_mode)
Write-Host ("Discovered candidates: {0}" -f $flow.discovered_candidate_count)
Write-Host ("Matched targets: {0}" -f $flow.matched_target_count)
Write-Host ("Validation profile: {0}" -f $flow.validation_profile)
Write-Host ("Locked input count: {0}" -f $flow.locked_input_count)
if ($flow.preferred_initial_page) {
    Write-Host ("Preferred initial page: {0}" -f $flow.preferred_initial_page)
}
if ($flow.browser_exe) {
    Write-Host ("Browser exe: {0}" -f $flow.browser_exe)
}
if ($flow.first_change_area) {
    Write-Host ("First change area: {0}" -f $flow.first_change_area)
}
if ($flow.suite_router_command) {
    Write-Host ("Shared suite router: {0}" -f $flow.suite_router_command)
}
if ($flow.issue3_suite_router_next_steps_command) {
    Write-Host ("Issue #3 next-step matrix: {0}" -f $flow.issue3_suite_router_next_steps_command)
}
if ($flow.issue3_replay_shortcuts_command) {
    Write-Host ("Issue #3 replay shortcuts: {0}" -f $flow.issue3_replay_shortcuts_command)
}
if ($flow.local_html_fixture_surface_check_command) {
    Write-Host ("Local fixture surface check: {0}" -f $flow.local_html_fixture_surface_check_command)
}
if ($flow.local_html_fixture_probe_command) {
    Write-Host ("Local fixture probe: {0}" -f $flow.local_html_fixture_probe_command)
}
if ($flow.attached_pages_sidecar_audit_command) {
    Write-Host ("Attached-pages sidecar audit: {0}" -f $flow.attached_pages_sidecar_audit_command)
}
if ($flow.checklist_note) {
    Write-Host ("Manual checklist: {0}" -f $flow.checklist_note)
}
if ($flow.first_bounded_step) {
    Write-Host ("Suggested first bounded step: {0}" -f $flow.first_bounded_step)
}
if ($flow.follow_up) {
    Write-Host ("Suggested follow-up: {0}" -f $flow.follow_up)
}
Write-Host ("Bundle summary: {0}" -f $flow.bundle_summary)
Write-Host ""
foreach ($step in $flow.steps) {
    Write-Host ("[{0}] {1}" -f $step.name, $step.goal)
    if ($step.command) {
        Write-Host ("  {0}" -f $step.command)
    } else {
        Write-Host "  <resolve bundle inputs first>"
    }
    Write-Host ""
}
if ($flow.targets.Count -gt 0) {
    Write-Host "Resolved targets:"
    foreach ($target in $flow.targets) {
        Write-Host ("- {0}" -f $target.display_name)
        if ($target.display_path) {
            Write-Host ("  Path: {0}" -f $target.display_path)
        }
        if ($target.route_change_area) {
            Write-Host ("  Route: {0}" -f $target.route_change_area)
        }
        if ($target.bounded_first_step) {
            Write-Host ("  First bounded step: {0}" -f $target.bounded_first_step)
        }
        if ($target.follow_up) {
            Write-Host ("  Follow-up: {0}" -f $target.follow_up)
        }
    }
    Write-Host ""
}
Write-Host "Notes:"
foreach ($note in $flow.notes) {
    Write-Host ("- {0}" -f $note)
}
Write-Host ""
Write-Host "Next steps:"
foreach ($step in $flow.next_steps) {
    Write-Host ("- {0}" -f $step)
}