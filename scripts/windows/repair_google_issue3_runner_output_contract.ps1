[CmdletBinding()]
param(
    [string]$SummaryPath,
    [string]$ManifestPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-RepoRoot([string]$StartPath) {
    if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
        return $env:LIGHTPANDA_REPO_ROOT
    }

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor 'build.zig')) {
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
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Artifact not found: $Path"
    }

    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    } catch {
        throw "Artifact is not valid JSON: $Path"
    }
}

function Test-HasProperty {
    param(
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [bool]($Object -and $Object.PSObject.Properties[$Name])
}

function Resolve-PreferredPathValue {
    param(
        [object]$Summary,
        [object]$Manifest,
        [Parameter(Mandatory = $true)]
        [string]$FieldName,
        [Parameter(Mandatory = $true)]
        [string]$ArtifactRoot,
        [Parameter(Mandatory = $true)]
        [string]$FallbackName
    )

    if ((Test-HasProperty -Object $Summary -Name $FieldName) -and -not [string]::IsNullOrWhiteSpace($Summary.$FieldName)) {
        return [pscustomobject]@{
            value = $Summary.$FieldName
            source = 'summary'
        }
    }

    if ((Test-HasProperty -Object $Manifest -Name $FieldName) -and -not [string]::IsNullOrWhiteSpace($Manifest.$FieldName)) {
        return [pscustomobject]@{
            value = $Manifest.$FieldName
            source = 'manifest'
        }
    }

    return [pscustomobject]@{
        value = (Resolve-ArtifactCandidatePath -ConfiguredPath $null -ArtifactRoot $ArtifactRoot -FallbackName $FallbackName)
        source = 'fallback-path'
    }
}

function Resolve-PreferredErrorValue {
    param(
        [object]$Summary,
        [object]$Manifest,
        [Parameter(Mandatory = $true)]
        [string]$FieldName
    )

    if (Test-HasProperty -Object $Summary -Name $FieldName) {
        return [pscustomobject]@{
            value = $Summary.$FieldName
            source = 'summary'
        }
    }

    if (Test-HasProperty -Object $Manifest -Name $FieldName) {
        return [pscustomobject]@{
            value = $Manifest.$FieldName
            source = 'manifest'
        }
    }

    return [pscustomobject]@{
        value = $null
        source = 'default-null'
    }
}

function Set-ArtifactField {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Artifact,
        [Parameter(Mandatory = $true)]
        [string]$FieldName,
        $Value,
        [Parameter(Mandatory = $true)]
        [string]$TargetName,
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[object]]$ChangeLog
    )

    $hadField = Test-HasProperty -Object $Artifact -Name $FieldName
    $previousValue = if ($hadField) { $Artifact.$FieldName } else { $null }
    $changed = (-not $hadField) -or ($previousValue -ne $Value)

    if (-not $hadField) {
        $Artifact | Add-Member -NotePropertyName $FieldName -NotePropertyValue $Value
    } else {
        $Artifact.$FieldName = $Value
    }

    $ChangeLog.Add([pscustomobject]@{
        target = $TargetName
        field = $FieldName
        changed = [bool]$changed
        previous_value = $previousValue
        new_value = $Value
    }) | Out-Null
}

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json'
}

$summary = Read-ArtifactJson -Path $SummaryPath
$artifactRoot = if ((Test-HasProperty -Object $summary -Name 'artifact_root') -and -not [string]::IsNullOrWhiteSpace($summary.artifact_root)) {
    $summary.artifact_root
} else {
    Split-Path -Parent $SummaryPath
}

if (-not $ManifestPath) {
    $ManifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ((Test-HasProperty -Object $summary -Name 'manifest_artifact_path') -and -not [string]::IsNullOrWhiteSpace($summary.manifest_artifact_path)) { $summary.manifest_artifact_path } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
}

$manifest = Read-ArtifactJson -Path $ManifestPath
$changeLog = [System.Collections.Generic.List[object]]::new()

