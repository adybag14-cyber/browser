#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/run_issue3_saved_snapshot_reentry_preflight.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--destination /path/to/browser-memory-snapshot] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--sync-helper-surface] \
    [--run] \
    [--json]

Print, or optionally run, the smallest repeatable saved-snapshot re-entry
preflight for the blocked issue #3 Linux/WSL path. This keeps the restore
surface, archive-surface drift check, restored-checkout readiness check,
saved-Memory preflight, saved-archive integrity preflight, and Linux build-
readiness preflight on one compact helper.
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

find_workspace_anchor() {
    local root="$1"
    local current="$1"

    while true; do
        if [[ -d "${current}/memory" || -d "${current}/agent_files" || "$(basename "${current}")" == "workspace" ]]; then
            printf '%s\n' "${current}"
            return
        fi

        local parent
        parent="$(dirname "${current}")"
        if [[ "${parent}" == "${current}" ]]; then
            break
        fi
        current="${parent}"
    done

    printf '%s\n' "$(cd "${root}/.." && pwd)"
}

resolve_workspace_companion_path() {
    local root="$1"
    local name="$2"
    local anchor

    anchor="$(find_workspace_anchor "${root}")"
    printf '%s\n' "${anchor}/${name}"
}

run_or_print() {
    local label="$1"
    local command="$2"

    if [[ "${RUN}" == "true" ]]; then
        echo "==> ${label}"
        echo "${command}"
        eval "${command}"
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"
DEFAULT_DESTINATION_NAME="browser-memory-snapshot"
DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
MEMORY_ROOT=""
ARCHIVE_PATH=""
DESTINATION=""
FALLBACK_ZIG_ARCHIVE=""
SYNC_HELPER_SURFACE="false"
RUN="false"
JSON="false"

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
        --sync-helper-surface)
            SYNC_HELPER_SURFACE="true"
            shift
            ;;
        --run)
            RUN="true"
            shift
            ;;
        --json)
            JSON="true"
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
if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${MEMORY_ROOT}/repo_archives/browser/${DEFAULT_ARCHIVE_NAME}"
fi
if [[ -z "${DESTINATION}" ]]; then
    DESTINATION="$(resolve_workspace_companion_path "${REPO_ROOT}" "${DEFAULT_DESTINATION_NAME}")"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(resolve_workspace_companion_path "${REPO_ROOT}" "agent_files")/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ARCHIVE_SURFACE_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_browser_snapshot_archive_surface.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
RESTORE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}")"
RESTORED_CHECKOUT_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${DESTINATION}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${DESTINATION}") --helper-root $(format_shell_arg "${HELPER_ROOT}")"
ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${DESTINATION}")"
BUILD_READINESS_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_linux_build_readiness.py") --repo-root $(format_shell_arg "${DESTINATION}") --skip-zig-check"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    RESTORE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_READINESS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${SYNC_HELPER_SURFACE}" == "true" ]]; then
    RESTORE_COMMAND+=" --sync-helper-surface"
fi

declare -a STEP_LABELS=(
    "Saved-browser-snapshot route surface"
    "Saved snapshot archive helper surface"
    "Saved snapshot restore surface"
    "Restored-checkout readiness"
    "Saved-Memory preflight"
    "Saved-archive integrity"
    "Linux build-readiness preflight"
)

declare -a STEP_COMMANDS=(
    "${SURFACE_CHECK_COMMAND}"
    "${ARCHIVE_SURFACE_COMMAND}"
    "${RESTORE_COMMAND}"
    "${RESTORED_CHECKOUT_COMMAND}"
    "${SAVED_MEMORY_PREFLIGHT_COMMAND}"
    "${ARCHIVE_INTEGRITY_COMMAND}"
    "${BUILD_READINESS_COMMAND}"
)

if [[ "${JSON}" == "true" ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "issue3-saved-snapshot-reentry-preflight")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "helper_root": %s,\n' "$(json_escape "${HELPER_ROOT}")"
    printf '  "memory_root": %s,\n' "$(json_escape "${MEMORY_ROOT}")"
    printf '  "archive": %s,\n' "$(json_escape "${ARCHIVE_PATH}")"
    printf '  "destination": %s,\n' "$(json_escape "${DESTINATION}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "sync_helper_surface": %s,\n' "$([[ "${SYNC_HELPER_SURFACE}" == "true" ]] && echo true || echo false)"
    printf '  "run": %s,\n' "$([[ "${RUN}" == "true" ]] && echo true || echo false)"
    printf '  "steps": [\n'
    for index in "${!STEP_LABELS[@]}"; do
        [[ "${index}" -gt 0 ]] && printf ',\n'
        printf '    {"label": %s, "command": %s}' \
            "$(json_escape "${STEP_LABELS[$index]}")" \
            "$(json_escape "${STEP_COMMANDS[$index]}")"
    done
    printf '\n  ]\n'
    printf '}\n'
else
    cat <<EOF
Issue #3 saved snapshot re-entry preflight

Repo root:             ${REPO_ROOT}
Helper root:           ${HELPER_ROOT}
Memory root:           ${MEMORY_ROOT}
Saved snapshot:        ${ARCHIVE_PATH}
Restored checkout:     ${DESTINATION}
Fallback Zig archive:  ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Sync helper surface:   ${SYNC_HELPER_SURFACE}
Run commands now:      ${RUN}

Suggested order
===============
  1. Saved-browser-snapshot route surface
     ${SURFACE_CHECK_COMMAND}

  2. Saved snapshot archive helper surface
     ${ARCHIVE_SURFACE_COMMAND}

  3. Saved snapshot restore surface
     ${RESTORE_COMMAND}

  4. Restored-checkout readiness
     ${RESTORED_CHECKOUT_COMMAND}

  5. Saved-Memory preflight
     ${SAVED_MEMORY_PREFLIGHT_COMMAND}

  6. Saved-archive integrity
     ${ARCHIVE_INTEGRITY_COMMAND}

  7. Linux build-readiness preflight
     ${BUILD_READINESS_COMMAND}

Working rules
=============
  - Use this helper when the direct Page.zig and win32_backend.zig runtime patch is still blocked, but the next run can still shorten restore and preflight setup.
  - Prefer --sync-helper-surface when the saved snapshot archive does not already carry the current helper docs and route scripts.
  - Keep the restored-checkout readiness check ahead of the saved-Memory and archive-integrity preflights so stale helper-surface drift fails fast.
  - Treat this helper as a restore and trust bundle, not as proof that the direct runtime lane is ready to reopen.
  - The restore step is a real restore command so the later checks can point at the same reusable checkout when --run is used.
EOF
fi

if [[ "${RUN}" == "true" ]]; then
    for index in "${!STEP_LABELS[@]}"; do
        run_or_print "${STEP_LABELS[$index]}" "${STEP_COMMANDS[$index]}"
    done
fi
