$ErrorActionPreference = "Stop"

param(
  [Parameter(Mandatory = $true)]
  [string]$PagesRoot,
  [int]$Port = 8194,
  [string]$Repo = "C:\Users\adyba\src\lightpanda-browser"
)

$root = Join-Path $Repo "tmp-browser-smoke\local-pages"
$profileRoot = Join-Path $root "profile-local-pages"
$browserExe = Join-Path $Repo "zig-out\bin\lightpanda.exe"
$serverScript = Join-Path $root "saved_pages_server.py"
$browserOut = Join-Path $root "chrome-local-pages-title.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-local-pages-title.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-local-pages-title.server.stdout.txt"
$serverErr = Join-Path $root "chrome-local-pages-title.server.stderr.txt"

cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

$env:APPDATA = $profileRoot
$env:LOCALAPPDATA = $profileRoot

. "$PSScriptRoot\..\tabs\TabProbeCommon.ps1"

$server = $null
$browser = $null
$ready = $false
$failure = $null
$manifest = $null
$pageResults = @()

function Wait-SavedPagesServer([int]$Port, [int]$Attempts = 30) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$Port/healthz" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { return $true }
    } catch {}
  }
  return $false
}

function Invoke-SavedPagesAddressCommit([IntPtr]$Hwnd, [string]$Url) {
  [void](Invoke-SmokeClientClick $Hwnd 160 40)
  Start-Sleep -Milliseconds 150
  Send-SmokeCtrlA
  Start-Sleep -Milliseconds 120
  Send-SmokeText $Url
  Start-Sleep -Milliseconds 120
  Send-SmokeEnter
}

function Wait-SavedPageTitle([int]$BrowserId, [string]$Needle, [int]$Attempts = 40) {
  return Wait-TabTitle $BrowserId $Needle $Attempts
}

try {
  if (-not (Test-Path $PagesRoot)) { throw "pages root not found: $PagesRoot" }
  if (-not (Test-Path $serverScript)) { throw "saved pages server script not found: $serverScript" }

  $server = Start-Process -FilePath "python" -ArgumentList $serverScript,$PagesRoot,$Port -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-SavedPagesServer -Port $Port
  if (-not $ready) { throw "saved pages server did not become ready" }

  $manifestResp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$Port/manifest.json" -TimeoutSec 5
  $manifest = $manifestResp.Content | ConvertFrom-Json
  if (-not $manifest.pages -or $manifest.pages.Count -eq 0) { throw "saved pages manifest is empty" }

  $firstPage = $manifest.pages[0]
  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$Port$($firstPage.url_path)","--window_width","1366","--window_height","900" -WorkingDirectory $Repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-TabWindowHandle $browser.Id
  if ($hwnd -eq [IntPtr]::Zero) { throw "saved pages probe window handle not found" }
  Show-SmokeWindow $hwnd

  foreach ($page in $manifest.pages) {
    $pageUrl = "http://127.0.0.1:$Port$($page.url_path)"
    Invoke-SavedPagesAddressCommit $hwnd $pageUrl
    $observedTitle = Wait-SavedPageTitle $browser.Id $page.title 50
    $matched = [bool]$observedTitle
    $pageResults += [ordered]@{
      slug = $page.slug
      source_name = $page.source_name
      expected_title = $page.title
      url = $pageUrl
      observed_title = $observedTitle
      matched = $matched
    }
    if (-not $matched) {
      throw "saved page title did not match for $($page.source_name)"
    }
  }
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
    ready = $ready
    pages_root = $PagesRoot
    page_count = if ($manifest -and $manifest.pages) { $manifest.pages.Count } else { 0 }
    page_results = $pageResults
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
