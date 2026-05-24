#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash show_issue3_restored_helper_surface_sync_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--memory-root /path/to/workspace/memory] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the helper-surface sync route for the blocked issue #3 restored-checkout
path when a saved snapshot already exists and only the helper docs/scripts need
an in-place refresh via `restore_saved_browser_snapshot.sh --sync-only`.

`--restored-root` remains accepted as a compatibility alias for
`--restored-checkout-root`.
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
DEFAULT_RESTORED_CHECKOUT_NAME="browser-memory-snapshot"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
RESTORED_CHECKOUT_ROOT=""
MEMORY_ROOT=""
ARCHIVE_PATH=""
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
        --restored-root|--restored-checkout-root)
            RESTORED_CHECKOUT_ROOT="$2"
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
    RESTORED_CHECKOUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/${DEFAULT_RESTORED_CHECKOUT_NAME}"
fi
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory"
fi
if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${MEMORY_ROOT}/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${HELPER_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
STALE_SURFACE_DIAGNOSIS_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
CHECK_ONLY_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-only --check-only"
SYNC_ONLY_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-only"
FULL_SYNC_RESTORE_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-helper-surface --check-only"
FULL_SYNC_RESTORE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-helper-surface"
RESTORED_CHECK_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CHECK_ONLY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNC_ONLY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 restored helper-surface sync route",
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "archive_path": ${ARCHIVE_PATH@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "commands": {
        "route_surface": ${ROUTE_SURFACE_COMMAND@Q},
        "stale_surface_diagnosis": ${STALE_SURFACE_DIAGNOSIS_COMMAND@Q},
        "check_only_route": ${CHECK_ONLY_ROUTE_COMMAND@Q},
        "sync_only_route": ${SYNC_ONLY_ROUTE_COMMAND@Q},
        "full_sync_restore_check": ${FULL_SYNC_RESTORE_CHECK_COMMAND@Q},
        "full_sync_restore": ${FULL_SYNC_RESTORE_COMMAND@Q},
        "restored_check": ${RESTORED_CHECK_COMMAND@Q},
        "saved_memory_preflight": ${SAVED_MEMORY_PREFLIGHT_COMMAND@Q},
        "saved_archive_integrity": ${SAVED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "linux_build_route": ${LINUX_BUILD_ROUTE_COMMAND@Q},
        "runtime_route": ${RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run route_surface first so missing sync-route docs or helper gaps fail before the restored checkout is refreshed in place.",
        "Use stale_surface_diagnosis to confirm the restored checkout really needs a helper-surface repair.",
        "Use check_only_route when the run needs the exact sync-only refresh command printed before any mutation.",
        "Use sync_only_route only when the restored checkout already exists and only the helper surface needs to be refreshed.",
        "Use full_sync_restore only when sync-only cannot repair the destination because the restored checkout is missing or incomplete.",
        "Run restored_check immediately after the sync-only refresh so helper-surface drift is proven fixed before broader follow-up work.",
        "Run saved_memory_preflight after the restored-checkout helper passes.",
        "Run saved_archive_integrity next when the refreshed route still depends on the exact saved repo and dependency archives.",
        "Use linux_build_route after the refreshed restored checkout is trusted again.",
        "Use runtime_route only after the refreshed restored checkout, saved inputs, and Linux build-readiness routes are green."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 restored helper-surface sync route

Repo root:               ${REPO_ROOT}
Live helper root:        ${HELPER_ROOT}
Restored checkout root:  ${RESTORED_CHECKOUT_ROOT}
Memory root:             ${MEMORY_ROOT}
Snapshot archive:        ${ARCHIVE_PATH}
Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Route surface check:
    ${ROUTE_SURFACE_COMMAND}

  Current stale-surface diagnosis:
    ${STALE_SURFACE_DIAGNOSIS_COMMAND}

  Sync-only route in check-only mode:
    ${CHECK_ONLY_ROUTE_COMMAND}

  Sync-only helper-surface refresh:
    ${SYNC_ONLY_ROUTE_COMMAND}

  Full synced restore fallback check:
    ${FULL_SYNC_RESTORE_CHECK_COMMAND}

  Full synced restore fallback:
    ${FULL_SYNC_RESTORE_COMMAND}

  Restored-checkout verification after refresh:
    ${RESTORED_CHECK_COMMAND}

  Saved-Memory preflight against the refreshed restored checkout:
    ${SAVED_MEMORY_PREFLIGHT_COMMAND}

  Saved-archive integrity preflight against the refreshed restored checkout:
    ${SAVED_ARCHIVE_INTEGRITY_COMMAND}

  Linux or WSL build-readiness route from the refreshed restored checkout:
    ${LINUX_BUILD_ROUTE_COMMAND}

  Direct runtime re-entry route from the refreshed restored checkout:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface check first so missing sync-route docs or helper gaps fail before the restored checkout is refreshed in place.
  - Use the check-only route when the exact helper root, Memory root, snapshot archive path, and restored checkout destination need to be printed before any mutation.
  - Use the sync-only route only when the restored checkout already exists and only the helper surface needs to be refreshed.
  - Run the restored-checkout helper immediately after the sync-only refresh so helper drift is proven fixed before saved-memory or Linux build-readiness follow-up work.
  - Run the saved-Memory preflight after the restored-checkout helper passes.
  - Run the saved-archive integrity preflight next when the route still depends on the exact saved repo and dependency archives.
  - Use the Linux or WSL build-readiness route after the refreshed restored checkout is trusted again.
  - Reopen the narrowed Page.zig plus win32_backend.zig runtime lane only after the refreshed restored checkout, saved inputs, and Linux build-readiness surfaces all agree.
EOF
