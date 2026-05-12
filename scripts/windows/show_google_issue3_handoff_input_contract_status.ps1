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

$manifestConfiguredPath = Get-OptionalPropertyValue -Object $summary -Name 'manifest_artifact_path'
$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $manifestConfiguredPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
$manifestRecord = $null
$manifestReadable = $false
$manifestError = $null
if ($manifestExists) {
    try {
        $manifestRecord = Read-ArtifactJson $manifestPath
        $manifestReadable = [bool]$manifestRecord
        if (-not $manifestReadable) {
            $manifestError = "Manifest artifact was read but did not deserialize into a JSON object."
        }
    } catch {
        $manifestError = $_.Exception.Message
    }
}

$contractFields = @(
    'refresh_chain_artifact_path'
    'refresh_chain_artifact_error'
    'handoff_artifact_path'
    'handoff_artifact_error'
)

$summaryFieldStatus = @($contractFields | ForEach-Object {
    [pscustomobject]@{
        field = $_
        present = [bool](Test-HasProperty -Object $summary -Name $_)
        value = Get-OptionalPropertyValue -Object $summary -Name $_
    }
})
$summaryMissingFields = @($summaryFieldStatus | Where-Object { -not $_.present } | ForEach-Object { $_.field })

$manifestFieldStatus = if ($manifestReadable) {
    @($contractFields | ForEach-Object {
        [pscustomobject]@{
            field = $_
            present = [bool](Test-HasProperty -Object $manifestRecord -Name $_)
            value = Get-OptionalPropertyValue -Object $manifestRecord -Name $_
        }
    })
} else {
    @()
}
$manifestMissingFields = if ($manifestReadable) {
    @($manifestFieldStatus | Where-Object { -not $_.present } | ForEach-Object { $_.field })
} else {
    @()
}

$summarySafe = ($summaryMissingFields.Count -eq 0)
$manifestSafe = (-not $manifestReadable) -or ($manifestMissingFields.Count -eq 0)
$safeToRunHandoffHelper = [bool]($summarySafe -and $manifestSafe)

$recommendedCommand = $null
$recommendedGuideCommand = $null
$reason = $null
$nextFocus = $null
if (-not $summarySafe) {
    $recommendedCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
    $recommendedGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
    $reason = 'The saved summary is still missing one or more direct refresh or handoff contract fields, so the current handoff helper can still trip strict-mode property access before it reaches its fallback path.'
    $nextFocus = 'Add the missing direct runner-output fields to the recommended validation summary and manifest outputs before relying on the narrower handoff helper.'
} elseif ($manifestReadable -and -not $manifestSafe) {
    $recommendedCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
    $recommendedGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
    $reason = 'The saved manifest is readable but still omits one or more direct refresh or handoff contract fields, so the current handoff helper can still trip strict-mode property access when it inspects manifest-backed values.'
    $nextFocus = 'Patch the runner-side contract fields or regenerate the manifest after repair so the narrower handoff helper can read the current manifest safely.'
} else {
    $recommendedCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
    $recommendedGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
    if ($manifestReadable) {
        $reason = 'Both the summary and manifest already expose the direct refresh and handoff contract fields that the current handoff helper reads under strict mode.'
    } elseif ($manifestExists) {
        $reason = 'The summary already carries the direct refresh and handoff contract fields, and the unreadable manifest does not block the current handoff helper from using summary-backed values.'
    } else {
        $reason = 'The summary already carries the direct refresh and handoff contract fields, so the current handoff helper can rely on summary-backed values even before a manifest is regenerated.'
    }
    $nextFocus = 'Use the existing handoff helper and refresh-status helper to keep the narrowed issue #3 replay moving forward.'
}

$report = [ordered]@{
    issue = 'Google issue #3 handoff input contract status'
    purpose = 'Check whether the saved summary and manifest expose the optional refresh and handoff fields that the current handoff helper reads under strict mode.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_readable = [bool]$manifestReadable
    manifest_artifact_error = $manifestError
    summary_safe_for_handoff_helper = [bool]$summarySafe
    manifest_safe_for_handoff_helper = [bool]$manifestSafe
    safe_to_run_handoff_helper = [bool]$safeToRunHandoffHelper
    summary_missing_contract_fields = @($summaryMissingFields)
    manifest_missing_contract_fields = @($manifestMissingFields)
    summary_field_status = @($summaryFieldStatus)
    manifest_field_status = @($manifestFieldStatus)
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    reason = $reason
    next_focus = $nextFocus
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 handoff input contract status'
Write-Host ''
Write-Host ("Summary:  {0}" -f $report.summary_path)
Write-Host ("Manifest: {0}" -f $report.manifest_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
Write-Host ("Manifest readable: {0}" -f $report.manifest_artifact_readable)
if ($report.manifest_artifact_error) {
    Write-Host ("Manifest error: {0}" -f $report.manifest_artifact_error)
}
Write-Host ("Summary safe: {0}" -f $report.summary_safe_for_handoff_helper)
Write-Host ("Manifest safe: {0}" -f $report.manifest_safe_for_handoff_helper)
Write-Host ("Safe to run handoff helper: {0}" -f $report.safe_to_run_handoff_helper)
if ($report.summary_missing_contract_fields.Count -gt 0) {
    Write-Host 'Summary missing fields:'
    foreach ($fieldName in $report.summary_missing_contract_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
if ($report.manifest_missing_contract_fields.Count -gt 0) {
    Write-Host 'Manifest missing fields:'
    foreach ($fieldName in $report.manifest_missing_contract_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
