#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_reentry_route_index.sh \
    [--repo-root /path/to/browser-repo] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--sync-helper-surface] \
    [--json]

Print the compact issue #3 re-entry route index for the saved snapshot,
saved-archive, Linux/WSL build-readiness, and direct runtime helper chain.
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
DEFAULT_RESTORED_NAME="browser-memory-snapshot"
DEFAULT_FALLBACK_ZIG_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
RESTORED_CHECKOUT_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
SYNC_HELPER_SURFACE=0
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
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/${DEFAULT_RESTORED_NAME}"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/${DEFAULT_FALLBACK_ZIG_NAME}"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_reentry_route_index_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SYNCED_SAVED_SNAPSHOT_ROUTE_COMMAND="${SAVED_SNAPSHOT_ROUTE_COMMAND} --sync-helper-surface"
RESTORED_SAVED_MEMORY_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RESTORED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RESTORED_LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RESTORED_RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
LIVE_SAVED_MEMORY_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
LIVE_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
LIVE_LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
LIVE_RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNCED_SAVED_SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_SAVED_MEMORY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LIVE_SAVED_MEMORY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LIVE_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LIVE_LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LIVE_RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

PREFERRED_RESTORE_ROUTE_COMMAND="${SAVED_SNAPSHOT_ROUTE_COMMAND}"
if [[ "${SYNC_HELPER_SURFACE}" -eq 1 ]]; then
    PREFERRED_RESTORE_ROUTE_COMMAND="${SYNCED_SAVED_SNAPSHOT_ROUTE_COMMAND}"
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "route": %s,\n' "$(json_escape "Google issue #3 re-entry route index")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "restored_checkout_root": %s,\n' "$(json_escape "${RESTORED_CHECKOUT_ROOT}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "sync_helper_surface": %s,\n' "$([[ "${SYNC_HELPER_SURFACE}" -eq 1 ]] && echo true || echo false)"
    printf '  "commands": {\n'
    printf '    "surface_check": %s,\n' "$(json_escape "${SURFACE_CHECK_COMMAND}")"
    printf '    "saved_snapshot_route": %s,\n' "$(json_escape "${SAVED_SNAPSHOT_ROUTE_COMMAND}")"
    printf '    "synced_saved_snapshot_route": %s,\n' "$(json_escape "${SYNCED_SAVED_SNAPSHOT_ROUTE_COMMAND}")"
    printf '    "preferred_restore_route": %s,\n' "$(json_escape "${PREFERRED_RESTORE_ROUTE_COMMAND}")"
    printf '    "restored_saved_memory_preflight": %s,\n' "$(json_escape "${RESTORED_SAVED_MEMORY_COMMAND}")"
    printf '    "restored_archive_integrity": %s,\n' "$(json_escape "${RESTORED_ARCHIVE_INTEGRITY_COMMAND}")"
    printf '    "restored_linux_build_route": %s,\n' "$(json_escape "${RESTORED_LINUX_BUILD_ROUTE_COMMAND}")"
    printf '    "restored_runtime_route": %s,\n' "$(json_escape "${RESTORED_RUNTIME_ROUTE_COMMAND}")"
    printf '    "live_saved_memory_preflight": %s,\n' "$(json_escape "${LIVE_SAVED_MEMORY_COMMAND}")"
    printf '    "live_archive_integrity": %s,\n' "$(json_escape "${LIVE_ARCHIVE_INTEGRITY_COMMAND}")"
    printf '    "live_linux_build_route": %s,\n' "$(json_escape "${LIVE_LINUX_BUILD_ROUTE_COMMAND}")"
    printf '    "live_runtime_route": %s\n' "$(json_escape "${LIVE_RUNTIME_ROUTE_COMMAND}")"
    printf '  },\n'
    printf '  "notes": [\n'
    printf '    %s,\n' "$(json_escape "Run surface_check first so helper drift fails before the route blames saved archives, toolchains, or runtime state.")"
    printf '    %s,\n' "$(json_escape "Use saved_snapshot_route when no reusable checkout exists yet and the next run still needs the saved Memory snapshot route from the live helper root.")"
    printf '    %s,\n' "$(json_escape "Prefer synced_saved_snapshot_route when the restored checkout should become its own follow-up root because the saved snapshot can lag the current branch-local helper surface.")"
    printf '    %s,\n' "$(json_escape "Run restored_saved_memory_preflight and restored_archive_integrity before trusting Linux or WSL build-readiness output from the restored checkout.")"
    printf '    %s,\n' "$(json_escape "Use restored_linux_build_route before reopened runtime validation when the environment is still the blocker.")"
    printf '    %s,\n' "$(json_escape "Use restored_runtime_route only after the saved-archive, toolchain, and offline dependency gates are green.")"
    printf '    %s,\n' "$(json_escape "Use the live_* commands only when a reusable checkout already exists and the route does not need the saved snapshot restore step.")"
    printf '    %s\n' "$(json_escape "Treat the attached Zig 0.17 fallback archive as surfaced context only, not as honest issue #3 validation evidence for this branch.")"
    printf '  ]\n'
    printf '}\n'
    exit 0
fi

cat <<EOF
Google issue #3 re-entry route index

Repo root:                ${REPO_ROOT}
Restored checkout root:   ${RESTORED_CHECKOUT_ROOT}
Fallback Zig archive:     ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Preferred restore route:  $([[ "${SYNC_HELPER_SURFACE}" -eq 1 ]] && echo synced helper-surface restore || echo live helper-surface restore)

Read first
==========
  docs/ISSUE3_REENTRY_ROUTE_INDEX.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Saved snapshot route from the live helper root:
    ${SAVED_SNAPSHOT_ROUTE_COMMAND}

  Recommended synced saved snapshot route:
    ${SYNCED_SAVED_SNAPSHOT_ROUTE_COMMAND}

  Preferred restore route for this invocation:
    ${PREFERRED_RESTORE_ROUTE_COMMAND}

  Restored checkout preflight:
    ${RESTORED_SAVED_MEMORY_COMMAND}
    ${RESTORED_ARCHIVE_INTEGRITY_COMMAND}

  Restored checkout follow-up:
    ${RESTORED_LINUX_BUILD_ROUTE_COMMAND}
    ${RESTORED_RUNTIME_ROUTE_COMMAND}

  Live-root follow-up when a reusable checkout already exists:
    ${LIVE_SAVED_MEMORY_COMMAND}
    ${LIVE_ARCHIVE_INTEGRITY_COMMAND}
    ${LIVE_LINUX_BUILD_ROUTE_COMMAND}
    ${LIVE_RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the surface check first so helper drift fails before the route blames saved archives, toolchains, or runtime state.
  - Use the saved snapshot route when no reusable checkout exists yet and the next run still needs the saved Memory snapshot path.
  - Prefer the synced saved snapshot route when the restored checkout should become its own follow-up root because the saved snapshot can lag the current branch-local helper surface.
  - Run the restored-checkout saved-Memory preflight and saved-archive integrity commands before trusting Linux or WSL build-readiness output from the restored checkout.
  - Use the restored-checkout Linux or WSL build-readiness route before reopened runtime validation when the environment is still the blocker.
  - Use the restored-checkout direct runtime route only after the saved-archive, toolchain, and offline dependency gates are green.
  - Use the live-root commands only when a reusable checkout already exists and the route does not need the saved snapshot restore step.
  - Treat the attached Zig 0.17 fallback archive as surfaced context only, not as honest issue #3 validation evidence for this branch.
EOF
