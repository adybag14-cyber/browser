#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue11_linux_reentry_tracker_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the compact issue #11 Linux/WSL re-entry tracker route that prepares the
next honest issue #3 runtime attempt.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
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
if [[ -z "${RUST_TOOLCHAIN_DIR}" ]]; then
    RUST_TOOLCHAIN_DIR="$(cd "${REPO_ROOT}/.." && pwd)/toolchains/rust-1.79.0"
fi
TOOLCHAINS_ROOT="$(dirname "${RUST_TOOLCHAIN_DIR}")"
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/offline-deps"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_linux_build_readiness_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
WORKSPACE_CONTEXT_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_workspace_context.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-helper-surface"
RESTORED_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_restored_checkout_reentry_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SAVED_MEMORY_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_memory_inputs_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${REPO_ROOT}")"
ARCHIVE_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_archive_integrity_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_RUST_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
ZIG_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
ZIG_MATCH_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_match.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
OFFLINE_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_offline_build_inputs_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
BUILD_READINESS_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --rust-toolchain-dir $(format_shell_arg "${RUST_TOOLCHAIN_DIR}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
WINDOWS_RUNTIME_SURFACE_COMMAND="powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
WINDOWS_RUNTIME_ROUTE_COMMAND="powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    WORKSPACE_CONTEXT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ARCHIVE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_MATCH_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    OFFLINE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_READINESS_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": 11,
    "issue_title": "Headed runtime re-entry: Linux/WSL build and toolchain readiness tracker",
    "repo_root": ${REPO_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "rust_toolchain_dir": ${RUST_TOOLCHAIN_DIR@Q},
    "toolchains_root": ${TOOLCHAINS_ROOT@Q},
    "offline_deps_root": ${OFFLINE_DEPS_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "workspace_context": ${WORKSPACE_CONTEXT_COMMAND@Q},
        "saved_snapshot_route_synced": ${SNAPSHOT_ROUTE_COMMAND@Q},
        "restored_checkout_route": ${RESTORED_ROUTE_COMMAND@Q},
        "saved_memory_route": ${SAVED_MEMORY_ROUTE_COMMAND@Q},
        "saved_archive_integrity_route": ${ARCHIVE_ROUTE_COMMAND@Q},
        "saved_rust_route": ${SAVED_RUST_ROUTE_COMMAND@Q},
        "zig_recovery_route": ${ZIG_ROUTE_COMMAND@Q},
        "zig_matching_gate": ${ZIG_MATCH_COMMAND@Q},
        "offline_build_inputs_route": ${OFFLINE_ROUTE_COMMAND@Q},
        "linux_build_readiness_route": ${BUILD_READINESS_ROUTE_COMMAND@Q},
        "windows_runtime_surface": ${WINDOWS_RUNTIME_SURFACE_COMMAND@Q},
        "windows_runtime_route": ${WINDOWS_RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Use this route for tracker issue #11 work that prepares the next honest issue #3 runtime attempt.",
        "Run the surface check first so doc or helper drift fails before any restore or staging step is trusted.",
        "Use the workspace-context helper before rebuilding overrides by hand when the checkout sits deeper than the default sibling layout.",
        "Prefer the synced saved-snapshot route when the restored checkout should become its own follow-up root with the current helper surface copied into place.",
        "Run the restored-checkout route before broader staging when a reusable restored checkout already exists or immediately after the synced restore finishes.",
        "Keep the saved-Memory route ahead of archive integrity, Rust, Zig, and offline-input staging so the basic saved-input contract is rechecked early.",
        "Treat the fallback Zig 0.17 archive as a surfaced input only, not as honest validation evidence for this branch.",
        "Reopen the Windows runtime route only after the saved-archive, Rust, Zig-line, and offline dependency gates stop being the blocker."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Issue #11 Linux/WSL Re-entry Tracker Route

Tracker:
  https://github.com/adybag14-cyber/browser/issues/11

Repo root:              ${REPO_ROOT}
Memory root:            ${MEMORY_ROOT}
Restored checkout root: ${RESTORED_CHECKOUT_ROOT}
Saved archives root:    ${SAVED_ARCHIVES_ROOT}
Rust toolchain dir:     ${RUST_TOOLCHAIN_DIR}
Toolchains root:        ${TOOLCHAINS_ROOT}
Offline deps root:      ${OFFLINE_DEPS_ROOT}
Fallback Zig archive:   ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
  docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md

Suggested route
===============
  1. Fail-fast route surface:
    ${SURFACE_CHECK_COMMAND}

  2. Workspace-context helper:
    ${WORKSPACE_CONTEXT_COMMAND}

  3. Synced saved-snapshot route:
    ${SNAPSHOT_ROUTE_COMMAND}

  4. Restored-checkout re-entry route:
    ${RESTORED_ROUTE_COMMAND}

  5. Saved-Memory route:
    ${SAVED_MEMORY_ROUTE_COMMAND}

  6. Saved-archive integrity route:
    ${ARCHIVE_ROUTE_COMMAND}

  7. Saved Rust route:
    ${SAVED_RUST_ROUTE_COMMAND}

  8. Zig recovery route:
    ${ZIG_ROUTE_COMMAND}

  9. Zig matching-line gate:
    ${ZIG_MATCH_COMMAND}

  10. Offline build-inputs route:
    ${OFFLINE_ROUTE_COMMAND}

  11. Linux/WSL build-readiness route:
    ${BUILD_READINESS_ROUTE_COMMAND}

  12. Windows runtime handoff:
    ${WINDOWS_RUNTIME_SURFACE_COMMAND}
    ${WINDOWS_RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Use this route for issue #11 work that prepares the next honest issue #3 runtime attempt.
  - Run the fail-fast route surface first so helper or note drift fails before restore, staging, or validation commands are trusted.
  - Run the workspace-context helper before rebuilding path overrides by hand when the checkout sits deeper than the default sibling layout.
  - Prefer the synced saved-snapshot route when the restored checkout should become its own follow-up root with the current helper surface copied into place.
  - Run the restored-checkout route before wider staging when a reusable restored checkout already exists or immediately after the synced restore finishes.
  - Keep the saved-Memory route ahead of archive integrity, Rust, Zig, and offline-input staging so the basic saved-input contract is rechecked early.
  - Treat the fallback Zig 0.17 archive as a surfaced input only, not as honest validation evidence for this branch.
  - Reopen the Windows runtime route only after the saved-archive, Rust, Zig-line, and offline dependency gates stop being the blocker.
EOF