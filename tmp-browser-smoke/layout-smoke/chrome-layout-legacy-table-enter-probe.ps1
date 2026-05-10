$ErrorActionPreference = "Stop"

$root = "C:\Users\adyba\src\lightpanda-browser\tmp-browser-smoke\layout-smoke"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$serverScript = Join-Path $root "layout_server.py"
$layoutCommon = Join-Path $root "LayoutProbeCommon.ps1"
$inputCommon = Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1"
. $layoutCommon
. $inputCommon

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 40, [int]$SleepMs = 200) {
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

$port = 8180
$pageUrl = "http://127.0.0.1:$port/legacy-table.html"
$outPng = Join-Path $root "legacy-table-enter.png"
$browserOut = Join-Path $root "legacy-table-enter.browser.stdout.txt"
$browserErr = Join-Path $root "legacy-table-enter.browser.stderr.txt"
$serverOut = Join-Path $root "legacy-table-enter.server.stdout.txt"
$serverErr = Join-Path $root "legacy-table-enter.server.stderr.txt"
$profileRoot = Join-Path $root "profile-legacy-table-enter"
$inputText = "Q"

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

try {
  $server = Start-Process -FilePath "python" -ArgumentList $serverScript,$port -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  if (-not (Wait-HttpReady $pageUrl)) { throw "layout smoke server did not become ready" }
  $ready = $true

  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse",$pageUrl,"--window_width","960","--window_height","540","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  if (-not (Wait-Screenshot $outPng)) { throw "legacy table enter screenshot did not become ready" }
  $pngReady = $true

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "legacy table enter window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250

  $boundTitle = Wait-ForTitleLike $hwnd "BOUND*"
  if ($null -eq $boundTitle) { throw "legacy table fixture did not bind the query input" }

  Invoke-SmokeClientClick $hwnd 470 235 | Out-Null
  $focusedTitle = Wait-ForTitleLike $hwnd "FOCUSED*"
  if ($null -eq $focusedTitle) { throw "legacy table input did not focus after click" }

  Send-SmokeText $inputText
  $typedTitle = Wait-ForTitleLike $hwnd (Get-LikePrefixPattern -Prefix "TYPED:" -Value $inputText)
  $typedWorked = $null -ne $typedTitle
  if (-not $typedWorked) { throw "legacy table input did not receive typed text" }

  Send-SmokeEnter
  $keydownTitle = Wait-ForTitleLike $hwnd (Get-LikePrefixPattern -Prefix "KEYDOWN:" -Value $inputText)
  $keydownWorked = $null -ne $keydownTitle
  if (-not $keydownWorked) { throw "legacy table input did not expose KEYDOWN before submit" }

  $submitTitle = Wait-ForTitleLike $hwnd (Get-LikePrefixPattern -Prefix "SUBMIT:" -Value $inputText)
  $submittedWorked = $null -ne $submitTitle
  if (-not $submittedWorked) { throw "legacy table input did not submit after Enter" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = if ($server) { Get-CimInstance Win32_Process -Filter "ProcessId=$($server.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  $browserMeta = if ($browser) { Get-CimInstance Win32_Process -Filter "ProcessId=$($browser.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  if ($browserMeta -and $browserMeta.CommandLine -and $browserMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-Process -Id $browser.Id -Force -ErrorAction SilentlyContinue }
  if ($serverMeta -and $serverMeta.CommandLine -and $serverMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
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
    error = $failure
    server_meta = $serverMeta
    browser_meta = $browserMeta
    browser_gone = $browserGone
    server_gone = $serverGone
  } | ConvertTo-Json -Depth 7
}

if ($failure) {
  exit 1
}
