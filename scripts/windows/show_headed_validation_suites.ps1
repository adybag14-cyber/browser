param(
    [ValidateSet("", "google-recommended")]
    [string]$SuiteName = "",
    [ValidateSet("", "attached-html", "attached-html-target-bundle", "google-attached-html", "google-input", "input", "navigation")]
    [string]$ChangeArea = "",
    [string]$RepoRoot = "",
    [string]$BrowserExe = "",
    [string]$InputPath = ""
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

if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

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

function Get-ManualAttachedHtmlRoute {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetInputPath
    )

    $resolved = Resolve-Path -LiteralPath $TargetInputPath -ErrorAction Stop
    $item = Get-Item -LiteralPath $resolved -ErrorAction Stop
    $root = if ($item.PSIsContainer) { $item.FullName } else { $item.DirectoryName }
    $page = if ($item.PSIsContainer) {
        "<page.html>"
    } else {
        $item.Name
    }

    return @(
        "cd `"$root`"",
        "python -m http.server 8123 --bind 127.0.0.1",
        "& `"$BrowserExe`" browse --headed --window_width 1366 --window_height 900 `"http://127.0.0.1:8123/$page`""
    )
}

function Get-AttachedHtmlNotes {
    $notes = @(
        "This branch does not yet include the wrapper-heavy attached HTML helper chain referenced by some older notes.",
        "Use a simple localhost server and headed browse for saved-page follow-up until those wrappers are committed.",
        "If a saved page has a sibling *_files directory, keep it beside the HTML file while serving localhost."
    )

    if ($InputPath) {
        $notes += "The commands below are expanded for the provided -InputPath."
    } else {
        $notes += "Pass -InputPath to print ready-to-run localhost commands for a specific saved page or bundle folder."
    }

    return $notes
}

function Show-DefaultRoutes {
    Write-Section "Headed Validation Suites"
    Write-Host "Use the smallest bounded check first, then widen into manual headed follow-up."

    Write-Route -Name "navigation" -Commands @(
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-history-probe.ps1",
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-reload-probe.ps1"
    ) -Notes @(
        "These probes exercise headed navigation, back, forward, and reload on localhost fixtures.",
        "Repo root resolves automatically from this script unless -RepoRoot overrides it."
    )

    Write-Route -Name "input" -Commands @(
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
    ) -Notes @(
        "These are the current bounded input checks already committed on this branch.",
        "Use them before live-site or saved-page follow-up."
    )

    $attachedCommands = if ($InputPath) {
        Get-ManualAttachedHtmlRoute -TargetInputPath $InputPath
    } else {
        @(
            "cd <folder-containing-exported-html>",
            "python -m http.server 8123 --bind 127.0.0.1",
            "& `"$BrowserExe`" browse --headed --window_width 1366 --window_height 900 `"http://127.0.0.1:8123/<page.html>`""
        )
    }

    Write-Route -Name "attached-html" -Commands $attachedCommands -Notes (Get-AttachedHtmlNotes)

    Write-Route -Name "google-recommended" -Commands @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input",
        "& `"$BrowserExe`" browse --headed `"https://www.google.com/`"",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html -InputPath <saved-html-or-folder>"
    ) -Notes @(
        "Use the bounded input probe first, then live Google, then the saved-page localhost follow-up that matches issue #3 triage."
    )
}

switch ($true) {
    { $SuiteName -eq "google-recommended" } {
        Write-Section "google-recommended"
        Write-Route -Name "google-recommended" -Commands @(
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
            "& `"$BrowserExe`" browse --headed `"https://www.google.com/`""
        ) -Notes @(
            "Use the form-controls Enter-submit probe to confirm shared headed typing and submit behavior first.",
            "After that, verify Google homepage typing, focus retention, and Enter submit manually."
        )

        Write-Route -Name "google-attached-html-follow-up" -Commands (
            if ($InputPath) { Get-ManualAttachedHtmlRoute -TargetInputPath $InputPath } else {
                @(
                    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html -InputPath <saved-html-or-folder>"
                )
            }
        ) -Notes (Get-AttachedHtmlNotes)
        break
    }
    { $ChangeArea -eq "input" -or $ChangeArea -eq "google-input" } {
        Write-Section $ChangeArea
        Write-Route -Name "bounded-input" -Commands @(
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
        ) -Notes @(
            "These probes are the smallest shared headed checks for typing, focus, and Enter submit."
        )

        if ($ChangeArea -eq "google-input") {
            Write-Route -Name "manual-google" -Commands @(
                "& `"$BrowserExe`" browse --headed `"https://www.google.com/`""
            ) -Notes @(
                "Use this after the bounded input probes are green."
            )
        }
        break
    }
    { $ChangeArea -eq "navigation" } {
        Write-Section "navigation"
        Write-Route -Name "wrapped-link" -Commands @(
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-history-probe.ps1",
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-reload-probe.ps1"
        ) -Notes @(
            "Use these for headed navigation, history, and reload behavior on bounded localhost pages."
        )
        break
    }
    { $ChangeArea -eq "attached-html" -or $ChangeArea -eq "google-attached-html" -or $ChangeArea -eq "attached-html-target-bundle" } {
        Write-Section $ChangeArea
        $commands = if ($InputPath) {
            Get-ManualAttachedHtmlRoute -TargetInputPath $InputPath
        } else {
            @(
                "cd <folder-containing-exported-html>",
                "python -m http.server 8123 --bind 127.0.0.1",
                "& `"$BrowserExe`" browse --headed --window_width 1366 --window_height 900 `"http://127.0.0.1:8123/<page.html>`""
            )
        }
        Write-Route -Name "manual-localhost-follow-up" -Commands $commands -Notes (Get-AttachedHtmlNotes)
        break
    }
    default {
        Show-DefaultRoutes
        break
    }
}
