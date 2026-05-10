[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PageRoot,

    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$InitialPage,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8123,
    [switch]$LaunchBrowser,
    [switch]$Wait,
    [switch]$LeaveServerRunning
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-UrlReady {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [int]$TimeoutSeconds = 10
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2 | Out-Null
            return $true
        } catch {
            Start-Sleep -Milliseconds 250
        }
    }

    return $false
}

function Get-RelativeHtmlPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $resolvedRoot = [System.IO.Path]::GetFullPath($Root)
    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    $relative = [System.IO.Path]::GetRelativePath($resolvedRoot, $resolvedPath)
    return ($relative -replace "\\", "/")
}

function Normalize-RelativeHtmlPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $normalized = ($Path -replace "\\", "/").Trim()
    while ($normalized.StartsWith("./")) {
        $normalized = $normalized.Substring(2)
    }
    return $normalized.TrimStart('/')
}

function Test-PathUnderRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $resolvedRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    return $resolvedPath.StartsWith($resolvedRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -or
        $resolvedPath.StartsWith($resolvedRoot + [System.IO.Path]::AltDirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
}

$scriptRoot = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $scriptRoot "..\..")).Path
}

$resolvedPageRoot = (Resolve-Path -LiteralPath $PageRoot).Path
if (-not (Test-Path -LiteralPath $resolvedPageRoot -PathType Container)) {
    throw "page root must be a directory: $PageRoot"
}

if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

if ($LaunchBrowser -and -not (Test-Path -LiteralPath $BrowserExe)) {
    throw "headed browser binary not found: $BrowserExe"
}

$artifactRoot = Join-Path $RepoRoot "tmp-browser-smoke\manual-user\localhost-html-validation"
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null

$serverOut = Join-Path $artifactRoot "localhost-html-server.stdout.txt"
$serverErr = Join-Path $artifactRoot "localhost-html-server.stderr.txt"
$sessionPath = Join-Path $artifactRoot "localhost-html-session.json"
foreach ($path in @($serverOut, $serverErr, $sessionPath)) {
    if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Force
    }
}

$htmlFiles = Get-ChildItem -LiteralPath $resolvedPageRoot -Recurse -File |
    Where-Object { $_.Extension -in @(".html", ".htm") } |
    Sort-Object FullName

if ($htmlFiles.Count -eq 0) {
    throw "no .html or .htm files were found under $resolvedPageRoot"
}

$relativePages = @($htmlFiles | ForEach-Object {
    Get-RelativeHtmlPath -Root $resolvedPageRoot -Path $_.FullName
})

if (-not $InitialPage) {
    $InitialPage = $relativePages[0]
} else {
    $resolvedInitialPath = $null
    if (Test-Path -LiteralPath $InitialPage -PathType Leaf) {
        $resolvedInitialPath = (Resolve-Path -LiteralPath $InitialPage).Path
    } elseif ([System.IO.Path]::IsPathRooted($InitialPage)) {
        throw "initial page '$InitialPage' was not found as a file path"
    }

    if ($resolvedInitialPath) {
        if (-not (Test-PathUnderRoot -Root $resolvedPageRoot -Path $resolvedInitialPath)) {
            throw "initial page '$resolvedInitialPath' must live under page root '$resolvedPageRoot'"
        }
        $InitialPage = Get-RelativeHtmlPath -Root $resolvedPageRoot -Path $resolvedInitialPath
    } else {
        $InitialPage = Normalize-RelativeHtmlPath -Path $InitialPage
    }
}

if ($relativePages -notcontains $InitialPage) {
    throw "initial page '$InitialPage' was not found under $resolvedPageRoot"
}

$initialUrl = "http://{0}:{1}/{2}" -f $Host, $Port, $InitialPage
$server = Start-Process -FilePath "python" `
    -ArgumentList "-m", "http.server", "$Port", "--bind", $Host `
    -WorkingDirectory $resolvedPageRoot `
    -PassThru `
    -RedirectStandardOutput $serverOut `
    -RedirectStandardError $serverErr

if (-not (Test-UrlReady -Url $initialUrl -TimeoutSeconds 10)) {
    try {
        Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
    } catch {
    }
    throw "localhost HTML server did not become ready at $initialUrl"
}

$browserPid = $null
if ($LaunchBrowser) {
    $browser = Start-Process -FilePath $BrowserExe `
        -ArgumentList "browse", "--browser_mode", "headed", "--window_width", "1366", "--window_height", "768", $initialUrl `
        -WorkingDirectory $RepoRoot `
        -PassThru
    $browserPid = $browser.Id
}

$pageUrls = @($relativePages | ForEach-Object {
    "http://{0}:{1}/{2}" -f $Host, $Port, $_
})

$result = [pscustomobject]@{
    page_root = $resolvedPageRoot
    repo_root = $RepoRoot
    host = $Host
    port = $Port
    initial_page = $InitialPage
    initial_url = $initialUrl
    page_count = $relativePages.Count
    pages = $relativePages
    urls = $pageUrls
    server_pid = $server.Id
    browser_pid = $browserPid
    server_stdout = $serverOut
    server_stderr = $serverErr
    started_at_utc = (Get-Date).ToUniversalTime().ToString("o")
}

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $sessionPath -Encoding Ascii

Write-Host ("Serving {0} HTML page(s) from {1}" -f $relativePages.Count, $resolvedPageRoot)
Write-Host ("Initial URL: {0}" -f $initialUrl)
Write-Host ("Server PID: {0}" -f $server.Id)
if ($browserPid) {
    Write-Host ("Browser PID: {0}" -f $browserPid)
}
Write-Host ("Session record: {0}" -f $sessionPath)
Write-Host ""
Write-Host "Available pages:"
foreach ($page in $relativePages) {
    Write-Host ("  {0}" -f $page)
}

if ($Wait) {
    Read-Host "Press Enter to stop the localhost HTML server" | Out-Null
}

if ($Wait -and -not $LeaveServerRunning -and -not $server.HasExited) {
    Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
}

$result | ConvertTo-Json -Depth 6
