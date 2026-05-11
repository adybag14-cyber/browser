[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
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

$flow = [ordered]@{
    issue = "Attached HTML compatibility bundle validation flow"
    focus = "Print the current bundle-pinned headed localhost route for the known three-page compatibility set so future runs can stay on one stable command surface instead of hand-copying commands from the bundle checker output."
    input_mode = $bundle.input_mode
    discovered_candidate_count = $bundle.discovered_candidate_count
    matched_target_count = $bundle.matched_target_count
    validation_profile = $overall.bundle_validation_profile
    locked_input_count = $overall.bundle_locked_input_count
    preferred_initial_page = $overall.preferred_initial_page_display_path
    first_change_area = $overall.first_change_area
    first_bounded_step = $overall.first_step
    follow_up = $overall.follow_up
    bundle_summary = $overall.bundle_summary
    steps = @(
        [ordered]@{
            name = "bundle-check"
            goal = "Confirm the current saved-page set still resolves to the expected three-page compatibility bundle and reuse the same locked InputPath set for the rest of the flow."
            command = $printedBundleCheckerCommand
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
            command = $overall.bundle_flow
        }
        [ordered]@{
            name = "bundle-runner"
            goal = "Launch the headed localhost replay through the same bundle-pinned route after the earlier checks stay green."
            command = $overall.bundle_runner
        }
    )
    targets = $targetSummary
    notes = @(
        "Use this helper after the bundle checker when you want a stable read-first command surface for the current compatibility set instead of copying commands out of free-form checker output.",
        "The preferred initial page stays pinned to the Google Safety Centre target when the current bundle includes the Google-style page, so the issue #3 localhost-first follow-up remains aligned with the current runbook.",
        "Pass -InputPath when you want the same printed bundle flow but against an explicit saved-page set rather than the auto-discovered workspace bundle."
    )
    next_steps = @(
        "Use the bundle-pinned flow command when you want the exact printed localhost ladder with the current paths already locked in.",
        "Use the bundle-pinned runner command when the bundle checks are green and you want to launch the headed localhost replay directly.",
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
if ($flow.first_change_area) {
    Write-Host ("First change area: {0}" -f $flow.first_change_area)
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
    Write-Host ("  {0}" -f $step.command)
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
