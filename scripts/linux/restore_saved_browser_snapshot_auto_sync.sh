#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/restore_saved_browser_snapshot_auto_sync.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--destination /path/to/extracted/browser-checkout] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--check-only] \
    [--force] \
    [--json]

Inspect the saved browser snapshot archive surface and choose the safest restore
mode automatically:
- plain restore when the saved archive already carries the current helper surface
- synced restore when the archive is stale and a new checkout must be extracted
- sync-only refresh when the archive is stale and the destination already exists
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
    local sibling_path

    sibling_path="$(cd "${root}/.." && pwd)/${name}"
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

probe_archive_surface() {
    local helper_script="$1"
    local repo_root="$2"
    local archive_path="$3"

    python3 - "$helper_script" "$repo_root" "$archive_path" <<'PY'
import json
import subprocess
import sys

helper_script, repo_root, archive_path = sys.argv[1:]
command = [
    sys.executable,
    helper_script,
    "--repo-root",
    repo_root,
    "--archive",
    archive_path,
    "--json",
]
result = subprocess.run(command, capture_output=True, text=True)
if result.returncode not in (0, 2):
    sys.stderr.write(result.stderr or result.stdout)
    raise SystemExit(result.returncode)
payload = json.loads(result.stdout)
print(
    json.dumps(
        {
            "recommended_restore_mode": payload.get("recommended_restore_mode", "plain"),
            "missing_paths": payload.get("missing_paths", []),
            "helper_surface_complete": payload.get("helper_surface_complete", False),
        }
    )
)
PY
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_DESTINATION_NAME="browser-memory-snapshot"
DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"
DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
MEMORY_ROOT=""
ARCHIVE_PATH=""
DESTINATION=""
FALLBACK_ZIG_ARCHIVE=""
CHECK_ONLY=0
FORCE_RESTORE=0
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
        --force)
            FORCE_RESTORE=1
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
    DEFAULT_AGENT_FILES_ROOT="$(resolve_workspace_companion_path "${HELPER_ROOT}" "agent_files")"
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${DEFAULT_AGENT_FILES_ROOT}/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ARCHIVE_SURFACE_HELPER="${HELPER_ROOT}/scripts/check_issue3_saved_browser_snapshot_archive_surface.py"
RESTORE_HELPER="${HELPER_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh"

if [[ ! -d "${REPO_ROOT}" ]]; then
    echo "Repo root does not exist: ${REPO_ROOT}" >&2
    exit 1
fi
if [[ ! -d "${HELPER_ROOT}" ]]; then
    echo "Helper root does not exist: ${HELPER_ROOT}" >&2
    exit 1
fi
if [[ ! -f "${ARCHIVE_SURFACE_HELPER}" ]]; then
    echo "Archive-surface helper is missing: ${ARCHIVE_SURFACE_HELPER}" >&2
    exit 1
fi
if [[ ! -f "${RESTORE_HELPER}" ]]; then
    echo "Restore helper is missing: ${RESTORE_HELPER}" >&2
    exit 1
fi
if [[ ! -f "${ARCHIVE_PATH}" ]]; then
    echo "Saved browser snapshot archive does not exist: ${ARCHIVE_PATH}" >&2
    exit 1
fi

PROBE_JSON="$(probe_archive_surface "${ARCHIVE_SURFACE_HELPER}" "${HELPER_ROOT}" "${ARCHIVE_PATH}")"
RECOMMENDED_RESTORE_MODE="$(
    python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["recommended_restore_mode"])' \
        <<<"${PROBE_JSON}"
)"
MISSING_PATH_COUNT="$(
    python3 -c 'import json,sys; print(len(json.loads(sys.stdin.read())["missing_paths"]))' \
        <<<"${PROBE_JSON}"
)"
MISSING_PATHS_JSON="$(
    python3 -c 'import json,sys; print(json.dumps(json.loads(sys.stdin.read())["missing_paths"]))' \
        <<<"${PROBE_JSON}"
)"

DESTINATION_EXISTS=0
if [[ -e "${DESTINATION}" ]]; then
    DESTINATION_EXISTS=1
fi

CHOSEN_RESTORE_MODE="plain"
FOLLOW_UP_HELPER_ROOT="${HELPER_ROOT}"
DECISION_REASON="saved snapshot archive already carries the current helper surface"

