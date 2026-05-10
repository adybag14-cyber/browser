[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$SharedInputText = "Q",
    [string]$EnterMutationSuffix = "!",
    [int]$SharedDefaultPort = 8154,
    [int]$SharedDeferredPort = 8155,
    [int]$SharedReducedGooglePort = 8156,
    [int]$SharedEnterOrderPort = 8157,
    [int]$InlineFlowPort = 8148,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 60,
    [int]$HomeTitleWaitAttempts = 80,
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

$sharedRunner = Join-Path $scriptRoot "run_google_input_validation.ps1"
$enterOrderProbe = Join-Path $RepoRoot "tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1"

if (-not (Test-Path -LiteralPath $sharedRunner -PathType Leaf)) {
    throw "Shared Google validation runner not found: $sharedRunner"
}
if (-not (Test-Path -LiteralPath $enterOrderProbe -PathType Leaf)) {
    throw "Google enter-order probe not found: $enterOrderProbe"
}

$sharedArgs = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Phase = "shared"
    Host = $Host
    SharedInputText = $SharedInputText
    SharedDefaultPort = $SharedDefaultPort
    SharedDeferredPort = $SharedDeferredPort
    SharedReducedGooglePort = $SharedReducedGooglePort
    InlineFlowPort = $InlineFlowPort
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    HomeWindowReadyAttempts = $HomeWindowReadyAttempts
    HomeTitleWaitAttempts = $HomeTitleWaitAttempts
    HomePollMilliseconds = $HomePollMilliseconds
}

$enterOrderArgs = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    Port = $SharedEnterOrderPort
    InputText = $SharedInputText
    EnterMutationSuffix = $EnterMutationSuffix
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    WindowReadyAttempts = $HomeWindowReadyAttempts
    TitleWaitAttempts = $HomeTitleWaitAttempts
    PollMilliseconds = $HomePollMilliseconds
}

Write-Host "Google shared Enter-order validation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Host: {0}" -f $Host)
Write-Host ("Shared input text: {0}" -f $SharedInputText)
Write-Host ("Shared enter-order port: {0}" -f $SharedEnterOrderPort)
Write-Host ""

& $sharedRunner @sharedArgs

Write-Host ""
Write-Host "=== google-enter-order-localhost ==="
Write-Host ("Script: {0}" -f $enterOrderProbe)
& $enterOrderProbe @enterOrderArgs

Write-Host ""
Write-Host "Next: if the shared gates and the enter-order localhost probe stay green, move on to the smallest live Google manual pass."
