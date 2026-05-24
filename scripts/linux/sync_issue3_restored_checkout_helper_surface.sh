#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/sync_issue3_restored_checkout_helper_surface.sh \
    [--helper-root /path/to/live/browser-repo] \
    [--restored-checkout /path/to/restored/browser-checkout] \
    [--check-only] \
    [--json]

Refresh the issue #3 helper surface inside an already-restored browser snapshot
checkout without re-extracting the saved repo archive.

Defaults:
  helper root        parent of this script
  restored checkout  <helper-root>/../browser-memory-snapshot
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

file_sha256() {
    sha256sum "$1" | awk '{print $1}'
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_HELPER_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_RESTORED_CHECKOUT_NAME="browser-memory-snapshot"

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
RESTORED_CHECKOUT=""
CHECK_ONLY=false
JSON=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --helper-root|--browser-root)
            HELPER_ROOT="$2"
            shift 2
            ;;
        --restored-checkout|--destination)
            RESTORED_CHECKOUT="$2"
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
if [[ -z "${RESTORED_CHECKOUT}" ]]; then
    RESTORED_CHECKOUT="$(cd "${HELPER_ROOT}/.." && pwd)/${DEFAULT_RESTORED_CHECKOUT_NAME}"
fi

if [[ ! -d "${HELPER_ROOT}" ]]; then
    echo "Helper root does not exist: ${HELPER_ROOT}" >&2
    exit 1
fi
if [[ ! -d "${RESTORED_CHECKOUT}" ]]; then
    echo "Restored checkout does not exist: ${RESTORED_CHECKOUT}" >&2
    exit 1
fi
if [[ ! -f "${RESTORED_CHECKOUT}/build.zig.zon" ]]; then
    echo "Restored checkout is missing build.zig.zon: ${RESTORED_CHECKOUT}/build.zig.zon" >&2
    exit 1
fi

missing_helper_sources=()
missing_restored_files=()
drifted_files=()
synced_files=()

for relative_path in "${HELPER_SURFACE_PATHS[@]}"; do
    source_path="${HELPER_ROOT}/${relative_path}"
    target_path="${RESTORED_CHECKOUT}/${relative_path}"
    if [[ ! -f "${source_path}" ]]; then
        missing_helper_sources+=("${relative_path}")
        continue
    fi
    if [[ ! -f "${target_path}" ]]; then
        missing_restored_files+=("${relative_path}")
        continue
    fi
    if [[ "$(file_sha256 "${source_path}")" == "$(file_sha256 "${target_path}")" ]]; then
        synced_files+=("${relative_path}")
    else
        drifted_files+=("${relative_path}")
    fi
done

FOLLOW_UP_RESTORED_CHECK="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
FOLLOW_UP_MEMORY_CHECK="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT}")"
FOLLOW_UP_ARCHIVE_INTEGRITY_CHECK="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT}")"
FOLLOW_UP_BUILD_ROUTE="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT}")"
FOLLOW_UP_RUNTIME_ROUTE="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT}")"
SUGGESTED_SYNC_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/sync_issue3_restored_checkout_helper_surface.sh") --helper-root $(format_shell_arg "${HELPER_ROOT}") --restored-checkout $(format_shell_arg "${RESTORED_CHECKOUT}")"

if [[ "${JSON}" == "true" ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "helper_root": ${HELPER_ROOT@Q},
    "restored_checkout": ${RESTORED_CHECKOUT@Q},
    "helper_surface_file_count": ${#HELPER_SURFACE_PATHS[@]},
    "missing_helper_sources": ${missing_helper_sources[@]+${missing_helper_sources[@]@Q}},
    "missing_restored_files": ${missing_restored_files[@]+${missing_restored_files[@]@Q}},
    "drifted_files": ${drifted_files[@]+${drifted_files[@]@Q}},
    "synced_files": ${synced_files[@]+${synced_files[@]@Q}},
    "check_only": ${CHECK_ONLY}
}, indent=2))
PY
    exit 0
fi

if [[ ${#missing_helper_sources[@]} -gt 0 ]]; then
    echo "Helper root is missing required issue #3 helper files:" >&2
    printf '  %s\n' "${missing_helper_sources[@]}" >&2
    exit 1
fi

if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo "Issue #3 helper-surface sync check passed."
    echo "Helper root:               ${HELPER_ROOT}"
    echo "Restored checkout:         ${RESTORED_CHECKOUT}"
    echo "Helper surface file count: ${#HELPER_SURFACE_PATHS[@]}"
    echo "Already synced:            ${#synced_files[@]}"
    echo "Drifted files:             ${#drifted_files[@]}"
    echo "Missing restored files:    ${#missing_restored_files[@]}"
    echo
    if [[ ${#drifted_files[@]} -gt 0 ]]; then
        echo "Drifted helper files:"
        printf '  %s\n' "${drifted_files[@]}"
        echo
    fi
    if [[ ${#missing_restored_files[@]} -gt 0 ]]; then
        echo "Missing helper files in restored checkout:"
        printf '  %s\n' "${missing_restored_files[@]}"
        echo
    fi
    echo "Suggested sync command:"
    echo "  ${SUGGESTED_SYNC_COMMAND}"
    echo
    echo "Suggested follow-up checks:"
    echo "  ${FOLLOW_UP_RESTORED_CHECK}"
    echo "  ${FOLLOW_UP_MEMORY_CHECK}"
    echo "  ${FOLLOW_UP_ARCHIVE_INTEGRITY_CHECK}"
    echo "  ${FOLLOW_UP_BUILD_ROUTE}"
    echo "  ${FOLLOW_UP_RUNTIME_ROUTE}"
    exit 0
fi

for relative_path in "${HELPER_SURFACE_PATHS[@]}"; do
    source_path="${HELPER_ROOT}/${relative_path}"
    target_path="${RESTORED_CHECKOUT}/${relative_path}"
    mkdir -p "$(dirname "${target_path}")"
    cp -p "${source_path}" "${target_path}"
done

echo "Issue #3 helper surface synced into restored checkout."
echo "Helper root:               ${HELPER_ROOT}"
echo "Restored checkout:         ${RESTORED_CHECKOUT}"
echo "Helper surface file count: ${#HELPER_SURFACE_PATHS[@]}"
echo "Previously drifted:        ${#drifted_files[@]}"
echo "Previously missing:        ${#missing_restored_files[@]}"
echo
echo "Suggested follow-up checks:"
echo "  ${FOLLOW_UP_RESTORED_CHECK}"
echo "  ${FOLLOW_UP_MEMORY_CHECK}"
echo "  ${FOLLOW_UP_ARCHIVE_INTEGRITY_CHECK}"
echo "  ${FOLLOW_UP_BUILD_ROUTE}"
echo "  ${FOLLOW_UP_RUNTIME_ROUTE}"
