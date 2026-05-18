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
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached-page flow note that the launcher companion keeps visible beside the sidecar-first preflight ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-page entrypoint note that should stay aligned with the launcher companion helper."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Windows-first attached-pages catalog quickstart note that depends on the same wrapper-backed sidecar preflight surface."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-pages quickstart note that stays aligned with the launcher companion helper surface."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware launcher commands."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the issue #3 attached-pages launcher companion surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Kind "file" -Purpose "Attached-pages launcher companion helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/start_attached_pages_catalog.ps1" -Kind "file" -Purpose "Windows wrapper that should stay aligned with the launcher companion ladder."),
    (New-ValidationReference -Path "tmp-browser-smoke/attached-pages/README.md" -Kind "file" -Purpose "Attached-pages launcher guide that should stay aligned with the wrapper and Python ladders printed by the companion helper."),
    (New-ValidationReference -Path "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py" -Kind "file" -Purpose "Cross-platform attached-pages launcher entrypoint that should stay aligned with the companion helper ladder.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet 'surface_check_command = Format-HelperCommand -ScriptName ''check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1'' -Arguments $surfaceCheckArguments' -Purpose "Launcher companion helper keeps its dedicated fail-fast checker wired into the helper surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet 'surface_check_reason = ''Use this first when the launcher companion itself, its note pointers, or the wrapper-backed attached-pages route may have drifted.''' -Purpose "Launcher companion helper explains when to run the dedicated surface check before trusting the sidecar-first ladder."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet 'launcher_companion_surface_check = ''scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1''' -Purpose "Launcher companion helper keeps the checker path visible beside the wrapper and Python entrypoints."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet 'wrapper_google_sidecar_audit = Format-HelperCommand -ScriptName ''start_attached_pages_catalog.ps1'' -Arguments $wrapperArguments -Switches @(''GoogleStyle'', ''AuditSidecars'')' -Purpose "Launcher companion helper keeps the Google-style wrapper sidecar audit in the printed ladder."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet 'python_google_sidecar_audit = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -Flags @(''--google-style'', ''--audit-sidecars'')' -Purpose "Launcher companion helper keeps the Google-style Python sidecar audit in the printed ladder."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet 'Write-Host (("Surface check:         {0}") -f $helper.surface_check_command)' -Purpose "Launcher companion helper prints the dedicated surface-check command before the sidecar-first ladder."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet 'Write-Host (("Guard reason:          {0}") -f $helper.surface_check_reason)' -Purpose "Launcher companion helper prints why the dedicated surface check should run first when drift is suspected."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet 'Write-Host (("Launcher surface check: {0}") -f $helper.companion_paths.launcher_companion_surface_check)' -Purpose "Launcher companion helper prints the checker path beside the wrapper and Python launcher companion paths."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet 'Run the surface check first when the launcher companion itself, its note pointers, or the wrapper-backed attached-pages route may have drifted.' -Purpose "Launcher companion usage notes keep the guarded-helper workflow visible for future replay runs."),
    (New-ValidationContentExpectation -Path "tmp-browser-smoke/attached-pages/README.md" -Snippet 'scripts/windows/start_attached_pages_catalog.ps1' -Purpose "Attached-pages README still documents the Windows wrapper surfaced by the launcher companion helper."),
    (New-ValidationContentExpectation -Path "tmp-browser-smoke/attached-pages/README.md" -Snippet '--audit-sidecars' -Purpose "Attached-pages README still documents the sidecar-first preflight mode surfaced by the launcher companion helper."),
    (New-ValidationContentExpectation -Path "scripts/windows/start_attached_pages_catalog.ps1" -Snippet '$launcherArgs += "--audit-sidecars"' -Purpose "Windows wrapper still forwards the sidecar-audit mode that the launcher companion recommends first."),
    (New-ValidationContentExpectation -Path "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py" -Snippet '        "--audit-sidecars",' -Purpose "Python launcher still exposes the sidecar-audit mode that the launcher companion keeps in the printed ladder.")
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
        profile = "google-issue3-attached-pages-launcher-companion"
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

Write-Host "Google issue #3 attached-pages launcher companion surface check"
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
    Write-Host "Google issue #3 attached-pages launcher companion surface is intact."
    exit 0
}

Write-Host (("Missing {0} attached-pages launcher companion path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing note, helper output contract, wrapper-backed sidecar ladder, or launcher guide before trusting the issue #3 attached-pages launcher companion route."
exit 1
