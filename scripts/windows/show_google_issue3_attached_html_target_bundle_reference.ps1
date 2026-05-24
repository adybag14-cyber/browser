[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
    [string]$BrowserExe,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [System.Collections.Generic.List[string]]$Arguments,
        [string[]]$Switches = @()
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\$ScriptName"
    if ($Arguments -and $Arguments.Count -gt 0) {
        $command += " " + ($Arguments -join ' ')
    }
    foreach ($switchName in $Switches) {
        if (-not [string]::IsNullOrWhiteSpace($switchName)) {
            $command += " -$switchName"
        }
    }

    return $command
}

function Format-ProbeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1"
    if ($Arguments -and $Arguments.Count -gt 0) {
        $command += " " + ($Arguments -join ' ')
    }

    return $command
}

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$checkerPath = Join-Path $PSScriptRoot 'check_attached_html_target_bundle.ps1'
if (-not (Test-Path -LiteralPath $checkerPath -PathType Leaf)) {
    throw "Attached HTML target bundle checker not found: $checkerPath"
}

$checkerArgs = @{
    Json = $true
}
if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
    $checkerArgs.RepoRoot = $RepoRoot
}
if ($InputPath -and $InputPath.Count -gt 0) {
    $checkerArgs.InputPath = $InputPath
}

$bundleJson = (& $checkerPath @checkerArgs) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0 -and [string]::IsNullOrWhiteSpace($bundleJson)) {
    exit $LASTEXITCODE
}

$bundle = $bundleJson | ConvertFrom-Json -Depth 12
$resolvedTargets = @($bundle.targets | Where-Object { $_.status -eq 'found' -and $_.path })
$preferredPage = if ($PreferredInitialPage) {
    $PreferredInitialPage
} elseif ($bundle.overall_recommendation.preferred_initial_page) {
    $bundle.overall_recommendation.preferred_initial_page
} else {
    $null
}

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $sharedArguments -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $sharedArguments -Name PreferredInitialPage -Value $preferredPage
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $InputPath

$bundleCheckerArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleCheckerArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleCheckerArguments -Name InputPath -Values $InputPath

$bundleSurfaceArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleSurfaceArguments -Name RepoRoot -Value $RepoRoot

$probeArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $probeArguments -Name RepoRoot -Value $RepoRoot
if ($InputPath -and $InputPath.Count -gt 0) {
    Add-SharedPathArrayArgument -Arguments $probeArguments -Name FixturePaths -Values $InputPath
} else {
    $probeArguments.Add('-FixturePaths')
    $probeArguments.Add("'<bundle-html-a>'")
    $probeArguments.Add("'<bundle-html-b>'")
    $probeArguments.Add("'<bundle-html-c>'")
}

