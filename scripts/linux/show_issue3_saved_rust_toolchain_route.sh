#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF_USAGE'
Usage:
  bash scripts/linux/show_issue3_saved_rust_toolchain_route.sh \
    [--browser-root /path/to/browser-repo] \
    [--dependencies-root /path/to/memory/repo_archives/browser/dependencies] \
    [--toolchain-root /path/to/toolchains/rust-1.79.0] \
    [--toolchain-parent /path/to/toolchains] \
    [--archive /path/to/rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz] \
    [--json]

Print the compact saved Rust toolchain restore route used by the Linux or WSL
issue #3 Enter-submit recovery path.
EOF_USAGE
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_BROWSER_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_TOOLCHAIN_DIR_NAME="rust-1.79.0"
DEFAULT_ARCHIVE_TOOLCHAIN_NAME="rust-1.79.0-x86_64-unknown-linux-gnu"
DEFAULT_ARCHIVE_NAME="01-${DEFAULT_ARCHIVE_TOOLCHAIN_NAME}.tar.xz"

BROWSER_ROOT="${DEFAULT_BROWSER_ROOT}"
DEPENDENCIES_ROOT=""
TOOLCHAIN_ROOT=""
TOOLCHAIN_PARENT=""
ARCHIVE_PATH=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --browser-root)
            BROWSER_ROOT="$2"
            shift 2
            ;;
        --dependencies-root)
            DEPENDENCIES_ROOT="$2"
            shift 2
            ;;
        --toolchain-root)
            TOOLCHAIN_ROOT="$2"
            shift 2
            ;;
        --toolchain-parent)
            TOOLCHAIN_PARENT="$2"
            shift 2
            ;;
        --archive)
            ARCHIVE_PATH="$2"
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

BROWSER_ROOT="$(cd "${BROWSER_ROOT}" && pwd)"
WORKSPACE_ROOT="$(cd "${BROWSER_ROOT}/.." && pwd)"
if [[ -z "${TOOLCHAIN_PARENT}" ]]; then
    TOOLCHAIN_PARENT="${WORKSPACE_ROOT}/toolchains"
fi
if [[ -z "${DEPENDENCIES_ROOT}" ]]; then
    DEPENDENCIES_ROOT="${WORKSPACE_ROOT}/memory/repo_archives/browser/dependencies"
fi
if [[ -z "${TOOLCHAIN_ROOT}" ]]; then
    TOOLCHAIN_ROOT="${TOOLCHAIN_PARENT}/${DEFAULT_TOOLCHAIN_DIR_NAME}"
fi
if [[ -z "${ARCHIVE_PATH}" ]]; then
    ARCHIVE_PATH="${DEPENDENCIES_ROOT}/${DEFAULT_ARCHIVE_NAME}"
fi

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${BROWSER_ROOT}/scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh") --repo-root $(format_shell_arg "${BROWSER_ROOT}")"
CHECK_ONLY_COMMAND="bash $(format_shell_arg "${BROWSER_ROOT}/scripts/linux/restore_saved_rust_toolchain.sh") --browser-root $(format_shell_arg "${BROWSER_ROOT}") --dependencies-root $(format_shell_arg "${DEPENDENCIES_ROOT}") --toolchain-root $(format_shell_arg "${TOOLCHAIN_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}") --check-only"
RESTORE_COMMAND="bash $(format_shell_arg "${BROWSER_ROOT}/scripts/linux/restore_saved_rust_toolchain.sh") --browser-root $(format_shell_arg "${BROWSER_ROOT}") --dependencies-root $(format_shell_arg "${DEPENDENCIES_ROOT}") --toolchain-root $(format_shell_arg "${TOOLCHAIN_ROOT}") --archive $(format_shell_arg "${ARCHIVE_PATH}")"
PATH_COMMAND="export PATH=$(format_shell_arg "${TOOLCHAIN_ROOT}/cargo/bin"):$(format_shell_arg "${TOOLCHAIN_ROOT}/rustc/bin"):\$PATH"
CARGO_COMMAND="export CARGO=$(format_shell_arg "${TOOLCHAIN_ROOT}/cargo/bin/cargo")"
RUSTC_COMMAND="export RUSTC=$(format_shell_arg "${TOOLCHAIN_ROOT}/rustc/bin/rustc")"
PREFLIGHT_COMMAND="python $(format_shell_arg "${BROWSER_ROOT}/scripts/check_linux_build_readiness.py") --repo-root $(format_shell_arg "${BROWSER_ROOT}") --skip-zig-check"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 saved Rust toolchain restore route",
    "browser_root": ${BROWSER_ROOT@Q},
    "dependencies_root": ${DEPENDENCIES_ROOT@Q},
    "toolchain_parent": ${TOOLCHAIN_PARENT@Q},
    "toolchain_root": ${TOOLCHAIN_ROOT@Q},
    "archive_path": ${ARCHIVE_PATH@Q},
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "check_only": ${CHECK_ONLY_COMMAND@Q},
        "restore": ${RESTORE_COMMAND@Q},
        "path": ${PATH_COMMAND@Q},
        "cargo": ${CARGO_COMMAND@Q},
        "rustc": ${RUSTC_COMMAND@Q},
        "preflight": ${PREFLIGHT_COMMAND@Q}
    },
    "notes": [
        "Run the surface_check command first so missing route docs or helper drift fails before the saved archive itself is blamed.",
        "Run the check_only command next when the saved archive location or target toolchain directory may have drifted.",
        "Use the restore command to keep the saved Rust 1.79.0 extraction path on one branch-local surface.",
        "Reuse the PATH, CARGO, and RUSTC exports before rerunning Linux or WSL build-readiness checks.",
        "By default this route now restores into ../toolchains/rust-1.79.0 so it matches the broader Linux build-readiness helper."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF_ROUTE
Google issue #3 saved Rust toolchain restore route

Browser root:      ${BROWSER_ROOT}
Dependencies root: ${DEPENDENCIES_ROOT}
Toolchain parent:  ${TOOLCHAIN_PARENT}
Toolchain root:    ${TOOLCHAIN_ROOT}
Rust archive:      ${ARCHIVE_PATH}

Read first
==========
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Saved Rust restore surface check:
    ${CHECK_ONLY_COMMAND}

  Restore the saved Rust 1.79.0 toolchain:
    ${RESTORE_COMMAND}

  Put the restored Rust toolchain first on PATH:
    ${PATH_COMMAND}
    ${CARGO_COMMAND}
    ${RUSTC_COMMAND}

  Quick readiness preflight after restore:
    ${PREFLIGHT_COMMAND}

Working rules
=============
  - Run the surface check first so missing route docs or helper drift fails before the saved archive itself is blamed.
  - Run the restore helper surface check next when the archive or destination path may have drifted.
  - Use the restore command instead of rebuilding the tar extraction path by hand.
  - Reuse the exported PATH, CARGO, and RUSTC values before rerunning Linux or WSL build-readiness helpers.
  - The default restore location now matches the broader Linux build-readiness route: ../toolchains/rust-1.79.0.
EOF_ROUTE