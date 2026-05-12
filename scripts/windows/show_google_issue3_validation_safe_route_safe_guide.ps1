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

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json'
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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-validation-safe-route-safe-guide.json'
}

$validationSafeRouteScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_safe_route.ps1'
$validationSafeRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_safe_route.ps1'
$validationSafeRouteSafeGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_safe_route_safe_guide.ps1'
$summaryGuideSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'

if (-not (Test-Path -LiteralPath $validationSafeRouteScript -PathType Leaf)) {
    throw "Issue #3 helper not found: $validationSafeRouteScript"
}

$routeStep = Invoke-JsonHelper -Name 'validation-safe-route' -ScriptPath $validationSafeRouteScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
$routeRecommendedCommand = Get-FirstNonEmptyValue -Values @(
    $routeStep.recommended_command,
    $validationSafeRouteCommand
)
$routeRecommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    $routeStep.recommended_guide_command,
    $summaryGuideSafeCommand
)
$preserveTopLevelGuide = [bool](
    $routeStep.success -and
    -not [string]::IsNullOrWhiteSpace($routeRecommendedCommand) -and
    $routeRecommendedCommand -ne $validationSafeRouteCommand
)

$status = $null
$reason = $null
$nextFocus = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null
if (-not $routeStep.success) {
    $status = 'validation-safe-route-failed'
    $reason = 'The existing issue #3 validation safe route did not finish cleanly, so the next Windows replay should reopen that bounded checkpoint before trusting any narrower guide.'
    $nextFocus = 'Start from the existing validation safe route until it produces a clean bounded recommendation.'
    $recommendedGuideCommand = $validationSafeRouteCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ($preserveTopLevelGuide) {
    $status = 'guide-preserved'
    $reason = 'The existing validation safe route narrowed the next checkpoint to a lower-level helper, so this wrapper keeps the guide field on the top bounded route instead of skipping straight to that narrower guide.'
    $nextFocus = 'Run the recommended command from this wrapper, then reopen this top-level safe-guide wrapper first so the bounded route can confirm whether another narrower checkpoint is still needed.'
    $recommendedGuideCommand = $validationSafeRouteSafeGuideCommand
    $nextArtifactToOpen = $ArtifactPath
} else {
    $status = 'already-self-consistent'
    $reason = 'The existing validation safe route already reports a self-consistent top-level guide, so no additional guide preservation was needed in this pass.'
    $nextFocus = Get-FirstNonEmptyValue -Values @(
        $routeStep.next_focus,
        'Follow the top-level validation safe route guidance before widening back out to lower-level issue #3 helpers.'
    )
    $recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
        $routeStep.recommended_guide_command,
        $validationSafeRouteCommand,
        $summaryGuideSafeCommand
    )
    $nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
        $routeStep.next_artifact_to_open,
        $SummaryPath
    )
}

$report = [ordered]@{
    issue = 'Google issue #3 validation safe-route safe-guide wrapper'
    purpose = 'Preserve the top-level issue #3 validation safe route as the guide entrypoint when that route narrows the next checkpoint to a lower-level helper.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    validation_safe_route_command = $validationSafeRouteCommand
    validation_safe_route_safe_guide_command = $validationSafeRouteSafeGuideCommand
    summary_guide_safe_command = $summaryGuideSafeCommand
    preserves_top_level_guide = [bool]$preserveTopLevelGuide
    recommended_command = $routeRecommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    underlying_recommended_guide_command = $routeRecommendedGuideCommand
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    status = $status
    reason = $reason
    steps = @(
        [ordered]@{
            name = $routeStep.name
            status = $routeStep.status
            success = [bool]$routeStep.success
            exit_code = $routeStep.exit_code
            parse_error = $routeStep.parse_error
            error = $routeStep.error
            recommended_command = $routeStep.recommended_command
            recommended_guide_command = $routeStep.recommended_guide_command
            next_focus = $routeStep.next_focus
            next_artifact_to_open = $routeStep.next_artifact_to_open
            reason = $routeStep.reason
            output_preview = @($routeStep.output_preview)
        }
    )
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    if ($status -eq 'validation-safe-route-failed') {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 validation safe-route safe-guide wrapper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Guide preserved: {0}" -f $report.preserves_top_level_guide)
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
if ($report.underlying_recommended_guide_command) {
    Write-Host ("Underlying guide: {0}" -f $report.underlying_recommended_guide_command)
}

if ($status -eq 'validation-safe-route-failed') {
    exit 1
}
