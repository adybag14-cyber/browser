#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_attached_pages_preflight_report.sh \
    [--repo-root /path/to/browser-repo] \
    [--input /path/to/page-or-dir]... \
    [--use-workspace-agent-files] \
    [--agent-files-root /path/to/agent_files] \
    [--preferred-initial-page 'Preferred Page.html'] \
    [--python-exe python3] \
    [--google-style] \
    [--json] \
    [--allow-missing-sidecars] \
    [--allow-missing-assets]

Run the attached-pages localhost preflight report from a Linux shell without
having to reassemble the Python command by hand.

Defaults:
  repo root         parent of this script
  python executable python

Use --use-workspace-agent-files to pin the report to the workspace agent_files
bundle discovered beside the repo workspace. Use --agent-files-root when the
attached HTML bundle lives in a specific directory that should be passed as one
explicit input root.
EOF
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
PYTHON_EXE="python"
PREFERRED_INITIAL_PAGE=""
GOOGLE_STYLE=0
JSON=0
ALLOW_MISSING_SIDECARS=0
ALLOW_MISSING_ASSETS=0
USE_WORKSPACE_AGENT_FILES=0
AGENT_FILES_ROOT=""
declare -a INPUT_PATHS=()

find_workspace_agent_files_root() {
    local repo_root="$1"
    local cursor="${repo_root}"

    while true; do
        if [[ -d "${cursor}/agent_files" ]]; then
            (
                cd "${cursor}/agent_files"
                pwd
            )
            return 0
        fi

        local parent
        parent="$(dirname "${cursor}")"
        if [[ "${parent}" == "${cursor}" ]]; then
            break
        fi
        cursor="${parent}"
    done

    echo "workspace agent_files folder not found from repo root: ${repo_root}" >&2
    return 1
}

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
        --use-workspace-agent-files)
            USE_WORKSPACE_AGENT_FILES=1
            shift
            ;;
        --agent-files-root)
            AGENT_FILES_ROOT="$2"
            shift 2
            ;;
        --preferred-initial-page)
            PREFERRED_INITIAL_PAGE="$2"
            shift 2
            ;;
        --python-exe)
            PYTHON_EXE="$2"
            shift 2
            ;;
        --google-style)
            GOOGLE_STYLE=1
            shift
            ;;
        --json)
            JSON=1
            shift
            ;;
        --allow-missing-sidecars)
            ALLOW_MISSING_SIDECARS=1
            shift
            ;;
        --allow-missing-assets)
            ALLOW_MISSING_ASSETS=1
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
REPORT_PATH="${REPO_ROOT}/tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py"
if [[ ! -f "${REPORT_PATH}" ]]; then
    echo "attached pages preflight report not found: ${REPORT_PATH}" >&2
    exit 1
fi

if [[ "${USE_WORKSPACE_AGENT_FILES}" -eq 1 && -n "${AGENT_FILES_ROOT}" ]]; then
    echo "Choose either --use-workspace-agent-files or --agent-files-root." >&2
    exit 1
fi
if [[ "${USE_WORKSPACE_AGENT_FILES}" -eq 1 && "${#INPUT_PATHS[@]}" -gt 0 ]]; then
    echo "Choose either explicit --input paths or --use-workspace-agent-files." >&2
    exit 1
fi
if [[ -n "${AGENT_FILES_ROOT}" && "${#INPUT_PATHS[@]}" -gt 0 ]]; then
    echo "Choose either explicit --input paths or --agent-files-root." >&2
    exit 1
fi

if [[ "${USE_WORKSPACE_AGENT_FILES}" -eq 1 ]]; then
    AGENT_FILES_ROOT="$(find_workspace_agent_files_root "${REPO_ROOT}")"
fi

if [[ -n "${AGENT_FILES_ROOT}" ]]; then
    if [[ ! -d "${AGENT_FILES_ROOT}" ]]; then
        echo "agent_files root does not exist: ${AGENT_FILES_ROOT}" >&2
        exit 1
    fi
    INPUT_PATHS+=("${AGENT_FILES_ROOT}")
fi

PYTHON_BIN="$(command -v "${PYTHON_EXE}")"
if [[ -z "${PYTHON_BIN}" ]]; then
    echo "python executable not found: ${PYTHON_EXE}" >&2
    exit 1
fi

declare -a REPORT_ARGS
REPORT_ARGS=("${REPORT_PATH}" "--repo-root" "${REPO_ROOT}")

for input_path in "${INPUT_PATHS[@]}"; do
    if [[ -n "${input_path}" ]]; then
        REPORT_ARGS+=("--input" "${input_path}")
    fi
done

if [[ -n "${PREFERRED_INITIAL_PAGE}" ]]; then
    REPORT_ARGS+=("--preferred-initial-page" "${PREFERRED_INITIAL_PAGE}")
fi
if [[ "${GOOGLE_STYLE}" -eq 1 ]]; then
    REPORT_ARGS+=("--google-style")
fi
if [[ "${JSON}" -eq 1 ]]; then
    REPORT_ARGS+=("--json")
fi
if [[ "${ALLOW_MISSING_SIDECARS}" -eq 1 ]]; then
    REPORT_ARGS+=("--allow-missing-sidecars")
fi
if [[ "${ALLOW_MISSING_ASSETS}" -eq 1 ]]; then
    REPORT_ARGS+=("--allow-missing-assets")
fi

"${PYTHON_BIN}" "${REPORT_ARGS[@]}"
