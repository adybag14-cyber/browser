#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF2'
Usage:
  bash scripts/linux/show_issue3_progress_tracker_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/helper/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--saved-archives-root /path/to/memory/repo_archives/browser[/dependencies]] \
    [--toolchains-root /path/to/toolchains] \
    [--offline-deps-root /path/to/offline-deps] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print the issue #11 progress-tracker route for the blocked issue #3 Linux or
WSL re-entry lane.
EOF2
}

format_shell_arg() {
    python3 - "$1" <<'PY'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY
}

json_escape() {
    python3 - "$1" <<'PY'
import json
import sys

print(json.dumps(sys.argv[1]))
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

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
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
        --helper-root)
            HELPER_ROOT="$2"
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
if [[ -z "${HELPER_ROOT}" ]]; then
    HELPER_ROOT="${REPO_ROOT}"
fi
HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
HELPER_WORKSPACE_ROOT="$(cd "${HELPER_ROOT}/.." && pwd)"
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="${HELPER_WORKSPACE_ROOT}/memory"
fi
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/browser-memory-snapshot"
fi
if [[ -z "${SAVED_ARCHIVES_ROOT}" ]]; then
    SAVED_ARCHIVES_ROOT="${MEMORY_ROOT}/repo_archives/browser"
fi
SAVED_ARCHIVES_ROOT="$(normalize_saved_archives_root "${SAVED_ARCHIVES_ROOT}")"
if [[ -z "${TOOLCHAINS_ROOT}" ]]; then
    TOOLCHAINS_ROOT="${HELPER_WORKSPACE_ROOT}/toolchains"
fi
if [[ -z "${OFFLINE_DEPS_ROOT}" ]]; then
    OFFLINE_DEPS_ROOT="${HELPER_WORKSPACE_ROOT}/offline-deps"
fi
RUST_TOOLCHAIN_DIR="${TOOLCHAINS_ROOT}/rust-1.79.0"
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="${HELPER_WORKSPACE_ROOT}/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

