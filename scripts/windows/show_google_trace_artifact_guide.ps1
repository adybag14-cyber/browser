[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$TraceRoot,
    [int]$TailCount = 20,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot([string]$StartPath) {
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

function Convert-ToRepoRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $normalizedRepoRoot = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\\', '/')
    $normalizedPath = [System.IO.Path]::GetFullPath($Path)
    if ($normalizedPath.StartsWith($normalizedRepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $normalizedPath.Substring($normalizedRepoRoot.Length).TrimStart('\\', '/')
        if (-not [string]::IsNullOrWhiteSpace($relative)) {
            return $relative -replace '\\', '/'
        }
    }

    return $normalizedPath
}

function New-ArtifactRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Purpose,
        [Parameter(Mandatory = $true)]
        [int]$TailCount
    )

    $exists = Test-Path -LiteralPath $Path -PathType Leaf
    $tail = @()
    if ($exists -and $TailCount -gt 0) {
        $tail = @(Get-Content -LiteralPath $Path -Tail $TailCount)
    }

    [pscustomobject]@{
        relative_path = Convert-ToRepoRelativePath -RepoRoot $RepoRoot -Path $Path
        exists = [bool]$exists
        length = if ($exists) { (Get-Item -LiteralPath $Path).Length } else { 0 }
        purpose = $Purpose
        tail = $tail
    }
}

function Get-ArtifactGroup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [string]$TraceRoot,
        [Parameter(Mandatory = $true)]
        [int]$TailCount,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        [Parameter(Mandatory = $true)]
        [string]$Purpose
    )

    $records = @(
        Get-ChildItem -LiteralPath $TraceRoot -Filter $Pattern -File -ErrorAction SilentlyContinue |
            Sort-Object FullName |
            ForEach-Object {
                New-ArtifactRecord -RepoRoot $RepoRoot -Path $_.FullName -Purpose $Purpose -TailCount $TailCount
            }
    )

    [pscustomobject]@{
        name = $Name
        purpose = $Purpose
        count = @($records).Count
        artifacts = $records
    }
}

function Resolve-ArtifactFullPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        $Artifact
    )

    if ($Artifact.relative_path -is [string] -and [System.IO.Path]::IsPathRooted($Artifact.relative_path)) {
        return $Artifact.relative_path
    }

    return Join-Path $RepoRoot ($Artifact.relative_path -replace '/', '\\')
}

function Get-ActivationMarkerSummaries {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [object[]]$Groups
    )

    $markers = @(
        [pscustomobject]@{
            marker = "browse headed runtime"
            meaning = "Confirms the browse command stayed on the native headed runtime."
            expected_when = "The reduced-home or live Google probe really opened the native headed browser window."
        }
        [pscustomobject]@{
            marker = "browse headed fallback"
            meaning = "Shows the browse command dropped to the safe headless runtime instead of staying headed."
            expected_when = "A headed request did not keep the native window alive, so later input traces may not describe the intended surface."
        }
        [pscustomobject]@{
            marker = "serve headed runtime"
            meaning = "Confirms the server-side headed startup stayed on the native runtime."
            expected_when = "A headed serve session for the localhost replay path really kept the native surface active."
        }
        [pscustomobject]@{
            marker = "serve headed fallback"
            meaning = "Shows the server-side headed startup dropped to the safe headless runtime."
            expected_when = "A headed localhost replay session fell back before the later Google flow could be trusted as a native headed run."
        }
    )

    $artifacts = @(
        $Groups |
            ForEach-Object { @($_.artifacts) } |
            Where-Object { $_.exists }
    )

    return @(
        foreach ($marker in $markers) {
            $matchedArtifacts = @()
            foreach ($artifact in $artifacts) {
                $artifactPath = Resolve-ArtifactFullPath -RepoRoot $RepoRoot -Artifact $artifact
                $match = Select-String -LiteralPath $artifactPath -SimpleMatch -Pattern $marker.marker -List -ErrorAction SilentlyContinue
                if ($match) {
                    $matchedArtifacts += [pscustomobject]@{
                        relative_path = $artifact.relative_path
                        sample_line = $match.Line.Trim()
                    }
                }
            }

            [pscustomobject]@{
                marker = $marker.marker
                meaning = $marker.meaning
                expected_when = $marker.expected_when
                found = [bool]($matchedArtifacts.Count -gt 0)
                artifacts = @($matchedArtifacts | ForEach-Object { $_.relative_path })
                samples = @($matchedArtifacts)
            }
        }
    )
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-RepoRoot $PSScriptRoot
}

