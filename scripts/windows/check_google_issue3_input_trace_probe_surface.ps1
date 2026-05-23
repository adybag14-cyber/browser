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
        [string]$Purpose
    )

    [pscustomobject]@{
        Path = $Path
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
    (New-ValidationReference -Path 'docs/ISSUE3_GOOGLE_INPUT_TRACE_PROBE.md' -Purpose 'Read-first note for the compact issue #3 Google input trace route.'),
    (New-ValidationReference -Path 'scripts/windows/show_google_issue3_input_trace_probe.ps1' -Purpose 'Helper that prints the live probe command, artifacts, and interpretation hints.'),
    (New-ValidationReference -Path 'scripts/windows/check_google_issue3_input_trace_probe_surface.ps1' -Purpose 'Fail-fast checker for the compact Google input trace route.'),
    (New-ValidationReference -Path 'scripts/windows/HeadedValidationHelpers.ps1' -Purpose 'Shared repo-root helper used by the compact Google input trace route.'),
    (New-ValidationReference -Path 'tmp-browser-smoke/google-investigation-next/chrome-google-input-trace-probe.ps1' -Purpose 'Live headed Google trace probe that captures title changes and Win32/runtime trace tails.')
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path 'docs/ISSUE3_GOOGLE_INPUT_TRACE_PROBE.md' -Snippet 'check_google_issue3_input_trace_probe_surface.ps1' -Purpose 'The note tells future runs to fail fast on the compact trace surface before trusting the route.'),
    (New-ValidationContentExpectation -Path 'docs/ISSUE3_GOOGLE_INPUT_TRACE_PROBE.md' -Snippet 'chrome-google-input-trace-probe.ps1' -Purpose 'The note keeps the live trace probe path visible.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_input_trace_probe.ps1' -Snippet "Join-Path \$resolvedRepoRoot 'tmp-browser-smoke/google-investigation-next/chrome-google-input-trace-probe.ps1'" -Purpose 'The helper stays wired to the branch-tracked Google input trace probe.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_input_trace_probe.ps1' -Snippet "surface_check = 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_input_trace_probe_surface.ps1'" -Purpose 'The helper keeps the fail-fast checker visible beside the direct trace command.'),
    (New-ValidationContentExpectation -Path 'tmp-browser-smoke/google-investigation-next/chrome-google-input-trace-probe.ps1' -Snippet 'runtime-input-backend-*.log' -Purpose 'The live probe still captures the runtime input backend traces needed for issue #3 narrowing.'),
    (New-ValidationContentExpectation -Path 'tmp-browser-smoke/google-investigation-next/chrome-google-input-trace-probe.ps1' -Snippet 'wndproc-input-*.log' -Purpose 'The live probe still captures the Win32 input traces needed for issue #3 narrowing.')
)

$referenceResults = foreach ($reference in $references) {
    $fullPath = Join-Path $resolvedRepoRoot $reference.Path
    [pscustomobject]@{
        CheckType = 'reference'
        Path = $reference.Path
        Purpose = $reference.Purpose
        Exists = [bool](Test-Path -LiteralPath $fullPath -PathType Leaf)
    }
}

$contentCache = @{}
$contentResults = foreach ($expectation in $contentExpectations) {
    $fullPath = Join-Path $resolvedRepoRoot $expectation.Path
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        [pscustomobject]@{
            CheckType = 'content'
            Path = $expectation.Path
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
        Purpose = $expectation.Purpose
        Exists = [bool]$contentCache[$fullPath].Contains($expectation.Snippet)
        Snippet = $expectation.Snippet
    }
}

$results = @($referenceResults + $contentResults)
$missing = @($results | Where-Object { -not $_.Exists })

$summary = [ordered]@{
    issue = 'Google issue #3 input trace probe surface'
    repo_root = $resolvedRepoRoot
    ok = ($missing.Count -eq 0)
    missing_count = $missing.Count
    checks = $results
}

if ($Json) {
    $summary | ConvertTo-Json -Depth 6
    exit 0
}

if ($summary.ok) {
    Write-Host 'Google issue #3 input trace surface is ready.'
    exit 0
}

Write-Error ('Google issue #3 input trace surface is missing {0} required item(s).' -f $missing.Count)
