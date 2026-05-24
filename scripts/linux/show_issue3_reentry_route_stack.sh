#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_reentry_route_stack.sh \
    [--repo-root /path/to/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--browser-exe /path/to/lightpanda.exe] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the compact Linux-or-WSL-first issue #3 re-entry route stack that keeps
restore, saved-archive validation, build-readiness, runtime revalidation, and
the Windows handoff on one branch-local surface.
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
MEMORY_ROOT=""
RESTORED_CHECKOUT_ROOT=""
BROWSER_EXE=""
FALLBACK_ZIG_ARCHIVE=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --memory-root)
            MEMORY_ROOT="$2"
            shift 2
            ;;
        --restored-checkout-root)
            RESTORED_CHECKOUT_ROOT="$2"
            shift 2
            ;;
        --browser-exe)
            BROWSER_EXE="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
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
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory"
fi
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/browser-memory-snapshot"
fi
if [[ -z "${BROWSER_EXE}" ]]; then
    BROWSER_EXE="${REPO_ROOT}/zig-out/bin/lightpanda.exe"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

STACK_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_reentry_route_stack_surface.sh"
SNAPSHOT_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"
SNAPSHOT_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
RESTORED_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh"
RESTORED_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_restored_checkout_reentry_route.sh"
ARCHIVE_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh"
ARCHIVE_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_archive_integrity_route.sh"
BUILD_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
BUILD_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh"
RUNTIME_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"
RUNTIME_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
WINDOWS_HANDOFF_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_windows_runtime_handoff_route.sh"
SAVED_MEMORY_INPUTS_SCRIPT="${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py"

