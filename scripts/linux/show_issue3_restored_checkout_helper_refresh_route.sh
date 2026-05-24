#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_restored_checkout_helper_refresh_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--destination /path/to/extracted/browser-checkout] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the in-place helper-refresh route for the blocked issue #3 Linux or WSL
path when the restored checkout already exists and only the newer helper
surface needs to be synced into that checkout.
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
DEFAULT_DESTINATION_NAME="browser-memory-snapshot"
DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
MEMORY_ROOT=""
DESTINATION=""
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
        --memory-root)
            MEMORY_ROOT="$2"
            shift 2
            ;;
        --destination)
            DESTINATION="$2"
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
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "memory")"
fi
if [[ -z "${DESTINATION}" ]]; then
    DESTINATION="$(resolve_workspace_companion_path "${REPO_ROOT}" "${DEFAULT_DESTINATION_NAME}")"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    DEFAULT_AGENT_FILES_ROOT="$(resolve_workspace_companion_path "${HELPER_ROOT}" "agent_files")"
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${DEFAULT_AGENT_FILES_ROOT}/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_restored_checkout_helper_refresh_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
REFRESH_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${DESTINATION}") --sync-only --check-only"
REFRESH_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${DESTINATION}") --sync-only"
RESTORED_CHECKOUT_CHECK_COMMAND="python $(format_shell_arg "${DESTINATION}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${DESTINATION}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${DESTINATION}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${DESTINATION}")"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${DESTINATION}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${DESTINATION}")"
LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${DESTINATION}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${DESTINATION}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${DESTINATION}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${DESTINATION}")"
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 restored-checkout helper-refresh route",
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "destination": ${DESTINATION@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "read_first": [
        "docs/ISSUE3_RESTORED_CHECKOUT_HELPER_REFRESH_ROUTE.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    ],
    "commands": {
        "route_surface": ${ROUTE_SURFACE_COMMAND@Q},
        "refresh_check": ${REFRESH_CHECK_COMMAND@Q},
        "refresh": ${REFRESH_COMMAND@Q},
        "restored_checkout_check": ${RESTORED_CHECKOUT_CHECK_COMMAND@Q},
        "saved_memory_preflight": ${SAVED_MEMORY_PREFLIGHT_COMMAND@Q},
        "saved_archive_integrity": ${SAVED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "linux_build_route": ${LINUX_BUILD_ROUTE_COMMAND@Q},
        "runtime_route": ${RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run route_surface first so missing helper-refresh docs or helper drift fails fast before the sync-only route is trusted.",
        "Run refresh_check next so the destination, helper root, and sync-only follow-up commands are confirmed before mutating the restored checkout.",
        "Use refresh only when the restored checkout already exists and only the branch-local issue #3 helper surface needs to be refreshed in place.",
        "Run restored_checkout_check immediately after refresh so helper-surface drift and missing browser repo surfaces fail before the saved-Memory preflight.",
        "Run saved_memory_preflight next so missing Memory archives or fallback Zig inputs fail before deeper Linux or WSL staging.",
        "Run saved_archive_integrity after the saved-Memory preflight when the route still depends on the exact saved repo and dependency bundles.",
        "Use linux_build_route when the next blocker is still toolchain or offline dependency readiness after the helper refresh.",
        "Use runtime_route only after the refreshed restored checkout and build-readiness route agree that the narrowed Page.zig and win32_backend.zig lane can reopen."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 restored-checkout helper-refresh route

Repo root:             ${REPO_ROOT}
Helper root:           ${HELPER_ROOT}
Memory root:           ${MEMORY_ROOT}
Restored checkout:     ${DESTINATION}
Fallback Zig archive:  ${FALLBACK_ZIG_ARCHIVE:-not found beside the workspace}

Read first:
  - docs/ISSUE3_RESTORED_CHECKOUT_HELPER_REFRESH_ROUTE.md
  - docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  - docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  - docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Route surface check:
  ${ROUTE_SURFACE_COMMAND}

Helper-refresh dry run:
  ${REFRESH_CHECK_COMMAND}

Helper-refresh command:
  ${REFRESH_COMMAND}

Restored-checkout readiness check:
  ${RESTORED_CHECKOUT_CHECK_COMMAND}

Saved-Memory preflight against the refreshed restored checkout:
  ${SAVED_MEMORY_PREFLIGHT_COMMAND}

Saved-archive integrity preflight against the refreshed restored checkout:
  ${SAVED_ARCHIVE_INTEGRITY_COMMAND}

Linux or WSL build-readiness route from the refreshed restored checkout:
  ${LINUX_BUILD_ROUTE_COMMAND}

Direct runtime re-entry route from the refreshed restored checkout:
  ${RUNTIME_ROUTE_COMMAND}
EOF
