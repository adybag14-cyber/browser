#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_google_attached_html_validation_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--input /path/to/attached.html | /path/to/bundle-dir] \
    [--preferred-initial-page page-name-or-path] \
    [--host 127.0.0.1] \
    [--port 8235] \
    [--check-only] \
    [--json]

Print the Linux or WSL preflight route for the issue #3 attached HTML replay.
This route keeps the saved-memory preflight, the attached-pages sidecar audit,
the local asset-closure audit, the strict manifest proof step, and the localhost
catalog launch command on one compact surface before the Windows headed replay
helper takes over.

Defaults:
  repo root  parent of this script
  host       127.0.0.1
  port       8235

Use --input more than once to pin an explicit attached-page bundle instead of
relying on the catalog helper's normal workspace auto-discovery.
Use --preferred-initial-page to keep one selected page first when printing the
strict manifest proof route and the localhost launch command.
Use --check-only to validate the branch-local helper surface without printing
the full route commands.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

format_command() {
    local rendered=""
    local arg=""
    for arg in "$@"; do
        if [[ -n "${rendered}" ]]; then
            rendered+=" "
        fi
        rendered+="$(format_shell_arg "${arg}")"
    done
    printf '%s\n' "${rendered}"
}

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

format_powershell_literal() {
    python3 - "$1" <<'PY'
import sys

print("'" + sys.argv[1].replace("'", "''") + "'")
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
HOST="127.0.0.1"
PORT="8235"
PREFERRED_INITIAL_PAGE=""
CHECK_ONLY=false
JSON=false
declare -a INPUT_PATHS=()

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
        --host)
            HOST="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --check-only)
            CHECK_ONLY=true
            shift
            ;;
        --json)
            JSON=true
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

declare -a REQUIRED_FILES=(
    "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"
    "scripts/check_issue3_saved_memory_inputs.py"
    "scripts/windows/show_google_attached_html_validation_flow.ps1"
    "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"
)

declare -a MISSING_FILES=()
for relative_path in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "${REPO_ROOT}/${relative_path}" ]]; then
        MISSING_FILES+=("${relative_path}")
    fi
done

declare -a BASE_CATALOG_CMD=(
    python
    ./tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py
    --repo-root
    "${REPO_ROOT}"
    --google-style
)

if [[ "${#INPUT_PATHS[@]}" -gt 0 ]]; then
    for input_path in "${INPUT_PATHS[@]}"; do
        BASE_CATALOG_CMD+=(--input "${input_path}")
    done
fi

if [[ -n "${PREFERRED_INITIAL_PAGE}" ]]; then
    BASE_CATALOG_CMD+=(--preferred-initial-page "${PREFERRED_INITIAL_PAGE}")
fi

declare -a MEMORY_PREFLIGHT_CMD=(
    python
    ./scripts/check_issue3_saved_memory_inputs.py
    --repo-root
    "${REPO_ROOT}"
)
declare -a SIDECAR_AUDIT_CMD=("${BASE_CATALOG_CMD[@]}" --audit-sidecars)
declare -a ASSET_AUDIT_CMD=("${BASE_CATALOG_CMD[@]}" --audit-assets)
declare -a MANIFEST_CMD=("${BASE_CATALOG_CMD[@]}" --print-manifest --require-complete-sidecars --require-complete-assets)
declare -a SERVER_CMD=("${BASE_CATALOG_CMD[@]}" --bind "${HOST}" --port "${PORT}")

WINDOWS_HELPER_CMD="powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1"
if [[ -n "${PREFERRED_INITIAL_PAGE}" ]]; then
    WINDOWS_HELPER_CMD+=" -PreferredInitialPage $(format_powershell_literal "${PREFERRED_INITIAL_PAGE}")"
fi
if [[ "${#INPUT_PATHS[@]}" -gt 0 ]]; then
    WINDOWS_HELPER_CMD+=" -InputPath"
    for input_path in "${INPUT_PATHS[@]}"; do
        WINDOWS_HELPER_CMD+=" $(format_powershell_literal "${input_path}")"
    done
fi

