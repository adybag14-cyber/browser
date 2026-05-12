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
        return [pscustomobject]@{
            value = $Primary.$FieldName
            source = 'summary'
        }
    }

    if ((Test-HasProperty -Object $Fallback -Name $FieldName) -and -not [string]::IsNullOrWhiteSpace($Fallback.$FieldName)) {
        return [pscustomobject]@{
            value = $Fallback.$FieldName
            source = 'manifest'
        }
    }

    return $null
}

function Get-ErrorValue {
    param(
        [object]$Primary,
        [object]$Fallback,
        [Parameter(Mandatory = $true)]
        [string]$FieldName
    )

    if (Test-HasProperty -Object $Primary -Name $FieldName) {
        return [pscustomobject]@{
            value = $Primary.$FieldName
            source = 'summary'
        }
    }

    if (Test-HasProperty -Object $Fallback -Name $FieldName) {
        return [pscustomobject]@{
            value = $Fallback.$FieldName
            source = 'manifest'
        }
    }

    return [pscustomobject]@{
        value = $null
        source = 'default-null'
    }
}

function New-PatchFieldRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FieldName,
        [Parameter(Mandatory = $true)]
        [object]$CurrentObject,
        [Parameter(Mandatory = $true)]
        [string]$SuggestedValue,
        [Parameter(Mandatory = $true)]
        [string]$ValueSource,
        [Parameter(Mandatory = $true)]
        [bool]$Nullable
    )

    $isPresent = Test-HasProperty -Object $CurrentObject -Name $FieldName
    $currentValue = if ($isPresent) { $CurrentObject.$FieldName } else { $null }

    return [pscustomobject]@{
        field = $FieldName
        present = [bool]$isPresent
        current_value = $currentValue
        suggested_value = $SuggestedValue
        suggested_value_source = $ValueSource
        nullable = [bool]$Nullable
    }
}

function Convert-ToPowerShellLiteral {
    param([object]$Value)

    if ($null -eq $Value) {
        return '$null'
    }

    $escaped = ([string]$Value) -replace "'", "''"
    return "'$escaped'"
}

function New-PatchSnippetLine {
    param(
        [Parameter(Mandatory = $true)]
        [object]$FieldRecord
    )

    return ('        {0} = {1}' -f $FieldRecord.field, (Convert-ToPowerShellLiteral -Value $FieldRecord.suggested_value))
}

function Get-DirectFieldAssignmentCount {
    param(
        [string]$SourceText,
        [Parameter(Mandatory = $true)]
        [string]$AssignmentText
    )

    if ([string]::IsNullOrWhiteSpace($SourceText)) {
        return 0
    }

    return [regex]::Matches($SourceText, [regex]::Escape($AssignmentText)).Count
}

$repoRoot = Resolve-RepoRoot $PSScriptRoot
$runnerScriptPath = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation.ps1'
$runnerScriptExists = Test-Path -LiteralPath $runnerScriptPath -PathType Leaf
$runnerScriptSource = if ($runnerScriptExists) {
    Get-Content -LiteralPath $runnerScriptPath -Raw
} else {
    $null
}
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json"
}
if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    throw "Issue #3 recommended validation summary not found: $SummaryPath"
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$artifactRoot = if (-not [string]::IsNullOrWhiteSpace($summary.artifact_root)) {
    $summary.artifact_root
} else {
    Split-Path -Parent $SummaryPath
}

$manifestConfigured = Get-ConfiguredValue -Primary $summary -Fallback $null -FieldName 'manifest_artifact_path'
$manifestPath = if ($manifestConfigured) {
    Resolve-ArtifactCandidatePath -ConfiguredPath $manifestConfigured.value -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
} else {
    Resolve-ArtifactCandidatePath -ConfiguredPath $null -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
}
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
$manifestRecord = Read-ArtifactJson $manifestPath
$manifestReadable = [bool]$manifestRecord

$refreshConfigured = Get-ConfiguredValue -Primary $summary -Fallback $manifestRecord -FieldName 'refresh_chain_artifact_path'
$handoffConfigured = Get-ConfiguredValue -Primary $summary -Fallback $manifestRecord -FieldName 'handoff_artifact_path'
$refreshErrorConfigured = Get-ErrorValue -Primary $summary -Fallback $manifestRecord -FieldName 'refresh_chain_artifact_error'
$handoffErrorConfigured = Get-ErrorValue -Primary $summary -Fallback $manifestRecord -FieldName 'handoff_artifact_error'

$resolvedRefreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($refreshConfigured) { $refreshConfigured.value } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$resolvedHandoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($handoffConfigured) { $handoffConfigured.value } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'

$summaryPatchFields = @(
    New-PatchFieldRecord -FieldName 'refresh_chain_artifact_path' -CurrentObject $summary -SuggestedValue $resolvedRefreshPath -ValueSource $(if ($refreshConfigured) { $refreshConfigured.source } else { 'fallback-path' }) -Nullable $false
    New-PatchFieldRecord -FieldName 'refresh_chain_artifact_error' -CurrentObject $summary -SuggestedValue $refreshErrorConfigured.value -ValueSource $refreshErrorConfigured.source -Nullable $true
    New-PatchFieldRecord -FieldName 'handoff_artifact_path' -CurrentObject $summary -SuggestedValue $resolvedHandoffPath -ValueSource $(if ($handoffConfigured) { $handoffConfigured.source } else { 'fallback-path' }) -Nullable $false
    New-PatchFieldRecord -FieldName 'handoff_artifact_error' -CurrentObject $summary -SuggestedValue $handoffErrorConfigured.value -ValueSource $handoffErrorConfigured.source -Nullable $true
)

$manifestPatchFields = @(
    New-PatchFieldRecord -FieldName 'refresh_chain_artifact_path' -CurrentObject $manifestRecord -SuggestedValue $resolvedRefreshPath -ValueSource $(if ($refreshConfigured) { $refreshConfigured.source } else { 'fallback-path' }) -Nullable $false
    New-PatchFieldRecord -FieldName 'refresh_chain_artifact_error' -CurrentObject $manifestRecord -SuggestedValue $refreshErrorConfigured.value -ValueSource $refreshErrorConfigured.source -Nullable $true
    New-PatchFieldRecord -FieldName 'handoff_artifact_path' -CurrentObject $manifestRecord -SuggestedValue $resolvedHandoffPath -ValueSource $(if ($handoffConfigured) { $handoffConfigured.source } else { 'fallback-path' }) -Nullable $false
    New-PatchFieldRecord -FieldName 'handoff_artifact_error' -CurrentObject $manifestRecord -SuggestedValue $handoffErrorConfigured.value -ValueSource $handoffErrorConfigured.source -Nullable $true
)

$summaryMissingPatchFields = @($summaryPatchFields | Where-Object { -not $_.present })
$manifestMissingPatchFields = @($manifestPatchFields | Where-Object { -not $_.present })
$summaryMissingFields = @($summaryMissingPatchFields | ForEach-Object { $_.field })
$manifestMissingFields = @($manifestMissingPatchFields | ForEach-Object { $_.field })
$allMissingFields = @($summaryMissingFields + $manifestMissingFields | Sort-Object -Unique)
$summaryPatchSnippetLines = @($summaryMissingPatchFields | ForEach-Object { New-PatchSnippetLine -FieldRecord $_ })
$manifestPatchSnippetLines = @($manifestMissingPatchFields | ForEach-Object { New-PatchSnippetLine -FieldRecord $_ })

$summaryNeedsPatch = $summaryMissingFields.Count -gt 0
$manifestNeedsPatch = $manifestMissingFields.Count -gt 0
$patchReady = [bool]($resolvedRefreshPath -and $resolvedHandoffPath)
$usesFallbackTargets = [bool]((-not $refreshConfigured) -or (-not $handoffConfigured))
$repairRunnerOutputContractCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1'
$runnerRefreshPathAssignmentCount = Get-DirectFieldAssignmentCount -SourceText $runnerScriptSource -AssignmentText 'refresh_chain_artifact_path = $RefreshChainArtifactPath'
$runnerRefreshErrorAssignmentCount = Get-DirectFieldAssignmentCount -SourceText $runnerScriptSource -AssignmentText 'refresh_chain_artifact_error = $RefreshChainArtifactError'
$runnerHandoffPathAssignmentCount = Get-DirectFieldAssignmentCount -SourceText $runnerScriptSource -AssignmentText 'handoff_artifact_path = $HandoffArtifactPath'
$runnerHandoffErrorAssignmentCount = Get-DirectFieldAssignmentCount -SourceText $runnerScriptSource -AssignmentText 'handoff_artifact_error = $HandoffArtifactError'
$runnerSourceIndicatesDirectFieldWiring = [bool](
    $runnerRefreshPathAssignmentCount -ge 2 -and
    $runnerRefreshErrorAssignmentCount -ge 2 -and
    $runnerHandoffPathAssignmentCount -ge 2 -and
    $runnerHandoffErrorAssignmentCount -ge 2
)
$runnerPatchStillRequired = [bool](($summaryNeedsPatch -or $manifestNeedsPatch) -and (-not $runnerSourceIndicatesDirectFieldWiring))

