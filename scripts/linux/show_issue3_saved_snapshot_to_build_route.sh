#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_snapshot_to_build_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--memory-root /path/to/workspace/memory] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--sync-helper-surface] \
    [--json]

Print the compact issue #3 handoff route from the saved Memory snapshot restore
into restored-checkout follow-up and Linux or WSL build-readiness staging.
EOF
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

resolve_workspace_companion_path() {
    local root="$1"
    local name="$2"
    local child_path="${root}/${name}"
    local sibling_path
    sibling_path="$(cd "${root}/.." && pwd)/${name}"

    if [[ -e "${child_path}" ]]; then
        printf '%s\n' "${child_path}"
        return
    fi

    if [[ "$(basename "${root}")" == "workspace" ]]; then
        printf '%s\n' "${child_path}"
        return
    fi

    printf '%s\n' "${sibling_path}"
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
DEFAULT_RESTORED_CHECKOUT_NAME="browser-memory-snapshot"
DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
RESTORED_CHECKOUT_ROOT=""
MEMORY_ROOT=""
SAVED_ARCHIVES_ROOT=""
RUST_TOOLCHAIN_DIR=""
OFFLINE_DEPS_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
SYNC_HELPER_SURFACE=0
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --helper-root)
            HELPER_ROOT="$2"
            shift 2
            ;;
        --restored-checkout-root|--restored-root)
            RESTORED_CHECKOUT_ROOT="$2"
            shift 2
            ;;
        --memory-root)
            MEMORY_ROOT="$2"
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
        --offline-deps-root)
            OFFLINE_DEPS_ROOT="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --sync-helper-surface)
            SYNC_HELPER_SURFACE=1
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
if [[ -z "${HELPER_ROOT}" ]]; then
    HELPER_ROOT="${REPO_ROOT}"
fi
HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "${DEFAULT_RESTORED_CHECKOUT_NAME}")"
fi
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "memory")"
fi
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${MEMORY_ROOT}/repo_archives/browser"
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${RUST_TOOLCHAIN_DIR}" ]]; then
    RUST_TOOLCHAIN_DIR="$(resolve_workspace_companion_path "${REPO_ROOT}" "toolchains")/rust-1.79.0"
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="$(resolve_workspace_companion_path "${REPO_ROOT}" "offline-deps")"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    local_agent_files_root="$(resolve_workspace_companion_path "${HELPER_ROOT}" "agent_files")"
    candidate_fallback_zig_archive="${local_agent_files_root}/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}"
    if [[ -f "${candidate_fallback_zig_archive}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${candidate_fallback_zig_archive}"
    fi
fi

SYNC_RESTORE_FLAG=""
SYNC_EXPECT_FLAG=""
FOLLOW_UP_ROOT="${HELPER_ROOT}"
if [[ "${SYNC_HELPER_SURFACE}" -eq 1 ]]; then
    SYNC_RESTORE_FLAG=" --sync-helper-surface"
    SYNC_EXPECT_FLAG=" --expect-helper-surface"
    FOLLOW_UP_ROOT="${RESTORED_CHECKOUT_ROOT}"
fi

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
SAVED_SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")${SYNC_RESTORE_FLAG}"
RESTORED_CHECKOUT_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_restored_checkout_reentry_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}")${SYNC_EXPECT_FLAG}"
SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${FOLLOW_UP_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${FOLLOW_UP_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${FOLLOW_UP_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --rust-toolchain-dir $(format_shell_arg "${RUST_TOOLCHAIN_DIR}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 saved-snapshot to build-readiness handoff route",
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "follow_up_root": ${FOLLOW_UP_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "rust_toolchain_dir": ${RUST_TOOLCHAIN_DIR@Q},
    "offline_deps_root": ${OFFLINE_DEPS_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "sync_helper_surface": ${SYNC_HELPER_SURFACE},
    "read_first": [
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    ],
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "saved_snapshot_route": ${SAVED_SNAPSHOT_ROUTE_COMMAND@Q},
        "restored_checkout_route": ${RESTORED_CHECKOUT_ROUTE_COMMAND@Q},
        "saved_memory_preflight": ${SAVED_MEMORY_PREFLIGHT_COMMAND@Q},
        "saved_archive_integrity": ${SAVED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "linux_build_route": ${LINUX_BUILD_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run the restored-checkout route surface check first so the compact handoff fails fast when the branch-local helper chain drifts.",
        "Use the saved_snapshot_route command to materialize or refresh the reusable checkout before any Linux or WSL build staging trusts it.",
        "Use --sync-helper-surface when the restored checkout should become its own follow-up root because the saved archive can lag the live helper surface.",
        "Run restored_checkout_route immediately after the restore route so the post-restore helper chain stays compact and ordered.",
        "Run saved_memory_preflight before the broader build route when the handoff still depends on the saved Memory snapshot and dependency bundles.",
        "Run saved_archive_integrity after the saved-memory preflight when the route needs to prove the restored checkout still points at the expected saved artifacts.",
        "Use linux_build_route when toolchain staging or offline dependencies are still the next blocker before the direct runtime patch can reopen."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 saved-snapshot to build-readiness handoff route

Repo root:              ${REPO_ROOT}
Live helper root:       ${HELPER_ROOT}
Restored checkout root: ${RESTORED_CHECKOUT_ROOT}
Follow-up helper root:  ${FOLLOW_UP_ROOT}
Memory root:            ${MEMORY_ROOT}
Saved archive root:     ${SAVED_ARCHIVES_ROOT}
Rust toolchain dir:     ${RUST_TOOLCHAIN_DIR}
Offline deps root:      ${OFFLINE_DEPS_ROOT}
Fallback Zig archive:   ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Sync helper surface:    $([[ "${SYNC_HELPER_SURFACE}" -eq 1 ]] && echo enabled || echo disabled)

Read first
==========
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Restored-checkout route surface check:
    ${SURFACE_CHECK_COMMAND}

  Saved-browser-snapshot route:
    ${SAVED_SNAPSHOT_ROUTE_COMMAND}

  Restored-checkout follow-up route:
    ${RESTORED_CHECKOUT_ROUTE_COMMAND}

  Saved-Memory preflight against the restored checkout:
    ${SAVED_MEMORY_PREFLIGHT_COMMAND}

  Saved-archive integrity preflight against the restored checkout:
    ${SAVED_ARCHIVE_INTEGRITY_COMMAND}

  Linux or WSL build-readiness route from the restored checkout:
    ${LINUX_BUILD_ROUTE_COMMAND}

Working rules
=============
  - Run the restored-checkout route surface check first so missing helper files or route drift fail fast before restore and staging work begins.
  - Use the saved-browser-snapshot route to materialize or refresh the reusable checkout before any Linux or WSL build staging trusts it.
  - Use --sync-helper-surface when the restored checkout should become its own follow-up root because the saved archive can lag the live helper surface.
  - Run the restored-checkout follow-up route immediately after restore so the post-restore helper chain stays compact and ordered.
  - Run the saved-Memory preflight against the restored checkout before the broader build-readiness route when the handoff still depends on the saved Memory snapshot and dependency bundles.
  - Run the saved-archive integrity preflight after the saved-Memory preflight when the route needs to prove the restored checkout still points at the expected saved artifacts.
  - Use the Linux or WSL build-readiness route when toolchain staging or offline dependencies are still the next blocker before the direct runtime patch can reopen.
EOF