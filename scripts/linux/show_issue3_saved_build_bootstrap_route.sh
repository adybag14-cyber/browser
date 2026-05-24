#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_build_bootstrap_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--saved-archives-root /path/to/memory/repo_archives/browser/dependencies] \
    [--toolchains-root /path/to/toolchains] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print one compact Linux or WSL bootstrap route for the blocked issue #3
environment: saved snapshot restore, saved-memory preflight, archive integrity,
offline build inputs, saved Rust, Zig recovery, and runtime re-entry handoff.
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
MEMORY_ROOT=""
RESTORED_CHECKOUT_ROOT=""
SAVED_ARCHIVES_ROOT=""
TOOLCHAINS_ROOT=""
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
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="${WORKSPACE_ROOT}/memory"
fi
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="${WORKSPACE_ROOT}/browser-memory-snapshot"
fi
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${MEMORY_ROOT}/repo_archives/browser/dependencies"
fi
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="${WORKSPACE_ROOT}/toolchains"
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="${WORKSPACE_ROOT}/offline-deps"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${WORKSPACE_ROOT}/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

RESTORE_SNAPSHOT_COMMAND="bash scripts/linux/restore_saved_browser_snapshot.sh --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-helper-surface"
RESTORE_SNAPSHOT_CHECK_ONLY_COMMAND="${RESTORE_SNAPSHOT_COMMAND} --check-only"

RESTORED_MEMORY_INPUTS_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --helper-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RESTORED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}")"
RESTORED_OFFLINE_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_offline_build_inputs_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
RESTORED_RUST_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh") --browser-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchain-parent $(format_shell_arg "${TOOLCHAINS_ROOT}")"
RESTORED_ZIG_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
RESTORED_RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    RESTORE_SNAPSHOT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORE_SNAPSHOT_CHECK_ONLY_COMMAND="${RESTORE_SNAPSHOT_COMMAND} --check-only"
    RESTORED_MEMORY_INPUTS_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_OFFLINE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_ZIG_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 saved Linux bootstrap route",
    "repo_root": ${REPO_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "saved_archives_root": ${SAVED_ARCHIVES_ROOT@Q},
    "toolchains_root": ${TOOLCHAINS_ROOT@Q},
    "offline_deps_root": ${OFFLINE_DEPS_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "read_first": [
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
    ],
    "commands": {
        "restore_snapshot_check_only": ${RESTORE_SNAPSHOT_CHECK_ONLY_COMMAND@Q},
        "restore_snapshot": ${RESTORE_SNAPSHOT_COMMAND@Q},
        "restored_memory_inputs": ${RESTORED_MEMORY_INPUTS_COMMAND@Q},
        "restored_archive_integrity": ${RESTORED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "restored_offline_build_inputs_route": ${RESTORED_OFFLINE_ROUTE_COMMAND@Q},
        "restored_saved_rust_route": ${RESTORED_RUST_ROUTE_COMMAND@Q},
        "restored_zig_recovery_route": ${RESTORED_ZIG_ROUTE_COMMAND@Q},
        "restored_runtime_reentry_route": ${RESTORED_RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Use the synced restore route first so the restored checkout becomes its own follow-up root instead of depending on a separate live helper checkout.",
        "Run the restored-memory preflight before the archive-integrity check when the route depends on the saved repo snapshot, dependency bundles, and optional fallback Zig archive.",
        "Run the offline-build-inputs route before the saved Rust and Zig routes when sibling dependencies or offline-deps may still be missing.",
        "Run the saved Rust route before the Zig recovery route when cargo or rustc may still be missing from the follow-up shell.",
        "Run the runtime re-entry route only after the restored checkout has passed the saved-input, archive, offline-dependency, Rust, and Zig-line gates."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 saved Linux bootstrap route

Repo root:              ${REPO_ROOT}
Memory root:            ${MEMORY_ROOT}
Restored checkout root: ${RESTORED_CHECKOUT_ROOT}
Saved archives root:    ${SAVED_ARCHIVES_ROOT}
Toolchains root:        ${TOOLCHAINS_ROOT}
Offline deps root:      ${OFFLINE_DEPS_ROOT}
Fallback Zig archive:   ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md

Suggested route
===============
  Check the synced saved-snapshot restore surface:
    ${RESTORE_SNAPSHOT_CHECK_ONLY_COMMAND}

  Restore the saved snapshot and sync the current helper surface into it:
    ${RESTORE_SNAPSHOT_COMMAND}

  Recheck saved Memory inputs from the restored checkout:
    ${RESTORED_MEMORY_INPUTS_COMMAND}

  Recheck saved archive integrity from the restored checkout:
    ${RESTORED_ARCHIVE_INTEGRITY_COMMAND}

  Reopen the offline build-inputs route from the restored checkout:
    ${RESTORED_OFFLINE_ROUTE_COMMAND}

  Reopen the saved Rust route from the restored checkout:
    ${RESTORED_RUST_ROUTE_COMMAND}

  Reopen the Zig recovery route from the restored checkout:
    ${RESTORED_ZIG_ROUTE_COMMAND}

  Reopen the runtime re-entry route from the restored checkout:
    ${RESTORED_RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Use the synced restore route first so the restored checkout becomes its own follow-up root instead of depending on a separate live helper checkout.
  - Run the restored-memory preflight before the archive-integrity check when the route depends on the saved repo snapshot, dependency bundles, and optional fallback Zig archive.
  - Run the offline-build-inputs route before the saved Rust and Zig routes when sibling dependencies or offline-deps may still be missing.
  - Run the saved Rust route before the Zig recovery route when cargo or rustc may still be missing from the follow-up shell.
  - Run the runtime re-entry route only after the restored checkout has passed the saved-input, archive, offline-dependency, Rust, and Zig-line gates.
EOF