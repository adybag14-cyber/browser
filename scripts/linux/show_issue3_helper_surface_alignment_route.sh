#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_helper_surface_alignment_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Print the helper-surface alignment route for the blocked issue #3 Linux or WSL
re-entry lane.
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

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_helper_surface_alignment_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ALIGNMENT_CHECK_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_helper_surface_alignment.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_MEMORY_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_memory_inputs_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
RESTORED_CHECKOUT_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${REPO_ROOT}/../browser-memory-snapshot")"
PROGRESS_TRACKER_ROUTE_PATH="${REPO_ROOT}/docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 helper-surface alignment route",
    "repo_root": ${REPO_ROOT@Q},
    "progress_tracker_route_path": ${PROGRESS_TRACKER_ROUTE_PATH@Q},
    "commands": {
        "route_surface": ${ROUTE_SURFACE_COMMAND@Q},
        "alignment_check": ${ALIGNMENT_CHECK_COMMAND@Q},
        "saved_memory_route": ${SAVED_MEMORY_ROUTE_COMMAND@Q},
        "saved_browser_snapshot_route": ${SNAPSHOT_ROUTE_COMMAND@Q},
        "restored_checkout_check": ${RESTORED_CHECKOUT_COMMAND@Q}
    },
    "notes": [
        "Run route_surface first so missing notes or helper scripts fail before the inventory comparison is blamed.",
        "Run alignment_check before trusting a restored checkout that was synced from a live helper surface.",
        "Keep docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md visible when helper drift is being fixed so issue #11 remains the low-volume progress-update lane.",
        "Use saved_memory_route when the saved-memory preflight inventory is the drift source.",
        "Use saved_browser_snapshot_route when the restore helper surface is the drift source or the run still needs a refreshed self-contained checkout.",
        "Use restored_checkout_check when a synced checkout already exists and the next question is whether its helper surface is trustworthy."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 helper-surface alignment route

Repo root:              ${REPO_ROOT}
Progress tracker route: ${PROGRESS_TRACKER_ROUTE_PATH}

Read first
==========
  docs/ISSUE3_HELPER_SURFACE_ALIGNMENT_ROUTE.md
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
  docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md

Suggested route
===============
  Surface check:
    ${ROUTE_SURFACE_COMMAND}

  Helper-surface alignment check:
    ${ALIGNMENT_CHECK_COMMAND}

  Saved-memory route when the preflight inventory is stale:
    ${SAVED_MEMORY_ROUTE_COMMAND}

  Restore route when the restore-helper inventory is stale:
    ${SNAPSHOT_ROUTE_COMMAND}

  Restored-checkout check when a synced checkout already exists:
    ${RESTORED_CHECKOUT_COMMAND}

Working rules
=============
  - Run the surface check first so missing notes or helper scripts fail before the inventory comparison is blamed.
  - Run the alignment check before trusting a restored checkout that was synced from a live helper surface.
  - Keep docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md visible when the route is still blocked on helper drift so issue #11 remains the practical progress-tracker handoff.
  - Use the saved-memory route when the saved-memory preflight inventory is the drift source.
  - Use the restore route when the restore-helper inventory is the drift source or when the run still needs a refreshed self-contained checkout.
  - Use the restored-checkout check when a synced checkout already exists and the next question is whether its helper surface is trustworthy.
  - Treat this route as a restore and preflight guard rail, not as proof that the direct Page.zig plus win32_backend.zig runtime patch is ready to reopen.
EOF
