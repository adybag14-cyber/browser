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

function Add-MissingField {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$List,
        [Parameter(Mandatory = $true)]
        [string]$FieldName,
        [Parameter(Mandatory = $true)]
        [bool]$Present
    )

    if (-not $Present) {
        $List.Add($FieldName) | Out-Null
    }
}

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json'
}
if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    throw "Issue #3 recommended validation summary not found: $SummaryPath"
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$summaryHasArtifactRootField = Test-HasProperty -Object $summary -Name 'artifact_root'
$artifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
if ([string]::IsNullOrWhiteSpace($artifactRoot)) {
    $artifactRoot = Split-Path -Parent $SummaryPath
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-validation-artifact-bundle-safe.json'
}

$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'
$bundleCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
$refreshStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe.ps1'
$handoffSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe.ps1'

$summaryMissingFields = [System.Collections.Generic.List[string]]::new()
foreach ($fieldName in @(
    'artifact_root',
    'surface_check_artifact_path',
    'guide_artifact_path',
    'manifest_artifact_path',
    'boundary_artifact_path',
    'handoff_artifact_path',
    'refresh_chain_artifact_path',
    'phase_artifact_root',
    'phase_results',
    'generated_at_utc',
    'completed',
    'first_failed_phase',
    'first_failed_phase_error',
    'surface_check_status',
    'guide_artifact_error',
    'boundary_artifact_error'
)) {
    Add-MissingField -List $summaryMissingFields -FieldName ("summary.{0}" -f $fieldName) -Present (Test-HasProperty -Object $summary -Name $fieldName)
}

$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'manifest_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$guidePath = Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'guide_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-guide.json'
$boundaryPath = Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'boundary_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-phase-boundary.json'
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'handoff_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
$refreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'refresh_chain_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$bundlePath = Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'artifact_bundle_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json'

$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
$guideExists = Test-Path -LiteralPath $guidePath -PathType Leaf
$boundaryExists = Test-Path -LiteralPath $boundaryPath -PathType Leaf
$handoffExists = Test-Path -LiteralPath $handoffPath -PathType Leaf
$refreshExists = Test-Path -LiteralPath $refreshPath -PathType Leaf

$manifestRecord = $null
$manifestError = $null
if ($manifestExists) {
    try {
        $manifestRecord = Read-ArtifactJson $manifestPath
    } catch {
        $manifestError = $_.Exception.Message
    }
}

$guideRecord = $null
$guideError = $null
if ($guideExists) {
    try {
        $guideRecord = Read-ArtifactJson $guidePath
    } catch {
        $guideError = $_.Exception.Message
    }
}

$boundaryRecord = $null
$boundaryError = $null
if ($boundaryExists) {
    try {
        $boundaryRecord = Read-ArtifactJson $boundaryPath
    } catch {
        $boundaryError = $_.Exception.Message
    }
}

$handoffRecord = $null
$handoffError = $null
if ($handoffExists) {
    try {
        $handoffRecord = Read-ArtifactJson $handoffPath
    } catch {
        $handoffError = $_.Exception.Message
    }
}

$refreshRecord = $null
$refreshError = $null
if ($refreshExists) {
    try {
        $refreshRecord = Read-ArtifactJson $refreshPath
    } catch {
        $refreshError = $_.Exception.Message
    }
}

$manifestMissingFields = [System.Collections.Generic.List[string]]::new()
if ($manifestRecord) {
    foreach ($fieldName in @('summary_path')) {
        Add-MissingField -List $manifestMissingFields -FieldName ("manifest.{0}" -f $fieldName) -Present (Test-HasProperty -Object $manifestRecord -Name $fieldName)
    }
}

$guideMissingFields = [System.Collections.Generic.List[string]]::new()
if ($guideRecord) {
    foreach ($fieldName in @(
        'summary_path',
        'generated_at_utc',
        'first_failed_phase_primary_json_artifact_path',
        'next_focus',
        'recommended_command',
        'recommended_guide_command',
        'broader_runner_command',
        'phase_boundary_command',
        'manual_fixture_replay_available',
        'manual_fixture_replay_command',
        'manual_asset_closure_command',
        'manual_attached_html_flow_command',
        'manual_attached_html_runner_command',
        'manual_saved_page_flow_command'
    )) {
        Add-MissingField -List $guideMissingFields -FieldName ("guide.{0}" -f $fieldName) -Present (Test-HasProperty -Object $guideRecord -Name $fieldName)
    }
}

$boundaryMissingFields = [System.Collections.Generic.List[string]]::new()
if ($boundaryRecord) {
    foreach ($fieldName in @(
        'summary_path',
        'generated_at_utc',
        'recommended_command',
        'recommended_guide_command',
        'next_artifact_to_open',
        'last_passed_phase',
        'first_failed_phase',
        'boundary_focus',
        'reason'
    )) {
        Add-MissingField -List $boundaryMissingFields -FieldName ("boundary.{0}" -f $fieldName) -Present (Test-HasProperty -Object $boundaryRecord -Name $fieldName)
    }
}

