[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [switch]$SkipSharedGate,
    [string]$Host = "127.0.0.1",
    [int]$SharedEnterOrderPort = 8157,
    [string]$SharedInputText = "Q",
    [string]$HomeInputText = "n",
    [int]$HomeProbePort = 9582,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$WindowReadyAttempts = 60,
    [int]$TitleWaitAttempts = 80,
    [int]$PollMilliseconds = 250,
    [int]$TimeoutSeconds = 90,
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot([string]$StartPath) {
    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor "build.zig")) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            throw "Could not resolve the Lightpanda repo root from $StartPath. Pass -RepoRoot to override."
        }
        $cursor = $parent
    }
}

if (-not $RepoRoot) {
    $RepoRoot = Resolve-RepoRoot $PSScriptRoot
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\\bin\\lightpanda.exe"
}

$surfaceCheck = Join-Path $PSScriptRoot "check_google_form_controls_enter_order_validation_surface.ps1"
$sharedRunner = Join-Path $PSScriptRoot "run_google_form_controls_enter_order_validation.ps1"
$homeProbe = Join-Path $RepoRoot "tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"
$revalidationNote = Join-Path $RepoRoot "docs\\ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"

foreach ($path in @($surfaceCheck, $sharedRunner, $homeProbe, $revalidationNote)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Issue #3 runtime revalidation dependency not found: $path"
    }
}

Write-Host "Issue #3 runtime revalidation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Browser: {0}" -f $BrowserExe)
Write-Host ("Revalidation note: {0}" -f $revalidationNote)
Write-Host ""
Write-Host "=== google-form-controls-enter-order-surface ==="
& $surfaceCheck -RepoRoot $RepoRoot

if (-not $SkipSharedGate) {
    Write-Host ""
    Write-Host "=== google-form-controls-enter-order ==="
    & $sharedRunner `
        -RepoRoot $RepoRoot `
        -BrowserExe $BrowserExe `
        -Host $Host `
        -SharedEnterOrderPort $SharedEnterOrderPort `
        -SharedInputText $SharedInputText `
        -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds `
        -HomeWindowReadyAttempts $WindowReadyAttempts `
        -HomeTitleWaitAttempts $TitleWaitAttempts `
        -HomePollMilliseconds $PollMilliseconds
}

Write-Host ""
Write-Host "=== google-home-title-probe ==="
$homeJson = & $homeProbe `
    -RepoRoot $RepoRoot `
    -BrowserExe $BrowserExe `
    -InputText $HomeInputText `
    -Port $HomeProbePort `
    -TimeoutSeconds $TimeoutSeconds `
    -PollMilliseconds $PollMilliseconds `
    -LeaveOpen:$LeaveOpen
$homeExitCode = $LASTEXITCODE
if ([string]::IsNullOrWhiteSpace($homeJson)) {
    throw "Google home title probe did not return a JSON summary."
}

$homeResult = $homeJson | ConvertFrom-Json
Write-Host ("Home helper outcome: {0}" -f $homeResult.helper_outcome)
Write-Host ("Home helper failure stage: {0}" -f $homeResult.helper_failure_stage)
Write-Host ("Home typed marker: {0}" -f $homeResult.helper_typed_marker)
Write-Host ("Home enter marker: {0}" -f $homeResult.helper_enter_marker)
Write-Host ("Trace artifacts: {0}" -f ((@($homeResult.trace_artifacts)).Count))

if ($homeExitCode -ne 0) {
    exit $homeExitCode
}
