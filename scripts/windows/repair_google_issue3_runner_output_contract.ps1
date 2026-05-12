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

function Get-OptionalPropertyValue {
    param(
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (Test-HasProperty -Object $Object -Name $Name) {
        return $Object.$Name
    }

    return $null
}

function Get-ConfiguredPathRecord {
    param(
        [object]$Primary,
        [object]$Secondary,
        [Parameter(Mandatory = $true)]
        [string]$FieldName
    )

    if ((Test-HasProperty -Object $Primary -Name $FieldName) -and -not [string]::IsNullOrWhiteSpace($Primary.$FieldName)) {
        return [pscustomobject]@{
            value = $Primary.$FieldName
            source = 'summary'
        }
    }

    if ((Test-HasProperty -Object $Secondary -Name $FieldName) -and -not [string]::IsNullOrWhiteSpace($Secondary.$FieldName)) {
        return [pscustomobject]@{
            value = $Secondary.$FieldName
            source = 'manifest'
        }
    }

    return $null
}

function Get-ErrorValueRecord {
    param(
        [object]$Primary,
        [object]$Secondary,
        [Parameter(Mandatory = $true)]
        [string]$FieldName
    )

    if (Test-HasProperty -Object $Primary -Name $FieldName) {
        return [pscustomobject]@{
            value = $Primary.$FieldName
            source = 'summary'
        }
    }

    if (Test-HasProperty -Object $Secondary -Name $FieldName) {
        return [pscustomobject]@{
            value = $Secondary.$FieldName
            source = 'manifest'
        }
    }

    return [pscustomobject]@{
        value = $null
        source = 'default-null'
    }
}

function Set-ContractField {
    param(
        [Parameter(Mandatory = $true)]
        $Object,
        [Parameter(Mandatory = $true)]
        [string]$FieldName,
        $Value,
        [switch]$TreatBlankAsMissing
    )

    $property = $Object.PSObject.Properties[$FieldName]
    $needsUpdate = -not $property
    if (-not $needsUpdate -and $TreatBlankAsMissing) {
        $needsUpdate = [string]::IsNullOrWhiteSpace([string]$property.Value)
    }

    if (-not $needsUpdate) {
        return $false
    }

    $Object | Add-Member -NotePropertyName $FieldName -NotePropertyValue $Value -Force
    return $true
}

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json"
}
if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    throw "Issue #3 recommended validation summary not found: $SummaryPath"
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$configuredArtifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
$artifactRoot = if (-not [string]::IsNullOrWhiteSpace($configuredArtifactRoot)) {
    $configuredArtifactRoot
} else {
    Split-Path -Parent $SummaryPath
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-runner-output-contract-repair.json'
}

$manifestConfigured = Get-ConfiguredPathRecord -Primary $summary -Secondary $null -FieldName 'manifest_artifact_path'
$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($manifestConfigured) { $manifestConfigured.value } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
$manifestRecord = $null
$manifestError = $null
if ($manifestExists) {
    try {
        $manifestRecord = Read-ArtifactJson $manifestPath
    } catch {
        $manifestError = $_.Exception.Message
    }
}
$manifestReadable = [bool]$manifestRecord

$refreshConfigured = Get-ConfiguredPathRecord -Primary $summary -Secondary $manifestRecord -FieldName 'refresh_chain_artifact_path'
$handoffConfigured = Get-ConfiguredPathRecord -Primary $summary -Secondary $manifestRecord -FieldName 'handoff_artifact_path'
$refreshErrorValue = Get-ErrorValueRecord -Primary $summary -Secondary $manifestRecord -FieldName 'refresh_chain_artifact_error'
$handoffErrorValue = Get-ErrorValueRecord -Primary $summary -Secondary $manifestRecord -FieldName 'handoff_artifact_error'

$resolvedRefreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($refreshConfigured) { $refreshConfigured.value } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$resolvedHandoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($handoffConfigured) { $handoffConfigured.value } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'

$summaryUpdatedFields = New-Object System.Collections.Generic.List[string]
$manifestUpdatedFields = New-Object System.Collections.Generic.List[string]

if (Set-ContractField -Object $summary -FieldName 'refresh_chain_artifact_path' -Value $resolvedRefreshPath -TreatBlankAsMissing) {
    $summaryUpdatedFields.Add('refresh_chain_artifact_path') | Out-Null
}
if (Set-ContractField -Object $summary -FieldName 'refresh_chain_artifact_error' -Value $refreshErrorValue.value) {
    $summaryUpdatedFields.Add('refresh_chain_artifact_error') | Out-Null
}
if (Set-ContractField -Object $summary -FieldName 'handoff_artifact_path' -Value $resolvedHandoffPath -TreatBlankAsMissing) {
    $summaryUpdatedFields.Add('handoff_artifact_path') | Out-Null
}
if (Set-ContractField -Object $summary -FieldName 'handoff_artifact_error' -Value $handoffErrorValue.value) {
    $summaryUpdatedFields.Add('handoff_artifact_error') | Out-Null
}

