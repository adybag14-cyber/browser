[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "tabs\TabProbeCommon.ps1")

function Resolve-StorageProbeConfig {
  param(
    [Parameter(Mandatory = $true)]
    [string]$StartPath,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$ProfileName = ""
  )

  $resolvedRepoRoot = if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    Resolve-LightpandaRepoRoot $StartPath
  } else {
    $RepoRoot
  }
  $smokeRoot = Join-Path $resolvedRepoRoot "tmp-browser-smoke\localstorage-persistence"
  $resolvedBrowserExe = Resolve-LightpandaBrowserExe $resolvedRepoRoot $BrowserExe
  $resolvedProfileRoot = if ([string]::IsNullOrWhiteSpace($ProfileName)) { $null } else { Join-Path $smokeRoot $ProfileName }
  $appDataRoot = if ($resolvedProfileRoot) { Join-Path $resolvedProfileRoot "lightpanda" } else { $null }

  return @{
    RepoRoot = $resolvedRepoRoot
    SmokeRoot = $smokeRoot
    BrowserExe = $resolvedBrowserExe
    ProfileRoot = $resolvedProfileRoot
    AppDataRoot = $appDataRoot
    DownloadsDir = if ($appDataRoot) { Join-Path $appDataRoot "downloads" } else { $null }
    LocalStorageFile = if ($appDataRoot) { Join-Path $appDataRoot "local-storage-v1.txt" } else { $null }
    SettingsFile = if ($appDataRoot) { Join-Path $appDataRoot "browse-settings-v1.txt" } else { $null }
  }
}

function Reset-StorageProfile([string]$ProfileRoot) {
  if ([string]::IsNullOrWhiteSpace($ProfileRoot)) {
    return $null
  }

  $appDataRoot = Join-Path $ProfileRoot "lightpanda"
  $downloadsDir = Join-Path $appDataRoot "downloads"
  if (Test-Path -LiteralPath $ProfileRoot) {
    Remove-Item -LiteralPath $ProfileRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
  New-Item -ItemType Directory -Force -Path $downloadsDir | Out-Null
  return @{
    AppDataRoot = $appDataRoot
    DownloadsDir = $downloadsDir
    LocalStorageFile = Join-Path $appDataRoot "local-storage-v1.txt"
    SettingsFile = Join-Path $appDataRoot "browse-settings-v1.txt"
  }
}

function Set-StorageProfileEnvironment([string]$ProfileRoot) {
  if ([string]::IsNullOrWhiteSpace($ProfileRoot)) {
    return
  }

  $env:APPDATA = $ProfileRoot
  $env:LOCALAPPDATA = $ProfileRoot
}

function Seed-StorageProfile([string]$AppDataRoot) {
@"
lightpanda-browse-settings-v1
restore_previous_session	0
allow_script_popups	0
default_zoom_percent	100
homepage_url	
"@ | Set-Content -Path (Join-Path $AppDataRoot "browse-settings-v1.txt") -NoNewline
}

function Wait-StorageServer([string]$Host, [int]$Port, [int]$TimeoutSeconds = 15, [int]$PollMilliseconds = 250) {
  return Wait-LightpandaHttpReady -Url "http://$Host`:$Port/seed.html" -TimeoutSeconds $TimeoutSeconds -PollMilliseconds $PollMilliseconds
}

function Start-StorageServer([string]$WorkingDirectory, [int]$Port, [string]$Stdout, [string]$Stderr) {
  $python = Resolve-LightpandaPythonCommand
  return Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @((Join-Path $WorkingDirectory "storage_server.py"),"$Port")) -WorkingDirectory $WorkingDirectory -PassThru -RedirectStandardOutput $Stdout -RedirectStandardError $Stderr
}

function Start-StorageBrowser([string]$RepoRoot, [string]$BrowserExe, [string]$StartupUrl, [string]$Stdout, [string]$Stderr) {
  return Start-Process -FilePath $BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl) -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $Stdout -RedirectStandardError $Stderr
}

function Invoke-StorageAddressCommit([IntPtr]$Hwnd, [string]$Url) {
  [void](Invoke-SmokeClientClick $Hwnd 160 40)
  Start-Sleep -Milliseconds 150
  Send-SmokeCtrlA
  Start-Sleep -Milliseconds 120
  Send-SmokeText $Url
  Start-Sleep -Milliseconds 120
  Send-SmokeEnter
}

function Invoke-StorageAddressNavigate([IntPtr]$Hwnd, [int]$BrowserId, [string]$Url, [string]$Needle) {
  Invoke-StorageAddressCommit $Hwnd $Url
  return Wait-TabTitle $BrowserId $Needle 40
}

function Read-LocalStorageFileData([string]$LocalStorageFile) {
  if (-not (Test-Path $LocalStorageFile)) {
    return ""
  }
  return Get-Content $LocalStorageFile -Raw
}

function ConvertTo-LocalStorageEntryPattern([string]$Origin, [string]$Key, [string]$Value) {
  $originField = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Origin))
  $keyField = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Key))
  $valueField = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Value))
  return [regex]::Escape("entry`t$originField`t$keyField`t$valueField")
}

function Wait-LocalStorageFileMatch([string]$LocalStorageFile, [string]$Pattern, [int]$Attempts = 40) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    $data = Read-LocalStorageFileData $LocalStorageFile
    if ($data -match $Pattern) {
      return $data
    }
    Start-Sleep -Milliseconds 150
  }
  return $null
}

function Wait-LocalStorageFileNoMatch([string]$LocalStorageFile, [string]$Pattern, [int]$Attempts = 40) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    $data = Read-LocalStorageFileData $LocalStorageFile
    if ($data -notmatch $Pattern) {
      return $data
    }
    Start-Sleep -Milliseconds 150
  }
  return $null
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

function Stop-OwnedProbeProcess([System.Diagnostics.Process]$Process) {
  return Stop-LightpandaOwnedProbeProcess $Process
}

function Format-StorageProbeProcessMeta($Meta) {
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

function Write-StorageProbeResult($Result, [string]$Prefix = "") {
  foreach ($entry in $Result.GetEnumerator()) {
    $key = if ($Prefix) { "$Prefix$($entry.Key)" } else { [string]$entry.Key }
    $value = $entry.Value

    if ($value -is [System.Collections.IDictionary]) {
      Write-StorageProbeResult $value "$key."
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
