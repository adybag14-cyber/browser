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

function Get-PreferredValueRecord {
    param(
        [object]$Primary,
        [object]$Secondary,
        [Parameter(Mandatory = $true)]
        [string]$FieldName,
        [switch]$TreatBlankAsMissing
    )

    $primaryValue = Get-OptionalPropertyValue -Object $Primary -Name $FieldName
    if ($null -ne $primaryValue) {
        if (-not $TreatBlankAsMissing -or -not [string]::IsNullOrWhiteSpace([string]$primaryValue)) {
            return [pscustomobject]@{
                value = $primaryValue
                source = 'summary'
            }
        }
    }

    $secondaryValue = Get-OptionalPropertyValue -Object $Secondary -Name $FieldName
    if ($null -ne $secondaryValue) {
        if (-not $TreatBlankAsMissing -or -not [string]::IsNullOrWhiteSpace([string]$secondaryValue)) {
            return [pscustomobject]@{
                value = $secondaryValue
                source = 'manifest'
            }
        }
    }

    return $null
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

function Resolve-FirstFailedPhasePrimaryJsonArtifactPath {
    param(
        [object]$Summary,
        [object]$Manifest
    )

    $manifestValue = Get-OptionalPropertyValue -Object $Manifest -Name 'first_failed_phase_primary_json_artifact_path'
    if (-not [string]::IsNullOrWhiteSpace($manifestValue)) {
        return [pscustomobject]@{
            value = $manifestValue
            source = 'manifest'
        }
    }

    $summaryValue = Get-OptionalPropertyValue -Object $Summary -Name 'first_failed_phase_primary_json_artifact_path'
    if (-not [string]::IsNullOrWhiteSpace($summaryValue)) {
        return [pscustomobject]@{
            value = $summaryValue
            source = 'summary'
        }
    }

    $firstFailedPhase = Get-OptionalPropertyValue -Object $Summary -Name 'first_failed_phase'
    if ([string]::IsNullOrWhiteSpace($firstFailedPhase)) {
        return $null
    }

    foreach ($phaseResult in @(Get-OptionalPropertyValue -Object $Summary -Name 'phase_results')) {
        if ($phaseResult -and $phaseResult.name -eq $firstFailedPhase) {
            $phaseArtifact = Get-OptionalPropertyValue -Object $phaseResult -Name 'primary_json_artifact_path'
            if (-not [string]::IsNullOrWhiteSpace($phaseArtifact)) {
                return [pscustomobject]@{
                    value = $phaseArtifact
                    source = 'summary.phase_results'
                }
            }
        }
    }

    return $null
}

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json"
}
if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    throw "Issue #3 recommended validation summary not found: $SummaryPath"
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$artifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
if ([string]::IsNullOrWhiteSpace($artifactRoot)) {
    $artifactRoot = Split-Path -Parent $SummaryPath
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-validation-manifest-contract-repair.json'
}

$manifestConfigured = Get-PreferredValueRecord -Primary $summary -Secondary $null -FieldName 'manifest_artifact_path' -TreatBlankAsMissing
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

