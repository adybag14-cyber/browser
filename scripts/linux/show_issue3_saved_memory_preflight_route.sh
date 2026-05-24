#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_memory_preflight_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the compact saved-Memory-first recovery route for the blocked issue #3
runtime lane. This keeps the route-surface check, saved-browser-snapshot restore
path, restored-checkout readiness check, saved-Memory preflight, saved-archive
integrity check, Linux build-readiness helper, and direct runtime re-entry
helper on one branch-local surface.
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
DEFAULT_RESTORED_CHECKOUT_NAME="browser-memory-snapshot"
DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
MEMORY_ROOT=""
RESTORED_CHECKOUT_ROOT=""
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
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${HELPER_ROOT}/.." && pwd)/agent_files/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_saved_memory_preflight_route_surface.sh"
RESTORE_ROUTE_SCRIPT="${HELPER_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
RESTORE_SCRIPT="${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh"
RESTORED_CHECK_SCRIPT="${HELPER_ROOT}/scripts/check_issue3_restored_checkout.py"
SAVED_MEMORY_INPUTS_SCRIPT="${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py"
SAVED_ARCHIVE_INTEGRITY_SCRIPT="${HELPER_ROOT}/scripts/check_issue3_saved_archive_integrity.py"
LINUX_BUILD_ROUTE_SCRIPT="${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh"
RUNTIME_REENTRY_ROUTE_SCRIPT="${HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
RESTORE_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORE_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
RESTORE_ROUTE_SYNCED_COMMAND="${RESTORE_ROUTE_COMMAND} --sync-helper-surface"
RESTORE_CHECK_ONLY_COMMAND="bash $(format_shell_arg "${RESTORE_SCRIPT}") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --check-only"
RESTORE_COMMAND="bash $(format_shell_arg "${RESTORE_SCRIPT}") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RESTORE_SYNCED_COMMAND="${RESTORE_COMMAND} --sync-helper-surface"
RESTORED_CHECK_COMMAND="python $(format_shell_arg "${RESTORED_CHECK_SCRIPT}") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RESTORED_CHECK_SYNCED_COMMAND="${RESTORED_CHECK_COMMAND} --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
SAVED_MEMORY_INPUTS_COMMAND="python $(format_shell_arg "${SAVED_MEMORY_INPUTS_SCRIPT}") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${SAVED_ARCHIVE_INTEGRITY_SCRIPT}") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}")"
LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${LINUX_BUILD_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RUNTIME_REENTRY_ROUTE_COMMAND="bash $(format_shell_arg "${RUNTIME_REENTRY_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    RESTORE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORE_ROUTE_SYNCED_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORE_CHECK_ONLY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORE_SYNCED_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_INPUTS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_REENTRY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Google issue #3 saved-Memory preflight route")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "helper_root": %s,\n' "$(json_escape "${HELPER_ROOT}")"
    printf '  "memory_root": %s,\n' "$(json_escape "${MEMORY_ROOT}")"
    printf '  "restored_checkout_root": %s,\n' "$(json_escape "${RESTORED_CHECKOUT_ROOT}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "commands": {\n'
    printf '    "surface_check": %s,\n' "$(json_escape "${SURFACE_CHECK_COMMAND}")"
    printf '    "saved_browser_snapshot_route": %s,\n' "$(json_escape "${RESTORE_ROUTE_COMMAND}")"
    printf '    "saved_browser_snapshot_route_synced": %s,\n' "$(json_escape "${RESTORE_ROUTE_SYNCED_COMMAND}")"
    printf '    "restore_check_only": %s,\n' "$(json_escape "${RESTORE_CHECK_ONLY_COMMAND}")"
    printf '    "restore_snapshot": %s,\n' "$(json_escape "${RESTORE_COMMAND}")"
    printf '    "restore_snapshot_synced": %s,\n' "$(json_escape "${RESTORE_SYNCED_COMMAND}")"
    printf '    "restored_checkout_check": %s,\n' "$(json_escape "${RESTORED_CHECK_COMMAND}")"
    printf '    "restored_checkout_check_synced": %s,\n' "$(json_escape "${RESTORED_CHECK_SYNCED_COMMAND}")"
    printf '    "saved_memory_inputs": %s,\n' "$(json_escape "${SAVED_MEMORY_INPUTS_COMMAND}")"
    printf '    "saved_archive_integrity": %s,\n' "$(json_escape "${SAVED_ARCHIVE_INTEGRITY_COMMAND}")"
    printf '    "linux_build_route": %s,\n' "$(json_escape "${LINUX_BUILD_ROUTE_COMMAND}")"
    printf '    "runtime_reentry_route": %s\n' "$(json_escape "${RUNTIME_REENTRY_ROUTE_COMMAND}")"
    printf '  },\n'
    printf '  "notes": [\n'
    printf '    %s,\n' "$(json_escape "Run the surface check first so the saved-Memory recovery helper chain fails fast before a run assumes the branch-local route still exists.")"
    printf '    %s,\n' "$(json_escape "If no reusable checkout exists yet, start with the saved-browser-snapshot route or restore_check_only command before deeper Linux or runtime helpers.")"
    printf '    %s,\n' "$(json_escape "Prefer the synced restore commands when the saved repo archive may lag the current helper surface and the restored checkout should become its own follow-up root.")"
    printf '    %s,\n' "$(json_escape "Run the restored-checkout check before the saved-memory preflight so missing build.zig.zon or helper drift fails before the archive inputs are blamed.")"
    printf '    %s,\n' "$(json_escape "Run the saved-memory preflight next so missing repo archive, blocker intelligence, dependency bundles, or fallback Zig surface fail before route widening.")"
    printf '    %s,\n' "$(json_escape "Run the saved-archive integrity check when the route needs the exact SHA-256 proof for the saved snapshot and dependency bundles before offline staging or runtime re-entry.")"
    printf '    %s,\n' "$(json_escape "Only after those checks are green should the run widen back out to the Linux build-readiness route and then the direct runtime re-entry route.")"
    printf '    %s\n' "$(json_escape "Treat the attached Zig 0.17 fallback archive as a surfaced input only; it is not honest branch-validation evidence for the blocked runtime patch.")"
    printf '  ]\n'
    printf '}\n'
    exit 0
fi

cat <<EOF
Google issue #3 saved-Memory preflight route

Repo root:              ${REPO_ROOT}
Helper root:            ${HELPER_ROOT}
Memory root:            ${MEMORY_ROOT}
Restored checkout root: ${RESTORED_CHECKOUT_ROOT}
Fallback Zig archive:   ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo helper root}

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  If no reusable checkout exists yet, reopen the saved-browser-snapshot route:
    ${RESTORE_ROUTE_COMMAND}

  Recommended synced saved-browser-snapshot route when the archive helper surface may be stale:
    ${RESTORE_ROUTE_SYNCED_COMMAND}

  Restore surface check without mutating the filesystem:
    ${RESTORE_CHECK_ONLY_COMMAND}

  Restore the saved browser snapshot:
    ${RESTORE_COMMAND}

  Restore the saved browser snapshot and sync the current helper surface:
    ${RESTORE_SYNCED_COMMAND}

  Restored-checkout readiness check:
    ${RESTORED_CHECK_COMMAND}

  Restored-checkout readiness check for the synced helper surface:
    ${RESTORED_CHECK_SYNCED_COMMAND}

  Saved-Memory input preflight:
    ${SAVED_MEMORY_INPUTS_COMMAND}

  Saved-archive integrity check:
    ${SAVED_ARCHIVE_INTEGRITY_COMMAND}

  Linux build-readiness route after the saved-Memory checks pass:
    ${LINUX_BUILD_ROUTE_COMMAND}

  Direct runtime re-entry route after the Linux build-readiness route is green:
    ${RUNTIME_REENTRY_ROUTE_COMMAND}

Working rules
=============
  - Run the surface check first so missing docs or helper drift fails before the route assumes the branch-local recovery chain is still intact.
  - If no reusable checkout exists yet, use the saved-browser-snapshot route or restore surface check before wider Linux or runtime helpers.
  - Prefer the synced restore commands when the saved repo archive may lag the current helper surface and the restored checkout should become its own follow-up root.
  - Run the restored-checkout readiness check before the saved-Memory preflight so missing build.zig.zon or helper drift fails before the archive inputs are blamed.
  - Run the saved-Memory preflight next so missing repo archive, blocker intelligence, dependency bundles, or fallback Zig surface fail before the route widens back out.
  - Run the saved-archive integrity check when the route needs exact SHA-256 proof for the saved snapshot and dependency bundles before offline staging or runtime re-entry.
  - Only after those checks are green should the run widen back out to the Linux build-readiness route and then the direct runtime re-entry route.
  - Treat the attached zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz fallback bundle as a surfaced input only, not as honest branch-validation evidence for the blocked runtime patch.
EOF