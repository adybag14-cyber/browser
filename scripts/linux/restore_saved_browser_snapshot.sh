#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/restore_saved_browser_snapshot.sh \
    [--browser-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--destination /path/to/extracted/browser-checkout] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--sync-helper-surface] \
    [--check-only] \
    [--json] \
    [--force]

Restore the saved browser repo snapshot from Memory into a reusable local
checkout for Linux or WSL validation work, print the derived paths without
extracting it, or optionally overlay the current issue #3 helper surface into
that restored checkout.

Defaults:
  browser root  parent of this script
  helper root   same as browser root
  memory root   <browser-root>/../memory
  archive       <memory-root>/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip
  destination   <browser-root>/../browser-memory-snapshot

Use --check-only to confirm the saved archive is present and to print the exact
restore and follow-up commands without mutating the filesystem.
Use --sync-helper-surface when the restored checkout should also carry the
current issue #3 helper docs and route scripts from the live helper root.
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
DEFAULT_BROWSER_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"
DEFAULT_DESTINATION_NAME="browser-memory-snapshot"
DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"

declare -a HELPER_SURFACE_PATHS=(
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
    "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"
    "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md"
    "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md"
    "scripts/check_issue3_saved_memory_inputs.py"
    "scripts/check_linux_build_readiness.py"
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
    "scripts/linux/restore_saved_browser_snapshot.sh"
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh"
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
    "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh"
    "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
    "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh"
    "scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
    "scripts/linux/restore_saved_rust_toolchain.sh"
    "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh"
    "scripts/linux/show_issue3_offline_build_inputs_route.sh"
    "scripts/linux/prepare_offline_build_inputs.sh"
)

BROWSER_ROOT="${DEFAULT_BROWSER_ROOT}"
HELPER_ROOT=""
MEMORY_ROOT=""
ARCHIVE_PATH=""
DESTINATION=""
FALLBACK_ZIG_ARCHIVE=""
CHECK_ONLY=false
JSON=false
FORCE_RESTORE=false
SYNC_HELPER_SURFACE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --browser-root)
            BROWSER_ROOT="$2"
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
        --archive)
            ARCHIVE_PATH="$2"
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
        --force)
            FORCE_RESTORE=true
            shift
            ;;
        --sync-helper-surface)
            SYNC_HELPER_SURFACE=true
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

BROWSER_ROOT="$(cd "${BROWSER_ROOT}" && pwd)"
if [[ -z "${HELPER_ROOT}" ]]; then
    HELPER_ROOT="${BROWSER_ROOT}"
fi
HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(cd "${BROWSER_ROOT}/.." && pwd)/memory"
fi
if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${MEMORY_ROOT}/repo_archives/browser/${DEFAULT_ARCHIVE_NAME}"
fi
if [[ -z "${DESTINATION}" ]]; then
    DESTINATION="$(cd "${BROWSER_ROOT}/.." && pwd)/${DEFAULT_DESTINATION_NAME}"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${HELPER_ROOT}/.." && pwd)/agent_files/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

if [[ ! -d "${BROWSER_ROOT}" ]]; then
    echo "Browser root does not exist: ${BROWSER_ROOT}" >&2
    exit 1
fi
if [[ ! -d "${HELPER_ROOT}" ]]; then
    echo "Helper root does not exist: ${HELPER_ROOT}" >&2
    exit 1
fi
if [[ ! -f "${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py" ]]; then
    echo "Helper root is missing scripts/check_issue3_saved_memory_inputs.py: ${HELPER_ROOT}" >&2
    exit 1
fi
if [[ ! -f "${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh" ]]; then
    echo "Helper root is missing scripts/linux/show_issue3_linux_build_readiness_route.sh: ${HELPER_ROOT}" >&2
    exit 1
fi
if [[ ! -f "${HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh" ]]; then
    echo "Helper root is missing scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh: ${HELPER_ROOT}" >&2
    exit 1
fi
if [[ ! -d "${MEMORY_ROOT}" ]]; then
    echo "Memory root does not exist: ${MEMORY_ROOT}" >&2
    exit 1
