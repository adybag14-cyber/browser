Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

param(
    [string]$BinaryPath = ".\zig-out\bin\lightpanda.exe",
    [int]$LocalPort = 8123,
    [string]$RemoteHost = "example.com"
)

function New-ModeCase {
    param(
        [string]$Command,
        [string]$ExpectedMode,
        [string]$Reason,
        [string]$Status
    )

    [pscustomobject]@{
        Command = $Command
        ExpectedMode = $ExpectedMode
        Status = $Status
        Reason = $Reason
    }
}

function Write-Section {
    param(
        [string]$Title,
        [object[]]$Cases
    )

    Write-Host ""
    Write-Host $Title
    Write-Host ("-" * $Title.Length)
    $Cases | Format-Table -AutoSize
}

$localCases = @(
    (New-ModeCase "$BinaryPath attached-page.html" "browse" "bare local html file should open in the headed browser path" "expected"),
    (New-ModeCase "$BinaryPath attached-page.xhtml#focus-probe" "browse" "local xhtml with a fragment should stay on the local browse path" "expected"),
    (New-ModeCase "$BinaryPath user_files\attached-page.html" "browse" "relative Windows-style html path should stay local" "expected"),
    (New-ModeCase "$BinaryPath localhost:$LocalPort/attached-page.html" "browse" "scheme-less loopback host should still open in browse mode" "expected"),
    (New-ModeCase "$BinaryPath 127.0.0.1:$LocalPort/attached-page.html?case=1" "browse" "scheme-less IPv4 loopback target should still open in browse mode" "expected")
)

$remoteCases = @(
    (New-ModeCase "$BinaryPath $RemoteHost/attached-page.html" "fetch" "scheme-less remote html should keep the normal fetch fallback" "targeted gap"),
    (New-ModeCase "$BinaryPath $RemoteHost/attached-page.xhtml#focus-probe" "fetch" "scheme-less remote xhtml should keep the normal fetch fallback" "targeted gap"),
    (New-ModeCase "$BinaryPath https://$RemoteHost/attached-page.html" "fetch" "fully qualified remote html already keeps fetch without a browse hint" "expected")
)

$overrideCases = @(
    (New-ModeCase "$BinaryPath --headed $RemoteHost/attached-page.html" "browse" "explicit headed hint should continue to force browse" "expected"),
    (New-ModeCase "$BinaryPath browse https://$RemoteHost/attached-page.html" "browse" "explicit browse command should continue to force browse" "expected")
)

Write-Host "Lightpanda headed command-target inference matrix"
Write-Host ("Binary: {0}" -f $BinaryPath)
Write-Host ("Local loopback port: {0}" -f $LocalPort)
Write-Host ("Remote host sample: {0}" -f $RemoteHost)
Write-Host ""
Write-Host "Use this matrix when validating the remaining Config.zig command-target classification gap."
Write-Host "The targeted gap is that scheme-less remote HTML/XHTML targets still get treated like local browse targets."

Write-Section "Local and loopback targets that should browse" $localCases
Write-Section "Scheme-less remote targets that should fetch" $remoteCases
Write-Section "Explicit overrides that should stay browse" $overrideCases

Write-Host ""
Write-Host "Suggested follow-up:"
Write-Host "1. Run the sample commands on a Windows build after the Config.zig fix lands."
Write-Host "2. Confirm only loopback and local HTML/XHTML targets infer browse automatically."
Write-Host "3. Keep scheme-less remote HTML/XHTML on fetch unless browse is requested explicitly."
