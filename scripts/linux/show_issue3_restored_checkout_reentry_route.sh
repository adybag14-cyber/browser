#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_restored_checkout_reentry_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--restored-root /path/to/restored/browser-checkout] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the restored-checkout re-entry route for the blocked issue #3 Linux or
WSL path once a saved browser snapshot has already been restored.
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
DEFAULT_RESTORED_ROOT_NAME="browser-memory-snapshot"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
RESTORED_ROOT=""
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
        --restored-root)
            RESTORED_ROOT="$2"
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
if [[ -z "${RESTORED_ROOT}" ]]; then
    RESTORED_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/${DEFAULT_RESTORED_ROOT_NAME}"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${HELPER_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
SAVED_SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --destination $(format_shell_arg "${RESTORED_ROOT}")"
RESTORED_CHECK_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_ROOT}")"
SYNCED_RESTORED_CHECK_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_ROOT}")"
SAVED_ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${RESTORED_ROOT}")"
BUILD_READINESS_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_READINESS_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 restored checkout re-entry route",
    "repo_root": ${REPO_ROOT@Q},
    "helper_root": ${HELPER_ROOT@Q},
    "restored_root": ${RESTORED_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "read_first": [
        "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
    ],
    "commands": {
        "surface_check": ${ROUTE_SURFACE_COMMAND@Q},
        "saved_browser_snapshot_route": ${SAVED_SNAPSHOT_ROUTE_COMMAND@Q},
        "restored_checkout_check": ${RESTORED_CHECK_COMMAND@Q},
        "synced_restored_checkout_check": ${SYNCED_RESTORED_CHECK_COMMAND@Q},
        "saved_memory_preflight": ${SAVED_MEMORY_PREFLIGHT_COMMAND@Q},
        "saved_archive_integrity": ${SAVED_ARCHIVE_INTEGRITY_COMMAND@Q},
        "linux_build_readiness_route": ${BUILD_READINESS_ROUTE_COMMAND@Q},
        "runtime_reentry_route": ${RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run the surface_check command first so missing docs, helper drift, or a missing restored-checkout helper fails fast before the restored checkout is trusted.",
        "Use saved_browser_snapshot_route when the saved snapshot may need to be restored again before the restored-checkout checkpoint can be rerun honestly.",
        "Use restored_checkout_check when the restored checkout should stay a clean historical snapshot and the live helper root remains the command source.",
        "Use synced_restored_checkout_check when the restored checkout was created with --sync-helper-surface and should be compared against the live helper root for drift.",
        "Run saved_memory_preflight only after the restored checkout passes its own checkpoint.",
        "Run saved_archive_integrity only after the restored checkout and saved-memory presence checks pass.",
        "Move into linux_build_readiness_route only after the restored checkout, saved-memory preflight, and archive-integrity route agree on the same follow-up root.",
        "Reopen runtime_reentry_route only after the restored checkout proves its repo shape and optional synced-helper surface are both honest."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 restored checkout re-entry route

Repo root:             ${REPO_ROOT}
Live helper root:      ${HELPER_ROOT}
Restored checkout:     ${RESTORED_ROOT}
Fallback Zig archive:  ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md

Suggested route
===============
  Route surface check:
    ${ROUTE_SURFACE_COMMAND}

  Return to the saved-browser-snapshot route when the checkout may need restore again:
    ${SAVED_SNAPSHOT_ROUTE_COMMAND}

  Restored-checkout readiness check:
    ${RESTORED_CHECK_COMMAND}

  Synced helper-surface restored-checkout check:
    ${SYNCED_RESTORED_CHECK_COMMAND}

  Saved-Memory preflight against the restored checkout:
    ${SAVED_MEMORY_PREFLIGHT_COMMAND}

  Saved-archive integrity preflight against the restored checkout:
    ${SAVED_ARCHIVE_INTEGRITY_COMMAND}

  Linux or WSL build-readiness route:
    ${BUILD_READINESS_ROUTE_COMMAND}

  Direct runtime re-entry route:
    ${RUNTIME_ROUTE_COMMAND}

Notes
=====
  - Run the restored-checkout readiness check before the saved-memory or saved-archive follow-ups.
  - Use the synced helper-surface check only when the restored checkout was rebuilt with --sync-helper-surface.
  - Keep the live helper root as the command source when the restored checkout should remain a clean historical snapshot.
  - Only reopen the direct runtime route after the restored checkout, saved-memory, and archive-integrity checkpoints all agree on the same follow-up root.
EOF
