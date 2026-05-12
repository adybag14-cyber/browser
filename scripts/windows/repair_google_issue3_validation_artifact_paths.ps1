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

    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    } catch {
        return $null
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

function Get-ConfiguredValue {
    param(
        [object]$Primary,
        [object]$Fallback,
        [Parameter(Mandatory = $true)]
        [string]$FieldName
    )

    if ((Test-HasProperty -Object $Primary -Name $FieldName) -and -not [string]::IsNullOrWhiteSpace($Primary.$FieldName)) {
        return $Primary.$FieldName
    }

    if ((Test-HasProperty -Object $Fallback -Name $FieldName) -and -not [string]::IsNullOrWhiteSpace($Fallback.$FieldName)) {
        return $Fallback.$FieldName
    }

    return $null
}

function Set-MissingArtifactPathField {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Record,
        [Parameter(Mandatory = $true)]
        [string]$FieldName,
        [Parameter(Mandatory = $true)]
        [string]$ResolvedPath,
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$ChangedFields
    )

    if ((Test-HasProperty -Object $Record -Name $FieldName) -and -not [string]::IsNullOrWhiteSpace($Record.$FieldName)) {
        return
    }

    if (Test-HasProperty -Object $Record -Name $FieldName) {
        $Record.$FieldName = $ResolvedPath
    } else {
        $Record | Add-Member -NotePropertyName $FieldName -NotePropertyValue $ResolvedPath
    }

    $ChangedFields.Add($FieldName) | Out-Null
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

$configuredManifestPath = Get-ConfiguredValue -Primary $summary -Fallback $null -FieldName 'manifest_artifact_path'
$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredManifestPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
$manifest = Read-ArtifactJson $manifestPath
$manifestReadable = [bool]$manifest

$fieldSpecs = @(
    [pscustomobject]@{ FieldName = 'manifest_artifact_path'; FallbackName = 'google-issue3-recommended-validation-manifest.json'; IncludeInManifest = $false }
    [pscustomobject]@{ FieldName = 'guide_artifact_path'; FallbackName = 'google-issue3-recommended-validation-guide.json'; IncludeInManifest = $true }
    [pscustomobject]@{ FieldName = 'boundary_artifact_path'; FallbackName = 'google-issue3-phase-boundary.json'; IncludeInManifest = $true }
    [pscustomobject]@{ FieldName = 'artifact_bundle_path'; FallbackName = 'google-issue3-validation-artifact-bundle.json'; IncludeInManifest = $true }
    [pscustomobject]@{ FieldName = 'handoff_artifact_path'; FallbackName = 'google-issue3-validation-handoff.json'; IncludeInManifest = $true }
    [pscustomobject]@{ FieldName = 'refresh_chain_artifact_path'; FallbackName = 'google-issue3-validation-handoff-chain-refresh.json'; IncludeInManifest = $true }
)

$resolvedPaths = [ordered]@{}
$summaryChangedFields = [System.Collections.Generic.List[string]]::new()
$manifestChangedFields = [System.Collections.Generic.List[string]]::new()

foreach ($spec in $fieldSpecs) {
    $resolvedPath = Resolve-ArtifactCandidatePath -ConfiguredPath (Get-ConfiguredValue -Primary $summary -Fallback $manifest -FieldName $spec.FieldName) -ArtifactRoot $artifactRoot -FallbackName $spec.FallbackName
    $resolvedPaths[$spec.FieldName] = $resolvedPath

    Set-MissingArtifactPathField -Record $summary -FieldName $spec.FieldName -ResolvedPath $resolvedPath -ChangedFields $summaryChangedFields
    if ($manifestReadable -and $spec.IncludeInManifest) {
        Set-MissingArtifactPathField -Record $manifest -FieldName $spec.FieldName -ResolvedPath $resolvedPath -ChangedFields $manifestChangedFields
    }
}

$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $SummaryPath -Encoding Ascii
if ($manifestReadable) {
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding Ascii
}

$status = $null
$reason = $null
$recommendedCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$recommendedGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe.ps1'
$nextFocus = 'Re-run the handoff helper against the repaired summary and manifest so the issue #3 helper chain can trust the resolved artifact paths.'
if (-not $manifestExists) {
    $status = 'summary-repaired-manifest-missing'
    $reason = 'The summary was normalized, but the manifest file was still missing, so only the summary artifact-path contract could be repaired in this pass.'
} elseif (-not $manifestReadable) {
    $status = 'summary-repaired-manifest-unreadable'
    $reason = 'The summary was normalized, but the manifest file could not be read cleanly, so the repair stopped short of manifest updates.'
} elseif ($summaryChangedFields.Count -eq 0 -and $manifestChangedFields.Count -eq 0) {
    $status = 'already-normalized'
    $reason = 'The saved issue #3 summary and manifest already exposed the expected artifact-path fields.'
} elseif ($summaryChangedFields.Count -gt 0 -and $manifestChangedFields.Count -gt 0) {
    $status = 'summary-and-manifest-repaired'
    $reason = 'The repair helper backfilled missing artifact-path fields in both the saved summary and manifest.'
} elseif ($summaryChangedFields.Count -gt 0) {
    $status = 'summary-repaired'
    $reason = 'The repair helper backfilled missing artifact-path fields in the saved summary.'
} else {
    $status = 'manifest-repaired'
    $reason = 'The repair helper backfilled missing artifact-path fields in the saved manifest.'
}

$report = [ordered]@{
    issue = 'Google issue #3 validation artifact path repair'
    purpose = 'Backfill missing summary and manifest artifact-path fields so the issue #3 helper chain can reopen older saved outputs without strict-mode path failures.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_readable = [bool]$manifestReadable
    resolved_paths = $resolvedPaths
    summary_changed_fields = @($summaryChangedFields)
    manifest_changed_fields = @($manifestChangedFields)
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_focus = $nextFocus
    status = $status
    reason = $reason
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 validation artifact path repair'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
Write-Host ("Manifest readable: {0}" -f $report.manifest_artifact_readable)
Write-Host ("Status:    {0}" -f $report.status)
foreach ($entry in $resolvedPaths.GetEnumerator()) {
    Write-Host ("{0}: {1}" -f $entry.Key, $entry.Value)
}
if ($report.summary_changed_fields.Count -gt 0) {
    Write-Host 'Summary fields added:'
    foreach ($fieldName in $report.summary_changed_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
if ($report.manifest_changed_fields.Count -gt 0) {
    Write-Host 'Manifest fields added:'
    foreach ($fieldName in $report.manifest_changed_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
