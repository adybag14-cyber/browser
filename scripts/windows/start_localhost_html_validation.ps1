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

function Resolve-PythonCommand {
    if (Get-Command python -ErrorAction SilentlyContinue) {
        return @{ FileName = "python"; Arguments = @() }
    }
    if (Get-Command py -ErrorAction SilentlyContinue) {
        return @{ FileName = "py"; Arguments = @("-3") }
    }

    throw "Python was not found in PATH. Install Python or the Python Launcher, or start the localhost HTML server separately."
}

function Resolve-TcpBindAddress {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Host
    )

    if ([string]::IsNullOrWhiteSpace($Host)) {
        return [System.Net.IPAddress]::Loopback
    }

    if ($Host -eq "0.0.0.0") {
        return [System.Net.IPAddress]::Any
    }

    if ($Host -eq "::") {
        return [System.Net.IPAddress]::IPv6Any
    }

    $parsedAddress = $null
    if ([System.Net.IPAddress]::TryParse($Host, [ref]$parsedAddress)) {
        return $parsedAddress
    }

    $resolvedAddresses = @(
        [System.Net.Dns]::GetHostAddresses($Host) |
            Where-Object {
                $_.AddressFamily -in @(
                    [System.Net.Sockets.AddressFamily]::InterNetwork,
                    [System.Net.Sockets.AddressFamily]::InterNetworkV6
                )
            }
    )
    if ($resolvedAddresses.Count -eq 0) {
        throw "could not resolve a TCP bind address for host '$Host'"
    }

    return $resolvedAddresses[0]
}

function Get-AvailableTcpPort {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Host
    )

    $listener = [System.Net.Sockets.TcpListener]::new((Resolve-TcpBindAddress -Host $Host), 0)
    try {
        $listener.Start()
        return ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port
    } finally {
        $listener.Stop()
    }
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

function Get-RelativeHtmlPathCandidates {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $normalized = Normalize-RelativeHtmlPath -Path $Path
    $decodedSegments = foreach ($segment in ($normalized -split "/")) {
        if ($segment -ne "") {
            [System.Uri]::UnescapeDataString($segment)
        }
    }
    $decoded = $decodedSegments -join "/"

    if ($decoded -eq $normalized) {
        return @($normalized)
    }

    return @($normalized, $decoded)
}

function Get-RelativeHtmlUrlPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $normalized = Normalize-RelativeHtmlPath -Path $Path
    $encodedSegments = foreach ($segment in ($normalized -split "/")) {
        if ($segment -ne "") {
            [System.Uri]::EscapeDataString($segment)
        }
    }
    return ($encodedSegments -join "/")
}

function Test-PathUnderRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $resolvedRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\\', '/')
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

if ($Port -lt 0 -or $Port -gt 65535) {
    throw "port must be between 0 and 65535"
}

$selectedPort = if ($Port -eq 0) {
    Get-AvailableTcpPort -Host $Host
} else {
    $Port
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
        $initialPageCandidates = Get-RelativeHtmlPathCandidates -Path $InitialPage
        $matchedInitialPage = $relativePages | Where-Object { $initialPageCandidates -contains $_ } | Select-Object -First 1
        if ($matchedInitialPage) {
            $InitialPage = $matchedInitialPage
        } else {
            $InitialPage = $initialPageCandidates[0]
        }
    }
}

if ($relativePages -notcontains $InitialPage) {
    throw "initial page '$InitialPage' was not found under $resolvedPageRoot"
}

$initialUrlPath = Get-RelativeHtmlUrlPath -Path $InitialPage
$initialUrl = "http://{0}:{1}/{2}" -f $Host, $selectedPort, $initialUrlPath
$python = Resolve-PythonCommand
$server = Start-Process -FilePath $python.FileName `
    -ArgumentList ($python.Arguments + @("-m", "http.server", "$selectedPort", "--bind", $Host)) `
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

$pageRecords = @($relativePages | ForEach-Object {
    $relativePath = $_
    $urlPath = Get-RelativeHtmlUrlPath -Path $relativePath
    [pscustomobject]@{
        relative_path = $relativePath
        url_path = $urlPath
        url = "http://{0}:{1}/{2}" -f $Host, $selectedPort, $urlPath
    }
})
$pageUrls = @($pageRecords | ForEach-Object { $_.url })

$result = [pscustomobject]@{
    page_root = $resolvedPageRoot
    repo_root = $RepoRoot
    host = $Host
    requested_port = $Port
    port = $selectedPort
    initial_page = $InitialPage
    initial_url_path = $initialUrlPath
    initial_url = $initialUrl
    page_count = $relativePages.Count
    pages = $relativePages
    page_records = $pageRecords
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
if ($Port -eq 0) {
    Write-Host ("Selected port: {0} (auto)" -f $selectedPort)
} else {
    Write-Host ("Port: {0}" -f $selectedPort)
}
Write-Host ("Server PID: {0}" -f $server.Id)
if ($browserPid) {
    Write-Host ("Browser PID: {0}" -f $browserPid)
}
Write-Host ("Session record: {0}" -f $sessionPath)
Write-Host ""
Write-Host "Available pages:"
foreach ($page in $pageRecords) {
    Write-Host ("  {0} -> {1}" -f $page.relative_path, $page.url)
}

if ($Wait) {
    Read-Host "Press Enter to stop the localhost HTML server" | Out-Null
}

if ($Wait -and -not $LeaveServerRunning -and -not $server.HasExited) {
    Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
}

$result | ConvertTo-Json -Depth 6
