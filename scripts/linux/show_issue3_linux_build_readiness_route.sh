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
    python3 - "$1" <<'PY2'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY2
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

LINUX_BUILD_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"
SAVED_BROWSER_SNAPSHOT_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
SAVED_ARCHIVE_ROUTE_SURFACE_SCRIPT="${REPO_ROOT}/scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh"
SAVED_ARCHIVE_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_archive_integrity_route.sh"
ZIG_TOOLCHAIN_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh"
SAVED_RUST_SURFACE_SCRIPT_PATH="${REPO_ROOT}/scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh"
SAVED_RUST_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh"
OFFLINE_ROUTE_SCRIPT="${REPO_ROOT}/scripts/linux/show_issue3_offline_build_inputs_route.sh"
SAVED_MEMORY_INPUTS_SCRIPT="${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py"
SAVED_ARCHIVE_INTEGRITY_SCRIPT="${REPO_ROOT}/scripts/check_issue3_saved_archive_integrity.py"
LINUX_BUILD_READINESS_SCRIPT="${REPO_ROOT}/scripts/check_linux_build_readiness.py"
PREPARE_OFFLINE_SCRIPT="${REPO_ROOT}/scripts/linux/prepare_offline_build_inputs.sh"
RESTORE_SAVED_RUST_SCRIPT="${REPO_ROOT}/scripts/linux/restore_saved_rust_toolchain.sh"

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${LINUX_BUILD_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${SAVED_BROWSER_SNAPSHOT_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_ARCHIVE_ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${SAVED_ARCHIVE_ROUTE_SURFACE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_ARCHIVE_ROUTE_COMMAND="bash $(format_shell_arg "${SAVED_ARCHIVE_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
TOOLCHAIN_ROUTE_COMMAND="bash $(format_shell_arg "${ZIG_TOOLCHAIN_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies")"
SAVED_RUST_SURFACE_COMMAND="bash $(format_shell_arg "${SAVED_RUST_SURFACE_SCRIPT_PATH}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_RUST_ROUTE_COMMAND="bash $(format_shell_arg "${SAVED_RUST_ROUTE_SCRIPT}") --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
OFFLINE_ROUTE_COMMAND="bash $(format_shell_arg "${OFFLINE_ROUTE_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies")"
RUST_ARCHIVE="${SAVED_ARCHIVES_ROOT}/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz"
HTML5EVER_ARCHIVE="${SAVED_ARCHIVES_ROOT}/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"
HTML5EVER_ARCHIVE_ARGUMENT=""
HTML5EVER_ARCHIVE_DISPLAY="not present under saved archives root"
if [[ -f "${HTML5EVER_ARCHIVE}" ]]; then
    HTML5EVER_ARCHIVE_ARGUMENT=" --html5ever-archive $(format_shell_arg "${HTML5EVER_ARCHIVE}")"
    HTML5EVER_ARCHIVE_DISPLAY="${HTML5EVER_ARCHIVE}"
fi
BORINGSSL_ARCHIVE="${SAVED_ARCHIVES_ROOT}/dependencies/03-boringssl-zig-main.zip"
BROWSER_DEPS_ARCHIVE="${SAVED_ARCHIVES_ROOT}/dependencies/04-zig-browser-depo.tar.zip"
SAVED_MEMORY_INPUTS_COMMAND="python $(format_shell_arg "${SAVED_MEMORY_INPUTS_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${SAVED_ARCHIVE_INTEGRITY_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}")"
PREFLIGHT_COMMAND="python $(format_shell_arg "${LINUX_BUILD_READINESS_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --skip-zig-check --expect-saved-archives --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies")"
PREPARE_COMMAND="bash $(format_shell_arg "${PREPARE_OFFLINE_SCRIPT}") --browser-root $(format_shell_arg "${REPO_ROOT}") --browser-deps-archive $(format_shell_arg "${BROWSER_DEPS_ARCHIVE}") --boringssl-archive $(format_shell_arg "${BORINGSSL_ARCHIVE}")${HTML5EVER_ARCHIVE_ARGUMENT} --check-only"
RUST_RESTORE_COMMAND="bash $(format_shell_arg "${RESTORE_SAVED_RUST_SCRIPT}") --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
RUST_RESTORE_CHECK_COMMAND="bash $(format_shell_arg "${RESTORE_SAVED_RUST_SCRIPT}") --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}") --check-only"
RUST_PATH_COMMAND="export PATH=$(format_shell_arg "${RUST_TOOLCHAIN_DIR}/cargo/bin"):$(format_shell_arg "${RUST_TOOLCHAIN_DIR}/rustc/bin"):\$PATH"
FULL_READINESS_COMMAND="python $(format_shell_arg "${LINUX_BUILD_READINESS_SCRIPT}") --repo-root $(format_shell_arg "${REPO_ROOT}") --expect-saved-archives --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}/dependencies") --expect-offline-deps --require-prebuilt-v8"
WINDOWS_RUNTIME_SURFACE_COMMAND="powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
WINDOWS_RUNTIME_ROUTE_COMMAND="powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1"
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    TOOLCHAIN_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    OFFLINE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_INPUTS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    FULL_READINESS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi
SNAPSHOT_SYNC_ROUTE_COMMAND="${SNAPSHOT_ROUTE_COMMAND} --sync-helper-surface"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY3
import json

print(json.dumps({
    "issue": "Google issue #3 Enter-submit runtime build-readiness route",
    "repo_root": ${REPO_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "rust_toolchain_dir": ${RUST_TOOLCHAIN_DIR@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "read_first": [
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
    ],
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "saved_browser_snapshot_route": ${SNAPSHOT_ROUTE_COMMAND@Q},
        "saved_browser_snapshot_route_synced": ${SNAPSHOT_SYNC_ROUTE_COMMAND@Q},
        "saved_archive_route_surface": ${SAVED_ARCHIVE_ROUTE_SURFACE_COMMAND@Q},
        "saved_archive_route": ${SAVED_ARCHIVE_ROUTE_COMMAND@Q},
        "saved_memory_inputs": ${SAVED_MEMORY_INPUTS_COMMAND@Q},
        "saved_archive_integrity": ${SAVED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "zig_toolchain_route": ${TOOLCHAIN_ROUTE_COMMAND@Q},
        "saved_rust_surface_check": ${SAVED_RUST_SURFACE_COMMAND@Q},
        "saved_rust_route": ${SAVED_RUST_ROUTE_COMMAND@Q},
        "offline_build_inputs_route": ${OFFLINE_ROUTE_COMMAND@Q},
        "saved_archive_preflight": ${PREFLIGHT_COMMAND@Q},
        "offline_prepare_check_only": ${PREPARE_COMMAND@Q},
        "rust_restore_check_only": ${RUST_RESTORE_CHECK_COMMAND@Q},
        "rust_restore": ${RUST_RESTORE_COMMAND@Q},
        "rust_path": ${RUST_PATH_COMMAND@Q},
        "full_readiness": ${FULL_READINESS_COMMAND@Q},
        "windows_runtime_surface": ${WINDOWS_RUNTIME_SURFACE_COMMAND@Q},
        "windows_runtime_route": ${WINDOWS_RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run the surface_check command first so missing branch-local docs or helper paths fail fast before offline staging starts.",
        "Use the saved_browser_snapshot_route command when no reusable checkout exists yet and the restore plus first follow-up commands need to stay on one surface.",
        "Prefer the saved_browser_snapshot_route_synced command when the restored checkout should become its own follow-up root because the saved archive can lag the live helper surface.",
        "Run the saved_memory_inputs command before the broader saved-archive preflight when the route depends on the saved Memory repo snapshot and dependency bundles.",
        "Run the saved_archive_route_surface command and then the saved_archive_route command when the route needs the dedicated checksum route back on one compact helper surface before offline staging starts.",
        "Run the saved_archive_integrity command after the saved archive route when the route needs to prove the saved repo and dependency bundles still match the expected exact artifacts before offline staging starts.",
        "Run the zig_toolchain_route command when the route still only sees the attached Zig 0.17 fallback or when multiple staged toolchains need a quick 0.15.x decision.",
        "Run the saved_rust_surface_check command before the saved Rust route when the doc and helper alignment should fail fast before the archive is blamed.",
        "Use the saved_rust_route command when the saved Rust archive and shell setup need to stay on one compact helper surface.",
        "Use the offline_build_inputs_route command when the offline dependency restore and its immediate follow-up checks need to stay on one compact helper surface before the raw restore command is trusted.",
        "The saved html5ever bundle is optional on this route and is only added to the offline restore surface check when it is actually present under the saved archives root.",
        "Use the saved-archive preflight before treating Linux or WSL Zig output as issue #3 evidence.",
        "Once the saved-archive, offline-inputs, Rust, and Zig-line checks pass, run windows_runtime_surface and then windows_runtime_route before wider replay or direct runtime edits.",
        "Treat the attached zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz bundle as a surfaced fallback input only; it should not be treated as honest issue #3 validation evidence for this branch.",
        "Prefer a Zig 0.15.2 toolchain for honest branch validation; the fallback Zig 0.17 dev line is known to fail in untouched branch files."
    ]
}, indent=2))
PY3
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
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
  docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md

Saved archives
==============
  Rust toolchain:    ${RUST_ARCHIVE}
  html5ever bundle:  ${HTML5EVER_ARCHIVE_DISPLAY}
  BoringSSL bundle:  ${BORINGSSL_ARCHIVE}
  Browser deps:      ${BROWSER_DEPS_ARCHIVE}

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Saved-browser-snapshot route when no reusable checkout exists yet:
    ${SNAPSHOT_ROUTE_COMMAND}

  Recommended synced saved-browser-snapshot route when the archive helper surface may be stale:
    ${SNAPSHOT_SYNC_ROUTE_COMMAND}

  Saved Memory input preflight:
    ${SAVED_MEMORY_INPUTS_COMMAND}

  Saved archive integrity route surface check:
    ${SAVED_ARCHIVE_ROUTE_SURFACE_COMMAND}

  Saved archive integrity route:
    ${SAVED_ARCHIVE_ROUTE_COMMAND}

  Saved archive integrity preflight:
    ${SAVED_ARCHIVE_INTEGRITY_COMMAND}

  Zig toolchain recovery route:
    ${TOOLCHAIN_ROUTE_COMMAND}

  Saved Rust route surface check:
    ${SAVED_RUST_SURFACE_COMMAND}

  Saved Rust toolchain route:
    ${SAVED_RUST_ROUTE_COMMAND}

  Offline build-inputs route:
    ${OFFLINE_ROUTE_COMMAND}

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

  Windows runtime surface handoff:
    ${WINDOWS_RUNTIME_SURFACE_COMMAND}

  Windows runtime route handoff:
    ${WINDOWS_RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the surface check first so missing docs or helper drift fails fast before offline staging starts.
  - If no reusable checkout exists yet, print the saved-browser-snapshot route before the broader readiness helper so the restore and immediate follow-up commands stay on one surface.
  - Prefer the synced saved-browser-snapshot route when the restored checkout should become its own follow-up root because the saved archive can lag the current branch-local helper surface.
  - Run the saved Memory input preflight before the broader saved-archive preflight when the route depends on the saved repo snapshot and dependency bundles.
  - Run the saved archive integrity route surface check and then the saved archive integrity route when the route needs the dedicated checksum helper chain surfaced before offline staging starts.
  - Run the saved archive integrity preflight after the saved archive route when the route needs to prove the saved repo and dependency bundles still match the expected exact artifacts before offline staging starts.
  - Run the Zig toolchain recovery route when the route still only sees the attached Zig 0.17 fallback or when multiple staged toolchains need a quick 0.15.x decision.
  - Run the saved Rust route surface check before the saved Rust route when the doc and helper alignment should fail fast before the archive is blamed.
  - Run the saved Rust toolchain route when the archive restore and shell setup need to stay on one compact helper surface.
  - Run the offline build-inputs route when the offline dependency restore and its immediate follow-up checks need to stay on one compact helper surface before the raw restore command is trusted.
  - The saved html5ever bundle is optional on this route and is only threaded into the offline restore surface check when it is actually present.
  - Do not treat Zig 403 fetch failures for brotli, zlib, nghttp2, or curl as a source regression before the offline restore route is staged.
  - Once the saved-archive, offline-inputs, Rust, and Zig-line checks pass, run the Windows runtime surface handoff and then the Windows runtime route handoff before wider replay or direct runtime edits.
  - Treat the attached zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz bundle as a surfaced fallback input only, not as honest issue #3 validation evidence for this branch.
  - Do not treat fallback Zig 0.17 dev failures in untouched branch files as issue #3 patch evidence.
  - Prefer a Zig 0.15.2 toolchain for honest branch validation after the saved archives and Rust toolchain are staged.
EOF