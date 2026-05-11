[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$InputText = "lightpanda",
    [int]$WindowReadyAttempts = 80,
    [int]$PollMilliseconds = 250,
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $scriptRoot "..\..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}
if (-not (Test-Path -LiteralPath $BrowserExe)) {
    throw "headed browser binary not found: $BrowserExe"
}

$root = $scriptRoot
$profileRoot = Join-Path $root "profile-google-live-input"
$browserOut = Join-Path $root "chrome-google-home-input.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-google-home-input.browser.stderr.txt"
$browseRenderLog = Join-Path $root "browse-render.log"
$rendererLog = Join-Path $root "runtime-renderer.log"
$sessionWaitLog = Join-Path $root "session-wait.log"

cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
Remove-Item $browserOut,$browserErr,$browseRenderLog,$rendererLog,$sessionWaitLog -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $root -Filter "runtime-input-backend-*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $root -Filter "wndproc-input-*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

$env:APPDATA = $profileRoot
$env:LOCALAPPDATA = $profileRoot

. "$PSScriptRoot\..\tabs\TabProbeCommon.ps1"

function Read-TailLines {
    param(
        [string]$Path,
        [int]$Count = 30
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }
    return @(Get-Content -LiteralPath $Path -Tail $Count)
}

$browser = $null
$ready = $false
$titleBefore = $null
$titleAfterType = $null
$titleAfterEnter = $null
$failure = $null

try {
    $browser = Start-Process -FilePath $BrowserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "1366", "--window_height", "768", "https://www.google.com/") -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
    $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts
    if ($hwnd -eq [IntPtr]::Zero) { throw "google input trace probe window handle not found" }
    $ready = $true

    Show-SmokeWindow $hwnd
    Start-Sleep -Milliseconds ([Math]::Max($PollMilliseconds, 250) * 10)
    $titleBefore = Get-SmokeWindowTitle $hwnd

    Send-SmokeAsciiText $InputText
    Start-Sleep -Milliseconds ([Math]::Max($PollMilliseconds, 250) * 5)
    $titleAfterType = Get-SmokeWindowTitle $hwnd

    Send-SmokeEnter
    Start-Sleep -Milliseconds ([Math]::Max($PollMilliseconds, 250) * 8)
    $titleAfterEnter = Get-SmokeWindowTitle $hwnd
} catch {
    $failure = $_.Exception.Message
} finally {
    $runtimeInputLogs = @(Get-ChildItem -Path $root -Filter "runtime-input-backend-*.log" -ErrorAction SilentlyContinue | Sort-Object Name)
    $wndprocLogs = @(Get-ChildItem -Path $root -Filter "wndproc-input-*.log" -ErrorAction SilentlyContinue | Sort-Object Name)
    $runtimeInputTail = @()
    foreach ($log in $runtimeInputLogs) {
        $runtimeInputTail += Read-TailLines -Path $log.FullName -Count 20
    }
    $wndprocTail = @()
    foreach ($log in $wndprocLogs) {
        $wndprocTail += Read-TailLines -Path $log.FullName -Count 20
    }

    $traceText = @(
        Read-TailLines -Path $browseRenderLog -Count 40
        Read-TailLines -Path $rendererLog -Count 40
        Read-TailLines -Path $sessionWaitLog -Count 40
        $runtimeInputTail
        $wndprocTail
    ) -join "`n"

    $resultsNavigationLikely =
        ($titleAfterEnter -like "*Google Search*") -or
        ($titleAfterEnter -like "*$InputText*") -or
        ($traceText -match "google\.com/search") -or
        ($traceText -match "search\?q=")

    $browserMeta = $null
    if ($browser) {
        if ($LeaveOpen) {
            $browserMeta = Get-CimInstance Win32_Process -Filter "ProcessId=$($browser.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate
        } else {
            $browserMeta = Stop-OwnedProbeProcess $browser
        }
    }
    Start-Sleep -Milliseconds 200
    $browserGone = if ($browser -and -not $LeaveOpen) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $false }

    [ordered]@{
        repo_root = $RepoRoot
        browser_exe = $BrowserExe
        input_text = $InputText
        browser_pid = if ($browser) { $browser.Id } else { 0 }
        ready = $ready
        leave_open = [bool]$LeaveOpen
        title_before = $titleBefore
        title_after_type = $titleAfterType
        title_after_enter = $titleAfterEnter
        results_navigation_likely = $resultsNavigationLikely
        error = $failure
        trace_files = [ordered]@{
            browse_render = $browseRenderLog
            runtime_renderer = $rendererLog
            session_wait = $sessionWaitLog
            runtime_input = @($runtimeInputLogs | ForEach-Object { $_.FullName })
            wndproc_input = @($wndprocLogs | ForEach-Object { $_.FullName })
        }
        trace_tails = [ordered]@{
            browse_render = @(Read-TailLines -Path $browseRenderLog -Count 20)
            runtime_renderer = @(Read-TailLines -Path $rendererLog -Count 20)
            session_wait = @(Read-TailLines -Path $sessionWaitLog -Count 20)
            runtime_input = $runtimeInputTail
            wndproc_input = $wndprocTail
        }
        browser_stdout_tail = @(Read-TailLines -Path $browserOut -Count 30)
        browser_stderr_tail = @(Read-TailLines -Path $browserErr -Count 30)
        browser_meta = $browserMeta
        browser_gone = $browserGone
    } | ConvertTo-Json -Depth 8
}

if ($failure) {
    exit 1
}
