#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_staged_rust_toolchain_candidates_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--toolchains-root /path/to/toolchains] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--json]

Print the staged Rust toolchain candidates route for the blocked issue #3 Linux
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
TOOLCHAINS_ROOT=""
SAVED_ARCHIVES_ROOT=""
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

ROUTE_NOTE_PATH="${REPO_ROOT}/docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md"
PROGRESS_TRACKER_ROUTE_PATH="${REPO_ROOT}/docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
STAGED_CANDIDATES_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_staged_rust_toolchain_candidates.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
SAVED_RUST_ARCHIVE_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
SAVED_RUST_TOOLCHAIN_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchain-parent $(format_shell_arg "${TOOLCHAINS_ROOT}")"
SAVED_RUST_BUILD_BRIDGE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_rust_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
PROGRESS_TRACKER_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_progress_tracker_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 staged Rust toolchain candidates route",
    "repo_root": ${REPO_ROOT@Q},
    "toolchains_root": ${TOOLCHAINS_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "route_note_path": ${ROUTE_NOTE_PATH@Q},
    "progress_tracker_route_path": ${PROGRESS_TRACKER_ROUTE_PATH@Q},
    "commands": {
        "surface_check": ${SURFACE_COMMAND@Q},
        "staged_toolchain_candidates": ${STAGED_CANDIDATES_COMMAND@Q},
        "saved_rust_archive_route": ${SAVED_RUST_ARCHIVE_ROUTE_COMMAND@Q},
        "saved_rust_toolchain_route": ${SAVED_RUST_TOOLCHAIN_ROUTE_COMMAND@Q},
        "saved_rust_build_bridge": ${SAVED_RUST_BUILD_BRIDGE_COMMAND@Q},
        "progress_tracker_route": ${PROGRESS_TRACKER_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run the route surface check first so missing docs or helper drift fails before the run trusts staged-toolchain discovery output.",
        "Use the staged-toolchain candidate helper before saved-archive restore so a matching Rust 1.79.x toolchain can be reused instead of unpacked again.",
        "If a matching staged candidate already exists, keep the saved Rust toolchain route visible only when the exact restore or export ladder is still needed.",
        "If no matching staged candidate exists, hand off to the saved Rust archive route or the saved-Rust build-readiness bridge instead of rebuilding restore commands by hand.",
        "Use the issue #11 progress-tracker route when this slice is still about saved inputs, toolchain reuse, or Linux or WSL readiness gates.",
        "Default root discovery walks up ancestor directories first, so restored nested checkouts can reuse the nearest memory and toolchains roots without hand overrides."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 staged Rust toolchain candidates route

Repo root:               ${REPO_ROOT}
Toolchains root:         ${TOOLCHAINS_ROOT}
Saved archives root:     ${SAVED_ARCHIVES_ROOT}
Route note:              ${ROUTE_NOTE_PATH}
Progress tracker route:  ${PROGRESS_TRACKER_ROUTE_PATH}

Read first
==========
  docs/ISSUE3_STAGED_RUST_TOOLCHAIN_CANDIDATES_ROUTE.md
  docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md

Suggested route
===============
  Route surface check:
    ${SURFACE_COMMAND}

  Staged toolchain candidate discovery:
    ${STAGED_CANDIDATES_COMMAND}

  Saved Rust archive route:
    ${SAVED_RUST_ARCHIVE_ROUTE_COMMAND}

  Saved Rust toolchain route:
    ${SAVED_RUST_TOOLCHAIN_ROUTE_COMMAND}

  Saved-Rust build-readiness bridge:
    ${SAVED_RUST_BUILD_BRIDGE_COMMAND}

  Issue #11 progress-tracker route:
    ${PROGRESS_TRACKER_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface check first so missing docs or helper drift fails before the run trusts staged-toolchain discovery output.
  - Use the staged-toolchain candidate helper before saved-archive restore so a matching Rust 1.79.x toolchain can be reused instead of unpacked again.
  - If a matching staged candidate already exists, keep the saved Rust toolchain route visible only when the exact restore or export ladder is still needed.
  - If no matching staged candidate exists, hand off to the saved Rust archive route or the saved-Rust build-readiness bridge instead of rebuilding restore commands by hand.
  - Use the issue #11 progress-tracker route when this slice is still about saved inputs, toolchain reuse, or Linux or WSL readiness gates.
  - Default root discovery walks up ancestor directories first, so restored nested checkouts can reuse the nearest memory and toolchains roots without hand overrides.
EOF
