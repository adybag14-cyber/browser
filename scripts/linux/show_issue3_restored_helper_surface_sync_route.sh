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

find_workspace_anchor() {
    local root="$1"
    local current="$1"

    while true; do
        if [[ -d "${current}/memory" || -d "${current}/agent_files" || "$(basename "${current}")" == "workspace" ]]; then
            printf '%s\n' "${current}"
            return
        fi

        local parent
        parent="$(dirname "${current}")"
        if [[ "${parent}" == "${current}" ]]; then
            break
        fi
        current="${parent}"
    done

    printf '%s\n' "$(cd "${root}/.." && pwd)"
}

resolve_workspace_companion_path() {
    local root="$1"
    local name="$2"
    local anchor

    anchor="$(find_workspace_anchor "${root}")"
    printf '%s\n' "${anchor}/${name}"
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
    RESTORED_ROOT="$(resolve_workspace_companion_path "${HELPER_ROOT}" "browser-memory-snapshot")"
fi
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(resolve_workspace_companion_path "${HELPER_ROOT}" "memory")"
fi
if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${MEMORY_ROOT}/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
fi

ROUTE_SURFACE="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
SYNC_CHECK="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_restored_helper_surface_sync.py") --helper-root $(format_shell_arg "${HELPER_ROOT}") --restored-root $(format_shell_arg "${RESTORED_ROOT}")"
ISSUE11_SAVED_MEMORY_CONTRACT="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue11_saved_memory_helper_contract.py") --repo-root $(format_shell_arg "${RESTORED_ROOT}")"
ISSUE11_REENTRY_INVENTORY="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue11_reentry_inventory_consistency.py") --repo-root $(format_shell_arg "${RESTORED_ROOT}")"
SYNC_REFRESH="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${HELPER_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${RESTORED_ROOT}") --sync-only"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Issue #11 Linux/WSL restored helper-surface sync route for issue #3 re-entry",
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
        "issue11_saved_memory_contract": ${ISSUE11_SAVED_MEMORY_CONTRACT@Q},
        "issue11_reentry_inventory": ${ISSUE11_REENTRY_INVENTORY@Q},
        "sync_refresh": ${SYNC_REFRESH@Q}
    },
    "notes": [
        "Run the route surface first so missing route files fail before the restored checkout is trusted as its own helper root.",
        "Run the narrower sync check after the broader restored-checkout readiness check and before saved-memory, saved-archive, build-readiness, or runtime follow-up helpers are trusted from the restored checkout.",
        "Run the two issue #11 contract checks immediately after the narrower sync check so the restored checkout keeps the current helper contract visible before broader follow-up helpers run.",
        "Use the sync-only refresh when the restored checkout already exists and only the helper surface needs to be repaired in place."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Issue #11 Linux/WSL restored helper-surface sync route for issue #3 re-entry

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

  Issue #11 saved-memory helper contract check:
    ${ISSUE11_SAVED_MEMORY_CONTRACT}

  Issue #11 re-entry inventory consistency check:
    ${ISSUE11_REENTRY_INVENTORY}

  In-place helper-surface refresh when the restored checkout is stale:
    ${SYNC_REFRESH}

Working rules
=============
  - Run the route surface first so missing route files fail before the restored checkout is trusted as its own helper root.
  - Use the narrower sync check after the broader restored-checkout readiness check and before saved-memory, saved-archive, build-readiness, or runtime follow-up helpers are trusted from the restored checkout.
  - Run the two issue #11 contract checks immediately after the narrower sync check so the restored checkout keeps the current helper contract visible before broader follow-up helpers run.
  - Use the sync-only refresh when the restored checkout already exists and only the helper surface needs to be repaired in place.
EOF
