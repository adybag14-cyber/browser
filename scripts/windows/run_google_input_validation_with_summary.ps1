[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$SummaryPath,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RunnerArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

$runner = Join-Path $PSScriptRoot "run_google_input_validation.ps1"
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw "Google input validation runner not found: $runner"
}

$artifactRoot = Join-Path $RepoRoot "tmp-browser-smoke\headed-probe"
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $artifactRoot "google-input-validation-summary.json"
}

$summaryDirectory = Split-Path -Parent $SummaryPath
if (-not [string]::IsNullOrWhiteSpace($summaryDirectory)) {
    New-Item -ItemType Directory -Force -Path $summaryDirectory | Out-Null
}

$logPath = [System.IO.Path]::ChangeExtension($SummaryPath, ".log")
if (Test-Path -LiteralPath $SummaryPath) {
    Remove-Item -LiteralPath $SummaryPath -Force
}
if (Test-Path -LiteralPath $logPath) {
    Remove-Item -LiteralPath $logPath -Force
}

function Test-RunnerSwitch {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Args,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    foreach ($arg in $Args) {
        if ([string]::Equals($arg, $Name, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function Get-RunnerArgumentValue {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Args,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        $Default = $null
    )

    for ($i = 0; $i -lt $Args.Count; $i++) {
        if (-not [string]::Equals($Args[$i], $Name, [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }

        $nextIndex = $i + 1
        if ($nextIndex -ge $Args.Count) {
            return $Default
        }

        $nextValue = $Args[$nextIndex]
        if ($nextValue.StartsWith("-")) {
            return $Default
        }

        return $nextValue
    }

    return $Default
}

function Get-RunnerArgumentValues {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Args,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $values = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $Args.Count; $i++) {
        if (-not [string]::Equals($Args[$i], $Name, [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }

        for ($j = $i + 1; $j -lt $Args.Count; $j++) {
            $candidate = $Args[$j]
            if ($candidate.StartsWith("-")) {
                break
            }
            $values.Add($candidate) | Out-Null
        }
        break
    }

    return @($values)
}

$startedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
$completed = $false
$runnerError = $null

try {
    & $runner -RepoRoot $RepoRoot -BrowserExe $BrowserExe @RunnerArgs *>&1 |
        Tee-Object -FilePath $logPath -Append
    $completed = $true
} catch {
    $runnerError = $_.Exception.Message
    $errorRecordText = ($_ | Out-String).TrimEnd()
    if (-not [string]::IsNullOrWhiteSpace($errorRecordText)) {
        Add-Content -Path $logPath -Value ""
        Add-Content -Path $logPath -Value $errorRecordText
    }
}

$completedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
$phase = Get-RunnerArgumentValue -Args $RunnerArgs -Name "-Phase" -Default "all"
$manualPort = Get-RunnerArgumentValue -Args $RunnerArgs -Name "-ManualPort" -Default "8123"
$manualInitialPage = Get-RunnerArgumentValue -Args $RunnerArgs -Name "-ManualInitialPage"
$manualInputPath = @(Get-RunnerArgumentValues -Args $RunnerArgs -Name "-ManualInputPath")
$nextStepsHint = $null

if (Test-Path -LiteralPath $logPath) {
    $nextLine = @(
        Get-Content -LiteralPath $logPath |
            Where-Object { $_ -like "Next:*" } |
            Select-Object -Last 1
    )
    if ($nextLine.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($nextLine[0])) {
        $nextStepsHint = $nextLine[0].Substring(5).Trim()
    }
}

$summary = [pscustomobject]@{
    generated_at_utc = $completedAtUtc
    started_at_utc = $startedAtUtc
    completed_at_utc = $completedAtUtc
    repo_root = $RepoRoot
    browser_exe = $BrowserExe
    runner_script = $runner
    runner_arguments = @($RunnerArgs)
    phase = $phase
    include_watch = [bool](Test-RunnerSwitch -Args $RunnerArgs -Name "-IncludeWatch")
    include_shared_input = [bool](Test-RunnerSwitch -Args $RunnerArgs -Name "-IncludeSharedInput")
    include_shared_enter_order = [bool](Test-RunnerSwitch -Args $RunnerArgs -Name "-IncludeSharedEnterOrder")
    include_title_probe = [bool](Test-RunnerSwitch -Args $RunnerArgs -Name "-IncludeTitleProbe")
    leave_open = [bool](Test-RunnerSwitch -Args $RunnerArgs -Name "-LeaveOpen")
    manual_google_style = [bool](Test-RunnerSwitch -Args $RunnerArgs -Name "-ManualGoogleStyle")
    manual_port = $manualPort
    manual_initial_page = $manualInitialPage
    manual_input_path = @($manualInputPath)
    summary_path = $SummaryPath
    log_path = $logPath
    next_steps_hint = $nextStepsHint
    completed = $completed
    error = $runnerError
}

$summary | ConvertTo-Json -Depth 6 | Set-Content -Path $SummaryPath -Encoding Ascii
Write-Host ("Summary JSON: {0}" -f $SummaryPath)
Write-Host ("Summary log: {0}" -f $logPath)

if (-not $completed) {
    throw ("Google input validation failed. Summary JSON: {0}" -f $SummaryPath)
}
