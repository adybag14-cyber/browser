$repo = "C:\Users\adyba\src\lightpanda-browser"
. "$repo\tmp-browser-smoke\browser-pages\BrowserPagesProbeCommon.ps1"

$homePort = 8213
$retryPort = 8214
$homeServerOut = Join-Path $Root "chrome-browser-pages-error-retry.home.server.stdout.txt"
$homeServerErr = Join-Path $Root "chrome-browser-pages-error-retry.home.server.stderr.txt"
$retryServerOut = Join-Path $Root "chrome-browser-pages-error-retry.retry.server.stdout.txt"
$retryServerErr = Join-Path $Root "chrome-browser-pages-error-retry.retry.server.stderr.txt"
$browserOut = Join-Path $Root "chrome-browser-pages-error-retry.browser.stdout.txt"
$browserErr = Join-Path $Root "chrome-browser-pages-error-retry.browser.stderr.txt"
Remove-Item $homeServerOut,$homeServerErr,$retryServerOut,$retryServerErr,$browserOut,$browserErr -Force -ErrorAction SilentlyContinue

$profileRoot = Join-Path $Root "profile-error-retry"
$app = Reset-BrowserPagesProfile $profileRoot
Seed-BrowserPagesProfile `
  -AppDataRoot $app.AppDataRoot `
  -DownloadsDir $app.DownloadsDir `
  -Port $homePort `
  -RestorePreviousSession $true `
  -AllowScriptPopups $false `
  -DefaultZoomPercent 120 `
  -HomepageUrl "http://127.0.0.1:$homePort/index.html"

$homeServer = $null
$retryServer = $null
$browser = $null
$failure = $null
$homeReady = $false
$retryReady = $false
$titles = [ordered]@{}

try {
  $homeServer = Start-BrowserPagesServer -Port $homePort -Stdout $homeServerOut -Stderr $homeServerErr
  $homeReady = Wait-BrowserPagesServer -Port $homePort
  if (-not $homeReady) { throw "error retry home server did not become ready" }

  $browser = Start-BrowserPagesBrowser -StartupUrl "http://127.0.0.1:$homePort/page-two.html" -Stdout $browserOut -Stderr $browserErr
  $hwnd = Wait-TabWindowHandle $browser.Id
  if ($hwnd -eq [IntPtr]::Zero) { throw "error retry browser window handle not found" }
  Show-SmokeWindow $hwnd

  $titles.initial = Wait-TabTitle $browser.Id "Browser Pages Two" 40
  if (-not $titles.initial) { throw "initial page did not load" }

  $titles.error = Invoke-BrowserPagesAddressNavigate $hwnd $browser.Id "http://127.0.0.1:$retryPort/index.html" "Navigation Error"
  if (-not $titles.error) { throw "navigation error page did not open" }

  $retryServer = Start-BrowserPagesServer -Port $retryPort -Stdout $retryServerOut -Stderr $retryServerErr
  $retryReady = Wait-BrowserPagesServer -Port $retryPort
  if (-not $retryReady) { throw "error retry target server did not become ready" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 150
  $titles.retry = Invoke-BrowserPagesDocumentAction $hwnd 7 $browser.Id "Browser Pages One"
  if (-not $titles.retry) { throw "error page retry action did not recover to the target page" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $browserMeta = Stop-OwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $retryServerMeta = Stop-OwnedProbeProcess $retryServer
  Start-Sleep -Milliseconds 200
  $retryServerGone = if ($retryServer) { -not (Get-Process -Id $retryServer.Id -ErrorAction SilentlyContinue) } else { $true }
  $homeServerMeta = Stop-OwnedProbeProcess $homeServer
  Start-Sleep -Milliseconds 200
  $homeServerGone = if ($homeServer) { -not (Get-Process -Id $homeServer.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    home_ready = $homeReady
    retry_ready = $retryReady
    error_opened = [bool]$titles.error
    retry_action_worked = [bool]$titles.retry
    error = $failure
    titles = $titles
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    browser_meta = $browserMeta
    browser_gone = $browserGone
    retry_server_pid = if ($retryServer) { $retryServer.Id } else { 0 }
    retry_server_meta = $retryServerMeta
    retry_server_gone = $retryServerGone
    home_server_pid = if ($homeServer) { $homeServer.Id } else { 0 }
    home_server_meta = $homeServerMeta
    home_server_gone = $homeServerGone
  } | ConvertTo-Json -Depth 6
}

if ($failure) { exit 1 }
if (-not $titles.error -or -not $titles.retry) {
  exit 1
}