$handoffMissingFields = [System.Collections.Generic.List[string]]::new()
if ($handoffRecord) {
    foreach ($fieldName in @(
        'summary_path',
        'summary_generated_at_utc',
        'recommended_command',
        'recommended_guide_command',
        'next_focus',
        'next_artifact_to_open',
        'broader_runner_command'
    )) {
        Add-MissingField -List $handoffMissingFields -FieldName ("handoff.{0}" -f $fieldName) -Present (Test-HasProperty -Object $handoffRecord -Name $fieldName)
    }
}

$refreshMissingFields = [System.Collections.Generic.List[string]]::new()
if ($refreshRecord) {
    foreach ($fieldName in @(
        'summary_path',
        'status',
        'generated_at_utc',
        'reason',
        'recommended_command',
        'recommended_guide_command',
        'next_artifact_to_open'
    )) {
        Add-MissingField -List $refreshMissingFields -FieldName ("refresh.{0}" -f $fieldName) -Present (Test-HasProperty -Object $refreshRecord -Name $fieldName)
    }
}

$helperArtifactErrors = [System.Collections.Generic.List[string]]::new()
$firstUnsafeArtifactPath = $null
if ($manifestError) {
    $helperArtifactErrors.Add("manifest: $manifestError") | Out-Null
    $firstUnsafeArtifactPath = $manifestPath
}
if ($guideError) {
    $helperArtifactErrors.Add("guide: $guideError") | Out-Null
    if (-not $firstUnsafeArtifactPath) { $firstUnsafeArtifactPath = $guidePath }
}
if ($boundaryError) {
    $helperArtifactErrors.Add("boundary: $boundaryError") | Out-Null
    if (-not $firstUnsafeArtifactPath) { $firstUnsafeArtifactPath = $boundaryPath }
}
if ($handoffError) {
    $helperArtifactErrors.Add("handoff: $handoffError") | Out-Null
    if (-not $firstUnsafeArtifactPath) { $firstUnsafeArtifactPath = $handoffPath }
}
if ($refreshError) {
    $helperArtifactErrors.Add("refresh: $refreshError") | Out-Null
    if (-not $firstUnsafeArtifactPath) { $firstUnsafeArtifactPath = $refreshPath }
}

$helperArtifactsMissingFields = [bool](
    $manifestMissingFields.Count -gt 0 -or
    $guideMissingFields.Count -gt 0 -or
    $boundaryMissingFields.Count -gt 0 -or
    $handoffMissingFields.Count -gt 0 -or
    $refreshMissingFields.Count -gt 0
)
if (-not $firstUnsafeArtifactPath) {
    if ($manifestMissingFields.Count -gt 0) {
        $firstUnsafeArtifactPath = $manifestPath
    } elseif ($guideMissingFields.Count -gt 0) {
        $firstUnsafeArtifactPath = $guidePath
    } elseif ($boundaryMissingFields.Count -gt 0) {
        $firstUnsafeArtifactPath = $boundaryPath
    } elseif ($handoffMissingFields.Count -gt 0) {
        $firstUnsafeArtifactPath = $handoffPath
    } elseif ($refreshMissingFields.Count -gt 0) {
        $firstUnsafeArtifactPath = $refreshPath
    }
}

$status = $null
$reason = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextFocus = $null
$nextArtifactToOpen = $null

if (-not $summaryHasArtifactRootField) {
    $status = 'summary-artifact-root-missing'
    $reason = 'The saved summary omits artifact_root, so the raw artifact-bundle helper can fail under strict mode before it reaches its fallback artifact-root logic.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $summaryGuideCommand
    $nextFocus = 'Regenerate the issue #3 recommended-validation summary before trusting the raw artifact-bundle helper.'
    $nextArtifactToOpen = $SummaryPath
} elseif ($summaryMissingFields.Count -gt 0) {
    $status = 'summary-contract-missing'
    $reason = 'The saved summary still omits one or more fields that the raw artifact-bundle helper reads directly under strict mode.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $summaryGuideCommand
    $nextFocus = 'Refresh the recommended-validation summary first, then reopen the bounded issue #3 guide before trusting the raw artifact-bundle helper.'
    $nextArtifactToOpen = $SummaryPath
} elseif ($helperArtifactErrors.Count -gt 0) {
    $status = 'helper-artifact-unreadable'
    $reason = 'One or more saved helper artifacts for the current summary could not be parsed cleanly, so the raw artifact-bundle helper is safer to revisit after a helper-chain refresh.'
    $recommendedCommand = $refreshChainCommand
    $recommendedGuideCommand = $refreshStatusSafeCommand
    $nextFocus = 'Refresh the saved guide, boundary, bundle, handoff, and refresh artifacts from the current summary before trusting the raw artifact-bundle helper.'
    $nextArtifactToOpen = $firstUnsafeArtifactPath
} elseif ($helperArtifactsMissingFields) {
    $status = 'helper-artifact-contract-missing'
    $reason = 'At least one saved helper artifact exists but still omits fields that the raw artifact-bundle helper reads directly under strict mode.'
    $recommendedCommand = $refreshChainCommand
    $recommendedGuideCommand = $refreshStatusSafeCommand
    $nextFocus = 'Regenerate the saved helper-chain artifacts first, then reopen the raw artifact-bundle helper from the refreshed summary state.'
    $nextArtifactToOpen = $firstUnsafeArtifactPath
} else {
    $status = 'safe-to-run-existing-helper'
    $reason = 'The current summary and any existing guide, boundary, manifest, handoff, and refresh artifacts expose the fields that the raw artifact-bundle helper expects under strict mode.'
    $recommendedCommand = $bundleCommand
    $recommendedGuideCommand = $handoffSafeCommand
    $nextFocus = 'Run the raw artifact-bundle helper, then follow the saved handoff-safe checkpoint before the next Windows replay trusts the narrower handoff path.'
    $nextArtifactToOpen = $bundlePath
}

