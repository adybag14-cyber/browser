#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  bash scripts/linux/check_issue3_saved_recovery_preflight.sh \
    [--repo-root /path/to/browser-repo] \
    [--helper-root /path/to/live/browser-repo] \
    [--memory-root /path/to/workspace/memory] \
    [--agent-files-root /path/to/workspace/agent_files] \
    [--restored-checkout-root /path/to/browser-memory-snapshot] \
    [--fallback-zig-archive /path/to/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz] \
    [--require-fallback-zig] \
    [--expect-helper-surface] \
    [--json]
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
MEMORY_ROOT=""
AGENT_FILES_ROOT=""
RESTORED_CHECKOUT_ROOT=""
FALLBACK_ZIG_ARCHIVE=""
REQUIRE_FALLBACK_ZIG=0
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
        --require-fallback-zig)
            REQUIRE_FALLBACK_ZIG=1
            shift
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
if [[ -z "${MEMORY_ROOT}" ]]; then
    MEMORY_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/memory"
fi
if [[ -z "${AGENT_FILES_ROOT}" ]]; then
    AGENT_FILES_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/agent_files"
fi
if [[ -z "${RESTORED_CHECKOUT_ROOT}" ]]; then
    RESTORED_CHECKOUT_ROOT="$(cd "${REPO_ROOT}/.." && pwd)/${DEFAULT_RESTORED_CHECKOUT_NAME}"
fi

declare -a REQUIRED_HELPERS=(
    "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh"
    "scripts/check_issue3_saved_archive_integrity.py"
    "scripts/check_issue3_saved_memory_inputs.py"
    "scripts/check_issue3_restored_checkout.py"
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"
    "scripts/linux/show_issue3_linux_build_readiness_route.sh"
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
)

for relative_path in "${REQUIRED_HELPERS[@]}"; do
    if [[ ! -f "${HELPER_ROOT}/${relative_path}" ]]; then
        echo "Required helper is missing from helper root: ${HELPER_ROOT}/${relative_path}" >&2
        exit 1
    fi
done

ARCHIVE_ROUTE_SURFACE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh") --repo-root $(format_shell_arg "${HELPER_ROOT}")"
ARCHIVE_INTEGRITY_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_archive_integrity.py") --repo-root $(format_shell_arg "${REPO_ROOT}")"
MEMORY_PREFLIGHT_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_saved_memory_inputs.py") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --restored-checkout-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RESTORED_CHECKOUT_COMMAND="python $(format_shell_arg "${HELPER_ROOT}/scripts/check_issue3_restored_checkout.py") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RESTORE_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh") --repo-root $(format_shell_arg "${REPO_ROOT}") --helper-root $(format_shell_arg "${HELPER_ROOT}") --memory-root $(format_shell_arg "${MEMORY_ROOT}") --destination $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
BUILD_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_linux_build_readiness_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"
RUNTIME_ROUTE_COMMAND="bash $(format_shell_arg "${HELPER_ROOT}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh") --repo-root $(format_shell_arg "${RESTORED_CHECKOUT_ROOT}")"

if [[ -n "${FALLBACK_ZIG_ARCHIVE}" ]]; then
    ARCHIVE_INTEGRITY_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    MEMORY_PREFLIGHT_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    BUILD_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
    RUNTIME_ROUTE_COMMAND+=" --fallback-zig-archive $(format_shell_arg "${FALLBACK_ZIG_ARCHIVE}")"
fi

if [[ "${REQUIRE_FALLBACK_ZIG}" -eq 1 ]]; then
    ARCHIVE_INTEGRITY_COMMAND+=" --require-fallback-zig"
fi

if [[ "${EXPECT_HELPER_SURFACE}" -eq 1 ]]; then
    RESTORED_CHECKOUT_COMMAND+=" --helper-root $(format_shell_arg "${HELPER_ROOT}") --expect-helper-surface"
fi

surface_status="not-run"
archive_status="not-run"
memory_status="not-run"
restored_status="skipped"
overall_status="blocked"
recommended_route="saved-archive-integrity"
recommended_next_step="${ARCHIVE_ROUTE_SURFACE_COMMAND}"

if eval "${ARCHIVE_ROUTE_SURFACE_COMMAND}" >/dev/null; then
    surface_status="pass"
else
    surface_status="fail"
fi

if [[ "${surface_status}" == "pass" ]] && eval "${ARCHIVE_INTEGRITY_COMMAND}" >/dev/null; then
    archive_status="pass"
elif [[ "${surface_status}" == "pass" ]]; then
    archive_status="fail"
fi

if [[ "${archive_status}" == "pass" ]] && eval "${MEMORY_PREFLIGHT_COMMAND}" >/dev/null; then
    memory_status="pass"
elif [[ "${archive_status}" == "pass" ]]; then
    memory_status="fail"
fi

if [[ "${memory_status}" == "pass" ]] && [[ -d "${RESTORED_CHECKOUT_ROOT}" ]]; then
    if eval "${RESTORED_CHECKOUT_COMMAND}" >/dev/null; then
        restored_status="pass"
    else
        restored_status="fail"
    fi
fi

if [[ "${surface_status}" != "pass" ]]; then
    overall_status="blocked"
    recommended_route="saved-archive-integrity"
    recommended_next_step="${ARCHIVE_ROUTE_SURFACE_COMMAND}"
elif [[ "${archive_status}" != "pass" ]]; then
    overall_status="blocked"
    recommended_route="saved-archive-integrity"
    recommended_next_step="${ARCHIVE_INTEGRITY_COMMAND}"
