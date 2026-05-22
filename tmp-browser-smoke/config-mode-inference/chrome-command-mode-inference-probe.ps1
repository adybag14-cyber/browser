$ErrorActionPreference = "Stop"
$root = "C:\Users\adyba\src\lightpanda-browser\tmp-browser-smoke\config-mode-inference"
$browserExe = "C:\Users\adyba\src\lightpanda-browser\zig-out\bin\lightpanda.exe"
$port = 8168
$serverOut = Join-Path $root "chrome-command-mode-inference.server.stdout.txt"
$serverErr = Join-Path $root "chrome-command-mode-inference.server.stderr.txt"
$localOut = Join-Path $root "chrome-command-mode-inference.local.stdout.txt"
$localErr = Join-Path $root "chrome-command-mode-inference.local.stderr.txt"
$sharedOut = Join-Path $root "chrome-command-mode-inference.shared.stdout.txt"
$sharedErr = Join-Path $root "chrome-command-mode-inference.shared.stderr.txt"
$remoteHtmlOut = Join-Path $root "chrome-command-mode-inference.remote-html.stdout.txt"
$remoteHtmlErr = Join-Path $root "chrome-command-mode-inference.remote-html.stderr.txt"
$remoteHtmOut = Join-Path $root "chrome-command-mode-inference.remote-htm.stdout.txt"
$remoteHtmErr = Join-Path $root "chrome-command-mode-inference.remote-htm.stderr.txt"
$localTarget = Join-Path $root "attached-page.xhtml"
$remoteHtmlPath = Join-Path $root "remote-export.html"
$remoteHtmPath = Join-Path $root "remote-export.htm"
Remove-Item $serverOut,$serverErr,$localOut,$localErr,$sharedOut,$sharedErr,$remoteHtmlOut,$remoteHtmlErr,$remoteHtmOut,$remoteHtmErr,$localTarget,$remoteHtmlPath,$remoteHtmPath -Force -ErrorAction SilentlyContinue

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

$server = $null
$local = $null
$shared = $null
$remoteHtml = $null
$remoteHtm = $null
$ready = $false
$localBrowseWorked = $false
$sharedBrowseWorked = $false
$remoteHtmlStayedNonWindowed = $false
$remoteHtmStayedNonWindowed = $false
$titles = [ordered]@{}
$failure = $null

function Wait-ForWindowHandle([int]$ProcessId, [int]$Attempts = 60, [int]$SleepMs = 250) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $proc = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      return [IntPtr]$proc.MainWindowHandle
    }
  }
  return [IntPtr]::Zero
}

function Wait-ForExit([System.Diagnostics.Process]$Process, [int]$Attempts = 40, [int]$SleepMs = 250) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    if ($Process.HasExited) {
      return $true
    }
    $Process.Refresh()
  }
  return $Process.HasExited
}

function Stop-OwnedProbeProcess($Process) {
  if (-not $Process) {
    return $null
  }
  $meta = Get-CimInstance Win32_Process -Filter "ProcessId=$($Process.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate
  if ($meta -and $meta.CommandLine -and $meta.CommandLine -notmatch "codex\.js|@openai/codex") {
    Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
  }
  return $meta
}

