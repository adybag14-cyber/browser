[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [int]$Port = 8160,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$ProbeAttempts = 80,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\stylesheet-smoke"
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$profileRoot = Join-Path $root "profile-stylesheet-import-auth"
$appDataRoot = Join-Path $profileRoot "lightpanda"
$serverScript = Join-Path $root "stylesheet_server.py"
$browserOut = Join-Path $root "stylesheet-import-auth.browser.stdout.txt"
$browserErr = Join-Path $root "stylesheet-import-auth.browser.stderr.txt"
$serverOut = Join-Path $root "stylesheet-import-auth.server.stdout.txt"
$serverErr = Join-Path $root "stylesheet-import-auth.server.stderr.txt"
$requestLog = Join-Path $root "stylesheet.requests.jsonl"
$pageUrl = "http://css%20user:p%40ss@127.0.0.1:$Port/auth-stylesheet-import-page.html"
$readyUrl = "http://127.0.0.1:$Port/auth-stylesheet-import-page.html"

Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$requestLog -Force -ErrorAction SilentlyContinue
cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
New-Item -ItemType Directory -Force -Path $appDataRoot | Out-Null
$env:APPDATA = $profileRoot
$env:LOCALAPPDATA = $profileRoot
@"
lightpanda-browse-settings-v1
restore_previous_session	0
allow_script_popups	0
default_zoom_percent	100
homepage_url	
"@ | Set-Content -Path (Join-Path $appDataRoot "browse-settings-v1.txt") -NoNewline

$server = $null
$browser = $null
$ready = $false
$loaded = $false
$failure = $null
$rootEntry = $null
$childEntry = $null
$loadedEntry = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }
  if (-not (Test-Path -LiteralPath $serverScript)) { throw "stylesheet server script not found: $serverScript" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url $readyUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "localhost stylesheet import auth server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "960", "--window_height", "640", $pageUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  for ($i = 0; $i -lt $ProbeAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    if (-not (Test-Path -LiteralPath $requestLog)) {
      continue
    }

    $entries = Get-Content -LiteralPath $requestLog | Where-Object { $_.Trim().Length -gt 0 } | ForEach-Object { $_ | ConvertFrom-Json }
    $rootEntries = @($entries | Where-Object { $_.path -eq "/private-import-root.css" })
    $childEntries = @($entries | Where-Object { $_.path -eq "/private-import-child.css" })
    $loadedEntries = @($entries | Where-Object { $_.path -eq "/loaded-import" })
    if ($rootEntries.Count -gt 0) { $rootEntry = $rootEntries[-1] }
    if ($childEntries.Count -gt 0) { $childEntry = $childEntries[-1] }
    if ($loadedEntries.Count -gt 0) { $loadedEntry = $loadedEntries[-1] }
    if ($rootEntry -and $childEntry -and $loadedEntry) {
      $loaded = $true
      break
    }
  }

  if (-not $loaded) { throw "stylesheet import auth probe did not observe root, child, and loaded beacons" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-LightpandaOwnedProbeProcess $server
  $browserMeta = Stop-LightpandaOwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    port = $Port
    page_url = $pageUrl
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    loaded = $loaded
    root_allowed = if ($rootEntry) { [bool]$rootEntry.allowed } else { $false }
    root_cookie = if ($rootEntry) { [string]$rootEntry.cookie } else { "" }
    root_referer = if ($rootEntry) { [string]$rootEntry.referer } else { "" }
    root_authorization = if ($rootEntry) { [string]$rootEntry.authorization } else { "" }
    child_allowed = if ($childEntry) { [bool]$childEntry.allowed } else { $false }
    child_cookie = if ($childEntry) { [string]$childEntry.cookie } else { "" }
    child_referer = if ($childEntry) { [string]$childEntry.referer } else { "" }
    child_authorization = if ($childEntry) { [string]$childEntry.authorization } else { "" }
    loaded_applied = if ($loadedEntry) { [string]$loadedEntry.applied } else { "" }
    loaded_bg = if ($loadedEntry) { [string]$loadedEntry.bg } else { "" }
    loaded_allowed = if ($loadedEntry) { [bool]$loadedEntry.allowed } else { $false }
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
