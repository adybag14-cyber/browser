#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_helper_surface_sync_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--destination /path/to/extracted/browser-checkout] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the issue #3 helper-surface sync recovery route for an existing restored
checkout that only needs branch-local docs and scripts refreshed in place.
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
DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"
DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
MEMORY_ROOT=""
ARCHIVE_PATH=""
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
        --archive)
            ARCHIVE_PATH="$2"
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
if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${MEMORY_ROOT}/repo_archives/browser/${DEFAULT_ARCHIVE_NAME}"
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

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_helper_surface_sync_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
SYNC_ONLY_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}") --sync-only --check-only"
SYNC_ONLY_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}") --sync-only"
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
    "issue": "Google issue #3 helper-surface sync recovery route",
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "archive_path": ${ARCHIVE_PATH@Q},
    "destination": ${DESTINATION@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "read_first": [
        "docs/ISSUE3_HELPER_SURFACE_SYNC_RECOVERY.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    ],
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "sync_only_check": ${SYNC_ONLY_CHECK_COMMAND@Q},
        "sync_only_refresh": ${SYNC_ONLY_COMMAND@Q},
        "restored_checkout_check": ${RESTORED_CHECKOUT_CHECK_COMMAND@Q},
        "saved_memory_preflight": ${SAVED_MEMORY_PREFLIGHT_COMMAND@Q},
        "saved_archive_integrity": ${SAVED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "linux_build_route": ${LINUX_BUILD_ROUTE_COMMAND@Q},
        "runtime_route": ${RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run surface_check first so missing route notes or helper scripts fail before sync-only refresh is trusted.",
        "Run sync_only_check next so the restore helper confirms the existing checkout path and follow-up commands before copying files.",
        "Use sync_only_refresh when the restored checkout already exists and only the branch-local helper surface needs repair.",
        "Run restored_checkout_check immediately after refresh so missing helper files or a broken checkout fail before deeper recovery steps.",
        "Run saved_memory_preflight after the restored-checkout check and before Linux or WSL staging is trusted.",
        "Run saved_archive_integrity when the route still depends on the exact saved repo and dependency bundles.",
        "Use linux_build_route only when the next blocker is still toolchain or offline dependency staging.",
        "Use runtime_route only after the refreshed checkout passes the restored-checkout and saved-Memory checks."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 helper-surface sync recovery route

Repo root:             ${REPO_ROOT}
Live helper root:      ${HELPER_ROOT}
Memory root:           ${MEMORY_ROOT}
Snapshot archive:      ${ARCHIVE_PATH}
Restore destination:   ${DESTINATION}
Fallback Zig archive:  ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_HELPER_SURFACE_SYNC_RECOVERY.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Route surface check:
    ${SURFACE_CHECK_COMMAND}

  Sync-only helper surface refresh check:
    ${SYNC_ONLY_CHECK_COMMAND}

  Sync-only helper surface refresh command:
    ${SYNC_ONLY_COMMAND}

  Restored-checkout readiness check:
    ${RESTORED_CHECKOUT_CHECK_COMMAND}

  Saved-Memory preflight against the refreshed checkout:
    ${SAVED_MEMORY_PREFLIGHT_COMMAND}

  Saved-archive integrity preflight against the refreshed checkout:
    ${SAVED_ARCHIVE_INTEGRITY_COMMAND}

  Linux or WSL build-readiness route from the refreshed checkout:
    ${LINUX_BUILD_ROUTE_COMMAND}

  Direct runtime re-entry route from the refreshed checkout:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface check first so missing docs or helper scripts fail before sync-only recovery is trusted.
  - Run the sync-only helper surface refresh check next so the restore helper confirms the existing checkout path before copying files.
  - Use the sync-only refresh command only when the restored checkout already exists and still looks like a browser checkout.
  - Run the restored-checkout readiness check immediately after refresh so missing helper files or a broken checkout fail before deeper recovery steps.
  - Run the saved-Memory preflight after the restored-checkout check and before Linux or WSL staging is trusted.
  - Run the saved-archive integrity preflight when the route still depends on the exact saved repo and dependency bundles.
  - Reopen Linux or WSL build-readiness only after the refreshed checkout passes the restored-checkout and saved-Memory checks.
  - Reopen the direct Page.zig plus win32_backend.zig runtime lane only after the refreshed checkout passes the same follow-up checks.
EOF
