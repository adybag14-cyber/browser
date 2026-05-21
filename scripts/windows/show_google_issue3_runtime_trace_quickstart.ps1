[CmdletBinding()]
param(
    [string]$RepoRoot = "",
    [string]$BrowserExe = "",
    [string]$SummaryPath = "",
    [string]$ProfileRoot = "",
    [string]$TraceRoot = "",
    [string]$MailboxPath = "",
    [string]$Url = "https://www.google.com/",
    [int]$WaitMs = 30000,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StartPath
    )

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor "build.zig")) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            throw "Could not resolve the Lightpanda repo root from $StartPath. Pass -RepoRoot to override."
        }
        $cursor = $parent
    }
}

function Quote-PS {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Write-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Host ""
    Write-Host $Title
    Write-Host ("=" * $Title.Length)
}

function Write-CommandBlock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [Parameter(Mandatory = $true)]
        [string[]]$Commands,
        [string[]]$Notes = @()
    )

    Write-Host ""
    Write-Host ("[{0}]" -f $Title)
    foreach ($command in $Commands) {
        Write-Host ("  {0}" -f $command)
    }
    foreach ($note in $Notes) {
        Write-Host ("  note: {0}" -f $note)
    }
}

if (-not $RepoRoot) {
    $RepoRoot = Resolve-RepoRoot -StartPath $PSScriptRoot
}

$defaultBrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
if (-not $BrowserExe) {
    $BrowserExe = $defaultBrowserExe
}

if (-not $ProfileRoot) {
    $ProfileRoot = Join-Path $RepoRoot "tmp-browser-smoke\google-investigation-next\profile"
}

if (-not $TraceRoot) {
    $TraceRoot = Join-Path $RepoRoot "tmp-browser-smoke\google-investigation-next"
}

if (-not $MailboxPath) {
    $MailboxPath = Join-Path $TraceRoot "input-mailbox.txt"
}

$cleanCommands = @(
    "Remove-Item -Recurse -Force " + (Quote-PS -Value $TraceRoot) + " -ErrorAction SilentlyContinue",
    "New-Item -ItemType Directory -Force -Path " + (Quote-PS -Value $TraceRoot) + " | Out-Null",
    "New-Item -ItemType Directory -Force -Path " + (Quote-PS -Value $ProfileRoot) + " | Out-Null"
)

$buildCommand = "zig build -Dtarget=x86_64-windows-msvc --summary all"
$browseCommand = "& " + (Quote-PS -Value $BrowserExe) + " browse --browser_mode headed --window_width 1366 --window_height 900 --user_data_dir " + (Quote-PS -Value $ProfileRoot) + " --http_timeout $WaitMs " + (Quote-PS -Value $Url)
$mailboxPrepCommand = "@('text|lightpanda issue3','key|13|1|0','key|13|0|0') | Set-Content -Encoding ascii " + (Quote-PS -Value $MailboxPath)
$mailboxBrowseCommand = '$env:LIGHTPANDA_WIN32_INPUT = ' + (Quote-PS -Value $MailboxPath) + '; ' +
    "& " + (Quote-PS -Value $BrowserExe) + " browse --browser_mode headed --window_width 1366 --window_height 900 --user_data_dir " + (Quote-PS -Value $ProfileRoot) + " --http_timeout $WaitMs " + (Quote-PS -Value $Url)
$traceListCommand = "Get-ChildItem -Force " + (Quote-PS -Value $TraceRoot)
$traceTailCommand = "Get-ChildItem " + (Quote-PS -Value $TraceRoot) + " | Sort-Object Name | ForEach-Object { ""`n### $($_.Name)""; Get-Content $_.FullName }"

$traceFiles = @(
    "session-wait.log",
    "browse-render.log",
    "runtime-renderer.log",
    "runtime-input-backend-<pid>.log",
    "wndproc-input-<pid>.log"
)

$notes = @(
    "Use the live browse command first to reproduce issue #3 with a disposable profile and a stable window size.",
    "The runtime writes Google-specific traces under tmp-browser-smoke\google-investigation-next when the target URL contains google.com or a google-home- probe name.",
    "Use the mailbox variant after a live failure when you want to compare native typing against deterministic queued text and Enter input.",
    "The mailbox file format accepts lines like text|hello, key|13|1|0, and key|13|0|0."
)

$helper = [ordered]@{
    issue = "Google issue #3 runtime trace quickstart"
    purpose = "Print the smallest Windows command ladder for reproducing the headed Google input failure and collecting the built-in trace files."
    repo_root = $RepoRoot
    browser_exe = $BrowserExe
    summary_path = $SummaryPath
    profile_root = $ProfileRoot
    trace_root = $TraceRoot
    mailbox_path = $MailboxPath
    url = $Url
    wait_ms = $WaitMs
    trace_files = $traceFiles
    commands = [ordered]@{
        clean_trace_root = $cleanCommands
        build = $buildCommand
        browse_live_google = $browseCommand
        prepare_mailbox = $mailboxPrepCommand
        browse_with_mailbox = $mailboxBrowseCommand
        list_traces = $traceListCommand
        dump_traces = $traceTailCommand
    }
    notes = $notes
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 6
    return
}

Write-Section "Google issue #3 runtime trace quickstart"
Write-Host "Use this when the headed Google search box still focuses but typed text or Enter does not land reliably."
Write-Host ("Repo root : {0}" -f $RepoRoot)
Write-Host ("Browser   : {0}" -f $BrowserExe)
Write-Host ("Profile   : {0}" -f $ProfileRoot)
Write-Host ("Trace dir : {0}" -f $TraceRoot)
Write-Host ("Mailbox   : {0}" -f $MailboxPath)

Write-CommandBlock -Title "1. Reset trace state" -Commands $cleanCommands
Write-CommandBlock -Title "2. Build the headed binary" -Commands @($buildCommand)
Write-CommandBlock -Title "3. Reproduce the live Google failure" -Commands @($browseCommand) -Notes @(
    "Click the Google search box, type a short query, and press Enter before closing the window."
)
Write-CommandBlock -Title "4. Compare with deterministic mailbox input" -Commands @($mailboxPrepCommand, $mailboxBrowseCommand) -Notes @(
    "This uses LIGHTPANDA_WIN32_INPUT so the Win32 backend queues the same text and Enter sequence from a file."
)
Write-CommandBlock -Title "5. Inspect the captured traces" -Commands @($traceListCommand, $traceTailCommand) -Notes @(
    "Expected trace files: " + ($traceFiles -join ", ")
)

Write-Section "Notes"
foreach ($note in $notes) {
    Write-Host ("- {0}" -f $note)
}