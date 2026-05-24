#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_memory_recovery_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print one compact Linux or WSL recovery route for the blocked issue #3 path
when the next run needs to reopen work from the saved Memory repo snapshot,
dependency archives, and helper surface before touching the direct runtime
files again.
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
WORKSPACE_ROOT="$(cd "${REPO_ROOT}/.." && pwd)"
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="${WORKSPACE_ROOT}/browser-memory-snapshot"
fi
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${WORKSPACE_ROOT}/memory/repo_archives/browser"
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${RUST_TOOLCHAIN_DIR}" ]]; then
    RUST_TOOLCHAIN_DIR="${WORKSPACE_ROOT}/toolchains/rust-1.79.0"
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

SURFACE_CHECK_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
SNAPSHOT_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
RESTORED_CHECKOUT_HELPER="${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_restored_checkout.py"
SAVED_MEMORY_INPUTS_HELPER="${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_memory_inputs.py"
SAVED_ARCHIVE_INTEGRITY_HELPER="${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_archive_integrity.py"
SAVED_RUST_ROUTE_SCRIPT="${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
OFFLINE_ROUTE_SCRIPT="${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_offline_build_inputs_route.sh"
TOOLCHAIN_ROUTE_SCRIPT="${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
BUILD_ROUTE_SCRIPT="${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh"
RUNTIME_ROUTE_SCRIPT="${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${SURFACE_CHECK_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${SNAPSHOT_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-helper-surface"
RESTORED_CHECKOUT_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_HELPER}") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${REPO_ROOT}") --expect-helper-surface"
SAVED_MEMORY_INPUTS_COMMAND="python $(format_shell_arg "${SAVED_MEMORY_INPUTS_HELPER}") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${SAVED_ARCHIVE_INTEGRITY_HELPER}") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SAVED_RUST_ROUTE_COMMAND="bash $(format_shell_arg "${SAVED_RUST_ROUTE_SCRIPT}") --browser-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
OFFLINE_ROUTE_COMMAND="bash $(format_shell_arg "${OFFLINE_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
TOOLCHAIN_ROUTE_COMMAND="bash $(format_shell_arg "${TOOLCHAIN_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${BUILD_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --rust-toolchain-dir $(format_shell_arg "${RUST_TOOLCHAIN_DIR}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${RUNTIME_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_INPUTS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    OFFLINE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    TOOLCHAIN_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Google issue #3 saved-memory recovery route")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "restored_checkout_root": %s,\n' "$(json_escape "${RESTORED_CHECKOUT_ROOT}")"
    printf '  "saved_archives_root": %s,\n' "$(json_escape "${SAVED_ARCHIVES_ROOT}")"
    printf '  "rust_toolchain_dir": %s,\n' "$(json_escape "${RUST_TOOLCHAIN_DIR}")"
    printf '  "offline_deps_root": %s,\n' "$(json_escape "${OFFLINE_DEPS_ROOT}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "read_first": [\n'
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md")"
    printf '    %s\n' "$(json_escape "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md")"
    printf '  ],\n'
    printf '  "commands": {\n'
    printf '    "surface_check": %s,\n' "$(json_escape "${SURFACE_CHECK_COMMAND}")"
    printf '    "snapshot_route": %s,\n' "$(json_escape "${SNAPSHOT_ROUTE_COMMAND}")"
    printf '    "restored_checkout": %s,\n' "$(json_escape "${RESTORED_CHECKOUT_COMMAND}")"
    printf '    "saved_memory_inputs": %s,\n' "$(json_escape "${SAVED_MEMORY_INPUTS_COMMAND}")"
    printf '    "saved_archive_integrity": %s,\n' "$(json_escape "${SAVED_ARCHIVE_INTEGRITY_COMMAND}")"
    printf '    "saved_rust_route": %s,\n' "$(json_escape "${SAVED_RUST_ROUTE_COMMAND}")"
    printf '    "offline_route": %s,\n' "$(json_escape "${OFFLINE_ROUTE_COMMAND}")"
    printf '    "toolchain_route": %s,\n' "$(json_escape "${TOOLCHAIN_ROUTE_COMMAND}")"
    printf '    "build_route": %s,\n' "$(json_escape "${BUILD_ROUTE_COMMAND}")"
    printf '    "runtime_route": %s\n' "$(json_escape "${RUNTIME_ROUTE_COMMAND}")"
    printf '  },\n'
    printf '  "notes": [\n'
    printf '    %s,\n' "$(json_escape "Run surface_check first so helper drift on the live branch fails before the restore route is trusted.")"
    printf '    %s,\n' "$(json_escape "The snapshot_route command prefers a synced helper surface so the restored checkout becomes its own follow-up root instead of inheriting an older archive-only helper set.")"
    printf '    %s,\n' "$(json_escape "Run restored_checkout immediately after restore so checkout drift fails before saved-memory or archive-integrity checks widen the route.")"
    printf '    %s,\n' "$(json_escape "Run saved_memory_inputs before the checksum pass when the route still depends on the saved repo snapshot, README, blocker intelligence, dependency archives, and optional fallback Zig bundle.")"
    printf '    %s,\n' "$(json_escape "Run saved_archive_integrity when exact archive identity matters before restoring Rust, staging offline deps, or trusting Linux build-readiness output.")"
    printf '    %s,\n' "$(json_escape "Use saved_rust_route, offline_route, and toolchain_route to reopen the three setup lanes without rebuilding those command ladders by hand.")"
    printf '    %s,\n' "$(json_escape "Use build_route only after the restored checkout and saved archive surfaces are green.")"
    printf '    %s\n' "$(json_escape "Use runtime_route only after the saved-memory recovery route is green enough that the environment is no longer the main blocker.")"
    printf '  ]\n'
    printf '}\n'
    exit 0
fi

cat <<EOF_ROUTE
Google issue #3 saved-memory recovery route

Repo root:              ${REPO_ROOT}
Restored checkout root: ${RESTORED_CHECKOUT_ROOT}
Saved archive root:     ${SAVED_ARCHIVES_ROOT}
Rust toolchain dir:     ${RUST_TOOLCHAIN_DIR}
Offline deps root:      ${OFFLINE_DEPS_ROOT}
Fallback Zig archive:   ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md

Suggested route
===============
  1. Check the live helper surface before restore:
    ${SURFACE_CHECK_COMMAND}

  2. Restore the saved browser snapshot with synced helper files:
    ${SNAPSHOT_ROUTE_COMMAND}

  3. Validate the restored checkout before deeper setup:
    ${RESTORED_CHECKOUT_COMMAND}

  4. Recheck saved Memory inputs from the restored checkout:
    ${SAVED_MEMORY_INPUTS_COMMAND}

  5. Recheck exact saved archive integrity when identity matters:
    ${SAVED_ARCHIVE_INTEGRITY_COMMAND}

  6. Reopen the saved Rust toolchain route:
    ${SAVED_RUST_ROUTE_COMMAND}

  7. Reopen the offline build-inputs route:
    ${OFFLINE_ROUTE_COMMAND}

  8. Reopen the Zig toolchain recovery route:
    ${TOOLCHAIN_ROUTE_COMMAND}

  9. Reopen Linux or WSL build readiness:
    ${BUILD_ROUTE_COMMAND}

  10. Reopen the direct issue #3 runtime route only after the setup gates are green:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the live helper surface check first so helper drift fails before the restore route is trusted.
  - Prefer the synced saved-browser-snapshot restore so the restored checkout becomes its own follow-up root instead of inheriting the older archive-only helper surface.
  - Run the restored-checkout check before saved-memory or checksum work so missing helper files or checkout drift fail early.
  - Run the saved-memory preflight before the checksum pass when the route still depends on the saved repo snapshot, README, blocker intelligence, dependency archives, and optional fallback Zig bundle.
  - Run the exact archive-integrity pass before restoring Rust, staging offline deps, or trusting Linux build-readiness output when the saved artifacts must match their expected fingerprints.
  - Use the saved Rust, offline-inputs, and Zig-recovery routes to reopen those setup lanes without rebuilding the command ladders by hand.
  - Reopen Linux or WSL build readiness only after the restored checkout and saved archive surfaces are green.
  - Reopen the direct runtime route only after the saved-memory recovery route is green enough that the environment is no longer the main blocker.
EOF_ROUTE
