[CmdletBinding()]
param(
    [string[]]$Path,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$rules = @(
    [pscustomobject]@{
        Name = "local-html-fixtures"
        ChangeArea = "local-html-fixtures"
        Patterns = @(
            "tmp-browser-smoke/local-html-fixtures/",
            "scripts/windows/check_local_html_fixture",
            "scripts/windows/run_localhost_html_validation_recommended.ps1"
        )
    }
    [pscustomobject]@{
        Name = "attached-html-target-bundle"
        ChangeArea = "attached-html-target-bundle"
        Patterns = @(
            "scripts/windows/check_attached_html_target_bundle",
            "scripts/windows/run_attached_html_target_bundle_validation",
            "scripts/windows/show_attached_html_target_bundle_validation_flow"
        )
    }
    [pscustomobject]@{
        Name = "google-attached-html"
        ChangeArea = "google-attached-html"
        Patterns = @(
            "scripts/windows/check_google_attached_html",
            "scripts/windows/run_google_attached_html_validation",
            "scripts/windows/show_google_attached_html_validation_flow",
            "scripts/windows/show_saved_page_google_validation_flow",
            "scripts/windows/run_google_issue3_recommended_validation.ps1"
        )
    }
    [pscustomobject]@{
        Name = "attached-html"
        ChangeArea = "attached-html"
        Patterns = @(
            "scripts/windows/check_saved_page_localhost_validation_surface.ps1",
            "scripts/windows/check_attached_html_local_asset_closure.ps1",
            "scripts/windows/run_saved_page_localhost_validation.ps1",
            "scripts/windows/run_sanitized_saved_page_localhost_validation.ps1",
            "scripts/windows/show_attached_html_validation_flow.ps1",
            "scripts/windows/HeadedValidationHelpers.ps1",
            "docs/windows_full_use.md",
            "tmp-browser-smoke/readme.md"
        )
    }
    [pscustomobject]@{
        Name = "google-input"
        ChangeArea = "google-input"
        Patterns = @(
            "src/display/win32_backend.zig",
            "src/browser/page.zig",
            "src/browser/tests/page/google_home_title_probe.html",
            "tmp-browser-smoke/google-investigation-next/",
            "scripts/windows/show_google_",
            "scripts/windows/run_google_",
            "scripts/windows/check_google_"
        )
    }
    [pscustomobject]@{
        Name = "input"
        ChangeArea = "input"
        Patterns = @(
            "src/display/",
            "src/browser/page.zig",
            "src/browser/eventmanager.zig",
            "src/browser/webapi/element/html/input.zig",
            "src/browser/webapi/element/html/textarea.zig",
            "src/browser/webapi/element/html/label.zig",
            "tmp-browser-smoke/form-controls/",
            "tmp-browser-smoke/find/",
            "tmp-browser-smoke/inline-flow/"
        )
    }
    [pscustomobject]@{
        Name = "rendering"
        ChangeArea = "rendering"
        Patterns = @(
            "src/render/",
            "src/browser/webapi/element/html/image.zig",
            "tmp-browser-smoke/layout-smoke/",
            "tmp-browser-smoke/flow-layout/",
            "tmp-browser-smoke/rendered-link-dom/",
            "tmp-browser-smoke/font-render/",
            "tmp-browser-smoke/font-smoke/",
            "tmp-browser-smoke/image-smoke/",
            "tmp-browser-smoke/stylesheet-smoke/",
            "tmp-browser-smoke/zoom/"
        )
    }
    [pscustomobject]@{
        Name = "graphics"
        ChangeArea = "graphics"
        Patterns = @(
            "src/browser/webapi/canvas/",
            "tmp-browser-smoke/canvas-smoke/",
            "tmp-browser-smoke/multi-image/"
        )
    }
    [pscustomobject]@{
        Name = "downloads"
        ChangeArea = "downloads"
        Patterns = @(
            "tmp-browser-smoke/file-upload/",
            "tmp-browser-smoke/downloads/",
            "tmp-browser-smoke/attachment-downloads/"
        )
    }
    [pscustomobject]@{
        Name = "storage"
        ChangeArea = "storage"
        Patterns = @(
            "src/hostpaths.zig",
            "tmp-browser-smoke/cookie-persistence/",
            "tmp-browser-smoke/localstorage-persistence/",
            "tmp-browser-smoke/indexeddb-persistence/",
            "tmp-browser-smoke/sessionstorage-scope/"
        )
    }
    [pscustomobject]@{
        Name = "network"
        ChangeArea = "network"
        Patterns = @(
            "src/http/",
            "src/browser/webapi/net/",
            "tmp-browser-smoke/fetch-abort/",
            "tmp-browser-smoke/fetch-credentials/",
            "tmp-browser-smoke/websocket-smoke/"
        )
    }
    [pscustomobject]@{
        Name = "shell"
        ChangeArea = "shell"
        Patterns = @(
            "src/app.zig",
            "src/config.zig",
            "src/main.zig",
            "src/lightpanda.zig",
            "src/browser/browser.zig",
            "src/display/browsercommand.zig",
            "tmp-browser-smoke/tabs/",
            "tmp-browser-smoke/browser-pages/",
            "tmp-browser-smoke/settings/",
            "tmp-browser-smoke/popup/",
            "tmp-browser-smoke/wrapped-link/",
            "tmp-browser-smoke/stop-loading/",
            "tmp-browser-smoke/bookmarks/"
        )
    }
)

$priority = @(
    "local-html-fixtures",
    "attached-html-target-bundle",
    "google-attached-html",
    "attached-html",
    "google-input",
    "input",
    "rendering",
    "graphics",
    "downloads",
    "storage",
    "network",
    "shell"
)

function Normalize-RepoPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $normalized = $Value.Replace("\", "/").Trim().ToLowerInvariant()
    $normalized = $normalized -replace '^[.]/', ''
    return $normalized
}

function Test-RuleMatch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$NormalizedPath,
        [Parameter(Mandatory = $true)]
        [object]$Rule
    )

    foreach ($pattern in $Rule.Patterns) {
        $normalizedPattern = Normalize-RepoPath -Value $pattern
        if ($NormalizedPath.Contains($normalizedPattern)) {
            return $pattern
        }
    }

    return $null
}

