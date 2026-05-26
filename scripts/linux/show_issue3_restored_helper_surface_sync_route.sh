#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_restored_helper_surface_sync_route.sh \
    [--helper-root /path/to/live/browser] \
    [--restored-root /path/to/browser-memory-snapshot] \
    [--memory-root /path/to/workspace/memory] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--json]

Print the compact restored-helper-surface sync route for the issue #11 Linux or
WSL re-entry lane.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_HELPER_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HELPER_ROOT="${DEFAULT_HELPER_ROOT}"
RESTORED_ROOT=""
MEMORY_ROOT=""
ARCHIVE_PATH=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --helper-root)
            HELPER_ROOT="$2"
            shift 2
            ;;
        --restored-root)
            RESTORED_ROOT="$2"
            shift 2
            ;;
        --memory-root)
            MEMORY_ROOT="$2"
            shift 2
            ;;
        --archive)
            ARCHIVE_PATH="$2"
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

HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
if [[ -z "${RESTORED_ROOT}" ]]; then
    RESTORED_ROOT="$(cd "${HELPER_ROOT}/.." && pwd)/browser-memory-snapshot"
fi
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(cd "${HELPER_ROOT}/.." && pwd)/memory"
fi
if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${MEMORY_ROOT}/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
fi

ROUTE_SURFACE="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
SYNC_CHECK="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_restored_helper_surface_sync.py") --helper-root $(format_shell_arg "${HELPER_ROOT}") --restored-root $(format_shell_arg "${RESTORED_ROOT}")"
SYNC_REFRESH="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${HELPER_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${RESTORED_ROOT}") --sync-only"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 restored helper-surface sync route",
    "helper_root": ${HELPER_ROOT@Q},
    "restored_root": ${RESTORED_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "archive_path": ${ARCHIVE_PATH@Q},
    "read_first": [
        "docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    ],
    "commands": {
        "route_surface": ${ROUTE_SURFACE@Q},
        "sync_check": ${SYNC_CHECK@Q},
        "sync_refresh": ${SYNC_REFRESH@Q}
    },
    "notes": [
        "Run the route surface first so missing route files fail before the restored checkout is trusted as its own helper root.",
        "Run the narrower sync check after the broader restored-checkout readiness check and before saved-memory, saved-archive, build-readiness, or runtime follow-up helpers are trusted from the restored checkout.",
        "Use the sync-only refresh when the restored checkout already exists and only the helper surface needs to be repaired in place."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 restored helper-surface sync route

Helper root:   ${HELPER_ROOT}
Restored root: ${RESTORED_ROOT}
Memory root:   ${MEMORY_ROOT}
Archive path:  ${ARCHIVE_PATH}

Read first
==========
  docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Route surface:
    ${ROUTE_SURFACE}

  Narrower helper-surface sync check:
    ${SYNC_CHECK}

  In-place helper-surface refresh when the restored checkout is stale:
    ${SYNC_REFRESH}

Working rules
=============
  - Run the route surface first so missing route files fail before the restored checkout is trusted as its own helper root.
  - Use the narrower sync check after the broader restored-checkout readiness check and before saved-memory, saved-archive, build-readiness, or runtime follow-up helpers are trusted from the restored checkout.
  - Use the sync-only refresh when the restored checkout already exists and only the helper surface needs to be repaired in place.
EOF