$status = $null
$reason = $null
$nextFocus = $null
if (-not $manifestExists) {
    $status = 'manifest-missing'
    $reason = 'The saved summary exists, but the manifest file is still missing, so the direct runner-output contract can only be derived from the summary plus fallback artifact paths.'
    $nextFocus = 'Patch the runner summary fields first, then regenerate the recommended validation outputs so the manifest carries the same direct refresh and handoff fields.'
} elseif (-not $manifestReadable) {
    $status = 'manifest-unreadable'
    $reason = 'The manifest file exists but could not be read cleanly, so the helper is falling back to summary values and default artifact locations for the direct runner-output contract.'
    $nextFocus = 'Patch the runner with the resolved direct fields, then regenerate the manifest and reopen the runner wiring audit.'
} elseif (-not $summaryNeedsPatch -and -not $manifestNeedsPatch) {
    $status = 'fully-wired'
    $reason = 'Both the summary and manifest already expose the direct refresh and handoff runner-output fields.'
    $nextFocus = 'Use the existing refresh and handoff helpers for the next narrowed issue #3 replay instead of editing the runner contract again.'
} elseif ($runnerSourceIndicatesDirectFieldWiring) {
    $status = 'saved-artifacts-stale-runner-already-wired'
    $reason = 'The saved summary or manifest still omits at least one direct refresh or handoff field, but the current runner source already writes those fields into both output objects.'
    $nextFocus = 'Regenerate the recommended validation outputs on Windows, or run the saved-output repair helper on the current artifacts before trusting patch-target guidance again.'
} elseif ($summaryNeedsPatch -and $manifestNeedsPatch) {
    $status = 'summary-and-manifest-need-direct-fields'
    $reason = 'Both saved runner outputs still omit at least one top-level refresh or handoff field, but the helper now resolves the exact values needed for a direct runner contract patch.'
    $nextFocus = 'Add the suggested direct fields to both the summary and manifest objects in run_google_issue3_recommended_validation.ps1, rerun the validation runner, then confirm the contract with the runner-output wiring helper.'
} elseif ($summaryNeedsPatch) {
    $status = 'summary-needs-direct-fields'
    $reason = 'The manifest already covers more of the runner-output contract than the summary, and the helper now resolves the exact values needed to close that summary gap directly.'
    $nextFocus = 'Add the suggested direct fields to the summary object in run_google_issue3_recommended_validation.ps1, rerun the runner, and confirm the contract with the runner-output wiring helper.'
} else {
    $status = 'manifest-needs-direct-fields'
    $reason = 'The summary already exposes more of the runner-output contract than the manifest, and the helper now resolves the exact values needed to close that manifest gap directly.'
    $nextFocus = 'Add the suggested direct fields to the manifest object in run_google_issue3_recommended_validation.ps1, rerun the runner, and confirm the contract with the runner-output wiring helper.'
}

