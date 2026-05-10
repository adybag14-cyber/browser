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
    [int]$SharedLabelPort = 8153,
    [int]$InlineFlowPort = 8148,
    [int]$ReducedHomeKeypressPort = 8167,
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
$reducedHomeKeypressProbe = Join-Path $RepoRoot "tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1"
$localhostEnterOrderProbe = Join-Path $RepoRoot "tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1"
$formControlsEnterOrderProbe = Join-Path $RepoRoot "tmp-browser-smoke\form-controls\enter-submit-probe.ps1"

if (-not (Test-Path -LiteralPath $sharedRunner -PathType Leaf)) {
    throw "Shared Google validation runner not found: $sharedRunner"
}
if (-not (Test-Path -LiteralPath $reducedHomeKeypressProbe -PathType Leaf)) {
    throw "Reduced Google homepage keypress-submit probe not found: $reducedHomeKeypressProbe"
}
if (-not (Test-Path -LiteralPath $localhostEnterOrderProbe -PathType Leaf)) {
    throw "Google enter-order localhost probe not found: $localhostEnterOrderProbe"
}
if (-not (Test-Path -LiteralPath $formControlsEnterOrderProbe -PathType Leaf)) {
    throw "Canonical shared form-controls enter-order probe not found: $formControlsEnterOrderProbe"
}

$sharedArgs = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Phase = "shared"
    Host = $Host
    SharedInputText = $SharedInputText
    SharedLabelPort = $SharedLabelPort
    SharedDefaultPort = $SharedDefaultPort
    SharedDeferredPort = $SharedDeferredPort
    SharedReducedGooglePort = $SharedReducedGooglePort
    InlineFlowPort = $InlineFlowPort
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    HomeWindowReadyAttempts = $HomeWindowReadyAttempts
    HomeTitleWaitAttempts = $HomeTitleWaitAttempts
    HomePollMilliseconds = $HomePollMilliseconds
}

$reducedHomeKeypressArgs = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    Port = $ReducedHomeKeypressPort
    InputText = $SharedInputText
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    WindowReadyAttempts = $HomeWindowReadyAttempts
    TitleWaitAttempts = $HomeTitleWaitAttempts
    PollMilliseconds = $HomePollMilliseconds
}

$localhostEnterOrderArgs = @{
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

$formControlsEnterOrderArgs = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    Port = $SharedEnterOrderPort
    InputText = $SharedInputText
    GoogleEnterOrder = $true
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    WindowReadyAttempts = $HomeWindowReadyAttempts
    TitleWaitAttempts = $HomeTitleWaitAttempts
    PollMilliseconds = $HomePollMilliseconds
}

Write-Host "Google shared Enter-order validation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Host: {0}" -f $Host)
Write-Host ("Shared input text: {0}" -f $SharedInputText)
Write-Host ("Shared label port: {0}" -f $SharedLabelPort)
Write-Host ("Reduced-home keypress port: {0}" -f $ReducedHomeKeypressPort)
Write-Host ("Shared Enter-order port: {0}" -f $SharedEnterOrderPort)
Write-Host ""

& $sharedRunner @sharedArgs

Write-Host ""
Write-Host "=== google-home-keypress-submit ==="
Write-Host ("Script: {0}" -f $reducedHomeKeypressProbe)
& $reducedHomeKeypressProbe @reducedHomeKeypressArgs

Write-Host ""
Write-Host "=== google-enter-order-localhost ==="
Write-Host ("Script: {0}" -f $localhostEnterOrderProbe)
& $localhostEnterOrderProbe @localhostEnterOrderArgs

Write-Host ""
Write-Host "=== form-controls-google-enter-order ==="
Write-Host ("Script: {0}" -f $formControlsEnterOrderProbe)
& $formControlsEnterOrderProbe @formControlsEnterOrderArgs

Write-Host ""
Write-Host "Next: if the shared gates, reduced-home keypress-before-submit probe, shared form-controls Enter-order probe, and localhost Enter-order wrapper stay green, move on to the smallest live Google manual pass."
