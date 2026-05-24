#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash show_issue3_restored_checkout_reentry_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--memory-root /path/to/workspace/memory] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--expect-helper-surface] \
    [--json]

Print the restored-checkout re-entry route for the blocked issue #3 Linux or
WSL path after the saved browser snapshot has been restored.

`--restored-root` remains accepted as a compatibility alias for
`--restored-checkout-root`.
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
DEFAULT_RESTORED_CHECKOUT_NAME="browser-memory-snapshot"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
RESTORED_CHECKOUT_ROOT=""
MEMORY_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
EXPECT_HELPER_SURFACE=0
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
        --restored-root|--restored-checkout-root)
            RESTORED_CHECKOUT_ROOT="$2"
            shift 2
            ;;
        --memory-root)
            MEMORY_ROOT="$2"
            shift 2
            ;;
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --expect-helper-surface)
            EXPECT_HELPER_SURFACE=1
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
    RESTORED_CHECKOUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/${DEFAULT_RESTORED_CHECKOUT_NAME}"
fi
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${HELPER_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
SAVED_SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SYNCED_SAVED_SNAPSHOT_ROUTE_COMMAND="${SAVED_SNAPSHOT_ROUTE_COMMAND} --sync-helper-surface"
RESTORED_CHECKOUT_CHECK_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SYNCED_RESTORED_CHECKOUT_CHECK_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
PREFERRED_RESTORED_CHECKOUT_CHECK_COMMAND="${RESTORED_CHECKOUT_CHECK_COMMAND}"
if [[ "${EXPECT_HELPER_SURFACE}" -eq 1 ]]; then
    PREFERRED_RESTORED_CHECKOUT_CHECK_COMMAND="${SYNCED_RESTORED_CHECKOUT_CHECK_COMMAND}"
fi
SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNCED_SAVED_SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

PREFERRED_SAVED_SNAPSHOT_ROUTE_COMMAND="${SAVED_SNAPSHOT_ROUTE_COMMAND}"
if [[ "${EXPECT_HELPER_SURFACE}" -eq 1 ]]; then
    PREFERRED_SAVED_SNAPSHOT_ROUTE_COMMAND="${SYNCED_SAVED_SNAPSHOT_ROUTE_COMMAND}"
fi
SYNC_ONLY_SAVED_SNAPSHOT_ROUTE_COMMAND="${SYNCED_SAVED_SNAPSHOT_ROUTE_COMMAND} --sync-only"

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 restored-checkout re-entry route",
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "expect_helper_surface": ${EXPECT_HELPER_SURFACE},
    "commands": {
        "route_surface": ${ROUTE_SURFACE_COMMAND@Q},
        "saved_snapshot_route": ${SAVED_SNAPSHOT_ROUTE_COMMAND@Q},
        "synced_saved_snapshot_route": ${SYNCED_SAVED_SNAPSHOT_ROUTE_COMMAND@Q},
        "sync_only_saved_snapshot_route": ${SYNC_ONLY_SAVED_SNAPSHOT_ROUTE_COMMAND@Q},
        "preferred_saved_snapshot_route": ${PREFERRED_SAVED_SNAPSHOT_ROUTE_COMMAND@Q},
        "restored_checkout_check": ${RESTORED_CHECKOUT_CHECK_COMMAND@Q},
        "synced_restored_checkout_check": ${SYNCED_RESTORED_CHECKOUT_CHECK_COMMAND@Q},
        "preferred_restored_checkout_check": ${PREFERRED_RESTORED_CHECKOUT_CHECK_COMMAND@Q},
        "saved_memory_preflight": ${SAVED_MEMORY_PREFLIGHT_COMMAND@Q},
        "saved_archive_integrity": ${SAVED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "linux_build_route": ${LINUX_BUILD_ROUTE_COMMAND@Q},
        "runtime_route": ${RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run route_surface first so missing route docs or helper drift fails before the restored checkout is trusted.",
        "Use preferred_saved_snapshot_route when the reusable checkout is still missing or needs to be refreshed from Memory.",
        "When expect_helper_surface is set, preferred_saved_snapshot_route switches to the synced restore path so the next helper-surface comparison does not immediately fail.",
        "Use sync_only_saved_snapshot_route when the restored checkout already exists and only the helper surface needs to be refreshed in place.",
        "Run restored_checkout_check immediately after restore when the restored checkout should stay a clean historical snapshot and the live helper root remains the command source.",
        "Run synced_restored_checkout_check when the restored checkout was rebuilt with --sync-helper-surface and should be compared against the live helper root for drift.",
        "Run saved_memory_preflight against the restored checkout after the restored-checkout check.",
        "Run saved_archive_integrity next when the route needs to prove the restored checkout still points back to the expected saved repo and dependency archives.",
        "Use linux_build_route when the next blocker is still toolchain or offline dependency staging.",
        "Use runtime_route only after the restored checkout exists and the environment gate is no longer the blocker."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 restored-checkout re-entry route

Repo root:               ${REPO_ROOT}
Live helper root:        ${HELPER_ROOT}
Restored checkout root:  ${RESTORED_CHECKOUT_ROOT}
Memory root:             ${MEMORY_ROOT}
Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Expect helper surface:   $([[ "${EXPECT_HELPER_SURFACE}" -eq 1 ]] && echo yes || echo no)

Read first
==========
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Route surface check:
    ${ROUTE_SURFACE_COMMAND}

  Preferred saved-browser-snapshot restore route:
    ${PREFERRED_SAVED_SNAPSHOT_ROUTE_COMMAND}

  Saved-browser-snapshot restore route:
    ${SAVED_SNAPSHOT_ROUTE_COMMAND}

  Synced saved-browser-snapshot restore route:
    ${SYNCED_SAVED_SNAPSHOT_ROUTE_COMMAND}

  Helper-surface refresh-only route:
    ${SYNC_ONLY_SAVED_SNAPSHOT_ROUTE_COMMAND}

  Preferred restored-checkout check:
    ${PREFERRED_RESTORED_CHECKOUT_CHECK_COMMAND}

  Restored-checkout readiness check:
    ${RESTORED_CHECKOUT_CHECK_COMMAND}

  Synced helper-surface restored-checkout check:
    ${SYNCED_RESTORED_CHECKOUT_CHECK_COMMAND}

  Saved-Memory preflight against the restored checkout:
    ${SAVED_MEMORY_PREFLIGHT_COMMAND}

  Saved-archive integrity preflight against the restored checkout:
    ${SAVED_ARCHIVE_INTEGRITY_COMMAND}

  Linux or WSL build-readiness route from the restored checkout:
    ${LINUX_BUILD_ROUTE_COMMAND}

  Direct runtime re-entry route from the restored checkout:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface check first so missing docs or helper drift fails fast before the restored checkout is trusted.
  - Use the preferred saved-browser-snapshot restore route when the reusable checkout is still missing or needs to be refreshed from Memory.
  - When --expect-helper-surface is set, prefer the synced saved-browser-snapshot restore route so the restored checkout actually carries the helper surface that the next comparison expects.
  - Use the helper-surface refresh-only route when the restored checkout already exists and only the synced issue #3 helper surface needs to be refreshed in place.
  - Run the restored-checkout readiness check right after restore when the restored checkout should stay a clean historical snapshot and the live helper root remains the command source.
  - Use the synced helper-surface restored-checkout check when the restored checkout was rebuilt with --sync-helper-surface.
  - Run the saved-Memory preflight against the restored checkout after the restored-checkout readiness check and before trusting broader helper output.
  - Run the saved-archive integrity preflight after the saved-Memory preflight when the route needs to prove the repo snapshot and dependency bundles still match the expected exact saved artifacts.
  - Use the Linux or WSL build-readiness route when the next blocked step is still toolchain or offline dependency staging.
  - Reopen the direct Page.zig plus win32_backend.zig runtime lane only after the restored checkout exists and the branch-compatible validation gate is no longer the blocker.
EOF
