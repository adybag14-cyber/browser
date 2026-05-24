#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue11_linux_reentry_tracker_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the compact branch-local Linux or WSL re-entry route for issue #11.
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
RESTORED_CHECKOUT_ROOT=""
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
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/browser-memory-snapshot"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

SAVED_MEMORY_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_MEMORY_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_memory_inputs_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SAVED_ARCHIVE_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_ARCHIVE_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_archive_integrity_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RESTORED_CHECKOUT_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${REPO_ROOT}") --expect-helper-surface"
SAVED_RUST_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_RUST_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh") --browser-root $(format_shell_arg "${REPO_ROOT}")"
ZIG_RECOVERY_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ZIG_RECOVERY_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
OFFLINE_INPUTS_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_offline_build_inputs_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
OFFLINE_INPUTS_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_offline_build_inputs_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
LINUX_BUILD_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_linux_build_readiness_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
RUNTIME_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_enter_submit_runtime_revalidation_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_RECOVERY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    OFFLINE_INPUTS_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Issue #11 Linux or WSL re-entry tracker route")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "restored_checkout_root": %s,\n' "$(json_escape "${RESTORED_CHECKOUT_ROOT}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "commands": {\n'
    printf '    "saved_memory_surface": %s,\n' "$(json_escape "${SAVED_MEMORY_SURFACE_COMMAND}")"
    printf '    "saved_memory_route": %s,\n' "$(json_escape "${SAVED_MEMORY_ROUTE_COMMAND}")"
    printf '    "saved_archive_surface": %s,\n' "$(json_escape "${SAVED_ARCHIVE_SURFACE_COMMAND}")"
    printf '    "saved_archive_route": %s,\n' "$(json_escape "${SAVED_ARCHIVE_ROUTE_COMMAND}")"
    printf '    "saved_browser_snapshot_surface": %s,\n' "$(json_escape "${SNAPSHOT_SURFACE_COMMAND}")"
    printf '    "saved_browser_snapshot_route": %s,\n' "$(json_escape "${SNAPSHOT_ROUTE_COMMAND}")"
    printf '    "restored_checkout_check": %s,\n' "$(json_escape "${RESTORED_CHECKOUT_COMMAND}")"
    printf '    "saved_rust_surface": %s,\n' "$(json_escape "${SAVED_RUST_SURFACE_COMMAND}")"
    printf '    "saved_rust_route": %s,\n' "$(json_escape "${SAVED_RUST_ROUTE_COMMAND}")"
    printf '    "zig_recovery_surface": %s,\n' "$(json_escape "${ZIG_RECOVERY_SURFACE_COMMAND}")"
    printf '    "zig_recovery_route": %s,\n' "$(json_escape "${ZIG_RECOVERY_ROUTE_COMMAND}")"
    printf '    "offline_inputs_surface": %s,\n' "$(json_escape "${OFFLINE_INPUTS_SURFACE_COMMAND}")"
    printf '    "offline_inputs_route": %s,\n' "$(json_escape "${OFFLINE_INPUTS_ROUTE_COMMAND}")"
    printf '    "linux_build_surface": %s,\n' "$(json_escape "${LINUX_BUILD_SURFACE_COMMAND}")"
    printf '    "linux_build_route": %s,\n' "$(json_escape "${LINUX_BUILD_ROUTE_COMMAND}")"
    printf '    "runtime_surface": %s,\n' "$(json_escape "${RUNTIME_SURFACE_COMMAND}")"
    printf '    "runtime_route": %s\n' "$(json_escape "${RUNTIME_ROUTE_COMMAND}")"
    printf '  },\n'
    printf '  "notes": [\n'
    printf '    %s,\n' "$(json_escape "Run the saved_memory_surface and saved_memory_route commands first so path and presence drift fail before deeper route replay.")"
    printf '    %s,\n' "$(json_escape "Run the saved_archive_surface and saved_archive_route commands before restore or toolchain work when the lane depends on the saved repo and dependency bundles.")"
    printf '    %s,\n' "$(json_escape "If no reusable checkout exists yet, run the saved_browser_snapshot_surface and saved_browser_snapshot_route commands before toolchain recovery or offline staging.")"
    printf '    %s,\n' "$(json_escape "If a reusable checkout already exists, run restored_checkout_check before wider helper replay so stale helper surfaces are caught early.")"
    printf '    %s,\n' "$(json_escape "Reopen the saved Rust, Zig recovery, and offline-input routes before the broader Linux build-readiness route.")"
    printf '    %s\n' "$(json_escape "Reopen the direct issue #3 runtime route only after the Linux or WSL gate is no longer the blocker.")"
    printf '  ]\n'
    printf '}\n'
    exit 0
fi

cat <<EOF
Issue #11 Linux or WSL re-entry tracker route

Repo root:               ${REPO_ROOT}
Restored checkout root:  ${RESTORED_CHECKOUT_ROOT}
Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE11_LINUX_REENTRY_TRACKER_ROUTE.md
  docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
  docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Saved-Memory route surface:
    ${SAVED_MEMORY_SURFACE_COMMAND}
    ${SAVED_MEMORY_ROUTE_COMMAND}

  Saved-archive integrity route:
    ${SAVED_ARCHIVE_SURFACE_COMMAND}
    ${SAVED_ARCHIVE_ROUTE_COMMAND}

  Saved-browser-snapshot route when no reusable checkout exists yet:
    ${SNAPSHOT_SURFACE_COMMAND}
    ${SNAPSHOT_ROUTE_COMMAND}

  Restored-checkout readiness when a reusable checkout already exists:
    ${RESTORED_CHECKOUT_COMMAND}

  Saved Rust route:
    ${SAVED_RUST_SURFACE_COMMAND}
    ${SAVED_RUST_ROUTE_COMMAND}

  Zig toolchain recovery route:
    ${ZIG_RECOVERY_SURFACE_COMMAND}
    ${ZIG_RECOVERY_ROUTE_COMMAND}

  Offline build-inputs route:
    ${OFFLINE_INPUTS_SURFACE_COMMAND}
    ${OFFLINE_INPUTS_ROUTE_COMMAND}

  Linux or WSL build-readiness route:
    ${LINUX_BUILD_SURFACE_COMMAND}
    ${LINUX_BUILD_ROUTE_COMMAND}

  Direct issue #3 runtime route after the environment gate turns green:
    ${RUNTIME_SURFACE_COMMAND}
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the saved-Memory route before the saved-archive integrity route so missing path drift fails before checksum work.
  - Run the saved-archive integrity route before restore, toolchain, or offline-input staging when the lane depends on the saved repo and dependency bundles.
  - Use the saved-browser-snapshot route when there is still no reusable checkout beside the workspace.
  - Use the restored-checkout check before wider helper replay when a reusable checkout already exists.
  - Reopen the saved Rust, Zig recovery, and offline-input routes before the broader Linux build-readiness route.
  - Reopen the direct issue #3 runtime route only after the Linux or WSL gate is no longer the blocker.
EOF
