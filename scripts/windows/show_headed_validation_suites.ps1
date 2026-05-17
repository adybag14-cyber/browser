param(
    [ValidateSet("", "google-recommended")]
    [string]$SuiteName = "",
    [ValidateSet("", "attached-html", "attached-html-target-bundle", "google-attached-html", "google-input", "input", "manual-html", "navigation", "network", "rendering")]
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
        "If a saved page has a sibling *_files directory, keep it beside the HTML file while serving localhost.",
        "The broader attached-page helper remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1.",
        "The manual-html, rendering, and network change areas currently collapse back to this same attached-html localhost route on the live branch."
    )

    if ($InputPath) {
        $notes += "The commands below are expanded for the provided -InputPath."
    } else {
        $notes += "Pass -InputPath to print ready-to-run localhost commands for a specific saved page or bundle folder."
    }

    return $notes
}

function Add-SharedArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        $Value
    )

    if ($null -eq $Value) {
        return
    }
    if ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    $Arguments.Add("-$Name")
    if ($Value -is [string]) {
        $Arguments.Add("'" + ($Value -replace "'", "''") + "'")
    } else {
        $Arguments.Add([string]$Value)
    }
}

function Add-SharedPathArrayArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string[]]$Values
    )

    if (-not $Values -or $Values.Count -eq 0) {
        return
    }

    $Arguments.Add("-$Name")
    foreach ($value in $Values) {
        $Arguments.Add("'" + ($value -replace "'", "''") + "'")
    }
}

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [System.Collections.Generic.List[string]]$Arguments
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\$ScriptName"
    if ($Arguments -and $Arguments.Count -gt 0) {
        $command += " " + ($Arguments -join ' ')
    }

    return $command
}

$issue3AttachedHtmlArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $issue3AttachedHtmlArguments -Name RepoRoot -Value $RepoRoot
if ($InputPath) {
    Add-SharedPathArrayArgument -Arguments $issue3AttachedHtmlArguments -Name InputPath -Values @($InputPath)
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
        (Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $issue3AttachedHtmlArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $issue3AttachedHtmlArguments)
    ) -Notes @(
        "Use the bounded input probe first, then live Google, then the shorter issue #3 attached-page helper surface before falling back to the broader manual localhost replay.",
        "Pass -InputPath when you already want the top-level attached-page quickstart or bundle-first helper pinned to a saved page or the current three-page compatibility bundle."
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

        Write-Route -Name "issue3-attached-html-follow-up" -Commands @(
            (Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $issue3AttachedHtmlArguments),
            (Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $issue3AttachedHtmlArguments)
        ) -Notes @(
            "Use the top-level attached-page quickstart when the next step is saved-page follow-up on the shorter issue #3 helper ladder.",
            "Use the bundle-first helper when the replay should stay pinned to the known three-page compatibility set or when -InputPath already fixes the bundle inputs."
        )
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

            Write-Route -Name "issue3-attached-html-follow-up" -Commands @(
                (Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $issue3AttachedHtmlArguments),
                (Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $issue3AttachedHtmlArguments)
            ) -Notes @(
                "Use the top-level attached-page quickstart when the next step is saved-page follow-up on the shorter issue #3 helper ladder.",
                "Use the bundle-first helper when the replay should stay pinned to the known three-page compatibility set or when -InputPath already fixes the bundle inputs."
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
    { $ChangeArea -eq "attached-html" -or $ChangeArea -eq "attached-html-target-bundle" -or $ChangeArea -eq "google-attached-html" -or $ChangeArea -eq "manual-html" -or $ChangeArea -eq "network" -or $ChangeArea -eq "rendering" } {
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
