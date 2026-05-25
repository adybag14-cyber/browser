#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_zig_archive_route_surface.sh [--repo-root /path/to/browser] [--json]

Fail fast when the saved Zig archive route drifts away from its expected helper files.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
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
DOC_PATH="${REPO_ROOT}/docs/ISSUE3_SAVED_ZIG_ARCHIVE_ROUTE.md"
HELPER_PATH="${REPO_ROOT}/scripts/check_issue3_saved_zig_archives.py"
RESTORE_HELPER="${REPO_ROOT}/scripts/linux/restore_zig_toolchain_archive.sh"
SHOW_ROUTE="${REPO_ROOT}/scripts/linux/show_issue3_saved_zig_archive_route.sh"

for path in "${DOC_PATH}" "${HELPER_PATH}" "${RESTORE_HELPER}" "${SHOW_ROUTE}"; do
    if [[ ! -f "${path}" ]]; then
        echo "Missing required route file: ${path}" >&2
        exit 1
    fi
done

if [[ "${JSON}" -eq 1 ]]; then
    python3 - "${REPO_ROOT}" "${DOC_PATH}" "${HELPER_PATH}" "${RESTORE_HELPER}" "${SHOW_ROUTE}" <<'PY'
import json
import sys

print(json.dumps({
    "status": "passed",
    "repo_root": sys.argv[1],
    "doc_path": sys.argv[2],
    "helper_path": sys.argv[3],
    "restore_helper": sys.argv[4],
    "show_route": sys.argv[5],
}, indent=2))
PY
    exit 0
fi

echo "Saved Zig archive route surface check passed."
echo "Repo root:      ${REPO_ROOT}"
echo "Route note:     ${DOC_PATH}"
echo "Python helper:  ${HELPER_PATH}"
echo "Restore helper: ${RESTORE_HELPER}"
echo "Route printer:  ${SHOW_ROUTE}"
