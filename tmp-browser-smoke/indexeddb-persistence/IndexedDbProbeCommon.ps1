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

function Reset-IndexedDbProfile([string]$ProfileRoot) {
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
    IndexedDbFile = Join-Path $appDataRoot "indexed-db-v1.txt"
    SettingsFile = Join-Path $appDataRoot "browse-settings-v1.txt"
  }
}

function Seed-IndexedDbProfile([string]$AppDataRoot) {
@"
lightpanda-browse-settings-v1
restore_previous_session	0
allow_script_popups	0
default_zoom_percent	100
homepage_url	
"@ | Set-Content -Path (Join-Path $AppDataRoot "browse-settings-v1.txt") -NoNewline
}

function Get-FreeIndexedDbPort() {
  $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
  $listener.Start()
  try {
    return ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port
  } finally {
    $listener.Stop()
  }
}

function Wait-IndexedDbServer([int]$Port, [int]$TimeoutSeconds = 15, [int]$PollMilliseconds = 250) {
  return Wait-LightpandaHttpReady -Url "http://127.0.0.1:$Port/seed.html" -TimeoutSeconds $TimeoutSeconds -PollMilliseconds $PollMilliseconds
}

function Start-IndexedDbServer([int]$Port, [string]$Stdout, [string]$Stderr) {
  $python = Resolve-LightpandaPythonCommand
  return Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @((Join-Path $script:Root "indexeddb_server.py"),"$Port")) -WorkingDirectory $script:Root -PassThru -RedirectStandardOutput $Stdout -RedirectStandardError $Stderr
}

function Start-IndexedDbBrowser([string]$StartupUrl, [string]$Stdout, [string]$Stderr) {
  return Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl) -WorkingDirectory $script:Repo -PassThru -RedirectStandardOutput $Stdout -RedirectStandardError $Stderr
}

function Invoke-IndexedDbAddressCommit([IntPtr]$Hwnd, [string]$Url) {
  Show-SmokeWindow $Hwnd
  Start-Sleep -Milliseconds 120
  Send-SmokeCtrlL
  Start-Sleep -Milliseconds 150
  Send-SmokeCtrlA
  Start-Sleep -Milliseconds 120
  Send-SmokeText $Url
  Start-Sleep -Milliseconds 120
  Send-SmokeEnter
}

function Invoke-IndexedDbAddressNavigate([IntPtr]$Hwnd, [int]$BrowserId, [string]$Url, [string]$Needle) {
  Invoke-IndexedDbAddressCommit $Hwnd $Url
  return Wait-TabTitle $BrowserId $Needle 40
}

function Read-IndexedDbFileData([string]$IndexedDbFile) {
  if (-not (Test-Path $IndexedDbFile)) {
    return ""
  }
  return Get-Content $IndexedDbFile -Raw
}

function ConvertTo-IndexedDbEntryPattern([string]$Origin, [string]$DatabaseName, [string]$StoreName, [string]$Key, [string]$Json) {
  $originField = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Origin))
  $dbField = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($DatabaseName))
  $storeField = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($StoreName))
  $keyField = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Key))
  $valueField = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Json))
  return [regex]::Escape("entry`t$originField`t$dbField`t$storeField`t$keyField`t$valueField")
}

function ConvertTo-IndexedDbIndexPattern([string]$Origin, [string]$DatabaseName, [string]$StoreName, [string]$IndexName, [string]$KeyPath) {
  $originField = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Origin))
  $dbField = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($DatabaseName))
  $storeField = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($StoreName))
  $indexField = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($IndexName))
  $keyPathField = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($KeyPath))
  return [regex]::Escape("index`t$originField`t$dbField`t$storeField`t$indexField`t$keyPathField")
}

function Wait-IndexedDbFileMatch([string]$IndexedDbFile, [string]$Pattern, [int]$Attempts = 40) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    $data = Read-IndexedDbFileData $IndexedDbFile
    if ($data -match $Pattern) {
      return $data
    }
    Start-Sleep -Milliseconds 150
  }
  return $null
}

function Wait-IndexedDbFileNoMatch([string]$IndexedDbFile, [string]$Pattern, [int]$Attempts = 40) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    $data = Read-IndexedDbFileData $IndexedDbFile
    if ($data -notmatch $Pattern) {
      return $data
    }
    Start-Sleep -Milliseconds 150
  }
  return $null
}

function Wait-OwnedIndexedDbProbeProcessGone([int]$ProcessId, [int]$Attempts = 40) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    if (-not (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue)) {
      return $true
    }
    Start-Sleep -Milliseconds 150
  }
  return $false
}

function Format-IndexedDbProbeProcessMeta($Meta) {
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

function Write-IndexedDbProbeResult($Result, [string]$Prefix = "") {
  foreach ($entry in $Result.GetEnumerator()) {
    $key = if ($Prefix) { "$Prefix$($entry.Key)" } else { [string]$entry.Key }
    $value = $entry.Value

    if ($value -is [System.Collections.IDictionary]) {
      Write-IndexedDbProbeResult $value "$key."
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