try {
  @'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Mode Probe XHTML</title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  </head>
  <body>
    <h1>Mode Probe XHTML</h1>
    <p>This page should open in headed browse mode when command inference sees a local .xhtml target.</p>
  </body>
</html>
'@ | Set-Content -Path $localTarget -Encoding UTF8

  @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Remote Export HTML</title>
  </head>
  <body>
    <h1>Remote Export HTML</h1>
    <p>This scheme-based .html URL should keep the non-windowed command inference fallback.</p>
  </body>
</html>
'@ | Set-Content -Path $remoteHtmlPath -Encoding UTF8

  @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Remote Export HTM</title>
  </head>
  <body>
    <h1>Remote Export HTM</h1>
    <p>This scheme-based .htm URL should keep the non-windowed command inference fallback.</p>
  </body>
</html>
'@ | Set-Content -Path $remoteHtmPath -Encoding UTF8

  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/remote-export.html" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "config mode inference server did not become ready" }

  $local = Start-Process -FilePath $browserExe -ArgumentList "--window_width","420","--window_height","320",$localTarget -PassThru -RedirectStandardOutput $localOut -RedirectStandardError $localErr
  $localHwnd = Wait-ForWindowHandle $local.Id
  if ($localHwnd -eq [IntPtr]::Zero) { throw "local xhtml target did not infer headed browse mode" }
  Show-SmokeWindow $localHwnd
  $titles.local = Get-SmokeWindowTitle $localHwnd
  $localBrowseWorked = ($titles.local -like "Mode Probe XHTML*")
  if (-not $localBrowseWorked) { throw "local xhtml target opened the wrong headed title" }

  $profileRoot = Join-Path $root "profile-xhtml-shared-flag"
  New-Item -ItemType Directory -Path $profileRoot -Force | Out-Null
  $shared = Start-Process -FilePath $browserExe -ArgumentList "--profile_dir",$profileRoot,$localTarget -PassThru -RedirectStandardOutput $sharedOut -RedirectStandardError $sharedErr
  $sharedHwnd = Wait-ForWindowHandle $shared.Id
  if ($sharedHwnd -eq [IntPtr]::Zero) { throw "shared-flag xhtml target did not infer headed browse mode" }
  Show-SmokeWindow $sharedHwnd
  $titles.shared = Get-SmokeWindowTitle $sharedHwnd
  $sharedBrowseWorked = ($titles.shared -like "Mode Probe XHTML*")
  if (-not $sharedBrowseWorked) { throw "shared-flag xhtml target opened the wrong headed title" }

  $remoteHtmlUrl = "http://127.0.0.1:$port/remote-export.html"
  $remoteHtml = Start-Process -FilePath $browserExe -ArgumentList $remoteHtmlUrl -PassThru -RedirectStandardOutput $remoteHtmlOut -RedirectStandardError $remoteHtmlErr
  $remoteHtmlExited = Wait-ForExit $remoteHtml
  $remoteHtml.Refresh()
  $remoteHtmlWindowed = (-not $remoteHtmlExited) -and ($remoteHtml.MainWindowHandle -ne 0)
  $remoteHtmlStayedNonWindowed = $remoteHtmlExited -and (-not $remoteHtmlWindowed)
  if (-not $remoteHtmlStayedNonWindowed) { throw "scheme-based .html URL inferred headed browse mode instead of the non-windowed fallback" }

  $remoteHtmUrl = "http://127.0.0.1:$port/remote-export.htm"
  $remoteHtm = Start-Process -FilePath $browserExe -ArgumentList $remoteHtmUrl -PassThru -RedirectStandardOutput $remoteHtmOut -RedirectStandardError $remoteHtmErr
  $remoteHtmExited = Wait-ForExit $remoteHtm
  $remoteHtm.Refresh()
  $remoteHtmWindowed = (-not $remoteHtmExited) -and ($remoteHtm.MainWindowHandle -ne 0)
  $remoteHtmStayedNonWindowed = $remoteHtmExited -and (-not $remoteHtmWindowed)
  if (-not $remoteHtmStayedNonWindowed) { throw "scheme-based .htm URL inferred headed browse mode instead of the non-windowed fallback" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $localMeta = Stop-OwnedProbeProcess $local
  $sharedMeta = Stop-OwnedProbeProcess $shared
  $remoteHtmlMeta = Stop-OwnedProbeProcess $remoteHtml
  $remoteHtmMeta = Stop-OwnedProbeProcess $remoteHtm
  Start-Sleep -Milliseconds 200

  [ordered]@{
    server_pid = if ($server) { $server.Id } else { 0 }
    local_pid = if ($local) { $local.Id } else { 0 }
    shared_pid = if ($shared) { $shared.Id } else { 0 }
    remote_html_pid = if ($remoteHtml) { $remoteHtml.Id } else { 0 }
    remote_htm_pid = if ($remoteHtm) { $remoteHtm.Id } else { 0 }
    ready = $ready
    local_browse_worked = $localBrowseWorked
    shared_browse_worked = $sharedBrowseWorked
    remote_html_stayed_non_windowed = $remoteHtmlStayedNonWindowed
    remote_htm_stayed_non_windowed = $remoteHtmStayedNonWindowed
    titles = $titles
    error = $failure
    server_meta = $serverMeta
    local_meta = $localMeta
    shared_meta = $sharedMeta
    remote_html_meta = $remoteHtmlMeta
    remote_htm_meta = $remoteHtmMeta
  } | ConvertTo-Json -Depth 7
}

if ($failure) {
  exit 1
}
