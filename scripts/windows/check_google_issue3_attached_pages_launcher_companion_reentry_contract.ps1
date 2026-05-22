[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'HeadedValidationHelpers.ps1')

function New-ValidationReference {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [ValidateSet('file', 'directory')]
        [string]$Kind,
        [Parameter(Mandatory = $true)]
        [string]$Purpose
    )

    [pscustomobject]@{
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

$references = @(
    (New-ValidationReference -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Kind 'file' -Purpose 'Launcher companion helper whose replay re-entry contract should stay stable.'),
    (New-ValidationReference -Path 'scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Kind 'file' -Purpose 'Windows replay quickstart helper that should stay on the replay-aware argument path from the launcher companion helper.'),
    (New-ValidationReference -Path 'scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Kind 'file' -Purpose 'Replay-route shortcut helper that should stay on the replay-aware argument path from the launcher companion helper.'),
    (New-ValidationReference -Path 'scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Kind 'file' -Purpose 'Pinned proof helper that should stay on the replay-aware argument path from the launcher companion helper.')
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet "Add-SharedArgument -Arguments `\$replayArguments -Name SummaryPath -Value `\$SummaryPath" -Purpose 'Launcher companion helper keeps SummaryPath on the replay handoff argument set.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet "Add-SharedArgument -Arguments `\$replayArguments -Name BrowserExe -Value `\$BrowserExe" -Purpose 'Launcher companion helper keeps BrowserExe on the replay handoff argument set.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet "Add-SharedArgument -Arguments `\$replayArguments -Name PreferredInitialPage -Value `\$PreferredInitialPage" -Purpose 'Launcher companion helper keeps PreferredInitialPage on the replay handoff argument set.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet "proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments `\$replayArguments" -Purpose 'Pinned proof helper stays wired to the replay-aware handoff arguments.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet "windows_replay_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments `\$replayArguments" -Purpose 'Windows replay quickstart stays wired to the replay-aware handoff arguments.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet "replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments `\$replayArguments" -Purpose 'Replay-route shortcut stays wired to the replay-aware handoff arguments.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'The replay re-entry helpers now preserve -SummaryPath and -BrowserExe when attached-page preflight hands control back into the Windows replay quickstart, the replay-route shortcut, or the pinned bundle proof helper.' -Purpose 'Launcher companion helper notes keep the replay re-entry contract visible to future runs.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\"Summary path: {0}\") -f $helper.summary_path)' -Purpose 'Launcher companion helper prints the current saved summary path when one is pinned.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\"Browser exe: {0}\") -f $helper.browser_exe)' -Purpose 'Launcher companion helper prints the current browser executable when one is pinned.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet "Write-Host 'Replay re-entry helpers:'" -Purpose 'Launcher companion helper prints a dedicated replay re-entry section.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\"  Windows replay quick: {0}\") -f $helper.helper_commands.windows_replay_quickstart)' -Purpose 'Launcher companion helper prints the Windows replay quickstart handoff in the replay re-entry section.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\"  Replay-route helper: {0}\") -f $helper.helper_commands.replay_route_shortcut)' -Purpose 'Launcher companion helper prints the replay-route shortcut handoff in the replay re-entry section.')
)

$referenceResults = foreach ($reference in $references) {
    $fullPath = Join-Path $resolvedRepoRoot $reference.Path
    $exists = if ($reference.Kind -eq 'directory') {
        Test-Path -LiteralPath $fullPath -PathType Container
    } else {
        Test-Path -LiteralPath $fullPath -PathType Leaf
    }

    [pscustomobject]@{
        CheckType = 'reference'
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
            CheckType = 'content'
            Path = $expectation.Path
            Kind = 'content-snippet'
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
        CheckType = 'content'
        Path = $expectation.Path
        Kind = 'content-snippet'
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
        profile = 'google-issue3-attached-pages-launcher-companion-reentry-contract'
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

Write-Host 'Google issue #3 attached-pages launcher companion replay re-entry contract check'
Write-Host ''
Write-Host (("Repo root: {0}") -f $resolvedRepoRoot)
Write-Host ''

foreach ($result in $referenceResults) {
    $status = if ($result.Exists) { 'PASS' } else { 'FAIL' }
    Write-Host (("[{0}] {1}") -f $status, $result.Path)
    Write-Host (("  {0}") -f $result.Purpose)
}

if ($contentResults.Count -gt 0) {
    Write-Host ''
    Write-Host 'Helper source expectations:'
    foreach ($result in $contentResults) {
        $status = if ($result.Exists) { 'PASS' } else { 'FAIL' }
        Write-Host (("[{0}] {1}") -f $status, $result.Path)
        Write-Host (("  {0}") -f $result.Purpose)
    }
}

Write-Host ''
if ($missing.Count -eq 0) {
    Write-Host 'Google issue #3 attached-pages launcher companion replay re-entry contract is intact.'
    exit 0
}

Write-Host (("Missing {0} launcher companion replay re-entry contract path or source check(s).") -f $missing.Count)
Write-Host 'Repair the replay-aware argument propagation, replay handoff commands, or replay-contract output before trusting the launcher companion to preserve saved summary, preferred page, and browser-executable context across attached-page preflight.'
exit 1
