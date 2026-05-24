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

Print the compact helper-surface sync route for repairing an existing restored
issue #3 checkout in place.
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
SYNC_ONLY_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-only --check-only"
SYNC_ONLY_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-only"
FULL_SYNC_RESTORE_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-helper-surface --check-only"
FULL_SYNC_RESTORE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-helper-surface"
SYNC_RESTORED_CHECKOUT_CHECK_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
SYNC_SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SYNC_SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SYNC_LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SYNC_RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SYNC_SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNC_SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNC_LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNC_RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
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
        "sync_only_check": ${SYNC_ONLY_CHECK_COMMAND@Q},
        "sync_only_refresh": ${SYNC_ONLY_COMMAND@Q},
        "full_sync_restore_check": ${FULL_SYNC_RESTORE_CHECK_COMMAND@Q},
        "full_sync_restore": ${FULL_SYNC_RESTORE_COMMAND@Q},
        "post_sync_restored_checkout_check": ${SYNC_RESTORED_CHECKOUT_CHECK_COMMAND@Q},
        "post_sync_saved_memory_preflight": ${SYNC_SAVED_MEMORY_PREFLIGHT_COMMAND@Q},
        "post_sync_saved_archive_integrity": ${SYNC_SAVED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "post_sync_linux_build_route": ${SYNC_LINUX_BUILD_ROUTE_COMMAND@Q},
        "post_sync_runtime_route": ${SYNC_RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run route_surface first so missing docs or helper commands fail before an in-place refresh is attempted.",
        "Use stale_surface_diagnosis to confirm the restored checkout really needs a helper-surface repair.",
        "Use sync_only_refresh when the restored checkout already exists and only the helper surface is stale or drifted.",
        "Use full_sync_restore only when sync-only cannot repair the destination because the restored checkout is missing or incomplete.",
        "Run post_sync_restored_checkout_check immediately after the refresh.",
        "Then rerun the saved-Memory preflight, saved-archive integrity helper, Linux build-readiness route, and direct runtime re-entry route from the repaired restored checkout."
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
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md

Suggested route
===============
  Route surface check:
    ${ROUTE_SURFACE_COMMAND}

  Current stale-surface diagnosis:
    ${STALE_SURFACE_DIAGNOSIS_COMMAND}

  Helper-surface refresh check:
    ${SYNC_ONLY_CHECK_COMMAND}

  Helper-surface refresh command:
    ${SYNC_ONLY_COMMAND}

  Full synced restore fallback check:
    ${FULL_SYNC_RESTORE_CHECK_COMMAND}

  Full synced restore fallback:
    ${FULL_SYNC_RESTORE_COMMAND}

  Post-refresh restored-checkout readiness check:
    ${SYNC_RESTORED_CHECKOUT_CHECK_COMMAND}

  Post-refresh saved-Memory preflight:
    ${SYNC_SAVED_MEMORY_PREFLIGHT_COMMAND}

  Post-refresh saved-archive integrity helper:
    ${SYNC_SAVED_ARCHIVE_INTEGRITY_COMMAND}

  Post-refresh Linux or WSL build-readiness route:
    ${SYNC_LINUX_BUILD_ROUTE_COMMAND}

  Post-refresh direct runtime re-entry route:
    ${SYNC_RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface check first so missing docs or helper commands fail before the in-place repair is trusted.
  - Use the stale-surface diagnosis command to confirm the restored checkout really needs a helper-surface refresh.
  - Prefer the helper-surface refresh command when the restored checkout already exists and only the branch-local docs or route scripts have drifted.
  - Use the full synced restore fallback only when sync-only cannot repair the destination because the restored checkout is missing, incomplete, or no longer trustworthy.
  - Run the post-refresh restored-checkout readiness check immediately after the repair.
  - Then rerun the saved-Memory preflight, the saved-archive integrity helper, the Linux build-readiness route, and the direct runtime re-entry route from the repaired restored checkout.
EOF
