[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-LightpandaRepoRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StartPath
    )

    if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
        return $env:LIGHTPANDA_REPO_ROOT
    }

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor "build.zig")) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            throw "Could not resolve the Lightpanda repo root from $StartPath. Set LIGHTPANDA_REPO_ROOT to override."
        }
        $cursor = $parent
    }
}

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
    Resolve-LightpandaRepoRoot -StartPath $PSScriptRoot
}

$references = @(
    (New-ValidationReference -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Kind "file" -Purpose "Read-first note for the exact issue #3 runtime slice on the headed Enter-submit path."),
    (New-ValidationReference -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Kind "file" -Purpose "Broader headed execution guide kept beside the narrow issue #3 runtime slice."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows replay guide used after the runtime slice is confirmed or repaired."),
    (New-ValidationReference -Path "src/browser/Page.zig" -Kind "file" -Purpose "Page runtime source that should own the deferred native Enter-submit state and helpers."),
    (New-ValidationReference -Path "src/display/win32_backend.zig" -Kind "file" -Purpose "Win32 backend source that should bracket keypress-time deferred Enter submit and byte-matched text suppression."),
    (New-ValidationReference -Path "src/browser/tests/page/google_home_title_probe.html" -Kind "file" -Purpose "Reduced Google-style probe used before widening back out to the live homepage."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1" -Kind "file" -Purpose "Windows replay probe used after the runtime slice is confirmed or repaired.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "_defer_native_text_input_enter_submit: bool" -Purpose "The runtime note keeps the deferred Page state field visible."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "_pending_native_enter_submit: ?*Element.Html.Input" -Purpose "The runtime note keeps the focused-input submit queue visible."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "beginDeferredNativeTextInputEnterSubmit()" -Purpose "The runtime note keeps the deferred-submit begin helper visible."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "applyDeferredNativeTextInputEnterSubmit()" -Purpose "The runtime note keeps the deferred-submit apply helper visible."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "std.ArrayListUnmanaged(TextInputEvent)" -Purpose "The runtime note keeps the byte-matched Win32 text suppression queue visible."),
    (New-ValidationContentExpectation -Path "src/browser/Page.zig" -Snippet "_defer_native_text_input_enter_submit" -Purpose "Page.zig exposes the deferred native Enter-submit flag."),
    (New-ValidationContentExpectation -Path "src/browser/Page.zig" -Snippet "_pending_native_enter_submit" -Purpose "Page.zig exposes the focused input pointer queued for deferred submit."),
    (New-ValidationContentExpectation -Path "src/browser/Page.zig" -Snippet "beginDeferredNativeTextInputEnterSubmit" -Purpose "Page.zig exposes the helper that starts deferred native Enter-submit handling."),
    (New-ValidationContentExpectation -Path "src/browser/Page.zig" -Snippet "endDeferredNativeTextInputEnterSubmit" -Purpose "Page.zig exposes the helper that ends deferred native Enter-submit handling."),
    (New-ValidationContentExpectation -Path "src/browser/Page.zig" -Snippet "applyDeferredNativeTextInputEnterSubmit" -Purpose "Page.zig exposes the helper that applies the queued submit after keypress-time DOM handling."),
    (New-ValidationContentExpectation -Path "src/display/win32_backend.zig" -Snippet "std.ArrayListUnmanaged(TextInputEvent)" -Purpose "win32_backend.zig uses byte-matched queued suppression entries instead of only a scalar suppression count."),
    (New-ValidationContentExpectation -Path "src/display/win32_backend.zig" -Snippet "beginDeferredNativeTextInputEnterSubmit" -Purpose "win32_backend.zig brackets Enter keydown handling with the deferred-submit begin helper."),
    (New-ValidationContentExpectation -Path "src/display/win32_backend.zig" -Snippet "endDeferredNativeTextInputEnterSubmit" -Purpose "win32_backend.zig brackets Enter keydown handling with the deferred-submit end helper."),
    (New-ValidationContentExpectation -Path "src/display/win32_backend.zig" -Snippet "applyDeferredNativeTextInputEnterSubmit" -Purpose "win32_backend.zig applies the queued submit only after the keypress phase completes.")
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
        profile = "issue3-enter-submit-runtime-slice"
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

Write-Host "Issue #3 Enter-submit runtime slice surface check"
Write-Host ""
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
Write-Host ""

foreach ($result in $referenceResults) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host ("[{0}] {1}" -f $status, $result.Path)
    Write-Host ("  {0}" -f $result.Purpose)
}

if ($contentResults.Count -gt 0) {
    Write-Host ""
    Write-Host "Helper source expectations:"
    foreach ($result in $contentResults) {
        $status = if ($result.Exists) { "PASS" } else { "FAIL" }
        Write-Host ("[{0}] {1}" -f $status, $result.Path)
        Write-Host ("  {0}" -f $result.Purpose)
    }
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Issue #3 runtime slice is intact: the revalidation note, Page.zig deferred Enter-submit state, and Win32 byte-matched text suppression hooks are all present before headed replay widens back out."
    exit 0
}

Write-Host ("Missing {0} issue #3 runtime slice path or source-contract check(s)." -f $missing.Count)
Write-Host "Repair the deferred Enter-submit helpers in src/browser/Page.zig and the queued text-suppression hooks in src/display/win32_backend.zig before trusting deeper headed Google replay."
exit 1