$refreshPath = Resolve-PreferredPathValue -Summary $summary -Manifest $manifest -FieldName 'refresh_chain_artifact_path' -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$handoffPath = Resolve-PreferredPathValue -Summary $summary -Manifest $manifest -FieldName 'handoff_artifact_path' -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
$refreshError = Resolve-PreferredErrorValue -Summary $summary -Manifest $manifest -FieldName 'refresh_chain_artifact_error'
$handoffError = Resolve-PreferredErrorValue -Summary $summary -Manifest $manifest -FieldName 'handoff_artifact_error'

Set-ArtifactField -Artifact $summary -FieldName 'refresh_chain_artifact_path' -Value $refreshPath.value -TargetName 'summary' -ChangeLog $changeLog
Set-ArtifactField -Artifact $summary -FieldName 'refresh_chain_artifact_error' -Value $refreshError.value -TargetName 'summary' -ChangeLog $changeLog
Set-ArtifactField -Artifact $summary -FieldName 'handoff_artifact_path' -Value $handoffPath.value -TargetName 'summary' -ChangeLog $changeLog
Set-ArtifactField -Artifact $summary -FieldName 'handoff_artifact_error' -Value $handoffError.value -TargetName 'summary' -ChangeLog $changeLog

Set-ArtifactField -Artifact $manifest -FieldName 'refresh_chain_artifact_path' -Value $refreshPath.value -TargetName 'manifest' -ChangeLog $changeLog
Set-ArtifactField -Artifact $manifest -FieldName 'refresh_chain_artifact_error' -Value $refreshError.value -TargetName 'manifest' -ChangeLog $changeLog
Set-ArtifactField -Artifact $manifest -FieldName 'handoff_artifact_path' -Value $handoffPath.value -TargetName 'manifest' -ChangeLog $changeLog
Set-ArtifactField -Artifact $manifest -FieldName 'handoff_artifact_error' -Value $handoffError.value -TargetName 'manifest' -ChangeLog $changeLog

$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $SummaryPath -Encoding Ascii
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ManifestPath -Encoding Ascii

$changedFields = @($changeLog | Where-Object { $_.changed })
$report = [ordered]@{
    issue = 'Google issue #3 runner output contract repair'
    purpose = 'Repair the saved recommended-validation summary and manifest so both artifacts expose refresh and handoff path and error fields directly.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    manifest_artifact_path = $ManifestPath
    resolved_refresh_artifact_path = $refreshPath.value
    resolved_handoff_artifact_path = $handoffPath.value
    refresh_path_value_source = $refreshPath.source
    handoff_path_value_source = $handoffPath.source
    refresh_error_value_source = $refreshError.source
    handoff_error_value_source = $handoffError.source
    changed_field_count = $changedFields.Count
    changed_fields = @($changedFields)
    verify_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
    status = if ($changedFields.Count -gt 0) { 'repaired' } else { 'already-direct' }
    reason = if ($changedFields.Count -gt 0) {
        'The saved runner outputs were normalized so later issue #3 helpers can rely on direct refresh and handoff fields instead of inferring them indirectly.'
    } else {
        'The saved runner outputs already exposed the direct refresh and handoff fields, so no repair was needed.'
    }
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 runner output contract repair'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Refresh:   {0}" -f $report.resolved_refresh_artifact_path)
Write-Host ("Refresh source: {0}" -f $report.refresh_path_value_source)
Write-Host ("Handoff:   {0}" -f $report.resolved_handoff_artifact_path)
Write-Host ("Handoff source: {0}" -f $report.handoff_path_value_source)
Write-Host ("Status:    {0}" -f $report.status)
if ($report.changed_field_count -gt 0) {
    Write-Host 'Changed fields:'
    foreach ($field in $report.changed_fields) {
        Write-Host ("- {0}.{1}" -f $field.target, $field.field)
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Verify: {0}" -f $report.verify_command)
