#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_windows_runtime_handoff_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--browser-exe /path/to/lightpanda.exe] \
    [--json]

Print the compact Linux-or-WSL-to-Windows handoff surface for the blocked
issue #3 headed runtime lane after the saved-browser-snapshot, offline-inputs,
Rust, and Zig-line gates are already green.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
BROWSER_EXE="${LIGHTPANDA_BROWSER_EXE:-}"
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --browser-exe)
            BROWSER_EXE="$2"
            shift 2
            ;;
        --json)
            JSON=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

REPO_ROOT="$(cd "${REPO_ROOT}" && pwd)"
if [[ -z "${BROWSER_EXE}" ]]; then
    BROWSER_EXE="${REPO_ROOT}/zig-out/bin/lightpanda.exe"
fi

HANDOFF_SURFACE_SCRIPT_PATH="${REPO_ROOT}/scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh"
WINDOWS_SURFACE_SCRIPT='.\\scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1'
WINDOWS_ROUTE_SCRIPT='.\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1'
REDUCED_GOOGLE_PROBE_SCRIPT='.\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1'
REDUCED_GOOGLE_FIXTURE_URL='http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1'
LIVE_GOOGLE_URL='https://www.google.com/'
TRACE_RUNTIME_PATTERN='tmp-browser-smoke/google-investigation-next/runtime-input-backend-<pid>.log'
TRACE_WNDPROC_PATTERN='tmp-browser-smoke/google-investigation-next/wndproc-input-<pid>.log'

HANDOFF_SURFACE_COMMAND="bash $(format_shell_arg "${HANDOFF_SURFACE_SCRIPT_PATH}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
WINDOWS_SURFACE_COMMAND="powershell -ExecutionPolicy Bypass -File ${WINDOWS_SURFACE_SCRIPT}"
WINDOWS_ROUTE_COMMAND="powershell -ExecutionPolicy Bypass -File ${WINDOWS_ROUTE_SCRIPT}"
WINDOWS_BUILD_COMMAND='zig build -Dtarget=x86_64-windows-msvc --summary all'
REDUCED_GOOGLE_PROBE_COMMAND="powershell -ExecutionPolicy Bypass -File ${REDUCED_GOOGLE_PROBE_SCRIPT}"
REDUCED_GOOGLE_FIXTURE_COMMAND="$(format_shell_arg "${BROWSER_EXE}") browse --headed --window_width 1366 --window_height 900 $(format_shell_arg "${REDUCED_GOOGLE_FIXTURE_URL}")"
LIVE_GOOGLE_COMMAND="$(format_shell_arg "${BROWSER_EXE}") browse --headed --window_width 1366 --window_height 900 $(format_shell_arg "${LIVE_GOOGLE_URL}")"

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Google issue #3 Windows runtime handoff")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "browser_exe": %s,\n' "$(json_escape "${BROWSER_EXE}")"
    printf '  "read_first": [\n'
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md")"
    printf '    %s\n' "$(json_escape "docs/WINDOWS_FULL_USE.md")"
    printf '  ],\n'
    printf '  "commands": {\n'
    printf '    "handoff_surface": %s,\n' "$(json_escape "${HANDOFF_SURFACE_COMMAND}")"
    printf '    "windows_runtime_surface": %s,\n' "$(json_escape "${WINDOWS_SURFACE_COMMAND}")"
    printf '    "windows_runtime_route": %s,\n' "$(json_escape "${WINDOWS_ROUTE_COMMAND}")"
    printf '    "windows_build": %s,\n' "$(json_escape "${WINDOWS_BUILD_COMMAND}")"
    printf '    "reduced_google_probe": %s,\n' "$(json_escape "${REDUCED_GOOGLE_PROBE_COMMAND}")"
    printf '    "reduced_google_fixture": %s,\n' "$(json_escape "${REDUCED_GOOGLE_FIXTURE_COMMAND}")"
    printf '    "live_google": %s\n' "$(json_escape "${LIVE_GOOGLE_COMMAND}")"
    printf '  },\n'
    printf '  "trace_patterns": [\n'
    printf '    %s,\n' "$(json_escape "${TRACE_RUNTIME_PATTERN}")"
    printf '    %s\n' "$(json_escape "${TRACE_WNDPROC_PATTERN}")"
    printf '  ],\n'
    printf '  "notes": [\n'
    printf '    %s,\n' "$(json_escape "Use this handoff only after the Linux or WSL saved-snapshot, offline-inputs, Rust, and Zig-line gates are already green.")"
    printf '    %s,\n' "$(json_escape "Run handoff_surface first so missing docs, reduced probes, or nearby Windows helpers fail fast before the narrower replay ladder reopens.")"
    printf '    %s,\n' "$(json_escape "Run windows_runtime_surface next so missing PowerShell helpers still fail fast before the broader Windows route reopens.")"
    printf '    %s,\n' "$(json_escape "Run windows_runtime_route after the fail-fast checks when you want the fuller replay ladder and nearby-note guidance on one Windows surface.")"
    printf '    %s,\n' "$(json_escape "Use reduced_google_probe before the direct fixture or live Google when you want the quickest headed Win32 yes-or-no signal with the current runtime traces.")"
    printf '    %s,\n' "$(json_escape "Check the runtime and wndproc trace patterns after reduced or live Google runs when focus, text commit, or submit still drift.")"
    printf '    %s\n' "$(json_escape "Treat live Google as the last step in this handoff, not the first one.")"
    printf '  ]\n'
    printf '}\n'
    exit 0
fi

cat <<EOF
Google issue #3 Windows runtime handoff

Repo root:   ${REPO_ROOT}
Browser exe: ${BROWSER_EXE}

Read first
==========
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
  docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md
  docs/WINDOWS_FULL_USE.md

Suggested route
===============
  Linux or WSL handoff surface check:
    ${HANDOFF_SURFACE_COMMAND}

  Fail-fast Windows runtime surface check:
    ${WINDOWS_SURFACE_COMMAND}

  Broader Windows runtime route:
    ${WINDOWS_ROUTE_COMMAND}

  Windows build:
    ${WINDOWS_BUILD_COMMAND}

  Reduced Google probe:
    ${REDUCED_GOOGLE_PROBE_COMMAND}

  Reduced Google fixture:
    ${REDUCED_GOOGLE_FIXTURE_COMMAND}

  Live Google:
    ${LIVE_GOOGLE_COMMAND}

Trace files to inspect next
===========================
  ${TRACE_RUNTIME_PATTERN}
  ${TRACE_WNDPROC_PATTERN}

Working rules
=============
  - Use this handoff only after the Linux or WSL saved-snapshot, offline-inputs, Rust, and Zig-line gates are already green.
  - Run handoff_surface first so missing docs, reduced probes, or nearby Windows helpers fail fast before the narrower replay ladder reopens.
  - Run the Windows runtime surface check next so missing PowerShell helpers still fail fast before the broader Windows route reopens.
  - Run the broader Windows runtime route next when you want the fuller replay ladder and nearby-note guidance on one Windows surface.
  - Use the reduced Google probe before the direct fixture or live Google when you want the quickest headed Win32 yes-or-no signal with the current runtime traces.
  - Check the runtime and wndproc trace files after reduced or live Google runs when focus, text commit, or submit still drift.
  - Treat live Google as the last step in this handoff, not the first one.
EOF
