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

function PathsMatch([string]$Left, [string]$Right) {
    if ([string]::IsNullOrWhiteSpace($Left) -or [string]::IsNullOrWhiteSpace($Right)) {
        return $false
    }

    return ([System.IO.Path]::GetFullPath($Left)).Equals([System.IO.Path]::GetFullPath($Right), [System.StringComparison]::OrdinalIgnoreCase)
}

function New-PathRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [string]$SummaryConfiguredPath,
        [string]$ManifestConfiguredPath,
        [Parameter(Mandatory = $true)]
        [string]$SummaryPreferredPath,
        [Parameter(Mandatory = $true)]
        [string]$ManifestPreferredPath
    )

    $pathsMatch = PathsMatch $SummaryPreferredPath $ManifestPreferredPath

    return [pscustomobject]@{
        label = $Label
        summary_records_path = -not [string]::IsNullOrWhiteSpace($SummaryConfiguredPath)
        summary_configured_path = $SummaryConfiguredPath
        manifest_records_path = -not [string]::IsNullOrWhiteSpace($ManifestConfiguredPath)
        manifest_configured_path = $ManifestConfiguredPath
        summary_preferred_path = $SummaryPreferredPath
        summary_preferred_exists = Test-Path -LiteralPath $SummaryPreferredPath -PathType Leaf
        manifest_preferred_path = $ManifestPreferredPath
        manifest_preferred_exists = Test-Path -LiteralPath $ManifestPreferredPath -PathType Leaf
        paths_match = [bool]$pathsMatch
        drift_detected = [bool](-not $pathsMatch)
    }
}

$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'
$manifestGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest.ps1'
$manifestSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest_safe.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$refreshStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json'
}

