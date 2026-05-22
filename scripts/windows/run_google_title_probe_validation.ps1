[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$SharedInputText = "Q",
    [int]$TitleProbePort = 8159,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 80,
    [int]$HomeTitleWaitAttempts = 30,
    [int]$HomePollMilliseconds = 250
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

$rawProbe = Join-Path $RepoRoot "tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1"
if (-not (Test-Path -LiteralPath $rawProbe -PathType Leaf)) {
    throw "Reduced Google title probe not found: $rawProbe"
}

$arguments = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    Port = $TitleProbePort
    InputText = $SharedInputText
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    WindowReadyAttempts = $HomeWindowReadyAttempts
    TitleWaitAttempts = $HomeTitleWaitAttempts
    PollMilliseconds = $HomePollMilliseconds
}

Write-Host "Google reduced title-probe validation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Host: {0}" -f $Host)
Write-Host ("Shared input text: {0}" -f $SharedInputText)
Write-Host ("Title probe port: {0}" -f $TitleProbePort)
Write-Host ""
Write-Host "=== google-title-localhost ==="
Write-Host ("Script: {0}" -f $rawProbe)
& $rawProbe @arguments

Write-Host ""
Write-Host "Next: if this reduced title probe stays green, reopen the broader shared Enter-order ladder with the same repo-root, browser, host, shared input text, title-probe port, and timing settings through .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1."