case "${RECOMMENDED_RESTORE_MODE}" in
    sync-helper-surface)
        FOLLOW_UP_HELPER_ROOT="${DESTINATION}"
        if [[ "${DESTINATION_EXISTS}" -eq 1 && "${FORCE_RESTORE}" -eq 0 ]]; then
            CHOSEN_RESTORE_MODE="sync-only"
            DECISION_REASON="saved snapshot archive is stale and the destination already exists, so refreshing the helper surface in place is safer"
        else
            CHOSEN_RESTORE_MODE="sync-helper-surface"
            DECISION_REASON="saved snapshot archive is stale, so a synced restore keeps the restored checkout aligned with the current helper surface"
        fi
        ;;
    plain)
        CHOSEN_RESTORE_MODE="plain"
        ;;
    *)
        echo "Unknown recommended restore mode from archive-surface helper: ${RECOMMENDED_RESTORE_MODE}" >&2
        exit 1
        ;;
esac

RESTORE_ARGS=(
    bash
    "${RESTORE_HELPER}"
    --browser-root
    "${REPO_ROOT}"
    --helper-root
    "${HELPER_ROOT}"
    --memory-root
    "${MEMORY_ROOT}"
    --archive
    "${ARCHIVE_PATH}"
    --destination
    "${DESTINATION}"
)

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    RESTORE_ARGS+=(--fallback-zig-archive "${FALLBACK_ZIG_ARCHIVE}")
fi
if [[ "${FORCE_RESTORE}" -eq 1 ]]; then
    RESTORE_ARGS+=(--force)
fi
case "${CHOSEN_RESTORE_MODE}" in
    sync-helper-surface)
        RESTORE_ARGS+=(--sync-helper-surface)
        ;;
    sync-only)
        RESTORE_ARGS+=(--sync-only)
        ;;
esac
if [[ "${CHECK_ONLY}" -eq 1 ]]; then
    RESTORE_ARGS+=(--check-only)
fi

RESTORE_COMMAND=""
for arg in "${RESTORE_ARGS[@]}"; do
    if [[ -n "${RESTORE_COMMAND}" ]]; then
        RESTORE_COMMAND+=" "
    fi
    RESTORE_COMMAND+="$(format_shell_arg "${arg}")"
done

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "issue3-saved-browser-snapshot-auto-sync-route",
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "follow_up_helper_root": ${FOLLOW_UP_HELPER_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "archive_path": ${ARCHIVE_PATH@Q},
    "destination": ${DESTINATION@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "check_only": ${CHECK_ONLY},
    "force_restore": ${FORCE_RESTORE},
    "destination_exists": ${DESTINATION_EXISTS},
    "recommended_restore_mode": ${RECOMMENDED_RESTORE_MODE@Q},
    "chosen_restore_mode": ${CHOSEN_RESTORE_MODE@Q},
    "decision_reason": ${DECISION_REASON@Q},
    "missing_path_count": int(${MISSING_PATH_COUNT}),
    "missing_paths": json.loads(${MISSING_PATHS_JSON@Q}),
    "restore_command": ${RESTORE_COMMAND@Q},
}, indent=2))
PY
    exit 0
fi

echo "Google issue #3 saved browser snapshot auto-sync restore route"
echo
echo "Repo root:               ${REPO_ROOT}"
echo "Helper root:             ${HELPER_ROOT}"
echo "Follow-up helper root:   ${FOLLOW_UP_HELPER_ROOT}"
echo "Memory root:             ${MEMORY_ROOT}"
echo "Snapshot archive:        ${ARCHIVE_PATH}"
echo "Restore destination:     ${DESTINATION}"
echo "Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the helper root}"
echo "Destination exists:      $([[ "${DESTINATION_EXISTS}" -eq 1 ]] && echo yes || echo no)"
echo "Recommended restore:     ${RECOMMENDED_RESTORE_MODE}"
echo "Chosen restore mode:     ${CHOSEN_RESTORE_MODE}"
echo "Missing helper paths:    ${MISSING_PATH_COUNT}"
echo "Decision reason:         ${DECISION_REASON}"
echo
if [[ "${MISSING_PATH_COUNT}" -gt 0 ]]; then
    echo "Missing archive helper paths:"
    python3 -c 'import json,sys; [print(f"  - {item}") for item in json.loads(sys.stdin.read())]' <<<"${MISSING_PATHS_JSON}"
    echo
fi
if [[ "${CHECK_ONLY}" -eq 1 ]]; then
    echo "Suggested command:"
else
    echo "Running command:"
fi
echo "  ${RESTORE_COMMAND}"

if [[ "${CHECK_ONLY}" -eq 1 ]]; then
    exit 0
fi

"${RESTORE_ARGS[@]}"
