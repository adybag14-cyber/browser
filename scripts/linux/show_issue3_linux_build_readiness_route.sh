#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_linux_build_readiness_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser] \
    [--rust-toolchain-dir /path/to/rust-toolchain-dir] \
    [--json]

Print the saved-archive-first Linux/WSL build-readiness route for the blocked
issue #3 Enter-submit runtime lane.
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
REPO_ROOT="${DEFAULT_REPO_ROOT}"
SAVED_ARCHIVES_ROOT=""
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
if [[ -z "${RUST_TOOLCHAIN_DIR}" ]]; then
    RUST_TOOLCHAIN_DIR="$(cd "${REPO_ROOT}/.." && pwd)/toolchains/rust-1.79.0"
fi

RUST_ARCHIVE="${SAVED_ARCHIVES_ROOT}/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz"
HTML5EVER_ARCHIVE="${SAVED_ARCHIVES_ROOT}/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"
BORINGSSL_ARCHIVE="${SAVED_ARCHIVES_ROOT}/dependencies/03-boringssl-zig-main.zip"
BROWSER_DEPS_ARCHIVE="${SAVED_ARCHIVES_ROOT}/dependencies/04-zig-browser-depo.tar.zip"
PREFLIGHT_COMMAND="python scripts/check_linux_build_readiness.py --repo-root $(format_shell_arg "${REPO_ROOT}") --skip-zig-check --expect-saved-archives --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies")"
PREPARE_COMMAND="bash scripts/linux/prepare_offline_build_inputs.sh --browser-root $(format_shell_arg "${REPO_ROOT}") --browser-deps-archive $(format_shell_arg "${BROWSER_DEPS_ARCHIVE}") --boringssl-archive $(format_shell_arg "${BORINGSSL_ARCHIVE}") --html5ever-archive $(format_shell_arg "${HTML5EVER_ARCHIVE}") --check-only"
RUST_RESTORE_COMMAND="mkdir -p $(format_shell_arg "${RUST_TOOLCHAIN_DIR}") && tar -xf $(format_shell_arg "${RUST_ARCHIVE}") -C $(format_shell_arg "${RUST_TOOLCHAIN_DIR}") --strip-components=1"
RUST_PATH_COMMAND="export PATH=$(format_shell_arg "${RUST_TOOLCHAIN_DIR}/cargo/bin"):\$PATH"
FULL_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root $(format_shell_arg "${REPO_ROOT}") --expect-saved-archives --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies") --expect-offline-deps --require-prebuilt-v8"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 Enter-submit runtime build-readiness route",
    "repo_root": ${REPO_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "rust_toolchain_dir": ${RUST_TOOLCHAIN_DIR@Q},
    "commands": {
        "saved_archive_preflight": ${PREFLIGHT_COMMAND@Q},
        "offline_prepare_check_only": ${PREPARE_COMMAND@Q},
        "rust_restore": ${RUST_RESTORE_COMMAND@Q},
        "rust_path": ${RUST_PATH_COMMAND@Q},
        "full_readiness": ${FULL_READINESS_COMMAND@Q}
    },
    "notes": [
        "Use the saved-archive preflight before treating Linux or WSL Zig output as issue #3 evidence.",
        "Keep the saved Rust 1.79.0 toolchain on PATH before retrying cargo-backed build steps.",
        "Prefer a Zig 0.15.2 toolchain for honest branch validation; the fallback Zig 0.17 dev line is known to fail in untouched branch files."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 Enter-submit runtime build-readiness route

Repo root:           ${REPO_ROOT}
Saved archive root:  ${SAVED_ARCHIVES_ROOT}
Rust toolchain dir:  ${RUST_TOOLCHAIN_DIR}

Read first
==========
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
  docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md

Saved archives
==============
  Rust toolchain:    ${RUST_ARCHIVE}
  html5ever bundle:  ${HTML5EVER_ARCHIVE}
  BoringSSL bundle:  ${BORINGSSL_ARCHIVE}
  Browser deps:      ${BROWSER_DEPS_ARCHIVE}

Suggested route
===============
  Saved-archive preflight:
    ${PREFLIGHT_COMMAND}

  Offline restore surface check:
    ${PREPARE_COMMAND}

  Restore the saved Rust 1.79.0 toolchain:
    ${RUST_RESTORE_COMMAND}

  Put the restored Rust toolchain first on PATH:
    ${RUST_PATH_COMMAND}

  Full Linux/WSL readiness check after offline staging:
    ${FULL_READINESS_COMMAND}

Working rules
=============
  - Do not treat Zig 403 fetch failures for brotli, zlib, nghttp2, or curl as a source regression before the offline restore route is staged.
  - Do not treat fallback Zig 0.17 dev failures in untouched branch files as issue #3 patch evidence.
  - Prefer a Zig 0.15.2 toolchain for honest branch validation after the saved archives and Rust toolchain are staged.
EOF