[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$SharedEnterOrderPort = 8157,
    [string]$SharedInputText = "Q",
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 60,
    [int]$HomeTitleWaitAttempts = 80,
    [int]$HomePollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

$surfaceCheck = Join-Path $PSScriptRoot "check_google_form_controls_enter_order_validation_surface.ps1"
$runner = Join-Path $RepoRoot "tmp-browser-smoke\form-controls\google-enter-order-probe.ps1"
if (-not (Test-Path -LiteralPath $surfaceCheck -PathType Leaf)) {
    throw "Google form-controls Enter-order validation surface checker not found: $surfaceCheck"
}
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw "Dedicated Google form-controls Enter-order probe not found: $runner"
}

$surfaceCheckArgs = @{
    RepoRoot = $RepoRoot
}

$arguments = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    Port = $SharedEnterOrderPort
    InputText = $SharedInputText
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    WindowReadyAttempts = $HomeWindowReadyAttempts
    TitleWaitAttempts = $HomeTitleWaitAttempts
    PollMilliseconds = $HomePollMilliseconds
}

Write-Host "Google form-controls Enter-order validation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Host: {0}" -f $Host)
Write-Host ("Shared input text: {0}" -f $SharedInputText)
Write-Host ("Shared Enter-order port: {0}" -f $SharedEnterOrderPort)
Write-Host ""
Write-Host "=== google-form-controls-enter-order-surface ==="
Write-Host ("Script: {0}" -f $surfaceCheck)
& $surfaceCheck @surfaceCheckArgs

Write-Host ""
Write-Host "=== google-form-controls-enter-order ==="
Write-Host ("Script: {0}" -f $runner)
& $runner @arguments
