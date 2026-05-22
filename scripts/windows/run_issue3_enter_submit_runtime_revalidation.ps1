[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$InputText = "n",
    [int]$SharedEnterOrderPort = 8157,
    [int]$ReducedGoogleProbePort = 9582,
    [int]$SharedEnterOrderServerReadyTimeoutSeconds = 15,
    [int]$SharedEnterOrderWindowReadyAttempts = 60,
    [int]$SharedEnterOrderTitleWaitAttempts = 80,
    [int]$SharedEnterOrderPollMilliseconds = 250,
    [int]$ReducedGoogleProbeTimeoutSeconds = 90,
    [int]$ReducedGoogleProbePollMilliseconds = 250,
    [switch]$SkipSharedEnterOrder,
    [switch]$SkipReducedGoogleProbe,
    [switch]$LeaveOpen,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StartPath
    )

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

function Run-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host ("=== {0} ===" -f $Name)

    $startedAt = (Get-Date).ToUniversalTime().ToString("o")
    & $Action
    $completedAt = (Get-Date).ToUniversalTime().ToString("o")

    return [pscustomobject]@{
        name = $Name
        started_at_utc = $startedAt
        completed_at_utc = $completedAt
        status = "completed"
    }
}

if (-not $RepoRoot) {
    $RepoRoot = Resolve-RepoRoot -StartPath $PSScriptRoot
} else {
    $RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
}

if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

$surfaceCheck = Join-Path $PSScriptRoot "check_google_form_controls_enter_order_validation_surface.ps1"
$sharedRunner = Join-Path $PSScriptRoot "run_google_form_controls_enter_order_validation.ps1"
$reducedProbe = Join-Path $RepoRoot "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1"

foreach ($path in @($surfaceCheck, $sharedRunner, $reducedProbe)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required runtime revalidation helper not found: $path"
    }
}

$steps = [System.Collections.Generic.List[object]]::new()

Write-Host "Issue #3 Enter-submit runtime revalidation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Browser: {0}" -f $BrowserExe)
Write-Host ("Host: {0}" -f $Host)
Write-Host ("Input text: {0}" -f $InputText)
Write-Host ("Shared Enter-order port: {0}" -f $SharedEnterOrderPort)
Write-Host ("Reduced Google probe port: {0}" -f $ReducedGoogleProbePort)

$steps.Add((Run-Step -Name "google-form-controls-enter-order-surface" -Action {
    & $surfaceCheck -RepoRoot $RepoRoot
})) | Out-Null

if (-not $SkipSharedEnterOrder) {
    $steps.Add((Run-Step -Name "google-form-controls-enter-order" -Action {
        & $sharedRunner `
            -RepoRoot $RepoRoot `
            -BrowserExe $BrowserExe `
            -Host $Host `
            -SharedEnterOrderPort $SharedEnterOrderPort `
            -SharedInputText $InputText `
            -ServerReadyTimeoutSeconds $SharedEnterOrderServerReadyTimeoutSeconds `
            -HomeWindowReadyAttempts $SharedEnterOrderWindowReadyAttempts `
            -HomeTitleWaitAttempts $SharedEnterOrderTitleWaitAttempts `
            -HomePollMilliseconds $SharedEnterOrderPollMilliseconds
    })) | Out-Null
}

if (-not $SkipReducedGoogleProbe) {
    $steps.Add((Run-Step -Name "reduced-google-home-title-probe" -Action {
        & $reducedProbe `
            -RepoRoot $RepoRoot `
            -BrowserExe $BrowserExe `
            -InputText $InputText `
            -Port $ReducedGoogleProbePort `
            -TimeoutSeconds $ReducedGoogleProbeTimeoutSeconds `
            -PollMilliseconds $ReducedGoogleProbePollMilliseconds `
            -LeaveOpen:$LeaveOpen
    })) | Out-Null
}

$manualCommand = ".\\zig-out\\bin\\lightpanda.exe browse --browser_mode headed http://127.0.0.1:{0}/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1" -f $ReducedGoogleProbePort

Write-Host ""
Write-Host "Manual reduced-probe replay"
Write-Host "==========================="
Write-Host $manualCommand

if ($Json) {
    [ordered]@{
        profile = "issue3-enter-submit-runtime-revalidation"
        repo_root = $RepoRoot
        browser_exe = $BrowserExe
        host = $Host
        input_text = $InputText
        shared_enter_order_port = $SharedEnterOrderPort
        reduced_google_probe_port = $ReducedGoogleProbePort
        skipped_shared_enter_order = [bool]$SkipSharedEnterOrder
        skipped_reduced_google_probe = [bool]$SkipReducedGoogleProbe
        leave_open = [bool]$LeaveOpen
        steps = @($steps)
        manual_reduced_probe_command = $manualCommand
    } | ConvertTo-Json -Depth 6
}
