Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "tabs\TabProbeCommon.ps1")

$script:Root = $PSScriptRoot
$script:Repo = Resolve-LightpandaRepoRoot $script:Root
$script:BrowserExe = Resolve-LightpandaBrowserExe $script:Repo $null

function Reset-BrowserPagesProfile([string]$ProfileRoot) {
  $appDataRoot = Join-Path $ProfileRoot "lightpanda"
  $downloadsDir = Join-Path $appDataRoot "downloads"
  cmd /c "rmdir /s /q `"$ProfileRoot`"" | Out-Null
  New-Item -ItemType Directory -Force -Path $downloadsDir | Out-Null
  $env:APPDATA = $ProfileRoot
  $env:LOCALAPPDATA = $ProfileRoot
  return @{
    AppDataRoot = $appDataRoot
    DownloadsDir = $downloadsDir
  }
}

function Seed-BrowserPagesProfile {
  param(
    [string]$AppDataRoot,
    [string]$DownloadsDir,
    [int]$Port,
    [bool]$RestorePreviousSession = $true,
    [bool]$AllowScriptPopups = $false,
    [int]$DefaultZoomPercent = 120,
    [string]$HomepageUrl = "http://127.0.0.1:$Port/index.html",
    [string[]]$Bookmarks = @(),
    [switch]$SeedDownload
  )

  @"
lightpanda-browse-settings-v1
restore_previous_session	$(if ($RestorePreviousSession) { 1 } else { 0 })
allow_script_popups	$(if ($AllowScriptPopups) { 1 } else { 0 })
default_zoom_percent	$DefaultZoomPercent
homepage_url	$HomepageUrl
"@ | Set-Content -Path (Join-Path $AppDataRoot "browse-settings-v1.txt") -NoNewline

  ($Bookmarks -join "`n") | Set-Content -Path (Join-Path $AppDataRoot "bookmarks.txt") -NoNewline

  if ($SeedDownload) {
    $seedDownloadPath = Join-Path $DownloadsDir "seed.txt"
    'seed file' | Set-Content -Path $seedDownloadPath -NoNewline
    @"
2	12	12	1	seed.txt	$seedDownloadPath	http://127.0.0.1:$Port/download.txt	
"@ | Set-Content -Path (Join-Path $AppDataRoot "downloads-v1.txt") -NoNewline
  } else {
    '' | Set-Content -Path (Join-Path $AppDataRoot "downloads-v1.txt") -NoNewline
  }
}

function Wait-BrowserPagesServer([int]$Port, [int]$Attempts = 30) {
  return Wait-LightpandaHttpReady -Url "http://127.0.0.1:$Port/index.html" -TimeoutSeconds ([Math]::Max(1, [int][Math]::Ceiling($Attempts / 4.0))) -PollMilliseconds 250
}

function Start-BrowserPagesServer([int]$Port, [string]$Stdout, [string]$Stderr) {
  $python = Resolve-LightpandaPythonCommand
  return Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind","127.0.0.1")) -WorkingDirectory $script:Root -PassThru -RedirectStandardOutput $Stdout -RedirectStandardError $Stderr
}

function Start-BrowserPagesBrowser {
  param(
    [string]$StartupUrl,
    [string]$Stdout,
    [string]$Stderr,
    [string]$DownloadShellLog = ""
  )

  $hadPreviousLog = Test-Path Env:LIGHTPANDA_DOWNLOAD_SHELL_LOG
  $previousLog = if ($hadPreviousLog) { $env:LIGHTPANDA_DOWNLOAD_SHELL_LOG } else { $null }
  try {
    if ([string]::IsNullOrWhiteSpace($DownloadShellLog)) {
      Remove-Item Env:LIGHTPANDA_DOWNLOAD_SHELL_LOG -ErrorAction SilentlyContinue
    } else {
      $env:LIGHTPANDA_DOWNLOAD_SHELL_LOG = $DownloadShellLog
    }
    return Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl) -WorkingDirectory $script:Repo -PassThru -RedirectStandardOutput $Stdout -RedirectStandardError $Stderr
  } finally {
    if ($hadPreviousLog) {
      $env:LIGHTPANDA_DOWNLOAD_SHELL_LOG = $previousLog
    } else {
      Remove-Item Env:LIGHTPANDA_DOWNLOAD_SHELL_LOG -ErrorAction SilentlyContinue
    }
  }
}

function Read-BrowserPagesShellLog([string]$LogPath) {
  if (-not (Test-Path $LogPath)) {
    return ,@()
  }
  return ,@(Get-Content $LogPath)
}

function Invoke-BrowserPagesAddressCommit([IntPtr]$Hwnd, [string]$Url) {
  [void](Invoke-SmokeClientClick $Hwnd 160 40)
  Start-Sleep -Milliseconds 150
  Send-SmokeCtrlA
  Start-Sleep -Milliseconds 120
  Send-SmokeText $Url
  Start-Sleep -Milliseconds 120
  Send-SmokeEnter
}

function Invoke-BrowserPagesAddressNavigate([IntPtr]$Hwnd, [int]$BrowserId, [string]$Url, [string]$Needle) {
  Invoke-BrowserPagesAddressCommit $Hwnd $Url
  return Wait-TabTitle $BrowserId $Needle 40
}

function Focus-BrowserPagesDocument([IntPtr]$Hwnd) {
  [void](Invoke-SmokeClientClick $Hwnd 120 120)
  Start-Sleep -Milliseconds 120
}

function Invoke-BrowserPagesTabActivate([IntPtr]$Hwnd, [int]$TabCount) {
  Focus-BrowserPagesDocument $Hwnd
  for ($i = 0; $i -lt $TabCount; $i++) {
    Send-SmokeTab
    Start-Sleep -Milliseconds 120
  }
  Send-SmokeEnter
}

function Invoke-BrowserPagesDocumentAction([IntPtr]$Hwnd, [int]$TabCount, [int]$BrowserId, [string]$Needle, [int]$Attempts = 40) {
  Focus-BrowserPagesDocument $Hwnd
  for ($i = 0; $i -lt $TabCount; $i++) {
    Send-SmokeTab
    Start-Sleep -Milliseconds 120
  }
  Send-SmokeEnter
  return Wait-TabTitle $BrowserId $Needle $Attempts
}

function Invoke-BrowserPagesDocumentActionNoNavigate([IntPtr]$Hwnd, [int]$TabCount, [int]$PauseMs = 450) {
  Focus-BrowserPagesDocument $Hwnd
  for ($i = 0; $i -lt $TabCount; $i++) {
    Send-SmokeTab
    Start-Sleep -Milliseconds 120
  }
  Send-SmokeEnter
  Start-Sleep -Milliseconds $PauseMs
}
