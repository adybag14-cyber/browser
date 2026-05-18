[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "tabs\TabProbeCommon.ps1")

$script:Root = $PSScriptRoot
$script:Repo = Resolve-LightpandaRepoRoot $script:Root
$script:BrowserExe = Resolve-LightpandaBrowserExe $script:Repo $null

function Reset-CookieProfile([string]$ProfileRoot) {
  $appDataRoot = Join-Path $ProfileRoot "lightpanda"
  $downloadsDir = Join-Path $appDataRoot "downloads"
  if (Test-Path -LiteralPath $ProfileRoot) {
    Remove-Item -LiteralPath $ProfileRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
  New-Item -ItemType Directory -Force -Path $downloadsDir | Out-Null
  $env:APPDATA = $ProfileRoot
  $env:LOCALAPPDATA = $ProfileRoot
  return @{
    AppDataRoot = $appDataRoot
    DownloadsDir = $downloadsDir
    CookiesFile = Join-Path $appDataRoot "cookies-v1.txt"
    SettingsFile = Join-Path $appDataRoot "browse-settings-v1.txt"
  }
}

function Seed-CookieProfile([string]$AppDataRoot) {
  @"
lightpanda-browse-settings-v1
restore_previous_session	0
allow_script_popups	0
default_zoom_percent	100
homepage_url	
"@ | Set-Content -Path (Join-Path $AppDataRoot "browse-settings-v1.txt") -NoNewline
}

function Wait-CookieServer([int]$Port, [int]$TimeoutSeconds = 15, [int]$PollMilliseconds = 250) {
  return Wait-LightpandaHttpReady -Url "http://127.0.0.1:$Port/seed.html" -TimeoutSeconds $TimeoutSeconds -PollMilliseconds $PollMilliseconds
}

function Start-CookieServer([int]$Port, [string]$Stdout, [string]$Stderr) {
  $python = Resolve-LightpandaPythonCommand
  return Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @((Join-Path $script:Root "cookie_server.py"),"$Port")) -WorkingDirectory $script:Root -PassThru -RedirectStandardOutput $Stdout -RedirectStandardError $Stderr
}

function Start-CookieBrowser([string]$StartupUrl, [string]$Stdout, [string]$Stderr) {
  return Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl) -WorkingDirectory $script:Repo -PassThru -RedirectStandardOutput $Stdout -RedirectStandardError $Stderr
}

function Invoke-CookieAddressCommit([IntPtr]$Hwnd, [string]$Url) {
  [void](Invoke-SmokeClientClick $Hwnd 160 40)
  Start-Sleep -Milliseconds 150
  Send-SmokeCtrlA
  Start-Sleep -Milliseconds 120
  Send-SmokeText $Url
  Start-Sleep -Milliseconds 120
  Send-SmokeEnter
}

function Invoke-CookieAddressNavigate([IntPtr]$Hwnd, [int]$BrowserId, [string]$Url, [string]$Needle) {
  Invoke-CookieAddressCommit $Hwnd $Url
  return Wait-TabTitle $BrowserId $Needle 40
}

function Focus-CookieDocument([IntPtr]$Hwnd) {
  [void](Invoke-SmokeClientClick $Hwnd 120 120)
  Start-Sleep -Milliseconds 120
}

function Invoke-CookieSettingsClear([IntPtr]$Hwnd, [int]$TabCount = 8, [int]$PauseMs = 500) {
  Focus-CookieDocument $Hwnd
  for ($i = 0; $i -lt $TabCount; $i++) {
    Send-SmokeTab
    Start-Sleep -Milliseconds 120
  }
  Send-SmokeEnter
  Start-Sleep -Milliseconds $PauseMs
}

function Read-CookieFileData([string]$CookieFile) {
  if (-not (Test-Path $CookieFile)) {
    return ""
  }
  return Get-Content $CookieFile -Raw
}

function Wait-OwnedProbeProcessGone([int]$ProcessId, [int]$Attempts = 40) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    if (-not (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue)) {
      return $true
    }
    Start-Sleep -Milliseconds 150
  }
  return $false
}

function Wait-CookieFileMatch([string]$CookieFile, [string]$Pattern, [int]$Attempts = 40) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    $data = Read-CookieFileData $CookieFile
    if ($data -match $Pattern) {
      return $data
    }
    Start-Sleep -Milliseconds 150
  }
  return $null
}

function Wait-CookieFileNoMatch([string]$CookieFile, [string]$Pattern, [int]$Attempts = 40) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    $data = Read-CookieFileData $CookieFile
    if ($data -notmatch $Pattern) {
      return $data
    }
    Start-Sleep -Milliseconds 150
  }
  return $null
}

function Format-CookieProbeProcessMeta($Meta) {
  if (-not $Meta) {
    return $null
  }

  return [ordered]@{
    name = [string]$Meta.Name
    pid = [int]$Meta.ProcessId
    command_line = [string]$Meta.CommandLine
    created = [string]$Meta.CreationDate
  }
}

function Write-CookieProbeResult($Result, [string]$Prefix = "") {
  foreach ($entry in $Result.GetEnumerator()) {
    $key = if ($Prefix) { "$Prefix$($entry.Key)" } else { [string]$entry.Key }
    $value = $entry.Value

    if ($value -is [System.Collections.IDictionary]) {
      Write-CookieProbeResult $value "$key."
      continue
    }

    if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
      $joined = ($value | ForEach-Object { [string]$_ }) -join ","
      Write-Output ("{0}={1}" -f $key, $joined)
      continue
    }

    $text = if ($null -eq $value) { "" } else { [string]$value }
    $text = $text -replace "`r", "\\r"
    $text = $text -replace "`n", "\\n"
    Write-Output ("{0}={1}" -f $key, $text)
  }
}
