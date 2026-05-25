#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_rust_build_readiness_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--toolchains-root /path/to/toolchains] \
    [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \
    [--json]

Print a compact bridge from the issue #11 progress tracker through the saved
Rust candidate helpers and back into the broader Linux build-readiness route.
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
SAVED_ARCHIVES_ROOT=""
TOOLCHAINS_ROOT=""
RUST_TOOLCHAIN_DIR=""
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
        --rust-toolchain-dir)
            RUST_TOOLCHAIN_DIR="$2"
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
    SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser"
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
fi
if [[ -z "${RUST_TOOLCHAIN_DIR}" ]]; then
    RUST_TOOLCHAIN_DIR="${TOOLCHAINS_ROOT}/rust-1.79.0"
fi

SURFACE_CHECK_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh"
PROGRESS_TRACKER_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_progress_tracker_route_surface.sh"
PROGRESS_TRACKER_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_progress_tracker_route.sh"
SAVED_RUST_ARCHIVE_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh"
SAVED_RUST_ARCHIVE_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh"
SAVED_RUST_ARCHIVE_HELPER="${REPO_ROOT}/scripts/check_issue3_saved_rust_archive_candidates.py"
STAGED_RUST_HELPER="${REPO_ROOT}/scripts/check_issue3_staged_rust_toolchain_candidates.py"
SAVED_RUST_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh"
SAVED_RUST_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
BUILD_READINESS_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
BUILD_READINESS_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh"
BUILD_READINESS_HELPER="${REPO_ROOT}/scripts/check_linux_build_readiness.py"

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${SURFACE_CHECK_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
PROGRESS_TRACKER_SURFACE_COMMAND="bash $(format_shell_arg "${PROGRESS_TRACKER_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
PROGRESS_TRACKER_ROUTE_COMMAND="bash $(format_shell_arg "${PROGRESS_TRACKER_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_RUST_ARCHIVE_SURFACE_COMMAND="bash $(format_shell_arg "${SAVED_RUST_ARCHIVE_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_RUST_ARCHIVE_ROUTE_COMMAND="bash $(format_shell_arg "${SAVED_RUST_ARCHIVE_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_RUST_ARCHIVE_HELPER_COMMAND="python $(format_shell_arg "${SAVED_RUST_ARCHIVE_HELPER}") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
STAGED_RUST_HELPER_COMMAND="python $(format_shell_arg "${STAGED_RUST_HELPER}") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
SAVED_RUST_SURFACE_COMMAND="bash $(format_shell_arg "${SAVED_RUST_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_RUST_ROUTE_COMMAND="bash $(format_shell_arg "${SAVED_RUST_ROUTE_SCRIPT}") --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
BUILD_READINESS_SURFACE_COMMAND="bash $(format_shell_arg "${BUILD_READINESS_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
BUILD_READINESS_ROUTE_COMMAND="bash $(format_shell_arg "${BUILD_READINESS_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --rust-toolchain-dir $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
BUILD_READINESS_HELPER_COMMAND="python $(format_shell_arg "${BUILD_READINESS_HELPER}") --repo-root $(format_shell_arg "${REPO_ROOT}") --skip-zig-check"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 saved Rust build-readiness bridge route",
    "repo_root": ${REPO_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "toolchains_root": ${TOOLCHAINS_ROOT@Q},
    "rust_toolchain_dir": ${RUST_TOOLCHAIN_DIR@Q},
    "read_first": [
        "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
        "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md",
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md"
    ],
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "progress_tracker_surface": ${PROGRESS_TRACKER_SURFACE_COMMAND@Q},
        "progress_tracker_route": ${PROGRESS_TRACKER_ROUTE_COMMAND@Q},
        "saved_rust_archive_surface": ${SAVED_RUST_ARCHIVE_SURFACE_COMMAND@Q},
        "saved_rust_archive_route": ${SAVED_RUST_ARCHIVE_ROUTE_COMMAND@Q},
        "saved_rust_archive_helper": ${SAVED_RUST_ARCHIVE_HELPER_COMMAND@Q},
        "staged_rust_helper": ${STAGED_RUST_HELPER_COMMAND@Q},
        "saved_rust_surface": ${SAVED_RUST_SURFACE_COMMAND@Q},
        "saved_rust_route": ${SAVED_RUST_ROUTE_COMMAND@Q},
        "build_readiness_surface": ${BUILD_READINESS_SURFACE_COMMAND@Q},
        "build_readiness_route": ${BUILD_READINESS_ROUTE_COMMAND@Q},
        "build_readiness_helper": ${BUILD_READINESS_HELPER_COMMAND@Q}
    }
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 saved Rust build-readiness bridge route

Repo root:           ${REPO_ROOT}
Saved archive root:  ${SAVED_ARCHIVES_ROOT}
Toolchains root:     ${TOOLCHAINS_ROOT}
Rust toolchain dir:  ${RUST_TOOLCHAIN_DIR}

Read first
==========
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
  docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Progress-tracker route surface check:
    ${PROGRESS_TRACKER_SURFACE_COMMAND}

  Progress-tracker route:
    ${PROGRESS_TRACKER_ROUTE_COMMAND}

  Saved Rust archive-candidate route surface check:
    ${SAVED_RUST_ARCHIVE_SURFACE_COMMAND}

  Saved Rust archive-candidate route:
    ${SAVED_RUST_ARCHIVE_ROUTE_COMMAND}

  Saved Rust archive candidates:
    ${SAVED_RUST_ARCHIVE_HELPER_COMMAND}

  Staged Rust toolchain candidates:
    ${STAGED_RUST_HELPER_COMMAND}

  Saved Rust route surface check:
    ${SAVED_RUST_SURFACE_COMMAND}

  Saved Rust route:
    ${SAVED_RUST_ROUTE_COMMAND}

  Linux build-readiness surface check:
    ${BUILD_READINESS_SURFACE_COMMAND}

  Linux build-readiness route:
    ${BUILD_READINESS_ROUTE_COMMAND}

  Linux build-readiness helper:
    ${BUILD_READINESS_HELPER_COMMAND}

Working rules
=============
  - Run the surface check first so missing branch-local route files fail fast before the Rust handoff is trusted.
  - Run the progress-tracker surface and route first when issue #11 should stay visible as the current status lane.
  - Run the saved Rust archive-candidate surface and route before choosing a saved archive by hand.
  - Run the staged Rust toolchain helper before restoring the saved archive again so a reusable Rust 1.79.x toolchain can be reused first.
  - Reopen the saved Rust route after candidate discovery when the exact restore and shell-export surface is still needed.
  - Hand back to the broader Linux build-readiness route as soon as the Rust toolchain stops being the main blocker.
EOF
