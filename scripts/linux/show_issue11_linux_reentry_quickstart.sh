#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue11_linux_reentry_quickstart.sh \
    [--repo-root /path/to/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--rust-toolchain-dir /path/to/toolchains/rust-1.79.0] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print one compact issue #11 Linux/WSL re-entry helper surface for the progress-
tracker, workspace-context, archive-integrity, restore, saved-memory, saved-
Rust, build-readiness, and Zig-matching routes.
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
MEMORY_ROOT=""
RESTORED_CHECKOUT_ROOT=""
SAVED_ARCHIVES_ROOT=""
RUST_TOOLCHAIN_DIR=""
OFFLINE_DEPS_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --memory-root)
            MEMORY_ROOT="$2"
            shift 2
            ;;
        --restored-checkout-root)
            RESTORED_CHECKOUT_ROOT="$2"
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
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory"
fi
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/browser-memory-snapshot"
fi
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${MEMORY_ROOT}/repo_archives/browser"
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${RUST_TOOLCHAIN_DIR}" ]]; then
    RUST_TOOLCHAIN_DIR="$(cd "${REPO_ROOT}/.." && pwd)/toolchains/rust-1.79.0"
fi
TOOLCHAINS_ROOT="$(dirname "${RUST_TOOLCHAIN_DIR}")"
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/offline-deps"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

PROGRESS_SURFACE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_progress_tracker_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
PROGRESS_ROUTE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_progress_tracker_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
WORKSPACE_CONTEXT="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_workspace_context.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ARCHIVE_SURFACE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ARCHIVE_ROUTE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_archive_integrity_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_SURFACE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_ROUTE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-helper-surface"
RESTORED_SURFACE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
RESTORED_ROUTE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_restored_checkout_reentry_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SAVED_MEMORY_SURFACE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_MEMORY_ROUTE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_memory_inputs_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_RUST_ROUTE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
BUILD_SURFACE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_linux_build_readiness_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
BUILD_ROUTE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --rust-toolchain-dir $(format_shell_arg "${RUST_TOOLCHAIN_DIR}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
ZIG_MATCH="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_match.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
ZIG_SURFACE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ZIG_ROUTE="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    WORKSPACE_CONTEXT+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ARCHIVE_ROUTE+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SNAPSHOT_ROUTE+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_ROUTE+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_ROUTE+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_MATCH+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_ROUTE+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": 11,
    "profile": "issue11-linux-reentry-quickstart",
    "repo_root": ${REPO_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "rust_toolchain_dir": ${RUST_TOOLCHAIN_DIR@Q},
    "offline_deps_root": ${OFFLINE_DEPS_ROOT@Q},
    "toolchains_root": ${TOOLCHAINS_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "commands": {
        "progress_surface": ${PROGRESS_SURFACE@Q},
        "progress_route": ${PROGRESS_ROUTE@Q},
        "workspace_context": ${WORKSPACE_CONTEXT@Q},
        "archive_surface": ${ARCHIVE_SURFACE@Q},
        "archive_route": ${ARCHIVE_ROUTE@Q},
        "snapshot_surface": ${SNAPSHOT_SURFACE@Q},
        "snapshot_route": ${SNAPSHOT_ROUTE@Q},
        "restored_surface": ${RESTORED_SURFACE@Q},
        "restored_route": ${RESTORED_ROUTE@Q},
        "saved_memory_surface": ${SAVED_MEMORY_SURFACE@Q},
        "saved_memory_route": ${SAVED_MEMORY_ROUTE@Q},
        "saved_rust_route": ${SAVED_RUST_ROUTE@Q},
        "build_surface": ${BUILD_SURFACE@Q},
        "build_route": ${BUILD_ROUTE@Q},
        "zig_match": ${ZIG_MATCH@Q},
        "zig_surface": ${ZIG_SURFACE@Q},
        "zig_route": ${ZIG_ROUTE@Q}
    },
    "notes": [
        "Use issue #11 as the current status lane for Linux or WSL re-entry work.",
        "Run the workspace-context helper before rebuilding shared-root overrides by hand.",
        "Run the archive-integrity route before trusting saved Memory inputs.",
        "Run the synced saved-browser-snapshot route when no reusable checkout exists yet.",
        "Run the restored-checkout and saved-memory routes before widening back out to broader build-readiness helpers.",
        "Run the saved Rust route before trusting host cargo or rustc.",
        "Run the Zig matching-line gate and recovery route before treating the fallback Zig archive as meaningful validation evidence."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Issue #11 Linux re-entry quickstart

Repo root:              ${REPO_ROOT}
Memory root:            ${MEMORY_ROOT}
Restored checkout root: ${RESTORED_CHECKOUT_ROOT}
Saved archives root:    ${SAVED_ARCHIVES_ROOT}
Rust toolchain dir:     ${RUST_TOOLCHAIN_DIR}
Offline deps root:      ${OFFLINE_DEPS_ROOT}
Toolchains root:        ${TOOLCHAINS_ROOT}
Fallback Zig archive:   ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE11_LINUX_REENTRY_QUICKSTART.md
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md

Suggested order
===============
  Issue #11 progress-tracker surface:
    ${PROGRESS_SURFACE}

  Issue #11 progress-tracker route:
    ${PROGRESS_ROUTE}

  Workspace-context helper:
    ${WORKSPACE_CONTEXT}

  Saved-archive integrity surface:
    ${ARCHIVE_SURFACE}

  Saved-archive integrity route:
    ${ARCHIVE_ROUTE}

  Saved-browser-snapshot restore surface:
    ${SNAPSHOT_SURFACE}

  Saved-browser-snapshot restore route:
    ${SNAPSHOT_ROUTE}

  Restored-checkout re-entry surface:
    ${RESTORED_SURFACE}

  Restored-checkout re-entry route:
    ${RESTORED_ROUTE}

  Saved-memory route surface:
    ${SAVED_MEMORY_SURFACE}

  Saved-memory route:
    ${SAVED_MEMORY_ROUTE}

  Saved Rust route:
    ${SAVED_RUST_ROUTE}

  Linux or WSL build-readiness surface:
    ${BUILD_SURFACE}

  Linux or WSL build-readiness route:
    ${BUILD_ROUTE}

  Zig matching-line gate:
    ${ZIG_MATCH}

  Zig toolchain recovery surface:
    ${ZIG_SURFACE}

  Zig toolchain recovery route:
    ${ZIG_ROUTE}

Working rules
=============
  - Treat issue #11 as the current status lane for Linux or WSL re-entry work.
  - Run the workspace-context helper before rebuilding path overrides by hand when the checkout sits deeper than the default sibling layout.
  - Run the archive-integrity route before trusting saved Memory inputs.
  - Run the synced saved-browser-snapshot route when no reusable checkout exists yet.
  - Run the restored-checkout and saved-memory routes before widening back out to broader saved Rust or Linux build-readiness helpers.
  - Run the saved Rust route before trusting host cargo or rustc.
  - Run the Zig matching-line gate and recovery route before treating the attached Zig 0.17 bundle as branch-compatible validation evidence.
EOF