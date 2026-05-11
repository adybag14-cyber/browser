[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$ProbeJsonPath,
  [string]$InputText = "n",
  [int]$Port = 9582,
  [int]$TimeoutSeconds = 90,
  [int]$PollMilliseconds = 250,
  [string]$OutputPath
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

function Get-StateField($State, [string]$Name) {
  if ($null -eq $State) {
    return $null
  }

  $property = $State.PSObject.Properties[$Name]
  if ($null -eq $property) {
    return $null
  }

  return $property.Value
}

function Convert-ToDateTimeOffset([string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) {
    return $null
  }
  return [DateTimeOffset]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture)
}

function Test-ObservedBefore([string]$Left, [string]$Right) {
  $leftTime = Convert-ToDateTimeOffset $Left
  $rightTime = Convert-ToDateTimeOffset $Right
  if ($null -eq $leftTime -or $null -eq $rightTime) {
    return $null
  }
  return $leftTime -le $rightTime
}

function Get-Classification($Probe, [string]$ExpectedInput) {
  if ($Probe.helper_outcome -ne "completed") {
    switch ([string]$Probe.helper_failure_stage) {
      "ready_marker" { return "title_probe_ready_missing" }
      "typed_marker" { return "title_probe_typed_missing" }
      "enter_marker" { return "title_probe_submit_missing" }
      "process_exit" { return "title_probe_process_exit" }
      default { return "title_probe_failed" }
    }
  }

  $typedValue = Get-StateField $Probe.helper_typed_title_state "query_value"
  $enterValue = Get-StateField $Probe.helper_enter_title_state "query_value"
  $lastValue = Get-StateField $Probe.helper_last_title_state "query_value"

  if (-not [string]::IsNullOrWhiteSpace($ExpectedInput) -and $typedValue -and $typedValue -ne $ExpectedInput) {
    return "title_probe_typed_value_mismatch"
  }
  if ($typedValue -and -not $enterValue) {
    return "title_probe_value_dropped_before_submit"
  }
  if (-not [string]::IsNullOrWhiteSpace($ExpectedInput) -and $enterValue -and $enterValue -ne $ExpectedInput) {
    return "title_probe_submit_value_mismatch"
  }
  if (-not [string]::IsNullOrWhiteSpace($ExpectedInput) -and $lastValue -and $lastValue -ne $ExpectedInput) {
    return "title_probe_last_value_mismatch"
  }

  return "title_probe_sequence_complete"
}

function Get-Recommendation([string]$Classification) {
  switch ($Classification) {
    "title_probe_ready_missing" { return "Stay on the title probe and inspect readiness, focus, and raw trace artifacts before widening to later submit-path helpers." }
    "title_probe_typed_missing" { return "Stay on the title probe and inspect native text delivery plus the raw input traces before reopening Enter sequencing." }
    "title_probe_submit_missing" { return "Use the title probe output as the quick narrowing point, then reopen the reduced Enter analysis to compare keydown, keypress, and submit ordering." }
    "title_probe_process_exit" { return "Check headed browser lifetime and raw backend traces before trusting any later interaction diagnosis." }
    "title_probe_typed_value_mismatch" { return "Inspect how the title probe field state differs from the expected input before moving to broader Google-path replay." }
    "title_probe_value_dropped_before_submit" { return "Compare the title-probe submit stage with the reduced Enter analysis to find where the query value disappears." }
    "title_probe_submit_value_mismatch" { return "Focus on Enter-side mutation or stale state before reopening the broader Google submit ladder." }
    "title_probe_last_value_mismatch" { return "Inspect the final title-probe tail state and trace summaries before widening back out." }
    default { return "The title probe looks coherent; move to the reduced Enter analysis or the broader issue #3 replay chain next." }
  }
}

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-RepoRoot $PSScriptRoot }
$probeRoot = Join-Path $repo "tmp-browser-smoke\google-investigation-next"
$probeScript = Join-Path $probeRoot "chrome-google-home-title-probe.ps1"