if [[ "${JSON}" == "true" ]]; then
    printf '{\n'
    printf '  "profile": "issue3-linux-google-attached-html-validation-route",\n'
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "host": %s,\n' "$(json_escape "${HOST}")"
    printf '  "port": %s,\n' "$(json_escape "${PORT}")"
    printf '  "preferred_initial_page": %s,\n' "$(json_escape "${PREFERRED_INITIAL_PAGE}")"
    printf '  "explicit_input_count": %s,\n' "${#INPUT_PATHS[@]}"
    printf '  "check_only": %s,\n' "${CHECK_ONLY}"
    printf '  "missing_file_count": %s,\n' "${#MISSING_FILES[@]}"
    printf '  "memory_preflight": %s,\n' "$(json_escape "$(format_command "${MEMORY_PREFLIGHT_CMD[@]}")")"
    printf '  "sidecar_audit": %s,\n' "$(json_escape "$(format_command "${SIDECAR_AUDIT_CMD[@]}")")"
    printf '  "asset_audit": %s,\n' "$(json_escape "$(format_command "${ASSET_AUDIT_CMD[@]}")")"
    printf '  "strict_manifest": %s,\n' "$(json_escape "$(format_command "${MANIFEST_CMD[@]}")")"
    printf '  "localhost_catalog": %s,\n' "$(json_escape "$(format_command "${SERVER_CMD[@]}")")"
    printf '  "windows_handoff": %s,\n' "$(json_escape "${WINDOWS_HELPER_CMD}")"
    printf '  "missing_files": ['
    for idx in "${!MISSING_FILES[@]}"; do
        if [[ "${idx}" -gt 0 ]]; then
            printf ', '
        fi
        printf '%s' "$(json_escape "${MISSING_FILES[$idx]}")"
    done
    printf ']\n'
    printf '}\n'
    if [[ "${#MISSING_FILES[@]}" -gt 0 ]]; then
        exit 1
    fi
    exit 0
fi

if [[ "${#MISSING_FILES[@]}" -gt 0 ]]; then
    echo "Issue #3 Linux attached HTML validation route surface is incomplete." >&2
    echo >&2
    for relative_path in "${MISSING_FILES[@]}"; do
        echo "Missing: ${relative_path}" >&2
    done
    exit 1
fi

if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo "Issue #3 Linux attached HTML validation route surface is present."
    echo
    echo "Repo root: ${REPO_ROOT}"
    echo "Guide:     docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"
    echo "Launcher:  tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"
    echo "Handoff:   scripts/windows/show_google_attached_html_validation_flow.ps1"
    exit 0
fi

echo "Issue #3 Linux attached HTML validation route"
echo
echo "Repo root: ${REPO_ROOT}"
echo "Goal: keep the saved-memory preflight, sidecar audit, local asset audit,"
echo "strict manifest proof step, and localhost catalog launch on one compact"
echo "Linux or WSL surface before the Windows headed replay helper takes over."
echo
echo "Read-first note:"
echo "  docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"
echo
echo "Commands:"
echo "  1. Saved-memory preflight: $(format_command "${MEMORY_PREFLIGHT_CMD[@]}")"
echo "  2. Sidecar audit:          $(format_command "${SIDECAR_AUDIT_CMD[@]}")"
echo "  3. Local asset audit:      $(format_command "${ASSET_AUDIT_CMD[@]}")"
echo "  4. Strict manifest proof:  $(format_command "${MANIFEST_CMD[@]}")"
echo "  5. Start localhost catalog: $(format_command "${SERVER_CMD[@]}")"
echo "  6. Windows headed handoff: ${WINDOWS_HELPER_CMD}"
echo
echo "Notes:"
echo "  - Leave --input unset to let the catalog helper auto-discover attached HTML"
echo "    files from the usual workspace search roots."
echo "  - Use --preferred-initial-page when the replay should keep one selected page"
echo "    first through the strict manifest proof step and the localhost launch."
echo "  - The Linux or WSL route stages the local bundle and localhost server. The"
echo "    final headed replay still hands off to the existing Windows helper."
