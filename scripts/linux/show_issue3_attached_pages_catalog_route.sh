#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_attached_pages_catalog_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--python-exe python3] \
    [--input-path /path/to/attached-html-or-folder] \
    [--preferred-initial-page page.html] \
    [--bind 127.0.0.1] \
    [--port 8235] \
    [--staging-root /tmp/attached-pages] \
    [--json]

Print the Linux or WSL command ladder for the issue #3 attached-pages catalog
route so the current saved HTML bundle can be audited, pinned, and replayed
through the existing localhost launcher without relying on the Windows wrapper
surface first.
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
PYTHON_EXE="python3"
PREFERRED_INITIAL_PAGE=""
BIND="127.0.0.1"
PORT="8235"
STAGING_ROOT=""
JSON=0
declare -a INPUT_PATHS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --python-exe)
            PYTHON_EXE="$2"
            shift 2
            ;;
        --input-path)
            INPUT_PATHS+=("$2")
            shift 2
            ;;
        --preferred-initial-page)
            PREFERRED_INITIAL_PAGE="$2"
            shift 2
            ;;
        --bind)
            BIND="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --staging-root)
            STAGING_ROOT="$2"
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
if [[ ! -f "${REPO_ROOT}/build.zig" ]]; then
    echo "Repo root does not look like a browser checkout: ${REPO_ROOT}" >&2
    exit 1
fi

LAUNCHER_PATH="${REPO_ROOT}/tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"
if [[ ! -f "${LAUNCHER_PATH}" ]]; then
    echo "Attached-pages launcher not found: ${LAUNCHER_PATH}" >&2
    exit 1
fi

BASE_COMMAND="$(format_shell_arg "${PYTHON_EXE}") $(format_shell_arg "${LAUNCHER_PATH}") --repo-root $(format_shell_arg "${REPO_ROOT}") --google-style"
for input_path in "${INPUT_PATHS[@]}"; do
    BASE_COMMAND+=" --input $(format_shell_arg "${input_path}")"
done
if [[ -n "${PREFERRED_INITIAL_PAGE}" ]]; then
    BASE_COMMAND+=" --preferred-initial-page $(format_shell_arg "${PREFERRED_INITIAL_PAGE}")"
fi
if [[ -n "${STAGING_ROOT}" ]]; then
    BASE_COMMAND+=" --staging-root $(format_shell_arg "${STAGING_ROOT}")"
fi

SIDECAR_AUDIT_COMMAND="${BASE_COMMAND} --audit-sidecars"
ASSET_AUDIT_COMMAND="${BASE_COMMAND} --audit-assets"
STRICT_MANIFEST_COMMAND="${BASE_COMMAND} --print-manifest --require-complete-sidecars --require-complete-assets"
START_SERVER_COMMAND="${BASE_COMMAND} --bind $(format_shell_arg "${BIND}") --port $(format_shell_arg "${PORT}")"

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Issue #3 attached-pages catalog route")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "python_exe": %s,\n' "$(json_escape "${PYTHON_EXE}")"
    printf '  "launcher_path": %s,\n' "$(json_escape "${LAUNCHER_PATH}")"
    printf '  "bind": %s,\n' "$(json_escape "${BIND}")"
    printf '  "port": %s,\n' "$(json_escape "${PORT}")"
    printf '  "preferred_initial_page": %s,\n' "$(json_escape "${PREFERRED_INITIAL_PAGE}")"
    printf '  "staging_root": %s,\n' "$(json_escape "${STAGING_ROOT}")"
    printf '  "input_path_count": %s,\n' "${#INPUT_PATHS[@]}"
    printf '  "commands": {\n'
    printf '    "sidecar_audit": %s,\n' "$(json_escape "${SIDECAR_AUDIT_COMMAND}")"
    printf '    "asset_audit": %s,\n' "$(json_escape "${ASSET_AUDIT_COMMAND}")"
    printf '    "strict_manifest": %s,\n' "$(json_escape "${STRICT_MANIFEST_COMMAND}")"
    printf '    "start_server": %s\n' "$(json_escape "${START_SERVER_COMMAND}")"
    printf '  }\n'
    printf '}\n'
    exit 0
fi

echo "Issue #3 attached-pages catalog route"
echo
echo "Repo root:              ${REPO_ROOT}"
echo "Launcher:               ${LAUNCHER_PATH}"
echo "Python:                 ${PYTHON_EXE}"
echo "Bind:                   http://${BIND}:${PORT}/"
if [[ -n "${PREFERRED_INITIAL_PAGE}" ]]; then
    echo "Preferred initial page: ${PREFERRED_INITIAL_PAGE}"
fi
if [[ -n "${STAGING_ROOT}" ]]; then
    echo "Staging root:           ${STAGING_ROOT}"
fi
if [[ "${#INPUT_PATHS[@]}" -gt 0 ]]; then
    echo "Pinned input paths:     ${#INPUT_PATHS[@]}"
fi
echo
echo "Suggested route:"
printf '  %s\n' "${SIDECAR_AUDIT_COMMAND}"
printf '  %s\n' "${ASSET_AUDIT_COMMAND}"
printf '  %s\n' "${STRICT_MANIFEST_COMMAND}"
printf '  %s\n' "${START_SERVER_COMMAND}"
echo
echo "Notes:"
echo "  - Run the sidecar audit first so missing sibling _files bundles are treated as export problems before browser-runtime debugging."
echo "  - Run the asset audit next so missing local CSS, JS, or image files are ruled out before the headed replay is trusted."
echo "  - Use the strict manifest command when the same inputs should stay pinned end-to-end for the localhost replay."
echo "  - Start the server only after the strict manifest route is green, then hand the printed localhost page URLs to the next headed replay step."