elif [[ "${memory_status}" != "pass" ]]; then
    overall_status="blocked"
    recommended_route="saved-memory-inputs"
    recommended_next_step="${MEMORY_PREFLIGHT_COMMAND}"
elif [[ ! -d "${RESTORED_CHECKOUT_ROOT}" ]]; then
    overall_status="needs-restore"
    recommended_route="saved-browser-snapshot"
    recommended_next_step="${RESTORE_ROUTE_COMMAND}"
elif [[ "${restored_status}" != "pass" ]]; then
    overall_status="restore-needs-attention"
    recommended_route="saved-browser-snapshot"
    recommended_next_step="${RESTORED_CHECKOUT_COMMAND}"
else
    overall_status="ready"
    recommended_route="linux-build-readiness"
    recommended_next_step="${BUILD_ROUTE_COMMAND}"
fi

if [[ "${JSON}" -eq 1 ]]; then
    printf '{\n'
    printf '  "profile": %s,\n' "$(json_escape "issue3-saved-recovery-preflight")"
    printf '  "repo_root": %s,\n' "$(json_escape "${REPO_ROOT}")"
    printf '  "helper_root": %s,\n' "$(json_escape "${HELPER_ROOT}")"
    printf '  "memory_root": %s,\n' "$(json_escape "${MEMORY_ROOT}")"
    printf '  "agent_files_root": %s,\n' "$(json_escape "${AGENT_FILES_ROOT}")"
    printf '  "restored_checkout_root": %s,\n' "$(json_escape "${RESTORED_CHECKOUT_ROOT}")"
    printf '  "fallback_zig_archive": %s,\n' "$(json_escape "${FALLBACK_ZIG_ARCHIVE}")"
    printf '  "require_fallback_zig": %s,\n' "$([[ "${REQUIRE_FALLBACK_ZIG}" -eq 1 ]] && echo true || echo false)"
    printf '  "expect_helper_surface": %s,\n' "$([[ "${EXPECT_HELPER_SURFACE}" -eq 1 ]] && echo true || echo false)"
    printf '  "surface_status": %s,\n' "$(json_escape "${surface_status}")"
    printf '  "archive_status": %s,\n' "$(json_escape "${archive_status}")"
    printf '  "memory_status": %s,\n' "$(json_escape "${memory_status}")"
    printf '  "restored_status": %s,\n' "$(json_escape "${restored_status}")"
    printf '  "overall_status": %s,\n' "$(json_escape "${overall_status}")"
    printf '  "recommended_route": %s,\n' "$(json_escape "${recommended_route}")"
    printf '  "recommended_next_step": %s,\n' "$(json_escape "${recommended_next_step}")"
    printf '  "commands": {\n'
    printf '    "archive_route_surface": %s,\n' "$(json_escape "${ARCHIVE_ROUTE_SURFACE_COMMAND}")"
    printf '    "archive_integrity": %s,\n' "$(json_escape "${ARCHIVE_INTEGRITY_COMMAND}")"
    printf '    "memory_preflight": %s,\n' "$(json_escape "${MEMORY_PREFLIGHT_COMMAND}")"
    printf '    "restored_checkout": %s,\n' "$(json_escape "${RESTORED_CHECKOUT_COMMAND}")"
    printf '    "restore_route": %s,\n' "$(json_escape "${RESTORE_ROUTE_COMMAND}")"
    printf '    "build_route": %s,\n' "$(json_escape "${BUILD_ROUTE_COMMAND}")"
    printf '    "runtime_route": %s\n' "$(json_escape "${RUNTIME_ROUTE_COMMAND}")"
    printf '  }\n'
    printf '}\n'
else
    cat <<EOF
Issue #3 saved recovery preflight

Repo root:             ${REPO_ROOT}
Live helper root:      ${HELPER_ROOT}
Memory root:           ${MEMORY_ROOT}
Agent files root:      ${AGENT_FILES_ROOT}
Restored checkout:     ${RESTORED_CHECKOUT_ROOT}
Fallback Zig archive:  ${FALLBACK_ZIG_ARCHIVE:-not provided}
Require fallback Zig:  $([[ "${REQUIRE_FALLBACK_ZIG}" -eq 1 ]] && echo yes || echo no)
Expect helper surface: $([[ "${EXPECT_HELPER_SURFACE}" -eq 1 ]] && echo yes || echo no)

Status
======
  Archive route surface: ${surface_status}
  Archive integrity:     ${archive_status}
  Memory inputs:         ${memory_status}
  Restored checkout:     ${restored_status}
  Overall:               ${overall_status}

Recommended next route: ${recommended_route}
Recommended next step:
  ${recommended_next_step}

Commands
========
  Archive route surface:
    ${ARCHIVE_ROUTE_SURFACE_COMMAND}
  Archive integrity:
    ${ARCHIVE_INTEGRITY_COMMAND}
  Memory preflight:
    ${MEMORY_PREFLIGHT_COMMAND}
  Restored checkout:
    ${RESTORED_CHECKOUT_COMMAND}
  Restore route:
    ${RESTORE_ROUTE_COMMAND}
  Linux build-readiness route:
    ${BUILD_ROUTE_COMMAND}
  Direct runtime re-entry route:
    ${RUNTIME_ROUTE_COMMAND}
EOF
fi

if [[ "${overall_status}" == "ready" ]]; then
    exit 0
fi

exit 1