if (-not $Path -or $Path.Count -eq 0) {
    throw "Pass one or more repo-relative paths with -Path."
}

$normalizedPaths = @($Path | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { Normalize-RepoPath -Value $_ })
if ($normalizedPaths.Count -eq 0) {
    throw "No non-empty paths were provided."
}

$matches = New-Object System.Collections.Generic.List[object]
foreach ($item in $normalizedPaths) {
    foreach ($rule in $rules) {
        $matchedPattern = Test-RuleMatch -NormalizedPath $item -Rule $rule
        if ($matchedPattern) {
            $matches.Add([pscustomobject]@{
                path = $item
                change_area = $rule.ChangeArea
                matched_pattern = $matchedPattern
            })
        }
    }
}

$uniqueAreas = @(
    foreach ($name in $priority) {
        if ($matches.change_area -contains $name) {
            $name
        }
    }
)

if ($uniqueAreas.Count -eq 0) {
    $uniqueAreas = @("manual-html")
}

$primaryArea = $uniqueAreas[0]
$commands = @(
    foreach ($area in $uniqueAreas) {
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea $area"
    }
)

$result = [ordered]@{
    input_paths = $normalizedPaths
    primary_change_area = $primaryArea
    suggested_change_areas = $uniqueAreas
    matched_rules = @($matches)
    commands = $commands
    note = "Start with the primary change area, then widen only if the touched files cross subsystem boundaries."
}

if ($Json) {
    $result | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed validation routing from changed paths"
Write-Host ""
Write-Host ("Primary change area: {0}" -f $primaryArea)
Write-Host ("Suggested change areas: {0}" -f ($uniqueAreas -join ", "))
Write-Host ""
Write-Host "Inputs:"
foreach ($item in $normalizedPaths) {
    Write-Host ("- {0}" -f $item)
}
Write-Host ""
if ($matches.Count -gt 0) {
    Write-Host "Matched rules:"
    foreach ($match in $matches) {
        Write-Host ("- {0} -> {1} ({2})" -f $match.path, $match.change_area, $match.matched_pattern)
    }
    Write-Host ""
}
Write-Host "Next commands:"
foreach ($command in $commands) {
    Write-Host ("- {0}" -f $command)
}
Write-Host ""
Write-Host $result.note