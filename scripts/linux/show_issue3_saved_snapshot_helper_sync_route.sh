#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_snapshot_helper_sync_route.sh \
    [--repo-root /path/to/live/browser-repo] \
    [--snapshot-root /path/to/restored/browser-memory-snapshot] \
    [--json]

Print the helper-sync route that copies the newest issue #3 docs and scripts
from the live checkout into a restored saved snapshot before Linux/WSL build-
readiness or Windows runtime re-entry continues from that snapshot.
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
SNAPSHOT_ROOT=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --snapshot-root)
            SNAPSHOT_ROOT="$2"
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
if [[ -z "${SNAPSHOT_ROOT}" ]]; then
    SNAPSHOT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/browser-memory-snapshot"
fi

SYNC_CHECK_COMMAND="python scripts/sync_issue3_saved_snapshot_helpers.py --live-repo-root $(format_shell_arg "${REPO_ROOT}") --snapshot-root $(format_shell_arg "${SNAPSHOT_ROOT}") --check-only"
SYNC_COMMAND="python scripts/sync_issue3_saved_snapshot_helpers.py --live-repo-root $(format_shell_arg "${REPO_ROOT}") --snapshot-root $(format_shell_arg "${SNAPSHOT_ROOT}")"
MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root $(format_shell_arg "${SNAPSHOT_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${SNAPSHOT_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${SNAPSHOT_ROOT}")"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 saved snapshot helper sync route",
    "repo_root": ${REPO_ROOT@Q},
    "snapshot_root": ${SNAPSHOT_ROOT@Q},
    "commands": {
        "sync_check": ${SYNC_CHECK_COMMAND@Q},
        "sync": ${SYNC_COMMAND@Q},
        "saved_memory_inputs": ${MEMORY_INPUTS_COMMAND@Q},
        "linux_build_route": ${BUILD_ROUTE_COMMAND@Q},
        "runtime_reentry_route": ${RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run sync_check first to see whether the restored snapshot is missing the newer branch-local helper surface.",
        "Run sync to copy the newer route docs and helper scripts into the restored snapshot before follow-up validation.",
        "After the sync completes, run the saved_memory_inputs preflight against the restored snapshot checkout.",
        "Then print the Linux build-readiness route or the direct runtime re-entry route against that restored snapshot."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 saved snapshot helper sync route

Live repo root: ${REPO_ROOT}
Snapshot root:  ${SNAPSHOT_ROOT}

Suggested route
===============
  Check whether the restored snapshot is missing newer helper files:
    ${SYNC_CHECK_COMMAND}

  Copy the newer helper surface into the restored snapshot:
    ${SYNC_COMMAND}

  Re-run the saved Memory input preflight against the restored snapshot:
    ${MEMORY_INPUTS_COMMAND}

  Print the Linux build-readiness route against the restored snapshot:
    ${BUILD_ROUTE_COMMAND}

  Print the direct runtime re-entry route against the restored snapshot:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Use this helper after restore_saved_browser_snapshot.sh when the restored checkout came from the older saved archive and still lacks newer branch-local route helpers.
  - Keep the live repo root as the source of truth for the helper surface you want to copy into the restored snapshot.
  - Re-run the saved Memory preflight after the sync so the next route step sees the restored checkout and the saved archives together.
  - Use the Linux build-readiness route first when toolchain and offline staging are still the blocker.
  - Use the direct runtime re-entry route only after the build and publication gates are no longer the blocker.
EOF
