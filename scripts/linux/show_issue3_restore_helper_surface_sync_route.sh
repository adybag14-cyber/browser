#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_restore_helper_surface_sync_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Print the restore-helper-surface sync route for the issue #3 Linux/WSL
saved-snapshot re-entry lane.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_restore_helper_surface_sync_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SYNC_CHECK_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_restore_helper_surface_sync.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SYNC_CHECK_JSON_COMMAND="${SYNC_CHECK_COMMAND} --json"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Issue #3 restore helper surface sync route",
    "repo_root": ${REPO_ROOT@Q},
    "commands": {
        "surface_check": ${SURFACE_COMMAND@Q},
        "sync_check": ${SYNC_CHECK_COMMAND@Q},
        "sync_check_json": ${SYNC_CHECK_JSON_COMMAND@Q},
    },
    "notes": [
        "Run the surface check first so missing route files fail fast before the sync checker is blamed.",
        "Run the sync check before trusting --sync-helper-surface or --sync-only restores for Linux or WSL follow-up work.",
        "Treat a reported mismatch as restore-helper drift first, not as evidence that the saved repo snapshot itself is corrupt.",
        "Keep docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md and docs/ISSUE3_RUNTIME_REENTRY_GATES.md nearby when the sync check fails, because the next fix usually belongs in the restore helper surface."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Issue #3 restore helper surface sync route

Repo root: ${REPO_ROOT}

Read first
==========
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  scripts/check_issue3_saved_memory_inputs.py
  scripts/linux/restore_saved_browser_snapshot.sh

Suggested route
===============
  Surface check:
    ${SURFACE_COMMAND}

  Sync check:
    ${SYNC_CHECK_COMMAND}

  Structured sync check output:
    ${SYNC_CHECK_JSON_COMMAND}

Working rules
=============
  - Run the surface check first so missing route files fail fast before the sync checker itself is blamed.
  - Run the sync check before trusting --sync-helper-surface or --sync-only restores for Linux or WSL follow-up work.
  - Treat a reported mismatch as restore-helper drift first, not as proof that the saved repo snapshot or dependency bundles are bad.
  - When the sync check fails, keep docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md and docs/ISSUE3_RUNTIME_REENTRY_GATES.md open so the next fix stays on the restore-helper lane instead of drifting back into the blocked runtime files.
EOF
