[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$InputText = "lightpanda",
    [int]$TraceWindowReadyAttempts = 80,
    [int]$TracePollMilliseconds = 250,
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

$surfaceCheck = Join-Path $PSScriptRoot "check_google_trace_validation_surface.ps1"
$flowHelper = Join-Path $PSScriptRoot "show_google_trace_validation_flow.ps1"
$runner = Join-Path $PSScriptRoot "run_google_input_validation.ps1"

if (-not (Test-Path -LiteralPath $surfaceCheck -PathType Leaf)) {
    throw "Google trace validation surface checker not found: $surfaceCheck"
}
if (-not (Test-Path -LiteralPath $flowHelper -PathType Leaf)) {
    throw "Google trace validation flow helper not found: $flowHelper"
}
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw "Google input validation runner not found: $runner"
}

$surfaceCheckArgs = @{
    RepoRoot = $RepoRoot
}

$arguments = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Phase = "trace"
    Host = $Host
    TraceInputText = $InputText
    TraceWindowReadyAttempts = $TraceWindowReadyAttempts
    TracePollMilliseconds = $TracePollMilliseconds
}
if ($LeaveOpen) {
    $arguments.LeaveOpen = $true
}

Write-Host "Google trace validation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Host: {0}" -f $Host)
Write-Host ("Trace input text: {0}" -f $InputText)
Write-Host ("Trace window-ready attempts: {0}" -f $TraceWindowReadyAttempts)
Write-Host ("Trace poll milliseconds: {0}" -f $TracePollMilliseconds)
Write-Host ""
Write-Host "This runner is for the later issue #3 trace handoff after the bounded localhost, reduced homepage, submit-timing, and shared Enter-order gates are green."
Write-Host ("If the later trace path diverges, print the dedicated flow helper at {0} before widening back out." -f $flowHelper)
Write-Host ""

Write-Host "=== google-trace-surface ==="
Write-Host ("Script: {0}" -f $surfaceCheck)
& $surfaceCheck @surfaceCheckArgs

Write-Host ""
Write-Host "=== google-trace ==="
Write-Host ("Script: {0}" -f $runner)
& $runner @arguments

Write-Host ""
Write-Host ("Next: compare the reduced-home and live Google trace output with the nearest bounded submit-timing and shared Enter-order checkpoints before editing the headed input path. Use {0} when you want the full read-first trace ladder printed before another rerun." -f $flowHelper)