$reference = [ordered]@{
    issue = 'Google issue #3 attached HTML target bundle reference'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    browser_exe = $BrowserExe
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    preferred_initial_page = $preferredPage
    bundle_passed = [bool]$bundle.passed
    input_mode = $bundle.input_mode
    discovered_candidate_count = $bundle.discovered_candidate_count
    expected_target_count = $bundle.expected_target_count
    matched_target_count = $bundle.matched_target_count
    overall_recommendation = $bundle.overall_recommendation.summary
    bundle_route_summary = $bundle.overall_recommendation.bundle_summary
    validation_profile = $bundle.overall_recommendation.bundle_validation_profile
    bundle_files = @(
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
    helper_commands = [ordered]@{
        bundle_surface_check = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $bundleSurfaceArguments
        bundle_check = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle.ps1' -Arguments $bundleCheckerArguments
        bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $sharedArguments
        bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $sharedArguments -Switches @('Wait')
        bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedArguments
        bundle_first_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
        proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $bundleSurfaceArguments
        proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $sharedArguments
        local_fixture_surface_check = Format-HelperCommand -ScriptName 'check_local_html_fixture_validation_surface.ps1' -Arguments $bundleSurfaceArguments
        local_fixture_probe = Format-ProbeCommand -Arguments $probeArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $sharedArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $sharedArguments
    }
    note_paths = [ordered]@{
        bundle_reference = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
        bundle_quickstart = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md'
        bundle_suite_surface = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md'
        bundle_proof = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md'
        bundle_checklist = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md'
        replay_route_shortcut = 'docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md'
    }
}

if ($Json) {
    $reference | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 attached HTML target bundle reference'
Write-Host ''
if ($reference.repo_root) {
    Write-Host ("Repo root:   {0}" -f $reference.repo_root)
}
if ($reference.summary_path) {
    Write-Host ("Summary path:{0}" -f " $($reference.summary_path)")
}
if ($reference.browser_exe) {
    Write-Host ("Browser exe: {0}" -f $reference.browser_exe)
}
if ($reference.preferred_initial_page) {
    Write-Host ("Preferred initial page: {0}" -f $reference.preferred_initial_page)
}
Write-Host ("Input mode: {0}" -f $reference.input_mode)
Write-Host ("Resolved targets: {0} of {1}" -f $reference.matched_target_count, $reference.expected_target_count)
Write-Host ("Validation profile: {0}" -f $reference.validation_profile)
Write-Host ''
Write-Host ("Overall recommendation: {0}" -f $reference.overall_recommendation)
Write-Host ("Bundle route summary:   {0}" -f $reference.bundle_route_summary)
Write-Host ''
Write-Host 'Pinned compatibility bundle:'
foreach ($bundleFile in $reference.bundle_files) {
    Write-Host ("  - {0}" -f $bundleFile.display_name)
    if ($bundleFile.display_path) {
        Write-Host ("    Path: {0}" -f $bundleFile.display_path)
    }
    if ($bundleFile.route_change_area) {
        Write-Host ("    Route: {0}" -f $bundleFile.route_change_area)
    }
}
Write-Host ''
Write-Host 'Read-first commands:'
Write-Host ("  Surface check: {0}" -f $reference.helper_commands.bundle_surface_check)
Write-Host ("  Bundle check:  {0}" -f $reference.helper_commands.bundle_check)
Write-Host ("  Flow helper:   {0}" -f $reference.helper_commands.bundle_flow)
Write-Host ("  Runner:        {0}" -f $reference.helper_commands.bundle_runner)
Write-Host ''
Write-Host 'Keep nearby:'
Write-Host ("  Suite surface: {0}" -f $reference.helper_commands.bundle_suite_surface)
Write-Host ("  Bundle-first:  {0}" -f $reference.helper_commands.bundle_first_entrypoint)
Write-Host ("  Proof check:   {0}" -f $reference.helper_commands.proof_surface_check)
Write-Host ("  Proof helper:  {0}" -f $reference.helper_commands.proof_entrypoint)
Write-Host ("  Fixture check: {0}" -f $reference.helper_commands.local_fixture_surface_check)
Write-Host ("  Fixture probe: {0}" -f $reference.helper_commands.local_fixture_probe)
Write-Host ("  Replay route:  {0}" -f $reference.helper_commands.replay_route)
Write-Host ("  Replay short:  {0}" -f $reference.helper_commands.replay_shortcuts)
Write-Host ''
Write-Host ("Bundle reference note: {0}" -f $reference.note_paths.bundle_reference)
Write-Host ("Bundle quickstart:     {0}" -f $reference.note_paths.bundle_quickstart)
Write-Host ("Bundle suite surface:  {0}" -f $reference.note_paths.bundle_suite_surface)
Write-Host ("Bundle proof note:     {0}" -f $reference.note_paths.bundle_proof)
Write-Host ("Pinned checklist:      {0}" -f $reference.note_paths.bundle_checklist)
Write-Host ("Replay-route bridge:   {0}" -f $reference.note_paths.replay_route_shortcut)
