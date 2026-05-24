#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_restored_checkout_follow_up.sh \
    [--repo-root /path/to/restored/browser-checkout] \
    [--helper-root /path/to/live/browser-checkout] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--expect-synced-helper-surface] \
    [--json]

Check that a restored browser snapshot is ready for the next Linux or WSL
follow-up commands after restore. This helper keeps the post-restore decision
small:

- confirm the restored checkout really exists and still looks like a browser
  checkout
- optionally require the synced issue #3 helper surface inside that checkout
- print the exact saved-memory, archive-integrity, build-readiness, and runtime
  route commands to run next
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
REPO_ROOT="${DEFAULT_REPO_ROOT}"
HELPER_ROOT="${DEFAULT_REPO_ROOT}"
FALLBACK_ZIG_ARCHIVE=""
EXPECT_SYNCED_HELPER_SURFACE=0
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
        --fallback-zig-archive)
            FALLBACK_ZIG_ARCHIVE="$2"
            shift 2
            ;;
        --expect-synced-helper-surface)
            EXPECT_SYNCED_HELPER_SURFACE=1
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
HELPER_ROOT="$(cd "${HELPER_ROOT}" && pwd)"
if [[ -z "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    CANDIDATE_FALLBACK_ZIG_ARCHIVE="$(cd "${HELPER_ROOT}/.." && pwd)/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
    if [[ -f "${CANDIDATE_FALLBACK_ZIG_ARCHIVE}" ]]; then
        FALLBACK_ZIG_ARCHIVE="${CANDIDATE_FALLBACK_ZIG_ARCHIVE}"
    fi
fi

declare -a REQUIRED_CHECKOUT_PATHS=(
    "build.zig.zon|restored browser manifest"
)

declare -a REQUIRED_SYNCED_SURFACE_PATHS=(
    "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md|saved-browser-snapshot route note"
    "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md|Linux build-readiness route note"
    "docs/ISSUE3_RUNTIME_REENTRY_GATES.md|runtime gate note"
    "scripts/check_issue3_saved_memory_inputs.py|saved-memory preflight helper"
    "scripts/check_issue3_saved_archive_integrity.py|saved-archive integrity helper"
    "scripts/check_linux_build_readiness.py|Linux build-readiness helper"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Linux build-readiness route helper"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|runtime re-entry route helper"
)

declare -a REQUIRED_HELPER_ROOT_PATHS=(
    "scripts/check_issue3_saved_memory_inputs.py|saved-memory preflight helper"
    "scripts/check_issue3_saved_archive_integrity.py|saved-archive integrity helper"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh|Linux build-readiness route helper"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh|runtime re-entry route helper"
)

missing_count=0
declare -a STATUS_ROWS=()

record_path_check() {
    local root="$1"
    local relative_path="$2"
    local label="$3"
    local exists=0
    if [[ -f "${root}/${relative_path}" ]]; then
        exists=1
    fi
    if [[ "${exists}" -eq 0 ]]; then
        missing_count=$((missing_count + 1))
    fi
    STATUS_ROWS+=("${root}|${relative_path}|${label}|${exists}")
}

for entry in "${REQUIRED_CHECKOUT_PATHS[@]}"; do
    IFS="|" read -r relative_path label <<<"${entry}"
    record_path_check "${REPO_ROOT}" "${relative_path}" "${label}"
done

for entry in "${REQUIRED_HELPER_ROOT_PATHS[@]}"; do
    IFS="|" read -r relative_path label <<<"${entry}"
    record_path_check "${HELPER_ROOT}" "${relative_path}" "${label}"
done

if [[ "${EXPECT_SYNCED_HELPER_SURFACE}" -eq 1 ]]; then
    for entry in "${REQUIRED_SYNCED_SURFACE_PATHS[@]}"; do
        IFS="|" read -r relative_path label <<<"${entry}"
        record_path_check "${REPO_ROOT}" "${relative_path}" "${label}"
    done
fi

FOLLOW_UP_ROOT="${HELPER_ROOT}"
if [[ "${EXPECT_SYNCED_HELPER_SURFACE}" -eq 1 ]]; then
    FOLLOW_UP_ROOT="${REPO_ROOT}"
fi

SAVED_MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${FOLLOW_UP_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${FOLLOW_UP_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
LINUX_BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${FOLLOW_UP_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${FOLLOW_UP_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    SAVED_MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    LINUX_BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "profile": %s,\n' "$(json_escape "issue3-restored-checkout-follow-up")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "helper_root": %s,\n' "$(json_escape "${HELPER_ROOT}")"
    printf '  "follow_up_root": %s,\n' "$(json_escape "${FOLLOW_UP_ROOT}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "expect_synced_helper_surface": %s,\n' "$([[ "${EXPECT_SYNCED_HELPER_SURFACE}" -eq 1 ]] && echo true || echo false)"
    printf '  "missing_count": %d,\n' "${missing_count}"
    printf '  "checks": [\n'
    for index in "${!STATUS_ROWS[@]}"; do
        IFS="|" read -r root relative_path label exists <<<"${STATUS_ROWS[$index]}"
        [[ "${index}" -gt 0 ]] && printf ',\n'
        printf '    {"root": %s, "path": %s, "label": %s, "exists": %s}' \
            "$(json_escape "${root}")" \
            "$(json_escape "${relative_path}")" \
            "$(json_escape "${label}")" \
            "$([[ "${exists}" -eq 1 ]] && echo true || echo false)"
    done
    printf '\n  ],\n'
    printf '  "commands": {\n'
    printf '    "saved_memory_preflight": %s,\n' "$(json_escape "${SAVED_MEMORY_PREFLIGHT_COMMAND}")"
    printf '    "archive_integrity": %s,\n' "$(json_escape "${ARCHIVE_INTEGRITY_COMMAND}")"
    printf '    "linux_build_route": %s,\n' "$(json_escape "${LINUX_BUILD_ROUTE_COMMAND}")"
    printf '    "runtime_route": %s\n' "$(json_escape "${RUNTIME_ROUTE_COMMAND}")"
    printf '  }\n'
    printf '}\n'
    if [[ "${missing_count}" -gt 0 ]]; then
        exit 1
    fi
    exit 0
fi

echo "Issue #3 restored checkout follow-up"
echo
echo "Restored checkout:      ${REPO_ROOT}"
echo "Helper root:            ${HELPER_ROOT}"
echo "Follow-up root:         ${FOLLOW_UP_ROOT}"
echo "Fallback Zig archive:   ${FALLBACK_ZIG_ARCHIVE:-not found beside the helper root}"
echo "Expect synced surface:  $([[ "${EXPECT_SYNCED_HELPER_SURFACE}" -eq 1 ]] && echo yes || echo no)"
echo

for row in "${STATUS_ROWS[@]}"; do
    IFS="|" read -r root relative_path label exists <<<"${row}"
    status="FAIL"
    [[ "${exists}" -eq 1 ]] && status="PASS"
    echo "[${status}] ${relative_path}"
    echo "  Root:  ${root}"
    echo "  Check: ${label}"
done

echo
echo "Suggested next commands:"
echo "  ${SAVED_MEMORY_PREFLIGHT_COMMAND}"
echo "  ${ARCHIVE_INTEGRITY_COMMAND}"
echo "  ${LINUX_BUILD_ROUTE_COMMAND}"
echo "  ${RUNTIME_ROUTE_COMMAND}"

if [[ "${missing_count}" -gt 0 ]]; then
    echo
    echo "Missing checks: ${missing_count}" >&2
    exit 1
fi

echo
echo "Restored checkout follow-up surface is ready."
