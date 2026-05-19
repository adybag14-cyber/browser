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
    (New-ValidationReference -Path 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md' -Kind 'file' -Purpose 'Replay-side attached HTML quickstart note that now surfaces the launcher companion checker and helper.'),
    (New-ValidationReference -Path 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md' -Kind 'file' -Purpose 'Broader Google attached HTML flow note that stays adjacent to the launcher companion route.'),
    (New-ValidationReference -Path 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md' -Kind 'file' -Purpose 'Issue-specific Google attached HTML entrypoint note that stays nearby after the launcher companion route.'),
    (New-ValidationReference -Path 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md' -Kind 'file' -Purpose 'Pinned bundle proof note that should stay reachable from the launcher companion route once replay is already locked to the three-page compatibility set.'),
    (New-ValidationReference -Path 'scripts/windows/HeadedValidationHelpers.ps1' -Kind 'file' -Purpose 'Shared repo-root helper surface used by the launcher companion helper and this checker.'),
    (New-ValidationReference -Path 'scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Kind 'file' -Purpose 'Fail-fast checker for the issue 3 attached-pages launcher companion surface.'),
    (New-ValidationReference -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Kind 'file' -Purpose 'Attached-pages launcher companion helper that this checker validates.'),
    (New-ValidationReference -Path 'scripts/windows/check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Kind 'file' -Purpose 'Pinned bundle proof surface checker that should stay reachable from the launcher companion route.'),
    (New-ValidationReference -Path 'scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Kind 'file' -Purpose 'Pinned bundle proof helper that should stay reachable from the launcher companion route.'),
    (New-ValidationReference -Path 'scripts/windows/start_attached_pages_catalog.ps1' -Kind 'file' -Purpose 'Windows wrapper-backed attached-pages launcher surfaced by the companion helper.'),
    (New-ValidationReference -Path 'tmp-browser-smoke/attached-pages/README.md' -Kind 'file' -Purpose 'Attached-pages launcher README surfaced as a companion path by the helper.'),
    (New-ValidationReference -Path 'tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py' -Kind 'file' -Purpose 'Cross-platform attached-pages launcher surfaced by the companion helper.')
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet "surface_check_command = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments `$surfaceCheckArguments" -Purpose 'Launcher companion helper wires its dedicated fail-fast checker into the surfaced command map.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet "launcher_companion_surface_check = 'scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1'" -Purpose 'Launcher companion helper keeps the checker path visible in its companion paths map.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet "wrapper_google_sidecar_audit = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments `$wrapperArguments -Switches @('GoogleStyle', 'AuditSidecars')" -Purpose 'Launcher companion helper keeps the Google-style wrapper sidecar audit in the printed ladder.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet "wrapper_strict_bundle = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments `$wrapperArguments -Switches @('RequireCompleteSidecars', 'RequireCompleteAssets')" -Purpose 'Launcher companion helper surfaces the combined strict sidecar-plus-asset wrapper launch path.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet "wrapper_google_strict_bundle = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments `$wrapperArguments -Switches @('GoogleStyle', 'RequireCompleteSidecars', 'RequireCompleteAssets')" -Purpose 'Launcher companion helper surfaces the combined strict Google-style wrapper launch path.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet "python_sidecar_audit = Format-PythonLauncherCommand -RepoRootOverride `$resolvedRepoRoot -InputValues `$InputPath -PreferredInitialPage `$PreferredInitialPage -Flags @('--audit-sidecars')" -Purpose 'Launcher companion helper preserves the preferred first page through the lower-level Python sidecar audit path.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet "python_google_sidecar_audit = Format-PythonLauncherCommand -RepoRootOverride `$resolvedRepoRoot -InputValues `$InputPath -PreferredInitialPage `$PreferredInitialPage -Flags @('--google-style', '--audit-sidecars')" -Purpose 'Launcher companion helper preserves the preferred first page through the lower-level Google-style Python sidecar audit path.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet "python_strict_bundle = Format-PythonLauncherCommand -RepoRootOverride `$resolvedRepoRoot -InputValues `$InputPath -PreferredInitialPage `$PreferredInitialPage -Flags @('--require-complete-sidecars', '--require-complete-assets')" -Purpose 'Launcher companion helper preserves the preferred first page through the lower-level strict Python launch path.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet "python_google_strict_bundle = Format-PythonLauncherCommand -RepoRootOverride `$resolvedRepoRoot -InputValues `$InputPath -PreferredInitialPage `$PreferredInitialPage -Flags @('--google-style', '--require-complete-sidecars', '--require-complete-assets')" -Purpose 'Launcher companion helper preserves the preferred first page through the lower-level strict Google-style Python launch path.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host (("  6. Strict bundle:      {0}") -f $helper.helper_commands.wrapper_strict_bundle)' -Purpose 'Launcher companion helper prints the combined strict wrapper launch path in the Windows ladder.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host (("  10. Google strict:     {0}") -f $helper.helper_commands.wrapper_google_strict_bundle)' -Purpose 'Launcher companion helper prints the combined strict Google-style wrapper launch path in the Windows ladder.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host (("  6. Strict bundle:      {0}") -f $helper.helper_commands.python_strict_bundle)' -Purpose 'Launcher companion helper prints the combined strict Python launch path in the cross-platform ladder.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host (("  10. Google strict:     {0}") -f $helper.helper_commands.python_google_strict_bundle)' -Purpose 'Launcher companion helper prints the combined strict Google-style Python launch path in the cross-platform ladder.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host (("Surface check:         {0}") -f $helper.surface_check_command)' -Purpose 'Launcher companion helper prints the fail-fast checker before the command ladders.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host (("Launcher surface check: {0}") -f $helper.companion_paths.launcher_companion_surface_check)' -Purpose 'Launcher companion helper prints the checker path again with the companion paths.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Use the strict bundle commands when both sidecars and referenced local assets must be complete before a manifest print or localhost launch is trusted.' -Purpose 'Launcher companion helper usage notes explain when to use the combined strict bundle commands.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'The lower-level Python launcher ladder shown here now preserves the same preferred-first-page override, so cross-platform reruns can keep the pinned bundle order without hand-editing each command.' -Purpose 'Launcher companion helper notes keep the cross-platform preferred-first-page support visible after the Python ladder gains parity with the wrapper.'),
    (New-ValidationContentExpectation -Path 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md' -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Purpose 'Replay attached HTML quickstart keeps the launcher companion checker visible before the companion helper is trusted.'),
    (New-ValidationContentExpectation -Path 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md' -Snippet "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'" -Purpose 'Replay attached HTML quickstart keeps the launcher companion helper visible after the checker.'),
    (New-ValidationContentExpectation -Path 'tmp-browser-smoke/attached-pages/README.md' -Snippet 'scripts/windows/start_attached_pages_catalog.ps1' -Purpose 'Attached-pages README still documents the Windows wrapper surfaced by the launcher companion helper.'),
    (New-ValidationContentExpectation -Path 'tmp-browser-smoke/attached-pages/README.md' -Snippet '--audit-sidecars' -Purpose 'Attached-pages README still documents the sidecar-first preflight mode surfaced by the launcher companion helper.'),
    (New-ValidationContentExpectation -Path 'tmp-browser-smoke/attached-pages/README.md' -Snippet "--require-complete-sidecars \\
  --require-complete-assets" -Purpose 'Attached-pages README still documents the combined strict launcher path that the companion helper now mirrors.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/start_attached_pages_catalog.ps1' -Snippet '$launcherArgs += "--audit-sidecars"' -Purpose 'Windows wrapper still forwards the sidecar-audit mode that the launcher companion recommends first.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/start_attached_pages_catalog.ps1' -Snippet '$launcherArgs += "--require-complete-assets"' -Purpose 'Windows wrapper still forwards the strict-asset launch gate that the launcher companion surfaces beside the rest of the preflight ladder.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/start_attached_pages_catalog.ps1' -Snippet '[string]$PreferredInitialPage,' -Purpose 'Windows wrapper still accepts the preferred-first-page override that the launcher companion promises across its surfaced ladder.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/start_attached_pages_catalog.ps1' -Snippet '$orderedInputs = Resolve-OrderedAttachedHtmlInputs -RawInputPath $InputPath -PreferredPage $PreferredInitialPage' -Purpose 'Windows wrapper still reorders explicit attached-page inputs through the preferred-first-page helper before printing the manifest or starting localhost replay.'),
    (New-ValidationContentExpectation -Path 'tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py' -Snippet '--preferred-initial-page' -Purpose 'Cross-platform attached-pages launcher still accepts the preferred-first-page override that the launcher companion promises for Linux reruns.'),
    (New-ValidationContentExpectation -Path 'tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py' -Snippet 'preferred_initial_page=args.preferred_initial_page,' -Purpose 'Cross-platform attached-pages launcher still threads the preferred-first-page override into fixture selection before manifest generation and localhost startup.')
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
        profile = 'google-issue3-attached-pages-launcher-companion'
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

Write-Host 'Google issue #3 attached-pages launcher companion surface check'
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
    Write-Host 'Google issue #3 attached-pages launcher companion surface is intact, including the strict sidecar-plus-asset launch gates, the preferred-first-page wrapper and Python handoff, and the pinned proof-route bridge back into the three-page compatibility bundle.'
    exit 0
}

Write-Host (("Missing {0} attached-pages launcher companion path or source contract check(s).") -f $missing.Count)
Write-Host 'Repair the replay note, launcher companion helper, proof-route bridge, preferred-first-page handoff, wrapper-backed launcher paths, or cross-platform launcher references before trusting the attached-pages launcher companion route.'
exit 1