$resolvedTraceRoot = if ($TraceRoot) {
    (Resolve-Path -LiteralPath $TraceRoot).Path
} else {
    Join-Path $resolvedRepoRoot "tmp-browser-smoke\google-investigation-next"
}

if (-not (Test-Path -LiteralPath $resolvedTraceRoot -PathType Container)) {
    throw "Google trace artifact root not found: $resolvedTraceRoot"
}

$groups = @(
    [pscustomobject]@{
        name = "reduced-trace"
        purpose = "Reduced-home probe logs and screenshot from chrome-google-home-enter-trace-probe.ps1."
        count = 5
        artifacts = @(
            New-ArtifactRecord -RepoRoot $resolvedRepoRoot -Path (Join-Path $resolvedTraceRoot "chrome-google-home-enter-trace.browser.stdout.txt") -Purpose "Reduced-home headed browser stdout." -TailCount $TailCount
            New-ArtifactRecord -RepoRoot $resolvedRepoRoot -Path (Join-Path $resolvedTraceRoot "chrome-google-home-enter-trace.browser.stderr.txt") -Purpose "Reduced-home headed browser stderr." -TailCount $TailCount
            New-ArtifactRecord -RepoRoot $resolvedRepoRoot -Path (Join-Path $resolvedTraceRoot "chrome-google-home-enter-trace.server.stdout.txt") -Purpose "Reduced-home localhost server stdout." -TailCount $TailCount
            New-ArtifactRecord -RepoRoot $resolvedRepoRoot -Path (Join-Path $resolvedTraceRoot "chrome-google-home-enter-trace.server.stderr.txt") -Purpose "Reduced-home localhost server stderr and submit markers." -TailCount $TailCount
            New-ArtifactRecord -RepoRoot $resolvedRepoRoot -Path (Join-Path $resolvedTraceRoot "chrome-google-home-enter-trace.before.png") -Purpose "Reduced-home screenshot captured before the trace typing phase." -TailCount 0
        )
    }
    [pscustomobject]@{
        name = "live-trace"
        purpose = "Real Google homepage probe logs from chrome-google-home-input-probe.ps1."
        count = 2
        artifacts = @(
            New-ArtifactRecord -RepoRoot $resolvedRepoRoot -Path (Join-Path $resolvedTraceRoot "chrome-google-home-input.browser.stdout.txt") -Purpose "Live Google headed browser stdout." -TailCount $TailCount
            New-ArtifactRecord -RepoRoot $resolvedRepoRoot -Path (Join-Path $resolvedTraceRoot "chrome-google-home-input.browser.stderr.txt") -Purpose "Live Google headed browser stderr." -TailCount $TailCount
        )
    }
    (Get-ArtifactGroup -RepoRoot $resolvedRepoRoot -TraceRoot $resolvedTraceRoot -TailCount $TailCount -Name "browse-render" -Pattern "browse-render.log" -Purpose "Shared browse-render log written by the browser trace path.")
    (Get-ArtifactGroup -RepoRoot $resolvedRepoRoot -TraceRoot $resolvedTraceRoot -TailCount $TailCount -Name "runtime-renderer" -Pattern "runtime-renderer.log" -Purpose "Shared runtime-renderer log emitted during Google-focused rendering.")
    (Get-ArtifactGroup -RepoRoot $resolvedRepoRoot -TraceRoot $resolvedTraceRoot -TailCount $TailCount -Name "session-wait" -Pattern "session-wait.log" -Purpose "Session wait trace captured while Google-related page readiness is polled.")
    (Get-ArtifactGroup -RepoRoot $resolvedRepoRoot -TraceRoot $resolvedTraceRoot -TailCount $TailCount -Name "runtime-input" -Pattern "runtime-input-backend-*.log" -Purpose "Per-window backend input trace logs from the headed Win32 runtime.")
    (Get-ArtifactGroup -RepoRoot $resolvedRepoRoot -TraceRoot $resolvedTraceRoot -TailCount $TailCount -Name "wndproc-input" -Pattern "wndproc-input-*.log" -Purpose "Per-window Win32 wndproc trace logs for Google-focused input handling.")
)

