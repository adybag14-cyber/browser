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
    [switch]$LeaveServerRunning
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-AttachedHtmlInputPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $agentFilesRoot = Join-Path $RepoRoot "agent_files"
    if (-not (Test-Path -LiteralPath $agentFilesRoot -PathType Container)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $agentFilesRoot -File |
            Where-Object { $_.Extension -in @(".html", ".htm") } |
            Sort-Object FullName |
            ForEach-Object { $_.FullName }
    )
}

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$savedRunner = Join-Path $PSScriptRoot "run_saved_page_localhost_validation.ps1"
$attachedRunner = Join-Path $PSScriptRoot "run_attached_html_localhost_validation.ps1"
foreach ($runner in @($savedRunner, $attachedRunner)) {
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
        Write-Host "Recommended localhost HTML validation"
        Write-Host ""
        Write-Host "Mode: staged saved-page inputs"
        Write-Host ("Inputs: {0}" -f $InputPath.Count)
        Write-Host "Runner: .\scripts\windows\run_saved_page_localhost_validation.ps1"
        Write-Host ""

        & $savedRunner @commonArgs -InputPath $InputPath
        exit $LASTEXITCODE
    }
    default {
        $attachedHtml = Get-AttachedHtmlInputPath -RepoRoot $RepoRoot
        if ($attachedHtml.Count -eq 0) {
            $agentFilesRoot = Join-Path $RepoRoot "agent_files"
            throw "No PageRoot or InputPath was provided, and no attached HTML files were found under $agentFilesRoot. Pass -PageRoot for one saved-page directory or -InputPath for staged HTML inputs."
        }

        Write-Host "Recommended localhost HTML validation"
        Write-Host ""
        Write-Host "Mode: auto-discovered attached HTML"
        Write-Host ("Attached HTML inputs: {0}" -f $attachedHtml.Count)
        Write-Host "Runner: .\scripts\windows\run_attached_html_localhost_validation.ps1"
        Write-Host ""

        & $attachedRunner @commonArgs -InputPath $attachedHtml
        exit $LASTEXITCODE
    }
}