$probeJson = $null
if ($ProbeJsonPath) {
  if (-not (Test-Path -LiteralPath $ProbeJsonPath)) {
    throw "Title probe JSON file not found: $ProbeJsonPath"
  }
  $probeJson = Get-Content -LiteralPath $ProbeJsonPath -Raw
} else {
  if (-not (Test-Path -LiteralPath $probeScript)) {
    throw "Google title probe script not found: $probeScript"
  }

  $probeArgs = @{
    RepoRoot = $repo
    InputText = $InputText
    Port = $Port
    TimeoutSeconds = $TimeoutSeconds
    PollMilliseconds = $PollMilliseconds
  }
  if ($BrowserExe) {
    $probeArgs.BrowserExe = $BrowserExe
  }

  $probeJson = & $probeScript @probeArgs
}

if ([string]::IsNullOrWhiteSpace($probeJson)) {
  throw "Google title probe did not return JSON output."
}

$probe = $probeJson | ConvertFrom-Json
$analysisInputText = if ($probe.input_text) { [string]$probe.input_text } else { $InputText }
$typedValue = Get-StateField $probe.helper_typed_title_state "query_value"
$enterValue = Get-StateField $probe.helper_enter_title_state "query_value"
$lastValue = Get-StateField $probe.helper_last_title_state "query_value"
$classification = Get-Classification $probe $analysisInputText

$analysis = [pscustomobject]@{
  probe_url = $probe.probe_url
  input_text = $analysisInputText
  helper_outcome = $probe.helper_outcome
  helper_exit_code = $probe.helper_exit_code
  helper_failure = $probe.helper_failure
  failure_stage = $probe.helper_failure_stage
  classification = $classification
  recommendation = Get-Recommendation $classification
  ready_marker = $probe.helper_matched_ready_marker
  ready_observed_at_utc = $probe.helper_ready_observed_at_utc
  typed_observed_at_utc = $probe.helper_typed_observed_at_utc
  enter_observed_at_utc = $probe.helper_enter_observed_at_utc
  input_sent_at_utc = $probe.helper_input_sent_at_utc
  enter_sent_at_utc = $probe.helper_enter_sent_at_utc
  typed_before_enter = Test-ObservedBefore $probe.helper_typed_observed_at_utc $probe.helper_enter_observed_at_utc
  input_before_enter = Test-ObservedBefore $probe.helper_input_sent_at_utc $probe.helper_enter_sent_at_utc
  typed_marker = $probe.helper_typed_marker
  enter_marker = $probe.helper_enter_marker
  last_marker = $probe.helper_last_marker
  ready_active_element = $probe.helper_ready_active_element
  typed_active_element = $probe.helper_typed_active_element
  enter_active_element = $probe.helper_enter_active_element
  last_active_element = $probe.helper_last_active_element
  typed_query_value = $typedValue
  enter_query_value = $enterValue
  last_query_value = $lastValue
  typed_value_matches_input = if ($typedValue) { $typedValue -eq $analysisInputText } else { $null }
  enter_value_matches_input = if ($enterValue) { $enterValue -eq $analysisInputText } else { $null }
  last_value_matches_input = if ($lastValue) { $lastValue -eq $analysisInputText } else { $null }
  helper_trace_path = $probe.helper_trace_path
  helper_trace_count = $probe.helper_trace_count
  helper_trace_tail = $probe.helper_trace_tail
  helper_trace_tail_markers = $probe.helper_trace_tail_markers
  helper_trace_tail_query_values = $probe.helper_trace_tail_query_values
  browse_trace = $probe.browse_trace
  renderer_trace = $probe.renderer_trace
  session_trace = $probe.session_trace
  trace_artifacts = $probe.trace_artifacts
  backend_trace_files = $probe.backend_trace_files
  wndproc_trace_files = $probe.wndproc_trace_files
  server_stdout = $probe.server_stdout
  server_stderr = $probe.server_stderr
  raw_probe = $probe
}

$json = $analysis | ConvertTo-Json -Depth 8
if ($OutputPath) {
  $json | Set-Content -LiteralPath $OutputPath -Encoding Ascii
}

$json
