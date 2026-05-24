#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_attached_pages_preflight_route_surface.sh \
    [--repo-root /path/to/browser-repo]

Fail fast when the issue #3 attached-pages preflight route is missing its
branch-local guide or helper surface.
EOF
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

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
    "docs/ISSUE3_ATTACHED_PAGES_PREFLIGHT_ROUTE.md"
    "scripts/linux/check_issue3_attached_pages_preflight_route_surface.sh"
    "scripts/linux/show_issue3_attached_pages_preflight_route.sh"
    "tmp-browser-smoke/attached-pages/README.md"
    "tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py"
    "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"
    "scripts/windows/show_attached_pages_preflight_report.ps1"
    "scripts/windows/start_attached_pages_catalog.ps1"
)

missing=()
for relative_path in "${required_paths[@]}"; do
    if [[ ! -f "${REPO_ROOT}/${relative_path}" ]]; then
        missing+=("${relative_path}")
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Issue #3 attached-pages preflight route surface is incomplete." >&2
    echo "Repo root: ${REPO_ROOT}" >&2
    echo "Missing files:" >&2
    for relative_path in "${missing[@]}"; do
        echo "  - ${relative_path}" >&2
    done
    exit 1
fi

cat <<EOF
Issue #3 attached-pages preflight route surface is ready.
Repo root: ${REPO_ROOT}
Guide: ${REPO_ROOT}/docs/ISSUE3_ATTACHED_PAGES_PREFLIGHT_ROUTE.md
Preflight helper: ${REPO_ROOT}/tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py
Catalog launcher: ${REPO_ROOT}/tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py
EOF
