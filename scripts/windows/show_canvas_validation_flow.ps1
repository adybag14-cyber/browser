[CmdletBinding()]
param(
    [string]$RepoRoot = "",
    [string]$BrowserExe = ""
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

if (-not $RepoRoot) {
    $RepoRoot = Resolve-RepoRoot -StartPath $PSScriptRoot
}

$defaultBrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
if (-not $BrowserExe) {
    $BrowserExe = $defaultBrowserExe
}

$isCustomBrowserExe = -not [string]::Equals($BrowserExe, $defaultBrowserExe, [System.StringComparison]::OrdinalIgnoreCase)

function Write-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Host ""
    Write-Host $Title
    Write-Host ("=" * $Title.Length)
}

function Write-Route {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string[]]$Commands,
        [string[]]$Notes = @()
    )

    Write-Host ""
    Write-Host ("[{0}]" -f $Name)
    foreach ($command in $Commands) {
        Write-Host ("  {0}" -f $command)
    }

    foreach ($note in $Notes) {
        Write-Host ("  note: {0}" -f $note)
    }
}

Write-Section "canvas-validation"
Write-Host "Use the smallest canvas smoke probe that matches the change, then widen into the broader rendering lane."
Write-Host ("Repo root: {0}" -f $RepoRoot)
if ($isCustomBrowserExe) {
    Write-Host ("Browser exe: {0}" -f $BrowserExe)
}

Write-Route -Name "canvas-2d" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-render-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-text-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-path-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-drawimage-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-drawimage-image-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-measuretext-probe.ps1"
) -Notes @(
    "Start here for 2D canvas draw, text, path, image, and measureText changes.",
    "Run only the first probe that matches the shared path you changed, then widen if that smaller checkpoint is green."
)

Write-Route -Name "webgl" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-webgl-clear-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-webgl-triangle-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-webgl-indexed-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-webgl-varying-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-webgl-dimensions-probe.ps1"
) -Notes @(
    "Use these when the change touched WebGL clear state, geometry, indexed draw paths, shader varyings, or viewport sizing.",
    "Keep the triangle probe early in the ladder when you want one quick visible proof before widening across the rest of the WebGL helpers."
)

Write-Route -Name "follow-up" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering",
    "& `\"$BrowserExe\"` browse --headed `\"http://127.0.0.1:8166/index.html`\""
) -Notes @(
    "Use the broader rendering route after the matching canvas probe is green and you want the shared headed surface checks reopened.",
    "Use the manual browse command only while a local canvas-smoke server is already running."
)

Write-Host ""
Write-Host "Use docs/HEADED_MODE_VALIDATION_MATRIX.md for the broader subsystem-to-probe map after the canvas ladder stays green."
