$repo = "C:\Users\adyba\src\lightpanda-browser"
. "$repo\tmp-browser-smoke\browser-pages\BrowserPagesProbeCommon.ps1"

$profileRoot = Join-Path $Root "profile-loopback-fqdn-startup"
$app = Reset-BrowserPagesProfile $profileRoot
$port = 8192
$browserOut = Join-Path $Root "chrome-browser-pages-loopback-fqdn-startup.browser.stdout.txt"
$browserErr = Join-Path $Root "chrome-browser-pages-loopback-fqdn-startup.browser.stderr.txt"
$serverOut = Join-Path $Root "chrome-browser-pages-loopback-fqdn-startup.server.stdout.txt"
$serverErr = Join-Path $Root "chrome-browser-pages-loopback-fqdn-startup.server.stderr.txt"
$startupUrl = "localhost.:$port/index.html"
$followupUrl = "localhost.:$port/page-two.html?from=loopback-fqdn"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Seed-BrowserPagesProfile -AppDataRoot $app.AppDataRoot -DownloadsDir $app.DownloadsDir -Port $port

$server = $null
$browser = $null
$ready = $false
$startupWorked = $false
$followupWorked = $false
$titles = [ordered]@{}
$failure = $null

try {
  $server = Start-BrowserPagesServer -Port $port -Stdout $serverOut -Stderr $serverErr
  $ready = Wait-BrowserPagesServer -Port $port
  if (-not $ready) { throw "loopback fqdn server did not become ready" }

  $browser = Start-BrowserPagesBrowser -StartupUrl $startupUrl -Stdout $browserOut -Stderr $browserErr
  $hwnd = Wait-TabWindowHandle $browser.Id
  if ($hwnd -eq [IntPtr]::Zero) { throw "loopback fqdn startup window handle not found" }
  Show-SmokeWindow $hwnd

  $titles.startup = Wait-TabTitle $browser.Id "Browser Pages One" 40
  $startupWorked = [bool]$titles.startup
  if (-not $startupWorked) { throw "scheme-less fully qualified localhost startup did not load page one" }

  $titles.followup = Invoke-BrowserPagesAddressNavigate $hwnd $browser.Id $followupUrl "Browser Pages Two"
  $followupWorked = [bool]$titles.followup
  if (-not $followupWorked) { throw "scheme-less fully qualified localhost follow-up navigation did not load page two" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    startup_url = $startupUrl
    followup_url = $followupUrl
    ready = $ready
    startup_worked = $startupWorked
    followup_worked = $followupWorked
    titles = $titles
    error = $failure
    server_meta = $serverMeta
    browser_meta = $browserMeta
    browser_gone = $browserGone
    server_gone = $serverGone
  } | ConvertTo-Json -Depth 7
}

if ($failure) { exit 1 }
