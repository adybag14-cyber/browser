#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_helper_surface_parity_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--json]

Print the issue #3 helper-surface parity route that should run before a saved
snapshot restore, sync-helper-surface refresh, or sync-only helper refresh is
trusted for Linux or WSL re-entry work.
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
SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_helper_surface_parity_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
PARITY_TEXT_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_helper_surface_parity.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
PARITY_JSON_COMMAND="${PARITY_TEXT_COMMAND} --json"
RESTORE_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 helper-surface parity route",
    "repo_root": ${REPO_ROOT@Q},
    "read_first": [
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "scripts/check_issue3_helper_surface_parity.py",
        "scripts/check_issue3_saved_memory_inputs.py",
        "scripts/check_issue3_restored_checkout.py",
        "scripts/linux/restore_saved_browser_snapshot.sh",
    ],
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "parity_text": ${PARITY_TEXT_COMMAND@Q},
        "parity_json": ${PARITY_JSON_COMMAND@Q},
        "saved_snapshot_route": ${RESTORE_ROUTE_COMMAND@Q},
    },
    "expected_signals": [
        "The restore-script manifest, saved-memory helper manifest, and restored-checkout helper manifest all describe the same helper-surface paths.",
        "The parity helper reports no drift before any --sync-helper-surface or --sync-only refresh is trusted.",
        "Only after parity passes should the saved-browser-snapshot route be reused for restore or helper-sync follow-up work.",
    ],
    "notes": [
        "Run the surface check first when the branch may have moved and you want a quick yes-or-no answer that the parity route itself is present.",
        "Run the parity helper in text mode for a short human-readable drift report, or use --json when another script needs the exact missing paths.",
        "If parity fails, update the drifted helper manifest before trusting restore_saved_browser_snapshot.sh --sync-helper-surface or --sync-only to refresh a restored checkout.",
        "If parity passes, continue into show_issue3_saved_browser_snapshot_route.sh for the restore, restored-checkout, archive-integrity, and Linux-or-WSL follow-up ladder.",
    ],
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Issue #3 helper-surface parity route

Repo root: ${REPO_ROOT}

Read first
==========
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  scripts/check_issue3_helper_surface_parity.py
  scripts/check_issue3_saved_memory_inputs.py
  scripts/check_issue3_restored_checkout.py
  scripts/linux/restore_saved_browser_snapshot.sh

Route
=====
  Surface check:       ${SURFACE_CHECK_COMMAND}
  Parity report:       ${PARITY_TEXT_COMMAND}
  Parity JSON:         ${PARITY_JSON_COMMAND}
  Restore route:       ${RESTORE_ROUTE_COMMAND}

Expected signals
================
  - The restore-script manifest, saved-memory helper manifest, and restored-checkout helper manifest all describe the same helper-surface paths.
  - The parity helper reports no drift before any --sync-helper-surface or --sync-only refresh is trusted.
  - Only after parity passes should the saved-browser-snapshot route be reused for restore or helper-sync follow-up work.

Notes
=====
  - Run the surface check first when the branch may have moved and you want a quick yes-or-no answer that the parity route itself is present.
  - Run the parity helper in text mode for a short human-readable drift report, or use --json when another script needs the exact missing paths.
  - If parity fails, update the drifted helper manifest before trusting restore_saved_browser_snapshot.sh --sync-helper-surface or --sync-only to refresh a restored checkout.
  - If parity passes, continue into show_issue3_saved_browser_snapshot_route.sh for the restore, restored-checkout, archive-integrity, and Linux-or-WSL follow-up ladder.
EOF
