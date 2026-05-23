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
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Broader Windows headed runbook that should keep the validation router, bundle routes, and matrix handoff discoverable."),
    (New-ValidationReference -Path "docs/HEADED_MODE_VALIDATION_MATRIX.md" -Kind "file" -Purpose "Read-first matrix that should stay aligned with the top-level headed validation router."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used by the headed validation router and the narrower route-specific checkers."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level headed validation router for the main change areas and suite views."),
    (New-ValidationReference -Path "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1" -Kind "file" -Purpose "Dedicated form-controls Enter-order fail-fast checker that should stay reachable from the router."),
    (New-ValidationReference -Path "scripts/windows/check_google_shared_enter_order_validation_surface.ps1" -Kind "file" -Purpose "Shared Enter-order fail-fast checker that should stay reachable from the router."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1" -Kind "file" -Purpose "Issue #3 attached-html fail-fast checker that should stay reachable from the router."),
    (New-ValidationReference -Path "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Dedicated form-controls Enter-order helper that the router should keep discoverable."),
    (New-ValidationReference -Path "scripts/windows/show_google_shared_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Shared Enter-order helper that the router should keep discoverable."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Shorter issue #3 attached-html helper that should stay reachable from the router."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Pinned bundle suite helper that should stay reachable from the router."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Pinned bundle-first helper that should stay reachable from the router."),
    (New-ValidationReference -Path "scripts/windows/start_attached_pages_catalog.ps1" -Kind "file" -Purpose "Attached-pages localhost catalog wrapper that should stay in the router and the Windows runbook."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "Shared smallest input probe that the router should still expose first."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/label-click-probe.ps1" -Kind "file" -Purpose "Shared label-activation probe that the router should still expose first."),
    (New-ValidationReference -Path "tmp-browser-smoke/wrapped-link/chrome-history-probe.ps1" -Kind "file" -Purpose "Navigation probe that the router should still expose for the navigation change area."),
    (New-ValidationReference -Path "tmp-browser-smoke/wrapped-link/chrome-reload-probe.ps1" -Kind "file" -Purpose "Reload probe that the router should still expose for the navigation change area."),
    (New-ValidationReference -Path "tmp-browser-smoke/stop-loading/chrome-stop-probe.ps1" -Kind "file" -Purpose "Stop/loading probe that the router should still expose for the stop-loading change area."),
    (New-ValidationReference -Path "tmp-browser-smoke/stop-loading/chrome-stop-input-probe.ps1" -Kind "file" -Purpose "Stop/loading restored-input probe that the router should still expose for the stop-loading change area."),
    (New-ValidationReference -Path "tmp-browser-smoke/layout-smoke/chrome-layout-flex-center-probe.ps1" -Kind "file" -Purpose "Rendering probe that the router should still expose for the rendering change area."),
    (New-ValidationReference -Path "tmp-browser-smoke/layout-smoke/chrome-screenshot-load-complete-probe.ps1" -Kind "file" -Purpose "Screenshot timing probe that the router should still expose for the rendering change area."),
    (New-ValidationReference -Path "tmp-browser-smoke/stylesheet-smoke/chrome-stylesheet-auth-probe.ps1" -Kind "file" -Purpose "Network probe that the router should still expose for the network change area."),
    (New-ValidationReference -Path "tmp-browser-smoke/fetch-credentials/chrome-fetch-credentials-probe.ps1" -Kind "file" -Purpose "Fetch-credentials probe that the router should still expose for the network change area."),
    (New-ValidationReference -Path "tmp-browser-smoke/tabs/chrome-tabs-probe.ps1" -Kind "file" -Purpose "Browser-shell tabs probe that the router should still expose for the browser-shell change area."),
    (New-ValidationReference -Path "tmp-browser-smoke/settings/chrome-settings-home-probe.ps1" -Kind "file" -Purpose "Browser-shell settings probe that the router should still expose for the browser-shell change area."),
    (New-ValidationReference -Path "tmp-browser-smoke/popup/chrome-popup-anchor-probe.ps1" -Kind "file" -Purpose "Popup probe that the router should still expose for the popup change area."),
    (New-ValidationReference -Path "tmp-browser-smoke/canvas-smoke/chrome-canvas-render-probe.ps1" -Kind "file" -Purpose "Canvas probe that the matrix should still expose for screenshot-visible canvas changes.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order' -Purpose "Windows full-use guide keeps the shared Enter-order route visible from the main headed runbook."),
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea browser-shell' -Purpose "Windows full-use guide keeps the browser-shell route visible from the main headed runbook."),
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle' -Purpose "Windows full-use guide keeps the pinned attached bundle route visible from the main headed runbook."),
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'docs/HEADED_MODE_VALIDATION_MATRIX.md' -Purpose "Windows full-use guide keeps the broader validation matrix handoff visible."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_VALIDATION_MATRIX.md" -Snippet 'google-shared-enter-order' -Purpose "Validation matrix keeps the shared Enter-order lane visible."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_VALIDATION_MATRIX.md" -Snippet 'browser-shell' -Purpose "Validation matrix keeps the browser-shell lane visible."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_VALIDATION_MATRIX.md" -Snippet 'attached-html-target-bundle' -Purpose "Validation matrix keeps the pinned attached bundle lane visible."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_VALIDATION_MATRIX.md" -Snippet 'run_attached_html_target_bundle_validation.ps1' -Purpose "Validation matrix keeps the bundle validation runner visible in the fast path."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet '[ValidateSet("", "attached-html-target-bundle", "google-attached-html", "google-form-controls-enter-order", "google-recommended", "google-shared-enter-order")]' -Purpose "Router suite selection still includes the shared Enter-order and attached bundle suite views."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet '[ValidateSet("", "attached-html", "attached-html-target-bundle", "browser-shell", "google-attached-html", "google-form-controls-enter-order", "google-input", "google-shared-enter-order", "input", "manual-html", "navigation", "network", "popup", "rendering", "stop-loading")]' -Purpose "Router change-area selection still includes the broader headed validation lanes."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Write-Route -Name "google-shared-enter-order" -Commands (Get-GoogleSharedEnterOrderCommands) -Notes (Get-GoogleSharedEnterOrderNotes)' -Purpose "Router default output still prints the shared Enter-order route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Write-Route -Name "browser-shell" -Commands (Get-BrowserShellRouteCommands) -Notes (Get-BrowserShellRouteNotes)' -Purpose "Router default output still prints the browser-shell route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Write-Route -Name "attached-html" -Commands $attachedCommands -Notes (Get-AttachedHtmlNotes)' -Purpose "Router default output still prints the attached-html route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Write-Route -Name "issue3-attached-html-follow-up" -Commands (Get-Issue3AttachedHtmlFollowUpCommands) -Notes (Get-Issue3AttachedHtmlFollowUpNotes)' -Purpose "Router default output still prints the issue #3 attached-html follow-up route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Write-Route -Name "bounded-browser-shell" -Commands (Get-BrowserShellRouteCommands) -Notes (Get-BrowserShellRouteNotes)' -Purpose "Router change-area output still prints the bounded browser-shell route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet '$bundleFocused = $ChangeArea -eq "attached-html-target-bundle"' -Purpose "Router attached-html branch still tracks the pinned attached bundle route explicitly.")
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
        profile = "headed-validation-router"
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

Write-Host "Headed validation router surface check"
Write-Host ""
Write-Host (("Repo root: {0}") -f $resolvedRepoRoot)
Write-Host ""

foreach ($result in $referenceResults) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host (("[{0}] {1}") -f $status, $result.Path)
    Write-Host (("  {0}") -f $result.Purpose)
}

if ($contentResults.Count -gt 0) {
    Write-Host ""
    Write-Host "Helper and doc expectations:"
    foreach ($result in $contentResults) {
        $status = if ($result.Exists) { "PASS" } else { "FAIL" }
        Write-Host (("[{0}] {1}") -f $status, $result.Path)
        Write-Host (("  {0}") -f $result.Purpose)
    }
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Headed validation router surface is intact."
    exit 0
}

Write-Host (("Missing {0} headed validation router path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing runbook link, matrix lane, router change area, fail-fast checker, or bounded probe before trusting the top-level headed validation router packet."
exit 1