ISSUE_NUMBER=11
ISSUE_URL="https://github.com/adybag14-cyber/browser/issues/11"
ROUTE_NOTE_PATH="${HELPER_ROOT}/docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"

ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_progress_tracker_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
SAVED_MEMORY_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_memory_inputs_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SAVED_RUST_ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
SAVED_RUST_ARCHIVE_CANDIDATES_COMMAND="python3 $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_rust_archive_candidates.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
STAGED_RUST_TOOLCHAIN_CANDIDATES_COMMAND="python3 $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_staged_rust_toolchain_candidates.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
SAVED_RUST_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_rust_toolchain_route.sh") --browser-root $(format_shell_arg "${REPO_ROOT}") --dependencies-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchain-parent $(format_shell_arg "${TOOLCHAINS_ROOT}") --toolchain-root $(format_shell_arg "${RUST_TOOLCHAIN_DIR}")"
SAVED_ZIG_ARCHIVE_ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
SAVED_ZIG_ARCHIVE_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
STAGED_ZIG_CANDIDATES_COMMAND="python3 $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_staged_zig_toolchain_candidates.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}")"
MATCHING_LINE_GATE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_zig_toolchain_match.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}")"
ARCHIVE_RESTORE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --rust-toolchain-dir $(format_shell_arg "${RUST_TOOLCHAIN_DIR}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"
ZIG_RECOVERY_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_zig_toolchain_recovery_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --toolchains-root $(format_shell_arg "${TOOLCHAINS_ROOT}") --saved-archives-root $(format_shell_arg "${SAVED_ARCHIVES_ROOT}") --offline-deps-root $(format_shell_arg "${OFFLINE_DEPS_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ZIG_ARCHIVE_ROUTE_SURFACE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SAVED_ZIG_ARCHIVE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    MATCHING_LINE_GATE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ZIG_RECOVERY_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

START_COMMENT_TEMPLATE=$'Goal: <state the exact Linux/WSL re-entry helper or environment gate work>\nStarted: <UTC timestamp>\nNext: <state the first concrete helper, validation check, or branch-safe change you are about to make>'
COMPLETION_COMMENT_TEMPLATE=$'Achieved: <state what route, helper, or branch-safe re-entry improvement landed>\nCompleted: <UTC timestamp>\nCommit: <commit sha>\nValidation: <state the focused helper check, self-test, or follow-up route that now applies>'

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Google issue #3 issue #11 progress-tracker route")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "helper_root": %s,\n' "$(json_escape "${HELPER_ROOT}")"
    printf '  "memory_root": %s,\n' "$(json_escape "${MEMORY_ROOT}")"
    printf '  "restored_checkout_root": %s,\n' "$(json_escape "${RESTORED_CHECKOUT_ROOT}")"
    printf '  "saved_archives_root": %s,\n' "$(json_escape "${SAVED_ARCHIVES_ROOT}")"
    printf '  "toolchains_root": %s,\n' "$(json_escape "${TOOLCHAINS_ROOT}")"
    printf '  "offline_deps_root": %s,\n' "$(json_escape "${OFFLINE_DEPS_ROOT}")"
    printf '  "issue_number": %s,\n' "$(json_escape "${ISSUE_NUMBER}")"
    printf '  "issue_url": %s,\n' "$(json_escape "${ISSUE_URL}")"
    printf '  "route_note_path": %s,\n' "$(json_escape "${ROUTE_NOTE_PATH}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "commands": {\n'
    printf '    "route_surface": %s,\n' "$(json_escape "${ROUTE_SURFACE_COMMAND}")"
    printf '    "saved_memory_inputs_route": %s,\n' "$(json_escape "${SAVED_MEMORY_ROUTE_COMMAND}")"
    printf '    "saved_rust_toolchain_route_surface": %s,\n' "$(json_escape "${SAVED_RUST_ROUTE_SURFACE_COMMAND}")"
    printf '    "saved_rust_archive_candidates": %s,\n' "$(json_escape "${SAVED_RUST_ARCHIVE_CANDIDATES_COMMAND}")"
    printf '    "staged_rust_toolchain_candidates": %s,\n' "$(json_escape "${STAGED_RUST_TOOLCHAIN_CANDIDATES_COMMAND}")"
    printf '    "saved_rust_toolchain_route": %s,\n' "$(json_escape "${SAVED_RUST_ROUTE_COMMAND}")"
    printf '    "saved_zig_archive_route_surface": %s,\n' "$(json_escape "${SAVED_ZIG_ARCHIVE_ROUTE_SURFACE_COMMAND}")"
    printf '    "saved_zig_archive_candidates_route": %s,\n' "$(json_escape "${SAVED_ZIG_ARCHIVE_ROUTE_COMMAND}")"
    printf '    "staged_zig_toolchain_candidates": %s,\n' "$(json_escape "${STAGED_ZIG_CANDIDATES_COMMAND}")"
    printf '    "zig_toolchain_matching_line_gate": %s,\n' "$(json_escape "${MATCHING_LINE_GATE_COMMAND}")"
    printf '    "zig_archive_restore_surface": %s,\n' "$(json_escape "${ARCHIVE_RESTORE_SURFACE_COMMAND}")"
    printf '    "linux_build_readiness_route": %s,\n' "$(json_escape "${BUILD_ROUTE_COMMAND}")"
    printf '    "zig_toolchain_recovery_route": %s\n' "$(json_escape "${ZIG_RECOVERY_ROUTE_COMMAND}")"
    printf '  },\n'
    printf '  "start_comment_template": %s,\n' "$(json_escape "${START_COMMENT_TEMPLATE}")"
    printf '  "completion_comment_template": %s,\n' "$(json_escape "${COMPLETION_COMMENT_TEMPLATE}")"
    printf '  "notes": [\n'
    printf '    %s,\n' "$(json_escape "Run route_surface first so note drift or helper drift fails fast before a scheduled run trusts issue #11 as its progress target.")"
    printf '    %s,\n' "$(json_escape "Use issue #11 while the Linux or WSL re-entry lane is still blocked on saved-input, toolchain, or offline dependency gates.")"
    printf '    %s,\n' "$(json_escape "When the immediate slice is about restoring or reusing the saved Rust toolchain, surface the dedicated saved-Rust route before broader Linux or WSL build-readiness reruns trust the environment.")"
    printf '    %s,\n' "$(json_escape "Surface saved Rust archive candidates and staged Rust toolchain candidates before unpacking the archive again so the route can reuse a matching 1.79.0 toolchain when one is already staged.")"
    printf '    %s,\n' "$(json_escape "When the immediate slice is about choosing or restoring a saved Zig 0.15.x archive, surface the dedicated saved-Zig route before falling back to the broader Zig recovery note.")"
    printf '    %s,\n' "$(json_escape "Surface staged Zig candidates before unpacking a saved archive so the route can reuse an already-matching toolchain when one is present.")"
    printf '    %s,\n' "$(json_escape "Thread helper-root plus the surfaced Memory, restored-checkout, saved-archives, toolchains, and offline-deps roots through this route so nested follow-up helpers keep pointing at the same practical workspace layout.")"
    printf '    %s,\n' "$(json_escape "Thread --fallback-zig-archive through this route when the attached archive is not beside the repo workspace so nested saved-memory, saved-Zig, build-readiness, matching-line, and Zig recovery helpers all inspect the same surfaced path.")"
    printf '    %s,\n' "$(json_escape "Run the matching-line gate after any saved Zig restore so the staged toolchains root proves a branch-compatible 0.15.x executable exists before broader readiness is trusted again.")"
    printf '    %s,\n' "$(json_escape "Run the archive-restore surface check before staging a chosen saved Zig archive under ../toolchains.")"
    printf '    %s,\n' "$(json_escape "Keep the start comment compact with Goal, Started, and Next.")"
    printf '    %s,\n' "$(json_escape "Post the completion comment only after the branch commit exists, and keep it compact with Achieved, Completed, Commit, and Validation.")"
    printf '    %s\n' "$(json_escape "When the next step is still environment-gated, follow the saved-memory, saved-Rust, saved-Zig, staged-Zig, build-readiness, matching-line, or Zig recovery routes instead of reopening the direct Page.zig plus win32_backend.zig patch.")"
    printf '  ]\n'
    printf '}\n'
    exit 0
fi

cat <<EOF2
Google issue #3 issue #11 progress-tracker route

Repo root:               ${REPO_ROOT}
Live helper root:        ${HELPER_ROOT}
Memory root:             ${MEMORY_ROOT}
Restored checkout root:  ${RESTORED_CHECKOUT_ROOT}
Saved archives root:     ${SAVED_ARCHIVES_ROOT}
Toolchains root:         ${TOOLCHAINS_ROOT}
Offline deps root:       ${OFFLINE_DEPS_ROOT}
Issue:                   #${ISSUE_NUMBER}
Issue URL:               ${ISSUE_URL}
Route note:              ${ROUTE_NOTE_PATH}
Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_SAVED_MEMORY_INPUTS_ROUTE.md
  docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md
  docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_ARCHIVE_RESTORE_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md

Suggested route
===============
  Route surface check:
    ${ROUTE_SURFACE_COMMAND}

  Saved-Memory follow-up route:
    ${SAVED_MEMORY_ROUTE_COMMAND}

  Saved Rust route surface check:
    ${SAVED_RUST_ROUTE_SURFACE_COMMAND}

  Saved Rust archive candidates:
    ${SAVED_RUST_ARCHIVE_CANDIDATES_COMMAND}

  Staged Rust toolchain candidates:
    ${STAGED_RUST_TOOLCHAIN_CANDIDATES_COMMAND}

  Saved Rust toolchain route:
    ${SAVED_RUST_ROUTE_COMMAND}

  Saved Zig route surface check:
    ${SAVED_ZIG_ARCHIVE_ROUTE_SURFACE_COMMAND}

  Saved Zig archive candidates route:
    ${SAVED_ZIG_ARCHIVE_ROUTE_COMMAND}

  Staged Zig candidates:
    ${STAGED_ZIG_CANDIDATES_COMMAND}

  Matching-line gate after any restore:
    ${MATCHING_LINE_GATE_COMMAND}

  Archive restore surface check:
    ${ARCHIVE_RESTORE_SURFACE_COMMAND}

  Linux or WSL build-readiness route:
    ${BUILD_ROUTE_COMMAND}

  Zig toolchain recovery route:
    ${ZIG_RECOVERY_ROUTE_COMMAND}

Start comment template
======================
Goal: <state the exact Linux/WSL re-entry helper or environment gate work>
Started: <UTC timestamp>
Next: <state the first concrete helper, validation check, or branch-safe change you are about to make>

Completion comment template
===========================
Achieved: <state what route, helper, or branch-safe re-entry improvement landed>
Completed: <UTC timestamp>
Commit: <commit sha>
Validation: <state the focused helper check, self-test, or follow-up route that now applies>

Working rules
=============
  - Run the route surface check first so note drift or helper drift fails fast before a scheduled run trusts issue #11 as its progress target.
  - Use issue #11 while the Linux or WSL re-entry lane is still blocked on saved-input, toolchain, or offline dependency gates.
  - When the immediate slice is about restoring or reusing the saved Rust toolchain, surface the dedicated saved-Rust route before broader Linux or WSL build-readiness reruns trust the environment.
  - Surface saved Rust archive candidates and staged Rust toolchain candidates before unpacking the archive again so the route can reuse a matching 1.79.0 toolchain when one is already staged.
  - When the immediate slice is about choosing or restoring a saved Zig 0.15.x archive, surface the dedicated saved-Zig route before falling back to the broader Zig recovery note.
  - Surface staged Zig candidates before unpacking a saved archive so the route can reuse an already-matching toolchain when one is present.
  - Thread helper-root plus the surfaced Memory, restored-checkout, saved-archives, toolchains, and offline-deps roots through this route so nested follow-up helpers keep pointing at the same practical workspace layout.
  - Thread --fallback-zig-archive through this route when the attached archive is not beside the repo workspace so nested saved-memory, saved-Zig, build-readiness, matching-line, and Zig recovery helpers all inspect the same surfaced path.
  - Run the matching-line gate after any saved Zig restore so the staged toolchains root has to prove a real branch-compatible Zig candidate exists.
  - Run the archive-restore surface check before staging a chosen saved Zig archive under ../toolchains.
  - Keep the start comment compact with Goal, Started, and Next.
  - Post the completion comment only after the branch commit exists, and keep it compact with Achieved, Completed, Commit, and Validation.
  - When the next step is still environment-gated, follow the saved-memory, saved-Rust, saved-Zig, staged-Zig, build-readiness, matching-line, or Zig recovery routes instead of reopening the direct Page.zig plus win32_backend.zig patch.
EOF2