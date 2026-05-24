#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_reentry_bundle.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--destination /path/to/restored/browser-checkout] \
    [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
    [--toolchains-root /path/to/toolchains] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--sync-helper-surface] \
    [--json]

Print one compact Linux or WSL re-entry route for the blocked headed issue #3
lane so future runs can replay the saved-memory, restore, Rust, Zig, offline
build-input, build-readiness, and direct runtime helper surfaces in one place.
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
DEFAULT_DESTINATION_NAME="browser-memory-snapshot"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
MEMORY_ROOT=""
DESTINATION=""
SAVED_ARCHIVES_ROOT=""
TOOLCHAINS_ROOT=""
OFFLINE_DEPS_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
SYNC_HELPER_SURFACE=0
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
        --saved-archives-root)
            SAVED_ARCHIVES_ROOT="$2"
            shift 2
            ;;
        --toolchains-root)
            TOOLCHAINS_ROOT="$2"
            shift 2
            ;;
        --offline-deps-root)
            OFFLINE_DEPS_ROOT="$2"
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
WORKSPACE_ROOT="$(cd "${REPO_ROOT}/.." && pwd)"
if [[ -z "${HELPER_ROOT}" ]]; then
    HELPER_ROOT="${REPO_ROOT}"
fi
HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="${WORKSPACE_ROOT}/memory"
fi
if [[ -z "${DESTINATION}" ]]; then
    DESTINATION="${WORKSPACE_ROOT}/${DEFAULT_DESTINATION_NAME}"
fi
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${MEMORY_ROOT}/repo_archives/browser/dependencies"
fi
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="${WORKSPACE_ROOT}/toolchains"
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="${WORKSPACE_ROOT}/offline-deps"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${WORKSPACE_ROOT}/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

SYNC_FLAG=""
if [[ "${SYNC_HELPER_SURFACE}" -eq 1 ]]; then
    SYNC_FLAG=" --sync-helper-surface"
fi

SAVED_MEMORY_INPUTS_COMMAND="python ${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_BROWSER_ROUTE_COMMAND="bash ${HELPER_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${DESTINATION}")${SYNC_FLAG}"
SAVED_RUST_ROUTE_COMMAND="bash ${HELPER_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchain-parent $(format_shell_arg "${TOOLCHAINS_ROOT}")"
ZIG_ROUTE_COMMAND="bash ${HELPER_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
OFFLINE_INPUTS_ROUTE_COMMAND="bash ${HELPER_ROOT}/scripts/linux/show_issue3_offline_build_inputs_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
LINUX_BUILD_READINESS_ROUTE_COMMAND="bash ${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
RUNTIME_REENTRY_ROUTE_COMMAND="bash ${HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_INPUTS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    OFFLINE_INPUTS_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_READINESS_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_REENTRY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 Linux or WSL re-entry bundle",
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "destination": ${DESTINATION@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "toolchains_root": ${TOOLCHAINS_ROOT@Q},
    "offline_deps_root": ${OFFLINE_DEPS_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "sync_helper_surface": ${SYNC_HELPER_SURFACE},
    "commands": {
        "saved_memory_inputs": ${SAVED_MEMORY_INPUTS_COMMAND@Q},
        "saved_browser_snapshot_route": ${SAVED_BROWSER_ROUTE_COMMAND@Q},
        "saved_rust_toolchain_route": ${SAVED_RUST_ROUTE_COMMAND@Q},
        "zig_toolchain_recovery_route": ${ZIG_ROUTE_COMMAND@Q},
        "offline_build_inputs_route": ${OFFLINE_INPUTS_ROUTE_COMMAND@Q},
        "linux_build_readiness_route": ${LINUX_BUILD_READINESS_ROUTE_COMMAND@Q},
        "runtime_reentry_route": ${RUNTIME_REENTRY_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run the saved-memory preflight first so missing saved inputs fail before restore or toolchain work starts.",
        "Use the saved-browser-snapshot route next when the run still lacks a reusable checkout for Linux or WSL follow-up work.",
        "Prefer --sync-helper-surface when the restored checkout should become its own follow-up root because the saved archive can lag the live helper surface.",
        "Use the saved Rust and Zig routes before trusting any focused Zig result from the blocked runtime lane.",
        "Run the offline build-inputs route before the broader Linux build-readiness route when sibling dependency staging is still missing.",
        "Reopen the direct runtime route only after the saved inputs, checkout, toolchain, and offline dependency surfaces stop being the blocker."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 Linux or WSL re-entry bundle

Repo root:            ${REPO_ROOT}
Helper root:          ${HELPER_ROOT}
Memory root:          ${MEMORY_ROOT}
Restore destination:  ${DESTINATION}
Saved archives root:  ${SAVED_ARCHIVES_ROOT}
Toolchains root:      ${TOOLCHAINS_ROOT}
Offline deps root:    ${OFFLINE_DEPS_ROOT}
Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Sync helper surface:  $([[ "${SYNC_HELPER_SURFACE}" -eq 1 ]] && echo enabled || echo disabled)

Read first
==========
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md

Suggested route
===============
  1. Saved Memory preflight:
    ${SAVED_MEMORY_INPUTS_COMMAND}

  2. Saved browser snapshot route:
    ${SAVED_BROWSER_ROUTE_COMMAND}

  3. Saved Rust toolchain route:
    ${SAVED_RUST_ROUTE_COMMAND}

  4. Zig toolchain recovery route:
    ${ZIG_ROUTE_COMMAND}

  5. Offline build-inputs route:
    ${OFFLINE_INPUTS_ROUTE_COMMAND}

  6. Linux build-readiness route:
    ${LINUX_BUILD_READINESS_ROUTE_COMMAND}

  7. Direct runtime re-entry route:
    ${RUNTIME_REENTRY_ROUTE_COMMAND}

Working rules
=============
  - Run the saved-memory preflight first so missing saved inputs fail before restore or toolchain work starts.
  - Use the saved-browser-snapshot route next when the run still lacks a reusable checkout for Linux or WSL follow-up work.
  - Prefer --sync-helper-surface when the restored checkout should become its own follow-up root because the saved archive can lag the live helper surface.
  - Use the saved Rust and Zig routes before trusting any focused Zig result from the blocked runtime lane.
  - Run the offline build-inputs route before the broader Linux build-readiness route when sibling dependency staging is still missing.
  - Reopen the direct runtime route only after the saved inputs, checkout, toolchain, and offline dependency surfaces stop being the blocker.
EOF