$resolvedGuidePath = Resolve-ArtifactCandidatePath -ConfiguredPath $(Get-PreferredValueRecord -Primary $summary -Secondary $manifestRecord -FieldName 'guide_artifact_path' -TreatBlankAsMissing | ForEach-Object { $_.value }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-guide.json'
$resolvedBoundaryPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(Get-PreferredValueRecord -Primary $summary -Secondary $manifestRecord -FieldName 'boundary_artifact_path' -TreatBlankAsMissing | ForEach-Object { $_.value }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-phase-boundary.json'
$resolvedBundlePath = Resolve-ArtifactCandidatePath -ConfiguredPath $(Get-PreferredValueRecord -Primary $summary -Secondary $manifestRecord -FieldName 'artifact_bundle_path' -TreatBlankAsMissing | ForEach-Object { $_.value }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json'
$resolvedHandoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(Get-PreferredValueRecord -Primary $summary -Secondary $manifestRecord -FieldName 'handoff_artifact_path' -TreatBlankAsMissing | ForEach-Object { $_.value }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
$resolvedRefreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(Get-PreferredValueRecord -Primary $summary -Secondary $manifestRecord -FieldName 'refresh_chain_artifact_path' -TreatBlankAsMissing | ForEach-Object { $_.value }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$resolvedSurfaceCheckPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(Get-PreferredValueRecord -Primary $summary -Secondary $manifestRecord -FieldName 'surface_check_artifact_path' -TreatBlankAsMissing | ForEach-Object { $_.value }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-surface.json'
$resolvedPhaseArtifactRoot = Get-PreferredValueRecord -Primary $summary -Secondary $manifestRecord -FieldName 'phase_artifact_root' -TreatBlankAsMissing | ForEach-Object { $_.value }
if ([string]::IsNullOrWhiteSpace($resolvedPhaseArtifactRoot)) {
    $resolvedPhaseArtifactRoot = Join-Path $artifactRoot 'google-issue3-recommended-validation-phases'
}

$artifactBundleErrorRecord = Get-PreferredValueRecord -Primary $summary -Secondary $manifestRecord -FieldName 'artifact_bundle_error'
$handoffErrorRecord = Get-PreferredValueRecord -Primary $summary -Secondary $manifestRecord -FieldName 'handoff_artifact_error'
$refreshErrorRecord = Get-PreferredValueRecord -Primary $summary -Secondary $manifestRecord -FieldName 'refresh_chain_artifact_error'
$manualReplayCommandRecord = Get-PreferredValueRecord -Primary $summary -Secondary $manifestRecord -FieldName 'manual_fixture_replay_command' -TreatBlankAsMissing
$manualReplayAvailableRecord = Get-PreferredValueRecord -Primary $summary -Secondary $manifestRecord -FieldName 'manual_fixture_replay_available'
$firstFailedPhasePrimaryJsonArtifactRecord = Resolve-FirstFailedPhasePrimaryJsonArtifactPath -Summary $summary -Manifest $manifestRecord

$manualReplayAvailableValue = if ($manualReplayAvailableRecord) {
    [bool]$manualReplayAvailableRecord.value
} elseif ($manualReplayCommandRecord) {
    $true
} else {
    $false
}

$manifestUpdatedFields = New-Object System.Collections.Generic.List[string]
if ($manifestReadable) {
    if (Set-ContractField -Object $manifestRecord -FieldName 'artifact_root' -Value $artifactRoot -TreatBlankAsMissing) {
        $manifestUpdatedFields.Add('artifact_root') | Out-Null
    }
    if (Set-ContractField -Object $manifestRecord -FieldName 'summary_path' -Value $SummaryPath -TreatBlankAsMissing) {
        $manifestUpdatedFields.Add('summary_path') | Out-Null
    }
    if (Set-ContractField -Object $manifestRecord -FieldName 'guide_artifact_path' -Value $resolvedGuidePath -TreatBlankAsMissing) {
        $manifestUpdatedFields.Add('guide_artifact_path') | Out-Null
    }
    if (Set-ContractField -Object $manifestRecord -FieldName 'boundary_artifact_path' -Value $resolvedBoundaryPath -TreatBlankAsMissing) {
        $manifestUpdatedFields.Add('boundary_artifact_path') | Out-Null
    }
    if (Set-ContractField -Object $manifestRecord -FieldName 'artifact_bundle_path' -Value $resolvedBundlePath -TreatBlankAsMissing) {
        $manifestUpdatedFields.Add('artifact_bundle_path') | Out-Null
    }
    if (Set-ContractField -Object $manifestRecord -FieldName 'artifact_bundle_error' -Value $(if ($artifactBundleErrorRecord) { $artifactBundleErrorRecord.value } else { $null })) {
        $manifestUpdatedFields.Add('artifact_bundle_error') | Out-Null
    }
    if (Set-ContractField -Object $manifestRecord -FieldName 'handoff_artifact_path' -Value $resolvedHandoffPath -TreatBlankAsMissing) {
        $manifestUpdatedFields.Add('handoff_artifact_path') | Out-Null
    }
    if (Set-ContractField -Object $manifestRecord -FieldName 'handoff_artifact_error' -Value $(if ($handoffErrorRecord) { $handoffErrorRecord.value } else { $null })) {
        $manifestUpdatedFields.Add('handoff_artifact_error') | Out-Null
    }
    if (Set-ContractField -Object $manifestRecord -FieldName 'refresh_chain_artifact_path' -Value $resolvedRefreshPath -TreatBlankAsMissing) {
        $manifestUpdatedFields.Add('refresh_chain_artifact_path') | Out-Null
    }
    if (Set-ContractField -Object $manifestRecord -FieldName 'refresh_chain_artifact_error' -Value $(if ($refreshErrorRecord) { $refreshErrorRecord.value } else { $null })) {
        $manifestUpdatedFields.Add('refresh_chain_artifact_error') | Out-Null
    }
    if (Set-ContractField -Object $manifestRecord -FieldName 'surface_check_artifact_path' -Value $resolvedSurfaceCheckPath -TreatBlankAsMissing) {
        $manifestUpdatedFields.Add('surface_check_artifact_path') | Out-Null
    }
    if (Set-ContractField -Object $manifestRecord -FieldName 'phase_artifact_root' -Value $resolvedPhaseArtifactRoot -TreatBlankAsMissing) {
        $manifestUpdatedFields.Add('phase_artifact_root') | Out-Null
    }
    if ($firstFailedPhasePrimaryJsonArtifactRecord) {
        if (Set-ContractField -Object $manifestRecord -FieldName 'first_failed_phase_primary_json_artifact_path' -Value $firstFailedPhasePrimaryJsonArtifactRecord.value -TreatBlankAsMissing) {
            $manifestUpdatedFields.Add('first_failed_phase_primary_json_artifact_path') | Out-Null
        }
    }
    if ($manualReplayCommandRecord) {
        if (Set-ContractField -Object $manifestRecord -FieldName 'manual_fixture_replay_command' -Value $manualReplayCommandRecord.value -TreatBlankAsMissing) {
            $manifestUpdatedFields.Add('manual_fixture_replay_command') | Out-Null
        }
    }
    if (Set-ContractField -Object $manifestRecord -FieldName 'manual_fixture_replay_available' -Value $manualReplayAvailableValue) {
        $manifestUpdatedFields.Add('manual_fixture_replay_available') | Out-Null
    }
}

if ($manifestReadable -and $manifestUpdatedFields.Count -gt 0) {
    $manifestRecord | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding Ascii
}

$manifestSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest_safe.ps1'
$manifestGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest.ps1'
$broaderRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

$status = if (-not $manifestExists) {
    'manifest-missing'
} elseif (-not $manifestReadable) {
    'manifest-unreadable'
} elseif ($manifestUpdatedFields.Count -gt 0) {
    'updated'
} else {
    'noop'
}

$reason = if ($status -eq 'updated') {
    'The saved issue #3 manifest now carries the stricter guide-facing contract fields that the manifest helper expects under strict mode, so later replays can reuse the saved outputs without falling back to the broader runner for this missing metadata.'
} elseif ($status -eq 'noop') {
    'The saved issue #3 manifest already exposed the stricter guide-facing contract fields, so there was nothing left for this repair helper to backfill.'
} elseif ($status -eq 'manifest-missing') {
    'No saved manifest was available to repair, so the broader recommended-validation runner still needs to regenerate that artifact before the manifest guide can be trusted.'
} else {
    'The saved manifest exists but could not be read cleanly, so the broader recommended-validation runner still needs to regenerate it before the manifest guide can be trusted.'
}

$nextFocus = if ($status -eq 'updated' -or $status -eq 'noop') {
    'Reopen the safe manifest helper first, then return to the manifest guide once it reports safe-to-run-manifest-guide for the current summary.'
} else {
    'Regenerate the saved recommended-validation outputs with the broader runner, then rerun this repair helper only if the manifest guide contract is still incomplete.'
}

$report = [ordered]@{
    issue = 'Google issue #3 validation manifest contract repair'
    purpose = 'Backfill missing manifest-guide contract fields into the saved issue #3 manifest so strict-mode manifest replay can reuse the current outputs without re-running the broader validation runner.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_readable = [bool]$manifestReadable
    manifest_artifact_error = $manifestError
    artifact_path = $ArtifactPath
    status = $status
    manifest_updated = [bool]($manifestUpdatedFields.Count -gt 0)
    manifest_updated_fields = @($manifestUpdatedFields)
    artifact_root = $artifactRoot
    guide_artifact_path = $resolvedGuidePath
    boundary_artifact_path = $resolvedBoundaryPath
    artifact_bundle_path = $resolvedBundlePath
    handoff_artifact_path = $resolvedHandoffPath
    refresh_chain_artifact_path = $resolvedRefreshPath
    surface_check_artifact_path = $resolvedSurfaceCheckPath
    phase_artifact_root = $resolvedPhaseArtifactRoot
    artifact_bundle_error_source = if ($artifactBundleErrorRecord) { $artifactBundleErrorRecord.source } else { 'default-null' }
    handoff_error_source = if ($handoffErrorRecord) { $handoffErrorRecord.source } else { 'default-null' }
    refresh_error_source = if ($refreshErrorRecord) { $refreshErrorRecord.source } else { 'default-null' }
    manual_fixture_replay_command_source = if ($manualReplayCommandRecord) { $manualReplayCommandRecord.source } else { 'default-null' }
    manual_fixture_replay_available_value = [bool]$manualReplayAvailableValue
    first_failed_phase_primary_json_artifact_path_source = if ($firstFailedPhasePrimaryJsonArtifactRecord) { $firstFailedPhasePrimaryJsonArtifactRecord.source } else { 'default-null' }
    recommended_command = if ($status -eq 'manifest-missing' -or $status -eq 'manifest-unreadable') { $broaderRunnerCommand } else { $manifestSafeCommand }
    recommended_guide_command = if ($status -eq 'manifest-missing' -or $status -eq 'manifest-unreadable') { $manifestSafeCommand } else { $manifestGuideCommand }
    broader_runner_command = $broaderRunnerCommand
    manifest_safe_command = $manifestSafeCommand
    manifest_guide_command = $manifestGuideCommand
    reason = $reason
    next_focus = $nextFocus
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host 'Google issue #3 validation manifest contract repair'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
Write-Host ("Manifest readable: {0}" -f $report.manifest_artifact_readable)
if ($report.manifest_artifact_error) {
    Write-Host ("Manifest error: {0}" -f $report.manifest_artifact_error)
}
Write-Host ("Report:    {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
if ($report.manifest_updated_fields.Count -gt 0) {
    Write-Host 'Manifest fields updated:'
    foreach ($fieldName in $report.manifest_updated_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
Write-Host ("Guide path: {0}" -f $report.guide_artifact_path)
Write-Host ("Boundary path: {0}" -f $report.boundary_artifact_path)
Write-Host ("Bundle path: {0}" -f $report.artifact_bundle_path)
Write-Host ("Handoff path: {0}" -f $report.handoff_artifact_path)
Write-Host ("Refresh path: {0}" -f $report.refresh_chain_artifact_path)
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
