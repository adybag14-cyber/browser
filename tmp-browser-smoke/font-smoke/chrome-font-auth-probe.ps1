[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [int]$Port = 8162,
  [int]$ServerReadyTimeoutSeconds = 10,
  [int]$RequestReadyAttempts = 80,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path (Split-Path $PSScriptRoot -Parent) 'common\ProbeRuntime.ps1')

$repo = if ([string]::IsNullOrWhiteSpace($RepoRoot)) { Resolve-LightpandaRepoRoot $PSScriptRoot } else { $RepoRoot }
$root = Join-Path $repo 'tmp-browser-smoke\font-smoke'
$profileRoot = Join-Path $root 'profile-font-auth'
$appDataRoot = Join-Path $profileRoot 'lightpanda'
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$serverScript = Join-Path $root 'font_server.py'
$browserOut = Join-Path $root 'font-auth.browser.stdout.txt'
$browserErr = Join-Path $root 'font-auth.browser.stderr.txt'
$serverOut = Join-Path $root 'font-auth.server.stdout.txt'
$serverErr = Join-Path $root 'font-auth.server.stderr.txt'
$requestLog = Join-Path $root 'font.requests.jsonl'
$pageUrl = "http://fontuser:p%40ss@127.0.0.1:$Port/auth-font-page.html"
$server = $null
$browser = $null
$ready = $false
$fontEntry = $null
$loadedEntry = $null
$failure = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$requestLog -Force -ErrorAction SilentlyContinue
  cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
  New-Item -ItemType Directory -Force -Path $appDataRoot | Out-Null
  @"
lightpanda-browse-settings-v1
restore_previous_session	0
allow_script_popups	0
default_zoom_percent	100
homepage_url	
"@ | Set-Content -Path (Join-Path $appDataRoot 'browse-settings-v1.txt') -NoNewline

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript,$Port)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "http://127.0.0.1:$Port/auth-font-page.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw 'localhost font auth server did not become ready' }

  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  $browser = Start-Process -FilePath $browserExe -ArgumentList 'browse','--browser_mode','headed',$pageUrl -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  for ($i = 0; $i -lt $RequestReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    if (Test-Path -LiteralPath $requestLog) {
      $entries = Get-Content -LiteralPath $requestLog | Where-Object { $_.Trim().Length -gt 0 } | ForEach-Object { $_ | ConvertFrom-Json }
      $fontEntries = @($entries | Where-Object { $_.path -eq '/private-font.woff2' })
      $loadedEntries = @($entries | Where-Object { $_.path -eq '/loaded' })
      if ($fontEntries.Count -gt 0) { $fontEntry = $fontEntries[-1] }
      if ($loadedEntries.Count -gt 0) { $loadedEntry = $loadedEntries[-1] }
      if ($fontEntry -and $loadedEntry) { break }
    }
  }

  if (-not $fontEntry) { throw 'font auth probe did not capture the font request' }
  if (-not $loadedEntry) { throw 'font auth probe did not capture the load completion signal' }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-LightpandaOwnedProbeProcess $server
  $browserMeta = Stop-LightpandaOwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200

  $result = [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    port = $Port
    ready = $ready
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    font_allowed = if ($fontEntry) { [bool]$fontEntry.allowed } else { $false }
    font_user_agent = if ($fontEntry) { [string]$fontEntry.user_agent } else { '' }
    font_cookie = if ($fontEntry) { [string]$fontEntry.cookie } else { '' }
    font_referer = if ($fontEntry) { [string]$fontEntry.referer } else { '' }
    font_authorization = if ($fontEntry) { [string]$fontEntry.authorization } else { '' }
    font_accept = if ($fontEntry) { [string]$fontEntry.accept } else { '' }
    loaded_allowed = if ($loadedEntry) { [bool]$loadedEntry.allowed } else { $false }
    loaded_size = if ($loadedEntry) { [string]$loadedEntry.size } else { '' }
    loaded_status = if ($loadedEntry) { [string]$loadedEntry.status } else { '' }
    loaded_check = if ($loadedEntry) { [string]$loadedEntry.check } else { '' }
    loaded_count = if ($loadedEntry) { [string]$loadedEntry.loadCount } else { '' }
    loaded_family = if ($loadedEntry) { [string]$loadedEntry.family } else { '' }
    loaded_sheet = if ($loadedEntry) { [string]$loadedEntry.sheet } else { '' }
    loaded_rules = if ($loadedEntry) { [string]$loadedEntry.rules } else { '' }
    browser_gone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
    server_gone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }
    error = if ($failure) { $failure } else { '' }
    browser_stderr = if (Test-Path -LiteralPath $browserErr) { (Get-Content -LiteralPath $browserErr -Raw) -replace "`r","\\r" -replace "`n","\\n" } else { '' }
    server_stderr = if (Test-Path -LiteralPath $serverErr) { (Get-Content -LiteralPath $serverErr -Raw) -replace "`r","\\r" -replace "`n","\\n" } else { '' }
    browser_meta = $browserMeta
    server_meta = $serverMeta
  }
  $result | ConvertTo-Json -Depth 6

  if ($failure -or -not $ready -or -not $fontEntry -or -not $loadedEntry) {
    exit 1
  }
}
