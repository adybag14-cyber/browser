#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/run_issue3_saved_memory_preflight_from_workspace.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--agent-files-root /path/to/workspace/agent_files] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--python python3] \
    [--json] \
    [--skip-archive-integrity-check] \
    [--self-test]

Resolve the scheduled-run workspace companion folders explicitly and forward
them to scripts/check_issue3_saved_memory_inputs.py so /workspace-style runs do
not fall back to /memory or /agent_files by mistake.
EOF
}

find_workspace_anchor() {
    local root="$1"
    local current="$1"

    while true; do
        if [[ -d "${current}/memory" || -d "${current}/agent_files" || "$(basename "${current}")" == "workspace" ]]; then
            printf '%s\n' "${current}"
            return
        fi

        local parent
        parent="$(dirname "${current}")"
        if [[ "${parent}" == "${current}" ]]; then
            break
        fi
        current="${parent}"
    done

    printf '%s\n' "$(cd "${root}" && pwd)"
}

resolve_workspace_companion_path() {
    local root="$1"
    local name="$2"
    local anchor

    anchor="$(find_workspace_anchor "${root}")"
    printf '%s\n' "${anchor}/${name}"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
MEMORY_ROOT=""
AGENT_FILES_ROOT=""
RESTORED_CHECKOUT_ROOT=""
PYTHON_EXE="python3"
declare -a FORWARD_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --helper-root)
            HELPER_ROOT="$2"
            shift 2
            ;;
        --memory-root)
            MEMORY_ROOT="$2"
            shift 2
            ;;
        --agent-files-root)
            AGENT_FILES_ROOT="$2"
            shift 2
            ;;
        --restored-checkout-root)
            RESTORED_CHECKOUT_ROOT="$2"
            shift 2
            ;;
        --python)
            PYTHON_EXE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            FORWARD_ARGS+=("$1")
            shift
            ;;
    esac
done

REPO_ROOT="$(cd "${REPO_ROOT}" && pwd)"
if [[ -z "${HELPER_ROOT}" ]]; then
    HELPER_ROOT="${REPO_ROOT}"
fi
HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"

if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "memory")"
fi
if [[ -z "${AGENT_FILES_ROOT}" ]]; then
    AGENT_FILES_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "agent_files")"
fi
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    if [[ "$(basename "${REPO_ROOT}")" == "workspace" ]]; then
        RESTORED_CHECKOUT_ROOT="${REPO_ROOT}/browser-memory-snapshot"
    else
        RESTORED_CHECKOUT_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "browser-memory-snapshot")"
    fi
fi

CHECK_SCRIPT="${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py"
if [[ ! -f "${CHECK_SCRIPT}" ]]; then
    echo "saved-memory preflight helper not found: ${CHECK_SCRIPT}" >&2
    exit 1
fi

exec "${PYTHON_EXE}" "${CHECK_SCRIPT}" \
    --repo-root "${REPO_ROOT}" \
    --helper-root "${HELPER_ROOT}" \
    --memory-root "${MEMORY_ROOT}" \
    --agent-files-root "${AGENT_FILES_ROOT}" \
    --restored-checkout-root "${RESTORED_CHECKOUT_ROOT}" \
    "${FORWARD_ARGS[@]}"