$summaryExists = Test-Path -LiteralPath $SummaryPath -PathType Leaf
if (-not $summaryExists) {
    $report = [ordered]@{
        issue = 'Google issue #3 validation manifest path coherency'
        purpose = 'Tell the next Windows replay whether the raw issue #3 manifest guide still points at the same saved artifacts as the current summary-backed helper chain.'
        generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        summary_path = $SummaryPath
        summary_exists = $false
        status = 'summary-missing'
        manifest_path = $null
        manifest_exists = $false
        manifest_readable = $false
        manifest_summary_matches = $false
        drift_labels = @()
        recommended_command = $recommendedRunnerCommand
        recommended_guide_command = $summaryGuideCommand
        next_artifact_to_open = $SummaryPath
        reason = 'No saved issue #3 recommended-validation summary exists yet, so the raw manifest guide has no current summary state to compare against.'
        next_focus = 'Run the bounded issue #3 validation runner first, then reopen this helper before trusting the raw manifest guide.'
    }

    if ($Json) {
        $report | ConvertTo-Json -Depth 6
        exit 0
    }

    Write-Host 'Google issue #3 validation manifest path coherency'
    Write-Host ''
    Write-Host ("Summary:  {0}" -f $report.summary_path)
    Write-Host ("Exists:   {0}" -f $report.summary_exists)
    Write-Host ("Reason:   {0}" -f $report.reason)
    Write-Host ("Focus:    {0}" -f $report.next_focus)
    Write-Host ("Run:      {0}" -f $report.recommended_command)
    Write-Host ("Guide:    {0}" -f $report.recommended_guide_command)
    exit 0
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$artifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
if ([string]::IsNullOrWhiteSpace($artifactRoot)) {
    $artifactRoot = Split-Path -Parent $SummaryPath
}

$summaryManifestPath = Get-OptionalPropertyValue -Object $summary -Name 'manifest_artifact_path'
$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summaryManifestPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
$manifestRecord = Read-ArtifactJson $manifestPath
$manifestReadable = [bool]$manifestRecord
$manifestSummaryPath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'summary_path'
$manifestSummaryMatches = PathsMatch $SummaryPath $manifestSummaryPath

$pathRecords = @(
    New-PathRecord -Label 'guide' `
        -SummaryConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'guide_artifact_path') `
        -ManifestConfiguredPath (Get-OptionalPropertyValue -Object $manifestRecord -Name 'guide_artifact_path') `
        -SummaryPreferredPath (Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'guide_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-guide.json') `
        -ManifestPreferredPath (Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $manifestRecord -Name 'guide_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-guide.json')
    New-PathRecord -Label 'boundary' `
        -SummaryConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'boundary_artifact_path') `
        -ManifestConfiguredPath (Get-OptionalPropertyValue -Object $manifestRecord -Name 'boundary_artifact_path') `
        -SummaryPreferredPath (Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'boundary_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-phase-boundary.json') `
        -ManifestPreferredPath (Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $manifestRecord -Name 'boundary_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-phase-boundary.json')
    New-PathRecord -Label 'bundle' `
        -SummaryConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'artifact_bundle_path') `
        -ManifestConfiguredPath (Get-OptionalPropertyValue -Object $manifestRecord -Name 'artifact_bundle_path') `
        -SummaryPreferredPath (Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'artifact_bundle_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json') `
        -ManifestPreferredPath (Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $manifestRecord -Name 'artifact_bundle_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json')
    New-PathRecord -Label 'handoff' `
        -SummaryConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'handoff_artifact_path') `
        -ManifestConfiguredPath (Get-OptionalPropertyValue -Object $manifestRecord -Name 'handoff_artifact_path') `
        -SummaryPreferredPath (Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'handoff_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json') `
        -ManifestPreferredPath (Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $manifestRecord -Name 'handoff_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json')
    New-PathRecord -Label 'refresh' `
        -SummaryConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'refresh_chain_artifact_path') `
        -ManifestConfiguredPath (Get-OptionalPropertyValue -Object $manifestRecord -Name 'refresh_chain_artifact_path') `
        -SummaryPreferredPath (Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'refresh_chain_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json') `
        -ManifestPreferredPath (Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $manifestRecord -Name 'refresh_chain_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json')
)

$driftLabels = @($pathRecords | Where-Object { $_.drift_detected } | ForEach-Object { $_.label })

$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null

if (-not $manifestExists) {
    $status = 'manifest-missing'
    $reason = 'The current summary points at a manifest path, but that manifest file is missing, so the raw manifest guide cannot be trusted yet.'
    $nextFocus = 'Regenerate the saved issue #3 outputs with the broader runner, then return to the safe manifest helper before trusting the raw manifest guide.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $manifestSafeCommand
    $nextArtifactToOpen = $SummaryPath
} elseif (-not $manifestReadable) {
    $status = 'manifest-unreadable'
    $reason = 'The saved manifest exists but could not be read cleanly, so the raw manifest guide cannot safely serve as the next checkpoint.'
    $nextFocus = 'Rebuild the helper chain from the current summary, then reopen the safe manifest helper before trusting the raw manifest guide.'
    $recommendedCommand = $refreshChainCommand
    $recommendedGuideCommand = $manifestSafeCommand
    $nextArtifactToOpen = $manifestPath
} elseif (-not $manifestSummaryMatches) {
    $status = 'manifest-summary-mismatch'
    $reason = 'The saved manifest still points at a different summary path than the current summary under inspection, so the raw manifest guide may follow stale artifacts.'
    $nextFocus = 'Refresh the summary-derived helper chain from the current summary, then reopen the safe manifest helper before trusting the raw manifest guide.'
    $recommendedCommand = $refreshChainCommand
    $recommendedGuideCommand = $manifestSafeCommand
    $nextArtifactToOpen = $manifestPath
} elseif ($driftLabels.Count -gt 0) {
    $status = 'path-drift-detected'
    $reason = 'One or more manifest-backed artifact paths now differ from the current summary-backed paths, so the raw manifest guide may reopen stale helper artifacts.'
    $nextFocus = 'Use the safe manifest or safe refresh-status checkpoints while the current summary and manifest paths are brought back into alignment.'
    $recommendedCommand = if ($driftLabels -contains 'refresh' -or $driftLabels -contains 'handoff') { $refreshStatusSafeCommand } else { $refreshChainCommand }
    $recommendedGuideCommand = $manifestSafeCommand
    $nextArtifactToOpen = if ($driftLabels -contains 'refresh') {
        ($pathRecords | Where-Object { $_.label -eq 'refresh' } | Select-Object -First 1).summary_preferred_path
    } elseif ($driftLabels -contains 'handoff') {
        ($pathRecords | Where-Object { $_.label -eq 'handoff' } | Select-Object -First 1).summary_preferred_path
    } else {
        $manifestPath
    }
} else {
    $status = 'coherent'
    $reason = 'The current summary-backed and manifest-backed artifact paths line up for the saved issue #3 helper chain, so the raw manifest guide is coherent for this summary.'
    $nextFocus = 'Use the raw manifest guide for the next narrowed Windows replay, or stay on the safe manifest helper if you want the extra guardrail.'
    $recommendedCommand = $manifestGuideCommand
    $recommendedGuideCommand = $manifestSafeCommand
    $nextArtifactToOpen = $manifestPath
}

$report = [ordered]@{
    issue = 'Google issue #3 validation manifest path coherency'
    purpose = 'Tell the next Windows replay whether the raw issue #3 manifest guide still points at the same saved artifacts as the current summary-backed helper chain.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    summary_exists = $true
    summary_generated_at_utc = Get-OptionalPropertyValue -Object $summary -Name 'generated_at_utc'
    artifact_root = $artifactRoot
    manifest_path = $manifestPath
    manifest_exists = [bool]$manifestExists
    manifest_readable = [bool]$manifestReadable
    manifest_summary_path = $manifestSummaryPath
    manifest_summary_matches = [bool]$manifestSummaryMatches
    drift_labels = @($driftLabels)
    path_records = @($pathRecords)
    status = $status
    reason = $reason
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    manifest_guide_command = $manifestGuideCommand
    manifest_safe_command = $manifestSafeCommand
    refresh_status_command = $refreshStatusCommand
    refresh_status_safe_command = $refreshStatusSafeCommand
    refresh_chain_command = $refreshChainCommand
    broader_runner_command = $recommendedRunnerCommand
}

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host 'Google issue #3 validation manifest path coherency'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_path)
Write-Host ("Readable:  {0}" -f $report.manifest_readable)
Write-Host ("Summary match: {0}" -f $report.manifest_summary_matches)
Write-Host ("Status:    {0}" -f $report.status)
if ($report.drift_labels.Count -gt 0) {
    Write-Host ("Drift:     {0}" -f ($report.drift_labels -join ', '))
}
Write-Host ("Open:      {0}" -f $report.next_artifact_to_open)
Write-Host ''
foreach ($record in $report.path_records) {
    Write-Host ("[{0}] summary -> {1}" -f $record.label, $record.summary_preferred_path)
    Write-Host ("[{0}] manifest -> {1}" -f $record.label, $record.manifest_preferred_path)
}
Write-Host ''
Write-Host ("Reason:    {0}" -f $report.reason)
Write-Host ("Focus:     {0}" -f $report.next_focus)
Write-Host ("Run:       {0}" -f $report.recommended_command)
Write-Host ("Guide:     {0}" -f $report.recommended_guide_command)