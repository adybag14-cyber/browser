#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--toolchains-root /path/to/toolchains] \
    [--json]

Print the saved Rust archive candidates route for the blocked issue #3 Linux or
WSL re-entry lane.
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

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

resolve_path() {
    python3 - "$1" <<'PY'
import pathlib
import sys

print(pathlib.Path(sys.argv[1]).resolve())
PY
}

locate_first_existing() {
    python3 - "$1" "$2" <<'PY'
import pathlib
import sys

start = pathlib.Path(sys.argv[1]).resolve()
relative = pathlib.Path(sys.argv[2])
for ancestor in (start, *start.parents):
    candidate = ancestor / relative
    if candidate.exists():
        print(candidate.resolve())
        break
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
SAVED_ARCHIVES_ROOT=""
TOOLCHAINS_ROOT=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
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
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    DISCOVERED_SAVED_ARCHIVES_ROOT="$(locate_first_existing "${REPO_ROOT}" "memory/repo_archives/browser" || true)"
    if [[ -n "${DISCOVERED_SAVED_ARCHIVES_ROOT}" ]]; then
        SAVED_ARCHIVES_ROOT="${DISCOVERED_SAVED_ARCHIVES_ROOT}"
    else
        SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser"
    fi
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    DISCOVERED_TOOLCHAINS_ROOT="$(locate_first_existing "${REPO_ROOT}" "toolchains" || true)"
    if [[ -n "${DISCOVERED_TOOLCHAINS_ROOT}" ]]; then
        TOOLCHAINS_ROOT="${DISCOVERED_TOOLCHAINS_ROOT}"
    else
        TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
    fi
fi
TOOLCHAINS_ROOT="$(resolve_path "${TOOLCHAINS_ROOT}")"

ROUTE_NOTE_PATH="${REPO_ROOT}/docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md"
TOOLCHAIN_ROUTE_NOTE_PATH="${REPO_ROOT}/docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md"
PROGRESS_TRACKER_ROUTE_PATH="${REPO_ROOT}/docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
CANDIDATE_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_rust_archive_candidates.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
STAGED_CANDIDATES_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_staged_rust_toolchain_candidates.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
RESTORE_ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
RESTORE_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchain-parent $(format_shell_arg "${TOOLCHAINS_ROOT}")"
PROGRESS_TRACKER_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_progress_tracker_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --rust-toolchain-dir $(format_shell_arg "${TOOLCHAINS_ROOT}/rust-1.79.0")"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 saved Rust archive candidates route",
    "repo_root": ${REPO_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "toolchains_root": ${TOOLCHAINS_ROOT@Q},
    "route_note_path": ${ROUTE_NOTE_PATH@Q},
    "saved_rust_toolchain_route_path": ${TOOLCHAIN_ROUTE_NOTE_PATH@Q},
    "progress_tracker_route_path": ${PROGRESS_TRACKER_ROUTE_PATH@Q},
    "commands": {
        "surface_check": ${SURFACE_COMMAND@Q},
        "candidate_discovery": ${CANDIDATE_COMMAND@Q},
        "staged_toolchain_candidates": ${STAGED_CANDIDATES_COMMAND@Q},
        "saved_rust_toolchain_route_surface": ${RESTORE_ROUTE_SURFACE_COMMAND@Q},
        "saved_rust_toolchain_route": ${RESTORE_ROUTE_COMMAND@Q},
        "progress_tracker_route": ${PROGRESS_TRACKER_ROUTE_COMMAND@Q},
        "linux_build_readiness_route": ${BUILD_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run the surface check first so route drift fails before the run trusts saved Rust archive discovery output.",
        "Use the candidate discovery helper before hand-picking a saved Rust archive from the dependencies folder.",
        "Run the staged-toolchain candidate helper before restore so a matching Rust 1.79.0 toolchain can be reused instead of unpacked again.",
        "Hand off to the saved Rust toolchain route once the preferred archive or reusable staged candidate is known.",
        "Use the issue #11 progress-tracker route when this slice is still part of the environment-gated Linux or WSL re-entry lane.",
        "Return to the broader Linux build-readiness route when the Rust archive decision is settled and the next rerun needs the wider helper ladder again.",
        "The saved_archives_root override accepts either repo_archives/browser or repo_archives/browser/dependencies and is normalized before discovery runs.",
        "When the checkout is nested or restored deeper in the workspace, this route reuses the nearest practical ancestor Memory and toolchains roots before it falls back to the simple sibling layout."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 saved Rust archive candidates route

Repo root:               ${REPO_ROOT}
Saved archives root:     ${SAVED_ARCHIVES_ROOT}
Toolchains root:         ${TOOLCHAINS_ROOT}
Route note:              ${ROUTE_NOTE_PATH}
Saved Rust route:        ${TOOLCHAIN_ROUTE_NOTE_PATH}
Progress tracker route:  ${PROGRESS_TRACKER_ROUTE_PATH}

Read first
==========
  docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md

Suggested route
===============
  Route surface check:
    ${SURFACE_COMMAND}

  Saved archive candidate discovery:
    ${CANDIDATE_COMMAND}

  Staged toolchain candidate discovery:
    ${STAGED_CANDIDATES_COMMAND}

  Saved Rust toolchain route surface check:
    ${RESTORE_ROUTE_SURFACE_COMMAND}

  Saved Rust toolchain route:
    ${RESTORE_ROUTE_COMMAND}

  Issue #11 progress-tracker route:
    ${PROGRESS_TRACKER_ROUTE_COMMAND}

  Broader Linux build-readiness route:
    ${BUILD_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface check first so missing docs or helper drift fails before the saved Rust archive itself is blamed.
  - Use the candidate discovery helper before hand-picking a saved Rust archive from the dependencies folder.
  - Run the staged-toolchain candidate helper before restore so a matching Rust 1.79.0 toolchain can be reused instead of unpacked again.
  - Hand off to the saved Rust toolchain route once the preferred archive or reusable staged candidate is known.
  - Use the issue #11 progress-tracker route when this slice is still part of the environment-gated Linux or WSL re-entry lane.
  - Return to the broader Linux build-readiness route when the Rust archive decision is settled and the next rerun needs the wider helper ladder again.
  - The saved-archives root override accepts either repo_archives/browser or repo_archives/browser/dependencies and is normalized before discovery runs.
  - When the checkout is nested or restored deeper in the workspace, this route reuses the nearest practical ancestor Memory and toolchains roots before it falls back to the simple sibling layout.
EOF