[CmdletBinding()]
param(
    [string]$SummaryPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot([string]$StartPath) {
    if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
        return $env:LIGHTPANDA_REPO_ROOT
    }

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor "build.zig")) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            throw "Could not resolve the Lightpanda repo root from $StartPath. Set LIGHTPANDA_REPO_ROOT to override."
        }
        $cursor = $parent
    }
}

function Convert-ToQuotedPowerShellArgument([string]$Value) {
    return "'" + $Value.Replace("'", "''") + "'"
}

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json"
}
if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    throw "Issue #3 recommended validation summary not found: $SummaryPath"
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$manualInputPath = @($summary.manual_input_path)
$missingFixtureAssetAudit = @($summary.missing_fixture_asset_audit)
$fixturesWithMissingAssets = @($missingFixtureAssetAudit | Where-Object { $_ -and $_.missing_asset_count -gt 0 })

if (-not $summary.manual_phase_uses_fixture_selection -or $manualInputPath.Count -eq 0) {
    throw "The saved issue #3 summary does not contain an attached-HTML manual fixture selection to replay."
}

$quotedInputPath = @($manualInputPath | ForEach-Object { Convert-ToQuotedPowerShellArgument $_ })
$inputPathArguments = $quotedInputPath -join ' '
$preferredInitialPageArgument = if ($summary.manual_initial_page) {
    " -PreferredInitialPage " + (Convert-ToQuotedPowerShellArgument $summary.manual_initial_page)
} else {
    ""
}

$assetClosureCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle -InputPath $inputPathArguments"
$flowCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -InputPath $inputPathArguments$preferredInitialPageArgument"
$runnerCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait -InputPath $inputPathArguments$preferredInitialPageArgument"
$savedPageCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_saved_page_google_validation_flow.ps1 -InputPath $inputPathArguments"

$result = [ordered]@{
    issue = 'Google issue #3 manual fixture replay'
    purpose = 'Replay the attached-HTML manual follow-up with the exact saved fixture bundle recorded by the recommended validation summary.'
    summary_path = $SummaryPath
    generated_at_utc = $summary.generated_at_utc
    manual_phase_google_style = [bool]$summary.manual_phase_google_style
    fixture_count = $manualInputPath.Count
    fixture_paths = @($manualInputPath)
    preferred_initial_page = $summary.manual_initial_page
    fixture_assets_missing = ($fixturesWithMissingAssets.Count -gt 0)
    fixture_selection_missing_asset_count = $fixturesWithMissingAssets.Count
    missing_fixture_asset_audit = @($missingFixtureAssetAudit)
    asset_closure_command = $assetClosureCommand
    flow_command = $flowCommand
    runner_command = $runnerCommand
    saved_page_flow_command = $savedPageCommand
    reminder = 'Run the asset-closure check first when saved exports have sibling assets, then use the attached-HTML flow or runner with the exact same fixture bundle before widening back out.'
}

if ($Json) {
    $result | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 manual fixture replay'
Write-Host ''
Write-Host ("Summary: {0}" -f $result.summary_path)
Write-Host ("Saved fixture count: {0}" -f $result.fixture_count)
Write-Host ''
Write-Host 'Saved fixture selection:'
foreach ($fixturePath in $result.fixture_paths) {
    Write-Host ("- {0}" -f $fixturePath)
}
if ($result.preferred_initial_page) {
    Write-Host ("Initial page: {0}" -f $result.preferred_initial_page)
}
if ($result.fixture_assets_missing) {
    Write-Host ''
    Write-Host 'Missing fixture assets:'
    foreach ($fixtureAudit in $fixturesWithMissingAssets) {
        Write-Host ("- {0} ({1})" -f $fixtureAudit.path, $fixtureAudit.missing_asset_count)
        foreach ($assetPath in ($fixtureAudit.missing_assets | Select-Object -First 5)) {
            Write-Host ("  - {0}" -f $assetPath)
        }
        if ($fixtureAudit.missing_asset_count -gt 5) {
            Write-Host ("  - ... {0} more" -f ($fixtureAudit.missing_asset_count - 5))
        }
    }
}
Write-Host ''
Write-Host ("Asset check: {0}" -f $result.asset_closure_command)
Write-Host ("Flow:        {0}" -f $result.flow_command)
Write-Host ("Runner:      {0}" -f $result.runner_command)
Write-Host ("Saved-page:  {0}" -f $result.saved_page_flow_command)
Write-Host ''
Write-Host ("Reminder:    {0}" -f $result.reminder)
