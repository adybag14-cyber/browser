#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_reentry_route_index_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Check that the issue #3 re-entry route index note and companion helpers still
exist on the current branch-local surface.
EOF
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
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

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

declare -a REQUIRED_PATHS=(
    "docs/ISSUE3_REENTRY_ROUTE_INDEX.md"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    "scripts/linux/check_issue3_reentry_route_index_surface.sh"
    "scripts/linux/show_issue3_reentry_route_index.sh"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
    "scripts/check_issue3_saved_memory_inputs.py"
    "scripts/check_issue3_saved_archive_integrity.py"
    "scripts/check_linux_build_readiness.py"
)

declare -a MISSING_PATHS=()
for relative_path in "${REQUIRED_PATHS[@]}"; do
    if [[ ! -f "${REPO_ROOT}/${relative_path}" ]]; then
        MISSING_PATHS+=("${relative_path}")
    fi
done

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "route": %s,\n' "$(json_escape "issue3 re-entry route index surface")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "required_paths": [\n'
    for i in "${!REQUIRED_PATHS[@]}"; do
        suffix=','
        if [[ "${i}" -eq $((${#REQUIRED_PATHS[@]} - 1)) ]]; then
            suffix=''
        fi
        printf '    %s%s\n' "$(json_escape "${REQUIRED_PATHS[i]}")" "${suffix}"
    done
    printf '  ],\n'
    printf '  "missing_paths": [\n'
    for i in "${!MISSING_PATHS[@]}"; do
        suffix=','
        if [[ "${i}" -eq $((${#MISSING_PATHS[@]} - 1)) ]]; then
            suffix=''
        fi
        printf '    %s%s\n' "$(json_escape "${MISSING_PATHS[i]}")" "${suffix}"
    done
    printf '  ],\n'
    printf '  "ok": %s\n' "$([[ "${#MISSING_PATHS[@]}" -eq 0 ]] && echo true || echo false)"
    printf '}\n'
    exit $([[ "${#MISSING_PATHS[@]}" -eq 0 ]] && echo 0 || echo 1)
fi

if [[ "${#MISSING_PATHS[@]}" -ne 0 ]]; then
    echo "Issue #3 re-entry route index surface is incomplete under ${REPO_ROOT}" >&2
    printf 'Missing path: %s\n' "${MISSING_PATHS[@]}" >&2
    exit 1
fi

echo "Issue #3 re-entry route index surface is present under ${REPO_ROOT}"
printf 'Checked path: %s\n' "${REQUIRED_PATHS[@]}"
