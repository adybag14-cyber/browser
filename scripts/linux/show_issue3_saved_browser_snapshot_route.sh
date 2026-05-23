#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_browser_snapshot_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--archive /path/to/01-browser-fork-headed-mode-foundation.zip] \
    [--destination /path/to/extracted/browser-checkout] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the saved-browser-snapshot restore route for the blocked issue #3 Linux or
WSL re-entry path.
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
DEFAULT_DESTINATION_NAME="browser-memory-snapshot"
DEFAULT_ARCHIVE_NAME="01-browser-fork-headed-mode-foundation.zip"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
MEMORY_ROOT=""
ARCHIVE_PATH=""
DESTINATION=""
FALLBACK_ZIG_ARCHIVE=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
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
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory"
fi
if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${MEMORY_ROOT}/repo_archives/browser/${DEFAULT_ARCHIVE_NAME}"
fi
if [[ -z "${DESTINATION}" ]]; then
    DESTINATION="$(cd "${REPO_ROOT}/.." && pwd)/${DEFAULT_DESTINATION_NAME}"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ROUTE_SURFACE_COMMAND="bash scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh --repo-root $(format_shell_arg "${REPO_ROOT}")"
SURFACE_CHECK_COMMAND="bash scripts/linux/restore_saved_browser_snapshot.sh --browser-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}") --check-only"
RESTORE_COMMAND="bash scripts/linux/restore_saved_browser_snapshot.sh --browser-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --destination $(format_shell_arg "${DESTINATION}")"
SAVED_MEMORY_PREFLIGHT_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root $(format_shell_arg "${DESTINATION}")"
LINUX_BUILD_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root $(format_shell_arg "${DESTINATION}")"
RUNTIME_ROUTE_COMMAND="bash scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root $(format_shell_arg "${DESTINATION}")"
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 saved browser snapshot restore route",
    "repo_root": ${REPO_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "archive_path": ${ARCHIVE_PATH@Q},
    "destination": ${DESTINATION@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "commands": {
        "route_surface": ${ROUTE_SURFACE_COMMAND@Q},
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "restore": ${RESTORE_COMMAND@Q},
        "saved_memory_preflight": ${SAVED_MEMORY_PREFLIGHT_COMMAND@Q},
        "linux_build_route": ${LINUX_BUILD_ROUTE_COMMAND@Q},
        "runtime_route": ${RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run route_surface first so missing branch-local docs or helper drift fails fast before the restore helper is trusted.",
        "Run surface_check next so the saved archive path, top-level folder, and follow-up commands are confirmed before extraction.",
        "Use restore only when the route really needs a disposable checkout for Linux or WSL helper validation.",
        "Run saved_memory_preflight against the restored checkout before trusting broader build-readiness or runtime helper output.",
        "Use linux_build_route when the next blocked step is still toolchain or offline dependency staging.",
        "Use runtime_route only after the saved checkout exists and the route is ready to reopen the narrowed Page.zig and win32_backend.zig lane."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 saved browser snapshot restore route

Repo root:            ${REPO_ROOT}
Memory root:          ${MEMORY_ROOT}
Snapshot archive:     ${ARCHIVE_PATH}
Restore destination:  ${DESTINATION}
Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Route surface check:
    ${ROUTE_SURFACE_COMMAND}

  Restore helper surface check:
    ${SURFACE_CHECK_COMMAND}

  Restore the saved checkout:
    ${RESTORE_COMMAND}

  Saved-Memory preflight against the restored checkout:
    ${SAVED_MEMORY_PREFLIGHT_COMMAND}

  Linux or WSL build-readiness route from the restored checkout:
    ${LINUX_BUILD_ROUTE_COMMAND}

  Direct runtime re-entry route from the restored checkout:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface check first so missing docs or helper drift fails fast before the restore helper is trusted.
  - Run the restore helper surface check next so the saved archive path, top-level folder, and follow-up commands are confirmed before extraction.
  - Use the restore step when the route needs a disposable checkout for helper validation without relying on live GitHub file publication.
  - Run the saved-Memory preflight against the restored checkout before trusting broader build-readiness or runtime helper output.
  - Use the Linux or WSL build-readiness route when the next blocked step is still toolchain or offline dependency staging.
  - Reopen the direct Page.zig plus win32_backend.zig runtime lane only after the restored checkout exists and the branch-compatible validation gate is no longer the blocker.
EOF