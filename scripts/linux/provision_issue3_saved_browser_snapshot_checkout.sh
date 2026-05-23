#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/provision_issue3_saved_browser_snapshot_checkout.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--destination /path/to/extracted/browser-checkout] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--check-only] \
    [--json] \
    [--force]

Restore the saved browser snapshot into a reusable self-contained checkout for
issue #3 recovery work, sync the current helper surface into that checkout, and
print or validate the immediate follow-up checks on one branch-local command.
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
HELPER_ROOT=""
MEMORY_ROOT=""
ARCHIVE_PATH=""
DESTINATION=""
FALLBACK_ZIG_ARCHIVE=""
CHECK_ONLY=0
JSON=0
FORCE_RESTORE=0

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
            CHECK_ONLY=1
            shift
            ;;
        --json)
            JSON=1
            shift
            ;;
        --force)
            FORCE_RESTORE=1
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
    HELPER_ROOT="${DEFAULT_REPO_ROOT}"
fi
HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory"
fi
if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${MEMORY_ROOT}/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
fi
if [[ -z "${DESTINATION}" ]]; then
    DESTINATION="$(cd "${REPO_ROOT}/.." && pwd)/browser-memory-snapshot"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${HELPER_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

RESTORE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
RESTORE_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}") --sync-helper-surface --check-only"
RESTORE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}") --sync-helper-surface"
SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${DESTINATION}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${DESTINATION}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${DESTINATION}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${DESTINATION}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${DESTINATION}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${DESTINATION}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    RESTORE_CHECK_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Google issue #3 saved snapshot checkout provisioning")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "helper_root": %s,\n' "$(json_escape "${HELPER_ROOT}")"
    printf '  "memory_root": %s,\n' "$(json_escape "${MEMORY_ROOT}")"
    printf '  "archive_path": %s,\n' "$(json_escape "${ARCHIVE_PATH}")"
    printf '  "destination": %s,\n' "$(json_escape "${DESTINATION}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "check_only": %s,\n' "$([[ "${CHECK_ONLY}" -eq 1 ]] && echo true || echo false)"
    printf '  "force_restore": %s,\n' "$([[ "${FORCE_RESTORE}" -eq 1 ]] && echo true || echo false)"
    printf '  "commands": {\n'
    printf '    "restore_surface": %s,\n' "$(json_escape "${RESTORE_SURFACE_COMMAND}")"
    printf '    "restore_check": %s,\n' "$(json_escape "${RESTORE_CHECK_COMMAND}")"
    printf '    "restore": %s,\n' "$(json_escape "${RESTORE_COMMAND}")"
    printf '    "saved_memory_preflight": %s,\n' "$(json_escape "${SAVED_MEMORY_PREFLIGHT_COMMAND}")"
    printf '    "linux_build_route": %s,\n' "$(json_escape "${BUILD_ROUTE_COMMAND}")"
    printf '    "runtime_route": %s\n' "$(json_escape "${RUNTIME_ROUTE_COMMAND}")"
    printf '  }\n'
    printf '}\n'
    exit 0
fi

if [[ "${CHECK_ONLY}" -eq 1 ]]; then
    cat <<EOF
Google issue #3 saved snapshot checkout provisioning

Repo root:            ${REPO_ROOT}
Live helper root:     ${HELPER_ROOT}
Memory root:          ${MEMORY_ROOT}
Snapshot archive:     ${ARCHIVE_PATH}
Provisioned checkout: ${DESTINATION}
Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Suggested route
===============
  Restore route surface check:
    ${RESTORE_SURFACE_COMMAND}

  Synced restore helper surface check:
    ${RESTORE_CHECK_COMMAND}

  Synced restore command:
    ${RESTORE_COMMAND}

  Saved-memory preflight from the provisioned checkout:
    ${SAVED_MEMORY_PREFLIGHT_COMMAND}

  Linux or WSL build-readiness route from the provisioned checkout:
    ${BUILD_ROUTE_COMMAND}

  Direct runtime re-entry route from the provisioned checkout:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the restore route surface check first so missing live helper files fail fast.
  - Run the synced restore helper surface check next before extracting anything.
  - Keep the restored checkout self-contained by using --sync-helper-surface.
  - Run the saved-memory preflight from the provisioned checkout before trusting build or runtime route output.
EOF
    exit 0
fi

if [[ "${FORCE_RESTORE}" -eq 1 ]]; then
    RESTORE_COMMAND+=" --force"
fi

eval "${RESTORE_COMMAND}"
eval "${SAVED_MEMORY_PREFLIGHT_COMMAND}"

cat <<EOF

Provisioned issue #3 saved snapshot checkout is ready.

Next commands
=============
  ${BUILD_ROUTE_COMMAND}
  ${RUNTIME_ROUTE_COMMAND}
EOF