if ($manifestRecord) {
    if (Set-ContractField -Object $manifestRecord -FieldName 'refresh_chain_artifact_path' -Value $resolvedRefreshPath -TreatBlankAsMissing) {
        $manifestUpdatedFields.Add('refresh_chain_artifact_path') | Out-Null
    }
    if (Set-ContractField -Object $manifestRecord -FieldName 'refresh_chain_artifact_error' -Value $refreshErrorValue.value) {
        $manifestUpdatedFields.Add('refresh_chain_artifact_error') | Out-Null
    }
    if (Set-ContractField -Object $manifestRecord -FieldName 'handoff_artifact_path' -Value $resolvedHandoffPath -TreatBlankAsMissing) {
        $manifestUpdatedFields.Add('handoff_artifact_path') | Out-Null
    }
    if (Set-ContractField -Object $manifestRecord -FieldName 'handoff_artifact_error' -Value $handoffErrorValue.value) {
        $manifestUpdatedFields.Add('handoff_artifact_error') | Out-Null
    }
}

$summaryUpdated = $summaryUpdatedFields.Count -gt 0
$manifestUpdated = $manifestUpdatedFields.Count -gt 0
if ($summaryUpdated) {
    $summary | ConvertTo-Json -Depth 8 | Set-Content -Path $SummaryPath -Encoding Ascii
}
if ($manifestUpdated) {
    $manifestRecord | ConvertTo-Json -Depth 8 | Set-Content -Path $manifestPath -Encoding Ascii
}

$status = if (-not $manifestExists) {
    if ($summaryUpdated) { 'summary-updated-manifest-missing' } else { 'manifest-missing' }
} elseif (-not $manifestReadable) {
    if ($summaryUpdated) { 'summary-updated-manifest-unreadable' } else { 'manifest-unreadable' }
} elseif ($summaryUpdated -or $manifestUpdated) {
    'updated'
} else {
    'noop'
}

$recommendedCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$recommendedGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
$broaderRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$reason = if ($status -eq 'updated') {
    'The saved issue #3 summary and manifest now both advertise the refresh and handoff runner-output contract directly, so later helpers no longer need to infer those top-level fields from partial pointer recovery alone.'
} elseif ($status -eq 'summary-updated-manifest-missing') {
    'The saved summary was repaired with the direct runner-output contract, but the manifest file is still missing and must be regenerated by a fresh recommended-validation replay.'
} elseif ($status -eq 'summary-updated-manifest-unreadable') {
    'The saved summary was repaired with the direct runner-output contract, but the manifest could not be read cleanly and still needs regeneration.'
} elseif ($status -eq 'manifest-missing') {
    'No saved manifest was available to repair, so the broader runner still needs to regenerate the missing manifest output.'
} elseif ($status -eq 'manifest-unreadable') {
    'The saved manifest exists but could not be read cleanly, so the broader runner still needs to regenerate it before the full direct contract can be trusted.'
} else {
    'The saved issue #3 summary and manifest already expose the direct refresh and handoff runner-output fields, so there was nothing left for this helper to repair.'
}
$nextFocus = if ($status -eq 'updated' -or $status -eq 'noop') {
    'Reopen the runner-output wiring helper and confirm the current saved outputs now report the full direct contract before widening back out to later refresh or handoff helpers.'
} else {
    'Regenerate the broader recommended-validation outputs first, then rerun this repair helper only if the runner still leaves a contract gap.'
}

$report = [ordered]@{
    issue = 'Google issue #3 runner output contract repair'
    purpose = 'Repair missing top-level refresh and handoff path and error fields in the saved issue #3 recommended-validation summary and manifest outputs.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_readable = [bool]$manifestReadable
    manifest_artifact_error = $manifestError
    artifact_path = $ArtifactPath
    status = $status
    summary_updated = [bool]$summaryUpdated
    manifest_updated = [bool]$manifestUpdated
    summary_updated_fields = @($summaryUpdatedFields)
    manifest_updated_fields = @($manifestUpdatedFields)
    resolved_refresh_artifact_path = $resolvedRefreshPath
    refresh_path_value_source = if ($refreshConfigured) { $refreshConfigured.source } else { 'fallback-path' }
    refresh_error_value_source = $refreshErrorValue.source
    resolved_handoff_artifact_path = $resolvedHandoffPath
    handoff_path_value_source = if ($handoffConfigured) { $handoffConfigured.source } else { 'fallback-path' }
    handoff_error_value_source = $handoffErrorValue.source
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    broader_runner_command = $broaderRunnerCommand
    reason = $reason
    next_focus = $nextFocus
}

$report | ConvertTo-Json -Depth 6 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 runner output contract repair'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
Write-Host ("Manifest readable: {0}" -f $report.manifest_artifact_readable)
Write-Host ("Report:    {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary updated:  {0}" -f $report.summary_updated)
Write-Host ("Manifest updated: {0}" -f $report.manifest_updated)
Write-Host ("Refresh path: {0}" -f $report.resolved_refresh_artifact_path)
Write-Host ("Refresh source: {0}" -f $report.refresh_path_value_source)
Write-Host ("Handoff path: {0}" -f $report.resolved_handoff_artifact_path)
Write-Host ("Handoff source: {0}" -f $report.handoff_path_value_source)
if ($report.summary_updated_fields.Count -gt 0) {
    Write-Host ("Summary fields:  {0}" -f ($report.summary_updated_fields -join ', '))
}
if ($report.manifest_updated_fields.Count -gt 0) {
    Write-Host ("Manifest fields: {0}" -f ($report.manifest_updated_fields -join ', '))
}
if ($report.manifest_artifact_error) {
    Write-Host ("Manifest error: {0}" -f $report.manifest_artifact_error)
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Verify: {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
Write-Host ("Runner: {0}" -f $report.broader_runner_command)
