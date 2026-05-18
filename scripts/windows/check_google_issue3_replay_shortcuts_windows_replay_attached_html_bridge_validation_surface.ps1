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
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Written replay-shortcuts to Windows replay attached-page bridge note that this checker guards."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Replay-route shortcut note that should keep the replay-shortcuts bridge visible from the narrower replay-route surface."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Higher-level Windows replay quickstart note that should keep the replay-shortcuts bridge visible."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Kind "file" -Purpose "Higher-level replay discovery note that should keep the replay-shortcuts bridge visible."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1" -Kind "file" -Purpose "Replay-shortcuts bridge helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Replay-route shortcut helper that should stay surfaced beside the replay-shortcuts bridge."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Replay-side fail-fast checker that should stay surfaced from the replay-shortcuts bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-page quickstart helper that should stay surfaced from the replay-shortcuts bridge.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Snippet 'show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1' -Purpose "Replay-route shortcut note keeps the replay-shortcuts bridge helper visible from the narrower replay-route surface."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Snippet '- `docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md`' -Purpose "Replay-route shortcut note keeps the replay-shortcuts bridge note visible as a companion reference."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1' -Purpose "Windows replay quickstart keeps the replay-shortcuts bridge helper visible before the route narrows further."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Snippet 'show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1' -Purpose "Replay discovery handoff keeps the replay-shortcuts bridge helper visible from the higher-level replay route."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Snippet '- `docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md`' -Purpose "Replay discovery handoff keeps the replay-shortcuts bridge note visible as a companion reference."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1" -Snippet "replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $sharedArguments" -Purpose "Bridge helper keeps the replay-route shortcut helper wired into the compact follow-up surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1" -Snippet "windows_replay_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -Arguments $routeSurfaceArguments" -Purpose "Bridge helper keeps the replay-side fail-fast checker wired into the compact follow-up surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1" -Snippet "windows_replay_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $sharedArguments" -Purpose "Bridge helper keeps the replay-side attached-page quickstart wired into the compact follow-up surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1" -Snippet 'Write-Host ((\"  Replay-route shortcut:    {0}\") -f $bridge.commands.replay_route_shortcut)' -Purpose "Printed bridge output still surfaces the replay-route shortcut helper."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1" -Snippet 'Write-Host ((\"  Replay quickstart check:  {0}\") -f $bridge.commands.windows_replay_surface_check)' -Purpose "Printed bridge output still surfaces the replay-side fail-fast checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1" -Snippet 'Write-Host ((\"  Windows replay quick:     {0}\") -f $bridge.commands.windows_replay_quickstart)' -Purpose "Printed bridge output still surfaces the replay-side attached-page quickstart."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1" -Snippet 'Write-Host ((\"Replay-route note:          {0}\") -f (' -Purpose "Printed bridge output still surfaces the replay-route companion note."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1" -Snippet 'Write-Host ((\"Replay-shortcuts note:      {0}\") -f (' -Purpose "Printed bridge output still surfaces the replay-shortcuts bridge companion note.")
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
        profile = "google-issue3-replay-shortcuts-windows-replay-attached-html-bridge"
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

Write-Host "Google issue #3 replay-shortcuts Windows replay attached HTML bridge surface check"
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
    Write-Host "Helper source expectations:"
    foreach ($result in $contentResults) {
        $status = if ($result.Exists) { "PASS" } else { "FAIL" }
        Write-Host (("[{0}] {1}") -f $status, $result.Path)
        Write-Host (("  {0}") -f $result.Purpose)
    }
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Google issue #3 replay-shortcuts Windows replay attached HTML bridge surface is intact."
    exit 0
}

Write-Host (("Missing {0} replay-shortcuts Windows replay attached HTML bridge path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the replay-route shortcut note, the higher-level replay notes, the replay-shortcuts bridge helper, the replay-side fail-fast checker, or the replay-side quickstart before trusting this replay-shortcuts bridge surface."
exit 1