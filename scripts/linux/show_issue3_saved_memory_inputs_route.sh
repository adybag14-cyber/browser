#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_memory_inputs_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--agent-files-root /path/to/workspace/agent_files] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the saved-Memory-inputs route for the blocked issue #3 Linux or WSL
re-entry path.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
MEMORY_ROOT=""
AGENT_FILES_ROOT=""
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
        --agent-files-root)
            AGENT_FILES_ROOT="$2"
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
if [[ -z "${AGENT_FILES_ROOT}" ]]; then
    AGENT_FILES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/agent_files"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${AGENT_FILES_ROOT}/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

PRECHECK_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --agent-files-root $(format_shell_arg "${AGENT_FILES_ROOT}")"
SAVED_BROWSER_SNAPSHOT_ROUTE_COMMAND="bash scripts/linux/show_issue3_saved_browser_snapshot_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}")"
LINUX_BUILD_READINESS_ROUTE_COMMAND="bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${MEMORY_ROOT}/repo_archives/browser")"
RUNTIME_REENTRY_ROUTE_COMMAND="bash scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}")"
SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    PRECHECK_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_BROWSER_SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_READINESS_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_REENTRY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

REPO_SNAPSHOT_PATH="${MEMORY_ROOT}/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
BLOCKER_INTELLIGENCE_PATH="${MEMORY_ROOT}/repo_archives/browser/blocker_intelligence.yaml"
DEPENDENCIES_ROOT="${MEMORY_ROOT}/repo_archives/browser/dependencies"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 saved Memory inputs route",
    "repo_root": ${REPO_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "agent_files_root": ${AGENT_FILES_ROOT@Q},
    "repo_snapshot_path": ${REPO_SNAPSHOT_PATH@Q},
    "blocker_intelligence_path": ${BLOCKER_INTELLIGENCE_PATH@Q},
    "dependencies_root": ${DEPENDENCIES_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "saved_memory_preflight": ${PRECHECK_COMMAND@Q},
        "saved_browser_snapshot_route": ${SAVED_BROWSER_SNAPSHOT_ROUTE_COMMAND@Q},
        "linux_build_readiness_route": ${LINUX_BUILD_READINESS_ROUTE_COMMAND@Q},
        "runtime_reentry_route": ${RUNTIME_REENTRY_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run the surface_check command first so missing docs or helper drift fails fast before the run blames missing Memory inputs.",
        "Run the saved_memory_preflight command before restore, build-readiness, or runtime helpers when the route depends on the saved repo snapshot and dependency bundles.",
        "Use the saved_browser_snapshot_route command when the saved archive exists but there is still no reusable checkout for Linux or WSL follow-up.",
        "Use the linux_build_readiness_route command after the saved-Memory preflight passes and the next blocker is still Rust, Zig, offline dependency staging, or prebuilt V8 readiness.",
        "Use the runtime_reentry_route command only after the saved checkout exists and the environment gates are no longer the blocker.",
        "Treat the attached Zig 0.17 dev bundle as surfaced fallback input only; do not treat it as honest issue #3 validation evidence for this branch."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 saved Memory inputs route

Repo root:               ${REPO_ROOT}
Memory root:             ${MEMORY_ROOT}
Agent files root:        ${AGENT_FILES_ROOT}
Saved repo snapshot:     ${REPO_SNAPSHOT_PATH}
Blocker intelligence:    ${BLOCKER_INTELLIGENCE_PATH}
Dependencies root:       ${DEPENDENCIES_ROOT}
Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Saved-Memory preflight:
    ${PRECHECK_COMMAND}

  Restore route when no reusable checkout exists yet:
    ${SAVED_BROWSER_SNAPSHOT_ROUTE_COMMAND}

  Linux or WSL build-readiness route:
    ${LINUX_BUILD_READINESS_ROUTE_COMMAND}

  Direct runtime re-entry route:
    ${RUNTIME_REENTRY_ROUTE_COMMAND}

Working rules
=============
  - Run the surface check first so missing docs or helper drift fails fast before the run blames missing Memory inputs.
  - Run the saved-Memory preflight before restore, build-readiness, or runtime helpers when the route depends on the saved repo snapshot and dependency bundles.
  - Use the restore route when the saved archive exists but there is still no reusable checkout for Linux or WSL follow-up.
  - Use the Linux or WSL build-readiness route after the saved-Memory preflight passes and the next blocker is still Rust, Zig, offline dependency staging, or prebuilt V8 readiness.
  - Use the direct runtime re-entry route only after the saved checkout exists and the environment gates are no longer the blocker.
  - Treat the attached Zig 0.17 dev bundle as surfaced fallback input only, not as honest issue #3 validation evidence for this branch.
EOF
