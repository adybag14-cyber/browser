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
    [switch]$GoogleStyle
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

if (-not $RepoRoot) {
    $RepoRoot = Resolve-LightpandaRepoRoot $PSScriptRoot
}

$savedRunner = Join-Path $PSScriptRoot "run_saved_page_localhost_validation.ps1"
$sanitizedRunner = Join-Path $PSScriptRoot "run_sanitized_saved_page_localhost_validation.ps1"
$attachedRunner = Join-Path $PSScriptRoot "run_attached_html_localhost_validation.ps1"
foreach ($runner in @($savedRunner, $sanitizedRunner, $attachedRunner)) {
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

$attachedArgs = $commonArgs.Clone()
if ($GoogleStyle) {
    $attachedArgs.GoogleStyle = $true
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
        Write-Host "Recommended localhost HTML validation"
        Write-Host ""
        if ($GoogleStyle) {
            Write-Host "Mode: staged attached HTML inputs"
            Write-Host ("Inputs: {0}" -f $InputPath.Count)
            Write-Host "Validation mode: google-style"
            Write-Host "Runner: .\scripts\windows\run_attached_html_localhost_validation.ps1"
            Write-Host ""

            & $attachedRunner @attachedArgs -InputPath $InputPath
        } else {
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

        Write-Host "Recommended localhost HTML validation"
        Write-Host ""
        Write-Host "Mode: auto-discovered attached HTML"
        Write-Host ("Attached HTML inputs: {0}" -f $attachedHtml.Count)
        if ($GoogleStyle) {
            Write-Host "Validation mode: google-style"
        }
        Write-Host "Runner: .\scripts\windows\run_attached_html_localhost_validation.ps1"
        Write-Host ""

        & $attachedRunner @attachedArgs -InputPath $attachedHtml
        exit $LASTEXITCODE
    }
}
