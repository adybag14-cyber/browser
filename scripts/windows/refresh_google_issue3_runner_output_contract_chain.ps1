[CmdletBinding()]
param(
    [string]$SummaryPath,
    [string]$ArtifactPath,
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

function Read-ArtifactJson {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Get-OptionalPropertyValue {
    param(
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($Object -and $Object.PSObject.Properties[$Name]) {
        return $Object.$Name
    }

    return $null
}

function Invoke-JsonHelper {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string]$ToolName,
        [object[]]$ArgumentList
    )

    if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
        throw "$ToolName not found: $ScriptPath"
    }

    $output = @(
        & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList -Json 2>&1
    )
    $exitCode = $LASTEXITCODE
    $text = ($output | ForEach-Object { "${_}" }) -join [Environment]::NewLine
    if ([string]::IsNullOrWhiteSpace($text)) {
        throw "$ToolName produced no JSON output."
    }

    try {
        $record = $text | ConvertFrom-Json
    } catch {
        throw ("{0} returned non-JSON output." -f $ToolName)
    }

    if ($exitCode -ne 0) {
        throw ("{0} failed with exit code {1}." -f $ToolName, $exitCode)
    }

    return $record
}

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json"
}

$summaryRecord = Read-ArtifactJson $SummaryPath
$configuredArtifactRoot = Get-OptionalPropertyValue -Object $summaryRecord -Name 'artifact_root'
$artifactRoot = if (-not [string]::IsNullOrWhiteSpace($configuredArtifactRoot)) {
    $configuredArtifactRoot
} else {
    Split-Path -Parent $SummaryPath
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-runner-output-contract-chain.json'
}

$repairScript = Join-Path $PSScriptRoot 'repair_google_issue3_runner_output_contract.ps1'
$wiringStatusScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_wiring_status.ps1'

$repairReport = Invoke-JsonHelper -ScriptPath $repairScript -ToolName 'Google issue #3 runner output contract repair helper' -ArgumentList @('-SummaryPath', $SummaryPath)
$wiringReport = Invoke-JsonHelper -ScriptPath $wiringStatusScript -ToolName 'Google issue #3 runner output wiring status helper' -ArgumentList @('-SummaryPath', $SummaryPath)

$status = $wiringReport.status
$reason = $wiringReport.reason
$nextFocus = $wiringReport.next_focus
if ($wiringReport.status -eq 'fully-wired' -and $repairReport.status -eq 'updated') {
    $status = 'repaired-and-fully-wired'
    $reason = 'The saved issue #3 summary and manifest were repaired and now both advertise the refresh and handoff runner-output contract directly.'
    $nextFocus = 'Move back to the narrower refresh-status or handoff helpers on the next Windows replay instead of spending another branch slice on runner-output cleanup.'
} elseif ($wiringReport.status -eq 'fully-wired') {
    $status = 'fully-wired'
    $reason = 'The saved issue #3 summary and manifest already advertise the refresh and handoff runner-output contract directly.'
    $nextFocus = 'Use the narrower refresh-status or handoff helpers for the next Windows replay.'
} elseif ($repairReport.status -eq 'updated') {
    $status = 'repaired-followup-still-needed'
    $reason = 'The saved outputs were repaired, but the wiring audit still found a remaining runner-output follow-up before the chain is fully direct.'
    $nextFocus = $wiringReport.next_focus
}

$report = [ordered]@{
    issue = 'Google issue #3 runner output contract chain refresh'
    purpose = 'Run the saved-output repair and immediate wiring audit together so the next Windows replay can see whether the saved issue #3 runner contract is now fully wired.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    repair_script_path = $repairScript
    wiring_status_script_path = $wiringStatusScript
    repair_status = $repairReport.status
    repair_reason = $repairReport.reason
    repair_report_path = $repairReport.artifact_path
    repair_summary_updated = $repairReport.summary_updated
    repair_manifest_updated = $repairReport.manifest_updated
    repair_summary_updated_fields = @($repairReport.summary_updated_fields)
    repair_manifest_updated_fields = @($repairReport.manifest_updated_fields)
    wiring_status = $wiringReport.status
    wiring_reason = $wiringReport.reason
    wiring_next_focus = $wiringReport.next_focus
    runner_outputs_fully_wired = if ($null -ne $wiringReport.runner_outputs_fully_wired) { [bool]$wiringReport.runner_outputs_fully_wired } else { $null }
    runner_patch_still_required = if ($null -ne $wiringReport.runner_patch_still_required) { [bool]$wiringReport.runner_patch_still_required } else { $null }
    next_artifact_to_open = $wiringReport.next_artifact_to_open
    recommended_command = $wiringReport.recommended_command
    recommended_guide_command = $wiringReport.recommended_guide_command
    repair_runner_output_contract_command = $wiringReport.repair_runner_output_contract_command
    broader_runner_command = $wiringReport.broader_runner_command
    status = $status
    reason = $reason
    next_focus = $nextFocus
    repair_report = $repairReport
    wiring_report = $wiringReport
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host 'Google issue #3 runner output contract chain refresh'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Report:    {0}" -f $report.artifact_path)
Write-Host ("Repair:    {0}" -f $report.repair_status)
Write-Host ("Repair report: {0}" -f $report.repair_report_path)
Write-Host ("Wiring:    {0}" -f $report.wiring_status)
Write-Host ("Status:    {0}" -f $report.status)
if ($report.repair_summary_updated_fields.Count -gt 0) {
    Write-Host ("Summary fields:  {0}" -f ($report.repair_summary_updated_fields -join ', '))
}
if ($report.repair_manifest_updated_fields.Count -gt 0) {
    Write-Host ("Manifest fields: {0}" -f ($report.repair_manifest_updated_fields -join ', '))
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
Write-Host ("Runner: {0}" -f $report.broader_runner_command)
