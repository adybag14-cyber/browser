#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_restored_checkout_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--restored-checkout-root /path/to/restored/browser-checkout] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the restored-checkout replay route for the blocked issue #3 Linux or WSL
re-entry path after a saved snapshot checkout already exists.
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
FALLBACK_ZIG_ARCHIVE=""
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
        --restored-checkout-root)
            RESTORED_CHECKOUT_ROOT="$2"
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
if [[ -z "${HELPER_ROOT}" ]]; then
    HELPER_ROOT="${REPO_ROOT}"
fi
HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/${DEFAULT_RESTORED_CHECKOUT_NAME}"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${HELPER_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_restored_checkout_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
RESTORED_CHECKOUT_CHECK_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SYNCED_RESTORED_CHECKOUT_CHECK_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SYNCED_SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SYNCED_SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SYNCED_LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SYNCED_RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNCED_SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNCED_SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNCED_LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SYNCED_RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 restored checkout replay route",
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "commands": {
        "route_surface": ${ROUTE_SURFACE_COMMAND@Q},
        "restored_checkout_check": ${RESTORED_CHECKOUT_CHECK_COMMAND@Q},
        "synced_restored_checkout_check": ${SYNCED_RESTORED_CHECKOUT_CHECK_COMMAND@Q},
        "saved_memory_preflight": ${SAVED_MEMORY_PREFLIGHT_COMMAND@Q},
        "synced_saved_memory_preflight": ${SYNCED_SAVED_MEMORY_PREFLIGHT_COMMAND@Q},
        "saved_archive_integrity": ${SAVED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "synced_saved_archive_integrity": ${SYNCED_SAVED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "linux_build_route": ${LINUX_BUILD_ROUTE_COMMAND@Q},
        "synced_linux_build_route": ${SYNCED_LINUX_BUILD_ROUTE_COMMAND@Q},
        "runtime_route": ${RUNTIME_ROUTE_COMMAND@Q},
        "synced_runtime_route": ${SYNCED_RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run route_surface first so missing branch-local helpers fail fast before the restored checkout is trusted.",
        "Run restored_checkout_check right after restore when the restored checkout is still using the live helper root.",
        "Run synced_restored_checkout_check when the restored checkout was created with a self-contained synced helper surface.",
        "Use the live-helper commands when the restored checkout should stay a clean historical snapshot.",
        "Use the synced commands only when the restored checkout carries the current issue #3 helper docs and scripts.",
        "Run the saved-Memory preflight after the restored-checkout check and before trusting build-readiness or runtime route output.",
        "Run saved-archive integrity after the saved-Memory preflight when the route still depends on the exact saved repo and dependency bundles.",
        "Use the Linux build route when the next blocker is still toolchain or offline dependency staging.",
        "Use the direct runtime route only after the restored checkout exists and the publication and toolchain gates are green."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 restored checkout replay route

Repo root:                ${REPO_ROOT}
Live helper root:         ${HELPER_ROOT}
Restored checkout root:   ${RESTORED_CHECKOUT_ROOT}
Fallback Zig archive:     ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Route surface check:
    ${ROUTE_SURFACE_COMMAND}

  Restored-checkout readiness check:
    ${RESTORED_CHECKOUT_CHECK_COMMAND}

  Saved-Memory preflight against the restored checkout:
    ${SAVED_MEMORY_PREFLIGHT_COMMAND}

  Saved-archive integrity preflight against the restored checkout:
    ${SAVED_ARCHIVE_INTEGRITY_COMMAND}

  Linux or WSL build-readiness route from the restored checkout:
    ${LINUX_BUILD_ROUTE_COMMAND}

  Direct runtime re-entry route from the restored checkout:
    ${RUNTIME_ROUTE_COMMAND}

  Restored checkout with a self-contained synced helper surface:
    Synced restored-checkout readiness check:
      ${SYNCED_RESTORED_CHECKOUT_CHECK_COMMAND}
    Synced saved-Memory preflight:
      ${SYNCED_SAVED_MEMORY_PREFLIGHT_COMMAND}
    Synced saved-archive integrity preflight:
      ${SYNCED_SAVED_ARCHIVE_INTEGRITY_COMMAND}
    Synced Linux or WSL build-readiness route:
      ${SYNCED_LINUX_BUILD_ROUTE_COMMAND}
    Synced direct runtime re-entry route:
      ${SYNCED_RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the route surface check first so missing branch-local helpers fail before the restored checkout is trusted.
  - Run the restored-checkout readiness check immediately after restore so missing repo surfaces or helper drift fail before broader preflights.
  - Use the live-helper commands when the restored checkout should stay a clean historical snapshot.
  - Use the self-contained synced helper surface commands only when the restored checkout carries the current issue #3 helper docs and scripts.
  - Run the saved-Memory preflight after the restored-checkout check and before trusting build-readiness or runtime route output.
  - Run the saved-archive integrity preflight after the saved-Memory preflight when the route still depends on the exact saved repo and dependency bundles.
  - Use the Linux or WSL build-readiness route when the next blocker is still toolchain or offline dependency staging.
  - Reopen the direct Page.zig plus win32_backend.zig lane only after the restored checkout exists and the publication and toolchain gates are green.
EOF
