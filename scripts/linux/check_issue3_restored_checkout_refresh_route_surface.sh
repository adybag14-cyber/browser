#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_restored_checkout_refresh_route_surface.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--restored-checkout /path/to/browser-memory-snapshot] \
    [--json]

Check that the live helper surface for the issue #3 restored-checkout refresh
route is present before future runs try to repair a stale restored checkout in
place.
EOF
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
HELPER_ROOT=""
RESTORED_CHECKOUT=""
JSON=0

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
        --restored-checkout)
            RESTORED_CHECKOUT="$2"
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
if [[ -z "${HELPER_ROOT}" ]]; then
    HELPER_ROOT="${REPO_ROOT}"
else
    HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
fi
if [[ -z "${RESTORED_CHECKOUT}" ]]; then
    RESTORED_CHECKOUT="$(cd "${REPO_ROOT}/.." && pwd)/browser-memory-snapshot"
fi

declare -a REQUIRED_PATHS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"
    "docs/ISSUE3_RESTORED_CHECKOUT_REFRESH_ROUTE.md"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
    "scripts/linux/restore_saved_browser_snapshot.sh"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
    "scripts/check_issue3_restored_checkout.py"
    "scripts/check_issue3_saved_memory_inputs.py"
)

declare -a MISSING=()
for relative_path in "${REQUIRED_PATHS[@]}"; do
    if [[ ! -f "${HELPER_ROOT}/${relative_path}" ]]; then
        MISSING+=("${relative_path}")
    fi
done

RESTORED_EXISTS=false
RESTORED_HAS_BUILD_MANIFEST=false
if [[ -d "${RESTORED_CHECKOUT}" ]]; then
    RESTORED_EXISTS=true
    if [[ -f "${RESTORED_CHECKOUT}/build.zig.zon" ]]; then
        RESTORED_HAS_BUILD_MANIFEST=true
    fi
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "route": %s,\n' "$(json_escape "issue3-restored-checkout-refresh-surface")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "helper_root": %s,\n' "$(json_escape "${HELPER_ROOT}")"
    printf '  "restored_checkout": %s,\n' "$(json_escape "${RESTORED_CHECKOUT}")"
    printf '  "restored_checkout_exists": %s,\n' "$([[ "${RESTORED_EXISTS}" == true ]] && echo true || echo false)"
    printf '  "restored_checkout_has_build_manifest": %s,\n' "$([[ "${RESTORED_HAS_BUILD_MANIFEST}" == true ]] && echo true || echo false)"
    printf '  "missing_required_paths": ['
    for i in "${!MISSING[@]}"; do
        if [[ "${i}" -gt 0 ]]; then
            printf ', '
        fi
        printf '%s' "$(json_escape "${MISSING[$i]}")"
    done
    printf '],\n'
    printf '  "ok": %s\n' "$([[ "${#MISSING[@]}" -eq 0 ]] && echo true || echo false)"
    printf '}\n'
    exit 0
fi

echo "Issue #3 restored-checkout refresh route surface"
echo
echo "Repo root:          ${REPO_ROOT}"
echo "Helper root:        ${HELPER_ROOT}"
echo "Restored checkout:  ${RESTORED_CHECKOUT}"
echo "Restored exists:    ${RESTORED_EXISTS}"
echo "Restored manifest:  ${RESTORED_HAS_BUILD_MANIFEST}"
echo

if [[ "${#MISSING[@]}" -eq 0 ]]; then
    echo "Surface check passed."
    exit 0
fi

echo "Surface check failed." >&2
for relative_path in "${MISSING[@]}"; do
    echo "  missing: ${relative_path}" >&2
done
exit 1
