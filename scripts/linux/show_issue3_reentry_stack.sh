#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_reentry_stack.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--restored-checkout-root /path/to/restored/browser-checkout] \
    [--saved-archives-root /path/to/memory/repo_archives/browser] \
    [--toolchains-root /path/to/toolchains] \
    [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \
    [--agent-files-root /path/to/workspace/agent_files] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the compact issue #3 Linux or WSL re-entry stack from saved snapshot
restore through direct runtime revalidation.
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
MEMORY_ROOT=""
RESTORED_CHECKOUT_ROOT=""
SAVED_ARCHIVES_ROOT=""
TOOLCHAINS_ROOT=""
RUST_TOOLCHAIN_DIR=""
AGENT_FILES_ROOT=""
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
        --restored-checkout-root)
            RESTORED_CHECKOUT_ROOT="$2"
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
        --rust-toolchain-dir)
            RUST_TOOLCHAIN_DIR="$2"
            shift 2
            ;;
        --agent-files-root)
            AGENT_FILES_ROOT="$2"
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
    MEMORY_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory"
fi
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/${DEFAULT_RESTORED_CHECKOUT_NAME}"
fi
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${MEMORY_ROOT}/repo_archives/browser"
fi
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
fi
if [[ -z "${RUST_TOOLCHAIN_DIR}" ]]; then
    RUST_TOOLCHAIN_DIR="${TOOLCHAINS_ROOT}/rust-1.79.0"
fi
if [[ -z "${AGENT_FILES_ROOT}" ]]; then
    AGENT_FILES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/agent_files"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${AGENT_FILES_ROOT}/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_reentry_stack_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
