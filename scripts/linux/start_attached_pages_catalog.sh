#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/start_attached_pages_catalog.sh \
    [--input-path /path/to/file-or-folder] \
    [--preferred-initial-page "Google Safety Centre.html"] \
    [--repo-root /path/to/browser-repo] \
    [--python python3] \
    [--bind 127.0.0.1] \
    [--port 8235] \
    [--staging-root /tmp/attached-pages-staging] \
    [--google-style] \
    [--print-manifest] \
    [--audit-assets] \
    [--audit-assets-json] \
    [--allow-missing-assets] \
    [--audit-sidecars] \
    [--audit-sidecars-json] \
    [--allow-missing-sidecars] \
    [--require-complete-sidecars] \
    [--require-complete-assets]

Launch or inspect the attached-pages localhost catalog through a Linux-friendly
wrapper around tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py.
EOF
}

resolve_repo_root() {
    local start_path="$1"
    local cursor
    cursor="$(cd "${start_path}" && pwd)"

    while true; do
        if [[ -f "${cursor}/build.zig" ]]; then
            printf '%s\n' "${cursor}"
            return
        fi

        local parent
        parent="$(dirname "${cursor}")"
        if [[ -z "${parent}" || "${parent}" == "${cursor}" ]]; then
            echo "Could not resolve the Lightpanda repo root from ${start_path}. Pass --repo-root to override." >&2
            exit 1
        fi
        cursor="${parent}"
    done
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
REPO_ROOT=""
PYTHON_BIN="python3"
BIND="127.0.0.1"
PORT="8235"
STAGING_ROOT=""
PREFERRED_INITIAL_PAGE=""
GOOGLE_STYLE=0
PRINT_MANIFEST=0
AUDIT_ASSETS=0
AUDIT_ASSETS_JSON=0
ALLOW_MISSING_ASSETS=0
AUDIT_SIDECARS=0
AUDIT_SIDECARS_JSON=0
ALLOW_MISSING_SIDECARS=0
REQUIRE_COMPLETE_SIDECARS=0
REQUIRE_COMPLETE_ASSETS=0
declare -a INPUT_PATHS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --input-path)
            INPUT_PATHS+=("$2")
            shift 2
            ;;
        --preferred-initial-page)
            PREFERRED_INITIAL_PAGE="$2"
            shift 2
            ;;
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --python)
            PYTHON_BIN="$2"
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
        --google-style)
            GOOGLE_STYLE=1
            shift
            ;;
        --print-manifest)
            PRINT_MANIFEST=1
            shift
            ;;
        --audit-assets)
            AUDIT_ASSETS=1
            shift
            ;;
        --audit-assets-json)
            AUDIT_ASSETS_JSON=1
            shift
            ;;
        --allow-missing-assets)
            ALLOW_MISSING_ASSETS=1
            shift
            ;;
        --audit-sidecars)
            AUDIT_SIDECARS=1
            shift
            ;;
        --audit-sidecars-json)
            AUDIT_SIDECARS_JSON=1
            shift
            ;;
        --allow-missing-sidecars)
            ALLOW_MISSING_SIDECARS=1
            shift
            ;;
        --require-complete-sidecars)
            REQUIRE_COMPLETE_SIDECARS=1
            shift
            ;;
        --require-complete-assets)
            REQUIRE_COMPLETE_ASSETS=1
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

if [[ -z "${REPO_ROOT}" ]]; then
    REPO_ROOT="$(resolve_repo_root "${SCRIPT_DIR}/../..")"
else
    REPO_ROOT="$(cd "${REPO_ROOT}" && pwd)"
fi

LAUNCHER_PATH="${REPO_ROOT}/tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"
if [[ ! -f "${LAUNCHER_PATH}" ]]; then
    echo "attached pages catalog launcher not found: ${LAUNCHER_PATH}" >&2
    exit 1
fi

