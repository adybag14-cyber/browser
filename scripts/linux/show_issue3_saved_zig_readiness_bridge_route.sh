#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_zig_readiness_bridge_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--toolchains-root /path/to/toolchains] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--expect-offline-deps] \
    [--require-prebuilt-v8] \
    [--json]

Print the saved Zig readiness bridge route for the blocked issue #3 Linux or
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
SAVED_ARCHIVES_ROOT=""
TOOLCHAINS_ROOT=""
OFFLINE_DEPS_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
EXPECT_OFFLINE_DEPS=0
REQUIRE_PREBUILT_V8=0
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
        --offline-deps-root)
            OFFLINE_DEPS_ROOT="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --expect-offline-deps)
            EXPECT_OFFLINE_DEPS=1
            shift
            ;;
        --require-prebuilt-v8)
            REQUIRE_PREBUILT_V8=1
            shift
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
    SAVED_ARCHIVES_ROOT="$(resolve_first_existing_path "${REPO_ROOT}" "memory/repo_archives/browser" || true)"
    if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
        SAVED_ARCHIVES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory/repo_archives/browser"
    fi
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="$(resolve_first_existing_path "${REPO_ROOT}" "toolchains" || true)"
    if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
        TOOLCHAINS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/toolchains"
    fi
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="$(resolve_first_existing_path "${REPO_ROOT}" "offline-deps" || true)"
    if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
        OFFLINE_DEPS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/offline-deps"
    fi
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(resolve_first_existing_path "${REPO_ROOT}" "agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz" || true)"
    if [[ -z "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    fi
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ROUTE_NOTE_PATH="${REPO_ROOT}/docs/ISSUE3_SAVED_ZIG_READINESS_BRIDGE_ROUTE.md"
PROGRESS_TRACKER_ROUTE_PATH="${REPO_ROOT}/docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"
SAVED_ZIG_ROUTE_PATH="${REPO_ROOT}/docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"
BUILD_READINESS_ROUTE_PATH="${REPO_ROOT}/docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"

SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_zig_readiness_bridge_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
BRIDGE_COMMAND="python3 $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_zig_readiness_bridge.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
SAVED_ZIG_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
PROGRESS_TRACKER_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_progress_tracker_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"

if [[ "${EXPECT_OFFLINE_DEPS}" -eq 1 ]]; then
    SURFACE_COMMAND="${SURFACE_COMMAND} --expect-offline-deps"
    BRIDGE_COMMAND="${BRIDGE_COMMAND} --expect-offline-deps"
fi
if [[ "${REQUIRE_PREBUILT_V8}" -eq 1 ]]; then
    SURFACE_COMMAND="${SURFACE_COMMAND} --require-prebuilt-v8"
    BRIDGE_COMMAND="${BRIDGE_COMMAND} --require-prebuilt-v8"
fi
if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SURFACE_COMMAND="${SURFACE_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BRIDGE_COMMAND="${BRIDGE_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ZIG_ROUTE_COMMAND="${SAVED_ZIG_ROUTE_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND="${BUILD_ROUTE_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    PROGRESS_TRACKER_ROUTE_COMMAND="${PROGRESS_TRACKER_ROUTE_COMMAND} --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 saved Zig readiness bridge route",
    "repo_root": ${REPO_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "toolchains_root": ${TOOLCHAINS_ROOT@Q},
    "offline_deps_root": ${OFFLINE_DEPS_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "expect_offline_deps": ${EXPECT_OFFLINE_DEPS},
    "require_prebuilt_v8": ${REQUIRE_PREBUILT_V8},
    "route_note_path": ${ROUTE_NOTE_PATH@Q},
    "progress_tracker_route_path": ${PROGRESS_TRACKER_ROUTE_PATH@Q},
    "saved_zig_route_path": ${SAVED_ZIG_ROUTE_PATH@Q},
    "build_readiness_route_path": ${BUILD_READINESS_ROUTE_PATH@Q},
    "commands": {
        "surface_check": ${SURFACE_COMMAND@Q},
        "bridge_helper": ${BRIDGE_COMMAND@Q},
        "saved_zig_route": ${SAVED_ZIG_ROUTE_COMMAND@Q},
        "build_readiness_route": ${BUILD_ROUTE_COMMAND@Q},
        "progress_tracker_route": ${PROGRESS_TRACKER_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run the surface check first so route drift fails before the rerun trusts the staged-versus-saved Zig decision.",
        "Use the bridge helper when the rerun needs one compact answer for whether it should reuse a staged Zig toolchain or restore a saved archive first.",
        "Pass --expect-offline-deps when the reopened Linux or WSL build-readiness lane must still prove cached offline inputs.",
        "Pass --require-prebuilt-v8 when the reopened build-readiness lane still depends on a surfaced prebuilt V8 archive.",
        "When the bridge helper reports a staged matching candidate, continue with the Linux build-readiness route next.",
        "When the bridge helper reports a saved-archive restore path, continue with the saved Zig archive route and the broader Zig recovery route next.",
        "Use the issue #11 progress-tracker route while this slice is still about saved inputs, toolchain recovery, or Linux or WSL readiness gates."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 saved Zig readiness bridge route

Repo root:               ${REPO_ROOT}
Saved archives root:     ${SAVED_ARCHIVES_ROOT}
Toolchains root:         ${TOOLCHAINS_ROOT}
Offline deps root:       ${OFFLINE_DEPS_ROOT}
Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Route note:              ${ROUTE_NOTE_PATH}
Progress tracker route:  ${PROGRESS_TRACKER_ROUTE_PATH}
Saved Zig route note:    ${SAVED_ZIG_ROUTE_PATH}
Build route note:        ${BUILD_READINESS_ROUTE_PATH}

Read first
==========
  docs/ISSUE3_SAVED_ZIG_READINESS_BRIDGE_ROUTE.md
  docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md

Suggested route
===============
  Route surface check:
    ${SURFACE_COMMAND}

  Bridge helper:
    ${BRIDGE_COMMAND}

  Saved Zig follow-up route:
    ${SAVED_ZIG_ROUTE_COMMAND}

  Linux build-readiness follow-up route:
    ${BUILD_ROUTE_COMMAND}

  Issue #11 progress-tracker route:
    ${PROGRESS_TRACKER_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface check first so missing docs or helper drift fails before the rerun trusts the bridge output.
  - Use the bridge helper before hand-picking a staged or saved Zig path whenever both the saved archive route and the broader build-readiness route are in play.
  - Pass --expect-offline-deps when the reopened Linux or WSL build-readiness lane still depends on cached offline inputs.
  - Pass --require-prebuilt-v8 when the reopened build-readiness lane still depends on a surfaced prebuilt V8 archive.
  - When the bridge helper reports a staged matching candidate, continue with the Linux build-readiness route next.
  - When the bridge helper reports a saved restore path, continue with the saved Zig archive route and the broader Zig recovery route next.
  - Use the issue #11 progress-tracker route while this slice is still about saved inputs, toolchain recovery, or Linux or WSL readiness gates.
EOF
