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
    return $fullPath.Substring($fullRoot.Length).TrimStart("\\", "/")
  }
  return $fullPath
}

function Format-PowerShellLiteral([string]$Value) {
  return "'" + $Value.Replace("'", "''") + "'"
}

function Get-AttachedHtmlSearchRoots([string]$RepoRoot) {
  $roots = New-Object System.Collections.Generic.List[string]
  $roots.Add((Join-Path $RepoRoot "user_files"))
  $roots.Add((Join-Path $RepoRoot "agent_files"))

  $repoParent = Split-Path $RepoRoot -Parent
  if (-not [string]::IsNullOrWhiteSpace($repoParent) -and $repoParent -ne $RepoRoot) {
    $roots.Add((Join-Path $repoParent "user_files"))
    $roots.Add((Join-Path $repoParent "agent_files"))
  }

  $currentRoot = (Get-Location).Path
  if (-not [string]::IsNullOrWhiteSpace($currentRoot)) {
    $roots.Add((Join-Path $currentRoot "user_files"))
    $roots.Add((Join-Path $currentRoot "agent_files"))
  }

  return @(
    $roots |
      Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
      Select-Object -Unique
  )
}

function Get-AttachedHtmlCandidates([string]$RepoRoot) {
  $roots = Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot
  $items = @()
  foreach ($root in $roots) {
    $items += Get-ChildItem -LiteralPath $root -Recurse -File |
      Where-Object { $_.Extension -in @(".html", ".htm") } |
      Sort-Object FullName
  }

  return @($items | Group-Object FullName | ForEach-Object { $_.Group[0] })
}

function Get-GoogleStyleFixtureScore($Fixture) {
  $score = 0
  $pathText = $Fixture.FullName.ToLowerInvariant()

  if ($pathText -match 'google[-_ ]?(home|search|input|query|submit|probe)') {
    $score += 6
  } elseif ($pathText -match 'search[-_ ]?(home|input|query|submit|probe|results)') {
    $score += 4
  } elseif ($pathText -match 'google') {
    $score += 1
  }

  if ($pathText -match '(safety|privacy|policy|account|support)') {
    $score -= 4
  }

  try {
    $raw = Get-Content -LiteralPath $Fixture.FullName -Raw -ErrorAction Stop
    $rawLower = $raw.ToLowerInvariant()

    if ($rawLower -match "<title[^>]*>[^<]*google[^<]*(search|home)") {
      $score += 6
    } elseif ($rawLower -match "<title[^>]*>[^<]*google[^<]*") {
      $score += 2
    }

    if ($rawLower -match "name\s*=\s*['\"]q['\"]") {
      $score += 7
    }
    if ($rawLower -match "aria-label\s*=\s*['\"][^'\"]*search[^'\"]*['\"]") {
      $score += 4
    }
    if ($rawLower -match "<form[^>]+action\s*=\s*['\"][^'\"]*/search" -or
        $rawLower -match "\b(btnk|apjfqb|glfyf|gsfi)\b") {
      $score += 6
    }

    if ($rawLower -match '(google safety|safety centre|privacy)') {
      $score -= 6
    }
  } catch {
    return $score
  }

  return $score
}

function Test-GoogleStyleFixture($Fixture) {
  return (Get-GoogleStyleFixtureScore $Fixture) -gt 2
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
    $fixtures = @(
      $fixtures |
        Sort-Object @(
          @{ Expression = { Get-GoogleStyleFixtureScore $_ }; Descending = $true },
          @{ Expression = { $_.FullName } }
        )
    )
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