SNAPSHOT_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SNAPSHOT_SYNC_ROUTE_COMMAND="${SNAPSHOT_ROUTE_COMMAND} --sync-helper-surface"
RESTORED_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_restored_checkout_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
RESTORED_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_restored_checkout_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
ARCHIVE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
ARCHIVE_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_archive_integrity_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --agent-files-root $(format_shell_arg "${AGENT_FILES_ROOT}")"
OFFLINE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_offline_build_inputs_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
OFFLINE_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_offline_build_inputs_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies")"
RUST_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
RUST_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
ZIG_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
ZIG_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies")"
BUILD_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_linux_build_readiness_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --rust-toolchain-dir $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
RUNTIME_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SNAPSHOT_SYNC_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ARCHIVE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    OFFLINE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 Linux or WSL re-entry stack",
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "toolchains_root": ${TOOLCHAINS_ROOT@Q},
    "rust_toolchain_dir": ${RUST_TOOLCHAIN_DIR@Q},
    "agent_files_root": ${AGENT_FILES_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "commands": {
        "route_surface": ${ROUTE_SURFACE_COMMAND@Q},
        "snapshot_surface": ${SNAPSHOT_SURFACE_COMMAND@Q},
        "snapshot_route": ${SNAPSHOT_ROUTE_COMMAND@Q},
        "snapshot_route_synced": ${SNAPSHOT_SYNC_ROUTE_COMMAND@Q},
        "restored_surface": ${RESTORED_SURFACE_COMMAND@Q},
        "restored_route": ${RESTORED_ROUTE_COMMAND@Q},
        "archive_surface": ${ARCHIVE_SURFACE_COMMAND@Q},
        "archive_route": ${ARCHIVE_ROUTE_COMMAND@Q},
        "offline_surface": ${OFFLINE_SURFACE_COMMAND@Q},
        "offline_route": ${OFFLINE_ROUTE_COMMAND@Q},
        "rust_surface": ${RUST_SURFACE_COMMAND@Q},
        "rust_route": ${RUST_ROUTE_COMMAND@Q},
        "zig_surface": ${ZIG_SURFACE_COMMAND@Q},
        "zig_route": ${ZIG_ROUTE_COMMAND@Q},
        "build_surface": ${BUILD_SURFACE_COMMAND@Q},
        "build_route": ${BUILD_ROUTE_COMMAND@Q},
        "runtime_surface": ${RUNTIME_SURFACE_COMMAND@Q},
        "runtime_route": ${RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run route_surface first so missing branch-local docs or helper drift fails before the compact ladder is trusted.",
        "If no reusable checkout exists, use snapshot_route first and prefer snapshot_route_synced when the restored checkout should become its own helper root.",
        "Run restored_route immediately after restore so missing repo files or helper-surface drift fails before broader preflights.",
        "Run archive_route before trusting offline dependency or toolchain staging when the route still depends on the exact saved Memory bundles.",
        "Use offline_route, rust_route, and zig_route when the next blocker is still Linux or WSL staging rather than direct runtime logic.",
        "Use build_route only after the saved checkout and saved bundles are trusted.",
        "Use runtime_route only after the publication and toolchain gates are green."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 Linux or WSL re-entry stack

Repo root:               ${REPO_ROOT}
Live helper root:        ${HELPER_ROOT}
Memory root:             ${MEMORY_ROOT}
Restored checkout root:  ${RESTORED_CHECKOUT_ROOT}
Saved archives root:     ${SAVED_ARCHIVES_ROOT}
Toolchains root:         ${TOOLCHAINS_ROOT}
Rust toolchain dir:      ${RUST_TOOLCHAIN_DIR}
Agent files root:        ${AGENT_FILES_ROOT}
Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_REENTRY_STACK_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Compact route
=============
  Top-level route surface check:
    ${ROUTE_SURFACE_COMMAND}

  Saved-browser-snapshot route surface check:
    ${SNAPSHOT_SURFACE_COMMAND}

  Saved-browser-snapshot route when no reusable checkout exists yet:
    ${SNAPSHOT_ROUTE_COMMAND}

  Recommended synced saved-browser-snapshot route when the restored checkout should carry the current synced helper surface:
    ${SNAPSHOT_SYNC_ROUTE_COMMAND}

  Restored-checkout route surface check:
    ${RESTORED_SURFACE_COMMAND}

  Restored-checkout route:
    ${RESTORED_ROUTE_COMMAND}

  Saved-archive integrity route surface check:
    ${ARCHIVE_SURFACE_COMMAND}

  Saved-archive integrity route:
    ${ARCHIVE_ROUTE_COMMAND}

  Offline build-inputs route surface check:
    ${OFFLINE_SURFACE_COMMAND}

  Offline build-inputs route:
    ${OFFLINE_ROUTE_COMMAND}

  Saved Rust route surface check:
    ${RUST_SURFACE_COMMAND}

  Saved Rust route:
    ${RUST_ROUTE_COMMAND}

  Zig-line recovery route surface check:
    ${ZIG_SURFACE_COMMAND}

  Zig-line recovery route:
    ${ZIG_ROUTE_COMMAND}

  Linux or WSL build-readiness route surface check:
    ${BUILD_SURFACE_COMMAND}

  Linux or WSL build-readiness route:
    ${BUILD_ROUTE_COMMAND}

  Direct runtime revalidation surface check:
    ${RUNTIME_SURFACE_COMMAND}

  Direct runtime revalidation route:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the top-level route surface first so missing branch-local docs or helper drift fails before the compact ladder is trusted.
  - If no reusable checkout exists, start with the saved-browser-snapshot route and prefer the synced helper surface when the restored checkout should become its own helper root.
  - Run the restored-checkout route immediately after restore so missing repo files or helper-surface drift fails before broader preflights.
  - Run the saved-archive integrity route before trusting offline dependency or toolchain staging when the route still depends on the exact saved Memory bundles.
  - Use the offline build-inputs, saved Rust, and Zig-line routes when the next blocker is still Linux or WSL staging rather than direct runtime logic.
  - Use the Linux or WSL build-readiness route only after the saved checkout and saved bundles are trusted.
  - Reopen the direct Page.zig plus win32_backend.zig lane only after the publication and toolchain gates are green.
EOF
