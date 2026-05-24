#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/sync_issue3_helper_surface.sh \
    [--helper-root /path/to/live/browser-repo] \
    [--destination /path/to/restored/browser-checkout] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--check-only] \
    [--json]

Copy the current issue #3 helper docs and scripts from a live helper root into
an already-restored browser snapshot checkout.

Defaults:
  helper root            parent of this script
  destination            <helper-root>/../browser-memory-snapshot
  fallback zig archive   <helper-root>/../agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz if present
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

sync_helper_surface() {
    local source_root="$1"
    local target_root="$2"
    local relative_path=""

    for relative_path in "${HELPER_SURFACE_PATHS[@]}"; do
        local source_path="${source_root}/${relative_path}"
        local target_path="${target_root}/${relative_path}"
        if [[ ! -f "${source_path}" ]]; then
            echo "Helper surface source file is missing: ${source_path}" >&2
            exit 1
        fi
        mkdir -p "$(dirname "${target_path}")"
        cp -p "${source_path}" "${target_path}"
    done
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_HELPER_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_DESTINATION_NAME="browser-memory-snapshot"
DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"

declare -a HELPER_SURFACE_PATHS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
    "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md"
    "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
    "docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md"
    "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md"
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md"
    "scripts/check_issue3_saved_memory_inputs.py"
    "scripts/check_issue3_saved_archive_integrity.py"
    "scripts/check_issue3_restored_checkout.py"
    "scripts/check_linux_build_readiness.py"
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh"
    "scripts/linux/show_issue3_saved_archive_integrity_route.sh"
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
    "scripts/linux/restore_saved_browser_snapshot.sh"
    "scripts/linux/sync_issue3_helper_surface.sh"
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh"
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
    "scripts/linux/restore_issue3_fallback_zig_toolchain.sh"
    "scripts/linux/restore_zig_toolchain_archive.sh"
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh"
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
    "scripts/linux/restore_saved_rust_toolchain.sh"
    "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh"
    "scripts/linux/show_issue3_offline_build_inputs_route.sh"
    "scripts/linux/prepare_offline_build_inputs.sh"
)

HELPER_ROOT="${DEFAULT_HELPER_ROOT}"
DESTINATION=""
FALLBACK_ZIG_ARCHIVE=""
CHECK_ONLY=false
JSON=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --helper-root)
            HELPER_ROOT="$2"
            shift 2
            ;;
        --destination)
            DESTINATION="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --check-only)
            CHECK_ONLY=true
            shift
            ;;
        --json)
            JSON=true
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

HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
if [[ -z "${DESTINATION}" ]]; then
    DESTINATION="$(cd "${HELPER_ROOT}/.." && pwd)/${DEFAULT_DESTINATION_NAME}"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${HELPER_ROOT}/.." && pwd)/agent_files/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

if [[ ! -d "${HELPER_ROOT}" ]]; then
    echo "Helper root does not exist: ${HELPER_ROOT}" >&2
    exit 1
fi
for relative_path in "${HELPER_SURFACE_PATHS[@]}"; do
    if [[ ! -f "${HELPER_ROOT}/${relative_path}" ]]; then
        echo "Helper root is missing ${relative_path}: ${HELPER_ROOT}" >&2
        exit 1
    fi
done
if [[ ! -d "${DESTINATION}" ]]; then
    echo "Destination checkout does not exist: ${DESTINATION}" >&2
    exit 1
fi
if [[ ! -f "${DESTINATION}/build.zig.zon" ]]; then
    echo "Destination checkout is missing build.zig.zon: ${DESTINATION}/build.zig.zon" >&2
    exit 1
fi

