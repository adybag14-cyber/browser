#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_restore_helper_surface_sync_route_surface.sh \
    [--repo-root /path/to/browser-repo]

Check that the branch-local restore-helper-surface sync route still has the
files it needs before a Linux/WSL re-entry run trusts it.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

REPO_ROOT="${DEFAULT_REPO_ROOT}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
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

declare -a REQUIRED_PATHS=(
    "build.zig.zon"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    "scripts/check_issue3_restore_helper_surface_sync.py"
    "scripts/check_issue3_saved_memory_inputs.py"
    "scripts/linux/restore_saved_browser_snapshot.sh"
    "scripts/linux/show_issue3_restore_helper_surface_sync_route.sh"
)

MISSING=0
for relative_path in "${REQUIRED_PATHS[@]}"; do
    if [[ ! -f "${REPO_ROOT}/${relative_path}" ]]; then
        echo "Missing route file: ${REPO_ROOT}/${relative_path}" >&2
        MISSING=1
    fi
done

if [[ "${MISSING}" -ne 0 ]]; then
    exit 1
fi

echo "Issue #3 restore helper surface sync route surface: PASS"
echo "Repo root: ${REPO_ROOT}"
echo "Suggested next step:"
echo "  python ${REPO_ROOT}/scripts/check_issue3_restore_helper_surface_sync.py --repo-root ${REPO_ROOT}"