$missingCount = @(
    $groups |
        ForEach-Object { @($_.artifacts) } |
        Where-Object { -not $_.exists }
).Count

$activationMarkers = Get-ActivationMarkerSummaries -RepoRoot $resolvedRepoRoot -Groups $groups
$activationOverview = [pscustomobject]@{
    headed_runtime_markers_found = @($activationMarkers | Where-Object { $_.marker -like '* headed runtime' -and $_.found }).Count
    fallback_markers_found = @($activationMarkers | Where-Object { $_.marker -like '* headed fallback' -and $_.found }).Count
    total_markers_found = @($activationMarkers | Where-Object { $_.found }).Count
}

$guide = [pscustomobject]@{
    issue = "Google live trace artifact guide"
    repo_root = $resolvedRepoRoot
    trace_root = $resolvedTraceRoot
    tail_count = $TailCount
    missing_count = $missingCount
    activation_overview = $activationOverview
    activation_markers = $activationMarkers
    groups = $groups
    next_steps = @(
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_trace_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_timing_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1",
        "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"
    )
    notes = @(
        "Check the activation markers first so a headed fallback is visible before you spend time narrowing Google input behavior.",
        "Compare the reduced-home and live-trace outputs before assuming the real Google homepage divergence belongs in the Win32 engine path.",
        "Use the submit-timing and shared Enter-order helpers when the trace logs stop matching the closest bounded localhost checkpoints.",
        "Use the attached-html helper when the next question is whether saved or attached Google-like localhost pages diverge earlier than the live homepage path."
    )
}

if ($Json) {
    $guide | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host "Google live trace artifact guide"
Write-Host ""
Write-Host ("Repo root: {0}" -f $guide.repo_root)
Write-Host ("Trace root: {0}" -f $guide.trace_root)
Write-Host ("Missing artifact count: {0}" -f $guide.missing_count)
Write-Host ("Activation summary: {0} runtime marker(s), {1} fallback marker(s)" -f $guide.activation_overview.headed_runtime_markers_found, $guide.activation_overview.fallback_markers_found)
Write-Host ""

foreach ($group in $guide.groups) {
    Write-Host ("[{0}] {1}" -f $group.name, $group.purpose)
    foreach ($artifact in @($group.artifacts)) {
        $status = if ($artifact.exists) { "PASS" } else { "MISS" }
        Write-Host ("  [{0}] {1}" -f $status, $artifact.relative_path)
        Write-Host ("    {0}" -f $artifact.purpose)
        if ($artifact.exists -and $artifact.tail.Count -gt 0) {
            foreach ($line in $artifact.tail) {
                Write-Host ("      {0}" -f $line)
            }
        }
    }
    Write-Host ""
}

Write-Host "Activation markers:"
foreach ($marker in $guide.activation_markers) {
    $status = if ($marker.found) { "PASS" } else { "MISS" }
    Write-Host ("[{0}] {1}" -f $status, $marker.marker)
    Write-Host ("  {0}" -f $marker.meaning)
    Write-Host ("  Expected when: {0}" -f $marker.expected_when)
    foreach ($sample in @($marker.samples)) {
        Write-Host ("    {0}" -f $sample.relative_path)
        Write-Host ("      {0}" -f $sample.sample_line)
    }
    Write-Host ""
}

Write-Host "Next steps:"
foreach ($step in $guide.next_steps) {
    Write-Host ("- {0}" -f $step)
}
Write-Host ""
Write-Host "Notes:"
foreach ($note in $guide.notes) {
    Write-Host ("- {0}" -f $note)
}
