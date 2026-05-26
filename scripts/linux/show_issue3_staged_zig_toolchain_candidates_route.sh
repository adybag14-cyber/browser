#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_staged_zig_toolchain_candidates_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the staged Zig toolchain candidates route for the blocked issue #3 Linux
or WSL re-entry lane.
EOF
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

resolve_first_existing_path() {
    local start="$1"
    local relative_path="$2"
    local current="$start"
    while true; do
        if [[ -e "${current}/${relative_path}" ]]; then
            printf '%s\n' "${current}/${relative_path}"
            return 0
        fi
        if [[ "${current}" == "/" ]]; then
            return 1
        fi
        current="$(dirname "${current}")"
    done
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
TOOLCHAINS_ROOT=""
SAVED_ARCHIVES_ROOT=""
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
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="$(resolve_first_existing_path "${REPO_ROOT}" "toolchains" || true)"
    if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
        TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
    fi
fi
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="$(resolve_first_existing_path "${REPO_ROOT}" "memory/repo_archives/browser" || true)"
    if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
        SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser"
    fi
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(resolve_first_existing_path "${REPO_ROOT}" "agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz" || true)"
    if [[ -z "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    fi
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ROUTE_NOTE_PATH="${REPO_ROOT}/docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md"
PROGRESS_TRACKER_ROUTE_PATH="${REPO_ROOT}/docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_staged_zig_toolchain_candidates_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
STAGED_CANDIDATES_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_staged_zig_toolchain_candidates.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
MATCHING_LINE_GATE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_match.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}")"
BUILD_RERUN_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_build_readiness_rerun.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}")"
SAVED_ZIG_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
RECOVERY_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
PROGRESS_TRACKER_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_progress_tracker_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    MATCHING_LINE_GATE_COMMAND="${MATCHING_LINE_GATE_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_RERUN_COMMAND="${BUILD_RERUN_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ZIG_ROUTE_COMMAND="${SAVED_ZIG_ROUTE_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RECOVERY_ROUTE_COMMAND="${RECOVERY_ROUTE_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    PROGRESS_TRACKER_ROUTE_COMMAND="${PROGRESS_TRACKER_ROUTE_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 staged Zig toolchain candidates route",
    "repo_root": ${REPO_ROOT@Q},
    "toolchains_root": ${TOOLCHAINS_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "route_note_path": ${ROUTE_NOTE_PATH@Q},
    "progress_tracker_route_path": ${PROGRESS_TRACKER_ROUTE_PATH@Q},
    "commands": {
        "surface_check": ${SURFACE_COMMAND@Q},
        "staged_toolchain_candidates": ${STAGED_CANDIDATES_COMMAND@Q},
        "matching_line_gate": ${MATCHING_LINE_GATE_COMMAND@Q},
        "build_readiness_rerun": ${BUILD_RERUN_COMMAND@Q},
        "saved_zig_archive_route": ${SAVED_ZIG_ROUTE_COMMAND@Q},
        "zig_recovery_route": ${RECOVERY_ROUTE_COMMAND@Q},
        "progress_tracker_route": ${PROGRESS_TRACKER_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run the route surface check first so missing docs or helper drift fails before the run trusts staged-toolchain discovery output.",
        "Use the staged-toolchain candidate helper before saved-archive restore so a matching Zig 0.15.x toolchain can be reused instead of unpacked again.",
        "Run the matching-line gate after staged-toolchain discovery so the branch's expected Zig line is proven before broader readiness is trusted.",
        "When a matching staged candidate exists, print the exact build-readiness rerun command before the broader helper is retried.",
        "If no matching staged candidate exists, hand off to the saved-Zig archive route or the broader Zig recovery route instead of rebuilding restore commands by hand.",
        "Use the issue #11 progress-tracker route when this slice is still about saved inputs, toolchain recovery, or Linux or WSL readiness gates.",
        "Default root discovery walks up ancestor directories first, so restored nested checkouts can reuse the nearest memory, toolchains, and agent_files roots without hand overrides."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 staged Zig toolchain candidates route

Repo root:               ${REPO_ROOT}
Toolchains root:         ${TOOLCHAINS_ROOT}
Saved archives root:     ${SAVED_ARCHIVES_ROOT}
Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Route note:              ${ROUTE_NOTE_PATH}
Progress tracker route:  ${PROGRESS_TRACKER_ROUTE_PATH}

Read first
==========
  docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md
  docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md

Suggested route
===============
  Route surface check:
    ${SURFACE_COMMAND}

  Staged toolchain candidate discovery:
    ${STAGED_CANDIDATES_COMMAND}

  Matching-line gate:
    ${MATCHING_LINE_GATE_COMMAND}

  Exact build-readiness rerun:
    ${BUILD_RERUN_COMMAND}

  Saved Zig archive route:
    ${SAVED_ZIG_ROUTE_COMMAND}

  Broader Zig recovery route:
    ${RECOVERY_ROUTE_COMMAND}

  Issue #11 progress-tracker route:
    ${PROGRESS_TRACKER_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface check first so missing docs or helper drift fails before the run trusts staged-toolchain discovery output.
  - Use the staged-toolchain candidate helper before saved-archive restore so a matching Zig 0.15.x toolchain can be reused instead of unpacked again.
  - Run the matching-line gate after staged-toolchain discovery so the branch's expected Zig line is proven before broader readiness is trusted.
  - When a matching staged candidate exists, print the exact build-readiness rerun command before the broader helper is retried.
  - If no matching staged candidate exists, hand off to the saved-Zig archive route or the broader Zig recovery route instead of rebuilding restore commands by hand.
  - Use the issue #11 progress-tracker route when this slice is still about saved inputs, toolchain recovery, or Linux or WSL readiness gates.
  - Default root discovery walks up ancestor directories first, so restored nested checkouts can reuse the nearest memory, toolchains, and agent_files roots without hand overrides.
EOF
