#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_build_recovery_bundle_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
    [--offline-deps-root /path/to/offline-deps] \
    [--toolchains-root /path/to/toolchains] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print one compact Linux or WSL recovery route for the blocked issue #3
Enter-submit runtime lane. This bundles the saved-input, offline-input, Rust,
and Zig recovery helpers in a stable order.
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
OFFLINE_DEPS_ROOT=""
TOOLCHAINS_ROOT=""
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
        --offline-deps-root)
            OFFLINE_DEPS_ROOT="$2"
            shift 2
            ;;
        --toolchains-root)
            TOOLCHAINS_ROOT="$2"
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
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${WORKSPACE_ROOT}/memory/repo_archives/browser/dependencies"
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="${WORKSPACE_ROOT}/offline-deps"
fi
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="${WORKSPACE_ROOT}/toolchains"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${WORKSPACE_ROOT}/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_build_recovery_bundle_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_MEMORY_INPUTS_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
OFFLINE_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_offline_build_inputs_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
SAVED_RUST_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchain-parent $(format_shell_arg "${TOOLCHAINS_ROOT}")"
ZIG_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
LIGHT_PREFLIGHT_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_linux_build_readiness.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --skip-zig-check --expect-saved-archives --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --expect-offline-deps --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
FULL_READINESS_COMMAND="${LIGHT_PREFLIGHT_COMMAND} --require-prebuilt-v8"
WINDOWS_HANDOFF_COMMAND="powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_enter_submit_runtime_revalidation.ps1"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_INPUTS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    OFFLINE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LIGHT_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    FULL_READINESS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 build recovery bundle route",
    "repo_root": ${REPO_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "offline_deps_root": ${OFFLINE_DEPS_ROOT@Q},
    "toolchains_root": ${TOOLCHAINS_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "saved_memory_inputs": ${SAVED_MEMORY_INPUTS_COMMAND@Q},
        "saved_archive_integrity": ${SAVED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "offline_route": ${OFFLINE_ROUTE_COMMAND@Q},
        "saved_rust_route": ${SAVED_RUST_ROUTE_COMMAND@Q},
        "zig_route": ${ZIG_ROUTE_COMMAND@Q},
        "light_preflight": ${LIGHT_PREFLIGHT_COMMAND@Q},
        "full_readiness": ${FULL_READINESS_COMMAND@Q},
        "windows_handoff": ${WINDOWS_HANDOFF_COMMAND@Q}
    }
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 build recovery bundle route

Repo root:            ${REPO_ROOT}
Saved archives root:  ${SAVED_ARCHIVES_ROOT}
Offline deps root:    ${OFFLINE_DEPS_ROOT}
Toolchains root:      ${TOOLCHAINS_ROOT}
Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_BUILD_RECOVERY_BUNDLE_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Saved Memory input preflight:
    ${SAVED_MEMORY_INPUTS_COMMAND}

  Saved archive integrity preflight:
    ${SAVED_ARCHIVE_INTEGRITY_COMMAND}

  Offline build-inputs route:
    ${OFFLINE_ROUTE_COMMAND}

  Saved Rust route:
    ${SAVED_RUST_ROUTE_COMMAND}

  Zig toolchain recovery route:
    ${ZIG_ROUTE_COMMAND}

  Light Linux or WSL preflight:
    ${LIGHT_PREFLIGHT_COMMAND}

  Full readiness rerun after staging:
    ${FULL_READINESS_COMMAND}

  Handoff back to the Windows runtime route:
    ${WINDOWS_HANDOFF_COMMAND}

Working rules
=============
  - Run the surface check first so missing docs or helper drift fails before the route blames archive or toolchain state.
  - Keep the saved Memory input preflight and saved archive integrity preflight ahead of the restore routes when the run still depends on the saved repo snapshot and dependency bundles.
  - Use the offline build-inputs route before rebuilding sibling dependency restore commands by hand.
  - Use the saved Rust route before trusting host cargo or rustc.
  - Use the Zig recovery route before treating the attached Zig 0.17 bundle as meaningful issue #3 evidence for this branch.
  - Treat the fallback Zig archive as a surfaced fallback only, not as a branch-compatible validation result.
  - Once the bundle route stops failing on environment recovery, move back to the Windows runtime helper before widening out to larger replay.
EOF
