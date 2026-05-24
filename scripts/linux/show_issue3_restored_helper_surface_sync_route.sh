#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_restored_helper_surface_sync_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--memory-root /path/to/workspace/memory] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the restored-helper-surface sync route for the blocked issue #3 Linux or
WSL follow-up lane.
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
        --restored-checkout-root)
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
    HELPER_ROOT="${DEFAULT_REPO_ROOT}"
fi
HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/${DEFAULT_RESTORED_CHECKOUT_NAME}"
fi
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${HELPER_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_restored_helper_surface_sync_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
SYNC_CHECK_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RESTORE_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SYNC_RESTORE_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-helper-surface --check-only"
SYNC_RESTORE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-helper-surface --force"
SELF_CONTAINED_SYNC_CHECK_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SYNC_CHECK_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNC_RESTORE_CHECK_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNC_RESTORE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SELF_CONTAINED_SYNC_CHECK_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 restored helper surface sync route",
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "commands": {
        "route_surface": ${ROUTE_SURFACE_COMMAND@Q},
        "sync_check": ${SYNC_CHECK_COMMAND@Q},
        "restore_route": ${RESTORE_ROUTE_COMMAND@Q},
        "sync_restore_check": ${SYNC_RESTORE_CHECK_COMMAND@Q},
        "sync_restore": ${SYNC_RESTORE_COMMAND@Q},
        "self_contained_sync_check": ${SELF_CONTAINED_SYNC_CHECK_COMMAND@Q},
        "archive_integrity": ${ARCHIVE_INTEGRITY_COMMAND@Q},
        "build_route": ${BUILD_ROUTE_COMMAND@Q},
        "runtime_route": ${RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run route_surface first so missing docs or helper scripts fail fast before the drift check is trusted.",
        "Run sync_check next to compare the live helper root against the restored checkout helper surface.",
        "If the restored checkout is missing, switch to restore_route before trying to repair helper drift.",
        "Use sync_restore_check before forceful repair so the resolved Memory root, destination, and fallback Zig surface are visible.",
        "Use sync_restore when the restored checkout exists but helper files are missing or drifted.",
        "Run self_contained_sync_check after a synced restore so the restored checkout proves its own helper surface.",
        "Run archive_integrity after the sync turns green when the route needs to prove the saved artifacts still match the expected copies.",
        "Use build_route when the next blocker is still Linux or WSL toolchain staging.",
        "Use runtime_route only after helper sync is green and the narrowed Page.zig plus win32_backend.zig route is the real next lane."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 restored helper surface sync route

Repo root:               ${REPO_ROOT}
Live helper root:        ${HELPER_ROOT}
Restored checkout root:  ${RESTORED_CHECKOUT_ROOT}
Memory root:             ${MEMORY_ROOT}
Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_RESTORED_HELPER_SURFACE_SYNC_ROUTE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Route surface check:
    ${ROUTE_SURFACE_COMMAND}

  Compare the live helper root against the restored checkout:
    ${SYNC_CHECK_COMMAND}

  If the restored checkout is missing, go back to the restore route:
    ${RESTORE_ROUTE_COMMAND}

  If the restored checkout exists but helper files are stale, preview the synced repair:
    ${SYNC_RESTORE_CHECK_COMMAND}

  Repair the restored checkout helper surface:
    ${SYNC_RESTORE_COMMAND}

  Re-check the restored checkout as a self-contained helper root:
    ${SELF_CONTAINED_SYNC_CHECK_COMMAND}

  Continue with the restored checkout follow-up ladder:
    ${ARCHIVE_INTEGRITY_COMMAND}
    ${BUILD_ROUTE_COMMAND}
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface check first so missing docs or helper scripts fail fast before the drift check is trusted.
  - Use the sync check to compare the live helper root against the restored checkout helper surface.
  - If the restored checkout is missing, switch back to the saved-browser-snapshot restore route instead of treating that as helper drift.
  - Use the synced restore repair path when helper files are missing or drifted.
  - Re-check the restored checkout as its own helper root after the synced restore so future runs can trust its local helper surface.
  - Use the archive-integrity check after helper sync turns green when exact saved artifacts matter.
  - Use the Linux or WSL build-readiness route only after the helper surface is synced.
  - Reopen the narrowed Page.zig plus win32_backend.zig runtime lane only after helper sync is green and the publication and toolchain gates are also open.
EOF
