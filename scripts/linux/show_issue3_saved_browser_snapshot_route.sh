#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_browser_snapshot_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--destination /path/to/extracted/browser-checkout] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--sync-helper-surface] \
    [--sync-only] \
    [--json]

Print the saved-browser-snapshot restore route for the blocked issue #3 Linux or
WSL re-entry path.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
PY
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_DESTINATION_NAME="browser-memory-snapshot"
DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
MEMORY_ROOT=""
ARCHIVE_PATH=""
DESTINATION=""
FALLBACK_ZIG_ARCHIVE=""
SYNC_HELPER_SURFACE=0
SYNC_ONLY=0
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
        --sync-helper-surface)
            SYNC_HELPER_SURFACE=1
            shift
            ;;
        --sync-only)
            SYNC_ONLY=1
            shift
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

if [[ "${SYNC_ONLY}" -eq 1 ]]; then
    SYNC_HELPER_SURFACE=1
fi

REPO_ROOT="$(cd "${REPO_ROOT}" && pwd)"
if [[ -z "${HELPER_ROOT}" ]]; then
    HELPER_ROOT="${REPO_ROOT}"
fi
HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory"
fi
if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${MEMORY_ROOT}/repo_archives/browser/${DEFAULT_ARCHIVE_NAME}"
fi
if [[ -z "${DESTINATION}" ]]; then
    DESTINATION="$(cd "${REPO_ROOT}/.." && pwd)/${DEFAULT_DESTINATION_NAME}"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${HELPER_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

FOLLOW_UP_HELPER_ROOT="${HELPER_ROOT}"
if [[ "${SYNC_HELPER_SURFACE}" -eq 1 ]]; then
    FOLLOW_UP_HELPER_ROOT="${DESTINATION}"
fi
SYNC_FLAG=""
if [[ "${SYNC_HELPER_SURFACE}" -eq 1 && "${SYNC_ONLY}" -eq 0 ]]; then
    SYNC_FLAG=" --sync-helper-surface"
fi
SYNC_ONLY_FLAG=""
if [[ "${SYNC_ONLY}" -eq 1 ]]; then
    SYNC_ONLY_FLAG=" --sync-only"
fi

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}")${SYNC_FLAG}${SYNC_ONLY_FLAG} --check-only"
RESTORE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}")${SYNC_FLAG}${SYNC_ONLY_FLAG}"
RESTORED_CHECKOUT_CHECK_COMMAND="python $(format_shell_arg "${FOLLOW_UP_HELPER_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${DESTINATION}")"
if [[ "${SYNC_HELPER_SURFACE}" -eq 1 ]]; then
    RESTORED_CHECKOUT_CHECK_COMMAND+=" --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
fi
SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${FOLLOW_UP_HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${DESTINATION}")"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${FOLLOW_UP_HELPER_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${DESTINATION}")"
LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${FOLLOW_UP_HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${DESTINATION}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${FOLLOW_UP_HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${DESTINATION}")"
SYNC_SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}") --sync-helper-surface --check-only"
SYNC_RESTORE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}") --sync-helper-surface"
SYNC_ONLY_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}") --sync-only --check-only"
SYNC_ONLY_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}") --sync-only"
SYNC_RESTORED_CHECKOUT_CHECK_COMMAND="python $(format_shell_arg "${DESTINATION}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${DESTINATION}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
SYNC_SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${DESTINATION}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${DESTINATION}")"
SYNC_SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${DESTINATION}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${DESTINATION}")"
SYNC_LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${DESTINATION}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${DESTINATION}")"
SYNC_RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${DESTINATION}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${DESTINATION}")"
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNC_SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNC_SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNC_LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNC_RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 saved browser snapshot restore route",
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "follow_up_helper_root": ${FOLLOW_UP_HELPER_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "archive_path": ${ARCHIVE_PATH@Q},
    "destination": ${DESTINATION@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "sync_helper_surface": ${SYNC_HELPER_SURFACE},
    "sync_only": ${SYNC_ONLY},
    "read_first": [
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
        "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    ],
    "commands": {
        "route_surface": ${ROUTE_SURFACE_COMMAND@Q},
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "restore": ${RESTORE_COMMAND@Q},
        "restored_checkout_check": ${RESTORED_CHECKOUT_CHECK_COMMAND@Q},
        "saved_memory_preflight": ${SAVED_MEMORY_PREFLIGHT_COMMAND@Q},
        "saved_archive_integrity": ${SAVED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "linux_build_route": ${LINUX_BUILD_ROUTE_COMMAND@Q},
        "runtime_route": ${RUNTIME_ROUTE_COMMAND@Q},
        "sync_surface_check": ${SYNC_SURFACE_CHECK_COMMAND@Q},
        "sync_restore": ${SYNC_RESTORE_COMMAND@Q},
        "sync_only_check": ${SYNC_ONLY_CHECK_COMMAND@Q},
        "sync_only_refresh": ${SYNC_ONLY_COMMAND@Q},
        "sync_restored_checkout_check": ${SYNC_RESTORED_CHECKOUT_CHECK_COMMAND@Q},
        "sync_saved_memory_preflight": ${SYNC_SAVED_MEMORY_PREFLIGHT_COMMAND@Q},
        "sync_saved_archive_integrity": ${SYNC_SAVED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "sync_linux_build_route": ${SYNC_LINUX_BUILD_ROUTE_COMMAND@Q},
        "sync_runtime_route": ${SYNC_RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run route_surface first so missing branch-local docs or helper drift fails fast before the restore helper is trusted.",
        "Run surface_check next so the saved archive path, top-level folder, sync mode, and follow-up commands are confirmed before extraction.",
        "Use restore only when the route really needs a disposable checkout for Linux or WSL helper validation.",
        "Run restored_checkout_check immediately after restore so missing build.zig.zon, missing helper-surface files, or helper drift fail before the archive-focused preflights.",
        "Run saved_memory_preflight against the restored checkout after the restored-checkout check and before trusting broader build-readiness or runtime helper output.",
        "Run saved_archive_integrity after the saved-memory preflight when the route needs to prove the restored checkout still points back to the exact saved repo and dependency bundles before broader staging begins.",
        "Keep helper_root pointed at the live branch-local helper surface when the restore should remain a clean historical snapshot.",
        "Use --sync-helper-surface when the restored checkout should also carry the current issue #3 helper docs and scripts.",
        "Use --sync-only when the restored checkout already exists and only the helper surface needs to be refreshed in place.",
        "Prefer the sync_* commands when the restored checkout should become its own follow-up root because the saved archive can lag the live helper surface.",
        "Use linux_build_route when the next blocked step is still toolchain or offline dependency staging.",
        "Use runtime_route only after the saved checkout exists and the route is ready to reopen the narrowed Page.zig and win32_backend.zig lane."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 saved browser snapshot restore route

Repo root:             ${REPO_ROOT}
Live helper root:      ${HELPER_ROOT}
Follow-up helper root: ${FOLLOW_UP_HELPER_ROOT}
Memory root:           ${MEMORY_ROOT}
Snapshot archive:      ${ARCHIVE_PATH}
Restore destination:   ${DESTINATION}
Fallback Zig archive:  ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Sync helper surface:   $([[ "${SYNC_HELPER_SURFACE}" -eq 1 ]] && echo enabled || echo disabled)
Sync only:             $([[ "${SYNC_ONLY}" -eq 1 ]] && echo enabled || echo disabled)

Read first
==========
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Route surface check:
    ${ROUTE_SURFACE_COMMAND}

  Restore helper surface check:
    ${SURFACE_CHECK_COMMAND}

  Restore the saved checkout:
    ${RESTORE_COMMAND}

  Recommended synced restore when the archive helper surface is stale:
    Synced restore helper surface check:
      ${SYNC_SURFACE_CHECK_COMMAND}
    Synced restore command:
      ${SYNC_RESTORE_COMMAND}
    Synced helper-surface refresh check for an existing restored checkout:
      ${SYNC_ONLY_CHECK_COMMAND}
    Synced helper-surface refresh command for an existing restored checkout:
      ${SYNC_ONLY_COMMAND}
    Synced restored-checkout readiness check:
      ${SYNC_RESTORED_CHECKOUT_CHECK_COMMAND}
    Synced saved-Memory preflight:
      ${SYNC_SAVED_MEMORY_PREFLIGHT_COMMAND}
    Synced saved-archive integrity preflight:
      ${SYNC_SAVED_ARCHIVE_INTEGRITY_COMMAND}
    Synced Linux or WSL build-readiness route:
      ${SYNC_LINUX_BUILD_ROUTE_COMMAND}
    Synced direct runtime re-entry route:
      ${SYNC_RUNTIME_ROUTE_COMMAND}

  Restored-checkout readiness check:
    ${RESTORED_CHECKOUT_CHECK_COMMAND}

  Saved-Memory preflight against the restored checkout:
    ${SAVED_MEMORY_PREFLIGHT_COMMAND}

  Saved-archive integrity preflight against the restored checkout:
    ${SAVED_ARCHIVE_INTEGRITY_COMMAND}

  Linux or WSL build-readiness route from the restored checkout:
    ${LINUX_BUILD_ROUTE_COMMAND}

  Direct runtime re-entry route from the restored checkout:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface check first so missing docs or helper drift fails fast before the restore helper is trusted.
  - Run the restore helper surface check next so the saved archive path, top-level folder, sync mode, and follow-up commands are confirmed before extraction.
  - Use the restore step when the route needs a disposable checkout for helper validation without relying on live GitHub file publication.
  - Run the restored-checkout readiness check right after restore so missing build.zig.zon, helper-surface omissions, or sync drift fail before the archive-focused preflights.
  - Prefer the recommended synced restore when the restored checkout should become its own follow-up root because the saved archive can lag the current branch-local helper surface.
  - Use the helper-surface refresh commands when the restored checkout already exists and only the branch-local docs and route scripts need to be refreshed in place.
  - Keep the live branch-local helper surface only when the restore should stay as a clean historical snapshot.
  - Use --sync-helper-surface when the restored checkout should also carry the current issue #3 helper docs and scripts.
  - Use --sync-only when the restored checkout already exists and only the helper surface needs repair.
  - Run the saved-Memory preflight against the restored checkout after the restored-checkout readiness check and before trusting broader build-readiness or runtime helper output.
  - Run the saved-archive integrity preflight after the saved-Memory preflight when the route needs to prove the repo snapshot and dependency bundles still match the expected exact saved artifacts.
  - Use the Linux or WSL build-readiness route when the next blocked step is still toolchain or offline dependency staging.
  - Reopen the direct Page.zig plus win32_backend.zig runtime lane only after the restored checkout exists and the branch-compatible validation gate is no longer the blocker.
EOF