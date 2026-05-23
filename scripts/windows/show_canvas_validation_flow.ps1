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
Write-Host "Use the checkout-portable canvas ladder first, then widen into broader rendering or older deeper canvas probes."
Write-Host ("Repo root: {0}" -f $RepoRoot)
if ($isCustomBrowserExe) {
    Write-Host ("Browser exe: {0}" -f $BrowserExe)
}

Write-Route -Name "portable-surface" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_canvas_validation_surface.ps1",
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_canvas_validation.ps1"
) -Notes @(
    "Start here when you want the current branch-safe canvas surface check plus the bounded render, text, drawImage, and WebGL clear ladder on one runner.",
    "Use the dedicated runner before older individual probe scripts so the current checkout-safe route stays first in the validation order."
)

Write-Route -Name "portable-canvas-2d" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-render-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-text-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-drawimage-checkout-probe.ps1"
) -Notes @(
    "Use these when you want the smallest checkout-portable 2D canvas proof without widening into the full runner.",
    "Prefer the checkout drawImage probe here because it resolves the current repo root and browser binary instead of assuming the original Windows checkout path."
)

Write-Route -Name "portable-webgl" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-webgl-clear-probe.ps1"
) -Notes @(
    "Use this for the first visible WebGL clear-state proof on the current checkout before you reopen broader rendering follow-up."
)

Write-Route -Name "deeper-follow-up" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-path-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-drawimage-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-drawimage-image-probe.ps1",
    "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\canvas-smoke\chrome-canvas-measuretext-probe.ps1"
) -Notes @(
    "Use these only after the checkout-portable surface is green or when you intentionally want the older deeper canvas helpers.",
    "Some of these deeper helpers still reflect the original Windows checkout layout, so normalize repo-root or browser-exe assumptions before treating a path failure as a browser regression."
)

Write-Route -Name "follow-up" -Commands @(
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering",
    "& `\"$BrowserExe\"` browse --headed `\"http://127.0.0.1:8166/index.html`\""
) -Notes @(
    "Use the broader rendering route after the matching canvas probe or the bounded canvas runner is green and you want the shared headed surface checks reopened.",
    "Use the manual browse command only while a local canvas-smoke server is already running."
)

if ($isCustomBrowserExe) {
    Write-Host ""
    Write-Host ("Current browser override is pinned to: {0}" -f $BrowserExe)
    Write-Host "Rerun run_canvas_validation.ps1 with -BrowserExe if you want the same non-default binary kept across the full canvas ladder."
}

Write-Host ""
Write-Host "Use docs/HEADED_MODE_VALIDATION_MATRIX.md for the broader subsystem-to-probe map after the checkout-portable canvas ladder stays green."