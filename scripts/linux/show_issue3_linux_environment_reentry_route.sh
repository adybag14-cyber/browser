#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/show_issue3_linux_environment_reentry_route.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--memory-root /path/to/workspace/memory] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--json]

Print one compact Linux or WSL environment re-entry route for the blocked issue
#3 runtime lane. This wrapper keeps the saved-snapshot, restored-checkout,
saved-archive-integrity, Linux build-readiness, and narrowed runtime helpers in
one practical order.
EOF
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

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_RESTORED_CHECKOUT_NAME="browser-memory-snapshot"
REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT=""
RESTORED_CHECKOUT_ROOT=""
MEMORY_ROOT=""
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

SNAPSHOT_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
RESTORED_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
ARCHIVE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
BUILD_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_linux_build_readiness_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
RUNTIME_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"

SNAPSHOT_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
PREFERRED_SNAPSHOT_ROUTE_COMMAND="${SNAPSHOT_ROUTE_COMMAND} --sync-helper-surface"
RESTORED_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_restored_checkout_reentry_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}")"
PREFERRED_RESTORED_ROUTE_COMMAND="${RESTORED_ROUTE_COMMAND} --expect-helper-surface"

SELF_CONTAINED_SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --helper-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SELF_CONTAINED_ARCHIVE_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_saved_archive_integrity_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}")"
SELF_CONTAINED_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
SELF_CONTAINED_RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    PREFERRED_SNAPSHOT_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RESTORED_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    PREFERRED_RESTORED_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SELF_CONTAINED_SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SELF_CONTAINED_ARCHIVE_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SELF_CONTAINED_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    SELF_CONTAINED_RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "issue": %s,\n' "$(json_escape "Google issue #3 Linux environment re-entry route")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "helper_root": %s,\n' "$(json_escape "${HELPER_ROOT}")"
    printf '  "restored_checkout_root": %s,\n' "$(json_escape "${RESTORED_CHECKOUT_ROOT}")"
    printf '  "memory_root": %s,\n' "$(json_escape "${MEMORY_ROOT}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "read_first": [\n'
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_LINUX_ENVIRONMENT_REENTRY_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_RUNTIME_REENTRY_GATES.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md")"
    printf '    %s,\n' "$(json_escape "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md")"
    printf '    %s\n' "$(json_escape "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md")"
    printf '  ],\n'
    printf '  "commands": {\n'
    printf '    "snapshot_surface": %s,\n' "$(json_escape "${SNAPSHOT_SURFACE_COMMAND}")"
    printf '    "restored_surface": %s,\n' "$(json_escape "${RESTORED_SURFACE_COMMAND}")"
    printf '    "archive_surface": %s,\n' "$(json_escape "${ARCHIVE_SURFACE_COMMAND}")"
    printf '    "build_surface": %s,\n' "$(json_escape "${BUILD_SURFACE_COMMAND}")"
    printf '    "runtime_surface": %s,\n' "$(json_escape "${RUNTIME_SURFACE_COMMAND}")"
    printf '    "snapshot_route": %s,\n' "$(json_escape "${SNAPSHOT_ROUTE_COMMAND}")"
    printf '    "preferred_snapshot_route": %s,\n' "$(json_escape "${PREFERRED_SNAPSHOT_ROUTE_COMMAND}")"
    printf '    "restored_route": %s,\n' "$(json_escape "${RESTORED_ROUTE_COMMAND}")"
    printf '    "preferred_restored_route": %s,\n' "$(json_escape "${PREFERRED_RESTORED_ROUTE_COMMAND}")"
    printf '    "self_contained_saved_memory_preflight": %s,\n' "$(json_escape "${SELF_CONTAINED_SAVED_MEMORY_PREFLIGHT_COMMAND}")"
    printf '    "self_contained_archive_route": %s,\n' "$(json_escape "${SELF_CONTAINED_ARCHIVE_ROUTE_COMMAND}")"
    printf '    "self_contained_build_route": %s,\n' "$(json_escape "${SELF_CONTAINED_BUILD_ROUTE_COMMAND}")"
    printf '    "self_contained_runtime_route": %s\n' "$(json_escape "${SELF_CONTAINED_RUNTIME_ROUTE_COMMAND}")"
    printf '  },\n'
    printf '  "notes": [\n'
    printf '    %s,\n' "$(json_escape "Run the five surface checks first so branch-local helper drift fails before the saved snapshot is trusted.")"
    printf '    %s,\n' "$(json_escape "Prefer preferred_snapshot_route when the restored checkout should become its own follow-up root, because it syncs the current issue #3 helper surface into the restored snapshot.")"
    printf '    %s,\n' "$(json_escape "Run preferred_restored_route immediately after the synced restore so restored-checkout drift is caught before archive or toolchain work widens out again.")"
    printf '    %s,\n' "$(json_escape "Use the self-contained commands only after the synced restore path has populated the restored checkout with the current helper surface.")"
    printf '    %s\n' "$(json_escape "Keep the route ordered as saved snapshot, restored checkout, saved archive integrity, Linux build readiness, and only then the narrowed runtime re-entry path.")"
    printf '  ]\n'
    printf '}\n'
    exit 0
fi

cat <<EOF
Google issue #3 Linux environment re-entry route

Repo root:               ${REPO_ROOT}
Live helper root:        ${HELPER_ROOT}
Restored checkout root:  ${RESTORED_CHECKOUT_ROOT}
Memory root:             ${MEMORY_ROOT}
Fallback Zig archive:    ${FALLBACK_ZIG_ARCHIVE:-not found beside the repo workspace}

Read first
==========
  docs/ISSUE3_LINUX_ENVIRONMENT_REENTRY_ROUTE.md
  docs/ISSUE3_RUNTIME_REENTRY_GATES.md
  docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md
  docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md
  docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md
  docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md
  docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md

Fail-fast surface checks
========================
  Saved-browser-snapshot surface:
    ${SNAPSHOT_SURFACE_COMMAND}

  Restored-checkout surface:
    ${RESTORED_SURFACE_COMMAND}

  Saved-archive-integrity surface:
    ${ARCHIVE_SURFACE_COMMAND}

  Linux build-readiness surface:
    ${BUILD_SURFACE_COMMAND}

  Narrowed runtime surface:
    ${RUNTIME_SURFACE_COMMAND}

Preferred route
===============
  Synced saved-browser-snapshot restore route:
    ${PREFERRED_SNAPSHOT_ROUTE_COMMAND}

  Synced restored-checkout re-entry route:
    ${PREFERRED_RESTORED_ROUTE_COMMAND}

Self-contained follow-up from the synced restored checkout
==========================================================
  Saved-Memory preflight:
    ${SELF_CONTAINED_SAVED_MEMORY_PREFLIGHT_COMMAND}

  Saved-archive-integrity route:
    ${SELF_CONTAINED_ARCHIVE_ROUTE_COMMAND}

  Linux build-readiness route:
    ${SELF_CONTAINED_BUILD_ROUTE_COMMAND}

  Narrowed runtime re-entry route:
    ${SELF_CONTAINED_RUNTIME_ROUTE_COMMAND}

Alternate live-helper route
===========================
  Saved-browser-snapshot route without helper sync:
    ${SNAPSHOT_ROUTE_COMMAND}

  Restored-checkout route without helper-surface expectation:
    ${RESTORED_ROUTE_COMMAND}

Working rules
=============
  - Run the five surface checks first so branch-local helper drift fails before the saved snapshot is trusted.
  - Prefer the synced restore route when the restored checkout should become its own follow-up root.
  - Run the restored-checkout route immediately after restore so snapshot drift is caught before archive or toolchain work widens out again.
  - Use the self-contained follow-up commands only after the synced restore path has populated the restored checkout with the current helper surface.
  - Keep the route ordered as saved snapshot, restored checkout, saved archive integrity, Linux build readiness, and only then the narrowed runtime re-entry path.
EOF
