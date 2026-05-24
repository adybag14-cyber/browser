#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_restored_checkout_refresh_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--restored-checkout /path/to/browser-memory-snapshot] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the compact live-helper route for repairing a stale restored checkout in
place when the saved repo snapshot does not need to be re-extracted yet.
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
RESTORED_CHECKOUT=""
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
        --restored-checkout)
            RESTORED_CHECKOUT="$2"
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
else
    HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
fi
if [[ -z "${RESTORED_CHECKOUT}" ]]; then
    RESTORED_CHECKOUT="$(cd "${REPO_ROOT}/.." && pwd)/browser-memory-snapshot"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${HELPER_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_restored_checkout_refresh_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --restored-checkout $(format_shell_arg "${RESTORED_CHECKOUT}")"
SYNC_ONLY_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT}") --sync-only --check-only"
SYNC_ONLY_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT}") --sync-only"
SYNC_RESTORE_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT}") --sync-helper-surface --check-only"
SYNC_RESTORE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT}") --sync-helper-surface"
RESTORED_CHECKOUT_CHECK_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "route": %s,\n' "$(json_escape "issue3-restored-checkout-refresh")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "helper_root": %s,\n' "$(json_escape "${HELPER_ROOT}")"
    printf '  "restored_checkout": %s,\n' "$(json_escape "${RESTORED_CHECKOUT}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "commands": {\n'
    printf '    "surface_check": %s,\n' "$(json_escape "${SURFACE_CHECK_COMMAND}")"
    printf '    "sync_only_check": %s,\n' "$(json_escape "${SYNC_ONLY_CHECK_COMMAND}")"
    printf '    "sync_only": %s,\n' "$(json_escape "${SYNC_ONLY_COMMAND}")"
    printf '    "sync_restore_check": %s,\n' "$(json_escape "${SYNC_RESTORE_CHECK_COMMAND}")"
    printf '    "sync_restore": %s,\n' "$(json_escape "${SYNC_RESTORE_COMMAND}")"
    printf '    "restored_checkout_check": %s,\n' "$(json_escape "${RESTORED_CHECKOUT_CHECK_COMMAND}")"
    printf '    "saved_memory_preflight": %s,\n' "$(json_escape "${SAVED_MEMORY_PREFLIGHT_COMMAND}")"
    printf '    "build_route": %s,\n' "$(json_escape "${BUILD_ROUTE_COMMAND}")"
    printf '    "runtime_route": %s\n' "$(json_escape "${RUNTIME_ROUTE_COMMAND}")"
    printf '  }\n'
    printf '}\n'
    exit 0
fi

cat <<EOF
Issue #3 restored-checkout refresh route

Repo root:            ${REPO_ROOT}
Helper root:          ${HELPER_ROOT}
Restored checkout:    ${RESTORED_CHECKOUT}
Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE:-not found beside the helper workspace}

Use this route when the restored checkout still looks usable, but its synced
issue #3 helper surface is stale or drifted from the live helper root.

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  In-place helper-surface refresh dry-run:
    ${SYNC_ONLY_CHECK_COMMAND}

  In-place helper-surface refresh:
    ${SYNC_ONLY_COMMAND}

  Full synced restore dry-run when the destination is missing or too stale:
    ${SYNC_RESTORE_CHECK_COMMAND}

  Full synced restore:
    ${SYNC_RESTORE_COMMAND}

  Re-check the refreshed restored checkout:
    ${RESTORED_CHECKOUT_CHECK_COMMAND}

  Re-run the saved-memory preflight:
    ${SAVED_MEMORY_PREFLIGHT_COMMAND}

  Re-open Linux or WSL build readiness from the refreshed checkout:
    ${BUILD_ROUTE_COMMAND}

  Re-open the direct runtime route from the refreshed checkout:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Prefer the in-place --sync-only refresh when the restored checkout already exists and still has a valid build.zig.zon.
  - Use the full synced restore when the destination is missing, incomplete, or too stale to trust.
  - Re-run the restored-checkout readiness helper before the saved-memory preflight so helper drift fails before wider Linux or WSL staging.
  - Re-run the saved-memory preflight before the build-readiness or runtime route so missing archives or fallback Zig wiring fail on the refreshed checkout first.
EOF
