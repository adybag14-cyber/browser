#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue11_saved_snapshot_reentry_chain.sh \
    [--repo-root /path/to/browser-repo] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--helper-root /path/to/live-browser-repo] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the compact issue #11 route that moves from the saved-browser-snapshot
helper to the restored-checkout checkpoint and then back into Linux build
readiness for the blocked issue #3 runtime lane.
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
RESTORED_CHECKOUT_ROOT=""
HELPER_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
JSON=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"
            shift 2
            ;;
        --restored-checkout-root)
            RESTORED_CHECKOUT_ROOT="$2"
            shift 2
            ;;
        --helper-root)
            HELPER_ROOT="$2"
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
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/browser-memory-snapshot"
fi
if [[ -z "${HELPER_ROOT}" ]]; then
    HELPER_ROOT="${REPO_ROOT}"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${REPO_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

SURFACE_CHECK_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue11_saved_snapshot_reentry_chain_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SNAPSHOT_ROUTE_SYNC_COMMAND="${SNAPSHOT_ROUTE_COMMAND} --sync-helper-surface"
RESTORE_CHECK_ONLY_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${REPO_ROOT}/../memory") --archive $(format_shell_arg "${REPO_ROOT}/../memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --check-only"
RESTORE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/restore_saved_browser_snapshot.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${REPO_ROOT}/../memory") --archive $(format_shell_arg "${REPO_ROOT}/../memory/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --sync-helper-surface"
RESTORED_ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
RESTORED_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_restored_checkout_reentry_route.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
RESTORED_CHECK_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RESTORED_SYNCED_CHECK_COMMAND="${RESTORED_CHECK_COMMAND} --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
SAVED_MEMORY_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_memory_inputs_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}")"
SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
WINDOWS_RUNTIME_ROUTE_COMMAND="powershell -ExecutionPolicy Bypass -File ./scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SNAPSHOT_ROUTE_SYNC_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Issue #11 saved-snapshot re-entry chain",
    "repo_root": ${REPO_ROOT@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "read_first": [
        "docs/ISSUE11_SAVED_SNAPSHOT_REENTRY_CHAIN.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
        "docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    ],
    "commands": {
        "surface_check": ${SURFACE_CHECK_COMMAND@Q},
        "saved_browser_snapshot_route": ${SNAPSHOT_ROUTE_COMMAND@Q},
        "saved_browser_snapshot_route_synced": ${SNAPSHOT_ROUTE_SYNC_COMMAND@Q},
        "restore_check_only": ${RESTORE_CHECK_ONLY_COMMAND@Q},
        "restore_synced_checkout": ${RESTORE_COMMAND@Q},
        "restored_checkout_route_surface": ${RESTORED_ROUTE_SURFACE_COMMAND@Q},
        "restored_checkout_route": ${RESTORED_ROUTE_COMMAND@Q},
        "restored_checkout_check": ${RESTORED_CHECK_COMMAND@Q},
        "restored_checkout_synced_check": ${RESTORED_SYNCED_CHECK_COMMAND@Q},
        "saved_memory_route": ${SAVED_MEMORY_ROUTE_COMMAND@Q},
        "saved_memory_preflight": ${SAVED_MEMORY_PREFLIGHT_COMMAND@Q},
        "linux_build_readiness_route": ${LINUX_BUILD_ROUTE_COMMAND@Q},
        "windows_runtime_route": ${WINDOWS_RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run the surface check first so a missing compact-chain file fails before restore or validation work starts.",
        "Prefer the synced saved-browser-snapshot route when the restored checkout should become its own follow-up root.",
        "Run the restored-checkout route surface and route printer before the raw restored-checkout helper when the route should stay visible on one compact surface.",
        "Run the restored-checkout helper before the saved-Memory preflight so a stale or incomplete checkout does not masquerade as a broader Linux build blocker.",
        "Use the helper-root comparison form when the restored checkout should carry the current issue #3 helper surface.",
        "Only reopen the Linux build-readiness route after the restored checkout and saved-Memory routes agree on the same follow-up root.",
        "Hand back to the narrower Windows runtime route only after the restored checkout and Linux build-readiness routes are green."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Issue #11 saved-snapshot re-entry chain

Repo root:               ${REPO_ROOT}
Restored checkout root:  ${RESTORED_CHECKOUT_ROOT}
Helper root:             ${HELPER_ROOT}
Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE11_SAVED_SNAPSHOT_REENTRY_CHAIN.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Surface check:
    ${SURFACE_CHECK_COMMAND}

  Saved-browser-snapshot route:
    ${SNAPSHOT_ROUTE_COMMAND}

  Recommended synced saved-browser-snapshot route:
    ${SNAPSHOT_ROUTE_SYNC_COMMAND}

  Restore helper check-only:
    ${RESTORE_CHECK_ONLY_COMMAND}

  Restore synced checkout:
    ${RESTORE_COMMAND}

  Restored-checkout route surface check:
    ${RESTORED_ROUTE_SURFACE_COMMAND}

  Restored-checkout route:
    ${RESTORED_ROUTE_COMMAND}

  Restored-checkout readiness check:
    ${RESTORED_CHECK_COMMAND}

  Restored-checkout synced-helper-surface check:
    ${RESTORED_SYNCED_CHECK_COMMAND}

  Saved-Memory route from the restored checkout:
    ${SAVED_MEMORY_ROUTE_COMMAND}

  Saved-Memory raw preflight from the restored checkout:
    ${SAVED_MEMORY_PREFLIGHT_COMMAND}

  Linux build-readiness route from the restored checkout:
    ${LINUX_BUILD_ROUTE_COMMAND}

  Windows runtime handoff after Linux build readiness is green:
    ${WINDOWS_RUNTIME_ROUTE_COMMAND}

Working rule
============
Run the restored-checkout helper before the broader saved-Memory or Linux
build-readiness helpers so a stale restored checkout does not get misclassified
as a wider toolchain blocker.
EOF
