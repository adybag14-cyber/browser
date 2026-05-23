[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function New-PathCheck {
    param(
        [string]$Path,
        [string]$Purpose
    )

    [pscustomobject]@{
        Path = $Path
        Purpose = $Purpose
    }
}

function New-SnippetCheck {
    param(
        [string]$Path,
        [string]$Snippet,
        [string]$Purpose
    )

    [pscustomobject]@{
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

$pathChecks = @(
    (New-PathCheck -Path "docs/WINDOWS_FULL_USE.md" -Purpose "Broader Windows headed runbook still exists."),
    (New-PathCheck -Path "docs/HEADED_MODE_VALIDATION_MATRIX.md" -Purpose "Probe-family validation matrix still exists."),
    (New-PathCheck -Path "scripts/windows/HeadedValidationHelpers.ps1" -Purpose "Shared headed-validation helper surface still exists."),
    (New-PathCheck -Path "scripts/windows/show_headed_validation_suites.ps1" -Purpose "Top-level headed validation router still exists."),
    (New-PathCheck -Path "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1" -Purpose "Dedicated Enter-order guard is still reachable."),
    (New-PathCheck -Path "scripts/windows/check_google_shared_enter_order_validation_surface.ps1" -Purpose "Shared Enter-order guard is still reachable."),
    (New-PathCheck -Path "scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1" -Purpose "Issue #3 attached-html guard is still reachable."),
    (New-PathCheck -Path "scripts/windows/start_attached_pages_catalog.ps1" -Purpose "Attached-pages localhost catalog wrapper still exists."),
    (New-PathCheck -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Purpose "Smallest shared input probe still exists."),
    (New-PathCheck -Path "tmp-browser-smoke/wrapped-link/chrome-history-probe.ps1" -Purpose "Navigation probe still exists."),
    (New-PathCheck -Path "tmp-browser-smoke/stop-loading/chrome-stop-probe.ps1" -Purpose "Stop/loading probe still exists."),
    (New-PathCheck -Path "tmp-browser-smoke/layout-smoke/chrome-layout-flex-center-probe.ps1" -Purpose "Rendering probe still exists."),
    (New-PathCheck -Path "tmp-browser-smoke/fetch-credentials/chrome-fetch-credentials-probe.ps1" -Purpose "Network probe still exists."),
    (New-PathCheck -Path "tmp-browser-smoke/tabs/chrome-tabs-probe.ps1" -Purpose "Browser-shell probe still exists."),
    (New-PathCheck -Path "tmp-browser-smoke/popup/chrome-popup-anchor-probe.ps1" -Purpose "Popup probe still exists.")
)

$snippetChecks = @(
    (New-SnippetCheck -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order' -Purpose "Windows runbook still points to the shared Enter-order lane."),
    (New-SnippetCheck -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'show_headed_validation_suites.ps1 -ChangeArea browser-shell' -Purpose "Windows runbook still points to the browser-shell lane."),
    (New-SnippetCheck -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle' -Purpose "Windows runbook still points to the pinned attached bundle lane."),
    (New-SnippetCheck -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'docs/HEADED_MODE_VALIDATION_MATRIX.md' -Purpose "Windows runbook still hands off to the validation matrix."),
    (New-SnippetCheck -Path "docs/HEADED_MODE_VALIDATION_MATRIX.md" -Snippet 'google-shared-enter-order' -Purpose "Validation matrix still names the shared Enter-order lane."),
    (New-SnippetCheck -Path "docs/HEADED_MODE_VALIDATION_MATRIX.md" -Snippet 'browser-shell' -Purpose "Validation matrix still names the browser-shell lane."),
    (New-SnippetCheck -Path "docs/HEADED_MODE_VALIDATION_MATRIX.md" -Snippet 'attached-html-target-bundle' -Purpose "Validation matrix still names the pinned attached bundle lane."),
    (New-SnippetCheck -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'google-shared-enter-order' -Purpose "Router still exposes the shared Enter-order route."),
    (New-SnippetCheck -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'browser-shell' -Purpose "Router still exposes the browser-shell route."),
    (New-SnippetCheck -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'attached-html-target-bundle' -Purpose "Router still exposes the pinned attached bundle route."),
    (New-SnippetCheck -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'issue3-attached-html-follow-up' -Purpose "Router still prints the issue #3 attached-html follow-up surface.")
)

$pathResults = foreach ($check in $pathChecks) {
    $fullPath = Join-Path $resolvedRepoRoot $check.Path
    [pscustomobject]@{
        CheckType = "path"
        Path = $check.Path
        Purpose = $check.Purpose
        Exists = [bool](Test-Path -LiteralPath $fullPath -PathType Leaf)
    }
}

$contentCache = @{}
$snippetResults = foreach ($check in $snippetChecks) {
    $fullPath = Join-Path $resolvedRepoRoot $check.Path
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        [pscustomobject]@{
            CheckType = "snippet"
            Path = $check.Path
            Purpose = $check.Purpose
            Exists = $false
            Snippet = $check.Snippet
        }
        continue
    }

    if (-not $contentCache.ContainsKey($fullPath)) {
        $contentCache[$fullPath] = Get-Content -LiteralPath $fullPath -Raw
    }

    [pscustomobject]@{
        CheckType = "snippet"
        Path = $check.Path
        Purpose = $check.Purpose
        Exists = [bool]$contentCache[$fullPath].Contains($check.Snippet)
        Snippet = $check.Snippet
    }
}

$missing = @(@($pathResults | Where-Object { -not $_.Exists }) + @($snippetResults | Where-Object { -not $_.Exists }))

if ($Json) {
    [ordered]@{
        profile = "headed-validation-router"
        repo_root = $resolvedRepoRoot
        checked_count = @($pathResults).Count + @($snippetResults).Count
        missing_count = @($missing).Count
        path_checks = @($pathResults)
        snippet_checks = @($snippetResults)
    } | ConvertTo-Json -Depth 6

    if ($missing.Count -gt 0) {
        exit 1
    }

    exit 0
}

Write-Host "Headed validation router surface check"
Write-Host ""
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
Write-Host ""

foreach ($result in $pathResults) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host ("[{0}] {1}" -f $status, $result.Path)
    Write-Host ("  {0}" -f $result.Purpose)
}

Write-Host ""
Write-Host "Route and doc expectations:"
foreach ($result in $snippetResults) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host ("[{0}] {1}" -f $status, $result.Path)
    Write-Host ("  {0}" -f $result.Purpose)
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Headed validation router surface is intact."
    exit 0
}

Write-Host ("Missing {0} headed validation router path or route expectation check(s)." -f $missing.Count)
Write-Host "Repair the missing runbook link, matrix lane, router route, guard, or bounded probe before trusting the top-level headed validation router packet."
exit 1