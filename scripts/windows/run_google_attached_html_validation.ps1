[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "PageRoot")]
    [string]$PageRoot,

    [Parameter(ParameterSetName = "InputPath")]
    [string[]]$InputPath,

    [string]$PreferredInitialPage,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8123,
    [switch]$SummaryOnly,
    [switch]$Wait,
    [switch]$LeaveServerRunning
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$runner = Join-Path $PSScriptRoot "run_localhost_html_validation_recommended.ps1"
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw "Google-style attached HTML validation runner not found: $runner"
}

$arguments = @{
    Host = $Host
    Port = $Port
    GoogleStyle = $true
}
if ($RepoRoot) {
    $arguments.RepoRoot = $RepoRoot
}
if ($BrowserExe) {
    $arguments.BrowserExe = $BrowserExe
}
if ($PreferredInitialPage) {
    $arguments.PreferredInitialPage = $PreferredInitialPage
}
if ($SummaryOnly) {
    $arguments.SummaryOnly = $true
}
if ($Wait) {
    $arguments.Wait = $true
}
if ($LeaveServerRunning) {
    $arguments.LeaveServerRunning = $true
}

Write-Host "Google-style attached HTML validation"
Write-Host ""
Write-Host "Mode: attached HTML auto-discovery with the Google-style localhost follow-up"
if ($PreferredInitialPage) {
    Write-Host ("Preferred initial page override: {0}" -f $PreferredInitialPage)
}
Write-Host "Runner: .\scripts\windows\run_localhost_html_validation_recommended.ps1 -GoogleStyle"
Write-Host ""

switch ($PSCmdlet.ParameterSetName) {
    "PageRoot" {
        & $runner @arguments -PageRoot $PageRoot
        exit $LASTEXITCODE
    }
    "InputPath" {
        & $runner @arguments -InputPath $InputPath
        exit $LASTEXITCODE
    }
    default {
        & $runner @arguments
        exit $LASTEXITCODE
    }
}
