#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_browser_snapshot_sync_decision_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--destination /path/to/extracted/browser-checkout] \
    [--json]

Print the saved-browser-snapshot sync-decision route for the blocked issue #3
Linux or WSL re-entry path.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

resolve_workspace_companion_path() {
    local root="$1"
    local name="$2"
    local child_path="${root}/${name}"
    local sibling_path="$(cd "${root}/.." && pwd)/${name}"

    if [[ -e "${child_path}" ]]; then
        printf '%s\n' "${child_path}"
        return
    fi

    if [[ "$(basename "${root}")" == "workspace" ]]; then
        printf '%s\n' "${child_path}"
        return
    fi

    printf '%s\n' "${sibling_path}"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"
DEFAULT_DESTINATION_NAME="browser-memory-snapshot"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
MEMORY_ROOT=""
ARCHIVE_PATH=""
DESTINATION=""
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
        --memory-root)
            MEMORY_ROOT="$2"
            shift 2
            ;;
        --archive)
            ARCHIVE_PATH="$2"
            shift 2
            ;;
        --destination)
            DESTINATION="$2"
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
fi
HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "memory")"
fi
if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${MEMORY_ROOT}/repo_archives/browser/${DEFAULT_ARCHIVE_NAME}"
fi
if [[ -z "${DESTINATION}" ]]; then
    DESTINATION="$(resolve_workspace_companion_path "${REPO_ROOT}" "${DEFAULT_DESTINATION_NAME}")"
fi

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_saved_browser_snapshot_sync_decision_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
SYNC_DECISION_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_browser_snapshot_sync_decision.py") --repo-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}")"
SYNC_DECISION_JSON_COMMAND="${SYNC_DECISION_COMMAND} --json"
PLAIN_RESTORE_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}") --check-only"
PLAIN_RESTORE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}")"
SYNC_RESTORE_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}") --sync-helper-surface --check-only"
SYNC_RESTORE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}") --sync-helper-surface"
SYNC_ONLY_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}") --sync-only --check-only"
SYNC_ONLY_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}") --sync-only"
RESTORED_CHECKOUT_COMMAND="python $(format_shell_arg "${DESTINATION}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${DESTINATION}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Issue #3 saved browser snapshot sync-decision route",
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "archive_path": ${ARCHIVE_PATH@Q},
    "destination": ${DESTINATION@Q},
    "read_first": [
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
    ],
    "commands": {
        "route_surface": ${ROUTE_SURFACE_COMMAND@Q},
        "sync_decision": ${SYNC_DECISION_COMMAND@Q},
        "sync_decision_json": ${SYNC_DECISION_JSON_COMMAND@Q},
        "plain_restore_check": ${PLAIN_RESTORE_CHECK_COMMAND@Q},
        "plain_restore": ${PLAIN_RESTORE_COMMAND@Q},
        "sync_restore_check": ${SYNC_RESTORE_CHECK_COMMAND@Q},
        "sync_restore": ${SYNC_RESTORE_COMMAND@Q},
        "sync_only_check": ${SYNC_ONLY_CHECK_COMMAND@Q},
        "sync_only_refresh": ${SYNC_ONLY_COMMAND@Q},
        "restored_checkout_check": ${RESTORED_CHECKOUT_COMMAND@Q}
    },
    "notes": [
        "Run the route surface check first so missing docs or command drift fails before the restore mode is chosen.",
        "Run the sync-decision helper next when the saved snapshot may lag the live helper surface or a previous restored checkout already exists.",
        "Use the plain restore commands only when the helper reports plain-restore.",
        "Use the sync-helper-surface commands when the helper reports sync-helper-surface.",
        "Use the sync-only commands when the helper reports sync-only.",
        "Use the restored-checkout check immediately after a synced restore or sync-only refresh."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Issue #3 saved browser snapshot sync-decision route

Repo root:           ${REPO_ROOT}
Live helper root:    ${HELPER_ROOT}
Memory root:         ${MEMORY_ROOT}
Snapshot archive:    ${ARCHIVE_PATH}
Restore destination: ${DESTINATION}

Read first
==========
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_SYNC_DECISION_ROUTE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md

Suggested route
===============
  Route surface check:
    ${ROUTE_SURFACE_COMMAND}

  Sync-decision helper:
    ${SYNC_DECISION_COMMAND}

  Sync-decision helper with JSON output:
    ${SYNC_DECISION_JSON_COMMAND}

  Plain restore surface check:
    ${PLAIN_RESTORE_CHECK_COMMAND}

  Plain restore command:
    ${PLAIN_RESTORE_COMMAND}

  Synced restore surface check:
    ${SYNC_RESTORE_CHECK_COMMAND}

  Synced restore command:
    ${SYNC_RESTORE_COMMAND}

  Sync-only refresh surface check:
    ${SYNC_ONLY_CHECK_COMMAND}

  Sync-only refresh command:
    ${SYNC_ONLY_COMMAND}

  Restored-checkout follow-up after a synced restore or refresh:
    ${RESTORED_CHECKOUT_COMMAND}

Working rules
=============
  - Run the route surface check first so missing docs or command drift fails before the restore mode is chosen.
  - Run the sync-decision helper next when the saved snapshot may lag the live helper surface or a previous restored checkout already exists.
  - Use the plain restore commands only when the helper reports plain-restore.
  - Use the synced restore commands only when the helper reports sync-helper-surface.
  - Use the sync-only refresh commands only when the helper reports sync-only.
  - Use the restored-checkout check immediately after a synced restore or sync-only refresh.
EOF
