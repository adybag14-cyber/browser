#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_helper_surface_alignment_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--destination /path/to/restored/browser-checkout] \
    [--json]

Print the issue #3 helper-surface alignment route for the saved-Memory and
saved-browser-snapshot recovery path.
EOF
}

quote_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_DESTINATION_NAME="browser-memory-snapshot"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
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
if [[ -z "${DESTINATION}" ]]; then
    DESTINATION="$(cd "${REPO_ROOT}/.." && pwd)/${DEFAULT_DESTINATION_NAME}"
fi

ALIGNMENT_COMMAND="python $(quote_arg "${HELPER_ROOT}/scripts/check_issue3_helper_surface_alignment.py") --repo-root $(quote_arg "${HELPER_ROOT}")"
RESTORED_ALIGNMENT_COMMAND="python $(quote_arg "${HELPER_ROOT}/scripts/check_issue3_helper_surface_alignment.py") --repo-root $(quote_arg "${DESTINATION}")"
SNAPSHOT_ROUTE_COMMAND="bash $(quote_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(quote_arg "${REPO_ROOT}") --helper-root $(quote_arg "${HELPER_ROOT}") --destination $(quote_arg "${DESTINATION}")"
SYNCED_SNAPSHOT_ROUTE_COMMAND="${SNAPSHOT_ROUTE_COMMAND} --sync-helper-surface"
RESTORED_CHECK_COMMAND="python $(quote_arg "${HELPER_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(quote_arg "${DESTINATION}") --helper-root $(quote_arg "${HELPER_ROOT}") --expect-helper-surface"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 helper-surface alignment route",
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "destination": ${DESTINATION@Q},
    "commands": {
        "alignment": ${ALIGNMENT_COMMAND@Q},
        "snapshot_route": ${SNAPSHOT_ROUTE_COMMAND@Q},
        "synced_snapshot_route": ${SYNCED_SNAPSHOT_ROUTE_COMMAND@Q},
        "restored_alignment": ${RESTORED_ALIGNMENT_COMMAND@Q},
        "restored_checkout_check": ${RESTORED_CHECK_COMMAND@Q}
    },
    "notes": [
        "Run the live helper-root alignment check before trusting a saved-browser-snapshot restore plan.",
        "If the live helper surface is already drifted, fix that first before copying helpers into a restored checkout.",
        "Use the synced snapshot route when the restored checkout should become its own follow-up helper root.",
        "After a synced restore, rerun the alignment checker against the restored checkout and then run the restored-checkout readiness helper."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 helper-surface alignment route

Repo root:        ${REPO_ROOT}
Live helper root: ${HELPER_ROOT}
Restore target:   ${DESTINATION}

Read first
==========
  scripts/check_issue3_helper_surface_alignment.py
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  1. Check the live helper surface before planning a restore:
     ${ALIGNMENT_COMMAND}

  2. Print the saved-browser-snapshot route:
     ${SNAPSHOT_ROUTE_COMMAND}

  3. Prefer the synced restore route when the restored checkout should carry the current helper surface:
     ${SYNCED_SNAPSHOT_ROUTE_COMMAND}

  4. After a synced restore, re-check alignment against the restored checkout:
     ${RESTORED_ALIGNMENT_COMMAND}

  5. Confirm the restored checkout is ready for follow-up:
     ${RESTORED_CHECK_COMMAND}

Working rules
=============
  - Run the live alignment check first so helper-surface drift is caught before a restore flow copies stale assumptions forward.
  - Prefer the synced restore route when the saved archive helper surface is older than the live branch-local helper surface.
  - Re-run the alignment checker against the restored checkout after a synced restore so drift is caught before Linux or WSL follow-up work starts.
  - Use the restored-checkout readiness helper only after the alignment check passes for the target helper root.
EOF
