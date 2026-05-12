[CmdletBinding()]
param(
    [string]$SummaryPath,
    [string]$ManifestPath,
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

function Resolve-ArtifactCandidatePath {
    param(
        [string]$ConfiguredPath,
        [Parameter(Mandatory = $true)]
        [string]$ArtifactRoot,
        [Parameter(Mandatory = $true)]
        [string]$FallbackName
    )

    if (-not [string]::IsNullOrWhiteSpace($ConfiguredPath)) {
        return $ConfiguredPath
    }

    return Join-Path $ArtifactRoot $FallbackName
}

function Read-ArtifactJson {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Test-HasProperty {
    param(
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [bool]($Object -and $Object.PSObject.Properties[$Name])
}

function Set-ObjectProperty {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        $Value
    )

    $property = $Object.PSObject.Properties[$Name]
    if ($property) {
        $property.Value = $Value
    } else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function Write-ArtifactJson {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $Object | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -Encoding Ascii
}

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json"
}
if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    throw "Issue #3 recommended validation summary not found: $SummaryPath"
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$artifactRoot = if ((Test-HasProperty -Object $summary -Name 'artifact_root') -and -not [string]::IsNullOrWhiteSpace($summary.artifact_root)) {
    $summary.artifact_root
} else {
    Split-Path -Parent $SummaryPath
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-summary-error-field-contract-repair.json'
}
if (-not $ManifestPath) {
    $configuredManifestPath = if (Test-HasProperty -Object $summary -Name 'manifest_artifact_path') {
        $summary.manifest_artifact_path
    } else {
        $null
    }
    $ManifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredManifestPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
}

$manifestExists = Test-Path -LiteralPath $ManifestPath -PathType Leaf
$manifest = $null
$manifestError = $null
if ($manifestExists) {
    try {
        $manifest = Read-ArtifactJson $ManifestPath
    } catch {
        $manifestError = $_.Exception.Message
    }
}

$summaryHasRefreshErrorField = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_error'
$summaryHasHandoffErrorField = Test-HasProperty -Object $summary -Name 'handoff_artifact_error'
$manifestHasRefreshErrorField = Test-HasProperty -Object $manifest -Name 'refresh_chain_artifact_error'
$manifestHasHandoffErrorField = Test-HasProperty -Object $manifest -Name 'handoff_artifact_error'

$resolvedRefreshError = if ($summaryHasRefreshErrorField) {
    $summary.refresh_chain_artifact_error
} elseif ($manifestHasRefreshErrorField) {
    $manifest.refresh_chain_artifact_error
} else {
    $null
}
$resolvedHandoffError = if ($summaryHasHandoffErrorField) {
    $summary.handoff_artifact_error
} elseif ($manifestHasHandoffErrorField) {
    $manifest.handoff_artifact_error
} else {
    $null
}

$summaryUpdatedFields = New-Object System.Collections.Generic.List[string]
$manifestUpdatedFields = New-Object System.Collections.Generic.List[string]

if (-not $summaryHasRefreshErrorField) {
    Set-ObjectProperty -Object $summary -Name 'refresh_chain_artifact_error' -Value $resolvedRefreshError
    $summaryUpdatedFields.Add('refresh_chain_artifact_error') | Out-Null
}
if (-not $summaryHasHandoffErrorField) {
    Set-ObjectProperty -Object $summary -Name 'handoff_artifact_error' -Value $resolvedHandoffError
    $summaryUpdatedFields.Add('handoff_artifact_error') | Out-Null
}
if ($summaryUpdatedFields.Count -gt 0) {
    Write-ArtifactJson -Object $summary -Path $SummaryPath
}

if ($manifest) {
    if (-not $manifestHasRefreshErrorField) {
        Set-ObjectProperty -Object $manifest -Name 'refresh_chain_artifact_error' -Value $resolvedRefreshError
        $manifestUpdatedFields.Add('refresh_chain_artifact_error') | Out-Null
    }
    if (-not $manifestHasHandoffErrorField) {
        Set-ObjectProperty -Object $manifest -Name 'handoff_artifact_error' -Value $resolvedHandoffError
        $manifestUpdatedFields.Add('handoff_artifact_error') | Out-Null
    }
    if ($manifestUpdatedFields.Count -gt 0) {
        Write-ArtifactJson -Object $manifest -Path $ManifestPath
    }
}

$status = if (-not $manifestExists) {
    if ($summaryUpdatedFields.Count -gt 0) { 'summary-updated-manifest-missing' } else { 'manifest-missing' }
} elseif ($manifestError) {
    if ($summaryUpdatedFields.Count -gt 0) { 'summary-updated-manifest-unreadable' } else { 'manifest-unreadable' }
} elseif ($summaryUpdatedFields.Count -gt 0 -or $manifestUpdatedFields.Count -gt 0) {
    'updated'
} else {
    'noop'
}

$runnerOutputWiringSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$runnerOutputWiringCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$runnerRefreshWiringCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_refresh_wiring_status.ps1'
$recommendedCommand = $runnerOutputWiringSafeCommand
$recommendedGuideCommand = $runnerOutputWiringCommand
$summaryPointerRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_summary_pointers.ps1'
$broaderRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

$reason = if ($status -eq 'updated') {
    'The saved issue #3 summary and manifest now preserve the refresh and handoff error-field contract even when those values are empty, so strict-mode wiring helpers can distinguish missing fields from blank error values.'
} elseif ($status -eq 'summary-updated-manifest-missing') {
    'The saved summary now preserves the refresh and handoff error-field contract, but the manifest file is still missing and must be regenerated by a fresh recommended-validation replay.'
} elseif ($status -eq 'summary-updated-manifest-unreadable') {
    'The saved summary now preserves the refresh and handoff error-field contract, but the manifest could not be read cleanly and still needs regeneration.'
} elseif ($status -eq 'manifest-missing') {
    'The summary already carried the refresh and handoff error fields, but no saved manifest was available to align with the same contract.'
} elseif ($status -eq 'manifest-unreadable') {
    'The summary already carried the refresh and handoff error fields, but the saved manifest could not be read cleanly.'
} else {
    'The saved summary and manifest already preserved the refresh and handoff error-field contract, so there was nothing left for this helper to repair.'
}

$nextFocus = if ($status -eq 'updated' -or $status -eq 'noop') {
    'Reopen the safe runner-output wiring audit first, then use the raw runner-output wiring helper only after the safe gate says the stricter check is appropriate.'
} else {
    'Regenerate the broader recommended-validation outputs first, then rerun the safe runner-output wiring audit before reopening the stricter runner helpers if the saved contract is still incomplete.'
}

$report = [ordered]@{
    issue = 'Google issue #3 summary error-field contract repair'
    purpose = 'Backfill missing refresh and handoff error fields into the saved issue #3 summary and manifest so strict-mode helper audits can distinguish missing fields from blank error values.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    manifest_path = $ManifestPath
    manifest_exists = [bool]$manifestExists
    manifest_error = $manifestError
    artifact_path = $ArtifactPath
    status = $status
    summary_has_refresh_error_field_before = [bool]$summaryHasRefreshErrorField
    summary_has_handoff_error_field_before = [bool]$summaryHasHandoffErrorField
    manifest_has_refresh_error_field_before = [bool]$manifestHasRefreshErrorField
    manifest_has_handoff_error_field_before = [bool]$manifestHasHandoffErrorField
    summary_updated_fields = @($summaryUpdatedFields)
    manifest_updated_fields = @($manifestUpdatedFields)
    resolved_refresh_error = $resolvedRefreshError
    resolved_handoff_error = $resolvedHandoffError
    runner_output_wiring_safe_command = $runnerOutputWiringSafeCommand
    runner_output_wiring_command = $runnerOutputWiringCommand
    runner_refresh_wiring_command = $runnerRefreshWiringCommand
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    summary_pointer_repair_command = $summaryPointerRepairCommand
    broader_runner_command = $broaderRunnerCommand
    reason = $reason
    next_focus = $nextFocus
}

$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    if ($manifestError) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 summary error-field contract repair'
Write-Host ''
Write-Host ("Summary:  {0}" -f $report.summary_path)
Write-Host ("Manifest: {0}" -f $report.manifest_path)
Write-Host ("Report:   {0}" -f $report.artifact_path)
Write-Host ("Status:   {0}" -f $report.status)
Write-Host ("Summary refresh field before: {0}" -f $report.summary_has_refresh_error_field_before)
Write-Host ("Summary handoff field before: {0}" -f $report.summary_has_handoff_error_field_before)
Write-Host ("Manifest refresh field before: {0}" -f $report.manifest_has_refresh_error_field_before)
Write-Host ("Manifest handoff field before: {0}" -f $report.manifest_has_handoff_error_field_before)
if ($report.summary_updated_fields.Count -gt 0) {
    Write-Host ("Summary fields updated: {0}" -f ($report.summary_updated_fields -join ', '))
}
if ($report.manifest_updated_fields.Count -gt 0) {
    Write-Host ("Manifest fields updated: {0}" -f ($report.manifest_updated_fields -join ', '))
}
if ($report.manifest_error) {
    Write-Host ("Manifest error: {0}" -f $report.manifest_error)
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Verify: {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
Write-Host ("Refresh audit: {0}" -f $report.runner_refresh_wiring_command)
Write-Host ("Pointer repair: {0}" -f $report.summary_pointer_repair_command)
Write-Host ("Runner: {0}" -f $report.broader_runner_command)

if ($report.manifest_error) {
    exit 1
}
