#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_saved_memory_inputs_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--agent-files-root /path/to/agent_files] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--skip-archive-integrity-check] \
    [--json]

Print the saved-Memory-inputs route for the blocked issue #3 Linux or WSL
re-entry path.
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
DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME="zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"

REPO_ROOT="${DEFAULT_REPO_ROOT}"
MEMORY_ROOT=""
AGENT_FILES_ROOT=""
RESTORED_CHECKOUT_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
SKIP_ARCHIVE_INTEGRITY_CHECK=0
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
        --agent-files-root)
            AGENT_FILES_ROOT="$2"
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
        --skip-archive-integrity-check)
            SKIP_ARCHIVE_INTEGRITY_CHECK=1
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
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory"
fi
if [[ -z "${AGENT_FILES_ROOT}" ]]; then
    AGENT_FILES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/agent_files"
fi
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/${DEFAULT_RESTORED_CHECKOUT_NAME}"
fi
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${AGENT_FILES_ROOT}/${DEFAULT_FALLBACK_ZIG_ARCHIVE_NAME}"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

REPO_SNAPSHOT_PATH="${MEMORY_ROOT}/repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
BLOCKER_INTELLIGENCE_PATH="${MEMORY_ROOT}/repo_archives/browser/blocker_intelligence.yaml"
DEPENDENCIES_ROOT="${MEMORY_ROOT}/repo_archives/browser/dependencies"

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
SAVED_INPUT_COMMAND="python $(format_shell_arg "${REPO_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --agent-files-root $(format_shell_arg "${AGENT_FILES_ROOT}")"
QUICK_SAVED_INPUT_COMMAND="${SAVED_INPUT_COMMAND} --skip-archive-integrity-check"
RESTORED_SAVED_INPUT_COMMAND="${SAVED_INPUT_COMMAND} --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${MEMORY_ROOT}/repo_archives/browser")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${REPO_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_INPUT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    QUICK_SAVED_INPUT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_SAVED_INPUT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${SKIP_ARCHIVE_INTEGRITY_CHECK}" -eq 1 ]]; then
    SAVED_INPUT_COMMAND+=" --skip-archive-integrity-check"
    RESTORED_SAVED_INPUT_COMMAND+=" --skip-archive-integrity-check"
fi

if [[ "${JSON}" -eq 1 ]]; then
    python3 - <<PY
import json

print(json.dumps({
    "issue": "Google issue #3 saved Memory inputs route",
    "repo_root": ${REPO_ROOT@Q},
    "memory_root": ${MEMORY_ROOT@Q},
    "agent_files_root": ${AGENT_FILES_ROOT@Q},
    "restored_checkout_root": ${RESTORED_CHECKOUT_ROOT@Q},
    "repo_snapshot_path": ${REPO_SNAPSHOT_PATH@Q},
    "blocker_intelligence_path": ${BLOCKER_INTELLIGENCE_PATH@Q},
    "dependencies_root": ${DEPENDENCIES_ROOT@Q},
    "fallback_zig_archive": ${FALLBACK_ZIG_ARCHIVE@Q},
    "skip_archive_integrity_check": ${SKIP_ARCHIVE_INTEGRITY_CHECK},
    "commands": {
        "route_surface": ${ROUTE_SURFACE_COMMAND@Q},
        "saved_input_preflight": ${SAVED_INPUT_COMMAND@Q},
        "quick_saved_input_preflight": ${QUICK_SAVED_INPUT_COMMAND@Q},
        "restored_checkout_saved_input_preflight": ${RESTORED_SAVED_INPUT_COMMAND@Q},
        "saved_browser_snapshot_route": ${SNAPSHOT_ROUTE_COMMAND@Q},
        "linux_build_readiness_route": ${BUILD_ROUTE_COMMAND@Q},
        "runtime_reentry_route": ${RUNTIME_ROUTE_COMMAND@Q}
    },
    "notes": [
        "Run route_surface first so helper drift fails fast before the saved archive inputs are blamed.",
        "Use saved_input_preflight for the normal archive readability and presence check.",
        "Use quick_saved_input_preflight only for a fast branch decision when archive integrity is not the question.",
        "Use restored_checkout_saved_input_preflight when a reusable checkout already exists and the route should confirm both saved inputs and the restored helper surface together.",
        "Use saved_browser_snapshot_route when the saved inputs are green but there is still no restored checkout.",
        "Use linux_build_readiness_route when the next blocker is still Zig-line selection, Rust restore, or offline dependency staging.",
        "Use runtime_reentry_route only after the saved inputs are green and the direct Page.zig plus win32_backend.zig lane is truly ready to reopen."
    ]
}, indent=2))
PY
    exit 0
fi

cat <<EOF
Google issue #3 saved Memory inputs route

Repo root:               ${REPO_ROOT}
Memory root:             ${MEMORY_ROOT}
Agent files root:        ${AGENT_FILES_ROOT}
Restored checkout root:  ${RESTORED_CHECKOUT_ROOT}
Saved repo snapshot:     ${REPO_SNAPSHOT_PATH}
Blocker intelligence:    ${BLOCKER_INTELLIGENCE_PATH}
Dependencies root:       ${DEPENDENCIES_ROOT}
Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}
Skip archive integrity:  $([[ "${SKIP_ARCHIVE_INTEGRITY_CHECK}" -eq 1 ]] && echo enabled || echo disabled)

Read first
==========
  docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md

Suggested route
===============
  Surface check:
    ${ROUTE_SURFACE_COMMAND}

  Saved-Memory preflight:
    ${SAVED_INPUT_COMMAND}

  Quick saved-Memory presence check:
    ${QUICK_SAVED_INPUT_COMMAND}

  Saved-Memory preflight when a restored checkout already exists:
    ${RESTORED_SAVED_INPUT_COMMAND}

  Restore route when no reusable checkout exists yet:
    ${SNAPSHOT_ROUTE_COMMAND}

  Linux or WSL build-readiness route:
    ${BUILD_ROUTE_COMMAND}

  Direct runtime re-entry route:
    ${RUNTIME_ROUTE_COMMAND}

Working rules
=============
  - Run the surface check first so helper drift fails fast before the run blames missing Memory inputs.
  - Run the saved-Memory preflight before restore, build-readiness, or runtime helpers when the route depends on the saved repo snapshot and dependency bundles.
  - Use the quick presence-only command for branch selection only; it is not honest archive validation.
  - Use the restored-checkout preflight when a reusable checkout already exists and the route should confirm that surface before broader helper output is trusted.
  - Use the restore route when the saved archive exists but there is still no reusable checkout for Linux or WSL follow-up.
  - Use the Linux or WSL build-readiness route after the saved-Memory preflight passes and the next blocker is still Rust, Zig, offline dependency staging, or prebuilt V8 readiness.
  - Use the direct runtime re-entry route only after the saved checkout exists and the environment gates are no longer the blocker.
  - Treat the attached Zig 0.17 dev bundle as surfaced fallback input only, not as honest issue #3 validation evidence for this branch.
EOF
