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

function Invoke-JsonHelper {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $startedAt = (Get-Date).ToUniversalTime().ToString('o')
    $output = @()
    $exitCode = 0
    $errorMessage = $null
    $parseError = $null
    $record = $null

    try {
        $output = @(
            & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1
        )
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            $errorMessage = "Helper exited with code $exitCode."
        }
    } catch {
        $exitCode = 1
        $errorMessage = $_.Exception.Message
    }

    $outputLines = @($output | ForEach-Object { "${_}" })
    $outputText = ($outputLines -join [Environment]::NewLine).Trim()
    if (-not [string]::IsNullOrWhiteSpace($outputText)) {
        try {
            $record = $outputText | ConvertFrom-Json
        } catch {
            $parseError = $_.Exception.Message
        }
    }

    $stepStatus = if ($record -and (Test-HasProperty -Object $record -Name 'status')) {
        $record.status
    } elseif ($parseError) {
        'non-json-output'
    } elseif ($exitCode -eq 0) {
        'completed-no-json'
    } else {
        'helper-failed'
    }

    return [pscustomobject]@{
        name = $Name
        script_path = $ScriptPath
        arguments = @($Arguments)
        started_at_utc = $startedAt
        completed_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        exit_code = $exitCode
        success = [bool]($exitCode -eq 0 -and $null -ne $record)
        status = $stepStatus
        parse_error = $parseError
        error = $errorMessage
        output_preview = @($outputLines | Select-Object -First 16)
        recommended_command = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'recommended_command' } else { $null }
        recommended_guide_command = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'recommended_guide_command' } else { $null }
        next_focus = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'next_focus' } else { $null }
        next_artifact_to_open = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'next_artifact_to_open' } else { $null }
        reason = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'reason' } else { $null }
        record = $record
    }
}

function New-SkippedHelperStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [string]$RecommendedCommand,
        [string]$RecommendedGuideCommand,
        [string]$NextFocus,
        [string]$NextArtifactToOpen,
        [string]$Reason
    )

    $timestamp = (Get-Date).ToUniversalTime().ToString('o')
    return [pscustomobject]@{
        name = $Name
        script_path = $ScriptPath
        arguments = @($Arguments)
        started_at_utc = $timestamp
        completed_at_utc = $timestamp
        exit_code = 0
        success = $true
        status = 'skipped-by-route'
        parse_error = $null
        error = $null
        output_preview = @()
        recommended_command = $RecommendedCommand
        recommended_guide_command = $RecommendedGuideCommand
        next_focus = $NextFocus
        next_artifact_to_open = $NextArtifactToOpen
        reason = $Reason
        record = $null
    }
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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-validation-manifest-safe-path-route.json'
}

$manifestSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_manifest_safe.ps1'
$manifestPathCoherencyScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_manifest_path_coherency.ps1'
$manifestSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest_safe.ps1'
$manifestPathCoherencyCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest_path_coherency.ps1'
$manifestGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest.ps1'
$summaryGuideSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'

