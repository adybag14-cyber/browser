#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_linux_reentry_stack.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
    [--toolchains-root /path/to/toolchains] \
    [--offline-deps-root /path/to/offline-deps] \
    [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \
    [--browser-exe /path/to/lightpanda.exe] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the issue #3 Linux or WSL re-entry helper stack as one compact route:
saved browser snapshot restore, saved archive integrity, Zig line recovery,
saved Rust restore, offline build inputs, Linux build readiness, and the direct
runtime re-entry surface.
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
REPO_ROOT="${DEFAULT_REPO_ROOT}"
SAVED_ARCHIVES_ROOT=""
TOOLCHAINS_ROOT=""
OFFLINE_DEPS_ROOT=""
RUST_TOOLCHAIN_DIR=""
BROWSER_EXE="${LIGHTPANDA_BROWSER_EXE:-}"
FALLBACK_ZIG_ARCHIVE=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
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
        --rust-toolchain-dir)
            RUST_TOOLCHAIN_DIR="$2"
            shift 2
            ;;
        --browser-exe)
            BROWSER_EXE="$2"
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
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${WORKSPACE_ROOT}/memory/repo_archives/browser/dependencies"
fi
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="${WORKSPACE_ROOT}/toolchains"
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="${WORKSPACE_ROOT}/offline-deps"
fi
if [[ -z "${RUST_TOOLCHAIN_DIR}" ]]; then
    RUST_TOOLCHAIN_DIR="${TOOLCHAINS_ROOT}/rust-1.79.0"
fi
if [[ -z "${BROWSER_EXE}" ]]; then
    BROWSER_EXE="${REPO_ROOT}/zig-out/bin/lightpanda.exe"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${WORKSPACE_ROOT}/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

STACK_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_linux_reentry_stack_surface.sh"
SNAPSHOT_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
ARCHIVE_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_archive_integrity_route.sh"
ZIG_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
RUST_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
OFFLINE_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_offline_build_inputs_route.sh"
BUILD_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh"
RUNTIME_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"

