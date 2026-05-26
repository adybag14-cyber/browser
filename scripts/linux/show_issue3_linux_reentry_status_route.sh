#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_linux_reentry_status_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--python /path/to/python3] \
    [--json]

Print the compact Linux or WSL re-entry status route for the blocked issue #3
runtime lane.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

resolve_path() {
    python3 - "$1" <<'PY'
import pathlib
import sys

print(pathlib.Path(sys.argv[1]).resolve())
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
PYTHON_BIN="python3"
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --python)
            PYTHON_BIN="$2"
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
PYTHON_BIN="$(resolve_path "${PYTHON_BIN}")"

ROUTE_NOTE_PATH="${REPO_ROOT}/docs/ISSUE3_LINUX_REENTRY_STATUS_ROUTE.md"
PROGRESS_TRACKER_ROUTE_PATH="${REPO_ROOT}/docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_linux_reentry_status_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --python $(format_shell_arg "${PYTHON_BIN}")"
STATUS_COMMAND="$(format_shell_arg "${PYTHON_BIN}") $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_linux_reentry_status.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
WORKSPACE_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_workspace_context_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_MEMORY_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_memory_inputs_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ZIG_RECOVERY_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
PROGRESS_TRACKER_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_progress_tracker_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 Linux re-entry status route",
    "repo_root": ${REPO_ROOT@Q},
    "python": ${PYTHON_BIN@Q},
    "route_note_path": ${ROUTE_NOTE_PATH@Q},
    "progress_tracker_route_path": ${PROGRESS_TRACKER_ROUTE_PATH@Q},
    "commands": {
        "surface_check": ${SURFACE_COMMAND@Q},
        "status_helper": ${STATUS_COMMAND@Q},
        "workspace_context_route": ${WORKSPACE_ROUTE_COMMAND@Q},
        "saved_memory_route": ${SAVED_MEMORY_ROUTE_COMMAND@Q},
        "zig_recovery_route": ${ZIG_RECOVERY_ROUTE_COMMAND@Q},
        "linux_build_readiness_route": ${BUILD_ROUTE_COMMAND@Q},
        "progress_tracker_route": ${PROGRESS_TRACKER_ROUTE_COMMAND@Q},
        "runtime_revalidation_route": ${RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run surface_check first so missing docs or helper drift fails before a scheduled run trusts the quick-status helper.",
        "Run status_helper next when the immediate question is which Linux or WSL gate is still closed right now.",
        "If the quick-status helper points at workspace context, saved Memory inputs, Zig recovery, or broader Linux build-readiness, reopen the matching route next instead of rebuilding follow-up commands by hand.",
        "Keep docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md visible when the run is still blocked in the Linux or WSL re-entry lane so issue #11 remains the practical progress-update target.",
        "Use runtime_revalidation_route only after the quick-status helper says the environment gates are green."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 Linux re-entry status route

Repo root:               ${REPO_ROOT}
Python helper:           ${PYTHON_BIN}
Route note:              ${ROUTE_NOTE_PATH}
Progress tracker route:  ${PROGRESS_TRACKER_ROUTE_PATH}

Read first
==========
  docs/ISSUE3_LINUX_REENTRY_STATUS_ROUTE.md
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_WORKSPACE_CONTEXT_ROUTE.md
  docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md

Suggested route
===============
  Surface check:
    ${SURFACE_COMMAND}

  Quick-status helper:
    ${STATUS_COMMAND}

  Workspace-context route:
    ${WORKSPACE_ROUTE_COMMAND}

  Saved-Memory route:
    ${SAVED_MEMORY_ROUTE_COMMAND}

  Zig recovery route:
    ${ZIG_RECOVERY_ROUTE_COMMAND}

  Linux or WSL build-readiness route:
    ${BUILD_ROUTE_COMMAND}

  Issue #11 progress-tracker route:
    ${PROGRESS_TRACKER_ROUTE_COMMAND}

  Direct runtime revalidation route:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the surface check first so missing docs or helper drift fails before the run trusts the quick-status helper.
  - Run the quick-status helper next when the immediate question is which Linux or WSL gate is still closed right now.
  - If the quick-status helper points at workspace context, reopen the workspace-context route before guessing shared roots by hand.
  - If the quick-status helper points at saved Memory inputs, reopen the saved-Memory route before widening back out to Zig or build-readiness work.
  - If the quick-status helper points at Zig recovery, reopen the Zig recovery route instead of blaming the runtime patch.
  - If the quick-status helper points at broader Linux or WSL build-readiness, reopen that route before trusting focused Zig output as issue-specific evidence.
  - Keep the issue #11 progress-tracker route visible while this lane is still environment-gated.
  - Use the direct runtime revalidation route only after the quick-status helper says the environment gates are green.
EOF
