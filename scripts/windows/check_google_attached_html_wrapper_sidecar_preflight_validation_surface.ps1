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
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_WRAPPER_SIDECAR_PREFLIGHT.md" -Kind "file" -Purpose "Compact written route for the wrapper-backed Google attached-page sidecar preflight."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Broader Google attached-page flow note that the compact preflight hands off into."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared repo-root helper surface used by the compact wrapper-backed preflight helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_wrapper_sidecar_preflight.ps1" -Kind "file" -Purpose "Compact helper that prints the wrapper-backed Google attached-page preflight commands."),
    (New-ValidationReference -Path "scripts/windows/start_attached_pages_catalog.ps1" -Kind "file" -Purpose "Windows wrapper that owns the Google-style sidecar audit, manifest, and strict launch commands."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader Google attached-page flow helper that should stay visible beside the compact wrapper-backed preflight surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/attached-pages/README.md" -Kind "file" -Purpose "Attached-pages launcher guide that documents the underlying launcher surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py" -Kind "file" -Purpose "Lower-level launcher entrypoint used when the wrapper should be bypassed explicitly.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_attached_html_wrapper_sidecar_preflight.ps1" -Snippet 'surface_check_command = Format-WrapperCommand -ScriptName ''check_google_attached_html_wrapper_sidecar_preflight_validation_surface.ps1'' -Arguments $surfaceCheckArguments' -Purpose "Helper keeps its dedicated fail-fast checker wired into the compact preflight surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_attached_html_wrapper_sidecar_preflight.ps1" -Snippet 'wrapper_google_sidecar_audit = Format-WrapperCommand -ScriptName ''start_attached_pages_catalog.ps1'' -Arguments $wrapperArguments -Switches @(''GoogleStyle'', ''AuditSidecars'')' -Purpose "Helper keeps the wrapper-backed Google-style sidecar audit as the default next step."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_attached_html_wrapper_sidecar_preflight.ps1" -Snippet 'wrapper_google_manifest = Format-WrapperCommand -ScriptName ''start_attached_pages_catalog.ps1'' -Arguments $wrapperArguments -Switches @(''GoogleStyle'', ''PrintManifest'')' -Purpose "Helper keeps the wrapper-backed Google-style manifest print visible beside the sidecar audit."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_attached_html_wrapper_sidecar_preflight.ps1" -Snippet 'wrapper_google_strict_launch = Format-WrapperCommand -ScriptName ''start_attached_pages_catalog.ps1'' -Arguments $wrapperArguments -Switches @(''GoogleStyle'', ''RequireCompleteSidecars'')' -Purpose "Helper keeps the wrapper-backed strict Google-style launch visible after the sidecar audit."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_attached_html_wrapper_sidecar_preflight.ps1" -Snippet 'broader_google_flow = Format-WrapperCommand -ScriptName ''show_google_attached_html_validation_flow.ps1'' -Arguments $wrapperArguments' -Purpose "Helper keeps the broader Google attached-page flow visible as the next handoff after preflight."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_attached_html_wrapper_sidecar_preflight.ps1" -Snippet 'python_google_sidecar_audit = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -Flags @(''--google-style'', ''--audit-sidecars'')' -Purpose "Helper keeps the lower-level Python launcher visible only as an explicit fallback."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_attached_html_wrapper_sidecar_preflight.ps1" -Snippet 'Write-Host (("Surface check:         {0}") -f $helper.surface_check_command)' -Purpose "Helper prints the dedicated checker before the wrapper-backed ladder."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_attached_html_wrapper_sidecar_preflight.ps1" -Snippet 'Write-Host (("  1. Google sidecars:    {0}") -f $helper.helper_commands.wrapper_google_sidecar_audit)' -Purpose "Helper prints the wrapper-backed Google-style sidecar audit as the first ladder step."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_attached_html_wrapper_sidecar_preflight.ps1" -Snippet 'Write-Host (("Preflight note:         {0}") -f $helper.companion_paths.preflight_note)' -Purpose "Helper prints the compact written route note beside the broader flow references."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_attached_html_wrapper_sidecar_preflight.ps1" -Snippet 'Prefer the wrapper-backed Google-style sidecar audit before the broader Google attached-page helper when the saved export itself may be incomplete.' -Purpose "Helper notes explain why the wrapper-backed sidecar audit comes before the broader flow helper.")
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
        profile = "google-attached-html-wrapper-sidecar-preflight"
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

Write-Host "Google attached HTML wrapper sidecar preflight surface check"
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
    Write-Host "Google attached HTML wrapper sidecar preflight surface is intact."
    exit 0
}

Write-Host (("Missing {0} wrapper-backed Google attached-page preflight path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the compact note, helper output contract, wrapper-backed launcher ladder, broader handoff, or fallback launcher reference before trusting this preflight surface."
exit 1
