[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SourceArtifactPath,
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

function Get-OptionalPropertyValue {
    param(
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($Object -and $Object.PSObject.Properties[$Name]) {
        return $Object.$Name
    }

    return $null
}

function Get-FirstNonEmptyValue {
    param([object[]]$Values)

    foreach ($value in $Values) {
        if ($null -eq $value) {
            continue
        }

        if ($value -is [string]) {
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                return $value
            }
            continue
        }

        return $value
    }

    return $null
}

function Get-ArrayValue {
    param(
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $value = Get-OptionalPropertyValue -Object $Object -Name $Name
    if ($null -eq $value) {
        return @()
    }

    return @($value)
}

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [hashtable]$Arguments = @{}
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\$ScriptName"
    foreach ($entry in $Arguments.GetEnumerator()) {
        $value = $entry.Value
        if ($null -eq $value) {
            continue
        }

        if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        $escapedValue = ("$value") -replace "'", "''"
        $command += (" -{0} '{1}'" -f $entry.Key, $escapedValue)
    }

    return $command
}

$resolvedRepoRoot = if ($RepoRoot) {
    $RepoRoot
} else {
    Resolve-RepoRoot $PSScriptRoot
}
$artifactRoot = Join-Path $resolvedRepoRoot 'tmp-browser-smoke\headed-probe'
$preferredSourceArtifactPaths = @(
    (Join-Path $artifactRoot 'google-issue3-recommended-validation-safe-route-runner-patch-handoff.json'),
    (Join-Path $artifactRoot 'google-issue3-validation-safe-route-runner-patch-wrapper.json'),
    (Join-Path $artifactRoot 'google-issue3-runner-output-patch-targets-safe-route.json'),
    (Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-runner-output-patch-targets.json')
)
if (-not $SourceArtifactPath) {
    $SourceArtifactPath = $preferredSourceArtifactPaths |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
        Select-Object -First 1
    if (-not $SourceArtifactPath) {
        $SourceArtifactPath = $preferredSourceArtifactPaths[0]
    }
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-runner-output-patch-handoff.json'
}
if (-not (Test-Path -LiteralPath $SourceArtifactPath -PathType Leaf)) {
    throw "Issue #3 runner-output patch-route artifact not found: $SourceArtifactPath"
}

$sourceArtifact = Get-Content -LiteralPath $SourceArtifactPath -Raw | ConvertFrom-Json
$sourceStatus = Get-OptionalPropertyValue -Object $sourceArtifact -Name 'status'
$recommendedPatchTarget = Get-OptionalPropertyValue -Object $sourceArtifact -Name 'recommended_patch_target'
$recommendedSourceCommand = Get-OptionalPropertyValue -Object $sourceArtifact -Name 'recommended_command'
$recommendedSourceGuideCommand = Get-OptionalPropertyValue -Object $sourceArtifact -Name 'recommended_guide_command'
$recommendedVerificationCommand = Get-OptionalPropertyValue -Object $sourceArtifact -Name 'recommended_verification_command'
$recommendedRegenerationCommand = Get-OptionalPropertyValue -Object $sourceArtifact -Name 'recommended_regeneration_command'
$recommendedRepairCommand = Get-OptionalPropertyValue -Object $sourceArtifact -Name 'recommended_repair_command'
$runnerPatchStillRequired = [bool](Get-OptionalPropertyValue -Object $sourceArtifact -Name 'runner_patch_still_required')
$runnerAlreadyWiredNeedsRegeneration = if ($sourceArtifact.PSObject.Properties['runner_already_wired_needs_regeneration']) {
    [bool]$sourceArtifact.runner_already_wired_needs_regeneration
} else {
    [bool]($sourceStatus -eq 'runner-already-wired-regenerate-outputs')
}
$alreadyDirectFromRawPatchTargets = if ($sourceArtifact.PSObject.Properties['already_direct_from_raw_patch_targets']) {
    [bool]$sourceArtifact.already_direct_from_raw_patch_targets
} else {
    [bool]($sourceStatus -eq 'already-direct')
}
$missingRunnerFields = @(Get-ArrayValue -Object $sourceArtifact -Name 'missing_runner_fields')
$summaryPatchSnippetLines = @(Get-ArrayValue -Object $sourceArtifact -Name 'summary_patch_snippet_lines')
$manifestPatchSnippetLines = @(Get-ArrayValue -Object $sourceArtifact -Name 'manifest_patch_snippet_lines')
$recommendedRepoRoot = if ($PSBoundParameters.ContainsKey('RepoRoot')) {
    $resolvedRepoRoot
} else {
    $null
}
$runnerOutputWiringSafeCommand = Format-HelperCommand -ScriptName 'show_google_issue3_runner_output_wiring_status_safe.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
})
$broaderRunnerCommand = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
})
$runnerPatchRulesNotePath = 'docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md'
$postPatchCommand = Get-FirstNonEmptyValue -Values @(
    $recommendedVerificationCommand,
    $runnerOutputWiringSafeCommand,
    $recommendedSourceGuideCommand
)