foreach ($helperPath in @($manifestSafeScript, $manifestPathCoherencyScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$steps = [System.Collections.Generic.List[object]]::new()
$manifestSafeStep = Invoke-JsonHelper -Name 'manifest-safe' -ScriptPath $manifestSafeScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
$steps.Add($manifestSafeStep) | Out-Null

$readyForManifestGuide = [bool]($manifestSafeStep.success -and $manifestSafeStep.recommended_command -eq $manifestGuideCommand)
$shouldRunManifestPathCoherency = [bool]$readyForManifestGuide
$manifestPathCoherencyStep = $null
if ($shouldRunManifestPathCoherency) {
    $manifestPathCoherencyStep = Invoke-JsonHelper -Name 'manifest-path-coherency' -ScriptPath $manifestPathCoherencyScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
} else {
    $manifestPathCoherencyStep = New-SkippedHelperStep -Name 'manifest-path-coherency' -ScriptPath $manifestPathCoherencyScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -RecommendedCommand $(Get-FirstNonEmptyValue -Values @($manifestSafeStep.recommended_command, $manifestSafeCommand)) -RecommendedGuideCommand $(Get-FirstNonEmptyValue -Values @($manifestSafeStep.recommended_guide_command, $summaryGuideSafeCommand)) -NextFocus $(Get-FirstNonEmptyValue -Values @($manifestSafeStep.next_focus, 'Use the current manifest-safe guidance; the extra manifest path-coherency checkpoint is only needed when the safe helper says the raw manifest guide is ready.')) -NextArtifactToOpen $(Get-FirstNonEmptyValue -Values @($manifestSafeStep.next_artifact_to_open, $SummaryPath)) -Reason 'The manifest-safe checkpoint did not route the next replay back to the raw manifest guide, so the extra manifest path-coherency helper was not reopened yet.'
}
$steps.Add($manifestPathCoherencyStep) | Out-Null

$status = $null
$reason = $null
if (-not $manifestSafeStep.success) {
    $status = 'manifest-safe-failed'
    $reason = 'The manifest-safe helper did not finish cleanly, so the next Windows replay should start from that safer checkpoint before widening back out.'
} elseif ($shouldRunManifestPathCoherency -and -not $manifestPathCoherencyStep.success) {
    $status = 'manifest-path-coherency-failed'
    $reason = 'The manifest-safe helper reported that the raw manifest guide was ready, but the path-coherency checkpoint did not finish cleanly, so the next replay should reopen that bounded audit directly.'
} elseif ($shouldRunManifestPathCoherency -and $manifestPathCoherencyStep.status -eq 'coherent') {
    $status = 'ready-for-manifest-guide'
    $reason = 'The manifest-safe helper cleared the strict-mode prerequisites and the manifest path-coherency helper confirmed the saved manifest still points at the same artifacts as the current summary.'
} elseif ($shouldRunManifestPathCoherency) {
    $status = 'manifest-path-follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        $manifestPathCoherencyStep.reason,
        'The manifest-safe helper completed, but the path-coherency checkpoint still has a narrower follow-up for the next Windows replay.'
    )
} else {
    $status = 'manifest-safe-follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        $manifestSafeStep.reason,
        'The manifest-safe helper completed, but the next replay still needs the safer follow-up it reported before the raw manifest path audit should run.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunManifestPathCoherency) { $manifestPathCoherencyStep.recommended_command },
    $manifestSafeStep.recommended_command,
    if ($shouldRunManifestPathCoherency) { $manifestPathCoherencyCommand },
    $manifestSafeCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($readyForManifestGuide -and $manifestPathCoherencyStep.status -eq 'coherent') { $manifestGuideCommand },
    if ($shouldRunManifestPathCoherency) { $manifestPathCoherencyStep.recommended_guide_command },
    $manifestSafeStep.recommended_guide_command,
    $summaryGuideSafeCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunManifestPathCoherency) { $manifestPathCoherencyStep.next_focus },
    $manifestSafeStep.next_focus,
    if ($shouldRunManifestPathCoherency) { 'Use the manifest path-coherency guidance produced in this run before reopening the raw manifest guide.' }
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunManifestPathCoherency) { $manifestPathCoherencyStep.next_artifact_to_open },
    $manifestSafeStep.next_artifact_to_open,
    $SummaryPath
)

$report = [ordered]@{
    issue = 'Google issue #3 manifest safe path route'
    purpose = 'Run the issue #3 manifest-safe checkpoint first and, when it says the raw manifest guide is ready, immediately reopen the manifest path-coherency audit so the next Windows replay can continue from the narrowest trustworthy manifest checkpoint.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    manifest_safe_command = $manifestSafeCommand
    manifest_path_coherency_command = $manifestPathCoherencyCommand
    manifest_guide_command = $manifestGuideCommand
    summary_guide_safe_command = $summaryGuideSafeCommand
    manifest_path_follow_up_ran = [bool]$shouldRunManifestPathCoherency
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    status = $status
    reason = $reason
    steps = @($steps | ForEach-Object {
        [ordered]@{
            name = $_.name
            status = $_.status
            success = [bool]$_.success
            exit_code = $_.exit_code
            parse_error = $_.parse_error
            error = $_.error
            recommended_command = $_.recommended_command
            recommended_guide_command = $_.recommended_guide_command
            next_focus = $_.next_focus
            next_artifact_to_open = $_.next_artifact_to_open
            reason = $_.reason
            output_preview = @($_.output_preview)
        }
    })
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    if (@('manifest-safe-failed', 'manifest-path-coherency-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 manifest safe path route'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Path follow-up ran: {0}" -f $report.manifest_path_follow_up_ran)
Write-Host ''
foreach ($step in $report.steps) {
    $marker = if ($step.success) { 'PASS' } else { 'FAIL' }
    Write-Host ("[{0}] {1} -> {2}" -f $marker, $step.name, $step.status)
    if ($step.error) {
        Write-Host ("  Error: {0}" -f $step.error)
    }
    if ($step.parse_error) {
        Write-Host ("  Parse error: {0}" -f $step.parse_error)
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)

if (@('manifest-safe-failed', 'manifest-path-coherency-failed') -contains $status) {
    exit 1
}
