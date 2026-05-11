[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8123,
    [switch]$SummaryOnly,
    [switch]$Wait,
    [switch]$LeaveServerRunning,
    [switch]$AllowMissingLocalAssets
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Get-ExpandedHtmlInputPath {
    param(
        [string[]]$InputPath
    )

    $expanded = [System.Collections.Generic.List[string]]::new()

    foreach ($rawPath in $InputPath) {
        foreach ($resolved in @(Resolve-Path -LiteralPath $rawPath -ErrorAction Stop)) {
            $resolvedPath = $resolved.Path

            if (Test-Path -LiteralPath $resolvedPath -PathType Container) {
                $htmlChildren = @(
                    Get-ChildItem -LiteralPath $resolvedPath -Recurse -File |
                        Where-Object { $_.Extension -in @(".html", ".htm") } |
                        ForEach-Object { $_.FullName }
                )

                foreach ($htmlChild in $htmlChildren) {
                    $expanded.Add($htmlChild)
                }

                continue
            }

            if (Test-Path -LiteralPath $resolvedPath -PathType Leaf) {
                $expanded.Add($resolvedPath)
            }
        }
    }

    return @(
        $expanded |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Sort-Object -Unique
    )
}

$runnerPath = Join-Path $PSScriptRoot "run_attached_html_target_bundle_validation.ps1"
if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) {
    throw "Attached HTML target bundle runner not found: $runnerPath"
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$expandedInputPath = if ($InputPath -and $InputPath.Count -gt 0) {
    @(Get-ExpandedHtmlInputPath -InputPath $InputPath)
} else {
    @()
}

if ($InputPath -and $InputPath.Count -gt 0 -and $expandedInputPath.Count -eq 0) {
    throw "No .html or .htm files were found under the explicit InputPath set."
}

$runnerArgs = @{
    RepoRoot = $resolvedRepoRoot
    Host = $Host
    Port = $Port
}
if ($expandedInputPath.Count -gt 0) {
    $runnerArgs.InputPath = $expandedInputPath
}
if ($PreferredInitialPage) {
    $runnerArgs.PreferredInitialPage = $PreferredInitialPage
}
if ($BrowserExe) {
    $runnerArgs.BrowserExe = $BrowserExe
}
if ($SummaryOnly) {
    $runnerArgs.SummaryOnly = $true
}
if ($Wait) {
    $runnerArgs.Wait = $true
}
if ($LeaveServerRunning) {
    $runnerArgs.LeaveServerRunning = $true
}
if ($AllowMissingLocalAssets) {
    $runnerArgs.AllowMissingLocalAssets = $true
}

if (-not $SummaryOnly -and $expandedInputPath.Count -gt 0) {
    Write-Host "Attached HTML target bundle validation from paths"
    Write-Host ""
    Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
    Write-Host ("Expanded HTML inputs: {0}" -f $expandedInputPath.Count)
    Write-Host ("Delegated runner: .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1")
    Write-Host ""
}

& $runnerPath @runnerArgs
exit $LASTEXITCODE
