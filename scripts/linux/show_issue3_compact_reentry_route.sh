#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_compact_reentry_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--destination /path/to/restored/browser-checkout] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--browser-exe /path/to/lightpanda.exe] \
    [--sync-helper-surface] \
    [--sync-only] \
    [--json]

Print the compact issue #3 re-entry ladder that starts from the saved
browser snapshot route, moves through Linux or WSL build readiness, reopens the
direct runtime route, and then hands off to the Windows replay surface.
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

resolve_workspace_companion_path() {
    local root="$1"
    local name="$2"
    local child_path="${root}/${name}"
    local sibling_path="$(cd "${root}/.." && pwd)/${name}"

    if [[ -e "${child_path}" ]]; then
        printf '%s\n' "${child_path}"
        return
    fi

    if [[ "$(basename "${root}")" == "workspace" ]]; then
        printf '%s\n' "${child_path}"
        return
    fi

    printf '%s\n' "${sibling_path}"
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

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_DESTINATION_NAME="browser-memory-snapshot"
DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
MEMORY_ROOT=""
DESTINATION=""
SAVED_ARCHIVES_ROOT=""
RUST_TOOLCHAIN_DIR=""
OFFLINE_DEPS_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
BROWSER_EXE=""
SYNC_HELPER_SURFACE=0
SYNC_ONLY=0
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
        --destination)
            DESTINATION="$2"
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
        --browser-exe)
            BROWSER_EXE="$2"
            shift 2
            ;;
        --sync-helper-surface)
            SYNC_HELPER_SURFACE=1
            shift
            ;;
        --sync-only)
            SYNC_ONLY=1
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

if [[ "${SYNC_ONLY}" -eq 1 ]]; then
    SYNC_HELPER_SURFACE=1
fi

REPO_ROOT="$(cd "${REPO_ROOT}" && pwd)"
if [[ -z "${HELPER_ROOT}" ]]; then
    HELPER_ROOT="${REPO_ROOT}"
fi
HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "memory")"
fi
if [[ -z "${DESTINATION}" ]]; then
    DESTINATION="$(resolve_workspace_companion_path "${REPO_ROOT}" "${DEFAULT_DESTINATION_NAME}")"
fi
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${MEMORY_ROOT}/repo_archives/browser"
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${RUST_TOOLCHAIN_DIR}" ]]; then
    RUST_TOOLCHAIN_DIR="$(resolve_workspace_companion_path "${REPO_ROOT}" "toolchains")/rust-1.79.0"
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "offline-deps")"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(resolve_workspace_companion_path "${HELPER_ROOT}" "agent_files")/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi
if [[ -z "${BROWSER_EXE}" ]]; then
    BROWSER_EXE="${DESTINATION}/zig-out/bin/lightpanda.exe"
fi

FOLLOW_UP_HELPER_ROOT="${HELPER_ROOT}"
if [[ "${SYNC_HELPER_SURFACE}" -eq 1 ]]; then
    FOLLOW_UP_HELPER_ROOT="${DESTINATION}"
fi