$status = $null
$reason = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextFocus = $null
$nextArtifactToOpen = $null
if ($runnerPatchStillRequired -or -not [string]::IsNullOrWhiteSpace($recommendedPatchTarget)) {
    $status = 'ready-for-runner-patch-handoff'
    $reason = 'The saved issue #3 patch-route artifact has already narrowed the next replay to a direct runner update, so the next step is to patch the recommended validation runner rather than rerun the raw patch-target helper.'
    $recommendedCommand = $recommendedPatchTarget
    $recommendedGuideCommand = $postPatchCommand
    $nextFocus = 'Open docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md beside the saved patch-handoff artifact, apply the preserved summary and manifest patch snippet lines to the recommended validation runner, rerun the broader issue #3 validation flow, then reopen the safe runner-output wiring audit before trusting the stricter raw wiring helper again.'
    $nextArtifactToOpen = $SourceArtifactPath
} elseif ($alreadyDirectFromRawPatchTargets) {
    $status = 'already-direct'
    $reason = 'The saved issue #3 patch-route artifact says the summary and manifest already carry the direct runner-output contract, so no runner-side patch handoff is needed before reopening the safe wiring audit.'
    $recommendedCommand = $runnerOutputWiringSafeCommand
    $recommendedGuideCommand = $runnerOutputWiringSafeCommand
    $nextFocus = 'Reopen the safe runner-output wiring audit now that the saved outputs already expose the direct contract, and only widen back out if that audit reports a new gap.'
    $nextArtifactToOpen = $SourceArtifactPath
} elseif ($runnerAlreadyWiredNeedsRegeneration) {
    $status = 'runner-already-wired-regenerate-outputs'
    $reason = 'The saved issue #3 patch-route artifact says the live runner source is already wired and the remaining work is to regenerate or repair the saved outputs instead of patching the runner again.'
    $recommendedCommand = Get-FirstNonEmptyValue -Values @(
        $recommendedSourceCommand,
        $recommendedRegenerationCommand,
        $recommendedRepairCommand,
        $broaderRunnerCommand
    )
    $recommendedGuideCommand = $runnerOutputWiringSafeCommand
    $nextFocus = 'Regenerate or repair the saved summary and manifest, then rerun the safe wiring audit before trusting the stricter raw verification command again.'
    $nextArtifactToOpen = $SourceArtifactPath
} else {
    $status = 'follow-source-artifact'
    $reason = Get-FirstNonEmptyValue -Values @(
        (Get-OptionalPropertyValue -Object $sourceArtifact -Name 'reason'),
        'The saved issue #3 patch-route artifact did not narrow the next replay to a direct runner patch, so its current recommended commands should still drive the next Windows follow-up.'
    )
    $recommendedCommand = Get-FirstNonEmptyValue -Values @(
        $recommendedSourceCommand,
        $recommendedRegenerationCommand,
        $recommendedRepairCommand,
        $broaderRunnerCommand
    )
    $recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
        $recommendedSourceGuideCommand,
        $recommendedVerificationCommand,
        $runnerOutputWiringSafeCommand
    )
    $nextFocus = Get-FirstNonEmptyValue -Values @(
        (Get-OptionalPropertyValue -Object $sourceArtifact -Name 'next_focus'),
        'Follow the saved issue #3 patch-route guidance, then reopen this handoff helper after the narrower route has new artifact state to inspect.'
    )
    $nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
        (Get-OptionalPropertyValue -Object $sourceArtifact -Name 'next_artifact_to_open'),
        $SourceArtifactPath
    )
}

