[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [switch]$SkipBaseline,
    [switch]$KeepGoing,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $scriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

$recommendedRunner = Join-Path $scriptRoot "run_form_controls_validation_recommended.ps1"
if (-not (Test-Path -LiteralPath $recommendedRunner -PathType Leaf)) {
    throw "Recommended form-controls runner not found: $recommendedRunner"
}

$runnerArgs = @{}
if ($RepoRoot) {
    $runnerArgs.RepoRoot = $RepoRoot
}
if ($BrowserExe) {
    $runnerArgs.BrowserExe = $BrowserExe
}
if ($Host) {
    $runnerArgs.Host = $Host
}
if ($SkipBaseline) {
    $runnerArgs.SkipBaseline = $true
}
if ($KeepGoing) {
    $runnerArgs.KeepGoing = $true
}

$rawOutput = $null
$parsed = $null
$exitCode = 0
try {
    $rawOutput = & $recommendedRunner @runnerArgs 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
} catch {
    $rawOutput = $_.Exception.Message
    $exitCode = 1
}

if (-not [string]::IsNullOrWhiteSpace($rawOutput)) {
    try {
        $parsed = $rawOutput | ConvertFrom-Json -ErrorAction Stop
    } catch {
    }
}

$summary = [ordered]@{
    issue = 3
    lane = "Validation and regression control"
    runner = $recommendedRunner
    repo_root = $RepoRoot
    browser_exe = $BrowserExe
    host = $Host
    skip_baseline = [bool]$SkipBaseline
    keep_going = [bool]$KeepGoing
    ok = ($exitCode -eq 0)
    next_step = "If these shared form-controls gates are green, run scripts/windows/run_google_shared_enter_order_validation.ps1 before the smallest live Google trace or manual pass."
    result = $parsed
}

if ($Json) {
    if (-not $parsed -and -not [string]::IsNullOrWhiteSpace($rawOutput)) {
        $summary.raw_output = $rawOutput.Trim()
    }
    $summary | ConvertTo-Json -Depth 10
    exit $exitCode
}

Write-Host "Google form-controls validation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Host: {0}" -f $Host)
Write-Host ("Runner: {0}" -f $recommendedRunner)
Write-Host ""

if ($parsed -and $parsed.probes) {
    foreach ($probe in $parsed.probes) {
        $status = if ($probe.ok) { "ok" } else { "fail" }
        Write-Host ("- {0}: {1}" -f $probe.name, $status)
        if ($probe.error) {
            Write-Host ("  error: {0}" -f $probe.error)
        }
    }
} elseif (-not [string]::IsNullOrWhiteSpace($rawOutput)) {
    Write-Host $rawOutput.Trim()
}

Write-Host ""
Write-Host $summary.next_step

exit $exitCode
