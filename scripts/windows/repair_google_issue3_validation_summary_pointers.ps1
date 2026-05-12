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

function Resolve-PointerRepair {
    param(
        [string]$CurrentPath,
        [string]$ManifestPath,
        [string]$FallbackPath
    )

    if (-not [string]::IsNullOrWhiteSpace($CurrentPath)) {
        return [pscustomobject]@{
            current_path = $CurrentPath
            resolved_path = $CurrentPath
            source = 'summary'
            repaired = $false
            exists = Test-Path -LiteralPath $CurrentPath -PathType Leaf
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($ManifestPath)) {
        return [pscustomobject]@{
            current_path = $CurrentPath
            resolved_path = $ManifestPath
            source = 'manifest'
            repaired = $true
            exists = Test-Path -LiteralPath $ManifestPath -PathType Leaf
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($FallbackPath) -and (Test-Path -LiteralPath $FallbackPath -PathType Leaf)) {
        return [pscustomobject]@{
            current_path = $CurrentPath
            resolved_path = $FallbackPath
            source = 'fallback'
            repaired = $true
            exists = $true
        }
    }

    return [pscustomobject]@{
        current_path = $CurrentPath
        resolved_path = $null
        source = 'missing'
        repaired = $false
        exists = $false
    }
}

function Copy-ErrorFieldFromManifest {
    param(
        [Parameter(Mandatory = $true)]
        $Summary,
        [Parameter(Mandatory = $true)]
        [string]$FieldName,
        $ManifestValue
    )

    $currentValue = $Summary.PSObject.Properties[$FieldName]
    if ($currentValue -and -not [string]::IsNullOrWhiteSpace([string]$currentValue.Value)) {
        return $false
    }

    if ([string]::IsNullOrWhiteSpace([string]$ManifestValue)) {
        return $false
    }

    $Summary | Add-Member -NotePropertyName $FieldName -NotePropertyValue $ManifestValue -Force
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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-summary-pointer-repair.json'
}

$manifestConfiguredPath = Get-OptionalPropertyValue -Object $summary -Name 'manifest_artifact_path'
$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $manifestConfiguredPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
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

$handoffFallbackPath = Join-Path $artifactRoot 'google-issue3-validation-handoff.json'
$refreshFallbackPath = Join-Path $artifactRoot 'google-issue3-validation-handoff-chain-refresh.json'

$summaryHandoffPath = Get-OptionalPropertyValue -Object $summary -Name 'handoff_artifact_path'
$summaryRefreshPath = Get-OptionalPropertyValue -Object $summary -Name 'refresh_chain_artifact_path'
$manifestHandoffPath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'handoff_artifact_path'
$manifestRefreshPath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'refresh_chain_artifact_path'
$manifestHandoffError = Get-OptionalPropertyValue -Object $manifestRecord -Name 'handoff_artifact_error'
$manifestRefreshError = Get-OptionalPropertyValue -Object $manifestRecord -Name 'refresh_chain_artifact_error'

$handoffRepair = Resolve-PointerRepair -CurrentPath $summaryHandoffPath -ManifestPath $manifestHandoffPath -FallbackPath $handoffFallbackPath
$refreshRepair = Resolve-PointerRepair -CurrentPath $summaryRefreshPath -ManifestPath $manifestRefreshPath -FallbackPath $refreshFallbackPath

$updatedFields = New-Object System.Collections.Generic.List[string]
$errorFieldRepairs = New-Object System.Collections.Generic.List[string]

if ($handoffRepair.repaired -and -not [string]::IsNullOrWhiteSpace($handoffRepair.resolved_path)) {
    $summary | Add-Member -NotePropertyName 'handoff_artifact_path' -NotePropertyValue $handoffRepair.resolved_path -Force
    $updatedFields.Add('handoff_artifact_path') | Out-Null
}
if ($refreshRepair.repaired -and -not [string]::IsNullOrWhiteSpace($refreshRepair.resolved_path)) {
    $summary | Add-Member -NotePropertyName 'refresh_chain_artifact_path' -NotePropertyValue $refreshRepair.resolved_path -Force
    $updatedFields.Add('refresh_chain_artifact_path') | Out-Null
}
if ($manifestRecord) {
    if (Copy-ErrorFieldFromManifest -Summary $summary -FieldName 'handoff_artifact_error' -ManifestValue $manifestHandoffError) {
        $errorFieldRepairs.Add('handoff_artifact_error') | Out-Null
    }
    if (Copy-ErrorFieldFromManifest -Summary $summary -FieldName 'refresh_chain_artifact_error' -ManifestValue $manifestRefreshError) {
        $errorFieldRepairs.Add('refresh_chain_artifact_error') | Out-Null
    }
}

$summaryUpdated = $updatedFields.Count -gt 0 -or $errorFieldRepairs.Count -gt 0
if ($summaryUpdated) {
    $summary | ConvertTo-Json -Depth 8 | Set-Content -Path $SummaryPath -Encoding Ascii
}

$status = if ($summaryUpdated) {
    'updated'
} elseif ($handoffRepair.source -eq 'missing' -or $refreshRepair.source -eq 'missing') {
    'missing-pointer-targets'
} else {
    'noop'
}

$handoffSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe.ps1'
$handoffCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$refreshStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
$artifactBundleCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1'
$recommendedCommand = if ($status -eq 'updated' -or $status -eq 'noop') {
    $handoffSafeCommand
} else {
    $refreshChainCommand
}
$recommendedGuideCommand = if ($status -eq 'updated' -or $status -eq 'noop') {
    $refreshStatusSafeCommand
} else {
    $artifactBundleCommand
}
$reason = if ($status -eq 'updated') {
    'The saved issue #3 summary was missing one or more helper-chain pointers, and this repair helper promoted the matching manifest-backed or fallback artifact paths into the summary so later helpers can trust explicit links again.'
} elseif ($status -eq 'noop') {
    'The saved issue #3 summary already recorded the helper-chain pointers or had nothing left to repair from the manifest and fallback artifacts.'
} else {
    'The saved issue #3 summary is still missing at least one helper-chain pointer, and no matching manifest-backed or fallback artifact could be promoted into the summary yet.'
}
$nextFocus = if ($status -eq 'updated' -or $status -eq 'noop') {
    'Reopen the safe handoff or safe refresh-status helper first, then use the raw helpers only after those safer checkpoints say the stricter follow-up is appropriate.'
} else {
    'Regenerate or refresh the helper chain first so the missing handoff or refresh artifact exists before trying to repair the summary pointers again.'
}

$summaryHandoffPathAfter = Get-OptionalPropertyValue -Object $summary -Name 'handoff_artifact_path'
$summaryRefreshPathAfter = Get-OptionalPropertyValue -Object $summary -Name 'refresh_chain_artifact_path'

$report = [ordered]@{
    issue = 'Google issue #3 validation summary pointer repair'
    purpose = 'Repair missing handoff and refresh pointer fields in the saved issue #3 recommended-validation summary by promoting the current manifest-backed or fallback artifact paths into the summary itself.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_error = $manifestError
    status = $status
    summary_updated = [bool]$summaryUpdated
    updated_fields = @($updatedFields)
    repaired_error_fields = @($errorFieldRepairs)
    handoff_pointer_before = $handoffRepair.current_path
    handoff_pointer_after = $summaryHandoffPathAfter
    handoff_pointer_source = $handoffRepair.source
    handoff_pointer_exists = [bool]$handoffRepair.exists
    refresh_pointer_before = $refreshRepair.current_path
    refresh_pointer_after = $summaryRefreshPathAfter
    refresh_pointer_source = $refreshRepair.source
    refresh_pointer_exists = [bool]$refreshRepair.exists
    handoff_safe_command = $handoffSafeCommand
    handoff_command = $handoffCommand
    refresh_status_safe_command = $refreshStatusSafeCommand
    refresh_status_command = $refreshStatusCommand
    refresh_chain_command = $refreshChainCommand
    artifact_bundle_command = $artifactBundleCommand
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    reason = $reason
    next_focus = $nextFocus
  }

$report | ConvertTo-Json -Depth 6 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 validation summary pointer repair'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Report:    {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Updated:   {0}" -f $report.summary_updated)
Write-Host ("Handoff before: {0}" -f $(if ($report.handoff_pointer_before) { $report.handoff_pointer_before } else { '<missing>' }))
Write-Host ("Handoff after:  {0}" -f $(if ($report.handoff_pointer_after) { $report.handoff_pointer_after } else { '<missing>' }))
Write-Host ("Handoff source: {0}" -f $report.handoff_pointer_source)
Write-Host ("Refresh before: {0}" -f $(if ($report.refresh_pointer_before) { $report.refresh_pointer_before } else { '<missing>' }))
Write-Host ("Refresh after:  {0}" -f $(if ($report.refresh_pointer_after) { $report.refresh_pointer_after } else { '<missing>' }))
Write-Host ("Refresh source: {0}" -f $report.refresh_pointer_source)
if ($report.updated_fields.Count -gt 0) {
    Write-Host ("Updated fields: {0}" -f ($report.updated_fields -join ', '))
}
if ($report.repaired_error_fields.Count -gt 0) {
    Write-Host ("Error fields:   {0}" -f ($report.repaired_error_fields -join ', '))
}
if ($report.manifest_artifact_error) {
    Write-Host ("Manifest error: {0}" -f $report.manifest_artifact_error)
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
Write-Host ("Raw handoff: {0}" -f $report.handoff_command)
Write-Host ("Raw refresh: {0}" -f $report.refresh_status_command)