STACK_SURFACE_COMMAND="bash $(format_shell_arg "${STACK_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${SNAPSHOT_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ARCHIVE_ROUTE_COMMAND="bash $(format_shell_arg "${ARCHIVE_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ZIG_ROUTE_COMMAND="bash $(format_shell_arg "${ZIG_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
RUST_ROUTE_COMMAND="bash $(format_shell_arg "${RUST_ROUTE_SCRIPT}") --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
OFFLINE_ROUTE_COMMAND="bash $(format_shell_arg "${OFFLINE_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${BUILD_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${WORKSPACE_ROOT}/memory/repo_archives/browser") --rust-toolchain-dir $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${RUNTIME_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --browser-exe $(format_shell_arg "${BROWSER_EXE}")"
SNAPSHOT_SYNC_ROUTE_COMMAND="${SNAPSHOT_ROUTE_COMMAND} --sync-helper-surface"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SNAPSHOT_SYNC_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ARCHIVE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    OFFLINE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Google issue #3 Linux re-entry stack")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "saved_archives_root": %s,\n' "$(json_escape "${SAVED_ARCHIVES_ROOT}")"
    printf '  "toolchains_root": %s,\n' "$(json_escape "${TOOLCHAINS_ROOT}")"
    printf '  "offline_deps_root": %s,\n' "$(json_escape "${OFFLINE_DEPS_ROOT}")"
    printf '  "rust_toolchain_dir": %s,\n' "$(json_escape "${RUST_TOOLCHAIN_DIR}")"
    printf '  "browser_exe": %s,\n' "$(json_escape "${BROWSER_EXE}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "read_first": [\n'
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md")"
    printf '    %s\n' "$(json_escape "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md")"
    printf '  ],\n'
    printf '  "commands": {\n'
    printf '    "stack_surface": %s,\n' "$(json_escape "${STACK_SURFACE_COMMAND}")"
    printf '    "saved_browser_snapshot_route": %s,\n' "$(json_escape "${SNAPSHOT_ROUTE_COMMAND}")"
    printf '    "saved_browser_snapshot_route_synced": %s,\n' "$(json_escape "${SNAPSHOT_SYNC_ROUTE_COMMAND}")"
    printf '    "saved_archive_integrity_route": %s,\n' "$(json_escape "${ARCHIVE_ROUTE_COMMAND}")"
    printf '    "zig_toolchain_route": %s,\n' "$(json_escape "${ZIG_ROUTE_COMMAND}")"
    printf '    "saved_rust_route": %s,\n' "$(json_escape "${RUST_ROUTE_COMMAND}")"
    printf '    "offline_build_inputs_route": %s,\n' "$(json_escape "${OFFLINE_ROUTE_COMMAND}")"
    printf '    "linux_build_readiness_route": %s,\n' "$(json_escape "${BUILD_ROUTE_COMMAND}")"
    printf '    "runtime_revalidation_route": %s\n' "$(json_escape "${RUNTIME_ROUTE_COMMAND}")"
    printf '  },\n'
    printf '  "notes": [\n'
    printf '    %s,\n' "$(json_escape "Run stack_surface first so the saved-browser-snapshot, archive-integrity, Zig-line, saved-Rust, offline-inputs, build-readiness, and direct-runtime helper surfaces fail fast as one stack.")"
    printf '    %s,\n' "$(json_escape "Use saved_browser_snapshot_route when no reusable checkout exists yet and the restore plus first follow-up commands need to stay on one branch-local surface.")"
    printf '    %s,\n' "$(json_escape "Prefer saved_browser_snapshot_route_synced when the restored checkout should become its own helper root because the saved snapshot can lag the newer branch-local scripts and notes.")"
    printf '    %s,\n' "$(json_escape "Use saved_archive_integrity_route before deeper staging when the route still depends on the saved repo snapshot and dependency bundles in Memory.")"
    printf '    %s,\n' "$(json_escape "Use zig_toolchain_route when the next run still needs a quick answer about whether any staged Zig candidate matches the branch's 0.15.x line.")"
    printf '    %s,\n' "$(json_escape "Use saved_rust_route and offline_build_inputs_route before treating Linux or WSL build output as issue-specific evidence.")"
    printf '    %s,\n' "$(json_escape "Use linux_build_readiness_route after the saved archives, Rust toolchain, Zig candidate, and offline inputs are staged and aligned.")"
    printf '    %s\n' "$(json_escape "Only reopen the direct runtime route after the stack stops reporting environment recovery as the blocker.")"
    printf '  ]\n'
    printf '}\n'
    exit 0
fi

cat <<EOF
Google issue #3 Linux re-entry stack

Repo root:            ${REPO_ROOT}
Saved archives root:  ${SAVED_ARCHIVES_ROOT}
Toolchains root:      ${TOOLCHAINS_ROOT}
Offline deps root:    ${OFFLINE_DEPS_ROOT}
Rust toolchain dir:   ${RUST_TOOLCHAIN_DIR}
Browser exe:          ${BROWSER_EXE}
Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md

Suggested route
===============
  1. Stack surface check:
    ${STACK_SURFACE_COMMAND}

  2. Restore a reusable checkout when needed:
    ${SNAPSHOT_ROUTE_COMMAND}

  3. Prefer the synced restore when the archive helper surface may be stale:
    ${SNAPSHOT_SYNC_ROUTE_COMMAND}

  4. Reconfirm saved archive integrity before deeper staging:
    ${ARCHIVE_ROUTE_COMMAND}

  5. Reopen the Zig line decision:
    ${ZIG_ROUTE_COMMAND}

  6. Reopen the saved Rust toolchain route:
    ${RUST_ROUTE_COMMAND}

  7. Stage offline build inputs:
    ${OFFLINE_ROUTE_COMMAND}

  8. Reopen Linux or WSL build readiness:
    ${BUILD_ROUTE_COMMAND}

  9. Hand back to the direct runtime route:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the stack surface check first so all Linux or WSL re-entry helper surfaces fail fast together.
  - Use the plain saved-browser-snapshot route when the helper workspace itself should stay the follow-up root.
  - Prefer the synced saved-browser-snapshot route when the restored checkout should carry the current helper notes and scripts forward as its own follow-up root.
  - Keep the saved-archive-integrity route ahead of deeper staging when the route still depends on the Memory snapshot or dependency bundles.
  - Keep the Zig toolchain route ahead of Linux or WSL build readiness when the current run still needs a branch-compatible 0.15.x toolchain decision.
  - Keep the saved Rust route and offline-inputs route ahead of Linux or WSL build readiness when the current run still depends on saved archives rather than a ready local environment.
  - Treat the attached Zig 0.17 dev archive as a surfaced fallback only, not as honest validation evidence for this branch.
  - Only reopen the direct runtime route after the stack stops reporting environment recovery as the blocker.
EOF