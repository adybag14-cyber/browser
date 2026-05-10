[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 9582,
    [string]$ProbePagePath = "/src/browser/tests/page/google_home_title_probe.html",
    [string]$InputText = "QZ",
    [int]$TimeoutSeconds = 90,
    [int]$PollMilliseconds = 250,
    [switch]$SendEnter = $true,
    [switch]$LeaveOpen,
    [int]$ServerReadyTimeoutSeconds = 15
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $scriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}
if (-not (Test-Path -LiteralPath $BrowserExe)) {
    throw "headed browser binary not found: $BrowserExe"
}

$watchScript = Join-Path $scriptRoot "watch_headed_probe.ps1"
if (-not (Test-Path -LiteralPath $watchScript -PathType Leaf)) {
    throw "watch helper not found: $watchScript"
}

$artifactRoot = Join-Path $RepoRoot "tmp-browser-smoke\headed-probe"
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null

$serverStdout = Join-Path $artifactRoot "google-home-watch.server.stdout.txt"
$serverStderr = Join-Path $artifactRoot "google-home-watch.server.stderr.txt"
$summaryPath = Join-Path $artifactRoot "google-home-watch.summary.json"
Remove-Item $serverStdout, $serverStderr, $summaryPath -Force -ErrorAction SilentlyContinue

function Resolve-PythonCommand {
    if (Get-Command python -ErrorAction SilentlyContinue) {
        return @{ FileName = "python"; Arguments = @("-m", "http.server") }
    }
    if (Get-Command py -ErrorAction SilentlyContinue) {
        return @{ FileName = "py"; Arguments = @("-3", "-m", "http.server") }
    }
    throw "Python was not found in PATH. Install Python or start the localhost server separately."
}

function Wait-HttpReady {
    param(
        [string]$Url,
        [int]$TimeoutSeconds
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
                return
            }
        } catch {
        }
        Start-Sleep -Milliseconds 250
    } while ((Get-Date) -lt $deadline)

    throw "Timed out waiting for probe server at $Url"
}

$probeUrl = "http://$Host`:$Port$ProbePagePath"
$python = Resolve-PythonCommand
$server = $null

try {
    $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($Port, "--bind", $Host)) -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $serverStdout -RedirectStandardError $serverStderr
    Wait-HttpReady -Url $probeUrl -TimeoutSeconds $ServerReadyTimeoutSeconds

    $watchArgs = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        Url = $probeUrl
        ExpectedTitleContains = "BOUND|"
        TimeoutSeconds = $TimeoutSeconds
        PollMilliseconds = $PollMilliseconds
        InputText = $InputText
    }
    if ($SendEnter) {
        $watchArgs.SendEnter = $true
        $watchArgs.ExpectedEnterTitleContains = "SUBMIT:$InputText"
    }
    if (-not [string]::IsNullOrWhiteSpace($InputText)) {
        $watchArgs.ExpectedTypedTitleContains = "TYPED:$InputText"
    }
    if ($LeaveOpen) {
        $watchArgs.LeaveOpen = $true
    }

    $watchResult = & $watchScript @watchArgs | ConvertFrom-Json

    $summary = [ordered]@{
        generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        repo_root = $RepoRoot
        browser_exe = $BrowserExe
        probe_url = $probeUrl
        server_stdout = $serverStdout
        server_stderr = $serverStderr
        watch_result = $watchResult
    }

    $summary | ConvertTo-Json -Depth 8 | Tee-Object -FilePath $summaryPath
} finally {
    if ($server) {
        Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
        Wait-Process -Id $server.Id -ErrorAction SilentlyContinue
    }
}
