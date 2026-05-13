[CmdletBinding()]
param()

Set-StrictMode -Version Latest

function Resolve-LightpandaRepoRoot([string]$StartPath) {
  if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    return $env:LIGHTPANDA_REPO_ROOT
  }

  $cursor = [System.IO.Path]::GetFullPath($StartPath)
  while ($true) {
    if (Test-Path (Join-Path $cursor "build.zig")) {
      return $cursor
    }

    $parent = Split-Path $cursor -Parent
    if ([string]::IsNullOrEmpty($parent) -or $parent -eq $cursor) {
      throw "Could not resolve the Lightpanda repo root from $StartPath. Set LIGHTPANDA_REPO_ROOT to override."
    }

    $cursor = $parent
  }
}

function Resolve-LightpandaBrowserExe([string]$RepoRoot, [string]$BrowserExe) {
  if (-not [string]::IsNullOrWhiteSpace($BrowserExe)) {
    return $BrowserExe
  }
  if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_BROWSER_EXE)) {
    return $env:LIGHTPANDA_BROWSER_EXE
  }
  return (Join-Path $RepoRoot "zig-out\bin\lightpanda.exe")
}

function Resolve-LightpandaPythonCommand {
  if (Get-Command python -ErrorAction SilentlyContinue) {
    return @{ FileName = "python"; Arguments = @() }
  }
  if (Get-Command py -ErrorAction SilentlyContinue) {
    return @{ FileName = "py"; Arguments = @("-3") }
  }
  throw "Python was not found in PATH. Install Python or start the probe server separately."
}

function Wait-LightpandaHttpReady([string]$Url, [int]$TimeoutSeconds = 15, [int]$PollMilliseconds = 250) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
      if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) {
        return $true
      }
    } catch {
    }
    Start-Sleep -Milliseconds $PollMilliseconds
  } while ((Get-Date) -lt $deadline)

  return $false
}

function Wait-LightpandaFileReady([string]$Path, [int]$Attempts = 60, [int]$PollMilliseconds = 250) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    if ((Test-Path -LiteralPath $Path) -and ((Get-Item -LiteralPath $Path).Length -gt 0)) {
      return $true
    }
  }

  return $false
}

function Stop-LightpandaOwnedProbeProcess($Process) {
  if (-not $Process) {
    return $null
  }

  $meta = Get-CimInstance Win32_Process -Filter "ProcessId=$($Process.Id)" -ErrorAction SilentlyContinue |
    Select-Object Name,ProcessId,CommandLine,CreationDate
  if ($meta -and $meta.CommandLine -and $meta.CommandLine -notmatch "codex\.js|@openai/codex") {
    Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
  }
  return $meta
}
