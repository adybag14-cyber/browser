#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_full_reentry_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-browser-archives-root /path/to/memory/repo_archives/browser] \
    [--toolchains-root /path/to/toolchains] \
    [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print one compact Linux or WSL handoff for the blocked issue #3 recovery stack:
saved-browser-snapshot restore, saved-Memory preflight, archive integrity,
Zig-line recovery, saved Rust restore, offline build-input staging, Linux
build-readiness, and the final Windows runtime handoff.
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
REPO_ROOT="${DEFAULT_REPO_ROOT}"
SAVED_BROWSER_ARCHIVES_ROOT=""
TOOLCHAINS_ROOT=""
RUST_TOOLCHAIN_DIR=""
OFFLINE_DEPS_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --saved-browser-archives-root)
            SAVED_BROWSER_ARCHIVES_ROOT="$2"
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
        --offline-deps-root)
            OFFLINE_DEPS_ROOT="$2"
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
WORKSPACE_ROOT="$(cd "${REPO_ROOT}/.." && pwd)"
if [[ -z "${SAVED_BROWSER_ARCHIVES_ROOT}" ]]; then
    SAVED_BROWSER_ARCHIVES_ROOT="${WORKSPACE_ROOT}/memory/repo_archives/browser"
fi
DEPENDENCIES_ROOT="${SAVED_BROWSER_ARCHIVES_ROOT}/dependencies"
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="${WORKSPACE_ROOT}/toolchains"
fi
if [[ -z "${RUST_TOOLCHAIN_DIR}" ]]; then
    RUST_TOOLCHAIN_DIR="${TOOLCHAINS_ROOT}/rust-1.79.0"
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

SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_ROUTE_COMMAND="bash scripts/linux/show_issue3_saved_browser_snapshot_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_SYNC_ROUTE_COMMAND="${SNAPSHOT_ROUTE_COMMAND} --sync-helper-surface"
SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python scripts/check_issue3_saved_archive_integrity.py --repo-root $(format_shell_arg "${REPO_ROOT}")"
ZIG_ROUTE_COMMAND="bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${DEPENDENCIES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
SAVED_RUST_ROUTE_COMMAND="bash scripts/linux/show_issue3_saved_rust_toolchain_route.sh --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${DEPENDENCIES_ROOT}") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
OFFLINE_ROUTE_COMMAND="bash scripts/linux/show_issue3_offline_build_inputs_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${DEPENDENCIES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_BROWSER_ARCHIVES_ROOT}") --rust-toolchain-dir $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
WINDOWS_RUNTIME_SURFACE_COMMAND='powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1'
WINDOWS_RUNTIME_ROUTE_COMMAND='powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1'

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SNAPSHOT_SYNC_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_INPUTS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    OFFLINE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 full recovery route",
    "repo_root": ${REPO_ROOT@Q},
    "saved_browser_archives_root": ${SAVED_BROWSER_ARCHIVES_ROOT@Q},
    "dependencies_root": ${DEPENDENCIES_ROOT@Q},
    "toolchains_root": ${TOOLCHAINS_ROOT@Q},
    "rust_toolchain_dir": ${RUST_TOOLCHAIN_DIR@Q},
    "offline_deps_root": ${OFFLINE_DEPS_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "read_first": [
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md",
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
        "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
    ],
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "saved_browser_snapshot_route": ${SNAPSHOT_ROUTE_COMMAND@Q},
        "saved_browser_snapshot_route_synced": ${SNAPSHOT_SYNC_ROUTE_COMMAND@Q},
        "saved_memory_inputs": ${SAVED_MEMORY_INPUTS_COMMAND@Q},
        "saved_archive_integrity": ${SAVED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "zig_toolchain_route": ${ZIG_ROUTE_COMMAND@Q},
        "saved_rust_route": ${SAVED_RUST_ROUTE_COMMAND@Q},
        "offline_build_inputs_route": ${OFFLINE_ROUTE_COMMAND@Q},
        "linux_build_readiness_route": ${BUILD_ROUTE_COMMAND@Q},
        "windows_runtime_surface": ${WINDOWS_RUNTIME_SURFACE_COMMAND@Q},
        "windows_runtime_route": ${WINDOWS_RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run the surface_check command first so route drift fails fast before the run blames saved archives, offline dependencies, or the fallback Zig bundle.",
        "If no reusable checkout exists beside the workspace, use saved_browser_snapshot_route first; prefer the synced variant when the restored checkout should become its own follow-up root.",
        "Run saved_memory_inputs before saved_archive_integrity so the route proves the saved repo snapshot, blocker file, dependency bundles, and fallback Zig surface exist before deeper integrity checks start.",
        "Run zig_toolchain_route before trusting the attached Zig 0.17 fallback or any mismatched staged Zig candidate as issue #3 evidence.",
        "Run saved_rust_route and offline_build_inputs_route before broader Linux or WSL readiness when the route still depends on the saved Rust and dependency archives.",
        "Use linux_build_readiness_route as the last Linux or WSL handoff before returning to the narrower Windows runtime surface and route.",
        "Only reopen the direct Page.zig plus win32_backend.zig runtime patch after the Linux or WSL route and the reduced Windows replay stop reporting the environment as the blocker."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 full recovery route

Repo root:                   ${REPO_ROOT}
Saved browser archives root: ${SAVED_BROWSER_ARCHIVES_ROOT}
Dependencies root:           ${DEPENDENCIES_ROOT}
Toolchains root:             ${TOOLCHAINS_ROOT}
Rust toolchain dir:          ${RUST_TOOLCHAIN_DIR}
Offline deps root:           ${OFFLINE_DEPS_ROOT}
Fallback Zig archive:        ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md

Suggested route
===============
  1. Fail-fast route surface:
    ${SURFACE_CHECK_COMMAND}

  2. Restore a reusable checkout when one is still missing:
    ${SNAPSHOT_ROUTE_COMMAND}

  3. Preferred synced restore when the saved archive helper surface may be stale:
    ${SNAPSHOT_SYNC_ROUTE_COMMAND}

  4. Saved Memory preflight:
    ${SAVED_MEMORY_INPUTS_COMMAND}

  5. Saved archive integrity preflight:
    ${SAVED_ARCHIVE_INTEGRITY_COMMAND}

  6. Zig line recovery route:
    ${ZIG_ROUTE_COMMAND}

  7. Saved Rust toolchain route:
    ${SAVED_RUST_ROUTE_COMMAND}

  8. Offline build-inputs route:
    ${OFFLINE_ROUTE_COMMAND}

  9. Linux or WSL build-readiness route:
    ${BUILD_ROUTE_COMMAND}

  10. Windows runtime surface handoff:
    ${WINDOWS_RUNTIME_SURFACE_COMMAND}

  11. Windows runtime route handoff:
    ${WINDOWS_RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the fail-fast surface first so helper drift fails before the run blames saved archives, offline dependencies, or the fallback Zig bundle.
  - If no reusable checkout exists beside the workspace, run the saved-browser-snapshot route before the broader Linux or WSL routes.
  - Prefer the synced saved-browser-snapshot route when the restored checkout should become its own follow-up root because the archive can lag the live helper surface.
  - Run the saved Memory preflight before the archive-integrity check when the route depends on the saved repo snapshot and dependency bundles.
  - Run the Zig line recovery route before trusting the attached Zig 0.17 fallback or any mismatched staged Zig candidate as issue #3 evidence.
  - Run the saved Rust toolchain route and the offline build-inputs route before the broader Linux or WSL readiness route when the run still depends on saved archives.
  - Return to the Windows runtime surface and then the Windows runtime route as soon as the Linux or WSL path stops reporting the environment as the blocker.
  - Reopen the direct Page.zig plus win32_backend.zig runtime patch only after this route and the reduced Windows replay agree that the environment is ready.
EOF