#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_full_reentry_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Check that the branch-local docs and route helpers needed for the compact issue
#3 full re-entry ladder are present before relying on the higher-level route.
EOF
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

declare -a REQUIRED_FILES=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
    "scripts/linux/show_issue3_windows_runtime_handoff_route.sh"
)

declare -a MISSING_FILES=()
for relative_path in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "${REPO_ROOT}/${relative_path}" ]]; then
        MISSING_FILES+=("${relative_path}")
    fi
done

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Google issue #3 full re-entry route surface")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "required_files": [\n'
    for index in "${!REQUIRED_FILES[@]}"; do
        suffix=','
        if [[ "${index}" -eq $((${#REQUIRED_FILES[@]} - 1)) ]]; then
            suffix=''
        fi
        printf '    %s%s\n' "$(json_escape "${REQUIRED_FILES[${index}]}")" "${suffix}"
    done
    printf '  ],\n'
    printf '  "missing_files": [\n'
    for index in "${!MISSING_FILES[@]}"; do
        suffix=','
        if [[ "${index}" -eq $((${#MISSING_FILES[@]} - 1)) ]]; then
            suffix=''
        fi
        printf '    %s%s\n' "$(json_escape "${MISSING_FILES[${index}]}")" "${suffix}"
    done
    printf '  ],\n'
    printf '  "ok": %s\n' "$([[ "${#MISSING_FILES[@]}" -eq 0 ]] && echo true || echo false)"
    printf '}\n'
    exit $([[ "${#MISSING_FILES[@]}" -eq 0 ]] && echo 0 || echo 1)
fi

echo "Google issue #3 full re-entry route surface"
echo
echo "Repo root: ${REPO_ROOT}"
echo

if [[ "${#MISSING_FILES[@]}" -eq 0 ]]; then
    echo "Surface check passed."
    echo "All required branch-local docs and route helpers are present."
    exit 0
fi

echo "Surface check failed." >&2
echo "Missing required files:" >&2
for relative_path in "${MISSING_FILES[@]}"; do
    echo "  - ${relative_path}" >&2
done
exit 1