$report = [ordered]@{
    issue = 'Google issue #3 runner output patch targets'
    purpose = 'Resolve the exact direct refresh and handoff field values the recommended validation runner should write into its saved summary and manifest outputs.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_readable = [bool]$manifestReadable
    resolved_refresh_artifact_path = $resolvedRefreshPath
    resolved_handoff_artifact_path = $resolvedHandoffPath
    refresh_path_value_source = if ($refreshConfigured) { $refreshConfigured.source } else { 'fallback-path' }
    handoff_path_value_source = if ($handoffConfigured) { $handoffConfigured.source } else { 'fallback-path' }
    refresh_error_value_source = $refreshErrorConfigured.source
    handoff_error_value_source = $handoffErrorConfigured.source
    patch_ready = [bool]$patchReady
    uses_fallback_targets = [bool]$usesFallbackTargets
    summary_needs_patch = [bool]$summaryNeedsPatch
    manifest_needs_patch = [bool]$manifestNeedsPatch
    missing_runner_fields = @($allMissingFields)
    summary_patch_fields = @($summaryPatchFields)
    manifest_patch_fields = @($manifestPatchFields)
    summary_patch_snippet_lines = @($summaryPatchSnippetLines)
    manifest_patch_snippet_lines = @($manifestPatchSnippetLines)
    runner_script_path = $runnerScriptPath
    runner_script_exists = [bool]$runnerScriptExists
    runner_source_indicates_direct_field_wiring = [bool]$runnerSourceIndicatesDirectFieldWiring
    runner_patch_still_required = [bool]$runnerPatchStillRequired
    runner_direct_field_assignment_counts = [ordered]@{
        refresh_chain_artifact_path = $runnerRefreshPathAssignmentCount
        refresh_chain_artifact_error = $runnerRefreshErrorAssignmentCount
        handoff_artifact_path = $runnerHandoffPathAssignmentCount
        handoff_artifact_error = $runnerHandoffErrorAssignmentCount
    }
    recommended_patch_target = if ($runnerPatchStillRequired) { 'scripts/windows/run_google_issue3_recommended_validation.ps1' } else { $null }
    recommended_repair_command = $repairRunnerOutputContractCommand
    recommended_regeneration_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
    recommended_verification_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
    runner_output_status_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
    broader_runner_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
    status = $status
    reason = $reason
    next_focus = $nextFocus
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 runner output patch targets'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
Write-Host ("Manifest readable: {0}" -f $report.manifest_artifact_readable)
Write-Host ("Patch ready: {0}" -f $report.patch_ready)
Write-Host ("Uses fallback targets: {0}" -f $report.uses_fallback_targets)
Write-Host ("Summary needs patch: {0}" -f $report.summary_needs_patch)
Write-Host ("Manifest needs patch: {0}" -f $report.manifest_needs_patch)
Write-Host ("Runner script: {0}" -f $report.runner_script_path)
Write-Host ("Runner source wired: {0}" -f $report.runner_source_indicates_direct_field_wiring)
Write-Host ("Runner patch still required: {0}" -f $report.runner_patch_still_required)
Write-Host ("Refresh target: {0}" -f $report.resolved_refresh_artifact_path)
Write-Host ("Refresh source: {0}" -f $report.refresh_path_value_source)
Write-Host ("Handoff target: {0}" -f $report.resolved_handoff_artifact_path)
Write-Host ("Handoff source: {0}" -f $report.handoff_path_value_source)
if ($report.missing_runner_fields.Count -gt 0) {
    Write-Host 'Missing fields:'
    foreach ($fieldName in $report.missing_runner_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
Write-Host ''
Write-Host 'Summary patch fields:'
foreach ($field in $report.summary_patch_fields) {
    if (-not $field.present) {
        Write-Host ("- {0}: {1} ({2})" -f $field.field, $field.suggested_value, $field.suggested_value_source)
    }
}
if ($report.summary_patch_snippet_lines.Count -gt 0) {
    Write-Host ''
    Write-Host 'Summary patch snippet:'
    foreach ($line in $report.summary_patch_snippet_lines) {
        Write-Host $line
    }
}
Write-Host ''
Write-Host 'Manifest patch fields:'
foreach ($field in $report.manifest_patch_fields) {
    if (-not $field.present) {
        Write-Host ("- {0}: {1} ({2})" -f $field.field, $field.suggested_value, $field.suggested_value_source)
    }
}
if ($report.manifest_patch_snippet_lines.Count -gt 0) {
    Write-Host ''
    Write-Host 'Manifest patch snippet:'
    foreach ($line in $report.manifest_patch_snippet_lines) {
        Write-Host $line
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
if ($report.recommended_patch_target) {
    Write-Host ("Patch:  {0}" -f $report.recommended_patch_target)
} else {
    Write-Host 'Patch:  Not required; regenerate or repair the saved outputs first.'
}
Write-Host ("Repair: {0}" -f $report.recommended_repair_command)
Write-Host ("Rerun:  {0}" -f $report.recommended_regeneration_command)
Write-Host ("Verify: {0}" -f $report.recommended_verification_command)