FOLLOW_UP_RESTORED_CHECK="python $(format_shell_arg "${DESTINATION}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${DESTINATION}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
FOLLOW_UP_MEMORY_CHECK="python $(format_shell_arg "${DESTINATION}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${DESTINATION}")"
FOLLOW_UP_ARCHIVE_INTEGRITY_CHECK="python $(format_shell_arg "${DESTINATION}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${DESTINATION}")"
FOLLOW_UP_BUILD_ROUTE="bash $(format_shell_arg "${DESTINATION}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${DESTINATION}")"
FOLLOW_UP_RUNTIME_ROUTE="bash $(format_shell_arg "${DESTINATION}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${DESTINATION}")"
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    FOLLOW_UP_MEMORY_CHECK+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    FOLLOW_UP_ARCHIVE_INTEGRITY_CHECK+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    FOLLOW_UP_BUILD_ROUTE+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    FOLLOW_UP_RUNTIME_ROUTE+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" == "true" ]]; then
    printf '{\n'
    printf '  "helper_root": %s,\n' "$(json_escape "${HELPER_ROOT}")"
    printf '  "destination": %s,\n' "$(json_escape "${DESTINATION}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "helper_surface_file_count": %s,\n' "${#HELPER_SURFACE_PATHS[@]}"
    printf '  "follow_up_restored_checkout_check": %s,\n' "$(json_escape "${FOLLOW_UP_RESTORED_CHECK}")"
    printf '  "follow_up_memory_check": %s,\n' "$(json_escape "${FOLLOW_UP_MEMORY_CHECK}")"
    printf '  "follow_up_archive_integrity_check": %s,\n' "$(json_escape "${FOLLOW_UP_ARCHIVE_INTEGRITY_CHECK}")"
    printf '  "follow_up_build_route": %s,\n' "$(json_escape "${FOLLOW_UP_BUILD_ROUTE}")"
    printf '  "follow_up_runtime_route": %s,\n' "$(json_escape "${FOLLOW_UP_RUNTIME_ROUTE}")"
    printf '  "check_only": %s\n' "$([[ "${CHECK_ONLY}" == "true" ]] && echo true || echo false)"
    printf '}\n'
    exit 0
fi

if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo "Issue #3 helper surface resync check passed."
    echo "Helper root:           ${HELPER_ROOT}"
    echo "Destination checkout:  ${DESTINATION}"
    echo "Fallback Zig archive:  ${FALLBACK_ZIG_ARCHIVE:-not found beside the helper root}"
    echo "Helper surface files:  ${#HELPER_SURFACE_PATHS[@]}"
    echo
    echo "Suggested sync command:"
    printf '  bash %s --helper-root %s --destination %s%s\n' \
        "$(format_shell_arg "${HELPER_ROOT}/scripts/linux/sync_issue3_helper_surface.sh")" \
        "$(format_shell_arg "${HELPER_ROOT}")" \
        "$(format_shell_arg "${DESTINATION}")" \
        "$([[ -n "${FALLBACK_ZIG_ARCHIVE}" ]] && printf ' --fallback-zig-archive %s' "$(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")")"
    echo
    echo "Suggested follow-up checks:"
    printf '  %s\n' "${FOLLOW_UP_RESTORED_CHECK}"
    printf '  %s\n' "${FOLLOW_UP_MEMORY_CHECK}"
    printf '  %s\n' "${FOLLOW_UP_ARCHIVE_INTEGRITY_CHECK}"
    printf '  %s\n' "${FOLLOW_UP_BUILD_ROUTE}"
    printf '  %s\n' "${FOLLOW_UP_RUNTIME_ROUTE}"
    exit 0
fi

sync_helper_surface "${HELPER_ROOT}" "${DESTINATION}"

echo
echo "Issue #3 helper surface is synced."
echo "Helper root:           ${HELPER_ROOT}"
echo "Destination checkout:  ${DESTINATION}"
echo "Fallback Zig archive:  ${FALLBACK_ZIG_ARCHIVE:-not found beside the helper root}"
echo "Helper surface files:  ${#HELPER_SURFACE_PATHS[@]}"
echo
echo "Suggested follow-up checks:"
printf '  %s\n' "${FOLLOW_UP_RESTORED_CHECK}"
printf '  %s\n' "${FOLLOW_UP_MEMORY_CHECK}"
printf '  %s\n' "${FOLLOW_UP_ARCHIVE_INTEGRITY_CHECK}"
printf '  %s\n' "${FOLLOW_UP_BUILD_ROUTE}"
printf '  %s\n' "${FOLLOW_UP_RUNTIME_ROUTE}"
