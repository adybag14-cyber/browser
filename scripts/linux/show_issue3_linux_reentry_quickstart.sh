#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_linux_reentry_quickstart.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--destination /path/to/extracted/browser-checkout] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--toolchains-root /path/to/toolchains] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the compact Linux or WSL re-entry quickstart for the blocked issue #3
headed-runtime lane.
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
TOOLCHAINS_ROOT=""
OFFLINE_DEPS_ROOT=""
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
        --destination)
            DESTINATION="$2"
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
    MEMORY_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "memory")"
fi
if [[ -z "${DESTINATION}" ]]; then
    DESTINATION="$(resolve_workspace_companion_path "${REPO_ROOT}" "${DEFAULT_DESTINATION_NAME}")"
fi
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${MEMORY_ROOT}/repo_archives/browser"
fi
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "toolchains")"
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "offline-deps")"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    DEFAULT_AGENT_FILES_ROOT="$(resolve_workspace_companion_path "${HELPER_ROOT}" "agent_files")"
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${DEFAULT_AGENT_FILES_ROOT}/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${DESTINATION}")"
PROGRESS_TRACKER_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_progress_tracker_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ZIG_RECOVERY_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
BUILD_READINESS_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
RESTORED_BUILD_READINESS_ROUTE_COMMAND="bash $(format_shell_arg "${DESTINATION}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${DESTINATION}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
RESTORED_RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${DESTINATION}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${DESTINATION}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_RECOVERY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_READINESS_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_BUILD_READINESS_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Google issue #3 Linux or WSL re-entry quickstart")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "helper_root": %s,\n' "$(json_escape "${HELPER_ROOT}")"
    printf '  "memory_root": %s,\n' "$(json_escape "${MEMORY_ROOT}")"
    printf '  "destination": %s,\n' "$(json_escape "${DESTINATION}")"
    printf '  "saved_archives_root": %s,\n' "$(json_escape "${SAVED_ARCHIVES_ROOT}")"
    printf '  "toolchains_root": %s,\n' "$(json_escape "${TOOLCHAINS_ROOT}")"
    printf '  "offline_deps_root": %s,\n' "$(json_escape "${OFFLINE_DEPS_ROOT}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "commands": {\n'
    printf '    "saved_browser_snapshot_route": %s,\n' "$(json_escape "${SNAPSHOT_ROUTE_COMMAND}")"
    printf '    "progress_tracker_route": %s,\n' "$(json_escape "${PROGRESS_TRACKER_ROUTE_COMMAND}")"
    printf '    "zig_toolchain_recovery_route": %s,\n' "$(json_escape "${ZIG_RECOVERY_ROUTE_COMMAND}")"
    printf '    "linux_build_readiness_route": %s,\n' "$(json_escape "${BUILD_READINESS_ROUTE_COMMAND}")"
    printf '    "restored_linux_build_readiness_route": %s,\n' "$(json_escape "${RESTORED_BUILD_READINESS_ROUTE_COMMAND}")"
    printf '    "restored_runtime_route": %s\n' "$(json_escape "${RESTORED_RUNTIME_ROUTE_COMMAND}")"
    printf '  },\n'
    printf '  "notes": [\n'
    printf '    %s,\n' "$(json_escape "Use the saved-browser-snapshot route first when no reusable checkout exists beside the workspace.")"
    printf '    %s,\n' "$(json_escape "Keep the issue #11 progress-tracker route visible while this lane is still blocked on Memory inputs, Zig line recovery, or offline dependency staging.")"
    printf '    %s,\n' "$(json_escape "Run the Zig recovery route before trusting the attached Zig 0.17 fallback as branch-compatible evidence.")"
    printf '    %s,\n' "$(json_escape "Use the live-root build-readiness route before restore when you are still checking workspace-level inputs, and switch to the restored-checkout route after extraction when the next work depends on the saved snapshot itself.")"
    printf '    %s\n' "$(json_escape "Only reopen the restored runtime route after the environment gates stop being the blocker.")"
    printf '  ]\n'
    printf '}\n'
    exit 0
fi

cat <<EOF
Google issue #3 Linux or WSL re-entry quickstart

Repo root:             ${REPO_ROOT}
Live helper root:      ${HELPER_ROOT}
Memory root:           ${MEMORY_ROOT}
Restore destination:   ${DESTINATION}
Saved archives root:   ${SAVED_ARCHIVES_ROOT}
Toolchains root:       ${TOOLCHAINS_ROOT}
Offline deps root:     ${OFFLINE_DEPS_ROOT}
Fallback Zig archive:  ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  When no reusable restored checkout exists yet:
    ${SNAPSHOT_ROUTE_COMMAND}

  Keep the issue #11 tracker visible while the lane is still environment-gated:
    ${PROGRESS_TRACKER_ROUTE_COMMAND}

  Reopen the Zig line before trusting fallback Zig:
    ${ZIG_RECOVERY_ROUTE_COMMAND}

  Check live-root Linux or WSL build readiness:
    ${BUILD_READINESS_ROUTE_COMMAND}

  After the saved snapshot has been restored, rerun readiness from the restored checkout:
    ${RESTORED_BUILD_READINESS_ROUTE_COMMAND}

  Only after the environment gates are green, reopen the narrowed runtime route:
    ${RESTORED_RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Use the saved-browser-snapshot route first when no reusable checkout exists beside the workspace.
  - Keep the issue #11 progress-tracker route visible while this lane is still blocked on Memory inputs, Zig line recovery, or offline dependency staging.
  - Run the Zig recovery route before trusting the attached Zig 0.17 fallback as branch-compatible evidence.
  - Use the live-root build-readiness route before restore when you are still checking workspace-level inputs, and switch to the restored-checkout route after extraction when the next work depends on the saved snapshot itself.
  - Only reopen the restored runtime route after the environment gates stop being the blocker.
EOF