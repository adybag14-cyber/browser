#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_google_clickfocus_trace_replay_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--browser-exe /path/to/lightpanda.exe] \
    [--input-path /path/to/attached-html-or-folder] \
    [--preferred-initial-page relative/or/absolute/page.html] \
    [--json]

Print the compact Linux-or-WSL-to-Windows replay route for the issue #3
click-focus Google path after the shared click-first checkpoint and the attached
HTML target-bundle route are the next honest gates before a fresh live-Google
trace replay.
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
INPUT_PATH=""
PREFERRED_INITIAL_PAGE=""
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
        --input-path)
            INPUT_PATH="$2"
            shift 2
            ;;
        --preferred-initial-page)
            PREFERRED_INITIAL_PAGE="$2"
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

VALIDATION_ROUTER_SCRIPT='.\\scripts\\windows\\show_headed_validation_suites.ps1'
WINDOWS_HANDOFF_SCRIPT='scripts/linux/show_issue3_windows_runtime_handoff_route.sh'
CLICK_FIRST_CHECKPOINT_SCRIPT='.\\tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1'
LIVE_GOOGLE_URL='https://www.google.com/'
TRACE_RUNTIME_PATTERN='tmp-browser-smoke/google-investigation-next/runtime-input-backend-<pid>.log'
TRACE_WNDPROC_PATTERN='tmp-browser-smoke/google-investigation-next/wndproc-input-<pid>.log'

ATTACHED_BUNDLE_COMMAND="powershell -ExecutionPolicy Bypass -File ${VALIDATION_ROUTER_SCRIPT} -ChangeArea attached-html-target-bundle"
if [[ -n "${BROWSER_EXE}" ]]; then
    ATTACHED_BUNDLE_COMMAND+=" -BrowserExe $(format_shell_arg "${BROWSER_EXE}")"
fi
if [[ -n "${INPUT_PATH}" ]]; then
    ATTACHED_BUNDLE_COMMAND+=" -InputPath $(format_shell_arg "${INPUT_PATH}")"
fi
if [[ -n "${PREFERRED_INITIAL_PAGE}" ]]; then
    ATTACHED_BUNDLE_COMMAND+=" -PreferredInitialPage $(format_shell_arg "${PREFERRED_INITIAL_PAGE}")"
fi

CLICK_FIRST_CHECKPOINT_COMMAND="powershell -ExecutionPolicy Bypass -File ${CLICK_FIRST_CHECKPOINT_SCRIPT} -GoogleEnterOrder -ClickFocus"
if [[ -n "${BROWSER_EXE}" ]]; then
    CLICK_FIRST_CHECKPOINT_COMMAND+=" -BrowserExe $(format_shell_arg "${BROWSER_EXE}")"
fi

WINDOWS_HANDOFF_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/${WINDOWS_HANDOFF_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --browser-exe $(format_shell_arg "${BROWSER_EXE}")"
LIVE_GOOGLE_COMMAND="$(format_shell_arg "${BROWSER_EXE}") browse --headed --window_width 1366 --window_height 900 $(format_shell_arg "${LIVE_GOOGLE_URL}")"

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Google issue #3 click-focus trace replay")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "browser_exe": %s,\n' "$(json_escape "${BROWSER_EXE}")"
    printf '  "input_path": %s,\n' "$(json_escape "${INPUT_PATH}")"
    printf '  "preferred_initial_page": %s,\n' "$(json_escape "${PREFERRED_INITIAL_PAGE}")"
    printf '  "read_first": [\n'
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md")"
    printf '    %s,\n' "$(json_escape "docs/WINDOWS_FULL_USE.md")"
    printf '    %s\n' "$(json_escape "scripts/linux/show_issue3_windows_runtime_handoff_route.sh")"
    printf '  ],\n'
    printf '  "commands": {\n'
    printf '    "click_first_checkpoint": %s,\n' "$(json_escape "${CLICK_FIRST_CHECKPOINT_COMMAND}")"
    printf '    "attached_html_target_bundle": %s,\n' "$(json_escape "${ATTACHED_BUNDLE_COMMAND}")"
    printf '    "live_google": %s,\n' "$(json_escape "${LIVE_GOOGLE_COMMAND}")"
    printf '    "windows_runtime_handoff": %s\n' "$(json_escape "${WINDOWS_HANDOFF_COMMAND}")"
    printf '  },\n'
    printf '  "trace_patterns": [\n'
    printf '    %s,\n' "$(json_escape "${TRACE_RUNTIME_PATTERN}")"
    printf '    %s\n' "$(json_escape "${TRACE_WNDPROC_PATTERN}")"
    printf '  ],\n'
    printf '  "notes": [\n'
    printf '    %s,\n' "$(json_escape "Run the click_first_checkpoint command first so the shared click-first Enter-order rung is green before the route widens into attached HTML or live Google.")"
    printf '    %s,\n' "$(json_escape "Run the attached_html_target_bundle command second so the pinned attached-page compatibility bundle is green before you trust a fresh live-Google trace replay.")"
    printf '    %s,\n' "$(json_escape "Use input_path when the attached bundle should stay pinned to a specific saved HTML page or folder during replay.")"
    printf '    %s,\n' "$(json_escape "Use preferred_initial_page when the same first page should stay pinned across the attached bundle route.")"
    printf '    %s,\n' "$(json_escape "Treat the trace_patterns as stale until the current live Google replay rewrites them.")"
    printf '    %s,\n' "$(json_escape "If either earlier gate still fails, reopen windows_runtime_handoff instead of jumping straight back to live Google.")"
    printf '    %s\n' "$(json_escape "Treat live_google as the last step in this route, not the first one.")"
    printf '  ]\n'
    printf '}\n'
    exit 0
fi

cat <<EOF
Google issue #3 click-focus trace replay

Repo root:   ${REPO_ROOT}
Browser exe: ${BROWSER_EXE}

Read first
==========
  docs/ISSUE3_GOOGLE_CLICKFOCUS_TRACE_REPLAY.md
  docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
  docs/WINDOWS_FULL_USE.md
  scripts/linux/show_issue3_windows_runtime_handoff_route.sh

Suggested route
===============
  Shared click-first checkpoint:
    ${CLICK_FIRST_CHECKPOINT_COMMAND}

  Attached HTML target-bundle route:
    ${ATTACHED_BUNDLE_COMMAND}

  Fresh live Google replay:
    ${LIVE_GOOGLE_COMMAND}

  Broader Windows runtime handoff if either earlier gate still fails:
    ${WINDOWS_HANDOFF_COMMAND}

Trace files to inspect after the fresh live replay
==================================================
  ${TRACE_RUNTIME_PATTERN}
  ${TRACE_WNDPROC_PATTERN}

Working rules
=============
  - Run the shared click-first checkpoint first so the last reusable Enter-order rung is green before the route widens.
  - Run the attached HTML target-bundle route second so the pinned compatibility bundle is green before you trust a fresh live-Google trace replay.
  - Use --input-path when the attached bundle should stay pinned to a specific saved HTML page or folder during replay.
  - Use --preferred-initial-page when the same first page should stay pinned across the attached bundle route.
  - Treat the trace files as stale until the current live Google replay rewrites them.
  - If either earlier gate still fails, reopen the broader Windows runtime handoff instead of jumping straight back to live Google.
  - Treat the live Google replay as the last step in this route, not the first one.
EOF
