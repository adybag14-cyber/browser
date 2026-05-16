[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath = 'saved-summary.json',
    [string[]]$InputPath = @(
        'attached-fixture-a.html',
        'attached-fixture-b.html'
    ),
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'HeadedValidationHelpers.ps1')

function New-FlowCommandCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [bool]$Passed,
        [Parameter(Mandatory = $true)]
        [string]$Details
    )

    return [pscustomobject]@{
        Name = $Name
        Passed = $Passed
        Details = $Details
    }
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$helperRelativePath = 'scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1'
$helperPath = Join-Path $resolvedRepoRoot $helperRelativePath
if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    throw "Replay attached-html helper not found: $helperPath"
}

$helperJson = (& $helperPath -SummaryPath $SummaryPath -InputPath $InputPath -Json) -join [Environment]::NewLine
$helper = $helperJson | ConvertFrom-Json -Depth 10

$commandsToCheck = @(
    [pscustomobject]@{
        Name = 'attached_html_validation_flow'
        Value = $helper.commands.attached_html_validation_flow
    }
    [pscustomobject]@{
        Name = 'google_attached_html_validation_flow'
        Value = $helper.commands.google_attached_html_validation_flow
    }
)

$checks = [System.Collections.Generic.List[object]]::new()
$checks.Add((New-FlowCommandCheck -Name 'helper_summary_path_preserved' -Passed ($helper.summary_path -eq $SummaryPath) -Details 'The replay helper should keep the requested summary path on its own surfaced state.'))
$checks.Add((New-FlowCommandCheck -Name 'explicit_input_path_count_preserved' -Passed ($helper.explicit_input_path_count -eq @($InputPath).Count) -Details 'The replay helper should report the same explicit input-path count that was passed into the check.'))

foreach ($command in $commandsToCheck) {
    $commandName = $command.Name
    $commandValue = "$($command.Value)"

    $checks.Add((New-FlowCommandCheck -Name "$commandName-present" -Passed (-not [string]::IsNullOrWhiteSpace($commandValue)) -Details "The replay helper should emit a non-empty $commandName command."))
    $checks.Add((New-FlowCommandCheck -Name "$commandName-no-summarypath" -Passed (-not ($commandValue -match '(?i)-SummaryPath\b')) -Details "The replay helper should not pass SummaryPath into $commandName because the downstream flow helpers do not accept that parameter."))
    $checks.Add((New-FlowCommandCheck -Name "$commandName-no-array-placeholder" -Passed (-not ($commandValue -match 'System\.(Object|String)\[\]')) -Details "The replay helper should expand each input path in $commandName instead of collapsing the array to a placeholder string."))

    foreach ($path in @($InputPath)) {
        $pathPattern = [regex]::Escape($path)
        $checks.Add((New-FlowCommandCheck -Name "$commandName-includes-$path" -Passed ($commandValue -match $pathPattern) -Details "The replay helper should preserve input path '$path' in $commandName so bundle-pinned replays stay reproducible."))
    }
}

$failures = @($checks | Where-Object { -not $_.Passed })

if ($Json) {
    [ordered]@{
        profile = 'google-issue3-windows-replay-attached-html-flow-command-surface'
        repo_root = $resolvedRepoRoot
        helper_script = $helperRelativePath
        summary_path = $SummaryPath
        input_path = @($InputPath)
        failure_count = @($failures).Count
        checks = @($checks)
        commands = [ordered]@{
            attached_html_validation_flow = $helper.commands.attached_html_validation_flow
            google_attached_html_validation_flow = $helper.commands.google_attached_html_validation_flow
        }
    } | ConvertTo-Json -Depth 6

    if ($failures.Count -gt 0) {
        exit 1
    }

    exit 0
}

Write-Host 'Google issue #3 Windows replay attached-html flow command surface check'
Write-Host ''
Write-Host (("Repo root:     {0}") -f $resolvedRepoRoot)
Write-Host (("Helper script: {0}") -f $helperRelativePath)
Write-Host (("Summary path:  {0}") -f $SummaryPath)
Write-Host (("Input paths:   {0}") -f (@($InputPath).Count))
Write-Host ''

foreach ($check in $checks) {
    $status = if ($check.Passed) { 'PASS' } else { 'FAIL' }
    Write-Host (("[{0}] {1}") -f $status, $check.Name)
    Write-Host (("  {0}") -f $check.Details)
}

Write-Host ''
if ($failures.Count -eq 0) {
    Write-Host 'Google issue #3 Windows replay attached-html flow commands are preserving input context without leaking unsupported SummaryPath arguments.'
    exit 0
}

Write-Host (("Detected {0} replay attached-html flow command surface regression(s).") -f $failures.Count)
Write-Host 'Repair the replay helper before trusting the broader attached-page flow commands for pinned bundle or saved-summary replays.'
exit 1
