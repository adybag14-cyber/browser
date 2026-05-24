#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_self_contained_linux_bootstrap_route.sh \
    [--repo-root /path/to/live/browser-repo] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--offline-deps-root /path/to/offline-deps] \
    [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the compact self-contained Linux bootstrap route for issue #3. This
route restores a synced saved snapshot checkout and then reopens the saved
archive, offline-input, saved-Rust, Zig-line, and runtime re-entry helpers from
that restored checkout instead of splitting the route across multiple roots.
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
RESTORED_CHECKOUT_ROOT=""
SAVED_ARCHIVES_ROOT=""
OFFLINE_DEPS_ROOT=""
RUST_TOOLCHAIN_DIR=""
FALLBACK_ZIG_ARCHIVE=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
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
        --offline-deps-root)
            OFFLINE_DEPS_ROOT="$2"
            shift 2
            ;;
        --rust-toolchain-dir)
            RUST_TOOLCHAIN_DIR="$2"
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
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="${WORKSPACE_ROOT}/browser-memory-snapshot"
fi
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${WORKSPACE_ROOT}/memory/repo_archives/browser"
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="${WORKSPACE_ROOT}/offline-deps"
fi
if [[ -z "${RUST_TOOLCHAIN_DIR}" ]]; then
    RUST_TOOLCHAIN_DIR="${WORKSPACE_ROOT}/toolchains/rust-1.79.0"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${WORKSPACE_ROOT}/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_self_contained_linux_bootstrap_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
RESTORE_CHECK_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${REPO_ROOT}") --archive $(format_shell_arg "${WORKSPACE_ROOT}/memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-helper-surface --check-only"
RESTORE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${REPO_ROOT}") --archive $(format_shell_arg "${WORKSPACE_ROOT}/memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-helper-surface"
SYNC_ONLY_CHECK_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${REPO_ROOT}") --archive $(format_shell_arg "${WORKSPACE_ROOT}/memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-only --check-only"
SYNC_ONLY_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${REPO_ROOT}") --archive $(format_shell_arg "${WORKSPACE_ROOT}/memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-only"
RESTORED_CHECK_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${REPO_ROOT}") --expect-helper-surface"
SAVED_MEMORY_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SAVED_ARCHIVE_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
OFFLINE_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_offline_build_inputs_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
RUST_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh") --browser-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
ZIG_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
READINESS_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_linux_build_readiness.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --skip-zig-check --expect-saved-archives --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --expect-offline-deps --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    RESTORE_CHECK_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNC_ONLY_CHECK_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNC_ONLY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    OFFLINE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    READINESS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 self-contained Linux bootstrap route",
    "repo_root": ${REPO_ROOT@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "offline_deps_root": ${OFFLINE_DEPS_ROOT@Q},
    "rust_toolchain_dir": ${RUST_TOOLCHAIN_DIR@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "restore_check_only": ${RESTORE_CHECK_COMMAND@Q},
        "restore_synced_checkout": ${RESTORE_COMMAND@Q},
        "sync_only_check": ${SYNC_ONLY_CHECK_COMMAND@Q},
        "sync_only_refresh": ${SYNC_ONLY_COMMAND@Q},
        "restored_checkout_check": ${RESTORED_CHECK_COMMAND@Q},
        "saved_memory_preflight": ${SAVED_MEMORY_COMMAND@Q},
        "saved_archive_integrity": ${SAVED_ARCHIVE_COMMAND@Q},
        "offline_route": ${OFFLINE_ROUTE_COMMAND@Q},
        "saved_rust_route": ${RUST_ROUTE_COMMAND@Q},
        "zig_route": ${ZIG_ROUTE_COMMAND@Q},
        "readiness_check": ${READINESS_COMMAND@Q},
        "runtime_route": ${RUNTIME_ROUTE_COMMAND@Q}
    }
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 self-contained Linux bootstrap route

Live helper root:       ${REPO_ROOT}
Restored checkout root: ${RESTORED_CHECKOUT_ROOT}
Saved archives root:    ${SAVED_ARCHIVES_ROOT}
Offline deps root:      ${OFFLINE_DEPS_ROOT}
Rust toolchain dir:     ${RUST_TOOLCHAIN_DIR}
Fallback Zig archive:   ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_SELF_CONTAINED_LINUX_BOOTSTRAP_ROUTE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Synced saved-snapshot restore surface check:
    ${RESTORE_CHECK_COMMAND}

  Restore the synced saved checkout:
    ${RESTORE_COMMAND}

  If the restored checkout already exists and only its helper surface is stale:
    ${SYNC_ONLY_CHECK_COMMAND}
    ${SYNC_ONLY_COMMAND}

  Restored-checkout readiness:
    ${RESTORED_CHECK_COMMAND}

  Saved-Memory preflight from the restored checkout:
    ${SAVED_MEMORY_COMMAND}

  Saved-archive integrity check from the restored checkout:
    ${SAVED_ARCHIVE_COMMAND}

  Offline build-inputs route from the restored checkout:
    ${OFFLINE_ROUTE_COMMAND}

  Saved Rust route from the restored checkout:
    ${RUST_ROUTE_COMMAND}

  Zig-line recovery route from the restored checkout:
    ${ZIG_ROUTE_COMMAND}

  Linux or WSL readiness check before focused runtime replay:
    ${READINESS_COMMAND}

  Runtime re-entry route after the Linux gate turns green:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Prefer the synced restore path so the restored checkout carries the current helper surface before deeper replay work starts.
  - Use the sync-only refresh when the restored checkout already exists and only the helper surface has drifted.
  - Keep the archive, offline-input, Rust, Zig, and runtime helpers anchored to the restored checkout once the synced restore succeeds.
  - Treat the fallback Zig 0.17 dev archive as surfaced input only, not as honest branch validation evidence.
  - Switch from this bootstrap route to the runtime re-entry route before reopening the direct Page.zig and win32_backend.zig slice.
EOF
