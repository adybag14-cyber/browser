#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/restore_saved_browser_snapshot_from_workspace.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--destination /path/to/extracted/browser-checkout] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--sync-helper-surface] \
    [--sync-only] \
    [--check-only] \
    [--json] \
    [--force]

Workspace-aware wrapper for scripts/linux/restore_saved_browser_snapshot.sh.

This helper prefers the mounted workspace companions that scheduled runs
actually use in this runtime:
  - /workspace/memory
  - /workspace/agent_files
  - /workspace/browser-memory-snapshot

When the repo root is not the workspace root, it falls back to the existing
sibling-path layout used by the underlying restore helper.
EOF
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
CHECK_ONLY=0
JSON=0
FORCE_RESTORE=0
SYNC_HELPER_SURFACE=0
SYNC_ONLY=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root|--browser-root)
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
        --sync-helper-surface)
            SYNC_HELPER_SURFACE=1
            shift
            ;;
        --sync-only)
            SYNC_ONLY=1
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
    AGENT_FILES_ROOT="$(resolve_workspace_companion_path "${HELPER_ROOT}" "agent_files")"
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${AGENT_FILES_ROOT}/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

COMMAND=(
    bash
    "${REPO_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh"
    --browser-root "${REPO_ROOT}"
    --helper-root "${HELPER_ROOT}"
    --memory-root "${MEMORY_ROOT}"
    --archive "${ARCHIVE_PATH}"
    --destination "${DESTINATION}"
)

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    COMMAND+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
fi
if [[ "${SYNC_HELPER_SURFACE}" -eq 1 ]]; then
    COMMAND+=(--sync-helper-surface)
fi
if [[ "${SYNC_ONLY}" -eq 1 ]]; then
    COMMAND+=(--sync-only)
fi
if [[ "${CHECK_ONLY}" -eq 1 ]]; then
    COMMAND+=(--check-only)
fi
if [[ "${JSON}" -eq 1 ]]; then
    COMMAND+=(--json)
fi
if [[ "${FORCE_RESTORE}" -eq 1 ]]; then
    COMMAND+=(--force)
fi

exec "${COMMAND[@]}"
