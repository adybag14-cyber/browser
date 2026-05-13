[CmdletBinding()]
param(
    [string]$RepoRoot,
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

function Format-HelperCommandWithRepoRootEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [hashtable]$Arguments = @{},
        [string]$RepoRootOverride
    )

    if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        return Format-HelperCommand -ScriptName $ScriptName -Arguments $Arguments
    }

    $command = "& '.\\scripts\\windows\\$ScriptName'"
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

    $escapedRepoRoot = ("$RepoRootOverride") -replace "'", "''"
    return "powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$env:LIGHTPANDA_REPO_ROOT = '$escapedRepoRoot'; $command`""
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

$repoRoot = if ($RepoRoot) {
    $RepoRoot
} else {
    Resolve-RepoRoot $PSScriptRoot
}
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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-validation-refresh-status-safe-path-route.json'
}
$shouldPreserveRepoRoot = $PSBoundParameters.ContainsKey('RepoRoot') -or -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)
$recommendedRepoRoot = if ($shouldPreserveRepoRoot) {
    $repoRoot
} else {
    $null
}
$recommendedSummaryPath = if ($PSBoundParameters.ContainsKey('SummaryPath')) {
    $SummaryPath
} else {
    $null
}

$refreshStatusSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_refresh_status_safe.ps1'
$refreshStatusScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_refresh_status.ps1'
$refreshStatusSafeCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_refresh_status_safe.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$refreshStatusCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_refresh_status.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$handoffSafeCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_handoff_safe.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$summaryGuideSafeCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_summary_guide_safe.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot

$refreshStatusSafeHelperArguments = @()
if ($PSBoundParameters.ContainsKey('RepoRoot')) {
    $refreshStatusSafeHelperArguments += @('-RepoRoot', $repoRoot)
}
$refreshStatusSafeHelperArguments += @('-SummaryPath', $SummaryPath, '-Json')

$refreshStatusHelperArguments = @()
if ($PSBoundParameters.ContainsKey('RepoRoot')) {
    $refreshStatusHelperArguments += @('-RepoRoot', $repoRoot)
}
$refreshStatusHelperArguments += @('-SummaryPath', $SummaryPath, '-Json')

foreach ($helperPath in @($refreshStatusSafeScript, $refreshStatusScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$steps = [System.Collections.Generic.List[object]]::new()
$refreshStatusSafeStep = Invoke-JsonHelper -Name 'refresh-status-safe' -ScriptPath $refreshStatusSafeScript -Arguments $refreshStatusSafeHelperArguments
$steps.Add($refreshStatusSafeStep) | Out-Null

$shouldRunRawRefreshStatus = [bool]($refreshStatusSafeStep.success -and $refreshStatusSafeStep.status -eq 'safe-to-run-existing-helper')
$refreshStatusStep = $null
if ($shouldRunRawRefreshStatus) {
    $refreshStatusStep = Invoke-JsonHelper -Name 'refresh-status' -ScriptPath $refreshStatusScript -Arguments $refreshStatusHelperArguments
} else {
    $refreshStatusStep = New-SkippedHelperStep -Name 'refresh-status' -ScriptPath $refreshStatusScript -Arguments $refreshStatusHelperArguments -RecommendedCommand $(Get-FirstNonEmptyValue -Values @($refreshStatusSafeStep.recommended_command, $refreshStatusSafeCommand)) -RecommendedGuideCommand $(Get-FirstNonEmptyValue -Values @($refreshStatusSafeStep.recommended_guide_command, $summaryGuideSafeCommand)) -NextFocus $(Get-FirstNonEmptyValue -Values @($refreshStatusSafeStep.next_focus, 'Use the current refresh-status-safe guidance; the raw refresh-status helper should only reopen after the safe checkpoint says the saved artifacts are ready.')) -NextArtifactToOpen $(Get-FirstNonEmptyValue -Values @($refreshStatusSafeStep.next_artifact_to_open, $SummaryPath)) -Reason 'The refresh-status-safe checkpoint did not report safe-to-run-existing-helper, so the raw refresh-status helper was not reopened yet.'
}
$steps.Add($refreshStatusStep) | Out-Null

$status = $null
$reason = $null
if (-not $refreshStatusSafeStep.success) {
    $status = 'refresh-status-safe-failed'
    $reason = 'The refresh-status-safe helper did not finish cleanly, so the next Windows replay should start from that safer checkpoint before widening back out.'
} elseif ($shouldRunRawRefreshStatus -and -not $refreshStatusStep.success) {
    $status = 'refresh-status-helper-failed'
    $reason = 'The refresh-status-safe helper reported that the raw refresh-status helper was ready, but the raw helper did not finish cleanly, so the next replay should reopen that bounded refresh-status audit directly.'
} elseif ($shouldRunRawRefreshStatus -and $refreshStatusStep.status -eq 'ready') {
    $status = 'ready-for-handoff-safe'
    $reason = 'The refresh-status-safe helper cleared the strict-mode prerequisites and the raw refresh-status helper completed with ready status, so the next Windows replay can continue from the narrower handoff-safe checkpoint it surfaced.'
} elseif ($shouldRunRawRefreshStatus) {
    $status = 'refresh-status-follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        $refreshStatusStep.reason,
        'The refresh-status-safe helper completed, but the raw refresh-status helper still has a narrower follow-up for the next Windows replay.'
    )
} else {
    $status = 'refresh-status-safe-follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        $refreshStatusSafeStep.reason,
        'The refresh-status-safe helper completed, but the next replay still needs the safer follow-up it reported before the raw refresh-status helper should run.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunRawRefreshStatus) { $refreshStatusStep.recommended_command },
    $refreshStatusSafeStep.recommended_command,
    if ($shouldRunRawRefreshStatus) { $refreshStatusCommand },
    $refreshStatusSafeCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunRawRefreshStatus -and $refreshStatusStep.status -eq 'ready') { $handoffSafeCommand },
    if ($shouldRunRawRefreshStatus) { $refreshStatusStep.recommended_guide_command },
    $refreshStatusSafeStep.recommended_guide_command,
    $summaryGuideSafeCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunRawRefreshStatus) { $refreshStatusStep.next_focus },
    $refreshStatusSafeStep.next_focus,
    if ($shouldRunRawRefreshStatus) { 'Use the raw refresh-status guidance produced in this run before reopening the next narrower handoff step.' }
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunRawRefreshStatus) { $refreshStatusStep.next_artifact_to_open },
    $refreshStatusSafeStep.next_artifact_to_open,
    $SummaryPath
)

$report = [ordered]@{
    issue = 'Google issue #3 refresh status safe path route'
    purpose = 'Run the issue #3 refresh-status-safe checkpoint first and, when it says the raw refresh-status helper is ready, immediately reopen that raw helper so the next Windows replay can continue from the narrowest trustworthy refresh checkpoint.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repo_root = $repoRoot
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    refresh_status_safe_command = $refreshStatusSafeCommand
    refresh_status_command = $refreshStatusCommand
    handoff_safe_command = $handoffSafeCommand
    summary_guide_safe_command = $summaryGuideSafeCommand
    raw_refresh_status_follow_up_ran = [bool]$shouldRunRawRefreshStatus
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
    if (@('refresh-status-safe-failed', 'refresh-status-helper-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 refresh status safe path route'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Raw refresh follow-up ran: {0}" -f $report.raw_refresh_status_follow_up_ran)
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

if (@('refresh-status-safe-failed', 'refresh-status-helper-failed') -contains $status) {
    exit 1
}
