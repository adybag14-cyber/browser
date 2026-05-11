[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8180,
    [string]$InputText = "Q",
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$WindowReadyAttempts = 60,
    [int]$TitleWaitAttempts = 40,
    [int]$PollMilliseconds = 200
)

$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $root "..\..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

$repo = $RepoRoot
$serverScript = Join-Path $root "layout_server.py"
$layoutCommon = Join-Path $root "LayoutProbeCommon.ps1"
$inputCommon = Join-Path $root "..\common\Win32Input.ps1"
. $layoutCommon
. $inputCommon

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = $TitleWaitAttempts, [int]$SleepMs = $PollMilliseconds) {
    for ($i = 0; $i -lt $Attempts; $i++) {
        Start-Sleep -Milliseconds $SleepMs
        $title = Get-SmokeWindowTitle $Hwnd
        if ($title -like $Pattern) {
            return $title
        }
    }
    return $null
}

function Get-LikePrefixPattern([string]$Prefix, [string]$Value) {
    return "{0}{1}*" -f $Prefix, ([System.Management.Automation.WildcardPattern]::Escape($Value))
}

$pageUrl = "http://$Host`:$Port/legacy-table-enter.html"
$outPng = Join-Path $root "legacy-table-enter.png"
$browserOut = Join-Path $root "legacy-table-enter.browser.stdout.txt"
$browserErr = Join-Path $root "legacy-table-enter.browser.stderr.txt"
$serverOut = Join-Path $root "legacy-table-enter.server.stdout.txt"
$serverErr = Join-Path $root "legacy-table-enter.server.stderr.txt"
$profileRoot = Join-Path $root "profile-legacy-table-enter"

Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Reset-ProfileRoot $profileRoot

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$boundTitle = $null
$focusedTitle = $null
$typedTitle = $null
$keydownTitle = $null
$submitTitle = $null
$typedWorked = $false
$keydownWorked = $false
$submittedWorked = $false
$failure = $null
$clickPoint = $null

try {
    $server = Start-Process -FilePath "python" -ArgumentList $serverScript,$Port -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
    if (-not (Wait-HttpReady $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds)) { throw "layout smoke server did not become ready" }
    $ready = $true

    $env:APPDATA = $profileRoot
    $env:LOCALAPPDATA = $profileRoot
    $browser = Start-Process -FilePath $BrowserExe -ArgumentList "browse",$pageUrl,"--window_width","960","--window_height","540","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

    if (-not (Wait-Screenshot $outPng -Attempts $WindowReadyAttempts -SleepMs $PollMilliseconds)) { throw "legacy table enter screenshot did not become ready" }
    $pngReady = $true

    $hwnd = [IntPtr]::Zero
    for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
        Start-Sleep -Milliseconds $PollMilliseconds
        $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
        if ($proc -and $proc.MainWindowHandle -ne 0) {
            $hwnd = [IntPtr]$proc.MainWindowHandle
            break
        }
    }
    if ($hwnd -eq [IntPtr]::Zero) { throw "legacy table enter window handle not found" }

    Show-SmokeWindow $hwnd
    Start-Sleep -Milliseconds $PollMilliseconds

    $boundTitle = Wait-ForTitleLike $hwnd "BOUND*"
    if ($null -eq $boundTitle) { throw "legacy table fixture did not bind the query input" }

    $clickPoint = Invoke-SmokeClientClick $hwnd 470 235
    $focusedTitle = Wait-ForTitleLike $hwnd "FOCUSED*"
    if ($null -eq $focusedTitle) { throw "legacy table input did not focus after click" }

    Send-SmokeText $InputText
    $typedTitle = Wait-ForTitleLike $hwnd (Get-LikePrefixPattern -Prefix "TYPED:" -Value $InputText)
    $typedWorked = $null -ne $typedTitle
    if (-not $typedWorked) { throw "legacy table input did not receive typed text" }

    Send-SmokeEnter
    $keydownTitle = Wait-ForTitleLike $hwnd (Get-LikePrefixPattern -Prefix "KEYDOWN:" -Value $InputText) -Attempts 80 -SleepMs 25
    $keydownWorked = $null -ne $keydownTitle
    if (-not $keydownWorked) { throw "legacy table input did not expose KEYDOWN before submit" }

    $submitTitle = Wait-ForTitleLike $hwnd (Get-LikePrefixPattern -Prefix "SUBMIT:" -Value $InputText) -Attempts 80 -SleepMs 25
    $submittedWorked = $null -ne $submitTitle
    if (-not $submittedWorked) { throw "legacy table input did not submit after Enter" }

    [ordered]@{
        page_url = $pageUrl
        input_text = $InputText
        click_screen = if ($null -ne $clickPoint) { [ordered]@{ x = $clickPoint.X; y = $clickPoint.Y } } else { $null }
        ready = $ready
        screenshot_ready = $pngReady
        bound_title = $boundTitle
        focused_title = $focusedTitle
        typed_title = $typedTitle
        keydown_title = $keydownTitle
        submit_title = $submitTitle
        typed_worked = $typedWorked
        keydown_worked = $keydownWorked
        submitted_worked = $submittedWorked
    } | ConvertTo-Json -Depth 6
}
catch {
    $failure = $_.Exception.Message
}
finally {
    if ($browser) {
        Stop-VerifiedProcess $browser.Id
        for ($i = 0; $i -lt 20; $i++) {
            if (-not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue)) { break }
            Start-Sleep -Milliseconds 100
        }
    }
    if ($server) {
        Stop-VerifiedProcess $server.Id
        for ($i = 0; $i -lt 20; $i++) {
            if (-not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue)) { break }
            Start-Sleep -Milliseconds 100
        }
    }
}

if ($failure) {
    throw $failure
}
