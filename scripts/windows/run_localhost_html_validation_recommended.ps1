[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "PageRoot")]
    [string]$PageRoot,

    [Parameter(ParameterSetName = "InputPath")]
    [string[]]$InputPath,

    [string]$PreferredInitialPage,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8123,
    [switch]$SummaryOnly,
    [switch]$Wait,
    [switch]$LeaveServerRunning,
    [switch]$GoogleStyle,
    [switch]$AllowMissingLocalAssets
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Get-AttachedHtmlInputPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [switch]$GoogleStyle
    )

    return @(Get-DefaultAttachedHtmlInputPath -RepoRoot $RepoRoot -GoogleStyle:$GoogleStyle)
}

function Resolve-AttachedHtmlRunnerSelection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [string[]]$InputPath,
        [switch]$GoogleStyle
    )

    $bundleChecker = Join-Path $PSScriptRoot "check_attached_html_target_bundle.ps1"
    $bundleRunner = Join-Path $PSScriptRoot "run_attached_html_target_bundle_validation.ps1"
    $attachedRunner = Join-Path $PSScriptRoot "run_attached_html_localhost_validation.ps1"
    foreach ($path in @($bundleChecker, $bundleRunner, $attachedRunner)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "required attached HTML validation path not found: $path"
        }
    }

    $checkerArgs = @{
        RepoRoot = $RepoRoot
        Json = $true
    }
    if ($InputPath -and $InputPath.Count -gt 0) {
        $checkerArgs.InputPath = $InputPath
    }

    $bundleJson = (& $bundleChecker @checkerArgs) -join [Environment]::NewLine
    $bundleExitCode = $LASTEXITCODE
    if ($bundleExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($bundleJson)) {
        $bundle = $bundleJson | ConvertFrom-Json -Depth 12
        $overall = $bundle.overall_recommendation
        $resolvedTargets = @($bundle.targets | Where-Object { $_.status -eq "found" -and $_.path })
        $resolvedInputPath = @($resolvedTargets | ForEach-Object { $_.path })
        if ($overall -and $overall.bundle_validation_profile -and $resolvedInputPath.Count -gt 0) {
            return [pscustomobject]@{
                runner_path = $bundleRunner
                runner_label = ".\scripts\windows\run_attached_html_target_bundle_validation.ps1"
                resolved_input_path = $resolvedInputPath
                preferred_initial_page = if ($overall.preferred_initial_page) { $overall.preferred_initial_page } else { $null }
                summary = if ($overall.bundle_summary) { $overall.bundle_summary } else { $overall.summary }
                validation_mode = $overall.bundle_validation_profile
            }
        }
    }

    return [pscustomobject]@{
        runner_path = $attachedRunner
        runner_label = ".\scripts\windows\run_attached_html_localhost_validation.ps1"
        resolved_input_path = $InputPath
        preferred_initial_page = $null
        summary = $null
        validation_mode = if ($GoogleStyle) { "google-style" } else { "general" }
    }
}

if (-not $RepoRoot) {
    $RepoRoot = Resolve-LightpandaRepoRoot $PSScriptRoot
}

$savedRunner = Join-Path $PSScriptRoot "run_saved_page_localhost_validation.ps1"
$sanitizedRunner = Join-Path $PSScriptRoot "run_sanitized_saved_page_localhost_validation.ps1"
foreach ($runner in @($savedRunner, $sanitizedRunner)) {
    if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
        throw "required localhost HTML validation runner not found: $runner"
    }
}

$commonArgs = @{
    RepoRoot = $RepoRoot
    Host = $Host
    Port = $Port
}
if ($BrowserExe) {
    $commonArgs.BrowserExe = $BrowserExe
}
if ($PreferredInitialPage) {
    $commonArgs.PreferredInitialPage = $PreferredInitialPage
}
if ($SummaryOnly) {
    $commonArgs.SummaryOnly = $true
}
if ($Wait) {
    $commonArgs.Wait = $true
}
if ($LeaveServerRunning) {
    $commonArgs.LeaveServerRunning = $true
}

