#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_runtime_reentry_gates_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--memory-checker /path/to/check_issue3_saved_memory_inputs.py] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--zig /path/to/zig] \
    [--json]

Print the compact issue #3 runtime re-entry gate route around
scripts/check_issue3_runtime_reentry_gates.py and its adjacent recovery paths.
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
TOOLCHAINS_ROOT=""
MEMORY_CHECKER=""
RESTORED_CHECKOUT_ROOT=""
ZIG_CMD="zig"
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --toolchains-root)
            TOOLCHAINS_ROOT="$2"
            shift 2
            ;;
        --memory-checker)
            MEMORY_CHECKER="$2"
            shift 2
            ;;
        --restored-checkout-root)
            RESTORED_CHECKOUT_ROOT="$2"
            shift 2
            ;;
        --zig)
            ZIG_CMD="$2"
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
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
fi
if [[ -z "${MEMORY_CHECKER}" ]]; then
    MEMORY_CHECKER="${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py"
fi
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/browser-memory-snapshot"
fi

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_runtime_reentry_gates_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
GATE_CHECK_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_runtime_reentry_gates.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --memory-checker $(format_shell_arg "${MEMORY_CHECKER}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --zig $(format_shell_arg "${ZIG_CMD}")"
RESTORE_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ZIG_RECOVERY_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 runtime re-entry gate route",
    "repo_root": ${REPO_ROOT@Q},
    "toolchains_root": ${TOOLCHAINS_ROOT@Q},
    "memory_checker": ${MEMORY_CHECKER@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "zig": ${ZIG_CMD@Q},
    "read_first": [
        "docs/ISSUE3_RUNTIME_REENTRY_GATE_ROUTE.md",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
    ],
    "commands": {
        "route_surface": ${ROUTE_SURFACE_COMMAND@Q},
        "gate_check": ${GATE_CHECK_COMMAND@Q},
        "restore_route": ${RESTORE_ROUTE_COMMAND@Q},
        "zig_recovery_route": ${ZIG_RECOVERY_ROUTE_COMMAND@Q},
        "build_route": ${BUILD_ROUTE_COMMAND@Q},
        "runtime_route": ${RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run route_surface first so missing route files or stale command surfaces fail fast.",
        "Run gate_check next so the publication and toolchain status comes from the branch-local checker rather than guesswork.",
        "If gate_check says the publication gate is still closed, reopen the restore_route before trying the direct runtime patch again.",
        "If gate_check says the toolchain gate is still closed, reopen the zig_recovery_route before trusting focused runtime validation.",
        "If restore and toolchain recovery are no longer the blocker, use build_route for the remaining Linux or WSL staging path.",
        "Use runtime_route only after gate_check passes."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 runtime re-entry gate route

Repo root:              ${REPO_ROOT}
Toolchains root:        ${TOOLCHAINS_ROOT}
Saved-memory checker:   ${MEMORY_CHECKER}
Restored checkout root: ${RESTORED_CHECKOUT_ROOT}
Zig command:            ${ZIG_CMD}

Read first
==========
  docs/ISSUE3_RUNTIME_REENTRY_GATE_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md

Suggested route
===============
  Route surface:
    ${ROUTE_SURFACE_COMMAND}

  Gate check:
    ${GATE_CHECK_COMMAND}

  Saved-browser restore route when the publication gate is still closed:
    ${RESTORE_ROUTE_COMMAND}

  Zig recovery route when the toolchain gate is still closed:
    ${ZIG_RECOVERY_ROUTE_COMMAND}

  Linux build-readiness route when restore or Zig recovery already happened:
    ${BUILD_ROUTE_COMMAND}

  Runtime revalidation route after the gates pass:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface first so missing helpers or stale route notes fail fast.
  - Run the gate check next so publication and toolchain status comes from the branch-local checker.
  - If the gate check keeps the publication gate closed, reopen the saved-browser restore route before retrying the direct runtime patch.
  - If the gate check keeps the toolchain gate closed, reopen the Zig recovery route before trusting focused runtime validation.
  - If restore and toolchain recovery are no longer the blocker, use the Linux build-readiness route before the final runtime handoff.
  - Use the runtime revalidation route only after the gate check passes.
EOF
