[CmdletBinding()]
param(
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

$repoRoot = Resolve-RepoRoot $PSScriptRoot
$artifactRoot = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe'
$rulesNotePath = 'docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md'
$runnerPatchTarget = 'scripts/windows/run_google_issue3_recommended_validation.ps1'
$generatePatchArtifactCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1'
$postPatchSafeAuditCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$postPatchRawAuditCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$postPatchRerunCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$preferredArtifacts = @(
    'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-safe-route-runner-patch-handoff.json',
    'tmp-browser-smoke\headed-probe\google-issue3-runner-output-patch-handoff.json',
    'tmp-browser-smoke\headed-probe\google-issue3-runner-output-patch-targets-safe-route.json',
    'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-repair-runner-output-patch-targets.json'
)
if (-not $SourceArtifactPath) {
    $resolvedArtifact = $preferredArtifacts |
        ForEach-Object { Join-Path $repoRoot $_ } |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
        Select-Object -First 1
    if ($resolvedArtifact) {
        $SourceArtifactPath = $resolvedArtifact
    } else {
        $SourceArtifactPath = Join-Path $repoRoot $preferredArtifacts[0]
    }
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-runner-patch-rules.json'
}

$sourceArtifact = $null
$sourceArtifactExists = Test-Path -LiteralPath $SourceArtifactPath -PathType Leaf
if ($sourceArtifactExists) {
    $sourceArtifact = Get-Content -LiteralPath $SourceArtifactPath -Raw | ConvertFrom-Json
}

$sourceStatus = if ($sourceArtifact) {
    Get-OptionalPropertyValue -Object $sourceArtifact -Name 'status'
} else {
    $null
}
$sourceRecommendedCommand = if ($sourceArtifact) {
    Get-OptionalPropertyValue -Object $sourceArtifact -Name 'recommended_command'
} else {
    $null
}
$sourceRecommendedGuideCommand = if ($sourceArtifact) {
    Get-OptionalPropertyValue -Object $sourceArtifact -Name 'recommended_guide_command'
} else {
    $null
}
$sourceRecommendedVerificationCommand = if ($sourceArtifact) {
    Get-OptionalPropertyValue -Object $sourceArtifact -Name 'recommended_verification_command'
} else {
    $null
}
$sourceRecommendedRegenerationCommand = if ($sourceArtifact) {
    Get-OptionalPropertyValue -Object $sourceArtifact -Name 'recommended_regeneration_command'
} else {
    $null
}
$sourceRecommendedRepairCommand = if ($sourceArtifact) {
    Get-OptionalPropertyValue -Object $sourceArtifact -Name 'recommended_repair_command'
} else {
    $null
}
$sourceRecommendedPatchTarget = if ($sourceArtifact) {
    Get-OptionalPropertyValue -Object $sourceArtifact -Name 'recommended_patch_target'
} else {
    $null
}
$sourceRunnerPatchStillRequired = if ($sourceArtifact) {
    [bool](Get-OptionalPropertyValue -Object $sourceArtifact -Name 'runner_patch_still_required')
} else {
    $false
}
$sourceAlreadyDirect = if ($sourceArtifact -and $sourceArtifact.PSObject.Properties['already_direct_from_raw_patch_targets']) {
    [bool]$sourceArtifact.already_direct_from_raw_patch_targets
} elseif ($sourceStatus -eq 'already-direct') {
    $true
} else {
    $false
}
$sourceRunnerAlreadyWiredNeedsRegeneration = if ($sourceArtifact -and $sourceArtifact.PSObject.Properties['runner_already_wired_needs_regeneration']) {
    [bool]$sourceArtifact.runner_already_wired_needs_regeneration
} elseif ($sourceStatus -eq 'runner-already-wired-regenerate-outputs') {
    $true
} else {
    $false
}
$missingRunnerFields = if ($sourceArtifact) {
    @(Get-ArrayValue -Object $sourceArtifact -Name 'missing_runner_fields')
} else {
    @()
}
$summaryPatchSnippetLines = if ($sourceArtifact) {
    @(Get-ArrayValue -Object $sourceArtifact -Name 'summary_patch_snippet_lines')
} else {
    @()
}
$manifestPatchSnippetLines = if ($sourceArtifact) {
    @(Get-ArrayValue -Object $sourceArtifact -Name 'manifest_patch_snippet_lines')
} else {
    @()
}

$readyForRunnerPatch = $false
if ($sourceArtifactExists) {
    $readyForRunnerPatch = [bool](
        $sourceRunnerPatchStillRequired -or
        -not [string]::IsNullOrWhiteSpace($sourceRecommendedPatchTarget) -or
        $sourceStatus -eq 'ready-for-runner-patch' -or
        $sourceStatus -eq 'ready-for-runner-patch-handoff' -or
        $sourceStatus -eq 'patch-targets-ready'
    )
}

$status = $null
$reason = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextFocus = $null
$nextArtifactToOpen = $null
if (-not $sourceArtifactExists) {
    $status = 'patch-artifact-missing'
    $reason = 'No current issue #3 runner-patch artifact was found in the preferred order, so the next replay should regenerate the safe-route patch handoff before attempting a direct runner edit.'
    $recommendedCommand = $generatePatchArtifactCommand
    $recommendedGuideCommand = $rulesNotePath
    $nextFocus = 'Regenerate the newest issue #3 patch handoff artifact first, then reopen this helper so the runner patch target and preserved snippet lines come from current saved outputs.'
    $nextArtifactToOpen = $SourceArtifactPath
} elseif ($sourceAlreadyDirect) {
    $status = 'already-direct'
    $reason = 'The newest issue #3 patch artifact already says the saved outputs carry the direct runner-output contract, so a source patch is not the next step.'
    $recommendedCommand = $postPatchSafeAuditCommand
    $recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
        $sourceRecommendedVerificationCommand,
        $sourceRecommendedGuideCommand,
        $postPatchRawAuditCommand
    )
    $nextFocus = 'Reopen the safe runner-output wiring audit instead of another direct runner patch, and only widen back out if that audit reports a fresh gap.'
    $nextArtifactToOpen = $SourceArtifactPath
} elseif ($sourceRunnerAlreadyWiredNeedsRegeneration) {
    $status = 'runner-already-wired-regenerate-outputs'
    $reason = 'The newest issue #3 patch artifact says the live runner source is already wired and the remaining work is to regenerate or repair saved outputs before another patch attempt.'
    $recommendedCommand = Get-FirstNonEmptyValue -Values @(
        $sourceRecommendedRegenerationCommand,
        $sourceRecommendedRepairCommand,
        $sourceRecommendedCommand,
        $generatePatchArtifactCommand
    )
    $recommendedGuideCommand = $postPatchSafeAuditCommand
    $nextFocus = 'Regenerate or repair the saved summary and manifest, then reopen the safe wiring audit before considering another runner patch.'
    $nextArtifactToOpen = $SourceArtifactPath
} elseif ($readyForRunnerPatch) {
    $status = 'ready-for-runner-patch-rules'
    $reason = 'The newest issue #3 patch artifact has already narrowed the next replay to a direct runner edit, so the next step is to open the focused rules note beside the preserved snippet lines and patch the recommended validation runner.'
    $recommendedCommand = $null
    $recommendedGuideCommand = $postPatchSafeAuditCommand
    $nextFocus = 'Open the rules note and the newest patch artifact together, copy the preserved summary and manifest snippet lines into the recommended validation runner, rerun the runner, then reopen the safe wiring audit.'
    $nextArtifactToOpen = $SourceArtifactPath
} else {
    $status = 'follow-source-artifact'
    $reason = Get-FirstNonEmptyValue -Values @(
        if ($sourceArtifact) { Get-OptionalPropertyValue -Object $sourceArtifact -Name 'reason' },
        'The newest issue #3 patch artifact has not yet narrowed the replay to a direct runner patch, so the next Windows follow-up should keep using its current guidance.'
    )
    $recommendedCommand = Get-FirstNonEmptyValue -Values @(
        $sourceRecommendedCommand,
        $sourceRecommendedRegenerationCommand,
        $sourceRecommendedRepairCommand,
        $generatePatchArtifactCommand
    )
    $recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
        $sourceRecommendedGuideCommand,
        $sourceRecommendedVerificationCommand,
        $rulesNotePath
    )
    $nextFocus = Get-FirstNonEmptyValue -Values @(
        if ($sourceArtifact) { Get-OptionalPropertyValue -Object $sourceArtifact -Name 'next_focus' },
        'Follow the current issue #3 patch artifact guidance, then reopen this helper after the narrower route has fresh saved state to inspect.'
    )
    $nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
        if ($sourceArtifact) { Get-OptionalPropertyValue -Object $sourceArtifact -Name 'next_artifact_to_open' },
        $SourceArtifactPath
    )
}

