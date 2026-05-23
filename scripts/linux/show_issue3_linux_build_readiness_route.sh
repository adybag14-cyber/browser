#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_linux_build_readiness_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser] \
    [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
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
FALLBACK_ZIG_ARCHIVE=""
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
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser"
fi
if [[ -z "${RUST_TOOLCHAIN_DIR}" ]]; then
    RUST_TOOLCHAIN_DIR="$(cd "${REPO_ROOT}/.." && pwd)/toolchains/rust-1.79.0"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_linux_build_readiness_route_surface.sh --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_ROUTE_COMMAND="bash scripts/linux/show_issue3_saved_browser_snapshot_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}")"
TOOLCHAIN_ROUTE_COMMAND="bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies")"
RUST_ARCHIVE="${SAVED_ARCHIVES_ROOT}/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz"
HTML5EVER_ARCHIVE="${SAVED_ARCHIVES_ROOT}/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"
BORINGSSL_ARCHIVE="${SAVED_ARCHIVES_ROOT}/dependencies/03-boringssl-zig-main.zip"
BROWSER_DEPS_ARCHIVE="${SAVED_ARCHIVES_ROOT}/dependencies/04-zig-browser-depo.tar.zip"
SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root $(format_shell_arg "${REPO_ROOT}")"
PREFLIGHT_COMMAND="python scripts/check_linux_build_readiness.py --repo-root $(format_shell_arg "${REPO_ROOT}") --skip-zig-check --expect-saved-archives --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies")"
PREPARE_COMMAND="bash scripts/linux/prepare_offline_build_inputs.sh --browser-root $(format_shell_arg "${REPO_ROOT}") --browser-deps-archive $(format_shell_arg "${BROWSER_DEPS_ARCHIVE}") --boringssl-archive $(format_shell_arg "${BORINGSSL_ARCHIVE}") --html5ever-archive $(format_shell_arg "${HTML5EVER_ARCHIVE}") --check-only"
RUST_RESTORE_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
RUST_RESTORE_CHECK_COMMAND="bash scripts/linux/restore_saved_rust_toolchain.sh --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}") --check-only"
RUST_PATH_COMMAND="export PATH=$(format_shell_arg "${RUST_TOOLCHAIN_DIR}/cargo/bin"):$(format_shell_arg "${RUST_TOOLCHAIN_DIR}/rustc/bin"):\$PATH"
FULL_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root $(format_shell_arg "${REPO_ROOT}") --expect-saved-archives --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies") --expect-offline-deps --require-prebuilt-v8"
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    TOOLCHAIN_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_INPUTS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    FULL_READINESS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 Enter-submit runtime build-readiness route",
    "repo_root": ${REPO_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "rust_toolchain_dir": ${RUST_TOOLCHAIN_DIR@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "saved_browser_snapshot_route": ${SNAPSHOT_ROUTE_COMMAND@Q},
        "saved_memory_inputs": ${SAVED_MEMORY_INPUTS_COMMAND@Q},
        "zig_toolchain_route": ${TOOLCHAIN_ROUTE_COMMAND@Q},
        "saved_archive_preflight": ${PREFLIGHT_COMMAND@Q},
        "offline_prepare_check_only": ${PREPARE_COMMAND@Q},
        "rust_restore_check_only": ${RUST_RESTORE_CHECK_COMMAND@Q},
        "rust_restore": ${RUST_RESTORE_COMMAND@Q},
        "rust_path": ${RUST_PATH_COMMAND@Q},
        "full_readiness": ${FULL_READINESS_COMMAND@Q}
    },
    "notes": [
        "Run the surface_check command first so missing branch-local docs or helper paths fail fast before offline staging starts.",
        "Use the saved_browser_snapshot_route command when no reusable checkout exists yet and the restore plus first follow-up commands need to stay on one surface.",
        "Run the saved_memory_inputs command before the broader saved-archive preflight when the route depends on the saved Memory repo snapshot and dependency bundles.",
        "Run the zig_toolchain_route command when the route still only sees the attached Zig 0.17 fallback or when multiple staged toolchains need a quick 0.15.x decision.",
        "Use the saved-archive preflight before treating Linux or WSL Zig output as issue #3 evidence.",
        "Run rust_restore_check_only when you want to confirm the saved Rust archive and target directory before extracting it.",
        "Use rust_restore to keep the saved Rust 1.79.0 toolchain restore on one branch-local helper surface instead of rebuilding the tar command by hand.",
        "Treat the attached zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz bundle as a surfaced fallback input only; it should not be treated as honest issue #3 validation evidence for this branch.",
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
Fallback Zig archive:${FALLBACK_ZIG_ARCHIVE:- not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md

Saved archives
==============
  Rust toolchain:    ${RUST_ARCHIVE}
  html5ever bundle:  ${HTML5EVER_ARCHIVE}
  BoringSSL bundle:  ${BORINGSSL_ARCHIVE}
  Browser deps:      ${BROWSER_DEPS_ARCHIVE}

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Saved-browser-snapshot route when no reusable checkout exists yet:
    ${SNAPSHOT_ROUTE_COMMAND}

  Saved Memory input preflight:
    ${SAVED_MEMORY_INPUTS_COMMAND}

  Zig toolchain recovery route:
    ${TOOLCHAIN_ROUTE_COMMAND}

  Saved-archive preflight:
    ${PREFLIGHT_COMMAND}

  Offline restore surface check:
    ${PREPARE_COMMAND}

  Saved Rust restore surface check:
    ${RUST_RESTORE_CHECK_COMMAND}

  Restore the saved Rust 1.79.0 toolchain:
    ${RUST_RESTORE_COMMAND}

  Put the restored Rust toolchain first on PATH:
    ${RUST_PATH_COMMAND}

  Full Linux/WSL readiness check after offline staging:
    ${FULL_READINESS_COMMAND}

Working rules
=============
  - Run the surface check first so missing docs or helper drift fails fast before offline staging starts.
  - If no reusable checkout exists yet, print the saved-browser-snapshot route before the broader readiness helper so the restore and immediate follow-up commands stay on one surface.
  - Run the saved Memory input preflight before the broader saved-archive preflight when the route depends on the saved repo snapshot and dependency bundles.
  - Run the Zig toolchain recovery route when the route still only sees the attached Zig 0.17 fallback or when multiple staged toolchains need a quick 0.15.x decision.
  - Do not treat Zig 403 fetch failures for brotli, zlib, nghttp2, or curl as a source regression before the offline restore route is staged.
  - Treat the attached zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz bundle as a surfaced fallback input only, not as honest issue #3 validation evidence for this branch.
  - Do not treat fallback Zig 0.17 dev failures in untouched branch files as issue #3 patch evidence.
  - Prefer a Zig 0.15.2 toolchain for honest branch validation after the saved archives and Rust toolchain are staged.
EOF