fi
if [[ ! -f "${ARCHIVE_PATH}" ]]; then
    echo "Saved browser snapshot archive does not exist: ${ARCHIVE_PATH}" >&2
    exit 1
fi

TOP_LEVEL_ENTRY="$(python3 - "${ARCHIVE_PATH}" <<'PY'
import pathlib
import sys
import zipfile

archive_path = pathlib.Path(sys.argv[1])
with zipfile.ZipFile(archive_path) as zf:
    names = [name for name in zf.namelist() if name and not name.startswith("__MACOSX/")]
if not names:
    raise SystemExit("archive has no entries")
top_level = names[0].split("/", 1)[0]
if not top_level:
    raise SystemExit("could not determine top-level folder")
print(top_level)
PY
)"

FOLLOW_UP_HELPER_ROOT="${HELPER_ROOT}"
if [[ "${SYNC_HELPER_SURFACE}" == "true" ]]; then
    FOLLOW_UP_HELPER_ROOT="${DESTINATION}"
fi
SYNC_FLAG=""
if [[ "${SYNC_HELPER_SURFACE}" == "true" ]]; then
    SYNC_FLAG=" --sync-helper-surface"
fi
FOLLOW_UP_MEMORY_CHECK="python $(format_shell_arg "${FOLLOW_UP_HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${DESTINATION}")"
FOLLOW_UP_BUILD_ROUTE="bash $(format_shell_arg "${FOLLOW_UP_HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${DESTINATION}")"
FOLLOW_UP_RUNTIME_ROUTE="bash $(format_shell_arg "${FOLLOW_UP_HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${DESTINATION}")"
RESTORE_FALLBACK_FLAG=""
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    RESTORE_FALLBACK_FLAG=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    FOLLOW_UP_MEMORY_CHECK+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    FOLLOW_UP_BUILD_ROUTE+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    FOLLOW_UP_RUNTIME_ROUTE+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" == "true" ]]; then
    printf '{\n'
    printf '  "browser_root": %s,\n' "$(json_escape "${BROWSER_ROOT}")"
    printf '  "helper_root": %s,\n' "$(json_escape "${HELPER_ROOT}")"
    printf '  "follow_up_helper_root": %s,\n' "$(json_escape "${FOLLOW_UP_HELPER_ROOT}")"
    printf '  "memory_root": %s,\n' "$(json_escape "${MEMORY_ROOT}")"
    printf '  "archive_path": %s,\n' "$(json_escape "${ARCHIVE_PATH}")"
    printf '  "destination": %s,\n' "$(json_escape "${DESTINATION}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "archive_top_level": %s,\n' "$(json_escape "${TOP_LEVEL_ENTRY}")"
    printf '  "follow_up_memory_check": %s,\n' "$(json_escape "${FOLLOW_UP_MEMORY_CHECK}")"
    printf '  "follow_up_build_route": %s,\n' "$(json_escape "${FOLLOW_UP_BUILD_ROUTE}")"
    printf '  "follow_up_runtime_route": %s,\n' "$(json_escape "${FOLLOW_UP_RUNTIME_ROUTE}")"
    printf '  "check_only": %s,\n' "$([[ "${CHECK_ONLY}" == "true" ]] && echo true || echo false)"
    printf '  "force_restore": %s,\n' "$([[ "${FORCE_RESTORE}" == "true" ]] && echo true || echo false)"
    printf '  "sync_helper_surface": %s,\n' "$([[ "${SYNC_HELPER_SURFACE}" == "true" ]] && echo true || echo false)"
    printf '  "helper_surface_file_count": %s,\n' "${#HELPER_SURFACE_PATHS[@]}"
    printf '  "destination_exists": %s\n' "$([[ -e "${DESTINATION}" ]] && echo true || echo false)"
    printf '}\n'
    exit 0
fi

if [[ "${CHECK_ONLY}" == "true" ]]; then
    echo "Saved browser snapshot restore surface check passed."
    echo "Browser root:          ${BROWSER_ROOT}"
    echo "Live helper root:      ${HELPER_ROOT}"
    echo "Follow-up helper root: ${FOLLOW_UP_HELPER_ROOT}"
    echo "Memory root:           ${MEMORY_ROOT}"
    echo "Snapshot archive:      ${ARCHIVE_PATH}"
    echo "Fallback Zig archive:  ${FALLBACK_ZIG_ARCHIVE:-not found beside the helper root}"
    echo "Archive top level:     ${TOP_LEVEL_ENTRY}"
    echo "Destination:           ${DESTINATION}"
    echo "Helper surface sync:   $([[ "${SYNC_HELPER_SURFACE}" == "true" ]] && echo enabled || echo disabled)"
    if [[ "${SYNC_HELPER_SURFACE}" == "true" ]]; then
        echo "Helper surface files:  ${#HELPER_SURFACE_PATHS[@]}"
    fi
    echo
    echo "Suggested restore command:"
    printf "  bash %s --browser-root %s --helper-root %s --destination %s%s%s\n" \
        "$(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh")" \
        "$(format_shell_arg "${BROWSER_ROOT}")" \
        "$(format_shell_arg "${HELPER_ROOT}")" \
        "$(format_shell_arg "${DESTINATION}")" \
        "${RESTORE_FALLBACK_FLAG}" \
        "${SYNC_FLAG}"
    echo
    echo "Suggested follow-up checks:"
    printf "  %s\n" "${FOLLOW_UP_MEMORY_CHECK}"
    printf "  %s\n" "${FOLLOW_UP_BUILD_ROUTE}"
    printf "  %s\n" "${FOLLOW_UP_RUNTIME_ROUTE}"
    exit 0
fi

DESTINATION_PARENT="$(cd "$(dirname "${DESTINATION}")" && pwd)"
mkdir -p "${DESTINATION_PARENT}"

if [[ -e "${DESTINATION}" ]]; then
    if [[ "${FORCE_RESTORE}" == "true" ]]; then
        rm -rf "${DESTINATION}"
    else
        echo "Destination already exists: ${DESTINATION}" >&2
        echo "Use --force to replace the existing restored checkout." >&2
        exit 1
    fi
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

unzip -q "${ARCHIVE_PATH}" -d "${TMP_DIR}"
if [[ ! -d "${TMP_DIR}/${TOP_LEVEL_ENTRY}" ]]; then
    echo "Expected extracted top-level folder was not found: ${TMP_DIR}/${TOP_LEVEL_ENTRY}" >&2
    exit 1
fi

mv "${TMP_DIR}/${TOP_LEVEL_ENTRY}" "${DESTINATION}"

if [[ ! -f "${DESTINATION}/build.zig.zon" ]]; then
    echo "Restored checkout is missing build.zig.zon: ${DESTINATION}/build.zig.zon" >&2
    exit 1
fi

if [[ "${SYNC_HELPER_SURFACE}" == "true" ]]; then
    sync_helper_surface "${HELPER_ROOT}" "${DESTINATION}"
fi

echo
echo "Saved browser snapshot is ready."
echo "Destination:           ${DESTINATION}"
echo "Live helper root:      ${HELPER_ROOT}"
echo "Follow-up helper root: ${FOLLOW_UP_HELPER_ROOT}"
echo "Fallback Zig archive:  ${FALLBACK_ZIG_ARCHIVE:-not found beside the helper root}"
echo "Archive top level:     ${TOP_LEVEL_ENTRY}"
echo "Helper surface sync:   $([[ "${SYNC_HELPER_SURFACE}" == "true" ]] && echo enabled || echo disabled)"
if [[ "${SYNC_HELPER_SURFACE}" == "true" ]]; then
    echo "Helper surface files:  ${#HELPER_SURFACE_PATHS[@]}"
fi
echo
echo "Suggested follow-up checks:"
printf "  %s\n" "${FOLLOW_UP_MEMORY_CHECK}"
printf "  %s\n" "${FOLLOW_UP_BUILD_ROUTE}"
printf "  %s\n" "${FOLLOW_UP_RUNTIME_ROUTE}"