$report = [ordered]@{
    issue = 'Google issue #3 runner patch rules entrypoint'
    purpose = 'Turn the newest issue #3 runner-patch artifact into an explicit patch-entry handoff with the focused rules note, patch target, preferred artifact order, and post-patch audit commands.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    artifact_path = $ArtifactPath
    source_artifact_path = $SourceArtifactPath
    source_artifact_exists = [bool]$sourceArtifactExists
    source_status = $sourceStatus
    status = $status
    reason = $reason
    rules_note_path = $rulesNotePath
    recommended_patch_target = Get-FirstNonEmptyValue -Values @(
        $sourceRecommendedPatchTarget,
        if ($readyForRunnerPatch) { $runnerPatchTarget }
    )
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    post_patch_commands = @(
        $postPatchRerunCommand,
        $postPatchSafeAuditCommand,
        $postPatchRawAuditCommand
    )
    preferred_artifact_order = @($preferredArtifacts)
    runner_patch_still_required = [bool]$sourceRunnerPatchStillRequired
    ready_for_runner_patch = [bool]$readyForRunnerPatch
    runner_already_wired_needs_regeneration = [bool]$sourceRunnerAlreadyWiredNeedsRegeneration
    already_direct_from_raw_patch_targets = [bool]$sourceAlreadyDirect
    missing_runner_fields = @($missingRunnerFields)
    summary_patch_snippet_lines = @($summaryPatchSnippetLines)
    manifest_patch_snippet_lines = @($manifestPatchSnippetLines)
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    if ($status -eq 'patch-artifact-missing') {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 runner patch rules entrypoint'
Write-Host ''
Write-Host ("Artifact:        {0}" -f $report.artifact_path)
Write-Host ("Source artifact: {0}" -f $report.source_artifact_path)
Write-Host ("Source status:   {0}" -f $report.source_status)
Write-Host ("Status:          {0}" -f $report.status)
Write-Host ("Rules note:      {0}" -f $report.rules_note_path)
if ($report.recommended_patch_target) {
    Write-Host ("Patch target:    {0}" -f $report.recommended_patch_target)
}
if ($report.recommended_command) {
    Write-Host ("Run now:         {0}" -f $report.recommended_command)
}
if ($report.recommended_guide_command) {
    Write-Host ("Guide next:      {0}" -f $report.recommended_guide_command)
}
Write-Host ''
Write-Host 'Preferred artifact order:'
foreach ($artifact in $report.preferred_artifact_order) {
    Write-Host ("- {0}" -f $artifact)
}
Write-Host ''
Write-Host 'Post-patch audit order:'
foreach ($command in $report.post_patch_commands) {
    Write-Host ("- {0}" -f $command)
}
if ($report.missing_runner_fields.Count -gt 0) {
    Write-Host ''
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

if ($status -eq 'patch-artifact-missing') {
    exit 1
}
