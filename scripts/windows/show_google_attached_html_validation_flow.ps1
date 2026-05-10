[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "PageRoot")]
    [string]$PageRoot,

    [Parameter(ParameterSetName = "InputPath")]
    [string[]]$InputPath,

    [string]$PreferredInitialPage,
    [int]$Port = 8123,
    [switch]$Json,
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$helper = Join-Path $PSScriptRoot "show_saved_page_google_validation_flow.ps1"
if (-not (Test-Path -LiteralPath $helper -PathType Leaf)) {
    throw "Google-style attached HTML flow helper not found: $helper"
}

$arguments = @{
    Port = $Port
    ManualGoogleStyle = $true
}
if ($PreferredInitialPage) {
    $arguments.PreferredInitialPage = $PreferredInitialPage
}
if ($Json) {
    $arguments.Json = $true
}
if ($LeaveOpen) {
    $arguments.LeaveOpen = $true
}

if (-not $Json) {
    Write-Host "Google-style attached HTML validation flow"
    Write-Host ""
    Write-Host "Mode: attached HTML auto-discovery with the Google-style localhost follow-up"
    switch ($PSCmdlet.ParameterSetName) {
        "PageRoot" {
            Write-Host ("Mode detail: explicit page root ({0})" -f $PageRoot)
        }
        "InputPath" {
            Write-Host ("Mode detail: explicit saved HTML inputs ({0})" -f $InputPath.Count)
        }
        default {
            Write-Host "Mode detail: auto-discover attached HTML under user_files first, then agent_files."
        }
    }
    if ($PreferredInitialPage) {
        Write-Host ("Preferred initial page override: {0}" -f $PreferredInitialPage)
    }
    Write-Host "Override: use -PreferredInitialPage to keep one Google-like page first, or pass -PageRoot / -InputPath to skip auto-discovery."
    Write-Host "Helper: .\scripts\windows\show_saved_page_google_validation_flow.ps1 -ManualGoogleStyle"
    Write-Host ""
}

switch ($PSCmdlet.ParameterSetName) {
    "PageRoot" {
        & $helper @arguments -PageRoot $PageRoot
        exit $LASTEXITCODE
    }
    "InputPath" {
        & $helper @arguments -InputPath $InputPath
        exit $LASTEXITCODE
    }
    default {
        & $helper @arguments
        exit $LASTEXITCODE
    }
}