$report = [ordered]@{
    issue = 'Google issue #3 runner output patch handoff'
    purpose = 'Turn the saved issue #3 patch-route artifact into an explicit runner patch handoff with the target file, preserved snippet lines, the focused patch-rules note, and the first post-patch audit command.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repo_root = $resolvedRepoRoot
    source_artifact_path = $SourceArtifactPath
    preferred_source_artifact_paths = @($preferredSourceArtifactPaths)
    source_status = $sourceStatus
    artifact_path = $ArtifactPath
    status = $status
    reason = $reason
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    recommended_patch_target = $recommendedPatchTarget
    recommended_reference_note_path = if ($status -eq 'ready-for-runner-patch-handoff') { $runnerPatchRulesNotePath } else { $null }
    recommended_post_patch_command = $postPatchCommand
    recommended_verification_command = $recommendedVerificationCommand
    recommended_regeneration_command = $recommendedRegenerationCommand
    recommended_repair_command = $recommendedRepairCommand
    runner_patch_still_required = [bool]$runnerPatchStillRequired
    runner_already_wired_needs_regeneration = [bool]$runnerAlreadyWiredNeedsRegeneration
    already_direct_from_raw_patch_targets = [bool]$alreadyDirectFromRawPatchTargets
    missing_runner_fields = @($missingRunnerFields)
    summary_patch_snippet_lines = @($summaryPatchSnippetLines)
    manifest_patch_snippet_lines = @($manifestPatchSnippetLines)
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host 'Google issue #3 runner output patch handoff'
Write-Host ''
Write-Host ("Repo root:       {0}" -f $report.repo_root)
Write-Host ("Source artifact: {0}" -f $report.source_artifact_path)
Write-Host ("Artifact:        {0}" -f $report.artifact_path)
Write-Host ("Source status:   {0}" -f $report.source_status)
Write-Host ("Status:          {0}" -f $report.status)
Write-Host ("Runner patch still required: {0}" -f $report.runner_patch_still_required)
Write-Host ("Runner already wired needs regeneration: {0}" -f $report.runner_already_wired_needs_regeneration)
Write-Host ("Already direct from raw patch-targets: {0}" -f $report.already_direct_from_raw_patch_targets)
if ($report.recommended_patch_target) {
    Write-Host ("Patch target:    {0}" -f $report.recommended_patch_target)
}
if ($report.recommended_reference_note_path) {
    Write-Host ("Rules note:      {0}" -f $report.recommended_reference_note_path)
}
Write-Host ("Run:             {0}" -f $report.recommended_command)
Write-Host ("Guide:           {0}" -f $report.recommended_guide_command)
if ($report.recommended_verification_command) {
    Write-Host ("Verify:          {0}" -f $report.recommended_verification_command)
}
if ($report.recommended_regeneration_command) {
    Write-Host ("Rerun:           {0}" -f $report.recommended_regeneration_command)
}
if ($report.recommended_repair_command) {
    Write-Host ("Repair:          {0}" -f $report.recommended_repair_command)
}
if ($report.missing_runner_fields.Count -gt 0) {
    Write-Host 'Missing runner fields:'
    foreach ($fieldName in $report.missing_runner_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
if ($report.summary_patch_snippet_lines.Count -gt 0) {
    Write-Host ''
    Write-Host 'Summary patch snippet:'
    foreach ($line in $report.summary_patch_snippet_lines) {
        Write-Host $line
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
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
