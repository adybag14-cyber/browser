[CmdletBinding()]
param(
    [ValidateSet("", "google-form-controls-enter-order", "google-recommended")]
    [string]$SuiteName = "",
    [ValidateSet("", "attached-html", "attached-html-target-bundle", "google-attached-html", "google-form-controls-enter-order", "google-input", "input", "manual-html", "navigation", "network", "rendering", "stop-loading")]
    [string]$ChangeArea = "",
    [string]$RepoRoot = "",
    [string]$BrowserExe = "",
    [string]$SummaryPath = "",
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

function Get-AttachedHtmlNotes {
    $notes = @(
        "Run the attached-pages sidecar audit first so missing sibling _files directories are visible before the browser is blamed.",
        "Run the attached-pages asset audit second so missing local assets stay visible before the browser is blamed.",
        "After the sidecar audit passes, reuse -RequireCompleteSidecars when you want the manifest or localhost catalog launch to fail fast on incomplete saved-page bundles.",
        "Use the attached-pages catalog wrapper to pin the current HTML bundle and expose short localhost routes at /, /manifest.json, /pages/<n>, /named/<slug>, and /raw/... .",
        "The broader attached-page helper remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1.",
        "The Google-shaped attached-page helper remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1.",
        "The issue #3 top-level attached-page helper remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_quickstart.ps1.",
        "The shorter issue #3 attached-page change-area quickstart remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_change_area_quickstart.ps1.",
        "The dedicated issue #3 validation-router attached-html surface checker remains available at powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1.",
        "The manual-html change area still reuses this attached-pages catalog route when you want a direct saved-page replay without a narrower bounded family.",
        "Start the catalog in one shell, then open the generated catalog or a manifest-backed short route from a second shell."
    )

    if ($InputPath) {
        $notes += "The commands below reuse the provided -InputPath across the audit, manifest, and catalog launch steps."
    } else {
        $notes += "Pass -InputPath to pin the audit, manifest, and catalog commands to a specific saved page or bundle folder."
    }

    if ($isCustomBrowserExe) {
        $notes += "Current browser override: $BrowserExe"
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

function Get-AttachedHtmlCatalogCommand {
    param(
        [string]$TargetInputPath,
        [switch]$GoogleStyle,
        [string[]]$ExtraSwitches = @()
    )

    $arguments = [System.Collections.Generic.List[string]]::new()
    if ($GoogleStyle) {
        $arguments.Add('-GoogleStyle')
    }
    if ($TargetInputPath) {
        Add-SharedPathArrayArgument -Arguments $arguments -Name InputPath -Values @($TargetInputPath)
    }
    foreach ($switchName in $ExtraSwitches) {
        if ([string]::IsNullOrWhiteSpace($switchName)) {
            continue
        }
        $arguments.Add("-$switchName")
    }

    return Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $arguments
}

function Get-AttachedHtmlRouteCommands {
    param(
        [string]$TargetInputPath,
        [switch]$GoogleStyle
    )

    return @(
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -GoogleStyle:$GoogleStyle -ExtraSwitches @('AuditSidecars')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -GoogleStyle:$GoogleStyle -ExtraSwitches @('AuditAssets')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -GoogleStyle:$GoogleStyle -ExtraSwitches @('PrintManifest')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteSidecars', 'PrintManifest')),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -GoogleStyle:$GoogleStyle),
        (Get-AttachedHtmlCatalogCommand -TargetInputPath $TargetInputPath -GoogleStyle:$GoogleStyle -ExtraSwitches @('RequireCompleteSidecars')),
        "& `"$BrowserExe`" browse --headed --window_width 1366 --window_height 900 `"http://127.0.0.1:8235/`""
    )
}

function Get-RenderingRouteCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-layout-flex-center-probe.ps1",
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\layout-smoke\chrome-screenshot-load-complete-probe.ps1"
    )
}

function Get-RenderingRouteNotes {
    return @(
        "Use these before attached-page replay when the change touched shared layout, paint, screenshot timing, or visible headed surface behavior.",
        "The first-line layout-smoke probes now auto-resolve the repo root and zig-out\bin\lightpanda.exe from the current checkout; widen into older deeper helpers only when you need more coverage."
    )
}

function Get-NetworkRouteCommands {
    return @(
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stylesheet-smoke\chrome-stylesheet-auth-probe.ps1",
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\fetch-credentials\chrome-fetch-credentials-probe.ps1"
    )
}

function Get-NetworkRouteNotes {
    return @(
        "Use these before attached-page replay when the change touched shared subresource loading, authenticated asset fetches, or browser-managed request credentials.",
        "These first-line stylesheet and fetch-credentials probes now auto-resolve the current checkout before widening into deeper network helpers."
    )
}

$issue3AttachedHtmlArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $issue3AttachedHtmlArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $issue3AttachedHtmlArguments -Name SummaryPath -Value $SummaryPath
if ($InputPath) {
    Add-SharedPathArrayArgument -Arguments $issue3AttachedHtmlArguments -Name InputPath -Values @($InputPath)
}

$issue3AttachedHtmlSurfaceCheckArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $issue3AttachedHtmlSurfaceCheckArguments -Name RepoRoot -Value $RepoRoot

$issue3AttachedHtmlBrowserArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $issue3AttachedHtmlBrowserArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $issue3AttachedHtmlBrowserArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $issue3AttachedHtmlBrowserArguments -Name BrowserExe -Value $BrowserExe
if ($InputPath) {
    Add-SharedPathArrayArgument -Arguments $issue3AttachedHtmlBrowserArguments -Name InputPath -Values @($InputPath)
}

$googleAttachedHtmlFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $googleAttachedHtmlFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $googleAttachedHtmlFlowArguments -Name BrowserExe -Value $BrowserExe
if ($InputPath) {
    Add-SharedPathArrayArgument -Arguments $googleAttachedHtmlFlowArguments -Name InputPath -Values @($InputPath)
}

$googleFormControlsEnterOrderArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $googleFormControlsEnterOrderArguments -Name RepoRoot -Value $RepoRoot
if ($isCustomBrowserExe) {
    Add-SharedArgument -Arguments $googleFormControlsEnterOrderArguments -Name BrowserExe -Value $BrowserExe
}

function Get-Issue3AttachedHtmlFollowUpCommands {
    return @(
        (Format-HelperCommand -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -Arguments $issue3AttachedHtmlSurfaceCheckArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $issue3AttachedHtmlArguments),
        (Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $issue3AttachedHtmlBrowserArguments)
    )
}

function Get-Issue3AttachedHtmlFollowUpNotes {
    param(
        [switch]$BundleFocused
    )

    if ($BundleFocused) {
        $notes = @(
            "Use the compact bundle-suite surface first when the top-level router is already narrowed to the known three-page compatibility bundle.",
            "Keep the dedicated Google-shaped attached-page flow visible until the current pages are clearly still the pinned bundle.",
            "Only drop into the bundle-first helper after the suite surface is visible, so the pinned bundle route stays easy to reopen."
        )
    } else {
        $notes = @(
            "Use the attached-html change-area quickstart when you want the shorter issue #3 attached-page helper ladder visible after the broader attached-pages catalog route.",
            "Keep the dedicated Google-shaped attached-page flow visible when the replay still looks Google-like before you narrow into the bundle-only or shortcut-first helpers.",
            "Use the compact bundle-suite surface before the bundle-first helper when the replay should stay pinned to the known three-page compatibility set or when -InputPath already fixes the bundle inputs."
        )
    }

    $notes += "Run the validation-router attached-html surface checker first so missing quickstart notes or downstream helper paths fail fast before you trust the shorter issue #3 attached-page ladder."

    if ($SummaryPath) {
        $notes += "Current saved summary: $SummaryPath"
        $notes += "The printed issue #3 follow-up commands now preserve -SummaryPath through the router handoff, so saved validation state can be reopened without manual re-entry."
    }

    if ($isCustomBrowserExe) {
        $notes += "Current browser override: $BrowserExe"
        $notes += "The printed issue #3 follow-up commands now preserve -BrowserExe through the router handoff where the downstream helper accepts it. Keep rerunning this router before hopping between helper surfaces so the same custom binary stays pinned."
    }

    return $notes
}

function Get-GoogleFormControlsEnterOrderCommands {
    return @(
        (Format-HelperCommand -ScriptName 'check_google_form_controls_enter_order_validation_surface.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'show_google_form_controls_enter_order_trace_guide.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'show_google_form_controls_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
        (Format-HelperCommand -ScriptName 'run_google_form_controls_enter_order_validation.ps1' -Arguments $googleFormControlsEnterOrderArguments)
    )
}

function Get-GoogleFormControlsEnterOrderNotes {
    $notes = @(
        "Use this when issue #3 is already narrowed to the smallest shared Enter-order checkpoint on the real headed surface.",
        "Run the surface checker first so missing docs, wrappers, or the raw probe fail before you trust the dedicated runner.",
        "Widen back out to the broader shared Enter-order ladder only after this dedicated gate stays green."
    )

    if ($isCustomBrowserExe) {
        $notes += "Current browser override: $BrowserExe"
    }

    return $notes
}

function Show-DefaultRoutes {
    Write-Section "Headed Validation Suites"
    Write-Host "Use the smallest bounded check first, then widen into manual headed follow-up."
    if ($isCustomBrowserExe) {
        Write-Host ("Browser exe: {0}" -f $BrowserExe)
    }

    Write-Route -Name "navigation" -Commands @(
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-history-probe.ps1",
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\wrapped-link\chrome-reload-probe.ps1"
    ) -Notes @(
        "These probes exercise headed navigation, back, forward, and reload on localhost fixtures.",
        "Repo root resolves automatically from this script unless -RepoRoot overrides it."
    )

    Write-Route -Name "stop-loading" -Commands @(
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stop-loading\chrome-stop-probe.ps1",
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stop-loading\chrome-stop-input-probe.ps1"
    ) -Notes @(
        "These probes exercise headed stop/loading recovery and restored input behavior on localhost fixtures.",
        "These first-line stop-loading probes now auto-resolve the repo root and zig-out\bin\lightpanda.exe from the current checkout; widen into older deeper helpers only when you need more coverage."
    )

    Write-Route -Name "input" -Commands @(
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
        "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
    ) -Notes @(
        "These are the current bounded input checks already committed on this branch.",
        "Use them before live-site or saved-page follow-up."
    )

    Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
    Write-Route -Name "rendering" -Commands (Get-RenderingRouteCommands) -Notes (Get-RenderingRouteNotes)
    Write-Route -Name "network" -Commands (Get-NetworkRouteCommands) -Notes (Get-NetworkRouteNotes)

    $attachedCommands = Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath
    Write-Route -Name "attached-html" -Commands $attachedCommands -Notes (Get-AttachedHtmlNotes)
    Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes)

    $googleRecommendedNotes = @(
        "Use the bounded input probe first, then the dedicated Google form-controls Enter-order gate, then live Google, then the dedicated Google-shaped attached-page flow before the shorter issue #3 helper surface or the broader manual localhost replay.",
        "Pass -InputPath when you already want the top-level attached-page quickstart or bundle-first helper pinned to a saved page or the current three-page compatibility bundle."
    )
    if ($SummaryPath) {
        $googleRecommendedNotes += "Keep the same saved summary pinned by rerunning this router with -SummaryPath before switching to the shorter issue #3 helper ladder."
    }
    if ($isCustomBrowserExe) {
        $googleRecommendedNotes += "Keep the same non-default binary pinned by rerunning this router with -BrowserExe before switching to the shorter issue #3 helper ladder."
    }

    Write-Route -Name "google-recommended" -Commands @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order",
        "& `"$BrowserExe`" browse --headed `"https://www.google.com/`"",
        (Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
        (Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $issue3AttachedHtmlBrowserArguments)
    ) -Notes $googleRecommendedNotes
}

switch ($true) {
    { $SuiteName -eq "google-form-controls-enter-order" } {
        Write-Section "google-form-controls-enter-order"
        if ($isCustomBrowserExe) {
            Write-Host ("Browser exe: {0}" -f $BrowserExe)
        }

        Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
        Write-Route -Name "shared-enter-order-follow-up" -Commands @(
            (Format-HelperCommand -ScriptName 'show_google_shared_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
            (Format-HelperCommand -ScriptName 'run_google_shared_enter_order_validation.ps1' -Arguments $googleFormControlsEnterOrderArguments)
        ) -Notes @(
            "Use these after the dedicated form-controls Enter-order gate is green and you want the broader shared Enter-order ladder back on one surface."
        )
        break
    }
    { $SuiteName -eq "google-recommended" } {
        Write-Section "google-recommended"
        if ($isCustomBrowserExe) {
            Write-Host ("Browser exe: {0}" -f $BrowserExe)
        }
        $issue3FollowUpNotes = @(
            "Use the dedicated Google-shaped attached-page flow when the next step still needs the broader Google-like replay map visible before the shorter issue #3 helpers.",
            "Use the top-level attached-page quickstart when the next step is saved-page follow-up on the shorter issue #3 helper ladder.",
            "Use the bundle-first helper when the replay should stay pinned to the known three-page compatibility set or when -InputPath already fixes the bundle inputs."
        )
        if ($SummaryPath) {
            $issue3FollowUpNotes += "Keep the same saved summary pinned by rerunning this router with -SummaryPath before switching to the shorter issue #3 helper ladder."
        }
        if ($isCustomBrowserExe) {
            $issue3FollowUpNotes += "Keep the same non-default binary pinned by rerunning this router with -BrowserExe before switching to the shorter issue #3 helper ladder."
        }

        Write-Route -Name "google-recommended" -Commands @(
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
            "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1",
            "& `"$BrowserExe`" browse --headed `"https://www.google.com/`""
        ) -Notes @(
            "Use the shared Enter-submit probe first, then the dedicated Google form-controls Enter-order gate, then verify Google homepage typing, focus retention, and Enter submit manually."
        )

        Write-Route -Name "issue3-attached-html-follow-up" -Commands @(
            (Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments),
            (Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
            (Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $issue3AttachedHtmlBrowserArguments)
        ) -Notes $issue3FollowUpNotes
        break
    }
    { $ChangeArea -eq "input" -or $ChangeArea -eq "google-input" } {
        Write-Section $ChangeArea
        if ($isCustomBrowserExe) {
            Write-Host ("Browser exe: {0}" -f $BrowserExe)
        }
        Write-Route -Name "bounded-input" -Commands @(
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\enter-submit-probe.ps1",
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\label-click-probe.ps1"
        ) -Notes @(
            "These probes are the smallest shared headed checks for typing, focus, and Enter submit."
        )

        if ($ChangeArea -eq "google-input") {
            $googleInputFollowUpNotes = @(
                "Use the dedicated Google-shaped attached-page flow when the next step still needs the broader Google-like replay map visible before the shorter issue #3 helpers.",
                "Use the top-level attached-page quickstart when the next step is saved-page follow-up on the shorter issue #3 helper ladder.",
                "Use the bundle-first helper when the replay should stay pinned to the known three-page compatibility set or when -InputPath already fixes the bundle inputs."
            )
            if ($SummaryPath) {
                $googleInputFollowUpNotes += "Keep the same saved summary pinned by rerunning this router with -SummaryPath before switching to the shorter issue #3 helper ladder."
            }
            if ($isCustomBrowserExe) {
                $googleInputFollowUpNotes += "Keep the same non-default binary pinned by rerunning this router with -BrowserExe before switching to the shorter issue #3 helper ladder."
            }

            Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes @(
                "Use this after the shared input probes are green when the next question is whether submit still waits until keypress on the Google-style form-controls path."
            )

            Write-Route -Name "manual-google" -Commands @(
                "& `"$BrowserExe`" browse --headed `"https://www.google.com/`""
            ) -Notes @(
                "Use this after the bounded input probes are green."
            )

            Write-Route -Name "issue3-attached-html-follow-up" -Commands @(
                (Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments),
                (Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $issue3AttachedHtmlBrowserArguments),
                (Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $issue3AttachedHtmlBrowserArguments)
            ) -Notes $googleInputFollowUpNotes
        }
        break
    }
    { $ChangeArea -eq "google-form-controls-enter-order" } {
        Write-Section "google-form-controls-enter-order"
        if ($isCustomBrowserExe) {
            Write-Host ("Browser exe: {0}" -f $BrowserExe)
        }

        Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)
        Write-Route -Name "shared-enter-order-follow-up" -Commands @(
            (Format-HelperCommand -ScriptName 'show_google_shared_enter_order_validation_flow.ps1' -Arguments $googleFormControlsEnterOrderArguments),
            (Format-HelperCommand -ScriptName 'run_google_shared_enter_order_validation.ps1' -Arguments $googleFormControlsEnterOrderArguments)
        ) -Notes @(
            "Use these after the dedicated form-controls Enter-order gate is green and you want the broader shared Enter-order ladder back on one surface."
        )
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
    { $ChangeArea -eq "stop-loading" } {
        Write-Section "stop-loading"
        Write-Route -Name "stop-loading" -Commands @(
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stop-loading\chrome-stop-probe.ps1",
            "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\stop-loading\chrome-stop-input-probe.ps1"
        ) -Notes @(
            "Use these for headed stop/loading recovery and restored input behavior on bounded localhost pages.",
            "These first-line stop-loading probes now auto-resolve the repo root and zig-out\bin\lightpanda.exe from the current checkout; widen into older deeper helpers only when you need more coverage."
        )
        break
    }
    { $ChangeArea -eq "rendering" } {
        Write-Section "rendering"
        Write-Route -Name "bounded-rendering" -Commands (Get-RenderingRouteCommands) -Notes (Get-RenderingRouteNotes)
        Write-Route -Name "attached-pages-catalog-follow-up" -Commands (Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath) -Notes (Get-AttachedHtmlNotes)
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes)
        break
    }
    { $ChangeArea -eq "network" } {
        Write-Section "network"
        Write-Route -Name "bounded-network" -Commands (Get-NetworkRouteCommands) -Notes (Get-NetworkRouteNotes)
        Write-Route -Name "attached-pages-catalog-follow-up" -Commands (Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath) -Notes (Get-AttachedHtmlNotes)
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes)
        break
    }
    { $ChangeArea -eq "attached-html" -or $ChangeArea -eq "attached-html-target-bundle" -or $ChangeArea -eq "google-attached-html" -or $ChangeArea -eq "manual-html" } {
        Write-Section $ChangeArea
        if ($isCustomBrowserExe) {
            Write-Host ("Browser exe: {0}" -f $BrowserExe)
        }
        $useGoogleStyleCatalog = $ChangeArea -eq "google-attached-html"
        $commands = Get-AttachedHtmlRouteCommands -TargetInputPath $InputPath -GoogleStyle:$useGoogleStyleCatalog
        $notes = Get-AttachedHtmlNotes
        if ($useGoogleStyleCatalog) {
            $notes += "Google-style auto-discovery keeps the strongest Google-like saved page first when -InputPath is omitted."
        }
        Write-Route -Name "attached-pages-catalog-follow-up" -Commands $commands -Notes $notes
        $bundleFocused = $ChangeArea -eq "attached-html-target-bundle"
        Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes -BundleFocused:$bundleFocused)
        break
    }
    default {
        Show-DefaultRoutes
        break
    }
}