#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_self_contained_linux_bootstrap_route_surface.sh \
    [--repo-root /path/to/browser-repo]

Verify that the compact self-contained Linux bootstrap route for issue #3 is
present on the current branch-local helper surface before the saved-snapshot
restore and Linux re-entry ladder is reopened.
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

required_paths=(
    "docs/ISSUE3_SELF_CONTAINED_LINUX_BOOTSTRAP_ROUTE.md"
    "scripts/linux/check_issue3_self_contained_linux_bootstrap_route_surface.sh"
    "scripts/linux/show_issue3_self_contained_linux_bootstrap_route.sh"
    "scripts/linux/restore_saved_browser_snapshot.sh"
    "scripts/check_issue3_restored_checkout.py"
    "scripts/check_issue3_saved_memory_inputs.py"
    "scripts/check_issue3_saved_archive_integrity.py"
    "scripts/linux/show_issue3_offline_build_inputs_route.sh"
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
)

for relative_path in "${required_paths[@]}"; do
    full_path="${REPO_ROOT}/${relative_path}"
    if [[ ! -f "${full_path}" ]]; then
        echo "Missing required route file: ${full_path}" >&2
        exit 1
    fi
done

echo "Issue #3 self-contained Linux bootstrap route surface check passed."
echo "Repo root: ${REPO_ROOT}"
for relative_path in "${required_paths[@]}"; do
    echo "  - ${relative_path}"
done
