[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function New-ValidationReference {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [ValidateSet("file", "directory")]
        [string]$Kind,
        [Parameter(Mandatory = $true)]
        [string]$Purpose
    )

    return [pscustomobject]@{
        Path = $Path
        Kind = $Kind
        Purpose = $Purpose
    }
}

function New-ValidationContentExpectation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Snippet,
        [Parameter(Mandatory = $true)]
        [string]$Purpose
    )

    return [pscustomobject]@{
        Path = $Path
        Snippet = $Snippet
        Purpose = $Purpose
    }
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$references = @(
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that should keep the top-level validation router commands visible as the source of truth."),
    (New-ValidationReference -Path "docs/HEADED_MODE_VALIDATION_MATRIX.md" -Kind "file" -Purpose "Validation matrix that should keep routing back to the top-level headed validation suite router for first picks."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared repo-root and command helpers used by the validation router and the other fail-fast checker surfaces."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level headed validation suite router whose printed command packet this checker protects."),
    (New-ValidationReference -Path "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1" -Kind "file" -Purpose "Dedicated fail-fast checker for the tight issue #3 form-controls Enter-order gate that the router should keep reachable."),
    (New-ValidationReference -Path "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the dedicated form-controls Enter-order gate."),
    (New-ValidationReference -Path "scripts/windows/check_google_shared_enter_order_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the broader shared Enter-order ladder that the router should keep reachable."),
    (New-ValidationReference -Path "scripts/windows/show_google_shared_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the broader shared Enter-order route."),
    (New-ValidationReference -Path "scripts/windows/start_attached_pages_catalog.ps1" -Kind "file" -Purpose "Windows wrapper for attached-pages catalog launch, audits, and strict completeness gates surfaced by the router."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-page localhost flow helper that the top-level router should keep visible."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-shaped attached-page flow helper that the top-level router should keep visible."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the narrower issue #3 attached-html validation-router bridge surfaced by the top-level router."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Shorter issue #3 attached-page change-area quickstart surfaced by the router."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Compact top-level attached-page quickstart surfaced by the router."),
    (New-ValidationReference -Path "tmp-browser-smoke/wrapped-link/chrome-history-probe.ps1" -Kind "file" -Purpose "First-line navigation probe that anchors the router's navigation surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/stop-loading/chrome-stop-probe.ps1" -Kind "file" -Purpose "First-line stop/loading probe that anchors the router's stop-loading surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "First-line shared form-controls probe that anchors the router's input surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/layout-smoke/chrome-layout-flex-center-probe.ps1" -Kind "file" -Purpose "First-line rendering probe that anchors the router's rendering surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/stylesheet-smoke/chrome-stylesheet-auth-probe.ps1" -Kind "file" -Purpose "First-line network probe that anchors the router's network surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/browser-pages/chrome-browser-pages-start-shell-probe.ps1" -Kind "file" -Purpose "First-line browser-shell probe that anchors the router's browser-shell surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/popup/chrome-popup-anchor-probe.ps1" -Kind "file" -Purpose "First-line popup probe that anchors the router's popup surface.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Write-Route -Name "google-form-controls-enter-order" -Commands (Get-GoogleFormControlsEnterOrderCommands) -Notes (Get-GoogleFormControlsEnterOrderNotes)' -Purpose "Validation router keeps the dedicated Google form-controls Enter-order surface wired into the printed packet."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)' -Purpose "Validation router keeps the broader shared Enter-order surface wired into the printed packet."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Write-Route -Name "rendering" -Commands (Get-RenderingRouteCommands) -Notes (Get-RenderingRouteNotes)' -Purpose "Validation router keeps the rendering surface wired into the printed packet."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Write-Route -Name "network" -Commands (Get-NetworkRouteCommands) -Notes (Get-NetworkRouteNotes)' -Purpose "Validation router keeps the network surface wired into the printed packet."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Write-Route -Name "browser-shell" -Commands (Get-BrowserShellRouteCommands) -Notes (Get-BrowserShellRouteNotes)' -Purpose "Validation router keeps the browser-shell surface wired into the printed packet."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Write-Route -Name "popup" -Commands (Get-PopupRouteCommands) -Notes (Get-PopupRouteNotes)' -Purpose "Validation router keeps the popup surface wired into the printed packet."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Write-Route -Name "attached-html" -Commands $attachedCommands -Notes (Get-AttachedHtmlNotes)' -Purpose "Validation router keeps the broader attached-html surface wired into the printed packet."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet "Format-HelperCommand -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -Arguments $issue3AttachedHtmlSurfaceCheckArguments" -Purpose "Validation router keeps the narrower issue #3 attached-html fail-fast checker wired before the shorter helper ladder."),
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order' -Purpose "Windows runbook keeps the dedicated Google form-controls Enter-order route visible from the main headed validation section."),
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order' -Purpose "Windows runbook keeps the broader shared Enter-order route visible from the main headed validation section."),
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea rendering' -Purpose "Windows runbook keeps the rendering router entry visible."),
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea network' -Purpose "Windows runbook keeps the network router entry visible."),
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea browser-shell' -Purpose "Windows runbook keeps the browser-shell router entry visible."),
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea popup' -Purpose "Windows runbook keeps the popup router entry visible."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_VALIDATION_MATRIX.md" -Snippet 'Prefer `scripts\\windows\\show_headed_validation_suites.ps1` first for the change areas it already routes directly: `navigation`, `stop-loading`, `input`, `google-form-controls-enter-order`, `google-shared-enter-order`, `rendering`, `network`, `browser-shell`, `popup`, `attached-html`, `attached-html-target-bundle`, `google-input`, and `google-attached-html`.' -Purpose "Validation matrix keeps the top-level router listed as the default first pick across the current change areas."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_VALIDATION_MATRIX.md" -Snippet '| Browser shell tabs, settings, and related chrome behavior | `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea browser-shell` |' -Purpose "Validation matrix keeps the browser-shell route anchored on the top-level router."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_VALIDATION_MATRIX.md" -Snippet '| Popup creation, named-target flows, or popup policy | `powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea popup` |' -Purpose "Validation matrix keeps the popup route anchored on the top-level router.")
)