switch ($PSCmdlet.ParameterSetName) {
    "PageRoot" {
        Write-Host "Recommended localhost HTML validation"
        Write-Host ""
        Write-Host "Mode: direct saved-page root"
        Write-Host ("Page root: {0}" -f $PageRoot)
        Write-Host "Runner: .\scripts\windows\run_saved_page_localhost_validation.ps1"
        Write-Host ""

        & $savedRunner @commonArgs -PageRoot $PageRoot
        exit $LASTEXITCODE
    }
    "InputPath" {
        $attachedSelection = Resolve-AttachedHtmlRunnerSelection -RepoRoot $RepoRoot -InputPath $InputPath -GoogleStyle:$GoogleStyle
        if ($attachedSelection.runner_label -like "*target_bundle*") {
            Write-Host "Recommended localhost HTML validation"
            Write-Host ""
            Write-Host "Mode: pinned attached HTML target bundle"
            Write-Host ("Inputs: {0}" -f $attachedSelection.resolved_input_path.Count)
            Write-Host ("Validation mode: {0}" -f $attachedSelection.validation_mode)
            Write-Host ("Runner: {0}" -f $attachedSelection.runner_label)
            if ($attachedSelection.summary) {
                Write-Host ("Bundle route: {0}" -f $attachedSelection.summary)
            }
            if ($AllowMissingLocalAssets) {
                Write-Host "Attached asset policy: degraded mode allowed"
            }
            Write-Host ""

            $bundleArgs = $commonArgs.Clone()
            if ($attachedSelection.resolved_input_path -and $attachedSelection.resolved_input_path.Count -gt 0) {
                $bundleArgs.InputPath = $attachedSelection.resolved_input_path
            } elseif ($InputPath -and $InputPath.Count -gt 0) {
                $bundleArgs.InputPath = $InputPath
            }
            if ($AllowMissingLocalAssets) {
                $bundleArgs.AllowMissingLocalAssets = $true
            }

            & $attachedSelection.runner_path @bundleArgs
        } elseif ($GoogleStyle) {
            Write-Host "Recommended localhost HTML validation"
            Write-Host ""
            Write-Host "Mode: staged attached HTML inputs"
            Write-Host ("Inputs: {0}" -f $InputPath.Count)
            Write-Host "Validation mode: google-style"
            Write-Host ("Runner: {0}" -f $attachedSelection.runner_label)
            if ($AllowMissingLocalAssets) {
                Write-Host "Attached asset policy: degraded mode allowed"
            }
            Write-Host ""

            $attachedArgs = $commonArgs.Clone()
            $attachedArgs.InputPath = $InputPath
            if ($AllowMissingLocalAssets) {
                $attachedArgs.AllowMissingLocalAssets = $true
            }

            & $attachedSelection.runner_path @attachedArgs
        } else {
            Write-Host "Recommended localhost HTML validation"
            Write-Host ""
            Write-Host "Mode: sanitized saved-page inputs"
            Write-Host ("Inputs: {0}" -f $InputPath.Count)
            Write-Host "Runner: .\scripts\windows\run_sanitized_saved_page_localhost_validation.ps1"
            Write-Host ""

            & $sanitizedRunner @commonArgs -InputPath $InputPath
        }
        exit $LASTEXITCODE
    }
    default {
        $attachedHtml = Get-AttachedHtmlInputPath -RepoRoot $RepoRoot -GoogleStyle:$GoogleStyle
        if ($attachedHtml.Count -eq 0) {
            $searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot)
            throw "No PageRoot or InputPath was provided, and no attached HTML files were found under: $($searchRoots -join '; '). Pass -PageRoot for one saved-page directory or -InputPath for staged HTML inputs."
        }

        $attachedSelection = Resolve-AttachedHtmlRunnerSelection -RepoRoot $RepoRoot -InputPath $attachedHtml -GoogleStyle:$GoogleStyle
        if ($attachedSelection.runner_label -like "*target_bundle*") {
            Write-Host "Recommended localhost HTML validation"
            Write-Host ""
            Write-Host "Mode: auto-discovered attached HTML target bundle"
            Write-Host ("Attached HTML inputs: {0}" -f $attachedSelection.resolved_input_path.Count)
            Write-Host ("Validation mode: {0}" -f $attachedSelection.validation_mode)
            if ($AllowMissingLocalAssets) {
                Write-Host "Attached asset policy: degraded mode allowed"
            }
            Write-Host ("Runner: {0}" -f $attachedSelection.runner_label)
            if ($attachedSelection.summary) {
                Write-Host ("Bundle route: {0}" -f $attachedSelection.summary)
            }
            Write-Host ""

            $bundleArgs = $commonArgs.Clone()
            $bundleArgs.InputPath = $attachedSelection.resolved_input_path
            if ($AllowMissingLocalAssets) {
                $bundleArgs.AllowMissingLocalAssets = $true
            }

            & $attachedSelection.runner_path @bundleArgs
        } else {
            Write-Host "Recommended localhost HTML validation"
            Write-Host ""
            Write-Host "Mode: auto-discovered attached HTML"
            Write-Host ("Attached HTML inputs: {0}" -f $attachedHtml.Count)
            if ($GoogleStyle) {
                Write-Host "Validation mode: google-style"
            }
            if ($AllowMissingLocalAssets) {
                Write-Host "Attached asset policy: degraded mode allowed"
            }
            Write-Host ("Runner: {0}" -f $attachedSelection.runner_label)
            Write-Host ""

            $attachedArgs = $commonArgs.Clone()
            $attachedArgs.InputPath = $attachedHtml
            if ($AllowMissingLocalAssets) {
                $attachedArgs.AllowMissingLocalAssets = $true
            }

            & $attachedSelection.runner_path @attachedArgs
        }
        exit $LASTEXITCODE
    }
}