$report = [ordered]@{
    issue = 'Google issue #3 validation artifact bundle safe helper'
    purpose = 'Check whether the raw artifact-bundle helper is safe to trust under strict mode for the current issue #3 summary and saved helper-chain artifacts.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    artifact_root = $artifactRoot
    raw_bundle_artifact_path = $bundlePath
    summary_has_artifact_root_field = [bool]$summaryHasArtifactRootField
    summary_contract_missing_fields = @($summaryMissingFields)
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_error = $manifestError
    manifest_safe_fields_missing = @($manifestMissingFields)
    guide_artifact_path = $guidePath
    guide_artifact_exists = [bool]$guideExists
    guide_artifact_error = $guideError
    guide_safe_fields_missing = @($guideMissingFields)
    boundary_artifact_path = $boundaryPath
    boundary_artifact_exists = [bool]$boundaryExists
    boundary_artifact_error = $boundaryError
    boundary_safe_fields_missing = @($boundaryMissingFields)
    handoff_artifact_path = $handoffPath
    handoff_artifact_exists = [bool]$handoffExists
    handoff_artifact_error = $handoffError
    handoff_safe_fields_missing = @($handoffMissingFields)
    refresh_artifact_path = $refreshPath
    refresh_artifact_exists = [bool]$refreshExists
    refresh_artifact_error = $refreshError
    refresh_safe_fields_missing = @($refreshMissingFields)
    helper_artifact_errors = @($helperArtifactErrors)
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    refresh_chain_command = $refreshChainCommand
    raw_bundle_command = $bundleCommand
    handoff_safe_command = $handoffSafeCommand
    refresh_status_safe_command = $refreshStatusSafeCommand
    next_artifact_to_open = $nextArtifactToOpen
    status = $status
    reason = $reason
    next_focus = $nextFocus
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host 'Google issue #3 validation artifact bundle safe helper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Bundle:    {0}" -f $report.raw_bundle_artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary artifact_root present: {0}" -f $report.summary_has_artifact_root_field)
if ($report.summary_contract_missing_fields.Count -gt 0) {
    Write-Host 'Missing summary-contract fields:'
    foreach ($fieldName in $report.summary_contract_missing_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
if ($report.helper_artifact_errors.Count -gt 0) {
    Write-Host 'Unreadable helper artifacts:'
    foreach ($helperError in $report.helper_artifact_errors) {
        Write-Host ("- {0}" -f $helperError)
    }
}
foreach ($entry in @(
    [pscustomobject]@{ label = 'manifest'; exists = $report.manifest_artifact_exists; missing = $report.manifest_safe_fields_missing; path = $report.manifest_artifact_path },
    [pscustomobject]@{ label = 'guide'; exists = $report.guide_artifact_exists; missing = $report.guide_safe_fields_missing; path = $report.guide_artifact_path },
    [pscustomobject]@{ label = 'boundary'; exists = $report.boundary_artifact_exists; missing = $report.boundary_safe_fields_missing; path = $report.boundary_artifact_path },
    [pscustomobject]@{ label = 'handoff'; exists = $report.handoff_artifact_exists; missing = $report.handoff_safe_fields_missing; path = $report.handoff_artifact_path },
    [pscustomobject]@{ label = 'refresh'; exists = $report.refresh_artifact_exists; missing = $report.refresh_safe_fields_missing; path = $report.refresh_artifact_path }
)) {
    Write-Host ("{0}: exists={1} path={2}" -f $entry.label, $entry.exists, $entry.path)
    if ($entry.missing.Count -gt 0) {
        foreach ($fieldName in $entry.missing) {
            Write-Host ("- {0}" -f $fieldName)
        }
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