$referenceResults = foreach ($reference in $references) {
    $fullPath = Join-Path $resolvedRepoRoot $reference.Path
    $exists = if ($reference.Kind -eq "directory") {
        Test-Path -LiteralPath $fullPath -PathType Container
    } else {
        Test-Path -LiteralPath $fullPath -PathType Leaf
    }

    [pscustomobject]@{
        CheckType = "reference"
        Path = $reference.Path
        Kind = $reference.Kind
        Purpose = $reference.Purpose
        Exists = [bool]$exists
    }
}

$contentCache = @{}
$contentResults = foreach ($expectation in $contentExpectations) {
    $fullPath = Join-Path $resolvedRepoRoot $expectation.Path
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        [pscustomobject]@{
            CheckType = "content"
            Path = $expectation.Path
            Kind = "content-snippet"
            Purpose = $expectation.Purpose
            Exists = $false
            Snippet = $expectation.Snippet
        }
        continue
    }

    if (-not $contentCache.ContainsKey($fullPath)) {
        $contentCache[$fullPath] = Get-Content -LiteralPath $fullPath -Raw
    }

    [pscustomobject]@{
        CheckType = "content"
        Path = $expectation.Path
        Kind = "content-snippet"
        Purpose = $expectation.Purpose
        Exists = [bool]$contentCache[$fullPath].Contains($expectation.Snippet)
        Snippet = $expectation.Snippet
    }
}

$missingReferences = @($referenceResults | Where-Object { -not $_.Exists })
$missingContent = @($contentResults | Where-Object { -not $_.Exists })
$missing = @($missingReferences + $missingContent)

if ($Json) {
    [ordered]@{
        profile = "headed-validation-suite-router"
        repo_root = $resolvedRepoRoot
        checked_count = @($referenceResults).Count + @($contentResults).Count
        reference_count = @($referenceResults).Count
        content_check_count = @($contentResults).Count
        missing_count = @($missing).Count
        references = @($referenceResults)
        content_checks = @($contentResults)
    } | ConvertTo-Json -Depth 6

    if ($missing.Count -gt 0) {
        exit 1
    }

    exit 0
}

Write-Host "Headed validation suite router surface check"
Write-Host ""
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
Write-Host ""

foreach ($result in $referenceResults) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host ("[{0}] {1}" -f $status, $result.Path)
    Write-Host ("  {0}" -f $result.Purpose)
}

if ($contentResults.Count -gt 0) {
    Write-Host ""
    Write-Host "Router and doc contract expectations:"
    foreach ($result in $contentResults) {
        $status = if ($result.Exists) { "PASS" } else { "FAIL" }
        Write-Host ("[{0}] {1}" -f $status, $result.Path)
        Write-Host ("  {0}" -f $result.Purpose)
    }
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Headed validation suite router surface is intact across the Windows runbook, validation matrix, top-level router script, and the first-line probe and issue-specific follow-up surfaces."
    exit 0
}

Write-Host ("Missing {0} headed validation suite router path or source contract check(s)." -f $missing.Count)
Write-Host "Repair the missing runbook command, router wiring, doc handoff, first-line probe, or narrower issue #3 helper surface before trusting the top-level headed validation packet."
exit 1