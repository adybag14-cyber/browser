param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
    [Parameter(Mandatory = $true)]
    [string]$PageRoot,
    [Parameter(Mandatory = $true)]
    [string]$StartPage,
    [ValidateSet("headed", "headless")]
    [string]$BrowserMode = "headed",
    [int]$Port = 8123,
    [string]$BindHost = "127.0.0.1",
    [int]$WindowWidth = 1366,
    [int]$WindowHeight = 768,
    [string]$BrowserExe = "",
    [string]$ScreenshotPng = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-FullPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return (Resolve-Path -LiteralPath $Path).Path
}

function Wait-HttpReady {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [int]$Attempts = 40
    )

    for ($i = 0; $i -lt $Attempts; $i++) {
        Start-Sleep -Milliseconds 250
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
                return $true
            }
        } catch {
        }
    }

    return $false
}

$resolvedRepoRoot = Resolve-FullPath -Path $RepoRoot
$resolvedPageRoot = Resolve-FullPath -Path $PageRoot
$pagePath = Join-Path $resolvedPageRoot $StartPage
if (-not (Test-Path -LiteralPath $pagePath -PathType Leaf)) {
    throw "StartPage '$StartPage' was not found under '$resolvedPageRoot'."
}

if ([string]::IsNullOrWhiteSpace($BrowserExe)) {
    $BrowserExe = Join-Path $resolvedRepoRoot "zig-out\bin\lightpanda.exe"
}
$resolvedBrowserExe = Resolve-FullPath -Path $BrowserExe

$normalizedRoot = [System.IO.Path]::GetFullPath($resolvedPageRoot)
if (-not $normalizedRoot.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
    $normalizedRoot += [System.IO.Path]::DirectorySeparatorChar
}
$normalizedPage = [System.IO.Path]::GetFullPath($pagePath)
if (-not $normalizedPage.StartsWith($normalizedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "StartPage '$StartPage' resolved outside PageRoot '$resolvedPageRoot'."
}
$relativePage = $normalizedPage.Substring($normalizedRoot.Length).Replace('\', '/')
$startupUrl = "http://{0}:{1}/{2}" -f $BindHost, $Port, $relativePage

$serverStdout = Join-Path $env:TEMP ("lightpanda-localhost-server-{0}.stdout.txt" -f $Port)
$serverStderr = Join-Path $env:TEMP ("lightpanda-localhost-server-{0}.stderr.txt" -f $Port)
$browserStdout = Join-Path $env:TEMP ("lightpanda-localhost-browser-{0}.stdout.txt" -f $Port)
$browserStderr = Join-Path $env:TEMP ("lightpanda-localhost-browser-{0}.stderr.txt" -f $Port)

$server = $null
try {
    $server = Start-Process -FilePath "python" -ArgumentList "-m", "http.server", $Port, "--bind", $BindHost -WorkingDirectory $resolvedPageRoot -PassThru -RedirectStandardOutput $serverStdout -RedirectStandardError $serverStderr

    if (-not (Wait-HttpReady -Url $startupUrl)) {
        throw "Localhost server did not become ready for $startupUrl."
    }

    $browserArgs = @(
        "browse",
        $startupUrl,
        "--browser_mode",
        $BrowserMode,
        "--window_width",
        "$WindowWidth",
        "--window_height",
        "$WindowHeight"
    )
    if (-not [string]::IsNullOrWhiteSpace($ScreenshotPng)) {
        $browserArgs += @("--screenshot_png", $ScreenshotPng)
    }

    $browser = Start-Process -FilePath $resolvedBrowserExe -ArgumentList $browserArgs -WorkingDirectory $resolvedRepoRoot -PassThru -RedirectStandardOutput $browserStdout -RedirectStandardError $browserStderr

    Write-Host ("Serving: {0}" -f $resolvedPageRoot)
    Write-Host ("Page: {0}" -f $startupUrl)
    Write-Host ("Server PID: {0}" -f $server.Id)
    Write-Host ("Browser PID: {0}" -f $browser.Id)
    Write-Host ("Server logs: {0} | {1}" -f $serverStdout, $serverStderr)
    Write-Host ("Browser logs: {0} | {1}" -f $browserStdout, $browserStderr)

    Wait-Process -Id $browser.Id
} finally {
    if ($null -ne $server -and -not $server.HasExited) {
        Stop-Process -Id $server.Id -Force
    }
}
