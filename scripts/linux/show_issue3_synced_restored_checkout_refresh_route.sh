#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_synced_restored_checkout_refresh_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--memory-root /path/to/workspace/memory] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the synced restored-checkout refresh route for the blocked issue #3 Linux
or WSL path when the saved checkout already exists and only the helper surface
needs to be refreshed in place.
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

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_RESTORED_CHECKOUT_NAME="browser-memory-snapshot"
DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
RESTORED_CHECKOUT_ROOT=""
MEMORY_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
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
        --restored-checkout-root|--restored-root)
            RESTORED_CHECKOUT_ROOT="$2"
            shift 2
            ;;
        --memory-root)
            MEMORY_ROOT="$2"
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
if [[ -z "${HELPER_ROOT}" ]]; then
    HELPER_ROOT="${REPO_ROOT}"
fi
HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "${DEFAULT_RESTORED_CHECKOUT_NAME}")"
fi
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "memory")"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    DEFAULT_AGENT_FILES_ROOT="$(resolve_workspace_companion_path "${HELPER_ROOT}" "agent_files")"
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${DEFAULT_AGENT_FILES_ROOT}/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_synced_restored_checkout_refresh_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
REFRESH_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-only --check-only"
REFRESH_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-only"
RESTORED_CHECKOUT_CHECK_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
REENTRY_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_restored_checkout_reentry_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --expect-helper-surface"
LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    REENTRY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 synced restored-checkout refresh route",
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "commands": {
        "route_surface": ${ROUTE_SURFACE_COMMAND@Q},
        "refresh_surface": ${REFRESH_SURFACE_COMMAND@Q},
        "refresh": ${REFRESH_COMMAND@Q},
        "restored_checkout_check": ${RESTORED_CHECKOUT_CHECK_COMMAND@Q},
        "saved_memory_preflight": ${SAVED_MEMORY_PREFLIGHT_COMMAND@Q},
        "saved_archive_integrity": ${SAVED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "reentry_route": ${REENTRY_ROUTE_COMMAND@Q},
        "linux_build_route": ${LINUX_BUILD_ROUTE_COMMAND@Q},
        "runtime_route": ${RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run route_surface first so missing docs or helper drift fails before --sync-only is trusted.",
        "Run refresh_surface next so the helper root, destination, and follow-up commands are confirmed without mutating the restored checkout.",
        "Use refresh only when the restored checkout already exists and the helper surface alone is stale.",
        "Run restored_checkout_check immediately after refresh so missing helper files or helper-root drift fail before broader staging.",
        "Run saved_memory_preflight after the refreshed restored-checkout check.",
        "Run saved_archive_integrity next when the route needs to prove the restored checkout still points back to the expected saved repo and dependency bundles.",
        "Use reentry_route when the refreshed restored checkout should stay the main follow-up root.",
        "Use linux_build_route when the next blocker is still toolchain or offline dependency staging.",
        "Use runtime_route only after the refreshed helper surface and the build-readiness gate agree that the environment is ready."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 synced restored-checkout refresh route

Repo root:               ${REPO_ROOT}
Live helper root:        ${HELPER_ROOT}
Restored checkout root:  ${RESTORED_CHECKOUT_ROOT}
Memory root:             ${MEMORY_ROOT}
Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_SYNCED_RESTORED_CHECKOUT_REFRESH_ROUTE.md
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Route surface check:
    ${ROUTE_SURFACE_COMMAND}

  Refresh helper surface check:
    ${REFRESH_SURFACE_COMMAND}

  Refresh helper surface in place:
    ${REFRESH_COMMAND}

  Refreshed restored-checkout readiness check:
    ${RESTORED_CHECKOUT_CHECK_COMMAND}

  Refreshed saved-Memory preflight:
    ${SAVED_MEMORY_PREFLIGHT_COMMAND}

  Refreshed saved-archive integrity preflight:
    ${SAVED_ARCHIVE_INTEGRITY_COMMAND}

  Refreshed restored-checkout re-entry route:
    ${REENTRY_ROUTE_COMMAND}

  Linux or WSL build-readiness route from the refreshed restored checkout:
    ${LINUX_BUILD_ROUTE_COMMAND}

  Direct runtime re-entry route from the refreshed restored checkout:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface check first so missing docs or helper drift fails fast before the helper refresh is trusted.
  - Run the helper refresh surface check next so the helper root, destination, and follow-up commands are confirmed without mutating the restored checkout.
  - Use the refresh step only when the restored checkout already exists and only the helper surface is stale.
  - Run the refreshed restored-checkout readiness check right after the refresh so missing helper files or helper-root drift fail before broader staging.
  - Run the saved-Memory preflight against the refreshed restored checkout after the restored-checkout check.
  - Run the saved-archive integrity preflight after the saved-Memory preflight when the route needs to prove the repo snapshot and dependency bundles still match the expected exact saved artifacts.
  - Use the refreshed restored-checkout re-entry route when the restored checkout should stay the main follow-up root.
  - Use the Linux or WSL build-readiness route when the next blocked step is still toolchain or offline dependency staging.
  - Reopen the direct Page.zig plus win32_backend.zig runtime lane only after the refreshed helper surface and the build-readiness gate agree that the environment is ready.
EOF
