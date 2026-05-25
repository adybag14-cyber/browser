#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue11_runtime_reentry_tracker_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the compact Linux/WSL environment re-entry route tracked by issue #11.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY2'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY2
}

normalize_saved_archives_root() {
    local raw_root="$1"
    if [[ -d "${raw_root}/dependencies" ]]; then
        raw_root="${raw_root}/dependencies"
    fi
    if [[ -d "${raw_root}" ]]; then
        (
            cd "${raw_root}"
            pwd
        )
        return 0
    fi
    printf '%s\n' "${raw_root}"
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
MEMORY_ROOT=""
RESTORED_CHECKOUT_ROOT=""
SAVED_ARCHIVES_ROOT=""
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
        --saved-archives-root)
            SAVED_ARCHIVES_ROOT="$2"
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
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${MEMORY_ROOT}/repo_archives/browser"
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

TRACKER_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue11_runtime_reentry_tracker_route_surface.sh"
SNAPSHOT_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
RESTORED_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_restored_checkout_reentry_route.sh"
SAVED_MEMORY_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_memory_inputs_route.sh"
SAVED_ARCHIVE_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_archive_integrity_route.sh"
ZIG_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
LINUX_BUILD_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh"

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${TRACKER_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${SNAPSHOT_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SNAPSHOT_ROUTE_SYNC_COMMAND="${SNAPSHOT_ROUTE_COMMAND} --sync-helper-surface"
RESTORED_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SAVED_MEMORY_ROUTE_COMMAND="bash $(format_shell_arg "${SAVED_MEMORY_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${REPO_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SAVED_ARCHIVE_ROUTE_COMMAND="bash $(format_shell_arg "${SAVED_ARCHIVE_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}")"
ZIG_ROUTE_COMMAND="bash $(format_shell_arg "${ZIG_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}")"
LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${LINUX_BUILD_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SNAPSHOT_ROUTE_SYNC_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY3
import json

print(json.dumps({
    "issue": "Issue #11 Linux runtime re-entry tracker route",
    "repo_root": ${REPO_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "read_first": [
        "docs/ISSUE11_LINUX_RUNTIME_REENTRY_TRACKER_ROUTE.md",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
        "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
        "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
    ],
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "saved_browser_snapshot_route": ${SNAPSHOT_ROUTE_COMMAND@Q},
        "saved_browser_snapshot_route_synced": ${SNAPSHOT_ROUTE_SYNC_COMMAND@Q},
        "restored_checkout_route": ${RESTORED_ROUTE_COMMAND@Q},
        "saved_memory_route": ${SAVED_MEMORY_ROUTE_COMMAND@Q},
        "saved_archive_route": ${SAVED_ARCHIVE_ROUTE_COMMAND@Q},
        "zig_toolchain_route": ${ZIG_ROUTE_COMMAND@Q},
        "linux_build_readiness_route": ${LINUX_BUILD_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run surface_check first so missing route files fail before the saved-checkout, archive, or toolchain lanes are blamed.",
        "Use saved_browser_snapshot_route when no reusable checkout exists yet and the restore plus first follow-up commands need to stay on one surface.",
        "Prefer saved_browser_snapshot_route_synced when the restored checkout should become its own follow-up root because the saved archive can lag the live helper surface.",
        "Use restored_checkout_route right after the snapshot route when the next question is whether the extracted checkout is safe to trust.",
        "Use saved_memory_route before raw preflights when the saved-input helper chain itself may have drifted.",
        "Use saved_archive_route before deeper Linux or WSL staging when the saved repo snapshot or dependency bundles may have changed.",
        "Use zig_toolchain_route when only the fallback Zig 0.17 bundle is visible or when multiple staged candidates need a quick 0.15.x decision.",
        "Use linux_build_readiness_route only after the restore, saved-input, archive-integrity, and Zig-line questions are already narrowed.",
        "Hand back to docs/ISSUE3_RUNTIME_REENTRY_GATES.md once the environment route stops being the blocker and the next run can honestly reopen the direct runtime patch."
    ]
}, indent=2))
PY3
    exit 0
fi

cat <<EOF
Issue #11 Linux runtime re-entry tracker route

Repo root:               ${REPO_ROOT}
Memory root:             ${MEMORY_ROOT}
Restored checkout root:  ${RESTORED_CHECKOUT_ROOT}
Saved archives root:     ${SAVED_ARCHIVES_ROOT}
Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE11_LINUX_RUNTIME_REENTRY_TRACKER_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Saved-browser-snapshot route when no reusable checkout exists yet:
    ${SNAPSHOT_ROUTE_COMMAND}

  Recommended synced saved-browser-snapshot route when the restored checkout should carry the current helper surface:
    ${SNAPSHOT_ROUTE_SYNC_COMMAND}

  Restored-checkout route:
    ${RESTORED_ROUTE_COMMAND}

  Saved Memory route:
    ${SAVED_MEMORY_ROUTE_COMMAND}

  Saved archive integrity route:
    ${SAVED_ARCHIVE_ROUTE_COMMAND}

  Zig toolchain recovery route:
    ${ZIG_ROUTE_COMMAND}

  Linux/WSL build-readiness route:
    ${LINUX_BUILD_ROUTE_COMMAND}

Working rules
=============
  - Run the surface check first so missing route files fail before the saved-checkout, archive, or toolchain lanes are blamed.
  - Use the saved-browser-snapshot route when no reusable checkout exists yet and the restore plus first follow-up commands need to stay on one surface.
  - Prefer the synced saved-browser-snapshot route when the restored checkout should become its own follow-up root because the saved archive can lag the live helper surface.
  - Use the restored-checkout route right after the snapshot route when the next question is whether the extracted checkout is safe to trust.
  - Use the saved Memory route before raw preflights when the saved-input helper chain itself may have drifted.
  - Use the saved archive integrity route before deeper Linux or WSL staging when the saved repo snapshot or dependency bundles may have changed.
  - Use the Zig toolchain recovery route when only the fallback Zig 0.17 bundle is visible or when multiple staged candidates need a quick 0.15.x decision.
  - Use the Linux/WSL build-readiness route only after the restore, saved-input, archive-integrity, and Zig-line questions are already narrowed.
  - Hand back to docs/ISSUE3_RUNTIME_REENTRY_GATES.md once the environment route stops being the blocker and the next run can honestly reopen the direct runtime patch.
EOF
