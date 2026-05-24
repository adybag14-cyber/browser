#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_attached_pages_launcher_companion_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--input /path/to/saved-page-or-folder] \
    [--preferred-initial-page "page.html"] \
    [--summary-path /path/to/summary.json] \
    [--browser-exe /path/to/lightpanda.exe] \
    [--json]

Print the compact Linux-or-WSL attached-pages launcher-companion route for the
blocked issue #3 replay lane before the run hands back to the Windows replay
helpers.
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

format_powershell_arg() {
    python3 - "$1" <<'PY'
import sys

print("'" + sys.argv[1].replace("'", "''") + "'")
PY
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
BROWSER_EXE="${LIGHTPANDA_BROWSER_EXE:-}"
SUMMARY_PATH=""
PREFERRED_INITIAL_PAGE=""
JSON=0
INPUT_PATHS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --input)
            INPUT_PATHS+=("$2")
            shift 2
            ;;
        --preferred-initial-page)
            PREFERRED_INITIAL_PAGE="$2"
            shift 2
            ;;
        --summary-path)
            SUMMARY_PATH="$2"
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

format_shell_input_args() {
    local result=""
    local path
    for path in "${INPUT_PATHS[@]}"; do
        result+=" --input $(format_shell_arg "${path}")"
    done
    printf '%s' "${result}"
}

format_powershell_input_args() {
    local result=""
    local path
    for path in "${INPUT_PATHS[@]}"; do
        result+=" -InputPath $(format_powershell_arg "${path}")"
    done
    printf '%s' "${result}"
}

INPUT_ARGS="$(format_shell_input_args)"
POWERSHELL_INPUT_ARGS="$(format_powershell_input_args)"
PREFERRED_ARG=""
SUMMARY_ARG=""
BROWSER_ARG=""
POWERSHELL_PREFERRED_ARG=""
POWERSHELL_SUMMARY_ARG=""
POWERSHELL_BROWSER_ARG=""
if [[ -n "${PREFERRED_INITIAL_PAGE}" ]]; then
    PREFERRED_ARG=" --preferred-initial-page $(format_shell_arg "${PREFERRED_INITIAL_PAGE}")"
    POWERSHELL_PREFERRED_ARG=" -PreferredInitialPage $(format_powershell_arg "${PREFERRED_INITIAL_PAGE}")"
fi
if [[ -n "${SUMMARY_PATH}" ]]; then
    SUMMARY_ARG=" --summary-path $(format_shell_arg "${SUMMARY_PATH}")"
    POWERSHELL_SUMMARY_ARG=" -SummaryPath $(format_powershell_arg "${SUMMARY_PATH}")"
fi
if [[ -n "${BROWSER_EXE}" ]]; then
    BROWSER_ARG=" --browser-exe $(format_shell_arg "${BROWSER_EXE}")"
    POWERSHELL_BROWSER_ARG=" -BrowserExe $(format_powershell_arg "${BROWSER_EXE}")"
fi

PYTHON_LAUNCHER="python $(format_shell_arg "${REPO_ROOT}/tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py") --repo-root $(format_shell_arg "${REPO_ROOT}")${INPUT_ARGS}${PREFERRED_ARG}"
LAUNCHER_SURFACE_CHECK="powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1"
LAUNCHER_COMPANION_HELPER="powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -RepoRoot $(format_powershell_arg "${REPO_ROOT}")${POWERSHELL_SUMMARY_ARG}${POWERSHELL_PREFERRED_ARG}${POWERSHELL_BROWSER_ARG}${POWERSHELL_INPUT_ARGS}"
PROOF_SURFACE_CHECK="powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1"
PROOF_ENTRYPOINT="powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1 -RepoRoot $(format_powershell_arg "${REPO_ROOT}")${POWERSHELL_SUMMARY_ARG}${POWERSHELL_PREFERRED_ARG}${POWERSHELL_BROWSER_ARG}${POWERSHELL_INPUT_ARGS}"
WINDOWS_REPLAY_QUICKSTART="powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1 -RepoRoot $(format_powershell_arg "${REPO_ROOT}")${POWERSHELL_SUMMARY_ARG}${POWERSHELL_PREFERRED_ARG}${POWERSHELL_BROWSER_ARG}${POWERSHELL_INPUT_ARGS}"
REPLAY_ROUTE_SHORTCUT="powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot $(format_powershell_arg "${REPO_ROOT}")${POWERSHELL_SUMMARY_ARG}${POWERSHELL_PREFERRED_ARG}${POWERSHELL_BROWSER_ARG}${POWERSHELL_INPUT_ARGS}"

