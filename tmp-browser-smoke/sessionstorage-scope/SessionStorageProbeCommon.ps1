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

function Reset-SessionStorageProfile([string]$ProfileRoot) {
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

function Seed-SessionStorageProfile([string]$AppDataRoot) {
@"
lightpanda-browse-settings-v1
restore_previous_session	0
allow_script_popups	0
default_zoom_percent	100
homepage_url	
"@ | Set-Content -Path (Join-Path $AppDataRoot "browse-settings-v1.txt") -NoNewline
}

function Wait-SessionStorageServer([int]$Port, [int]$Attempts = 30) {
  return Wait-LightpandaHttpReady -Url "http://127.0.0.1:$Port/seed.html" -TimeoutSeconds ([Math]::Max(1, [int][Math]::Ceiling($Attempts / 4.0))) -PollMilliseconds 250
}

function Start-SessionStorageServer([int]$Port, [string]$Stdout, [string]$Stderr) {
  $python = Resolve-LightpandaPythonCommand
  return Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @((Join-Path $script:Root "session_storage_server.py"),"$Port")) -WorkingDirectory $script:Root -PassThru -RedirectStandardOutput $Stdout -RedirectStandardError $Stderr
}

function Start-SessionStorageBrowser([string]$StartupUrl, [string]$Stdout, [string]$Stderr) {
  return Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl) -WorkingDirectory $script:Repo -PassThru -RedirectStandardOutput $Stdout -RedirectStandardError $Stderr
}

function Invoke-SessionStorageAddressCommit([IntPtr]$Hwnd, [string]$Url) {
  [void](Invoke-SmokeClientClick $Hwnd 160 40)
  Start-Sleep -Milliseconds 150
  Send-SmokeCtrlA
  Start-Sleep -Milliseconds 120
  Send-SmokeText $Url
  Start-Sleep -Milliseconds 120
  Send-SmokeEnter
}

function Invoke-SessionStorageAddressNavigate([IntPtr]$Hwnd, [int]$BrowserId, [string]$Url, [string]$Needle) {
  Invoke-SessionStorageAddressCommit $Hwnd $Url
  return Wait-SessionStorageWindowTitle $Hwnd $Needle 40
}

function Wait-SessionStorageWindowTitle([IntPtr]$Hwnd, [string]$Needle, [int]$Attempts = 40) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds 250
    $title = Get-SmokeWindowTitle $Hwnd
    if ($title -like "*$Needle*") {
      return $title
    }
  }
  return $null
}

function Format-SessionStorageProbeProcessMeta($Meta) {
  if (-not $Meta) { return $null }
  return [ordered]@{
    name = [string]$Meta.Name
    pid = [int]$Meta.ProcessId
    command_line = [string]$Meta.CommandLine
    created = [string]$Meta.CreationDate
  }
}

function Write-SessionStorageProbeResult($Result, [string]$Prefix = "") {
  foreach ($entry in $Result.GetEnumerator()) {
    $key = if ($Prefix) { "$Prefix$($entry.Key)" } else { [string]$entry.Key }
    $value = $entry.Value
    if ($value -is [System.Collections.IDictionary]) {
      Write-SessionStorageProbeResult $value "$key."
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
