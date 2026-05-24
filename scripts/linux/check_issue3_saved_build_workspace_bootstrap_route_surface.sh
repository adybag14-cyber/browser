#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_build_workspace_bootstrap_route_surface.sh \
    [--repo-root /path/to/browser-repo]

Fail fast when the saved build workspace bootstrap route helper or one of its
required branch-local dependencies is missing.
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

REQUIRED_PATHS=(
    "scripts/linux/show_issue3_saved_build_workspace_bootstrap_route.sh"
    "scripts/linux/bootstrap_issue3_saved_build_workspace.sh"
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
)

for relative_path in "${REQUIRED_PATHS[@]}"; do
    if [[ ! -f "${REPO_ROOT}/${relative_path}" ]]; then
        echo "Missing required route helper: ${REPO_ROOT}/${relative_path}" >&2
        exit 1
    fi
done

echo "Saved build workspace bootstrap route surface check passed."
echo "Repo root: ${REPO_ROOT}"
echo "Required helper files: ${#REQUIRED_PATHS[@]}"
