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
$profileRoot = Join-Path $root "profile-stylesheet-auth"
$appDataRoot = Join-Path $profileRoot "lightpanda"
$serverScript = Join-Path $root "stylesheet_server.py"
$browserOut = Join-Path $root "stylesheet-auth.browser.stdout.txt"
$browserErr = Join-Path $root "stylesheet-auth.browser.stderr.txt"
$serverOut = Join-Path $root "stylesheet-auth.server.stdout.txt"
$serverErr = Join-Path $root "stylesheet-auth.server.stderr.txt"
$requestLog = Join-Path $root "stylesheet.requests.jsonl"
$pageUrl = "http://css%20user:p%40ss@127.0.0.1:$Port/auth-stylesheet-page.html"
$readyUrl = "http://127.0.0.1:$Port/auth-stylesheet-page.html"

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
$cssEntry = $null
$loadedEntry = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }
  if (-not (Test-Path -LiteralPath $serverScript)) { throw "stylesheet server script not found: $serverScript" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url $readyUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "localhost stylesheet auth server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "960", "--window_height", "640", $pageUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  for ($i = 0; $i -lt $ProbeAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    if (-not (Test-Path -LiteralPath $requestLog)) {
      continue
    }

    $entries = Get-Content -LiteralPath $requestLog | Where-Object { $_.Trim().Length -gt 0 } | ForEach-Object { $_ | ConvertFrom-Json }
    $cssEntries = @($entries | Where-Object { $_.path -eq "/private.css" })
    $loadedEntries = @($entries | Where-Object { $_.path -eq "/loaded" })
    if ($cssEntries.Count -gt 0) { $cssEntry = $cssEntries[-1] }
    if ($loadedEntries.Count -gt 0) { $loadedEntry = $loadedEntries[-1] }
    if ($cssEntry -and $loadedEntry) {
      $loaded = $true
      break
    }
  }

  if (-not $loaded) { throw "stylesheet auth probe did not observe both stylesheet and loaded beacons" }
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
    stylesheet_allowed = if ($cssEntry) { [bool]$cssEntry.allowed } else { $false }
    stylesheet_user_agent = if ($cssEntry) { [string]$cssEntry.user_agent } else { "" }
    stylesheet_cookie = if ($cssEntry) { [string]$cssEntry.cookie } else { "" }
    stylesheet_referer = if ($cssEntry) { [string]$cssEntry.referer } else { "" }
    stylesheet_authorization = if ($cssEntry) { [string]$cssEntry.authorization } else { "" }
    stylesheet_accept = if ($cssEntry) { [string]$cssEntry.accept } else { "" }
    loaded_sheet = if ($loadedEntry) { [string]$loadedEntry.sheet } else { "" }
    loaded_count = if ($loadedEntry) { [string]$loadedEntry.count } else { "" }
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
