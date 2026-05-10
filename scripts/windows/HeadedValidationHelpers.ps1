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
    if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
      throw "Could not resolve the Lightpanda repo root from $StartPath. Set LIGHTPANDA_REPO_ROOT to override."
    }
    $cursor = $parent
  }
}

function Convert-ToDisplayPath([string]$Path, [string]$RepoRoot) {
  $fullPath = [System.IO.Path]::GetFullPath($Path)
  $fullRoot = [System.IO.Path]::GetFullPath($RepoRoot)
  if ($fullPath.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $fullPath.Substring($fullRoot.Length).TrimStart("\", "/")
  }
  return $fullPath
}

function Format-PowerShellLiteral([string]$Value) {
  return "'" + $Value.Replace("'", "''") + "'"
}

function Get-AttachedHtmlCandidates([string]$RepoRoot) {
  $roots = @(
    (Join-Path $RepoRoot "user_files"),
    (Join-Path $RepoRoot "agent_files")
  )

  $items = @()
  foreach ($root in $roots) {
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
      continue
    }

    $items += Get-ChildItem -LiteralPath $root -Recurse -File |
      Where-Object { $_.Extension -in @(".html", ".htm") } |
      Sort-Object FullName
  }

  return @($items | Group-Object FullName | ForEach-Object { $_.Group[0] })
}

function Test-GoogleStyleFixture($Fixture) {
  $pathText = $Fixture.FullName
  if ($pathText -match '(?i)(google|safety|search)') {
    return $true
  }

  try {
    $raw = Get-Content -LiteralPath $Fixture.FullName -Raw -ErrorAction Stop
    return $raw -match '(?i)(<title[^>]*>.*google|google safety|search)'
  } catch {
    return $false
  }
}

function Resolve-FixtureSelection {
  param(
    [string]$RepoRoot,
    [string]$InputPath,
    [switch]$GoogleStyle,
    [int]$MaxCount = 3
  )

  $fixtures = @()
  if (-not [string]::IsNullOrWhiteSpace($InputPath)) {
    if (-not (Test-Path -LiteralPath $InputPath)) {
      throw "Input path not found: $InputPath"
    }

    $item = Get-Item -LiteralPath $InputPath
    if ($item.PSIsContainer) {
      $fixtures = Get-ChildItem -LiteralPath $item.FullName -Recurse -File |
        Where-Object { $_.Extension -in @(".html", ".htm") } |
        Sort-Object FullName
    } else {
      $fixtures = @($item)
    }
  } else {
    $fixtures = Get-AttachedHtmlCandidates -RepoRoot $RepoRoot
  }

  $fixtures = @($fixtures)
  if (-not $fixtures.Count) {
    return @()
  }

  if ($GoogleStyle) {
    $preferred = @($fixtures | Where-Object { Test-GoogleStyleFixture $_ })
    $others = @($fixtures | Where-Object { -not (Test-GoogleStyleFixture $_) })
    $fixtures = @($preferred + $others)
  }

  if ($MaxCount -gt 0 -and $fixtures.Count -gt $MaxCount) {
    $fixtures = $fixtures[0..($MaxCount - 1)]
  }

  return @($fixtures | ForEach-Object { $_.FullName })
}

function Convert-ToFixtureArgumentLines {
  param(
    [string[]]$FixturePaths,
    [string]$Indent = "  "
  )

  if (-not $FixturePaths -or -not $FixturePaths.Count) {
    return @()
  }

  $lines = @()
  for ($i = 0; $i -lt $FixturePaths.Count; $i++) {
    $suffix = if ($i -lt ($FixturePaths.Count - 1)) { "," } else { "" }
    $lines += ($Indent + (Format-PowerShellLiteral $FixturePaths[$i]) + $suffix)
  }
  return $lines
}

function Show-FixtureSelectionSummary {
  param(
    [string[]]$FixturePaths,
    [string]$RepoRoot
  )

  if (-not $FixturePaths -or -not $FixturePaths.Count) {
    Write-Output "No attached or saved HTML fixtures were found."
    return
  }

  Write-Output "Selected fixtures:"
  foreach ($fixture in $FixturePaths) {
    Write-Output ("- " + (Convert-ToDisplayPath -Path $fixture -RepoRoot $RepoRoot))
  }
}

function Wait-ValidationPause([switch]$Wait) {
  if ($Wait) {
    [void](Read-Host "Validation command finished. Press Enter to continue")
  }
}
