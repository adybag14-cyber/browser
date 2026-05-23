[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-LightpandaRepoRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StartPath
    )

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor 'build.zig')) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            throw "Could not resolve the Lightpanda repo root from $StartPath. Pass -RepoRoot to override."
        }

        $cursor = $parent
    }
}

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

function New-ReferenceCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Purpose
    )

    [pscustomobject]@{
        Path = $Path
        Purpose = $Purpose
        Exists = Test-Path -LiteralPath (Join-Path $resolvedRepoRoot $Path) -PathType Leaf
    }
}

function New-ContentCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Snippet,
        [Parameter(Mandatory = $true)]
        [string]$Purpose
    )

    $fullPath = Join-Path $resolvedRepoRoot $Path
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        return [pscustomobject]@{
            Path = $Path
            Purpose = $Purpose
            Snippet = $Snippet
            Exists = $false
        }
    }

    $content = Get-Content -LiteralPath $fullPath -Raw
    return [pscustomobject]@{
        Path = $Path
        Purpose = $Purpose
        Snippet = $Snippet
        Exists = $content.Contains($Snippet)
    }
}

$references = @(
    (New-ReferenceCheck -Path 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md' -Purpose 'Read-first runtime note for the Google Enter-submit revalidation slice.'),
    (New-ReferenceCheck -Path 'docs/WINDOWS_FULL_USE.md' -Purpose 'Windows-first runbook that still anchors local headed validation.'),
    (New-ReferenceCheck -Path 'docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md' -Purpose 'Broader headed-mode runbook kept beside the runtime note.'),
    (New-ReferenceCheck -Path 'tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1' -Purpose 'Reduced Google probe that should stay first before widening back out to live Google.'),
    (New-ReferenceCheck -Path 'src/browser/tests/page/google_home_title_probe.html' -Purpose 'Reduced Google fixture that keeps the Enter ordering replay local and bounded.'),
    (New-ReferenceCheck -Path 'scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1' -Purpose 'Helper that prints the current runtime revalidation route.')
)

$contentChecks = @(
    (New-ContentCheck -Path 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md' -Snippet 'tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1' -Purpose 'Runtime note still points to the reduced Google probe.'),
    (New-ContentCheck -Path 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md' -Snippet 'src/browser/tests/page/google_home_title_probe.html' -Purpose 'Runtime note still points to the reduced Google fixture.'),
    (New-ContentCheck -Path 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md' -Snippet 'src/browser/Page.zig' -Purpose 'Runtime note still anchors the Page.zig side of the fix.'),
    (New-ContentCheck -Path 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md' -Snippet 'src/display/win32_backend.zig' -Purpose 'Runtime note still anchors the Win32 backend side of the fix.'),
    (New-ContentCheck -Path 'scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1' -Snippet 'chrome-google-home-title-probe.ps1' -Purpose 'Helper still prints the reduced Google probe command.'),
    (New-ContentCheck -Path 'scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1' -Snippet 'google_home_title_probe.html?google-home-probe=1' -Purpose 'Helper still prints the reduced Google fixture route.'),
    (New-ContentCheck -Path 'scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1' -Snippet 'https://www.google.com/' -Purpose 'Helper still keeps live Google as the later widening step.')
)

$allChecks = @($references + $contentChecks)
$missing = @($allChecks | Where-Object { -not $_.Exists })

if ($Json) {
    [ordered]@{
        profile = 'google-issue3-enter-submit-runtime-validation-surface'
        repo_root = $resolvedRepoRoot
        checked_count = $allChecks.Count
        missing_count = $missing.Count
        references = $references
        content_checks = $contentChecks
    } | ConvertTo-Json -Depth 6

    if ($missing.Count -gt 0) {
        exit 1
    }

    exit 0
}

Write-Host 'Google issue #3 Enter-submit runtime validation surface check'
Write-Host ''
Write-Host (("Repo root: {0}") -f $resolvedRepoRoot)
Write-Host ''

foreach ($check in $allChecks) {
    $status = if ($check.Exists) { 'PASS' } else { 'FAIL' }
    Write-Host (("[{0}] {1}") -f $status, $check.Path)
    Write-Host (("  {0}") -f $check.Purpose)
}

if ($missing.Count -gt 0) {
    Write-Host ''
    Write-Host 'Missing expectations:'
    foreach ($check in $missing) {
        Write-Host (("  - {0}") -f $check.Path)
    }
    exit 1
}

Write-Host ''
Write-Host 'Validation surface is complete.'
