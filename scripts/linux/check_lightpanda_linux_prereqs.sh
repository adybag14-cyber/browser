#!/usr/bin/env bash

set -euo pipefail

overall_ok=0

zig_bin=""

write_status() {
    local name="$1"
    local ok="$2"
    local details="$3"
    local mark="FAIL"
    if [[ "$ok" == "true" ]]; then
        mark="PASS"
    fi
    printf '[%s] %s - %s\n' "$mark" "$name" "$details"
}

check_command() {
    local name="$1"
    local details
    if command -v "$name" >/dev/null 2>&1; then
        details="$("$name" --version 2>/dev/null | head -n 1 || true)"
        if [[ -z "$details" ]]; then
            details="available in PATH"
        fi
        write_status "$name" true "$details"
        return 0
    fi

    write_status "$name" false "not found in PATH"
    overall_ok=1
    return 1
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

if [[ -n "${ZIG:-}" && -x "${ZIG}" ]]; then
    zig_bin="${ZIG}"
elif command -v zig >/dev/null 2>&1; then
    zig_bin="$(command -v zig)"
elif [[ -x "$repo_root/zig/zig" ]]; then
    zig_bin="$repo_root/zig/zig"
elif [[ -x "$repo_root/toolchains/zig/zig" ]]; then
    zig_bin="$repo_root/toolchains/zig/zig"
fi

if [[ "$(uname -s)" == "Linux" ]]; then
    write_status "Platform" true "Linux host detected"
else
    write_status "Platform" false "expected Linux host"
    overall_ok=1
fi

check_command python3 || true

if [[ -n "$zig_bin" ]]; then
    zig_details="$("$zig_bin" version 2>/dev/null | head -n 1 || true)"
    if [[ -z "$zig_details" ]]; then
        zig_details="available at $zig_bin"
    else
        zig_details="zig $zig_details ($zig_bin)"
    fi
    write_status "zig" true "$zig_details"
else
    write_status "zig" false "not found in PATH, \$ZIG, ./zig/zig, or ./toolchains/zig/zig"
    overall_ok=1
fi

if [[ -d "$repo_root/tmp-browser-smoke" ]]; then
    write_status "SmokeAssets" true "tmp-browser-smoke directory present"
else
    write_status "SmokeAssets" false "tmp-browser-smoke directory missing"
    overall_ok=1
fi

if [[ -f "$repo_root/docs/WINDOWS_FULL_USE.md" ]]; then
    write_status "WindowsRunbook" true "docs/WINDOWS_FULL_USE.md present"
else
    write_status "WindowsRunbook" false "docs/WINDOWS_FULL_USE.md missing"
    overall_ok=1
fi

if [[ -f "$repo_root/docs/LINUX_LOCALHOST_VALIDATION.md" ]]; then
    write_status "LinuxRunbook" true "docs/LINUX_LOCALHOST_VALIDATION.md present"
else
    write_status "LinuxRunbook" false "docs/LINUX_LOCALHOST_VALIDATION.md missing"
    overall_ok=1
fi

zig_probe_cache="$repo_root/.zig-cache-linux-prereq-probe"
zig_probe_global_cache="$repo_root/.zig-global-cache-linux-prereq-probe"

if [[ -n "$zig_bin" ]]; then
    if "$zig_bin" build --help --cache-dir "$zig_probe_cache" --global-cache-dir "$zig_probe_global_cache" >/dev/null 2>&1; then
        write_status "ZigHelpProbe" true "zig build --help completed with isolated caches"
    else
        write_status "ZigHelpProbe" false "zig build --help failed; check docs/LINUX_LOCALHOST_VALIDATION.md"
        overall_ok=1
    fi
fi

printf '\n'
if [[ "$overall_ok" -eq 0 ]]; then
    printf 'Linux prerequisites look good for local restore and localhost validation.\n'
    printf 'Use docs/LINUX_LOCALHOST_VALIDATION.md for the next build and probe steps.\n'
    exit 0
fi

printf 'One or more prerequisite checks failed.\n'
printf 'See docs/LINUX_LOCALHOST_VALIDATION.md for remediation and validation steps.\n'
exit 1
