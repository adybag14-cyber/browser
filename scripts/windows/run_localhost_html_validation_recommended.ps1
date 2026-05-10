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

function Get-AttachedHtmlInputPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $searchRoots = @(
        (Join-Path $RepoRoot "user_files"),
        (Join-Path $RepoRoot "agent_files")
    )
    $existingRoots = @(
        $searchRoots | Where-Object {
            Test-Path -LiteralPath $_ -PathType Container
        }
    )

    if ($existingRoots.Count -eq 0) {
        return @()
    }

    return @(
        foreach ($root in $existingRoots) {
            Get-ChildItem -LiteralPath $root -Recurse -File |
                Where-Object { $_.Extension -in @(".html", ".htm") } |
                Sort-Object FullName |
                ForEach-Object { $_.FullName }
        }
    ) | Select-Object -Unique
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
            Write-Host "Mode: staged saved-page inputs"
            Write-Host ("Inputs: {0}" -f $InputPath.Count)
            Write-Host "Runner: .\scripts\windows\run_saved_page_localhost_validation.ps1"
            Write-Host ""

            & $savedRunner @commonArgs -InputPath $InputPath
        }
        exit $LASTEXITCODE
    }
    default {
        $attachedHtml = Get-AttachedHtmlInputPath -RepoRoot $RepoRoot
        if ($attachedHtml.Count -eq 0) {
            $userFilesRoot = Join-Path $RepoRoot "user_files"
            $agentFilesRoot = Join-Path $RepoRoot "agent_files"
            throw "No PageRoot or InputPath was provided, and no attached HTML files were found anywhere under $userFilesRoot or $agentFilesRoot. Pass -PageRoot for one saved-page directory or -InputPath for staged HTML inputs."
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
