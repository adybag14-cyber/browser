[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [ValidateSet("localhost", "title", "home", "shared", "watch", "manual", "all")]
    [string]$Phase = "all",
    [switch]$IncludeWatch,
    [switch]$IncludeSharedInput,
    [switch]$IncludeTitleProbe,
    [string[]]$ManualInputPath,
    [string]$ManualInitialPage,
    [int]$ManualPort = 8123,
    [switch]$LeaveOpen
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

$probeRoot = Join-Path $RepoRoot "tmp-browser-smoke"
$googleLocalhostRoot = Join-Path $probeRoot "google-investigation-next"
$titleProbe = Join-Path $scriptRoot "run_google_home_title_probe.ps1"
$googleHomeProbe = Join-Path $probeRoot "google-home\chrome-google-home-enter-probe.ps1"
$deferredEnterProbe = Join-Path $probeRoot "form-controls\deferred-enter-submit-probe.ps1"
$formControlsEnterProbe = Join-Path $probeRoot "form-controls\enter-submit-probe.ps1"
$inlineFlowEnterProbe = Join-Path $probeRoot "inline-flow\chrome-inline-break-input-enter-submit-probe.ps1"
$watchProbe = Join-Path $scriptRoot "run_google_home_watch_probe.ps1"
$manualHtmlHelper = Join-Path $scriptRoot "start_staged_localhost_html_validation.ps1"

$localhostProbes = @(
    "google-style-localhost-probe.ps1",
    "google-style-correction-localhost-probe.ps1",
    "google-enter-order-localhost-probe.ps1",
    "google-style-delayed-ready-localhost-probe.ps1"
)

function Invoke-ProbeScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [hashtable]$Arguments
    )

    if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
        throw "Probe script not found: $ScriptPath"
    }

    Write-Host ("")
    Write-Host ("=== {0} ===" -f $Label)
    Write-Host ("Script: {0}" -f $ScriptPath)

    if ($Arguments) {
        & $ScriptPath @Arguments
    } else {
        & $ScriptPath
    }
}

function Invoke-LocalhostSequence {
    foreach ($probeName in $localhostProbes) {
        $scriptPath = Join-Path $googleLocalhostRoot $probeName
        Invoke-ProbeScript -Label $probeName -ScriptPath $scriptPath
    }
}

function Invoke-TitleSequence {
    $args = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
    }
    Invoke-ProbeScript -Label "google-home-title" -ScriptPath $titleProbe -Arguments $args
}

function Invoke-HomeSequence {
    $args = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
    }
    Invoke-ProbeScript -Label "google-home-enter" -ScriptPath $googleHomeProbe -Arguments $args
}

function Invoke-SharedInputSequence {
    $previousRepoRoot = $env:LIGHTPANDA_REPO_ROOT
    $previousBrowserExe = $env:LIGHTPANDA_BROWSER_EXE
    try {
        $env:LIGHTPANDA_REPO_ROOT = $RepoRoot
        $env:LIGHTPANDA_BROWSER_EXE = $BrowserExe
        Invoke-ProbeScript -Label "form-controls-deferred-enter-submit" -ScriptPath $deferredEnterProbe
        Invoke-ProbeScript -Label "form-controls-enter-submit" -ScriptPath $formControlsEnterProbe
    } finally {
        if ($null -eq $previousRepoRoot) {
            Remove-Item Env:LIGHTPANDA_REPO_ROOT -ErrorAction SilentlyContinue
        } else {
            $env:LIGHTPANDA_REPO_ROOT = $previousRepoRoot
        }
        if ($null -eq $previousBrowserExe) {
            Remove-Item Env:LIGHTPANDA_BROWSER_EXE -ErrorAction SilentlyContinue
        } else {
            $env:LIGHTPANDA_BROWSER_EXE = $previousBrowserExe
        }
    }

    $args = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
    }
    Invoke-ProbeScript -Label "inline-flow-enter-submit" -ScriptPath $inlineFlowEnterProbe -Arguments $args
}

