#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_build_readiness_rerun_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the exact build-readiness rerun route for the blocked issue #3 Linux or
WSL re-entry lane after a staged Zig candidate is already in play.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
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
REPO_ROOT="${DEFAULT_REPO_ROOT}"
TOOLCHAINS_ROOT=""
SAVED_ARCHIVES_ROOT=""
OFFLINE_DEPS_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --toolchains-root)
            TOOLCHAINS_ROOT="$2"
            shift 2
            ;;
        --saved-archives-root)
            SAVED_ARCHIVES_ROOT="$2"
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
WORKSPACE_ROOT="$(cd "${REPO_ROOT}/.." && pwd)"
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="${WORKSPACE_ROOT}/toolchains"
fi
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${WORKSPACE_ROOT}/memory/repo_archives/browser"
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="${WORKSPACE_ROOT}/offline-deps"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${WORKSPACE_ROOT}/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ROUTE_NOTE_PATH="${REPO_ROOT}/docs/ISSUE3_BUILD_READINESS_RERUN_ROUTE.md"
PROGRESS_TRACKER_ROUTE_PATH="${REPO_ROOT}/docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
BUILD_ROUTE_PATH="${REPO_ROOT}/docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
RECOVERY_ROUTE_PATH="${REPO_ROOT}/docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md"

SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_build_readiness_rerun_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
STAGED_ZIG_CANDIDATES_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_staged_zig_toolchain_candidates.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
MATCHING_LINE_GATE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_match.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}")"
RERUN_HELPER_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_build_readiness_rerun.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
RECOVERY_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
PROGRESS_TRACKER_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_progress_tracker_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    MATCHING_LINE_GATE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RERUN_HELPER_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RECOVERY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    PROGRESS_TRACKER_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 build-readiness rerun route",
    "repo_root": ${REPO_ROOT@Q},
    "toolchains_root": ${TOOLCHAINS_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "offline_deps_root": ${OFFLINE_DEPS_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "route_note_path": ${ROUTE_NOTE_PATH@Q},
    "progress_tracker_route_path": ${PROGRESS_TRACKER_ROUTE_PATH@Q},
    "build_route_path": ${BUILD_ROUTE_PATH@Q},
    "recovery_route_path": ${RECOVERY_ROUTE_PATH@Q},
    "commands": {
        "surface_check": ${SURFACE_COMMAND@Q},
        "staged_zig_candidates": ${STAGED_ZIG_CANDIDATES_COMMAND@Q},
        "matching_line_gate": ${MATCHING_LINE_GATE_COMMAND@Q},
        "exact_rerun_helper": ${RERUN_HELPER_COMMAND@Q},
        "linux_build_readiness_route": ${BUILD_ROUTE_COMMAND@Q},
        "zig_toolchain_recovery_route": ${RECOVERY_ROUTE_COMMAND@Q},
        "progress_tracker_route": ${PROGRESS_TRACKER_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run the surface check first so note drift or helper drift fails before a scheduled run trusts the exact rerun command.",
        "Surface staged Zig candidates before the rerun helper so a matching toolchain is visible on the same branch-local route.",
        "Run the matching-line gate before the rerun helper so the same shared toolchains root proves a real 0.15.x candidate exists.",
        "Use the exact rerun helper once a matching staged Zig candidate is available and the broader Linux or WSL readiness command is the next step.",
        "Keep the issue #11 progress-tracker route visible while this slice is still part of the environment-gated re-entry lane.",
        "Return to the broader Linux build-readiness route once the rerun command is settled.",
        "Return to the broader Zig recovery route when no matching staged Zig candidate is available yet."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 build-readiness rerun route

Repo root:               ${REPO_ROOT}
Toolchains root:         ${TOOLCHAINS_ROOT}
Saved archives root:     ${SAVED_ARCHIVES_ROOT}
Offline deps root:       ${OFFLINE_DEPS_ROOT}
Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Route note:              ${ROUTE_NOTE_PATH}
Progress tracker route:  ${PROGRESS_TRACKER_ROUTE_PATH}
Linux build route:       ${BUILD_ROUTE_PATH}
Recovery route:          ${RECOVERY_ROUTE_PATH}

Read first
==========
  docs/ISSUE3_BUILD_READINESS_RERUN_ROUTE.md
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md

Suggested route
===============
  Route surface check:
    ${SURFACE_COMMAND}

  Staged Zig candidate discovery:
    ${STAGED_ZIG_CANDIDATES_COMMAND}

  Matching-line gate:
    ${MATCHING_LINE_GATE_COMMAND}

  Exact readiness rerun helper:
    ${RERUN_HELPER_COMMAND}

  Issue #11 progress-tracker route:
    ${PROGRESS_TRACKER_ROUTE_COMMAND}

  Broader Linux build-readiness route:
    ${BUILD_ROUTE_COMMAND}

  Broader Zig toolchain recovery route:
    ${RECOVERY_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface check first so missing docs or helper drift fails before the printed rerun command is trusted.
  - Run the staged Zig candidate helper before the rerun helper so a reusable branch-compatible toolchain can be surfaced first.
  - Run the matching-line gate before the rerun helper so the shared toolchains root proves a real 0.15.x candidate exists.
  - Use the exact rerun helper once the staged Zig line is known and the broader Linux or WSL readiness command is the next step.
  - Keep the issue #11 progress-tracker route visible while this slice is still part of the environment-gated re-entry lane.
EOF
