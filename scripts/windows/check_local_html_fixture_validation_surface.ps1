[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string[]]$InputPath,
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

function Test-HtmlFixtureFileName([string]$Path) {
    return [System.String]::Equals([System.IO.Path]::GetExtension($Path), ".html", [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-ExplicitInputChecks {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    $checks = foreach ($path in $Paths) {
        $itemExists = Test-Path -LiteralPath $path
        $resolvedPath = $null
        $itemKind = "missing"
        $htmlFileCount = 0
        $status = "FAIL"
        $detail = "Path does not exist."

        if ($itemExists) {
            $resolvedPath = (Resolve-Path -LiteralPath $path).Path
            $item = Get-Item -LiteralPath $resolvedPath

            if ($item.PSIsContainer) {
                $itemKind = "directory"
                $htmlFileCount = @(
                    Get-ChildItem -LiteralPath $resolvedPath -Recurse -File -Filter *.html
                ).Count

                if ($htmlFileCount -gt 0) {
                    $status = "PASS"
                    $detail = ("Directory contains {0} HTML file(s)." -f $htmlFileCount)
                } else {
                    $detail = "Directory does not contain any HTML files."
                }
            } else {
                $itemKind = "file"
                if (Test-HtmlFixtureFileName $resolvedPath) {
                    $htmlFileCount = 1
                    $status = "PASS"
                    $detail = "HTML file is ready for fixture replay."
                } else {
                    $detail = "File is not an HTML document."
                }
            }
        }

        [pscustomobject]@{
            RequestedPath = $path
            ResolvedPath = $resolvedPath
            Kind = $itemKind
            Exists = [bool]$itemExists
            HtmlFileCount = $htmlFileCount
            Status = $status
            Detail = $detail
        }
    }

    return @($checks)
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$inputMode = if ($InputPath -and $InputPath.Count -gt 0) {
    "explicit"
} else {
    "auto-discovered"
}
$explicitInputPathCount = if ($InputPath) { @($InputPath).Count } else { 0 }

$references = @(
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that documents the reusable local HTML fixture probe."),
    (New-ValidationReference -Path "docs/LOCAL_HTML_FIXTURE_VALIDATION_FLOW.md" -Kind "file" -Purpose "Read-first note for the fixed-list localhost fixture replay path."),
    (New-ValidationReference -Path "scripts/windows/show_local_html_fixture_validation_flow.ps1" -Kind "file" -Purpose "Printed flow helper for the fixed-list localhost fixture replay path."),
    (New-ValidationReference -Path "tmp-browser-smoke/README.md" -Kind "file" -Purpose "Top-level probe-suite index that routes saved-page follow-up into the local fixture probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/local-html-fixtures" -Kind "directory" -Purpose "Reusable staged localhost fixture workspace for saved HTML validation."),
    (New-ValidationReference -Path "tmp-browser-smoke/local-html-fixtures/README.md" -Kind "file" -Purpose "Compact probe contract for the fixed-list localhost fixture replay surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/local-html-fixtures/chrome-local-html-fixture-probe.ps1" -Kind "file" -Purpose "Main reusable local HTML fixture probe runner."),
    (New-ValidationReference -Path "scripts/windows/check_local_html_fixture_asset_closure.ps1" -Kind "file" -Purpose "Dedicated deep asset-closure preflight for fixed local HTML fixture bundles."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_local_asset_closure.ps1" -Kind "file" -Purpose "Shared recursive CSS and module-asset audit used by the local fixture asset-closure preflight."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared validation helper surface used by the local fixture preflight wrappers."),
    (New-ValidationReference -Path "tmp-browser-smoke/common/Win32Input.ps1" -Kind "file" -Purpose "Shared headed Win32 window helpers used by the fixture probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/tabs/TabProbeCommon.ps1" -Kind "file" -Purpose "Shared probe process ownership helpers used by the fixture probe."),
    (New-ValidationReference -Path "scripts/windows/check_saved_page_localhost_validation_surface.ps1" -Kind "file" -Purpose "Broader saved-page localhost surface checker that now includes this reusable fixture path.")
)

$results = foreach ($reference in $references) {
    $fullPath = Join-Path $resolvedRepoRoot $reference.Path
    $exists = if ($reference.Kind -eq "directory") {
        Test-Path -LiteralPath $fullPath -PathType Container
    } else {
        Test-Path -LiteralPath $fullPath -PathType Leaf
    }

    [pscustomobject]@{
        Path = $reference.Path
        Kind = $reference.Kind
        Purpose = $reference.Purpose
        Exists = [bool]$exists
    }
}

$missing = @($results | Where-Object { -not $_.Exists })
$inputChecks = if ($explicitInputPathCount -gt 0) {
    Get-ExplicitInputChecks -Paths $InputPath
} else {
    @()
}
$inputProblems = @($inputChecks | Where-Object { $_.Status -ne "PASS" })

if ($Json) {
    [ordered]@{
        profile = "local-html-fixture"
        repo_root = $resolvedRepoRoot
        input_mode = $inputMode
        explicit_input_path_count = $explicitInputPathCount
        checked_count = @($results).Count
        missing_count = @($missing).Count
        input_problem_count = @($inputProblems).Count
        references = @($results)
        input_checks = @($inputChecks)
    } | ConvertTo-Json -Depth 6

    if ($missing.Count -gt 0 -or $inputProblems.Count -gt 0) {
        exit 1
    }

    exit 0
}

Write-Host "Local HTML fixture validation surface check"
Write-Host ""
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
Write-Host ("Input mode: {0}" -f $inputMode)
if ($explicitInputPathCount -gt 0) {
    Write-Host ("Explicit input paths: {0}" -f $explicitInputPathCount)
    Write-Host ""
    foreach ($inputCheck in $inputChecks) {
        Write-Host ("[{0}] {1}" -f $inputCheck.Status, $inputCheck.RequestedPath)
        if ($inputCheck.ResolvedPath) {
            Write-Host ("  Resolved path: {0}" -f $inputCheck.ResolvedPath)
        }
        Write-Host ("  Kind: {0}" -f $inputCheck.Kind)
        Write-Host ("  HTML files: {0}" -f $inputCheck.HtmlFileCount)
        Write-Host ("  {0}" -f $inputCheck.Detail)
    }
}
Write-Host ""

foreach ($result in $results) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host ("[{0}] {1}" -f $status, $result.Path)
    Write-Host ("  {0}" -f $result.Purpose)
}

Write-Host ""
if ($missing.Count -eq 0 -and $inputProblems.Count -eq 0) {
    Write-Host "Local HTML fixture validation surface is intact."
    exit 0
}

if ($missing.Count -gt 0) {
    Write-Host ("Missing {0} local HTML fixture validation path(s)." -f $missing.Count)
}
if ($inputProblems.Count -gt 0) {
    Write-Host ("Explicit fixture input validation found {0} problem path(s)." -f $inputProblems.Count)
}
Write-Host "Repair the missing guide, flow helper, probe dependency, deep asset audit dependency, or bad fixture input before trusting the reusable local fixture replay path."
exit 1
