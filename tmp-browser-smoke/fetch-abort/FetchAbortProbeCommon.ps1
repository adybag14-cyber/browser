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

function Reset-FetchAbortProfile([string]$ProfileRoot) {
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

function Seed-FetchAbortProfile([string]$AppDataRoot) {
@"
lightpanda-browse-settings-v1
restore_previous_session	0
allow_script_popups	0
default_zoom_percent	100
homepage_url	
"@ | Set-Content -Path (Join-Path $AppDataRoot "browse-settings-v1.txt") -NoNewline
}

function Wait-FetchAbortServer([int]$Port, [int]$Attempts = 30) {
  return Wait-LightpandaHttpReady -Url "http://127.0.0.1:$Port/healthz" -TimeoutSeconds ([Math]::Max(1, [int][Math]::Ceiling($Attempts / 4.0))) -PollMilliseconds 250
}

function Start-FetchAbortServer([int]$Port, [string]$Stdout, [string]$Stderr) {
  $python = Resolve-LightpandaPythonCommand
  return Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @((Join-Path $script:Root "fetch_abort_server.py"),"$Port")) -WorkingDirectory $script:Root -PassThru -RedirectStandardOutput $Stdout -RedirectStandardError $Stderr
}

function Start-FetchAbortBrowser([string]$StartupUrl, [string]$Stdout, [string]$Stderr) {
  return Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl) -WorkingDirectory $script:Repo -PassThru -RedirectStandardOutput $Stdout -RedirectStandardError $Stderr
}

function Read-FetchAbortServerLog([string]$Path) {
  if (-not (Test-Path $Path)) {
    return ""
  }
  return Get-Content -Path $Path -Raw
}

function Wait-FetchAbortServerLogMatch([string]$Path, [string]$Pattern, [int]$Attempts = 40) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    $data = Read-FetchAbortServerLog $Path
    if ($data -match $Pattern) {
      return $data
    }
    Start-Sleep -Milliseconds 150
  }
  return $null
}

function Format-FetchAbortProcessMeta($Meta) {
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

function Write-FetchAbortResult($Result, [string]$Prefix = "") {
  foreach ($entry in $Result.GetEnumerator()) {
    $key = if ($Prefix) { "$Prefix$($entry.Key)" } else { [string]$entry.Key }
    $value = $entry.Value

    if ($value -is [System.Collections.IDictionary]) {
      Write-FetchAbortResult $value "$key."
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
