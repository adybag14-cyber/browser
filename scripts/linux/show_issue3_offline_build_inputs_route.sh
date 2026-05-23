#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_offline_build_inputs_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the issue #3 Linux or WSL offline build-inputs restore route for the
blocked Enter-submit runtime lane.
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
    SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser/dependencies"
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/offline-deps"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

RUST_TOOLCHAIN_DIR="$(cd "${REPO_ROOT}/.." && pwd)/toolchains/rust-1.79.0"
BROWSER_DEPS_ARCHIVE="${SAVED_ARCHIVES_ROOT}/04-zig-browser-depo.tar.zip"
BORINGSSL_ARCHIVE="${SAVED_ARCHIVES_ROOT}/03-boringssl-zig-main.zip"
HTML5EVER_ARCHIVE="${SAVED_ARCHIVES_ROOT}/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"

SURFACE_CHECK_COMMAND="bash scripts/linux/check_issue3_offline_build_inputs_route_surface.sh --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_MEMORY_INPUTS_COMMAND="python scripts/check_issue3_saved_memory_inputs.py --repo-root $(format_shell_arg "${REPO_ROOT}")"
PREPARE_CHECK_COMMAND="bash scripts/linux/prepare_offline_build_inputs.sh --browser-root $(format_shell_arg "${REPO_ROOT}") --browser-deps-archive $(format_shell_arg "${BROWSER_DEPS_ARCHIVE}") --boringssl-archive $(format_shell_arg "${BORINGSSL_ARCHIVE}") --html5ever-archive $(format_shell_arg "${HTML5EVER_ARCHIVE}") --check-only"
PREPARE_COMMAND="bash scripts/linux/prepare_offline_build_inputs.sh --browser-root $(format_shell_arg "${REPO_ROOT}") --browser-deps-archive $(format_shell_arg "${BROWSER_DEPS_ARCHIVE}") --boringssl-archive $(format_shell_arg "${BORINGSSL_ARCHIVE}") --html5ever-archive $(format_shell_arg "${HTML5EVER_ARCHIVE}")"
SAVED_RUST_ROUTE_COMMAND="bash scripts/linux/show_issue3_saved_rust_toolchain_route.sh --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
ZIG_ROUTE_COMMAND="bash scripts/linux/show_issue3_zig_toolchain_recovery_route.sh --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
POST_STAGE_READINESS_COMMAND="python scripts/check_linux_build_readiness.py --repo-root $(format_shell_arg "${REPO_ROOT}") --skip-zig-check --expect-saved-archives --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --expect-offline-deps --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_INPUTS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    POST_STAGE_READINESS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 offline build-inputs route",
    "repo_root": ${REPO_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "offline_deps_root": ${OFFLINE_DEPS_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "saved_memory_inputs": ${SAVED_MEMORY_INPUTS_COMMAND@Q},
        "prepare_check_only": ${PREPARE_CHECK_COMMAND@Q},
        "prepare_restore": ${PREPARE_COMMAND@Q},
        "saved_rust_route": ${SAVED_RUST_ROUTE_COMMAND@Q},
        "zig_toolchain_route": ${ZIG_ROUTE_COMMAND@Q},
        "post_stage_readiness": ${POST_STAGE_READINESS_COMMAND@Q}
    },
    "notes": [
        "Run the surface_check command first so missing route files fail fast before archive staging starts.",
        "Run the saved_memory_inputs command before the restore commands when the route depends on the saved repo snapshot and dependency bundles.",
        "Use the prepare_check_only command to confirm the archive paths and the resolved zig-v8-fork, boringssl-zig, and offline-deps targets before mutating the workspace.",
        "Use the prepare_restore command to stage the sibling dependency layout expected by build.zig.zon from the saved archives.",
        "After staging completes, use the saved_rust_route and zig_toolchain_route helpers before trusting any focused Zig result.",
        "Use the post_stage_readiness command to confirm the saved archives and offline-dependency layout before reopening broader build-readiness or runtime re-entry work."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 offline build-inputs route

Repo root:            ${REPO_ROOT}
Saved archives root:  ${SAVED_ARCHIVES_ROOT}
Offline deps root:    ${OFFLINE_DEPS_ROOT}
Fallback Zig archive: ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Saved archives
==============
  Browser deps:       ${BROWSER_DEPS_ARCHIVE}
  BoringSSL bundle:   ${BORINGSSL_ARCHIVE}
  html5ever bundle:   ${HTML5EVER_ARCHIVE}

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Saved Memory input preflight:
    ${SAVED_MEMORY_INPUTS_COMMAND}

  Offline restore surface check:
    ${PREPARE_CHECK_COMMAND}

  Restore offline inputs from the saved archives:
    ${PREPARE_COMMAND}

  Saved Rust toolchain route after staging:
    ${SAVED_RUST_ROUTE_COMMAND}

  Zig toolchain recovery route after staging:
    ${ZIG_ROUTE_COMMAND}

  Post-stage readiness check:
    ${POST_STAGE_READINESS_COMMAND}

Working rules
=============
  - Run the surface check first so missing docs or helper drift fails before the route starts blaming archive or dependency state.
  - Run the saved Memory input preflight before the restore commands when the route depends on the saved repo snapshot and dependency bundles.
  - Use the offline restore surface check before mutation so the resolved zig-v8-fork, boringssl-zig, and offline-deps targets are visible on one helper surface.
  - Keep the raw restore command on this route instead of rebuilding the archive arguments by hand.
  - After staging finishes, move to the saved Rust toolchain route and the Zig toolchain recovery route before trusting focused Zig output.
  - Do not treat missing sibling dependencies or offline-deps folders as a source regression before this route has been replayed.
EOF