if [[ "${AUDIT_ASSETS_JSON}" -eq 1 && "${AUDIT_ASSETS}" -ne 1 ]]; then
    echo "--audit-assets-json requires --audit-assets" >&2
    exit 1
fi
if [[ "${ALLOW_MISSING_ASSETS}" -eq 1 && "${AUDIT_ASSETS}" -ne 1 ]]; then
    echo "--allow-missing-assets requires --audit-assets" >&2
    exit 1
fi
if [[ "${AUDIT_SIDECARS_JSON}" -eq 1 && "${AUDIT_SIDECARS}" -ne 1 ]]; then
    echo "--audit-sidecars-json requires --audit-sidecars" >&2
    exit 1
fi
if [[ "${ALLOW_MISSING_SIDECARS}" -eq 1 && "${AUDIT_SIDECARS}" -ne 1 ]]; then
    echo "--allow-missing-sidecars requires --audit-sidecars" >&2
    exit 1
fi
if [[ "${AUDIT_ASSETS}" -eq 1 && "${AUDIT_SIDECARS}" -eq 1 ]]; then
    echo "choose only one of --audit-assets or --audit-sidecars" >&2
    exit 1
fi
if [[ "${ALLOW_MISSING_ASSETS}" -eq 1 && "${REQUIRE_COMPLETE_ASSETS}" -eq 1 ]]; then
    echo "choose only one of --allow-missing-assets or --require-complete-assets" >&2
    exit 1
fi
if [[ "${ALLOW_MISSING_SIDECARS}" -eq 1 && "${REQUIRE_COMPLETE_SIDECARS}" -eq 1 ]]; then
    echo "choose only one of --allow-missing-sidecars or --require-complete-sidecars" >&2
    exit 1
fi

declare -a launcher_args
launcher_args=("${LAUNCHER_PATH}" "--repo-root" "${REPO_ROOT}")

for input_path in "${INPUT_PATHS[@]}"; do
    launcher_args+=("--input" "${input_path}")
done

if [[ -n "${PREFERRED_INITIAL_PAGE}" ]]; then
    launcher_args+=("--preferred-initial-page" "${PREFERRED_INITIAL_PAGE}")
fi
if [[ -n "${STAGING_ROOT}" ]]; then
    launcher_args+=("--staging-root" "${STAGING_ROOT}")
fi
if [[ "${GOOGLE_STYLE}" -eq 1 ]]; then
    launcher_args+=("--google-style")
fi
if [[ "${PRINT_MANIFEST}" -eq 1 ]]; then
    launcher_args+=("--print-manifest")
elif [[ "${AUDIT_ASSETS}" -eq 1 ]]; then
    launcher_args+=("--audit-assets")
    if [[ "${AUDIT_ASSETS_JSON}" -eq 1 ]]; then
        launcher_args+=("--audit-assets-json")
    fi
    if [[ "${ALLOW_MISSING_ASSETS}" -eq 1 ]]; then
        launcher_args+=("--allow-missing-assets")
    fi
elif [[ "${AUDIT_SIDECARS}" -eq 1 ]]; then
    launcher_args+=("--audit-sidecars")
    if [[ "${AUDIT_SIDECARS_JSON}" -eq 1 ]]; then
        launcher_args+=("--audit-sidecars-json")
    fi
    if [[ "${ALLOW_MISSING_SIDECARS}" -eq 1 ]]; then
        launcher_args+=("--allow-missing-sidecars")
    fi
else
    launcher_args+=("--bind" "${BIND}" "--port" "${PORT}")
fi

if [[ "${REQUIRE_COMPLETE_SIDECARS}" -eq 1 ]]; then
    launcher_args+=("--require-complete-sidecars")
fi
if [[ "${REQUIRE_COMPLETE_ASSETS}" -eq 1 ]]; then
    launcher_args+=("--require-complete-assets")
fi

"${PYTHON_BIN}" "${launcher_args[@]}"