FULL_ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_full_reentry_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${DESTINATION}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${FOLLOW_UP_HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${DESTINATION}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --rust-toolchain-dir $(format_shell_arg "${RUST_TOOLCHAIN_DIR}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${FOLLOW_UP_HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${DESTINATION}")"
WINDOWS_HANDOFF_COMMAND="bash $(format_shell_arg "${FOLLOW_UP_HELPER_ROOT}/scripts/linux/show_issue3_windows_runtime_handoff_route.sh") --repo-root $(format_shell_arg "${DESTINATION}") --browser-exe $(format_shell_arg "${BROWSER_EXE}")"

if [[ "${SYNC_ONLY}" -eq 1 ]]; then
    SNAPSHOT_ROUTE_COMMAND+=" --sync-only"
elif [[ "${SYNC_HELPER_SURFACE}" -eq 1 ]]; then
    SNAPSHOT_ROUTE_COMMAND+=" --sync-helper-surface"
fi

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Google issue #3 compact re-entry route")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "helper_root": %s,\n' "$(json_escape "${HELPER_ROOT}")"
    printf '  "follow_up_helper_root": %s,\n' "$(json_escape "${FOLLOW_UP_HELPER_ROOT}")"
    printf '  "memory_root": %s,\n' "$(json_escape "${MEMORY_ROOT}")"
    printf '  "destination": %s,\n' "$(json_escape "${DESTINATION}")"
    printf '  "saved_archives_root": %s,\n' "$(json_escape "${SAVED_ARCHIVES_ROOT}")"
    printf '  "rust_toolchain_dir": %s,\n' "$(json_escape "${RUST_TOOLCHAIN_DIR}")"
    printf '  "offline_deps_root": %s,\n' "$(json_escape "${OFFLINE_DEPS_ROOT}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "browser_exe": %s,\n' "$(json_escape "${BROWSER_EXE}")"
    printf '  "sync_helper_surface": %s,\n' "$([[ "${SYNC_HELPER_SURFACE}" -eq 1 ]] && echo true || echo false)"
    printf '  "sync_only": %s,\n' "$([[ "${SYNC_ONLY}" -eq 1 ]] && echo true || echo false)"
    printf '  "read_first": [\n'
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md")"
    printf '    %s\n' "$(json_escape "docs/WINDOWS_FULL_USE.md")"
    printf '  ],\n'
    printf '  "commands": {\n'
    printf '    "surface_check": %s,\n' "$(json_escape "${FULL_ROUTE_SURFACE_COMMAND}")"
    printf '    "saved_browser_snapshot_route": %s,\n' "$(json_escape "${SNAPSHOT_ROUTE_COMMAND}")"
    printf '    "linux_build_readiness_route": %s,\n' "$(json_escape "${BUILD_ROUTE_COMMAND}")"
    printf '    "runtime_reentry_route": %s,\n' "$(json_escape "${RUNTIME_ROUTE_COMMAND}")"
    printf '    "windows_runtime_handoff": %s\n' "$(json_escape "${WINDOWS_HANDOFF_COMMAND}")"
    printf '  },\n'
    printf '  "notes": [\n'
    printf '    %s,\n' "$(json_escape "Run the surface check first so missing branch-local docs or route helpers fail fast before the ladder is trusted.")"
    printf '    %s,\n' "$(json_escape "Use the saved browser snapshot route next when the direct runtime fix still needs a disposable checkout before Linux or WSL staging can resume.")"
    printf '    %s,\n' "$(json_escape "Prefer --sync-helper-surface when the restored checkout should become its own follow-up root because the saved archive can lag the live helper surface.")"
    printf '    %s,\n' "$(json_escape "Run the Linux build-readiness route after the restore step so saved archives, offline inputs, Rust, and Zig-line checks stay on one branch-local route.")"
    printf '    %s,\n' "$(json_escape "Reopen the direct runtime route only after the build-readiness path is no longer blocked.")"
    printf '    %s\n' "$(json_escape "Use the Windows runtime handoff last, after the Linux or WSL staging gates are green and the narrowed runtime lane is ready for replay.")"
    printf '  ]\n'
    printf '}\n'
    exit 0
fi

cat <<EOF
Google issue #3 compact re-entry route

Repo root:             ${REPO_ROOT}
Live helper root:      ${HELPER_ROOT}
Follow-up helper root: ${FOLLOW_UP_HELPER_ROOT}
Memory root:           ${MEMORY_ROOT}
Restore destination:   ${DESTINATION}
Saved archive root:    ${SAVED_ARCHIVES_ROOT}
Rust toolchain dir:    ${RUST_TOOLCHAIN_DIR}
Offline deps root:     ${OFFLINE_DEPS_ROOT}
Fallback Zig archive:  ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Windows browser exe:   ${BROWSER_EXE}
Sync helper surface:   $([[ "${SYNC_HELPER_SURFACE}" -eq 1 ]] && echo enabled || echo disabled)
Sync only:             $([[ "${SYNC_ONLY}" -eq 1 ]] && echo enabled || echo disabled)

Read first
==========
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
  docs/WINDOWS_FULL_USE.md

Suggested ladder
================
  Surface check:
    ${FULL_ROUTE_SURFACE_COMMAND}

  Saved-browser-snapshot route:
    ${SNAPSHOT_ROUTE_COMMAND}

  Linux or WSL build-readiness route:
    ${BUILD_ROUTE_COMMAND}

  Direct runtime re-entry route:
    ${RUNTIME_ROUTE_COMMAND}

  Windows runtime handoff:
    ${WINDOWS_HANDOFF_COMMAND}

Working rules
=============
  - Run the surface check first so missing branch-local docs or route helpers fail fast before the ladder is trusted.
  - Use the saved-browser-snapshot route next when the direct runtime fix still needs a disposable checkout before Linux or WSL staging can resume.
  - Prefer --sync-helper-surface when the restored checkout should become its own follow-up root because the saved archive can lag the live helper surface.
  - Use --sync-only when the restored checkout already exists and only the helper surface needs to be refreshed in place.
  - Run the Linux or WSL build-readiness route after the restore step so saved archives, offline inputs, Rust, and Zig-line checks stay on one branch-local route.
  - Reopen the direct runtime route only after the build-readiness path is no longer blocked.
  - Use the Windows runtime handoff last, after the Linux or WSL staging gates are green and the narrowed runtime lane is ready for replay.
EOF