PYTHON_SIDECAR_AUDIT="${PYTHON_LAUNCHER} --audit-sidecars"
PYTHON_ASSET_AUDIT="${PYTHON_LAUNCHER} --audit-assets"
PYTHON_PRINT_MANIFEST="${PYTHON_LAUNCHER} --print-manifest"
PYTHON_STRICT_SIDECARS="${PYTHON_LAUNCHER} --require-complete-sidecars --print-manifest"
PYTHON_STRICT_ASSETS="${PYTHON_LAUNCHER} --require-complete-assets --print-manifest"
PYTHON_STRICT_BUNDLE="${PYTHON_LAUNCHER} --require-complete-sidecars --require-complete-assets --print-manifest"
PYTHON_GOOGLE_SIDECAR_AUDIT="${PYTHON_LAUNCHER} --google-style --audit-sidecars"
PYTHON_GOOGLE_ASSET_AUDIT="${PYTHON_LAUNCHER} --google-style --audit-assets"
PYTHON_GOOGLE_MANIFEST="${PYTHON_LAUNCHER} --google-style --print-manifest"
PYTHON_GOOGLE_STRICT_BUNDLE="${PYTHON_LAUNCHER} --google-style --require-complete-sidecars --require-complete-assets --print-manifest"
PYTHON_GOOGLE_LAUNCH="${PYTHON_LAUNCHER} --google-style"

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Google issue #3 attached-pages launcher companion route")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "browser_exe": %s,\n' "$(json_escape "${BROWSER_EXE}")"
    printf '  "summary_path": %s,\n' "$(json_escape "${SUMMARY_PATH}")"
    printf '  "preferred_initial_page": %s,\n' "$(json_escape "${PREFERRED_INITIAL_PAGE}")"
    printf '  "input_count": %s,\n' "$(json_escape "${#INPUT_PATHS[@]}")"
    printf '  "read_first": [\n'
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md")"
    printf '    %s\n' "$(json_escape "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md")"
    printf '  ],\n'
    printf '  "commands": {\n'
    printf '    "surface_check": %s,\n' "$(json_escape "${LAUNCHER_SURFACE_CHECK}")"
    printf '    "launcher_companion": %s,\n' "$(json_escape "${LAUNCHER_COMPANION_HELPER}")"
    printf '    "python_sidecar_audit": %s,\n' "$(json_escape "${PYTHON_SIDECAR_AUDIT}")"
    printf '    "python_asset_audit": %s,\n' "$(json_escape "${PYTHON_ASSET_AUDIT}")"
    printf '    "python_print_manifest": %s,\n' "$(json_escape "${PYTHON_PRINT_MANIFEST}")"
    printf '    "python_strict_sidecars": %s,\n' "$(json_escape "${PYTHON_STRICT_SIDECARS}")"
    printf '    "python_strict_assets": %s,\n' "$(json_escape "${PYTHON_STRICT_ASSETS}")"
    printf '    "python_strict_bundle": %s,\n' "$(json_escape "${PYTHON_STRICT_BUNDLE}")"
    printf '    "python_google_sidecar_audit": %s,\n' "$(json_escape "${PYTHON_GOOGLE_SIDECAR_AUDIT}")"
    printf '    "python_google_asset_audit": %s,\n' "$(json_escape "${PYTHON_GOOGLE_ASSET_AUDIT}")"
    printf '    "python_google_manifest": %s,\n' "$(json_escape "${PYTHON_GOOGLE_MANIFEST}")"
    printf '    "python_google_strict_bundle": %s,\n' "$(json_escape "${PYTHON_GOOGLE_STRICT_BUNDLE}")"
    printf '    "python_google_launch": %s,\n' "$(json_escape "${PYTHON_GOOGLE_LAUNCH}")"
    printf '    "proof_surface_check": %s,\n' "$(json_escape "${PROOF_SURFACE_CHECK}")"
    printf '    "proof_entrypoint": %s,\n' "$(json_escape "${PROOF_ENTRYPOINT}")"
    printf '    "windows_replay_quickstart": %s,\n' "$(json_escape "${WINDOWS_REPLAY_QUICKSTART}")"
    printf '    "replay_route_shortcut": %s\n' "$(json_escape "${REPLAY_ROUTE_SHORTCUT}")"
    printf '  },\n'
    printf '  "notes": [\n'
    printf '    %s,\n' "$(json_escape "Run the launcher companion surface check first so missing Windows helper paths or nearby docs fail fast before you trust the cross-platform launcher ladder.")"
    printf '    %s,\n' "$(json_escape "Use python_sidecar_audit first, then python_asset_audit, then the strict bundle checks so missing sibling _files directories or local assets are caught before replay is blamed on the browser.")"
    printf '    %s,\n' "$(json_escape "Use the Google-style Python variants when the current bundle should keep the strongest Google-like attached page first while the route narrows back toward issue #3 reproduction.")"
    printf '    %s,\n' "$(json_escape "Use proof_surface_check and proof_entrypoint when the current run is already pinned to the known three-page compatibility bundle and you want the proof-only bridge reprinted before replay widens again.")"
    printf '    %s,\n' "$(json_escape "Use windows_replay_quickstart after launcher-side preflight when the next honest step is to hand control back into the Windows replay ladder without reopening the broader route map first.")"
    printf '    %s\n' "$(json_escape "Use replay_route_shortcut after launcher-side preflight when the route is already narrowed and the shorter replay-route companion is the next better bridge than the broader replay quickstart.")"
    printf '  ]\n'
    printf '}\n'
    exit 0
fi

cat <<EOF
Google issue #3 attached-pages launcher companion route

Repo root:           ${REPO_ROOT}
Browser exe:         ${BROWSER_EXE}
Summary path:        ${SUMMARY_PATH:- not set}
Preferred page:      ${PREFERRED_INITIAL_PAGE:- not set}
Explicit inputs:     ${#INPUT_PATHS[@]}

Read first
==========
  docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md
  docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md
  docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md
  docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md
  docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md

Suggested route
===============
  Launcher companion surface check:
    ${LAUNCHER_SURFACE_CHECK}

  Broader launcher companion helper:
    ${LAUNCHER_COMPANION_HELPER}

  Cross-platform launcher ladder:
    ${PYTHON_SIDECAR_AUDIT}
    ${PYTHON_ASSET_AUDIT}
    ${PYTHON_PRINT_MANIFEST}
    ${PYTHON_STRICT_SIDECARS}
    ${PYTHON_STRICT_ASSETS}
    ${PYTHON_STRICT_BUNDLE}
    ${PYTHON_GOOGLE_SIDECAR_AUDIT}
    ${PYTHON_GOOGLE_ASSET_AUDIT}
    ${PYTHON_GOOGLE_MANIFEST}
    ${PYTHON_GOOGLE_STRICT_BUNDLE}
    ${PYTHON_GOOGLE_LAUNCH}

  Pinned bundle proof follow-up:
    ${PROOF_SURFACE_CHECK}
    ${PROOF_ENTRYPOINT}

  Windows replay re-entry:
    ${WINDOWS_REPLAY_QUICKSTART}
    ${REPLAY_ROUTE_SHORTCUT}

Working rules
=============
  - Run the launcher companion surface check first so missing Windows helper paths or nearby docs fail fast before you trust the cross-platform launcher ladder.
  - Use the Python sidecar audit first, then the Python asset audit, then the strict bundle checks so missing sibling _files directories or local assets are caught before replay is blamed on the browser.
  - Use the Google-style Python variants when the current bundle should keep the strongest Google-like attached page first while the route narrows back toward issue #3 reproduction.
  - Use the proof surface check and proof entrypoint when the current run is already pinned to the known three-page compatibility bundle and you want the proof-only bridge reprinted before replay widens again.
  - Use the Windows replay quickstart after launcher-side preflight when the next honest step is to hand control back into the Windows replay ladder without reopening the broader route map first.
  - Use the replay-route shortcut after launcher-side preflight when the route is already narrowed and the shorter replay-route companion is the next better bridge than the broader replay quickstart.
EOF