STACK_SURFACE_COMMAND="bash $(format_shell_arg "${STACK_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_SURFACE_COMMAND="bash $(format_shell_arg "${SNAPSHOT_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${SNAPSHOT_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_SYNC_ROUTE_COMMAND="${SNAPSHOT_ROUTE_COMMAND} --sync-helper-surface"
RESTORED_SURFACE_COMMAND="bash $(format_shell_arg "${RESTORED_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
RESTORED_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
ARCHIVE_SURFACE_COMMAND="bash $(format_shell_arg "${ARCHIVE_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ARCHIVE_ROUTE_COMMAND="bash $(format_shell_arg "${ARCHIVE_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
BUILD_SURFACE_COMMAND="bash $(format_shell_arg "${BUILD_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${BUILD_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RUNTIME_SURFACE_COMMAND="bash $(format_shell_arg "${RUNTIME_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${RUNTIME_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --browser-exe $(format_shell_arg "${BROWSER_EXE}")"
WINDOWS_HANDOFF_COMMAND="bash $(format_shell_arg "${WINDOWS_HANDOFF_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --browser-exe $(format_shell_arg "${BROWSER_EXE}")"
SAVED_MEMORY_INPUTS_COMMAND="python $(format_shell_arg "${SAVED_MEMORY_INPUTS_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SNAPSHOT_SYNC_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_INPUTS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 re-entry route stack",
    "repo_root": ${REPO_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "browser_exe": ${BROWSER_EXE@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "read_first": [
        "docs/ISSUE3_REENTRY_ROUTE_STACK.md",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
        "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
    ],
    "commands": {
        "stack_surface": ${STACK_SURFACE_COMMAND@Q},
        "saved_browser_snapshot_surface": ${SNAPSHOT_SURFACE_COMMAND@Q},
        "saved_browser_snapshot_route": ${SNAPSHOT_ROUTE_COMMAND@Q},
        "saved_browser_snapshot_route_synced": ${SNAPSHOT_SYNC_ROUTE_COMMAND@Q},
        "restored_checkout_surface": ${RESTORED_SURFACE_COMMAND@Q},
        "restored_checkout_route": ${RESTORED_ROUTE_COMMAND@Q},
        "saved_memory_inputs": ${SAVED_MEMORY_INPUTS_COMMAND@Q},
        "saved_archive_surface": ${ARCHIVE_SURFACE_COMMAND@Q},
        "saved_archive_route": ${ARCHIVE_ROUTE_COMMAND@Q},
        "linux_build_surface": ${BUILD_SURFACE_COMMAND@Q},
        "linux_build_route": ${BUILD_ROUTE_COMMAND@Q},
        "linux_runtime_surface": ${RUNTIME_SURFACE_COMMAND@Q},
        "linux_runtime_route": ${RUNTIME_ROUTE_COMMAND@Q},
        "windows_runtime_handoff": ${WINDOWS_HANDOFF_COMMAND@Q}
    },
    "notes": [
        "Run stack_surface first so missing notes or helper drift fail before route selection starts.",
        "Use the saved-browser-snapshot surface and route when no reusable checkout exists yet.",
        "Prefer the synced saved-browser-snapshot route when the restored checkout should become its own follow-up root.",
        "Use the restored-checkout surface and route before trusting a reusable checkout for Linux or WSL follow-up commands.",
        "Keep the saved-Memory preflight ahead of deeper archive or build-readiness work when the route still depends on the saved repo snapshot and dependency bundles.",
        "Use the saved-archive-integrity surface and route before the Linux build-readiness helper when archive identity still matters.",
        "Treat the Linux build-readiness route as the last Linux gate before the runtime revalidation route.",
        "Use the Windows runtime handoff only after the Linux or WSL gates are green."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 re-entry route stack

Repo root:              ${REPO_ROOT}
Memory root:            ${MEMORY_ROOT}
Restored checkout root: ${RESTORED_CHECKOUT_ROOT}
Browser exe:            ${BROWSER_EXE}
Fallback Zig archive:   ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_REENTRY_ROUTE_STACK.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md

Suggested route stack
=====================
  Re-entry stack surface:
    ${STACK_SURFACE_COMMAND}

  Saved-browser-snapshot surface:
    ${SNAPSHOT_SURFACE_COMMAND}

  Saved-browser-snapshot route:
    ${SNAPSHOT_ROUTE_COMMAND}

  Recommended synced saved-browser-snapshot route:
    ${SNAPSHOT_SYNC_ROUTE_COMMAND}

  Restored-checkout surface:
    ${RESTORED_SURFACE_COMMAND}

  Restored-checkout route:
    ${RESTORED_ROUTE_COMMAND}

  Saved-Memory preflight:
    ${SAVED_MEMORY_INPUTS_COMMAND}

  Saved-archive-integrity surface:
    ${ARCHIVE_SURFACE_COMMAND}

  Saved-archive-integrity route:
    ${ARCHIVE_ROUTE_COMMAND}

  Linux build-readiness surface:
    ${BUILD_SURFACE_COMMAND}

  Linux build-readiness route:
    ${BUILD_ROUTE_COMMAND}

  Linux runtime revalidation surface:
    ${RUNTIME_SURFACE_COMMAND}

  Linux runtime revalidation route:
    ${RUNTIME_ROUTE_COMMAND}

  Windows runtime handoff:
    ${WINDOWS_HANDOFF_COMMAND}

Working rules
=============
  - Run the re-entry stack surface first so missing notes or helper drift fail before route selection starts.
  - Use the saved-browser-snapshot surface and route when no reusable checkout exists yet.
  - Prefer the synced saved-browser-snapshot route when the restored checkout should become its own follow-up root.
  - Use the restored-checkout surface and route before trusting a reusable checkout for Linux or WSL follow-up commands.
  - Keep the saved-Memory preflight ahead of deeper archive or build-readiness work when the route still depends on the saved repo snapshot and dependency bundles.
  - Use the saved-archive-integrity surface and route before the Linux build-readiness helper when archive identity still matters.
  - Treat the Linux build-readiness route as the last Linux gate before the runtime revalidation route.
  - Use the Windows runtime handoff only after the Linux or WSL gates are green.
EOF