function Invoke-WatchSequence {
    $args = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        InputText = "QZ"
        SendEnter = $true
    }
    if ($LeaveOpen) {
        $args.LeaveOpen = $true
    }
    Invoke-ProbeScript -Label "google-home-watch" -ScriptPath $watchProbe -Arguments $args
}

function Invoke-ManualHtmlSequence {
    if (-not $ManualInputPath -or $ManualInputPath.Count -eq 0) {
        throw "ManualInputPath is required when running the manual localhost HTML follow-up."
    }

    $args = @{
        InputPath = $ManualInputPath
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        Port = $ManualPort
        LaunchBrowser = $true
        Wait = $true
    }
    if ($ManualInitialPage) {
        $args.InitialPage = $ManualInitialPage
    }
    if ($LeaveOpen) {
        $args.LeaveServerRunning = $true
    }

    Invoke-ProbeScript -Label "manual-localhost-html" -ScriptPath $manualHtmlHelper -Arguments $args
}

Write-Host "Google headed-input validation runner"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Phase: {0}" -f $Phase)
if ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
    Write-Host ("Manual HTML follow-up: {0}" -f (($ManualInputPath | ForEach-Object { $_ }) -join ", "))
}

switch ($Phase) {
    "localhost" {
        Invoke-LocalhostSequence
    }
    "title" {
        Invoke-TitleSequence
    }
    "home" {
        Invoke-HomeSequence
    }
    "shared" {
        Invoke-SharedInputSequence
    }
    "watch" {
        Invoke-WatchSequence
    }
    "manual" {
        Invoke-ManualHtmlSequence
    }
    "all" {
        Invoke-LocalhostSequence
        if ($IncludeTitleProbe) {
            Invoke-TitleSequence
        }
        Invoke-HomeSequence
        if ($IncludeSharedInput) {
            Invoke-SharedInputSequence
        }
        if ($IncludeWatch) {
            Invoke-WatchSequence
        }
        if ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
            Invoke-ManualHtmlSequence
        }
    }
}

Write-Host ("")
if ($Phase -eq "manual") {
    Write-Host "Next: compare any saved-page failures with the reduced localhost and bounded homepage probes before moving on to the smallest live Google manual pass."
} elseif ($Phase -eq "shared") {
    Write-Host "Next: return to -Phase home or -Phase watch once the deferred/basic form-controls and inline-flow probes are green."
} elseif ($Phase -eq "title") {
    Write-Host "Next: use -Phase home for the reduced homepage Enter pass, or run -Phase all -IncludeTitleProbe to put the quick headed title check at the front of the shared flow."
} elseif ($Phase -eq "watch" -or $IncludeWatch) {
    if ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
        Write-Host "Next: use the saved-page localhost session to compare attached-page behavior with the reduced homepage watcher before the smallest live Google manual pass."
    } else {
        Write-Host "Next: move on to the smallest live Google manual pass once the self-starting watcher confirms SUBMIT:QZ."
    }
} elseif ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
    Write-Host "Next: use the saved-page localhost session to compare attached-page behavior with the reduced Google and shared-input probes before the smallest live Google manual pass."
} elseif ($IncludeSharedInput -and $IncludeTitleProbe) {
    Write-Host "Next: if the quick title probe, reduced Google pass, deferred/basic form-controls, and inline-flow probes stay green, move on to the smallest live Google manual pass."
} elseif ($IncludeSharedInput) {
    Write-Host "Next: if the reduced Google, deferred/basic form-controls, and inline-flow probes stay green, move on to the smallest live Google manual pass."
} elseif ($IncludeTitleProbe) {
    Write-Host "Next: if the quick title probe and reduced Google pass stay green, add -IncludeSharedInput or move on to the smallest live Google manual pass."
} else {
    Write-Host "Next: use -IncludeTitleProbe for the quick headed title pass, -IncludeSharedInput for the deferred/basic form-controls plus inline-flow checks, -IncludeWatch for the self-starting title-stream pass, or -ManualInputPath for the saved localhost HTML follow-up before the smallest live Google manual check."
}
