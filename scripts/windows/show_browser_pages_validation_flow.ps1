[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-PowerShellSingleQuotedLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Format-RepoFileCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [string[]]$Arguments = @()
    )

    if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
        $command = "powershell -ExecutionPolicy Bypass -File .\\$RelativePath"
    } else {
        $fullPath = Join-Path $RepoRoot ($RelativePath -replace '/', '\\')
        $command = "powershell -ExecutionPolicy Bypass -File " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $fullPath)
    }

    if ($Arguments -and $Arguments.Count -gt 0) {
        $command += " " + ($Arguments -join " ")
    }

    return $command
}

$surfaceCheckCommand = Format-RepoFileCommand -RelativePath "scripts/windows/check_browser_pages_validation_surface.ps1"
$suiteNameCommand = Format-RepoFileCommand -RelativePath "scripts/windows/show_headed_validation_suites.ps1" -Arguments @("-SuiteName", "browser-pages")
$shellChangeAreaCommand = Format-RepoFileCommand -RelativePath "scripts/windows/show_headed_validation_suites.ps1" -Arguments @("-ChangeArea", "shell")
$titleFidelityCommand = Format-RepoFileCommand -RelativePath "tmp-browser-smoke/browser-pages/chrome-browser-pages-title-fidelity-probe.ps1"
$startShellCommand = Format-RepoFileCommand -RelativePath "tmp-browser-smoke/browser-pages/chrome-browser-pages-start-shell-probe.ps1"
$historyFilterCommand = Format-RepoFileCommand -RelativePath "tmp-browser-smoke/browser-pages/chrome-browser-pages-history-filter-probe.ps1"
$bookmarksFilterCommand = Format-RepoFileCommand -RelativePath "tmp-browser-smoke/browser-pages/chrome-browser-pages-bookmarks-filter-probe.ps1"
$downloadsFilterCommand = Format-RepoFileCommand -RelativePath "tmp-browser-smoke/browser-pages/chrome-browser-pages-downloads-filter-probe.ps1"

$flow = [ordered]@{
    profile = "browser-pages"
    repo_root = $RepoRoot
    focus = "Validate headed browser:// shell flows and quick-filter state with the smallest browser-pages probes before widening into larger attached-page or Google-specific replays."
    suite_router_command = $suiteNameCommand
    shell_change_area_command = $shellChangeAreaCommand
    surface_check_command = $surfaceCheckCommand
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the browser-pages docs, helpers, or core probes drifted before you trust the shell-validation route."
            command = $surfaceCheckCommand
        }
        [ordered]@{
            name = "suite-router"
            goal = "Reprint the narrow browser-pages suite from the top-level validation catalog."
            command = $suiteNameCommand
        }
        [ordered]@{
            name = "shell-catalog"
            goal = "Keep the broader shell suite neighbors visible when the issue could cross browser:// pages, tabs, settings, or downloads."
            command = $shellChangeAreaCommand
        }
        [ordered]@{
            name = "title-fidelity"
            goal = "Check generated browser:// titles, Alt+Home homepage routing, and restored internal-tab naming."
            command = $titleFidelityCommand
        }
        [ordered]@{
            name = "start-shell"
            goal = "Check Browser Start navigation links across tabs, history, bookmarks, downloads, settings, and the start-page round trip."
            command = $startShellCommand
        }
        [ordered]@{
            name = "history-filter"
            goal = "Check browser://history quick filtering and filter-clear state restoration."
            command = $historyFilterCommand
        }
        [ordered]@{
            name = "bookmarks-filter"
            goal = "Check browser://bookmarks quick filtering and filter-clear state restoration."
            command = $bookmarksFilterCommand
        }
        [ordered]@{
            name = "downloads-filter"
            goal = "Check browser://downloads quick filtering and filter-clear state restoration."
            command = $downloadsFilterCommand
        }
    )
    notes = @(
        "Use this flow when headed work touches browser:// pages, shell navigation, or filter-state rendering before you widen back into attached HTML or Google-specific investigation.",
        "The title-fidelity and start-shell probes make good first passes when the failure smells like navigation, generated titles, or Browser Start wiring rather than raw text entry.",
        "The history, bookmarks, and downloads probes are intentionally small filter-state checks that catch browser-page regressions without depending on the larger issue #3 input path."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Browser pages validation flow"
Write-Host ""
if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
    Write-Host ("Repo root: {0}" -f $RepoRoot)
    Write-Host ""
}
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Suite router: {0}" -f $flow.suite_router_command)
Write-Host ("Shell change area: {0}" -f $flow.shell_change_area_command)
Write-Host ("Surface check: {0}" -f $flow.surface_check_command)
Write-Host ""
foreach ($step in $flow.steps) {
    Write-Host ("[{0}] {1}" -f $step.name, $step.goal)
    Write-Host ("  {0}" -f $step.command)
    Write-Host ""
}
Write-Host "Notes:"
foreach ($note in $flow.notes) {
    Write-Host ("- {0}" -f $note)
}